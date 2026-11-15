import 'dart:async';
import 'dart:convert';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/mock_ledger_store.dart';
import '../../../auth/data/datasources/mock_user_database.dart';
import '../../../orders/data/models/order_model.dart';
import '../models/create_walk_in_sale_request.dart';
import '../models/sales_channel.dart';
import '../models/sales_record_item_model.dart';
import '../models/sales_record_model.dart';
import '../models/void_sale_request.dart';
import 'sales_remote_datasource.dart';

/// Offline & In-Memory Centralized Sales Ledger (Single Source of Truth)
/// Stores actual completed walk-in and mobile transactions without hardcoded analytics.
class MockSalesRemoteDataSource implements SalesRemoteDataSource {
  static final MockSalesRemoteDataSource _instance = MockSalesRemoteDataSource._internal();
  factory MockSalesRemoteDataSource() => _instance;

  final List<SalesRecordModel> _sales = [];

  MockSalesRemoteDataSource._internal() {
    _seedHistoricalSalesLedger();
    _restorePersistedSales();
  }

  /// Runtime (non-seed) sales are those recorded from completed customer orders and POS transactions
  bool _isRuntimeSale(SalesRecordModel s) =>
      !s.id.startsWith('sale_hist_') &&
      !s.id.startsWith('sale_deep_') &&
      s.id != 'sale_8092';

  void _restorePersistedSales() {
    final raw = MockLedgerStore.read(MockLedgerStore.salesKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final restored = decoded
          .map((e) => SalesRecordModel.fromJson(e as Map<String, dynamic>))
          .where((s) => !_sales.any((existing) => existing.id == s.id));
      _sales.insertAll(0, restored);
    } catch (_) {
      // Corrupt payload: ignore, seeded ledger remains intact
    }
  }

  void _persistRuntimeSales() {
    if (!MockLedgerStore.isEnabled) return;
    MockLedgerStore.write(
      MockLedgerStore.salesKey,
      jsonEncode(_sales.where(_isRuntimeSale).map((s) => s.toJson()).toList()),
    );
  }

  /// Reloads persisted runtime sales after MockLedgerStore.init() finishes
  void reloadPersistedSales() {
    if (MockLedgerStore.isEnabled) {
      _restorePersistedSales();
    }
  }

  UserModel? get _currentUser => MockUserDatabase().currentUser;

  /// Returns unmodifiable list of all persisted sales records in the ledger
  List<SalesRecordModel> getAllSales({bool includeVoided = false}) {
    if (includeVoided) {
      return List.unmodifiable(_sales);
    }
    return List.unmodifiable(_sales.where((s) => !s.isVoided));
  }

  /// Query sales strictly filtered between [start] and [end] timestamps
  List<SalesRecordModel> getSalesForDateRange(
    DateTime start,
    DateTime end, {
    bool includeVoided = false,
    SalesChannel? channel,
  }) {
    final startUtc = start.toUtc();
    final endUtc = end.toUtc();
    return _sales.where((s) {
      if (!includeVoided && s.isVoided) return false;
      if (channel != null && s.channel != channel) return false;
      final sUtc = s.createdAt.toUtc();
      return !sUtc.isBefore(startUtc) && sUtc.isBefore(endUtc);
    }).toList();
  }

  /// Automatically records a completed mobile order as a valid sales transaction.
  /// Idempotent: exactly one sale per order id. Returns true when a sale for the
  /// order exists after the call (newly recorded or previously recorded).
  /// The sale is dated by the order's completion/pickup time (never creation time).
  bool recordCompletedOrderSale(OrderModel order) {
    final existingIndex = _sales.indexWhere((s) => s.orderId == order.id);
    if (existingIndex != -1) return true; // Already recorded - never duplicate

    final items = order.items.map((item) {
      return SalesRecordItemModel(
        id: 'item_s_${item.id}',
        productId: item.productId,
        productName: item.productName,
        size: item.size,
        grind: item.grind,
        snapshotUnitPrice: item.unitPrice,
        quantity: item.quantity,
        totalPrice: item.totalPrice,
      );
    }).toList();

    final newSale = SalesRecordModel(
      id: 'sale_${order.id}',
      transactionNumber: 'TX-MOB-${order.orderNumber}',
      channel: SalesChannel.mobileApp,
      orderId: order.id,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      items: items,
      subtotal: order.subtotal,
      totalAmount: order.totalAmount,
      paymentMethod: order.paymentMethod,
      createdAt: order.completedAt ?? DateTime.now(),
    );

    _sales.insert(0, newSale);
    _persistRuntimeSales();
    return true;
  }

  /// Records a direct transaction (e.g. POS counter sale) into the centralized sales ledger.
  /// Idempotent: exactly one sale per sale id.
  bool recordDirectSale(SalesRecordModel sale) {
    final existingIndex = _sales.indexWhere((s) => s.id == sale.id);
    if (existingIndex != -1) return true; // Already recorded - idempotent
    _sales.insert(0, sale);
    _persistRuntimeSales();
    return true;
  }

  /// Rolls back a sale created during a failed completion transaction
  void rollbackSaleForOrder(String orderId) {
    _sales.removeWhere((s) => s.orderId == orderId);
    _persistRuntimeSales();
  }

  /// Whether a sale already exists for the given order
  bool hasSaleForOrder(String orderId) => _sales.any((s) => s.orderId == orderId);

  @override
  Future<Result<List<SalesRecordModel>, AppFailure>> getSalesRecords({
    SalesChannel? channel,
    String? dateRange,
    String? searchQuery,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 60));

    final user = _currentUser;
    if (user == null || !user.isBusinessUser) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Access denied to centralized sales ledger.'),
      );
    }

    var filtered = List<SalesRecordModel>.from(_sales);

    if (channel != null) {
      filtered = filtered.where((s) => s.channel == channel).toList();
    }

    if (dateRange != null && dateRange.isNotEmpty) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      switch (dateRange.toLowerCase()) {
        case 'today':
          filtered = filtered.where((s) => s.createdAt.isAfter(todayStart) && s.createdAt.isBefore(todayEnd)).toList();
          break;
        case '7d':
        case '7 days':
        case 'last 7 days':
          final start7 = todayStart.subtract(const Duration(days: 6));
          filtered = filtered.where((s) => s.createdAt.isAfter(start7) && s.createdAt.isBefore(todayEnd)).toList();
          break;
        case '15d':
        case '15 days':
        case 'last 15 days':
          final start15 = todayStart.subtract(const Duration(days: 14));
          filtered = filtered.where((s) => s.createdAt.isAfter(start15) && s.createdAt.isBefore(todayEnd)).toList();
          break;
        case '30d':
        case '30 days':
        case 'last 30 days':
          final start30 = todayStart.subtract(const Duration(days: 29));
          filtered = filtered.where((s) => s.createdAt.isAfter(start30) && s.createdAt.isBefore(todayEnd)).toList();
          break;
      }
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      filtered = filtered.where((s) {
        return s.transactionNumber.toLowerCase().contains(q) ||
            (s.customerName?.toLowerCase().contains(q) ?? false) ||
            s.items.any((i) => i.productName.toLowerCase().contains(q));
      }).toList();
    }

    // Sort descending by creation date
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Result.success(List.unmodifiable(filtered));
  }

  @override
  Future<Result<SalesRecordModel, AppFailure>> recordWalkInSale(CreateWalkInSaleRequest request) async {
    return const Result.failure(
      ForbiddenFailure(message: 'Walk-In POS ordering is temporarily disabled.'),
    );
  }

  @override
  Future<Result<SalesRecordModel, AppFailure>> voidSaleRecord(VoidSaleRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final user = _currentUser;
    if (user == null || !user.isBusinessUser) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Voiding sales is restricted to authorized staff.'),
      );
    }

    final index = _sales.indexWhere((s) => s.id == request.saleId);
    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Sales record not found.'),
      );
    }

    final voided = _sales[index].copyWith(
      isVoided: true,
      voidReason: request.voidReason,
    );

    _sales[index] = voided;
    return Result.success(voided);
  }

  /// Reset all sales to default historical seed for test isolation
  void resetForTesting() {
    _sales.clear();
    _seedHistoricalSalesLedger();
  }

  /// Seeds an authentic 45-day sales ledger with real mobile customer pickup transactions
  void _seedHistoricalSalesLedger() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // Historical Yesterday Mobile Pickup Sale (Day 1)
    _sales.add(
      SalesRecordModel(
        id: 'sale_8092',
        transactionNumber: 'TX-MOB-8092',
        channel: SalesChannel.mobileApp,
        orderId: 'ord_lmb_0941',
        customerName: 'Kenji Takahashi',
        customerPhone: '09171234567',
        items: const [
          SalesRecordItemModel(
            id: 'item_t3',
            productId: 'benguet-typica',
            productName: 'Benguet Arabica Typica Heirloom',
            size: '250g Bag',
            grind: 'V60 / Pourover',
            snapshotUnitPrice: 420.0,
            quantity: 2,
            totalPrice: 840.0,
          ),
        ],
        subtotal: 840.0,
        totalAmount: 840.0,
        paymentMethod: 'Pay at Counter',
        createdAt: DateTime(yesterday.year, yesterday.month, yesterday.day, 20, 15),
      ),
    );

    // Historical Days Generation (Days 1 through 15) - Customer Mobile Pickup Orders
    final dailyTransactionsPlan = [
      // Day 1 (Yesterday)
      [
        ('tokyo-blend', 'Tokyo Kissaten Signature Blend', 380.0, 2, 'GCash'),
        ('sagada-geisha', 'Sagada High Mountain Geisha', 580.0, 1, 'Maya'),
        ('kyoto-cold-brew', 'Kyoto 18-Hour Slow Cold Brew', 220.0, 3, 'Pay at Counter'),
      ],
      // Day 2
      [
        ('mt-apo-honey', 'Mount Apo Anaerobic Honey Reserve', 480.0, 3, 'GCash'),
        ('benguet-typica', 'Benguet Arabica Typica Heirloom', 420.0, 2, 'Pay at Counter'),
      ],
      // Day 3
      [
        ('tokyo-blend', 'Tokyo Kissaten Signature Blend', 380.0, 3, 'Card'),
        ('decaf-swiss-water', 'Swiss Water Decaf Reserve', 360.0, 1, 'Pay at Counter'),
        ('kyoto-cold-brew', 'Kyoto 18-Hour Slow Cold Brew', 220.0, 4, 'GCash'),
      ],
      // Day 4
      [
        ('sagada-geisha', 'Sagada High Mountain Geisha', 580.0, 2, 'GCash'),
        ('mt-apo-honey', 'Mount Apo Anaerobic Honey Reserve', 480.0, 2, 'Pay at Counter'),
        ('benguet-typica', 'Benguet Arabica Typica Heirloom', 420.0, 1, 'GCash'),
      ],
      // Day 5
      [
        ('tokyo-blend', 'Tokyo Kissaten Signature Blend', 380.0, 4, 'Pay at Counter'),
        ('kyoto-cold-brew', 'Kyoto 18-Hour Slow Cold Brew', 220.0, 5, 'GCash'),
      ],
      // Day 6
      [
        ('mt-apo-honey', 'Mount Apo Anaerobic Honey Reserve', 480.0, 4, 'Maya'),
        ('benguet-typica', 'Benguet Arabica Typica Heirloom', 420.0, 3, 'Pay at Counter'),
        ('sagada-geisha', 'Sagada High Mountain Geisha', 580.0, 1, 'Card'),
      ],
      // Day 7
      [
        ('tokyo-blend', 'Tokyo Kissaten Signature Blend', 380.0, 2, 'Pay at Counter'),
        ('kyoto-cold-brew', 'Kyoto 18-Hour Slow Cold Brew', 220.0, 2, 'GCash'),
      ],
      // Day 8
      [
        ('mt-apo-honey', 'Mount Apo Anaerobic Honey Reserve', 480.0, 3, 'GCash'),
        ('benguet-typica', 'Benguet Arabica Typica Heirloom', 420.0, 2, 'Maya'),
      ],
      // Day 9
      [
        ('tokyo-blend', 'Tokyo Kissaten Signature Blend', 380.0, 3, 'Pay at Counter'),
        ('sagada-geisha', 'Sagada High Mountain Geisha', 580.0, 2, 'GCash'),
        ('kyoto-cold-brew', 'Kyoto 18-Hour Slow Cold Brew', 220.0, 3, 'Pay at Counter'),
      ],
      // Day 10
      [
        ('benguet-typica', 'Benguet Arabica Typica Heirloom', 420.0, 4, 'GCash'),
        ('mt-apo-honey', 'Mount Apo Anaerobic Honey Reserve', 480.0, 2, 'Pay at Counter'),
      ],
      // Day 11
      [
        ('tokyo-blend', 'Tokyo Kissaten Signature Blend', 380.0, 2, 'GCash'),
        ('kyoto-cold-brew', 'Kyoto 18-Hour Slow Cold Brew', 220.0, 4, 'Pay at Counter'),
      ],
      // Day 12
      [
        ('mt-apo-honey', 'Mount Apo Anaerobic Honey Reserve', 480.0, 4, 'Card'),
        ('sagada-geisha', 'Sagada High Mountain Geisha', 580.0, 1, 'Maya'),
        ('decaf-swiss-water', 'Swiss Water Decaf Reserve', 360.0, 1, 'Pay at Counter'),
      ],
      // Day 13
      [
        ('tokyo-blend', 'Tokyo Kissaten Signature Blend', 380.0, 3, 'GCash'),
        ('benguet-typica', 'Benguet Arabica Typica Heirloom', 420.0, 2, 'Pay at Counter'),
      ],
      // Day 14
      [
        ('mt-apo-honey', 'Mount Apo Anaerobic Honey Reserve', 480.0, 3, 'GCash'),
        ('kyoto-cold-brew', 'Kyoto 18-Hour Slow Cold Brew', 220.0, 6, 'Pay at Counter'),
      ],
      // Day 15
      [
        ('sagada-geisha', 'Sagada High Mountain Geisha', 580.0, 2, 'Pay at Counter'),
        ('tokyo-blend', 'Tokyo Kissaten Signature Blend', 380.0, 3, 'Maya'),
      ],
    ];

    int txCounter = 8100;
    for (int dayIndex = 0; dayIndex < dailyTransactionsPlan.length; dayIndex++) {
      final dayAgo = dayIndex + 1;
      final dayDate = now.subtract(Duration(days: dayAgo));
      final itemsForDay = dailyTransactionsPlan[dayIndex];

      for (int i = 0; i < itemsForDay.length; i++) {
        txCounter++;
        final (pId, pName, price, qty, payMethod) = itemsForDay[i];
        final total = price * qty;
        final txTime = DateTime(
          dayDate.year,
          dayDate.month,
          dayDate.day,
          9 + (i * 3) % 10,
          15 + (i * 17) % 40,
        );

        _sales.add(
          SalesRecordModel(
            id: 'sale_hist_$txCounter',
            transactionNumber: 'TX-MOB-$txCounter',
            channel: SalesChannel.mobileApp,
            orderId: 'ord_hist_$txCounter',
            customerName: 'Mobile Customer #${txCounter % 50 + 1}',
            customerPhone: '0917${(1000000 + txCounter).toString()}',
            items: [
              SalesRecordItemModel(
                id: 'item_h_$txCounter',
                productId: pId,
                productName: pName,
                size: '250g Bag',
                grind: 'V60 Pourover',
                snapshotUnitPrice: price,
                quantity: qty,
                totalPrice: total,
              ),
            ],
            subtotal: total,
            totalAmount: total,
            paymentMethod: payMethod,
            createdAt: txTime,
          ),
        );
      }
    }

    // Additional 16-45 days history for deep statistical training (Customer Mobile Pickup Orders)
    for (int day = 16; day <= 45; day++) {
      final dayDate = now.subtract(Duration(days: day));
      final isWeekend = dayDate.weekday == DateTime.saturday || dayDate.weekday == DateTime.sunday;
      final txCount = isWeekend ? 3 : 2;

      for (int t = 0; t < txCount; t++) {
        txCounter++;
        final pChoice = (day + t) % 5;
        final (pId, pName, price) = switch (pChoice) {
          0 => ('mt-apo-honey', 'Mount Apo Anaerobic Honey Reserve', 480.0),
          1 => ('tokyo-blend', 'Tokyo Kissaten Signature Blend', 380.0),
          2 => ('benguet-typica', 'Benguet Arabica Typica Heirloom', 420.0),
          3 => ('sagada-geisha', 'Sagada High Mountain Geisha', 580.0),
          _ => ('kyoto-cold-brew', 'Kyoto 18-Hour Slow Cold Brew', 220.0),
        };
        final qty = 1 + ((day * 3 + t) % 3);
        final total = price * qty;

        _sales.add(
          SalesRecordModel(
            id: 'sale_hist_$txCounter',
            transactionNumber: 'TX-MOB-$txCounter',
            channel: SalesChannel.mobileApp,
            orderId: 'ord_hist_$txCounter',
            customerName: 'Mobile Customer #${txCounter % 50 + 1}',
            customerPhone: '0917${(1000000 + txCounter).toString()}',
            items: [
              SalesRecordItemModel(
                id: 'item_h_$txCounter',
                productId: pId,
                productName: pName,
                size: '250g Bag',
                grind: 'Whole Bean',
                snapshotUnitPrice: price,
                quantity: qty,
                totalPrice: total,
              ),
            ],
            subtotal: total,
            totalAmount: total,
            paymentMethod: 'GCash',
            createdAt: DateTime(dayDate.year, dayDate.month, dayDate.day, 10 + t * 4, 20),
          ),
        );
      }
    }
  }
}
