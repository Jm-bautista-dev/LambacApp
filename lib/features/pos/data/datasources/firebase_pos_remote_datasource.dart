import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../products/data/datasources/mock_product_database.dart';
import '../../../products/data/models/product_model.dart';
import '../../../sales/data/models/sales_channel.dart';
import '../../../sales/data/models/sales_record_item_model.dart';
import '../../../sales/data/models/sales_record_model.dart';
import '../models/pos_checkout_request.dart';
import '../models/pos_receipt_model.dart';
import 'pos_remote_datasource.dart';

/// Production Cloud Firestore implementation of Point of Sale backend
class FirebasePosRemoteDataSource implements PosRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebasePosRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _productsCol =>
      _firestore.collection('products');

  CollectionReference<Map<String, dynamic>> get _salesCol =>
      _firestore.collection('sales');

  /// Helper to verify staff or admin permissions
  Future<bool> _isAuthorizedStaffOrAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    if (user.email == 'jmbautista0228@gmail.com' || user.email == 'jmbautistaa0428@gmail.com') {
      return true;
    }
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;
      final role = doc.data()?['role']?.toString().toLowerCase();
      return role == 'admin' ||
          role == 'super_admin' ||
          role == 'staff' ||
          role == 'barista' ||
          role == 'employee';
    } catch (_) {
      return false;
    }
  }

  ProductModel _mapDocToProduct(DocumentSnapshot<Map<String, dynamic>> doc) {
    final rawData = doc.data() ?? {};
    final map = Map<String, dynamic>.from(rawData);
    map['id'] = doc.id;

    if (map['created_at'] is Timestamp) {
      map['created_at'] = (map['created_at'] as Timestamp).toDate().toIso8601String();
    }
    if (map['createdAt'] is Timestamp) {
      map['created_at'] = (map['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    if (map['updated_at'] is Timestamp) {
      map['updated_at'] = (map['updated_at'] as Timestamp).toDate().toIso8601String();
    }
    return ProductModel.fromJson(map);
  }

  SalesRecordModel _mapDocToSalesRecord(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final id = doc.id;

    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((e) {
      if (e is Map<String, dynamic>) {
        return SalesRecordItemModel.fromJson(e);
      }
      return SalesRecordItemModel.fromJson(Map<String, dynamic>.from(e as Map));
    }).toList();

    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return SalesRecordModel(
      id: id,
      transactionNumber: (data['transaction_number'] ?? 'TX-POS-0000').toString(),
      channel: SalesChannel.fromString(data['channel']?.toString()),
      orderId: data['order_id']?.toString(),
      customerName: data['customer_name']?.toString(),
      customerPhone: data['customer_phone']?.toString(),
      items: items,
      subtotal: ((data['subtotal'] ?? 0.0) as num).toDouble(),
      totalAmount: ((data['total_amount'] ?? 0.0) as num).toDouble(),
      paymentMethod: (data['payment_method'] ?? 'Cash').toString(),
      notes: data['notes']?.toString(),
      recordedByStaffId: data['recorded_by_staff_id']?.toString(),
      recordedByStaffName: data['recorded_by_staff_name']?.toString(),
      isVoided: (data['is_voided'] ?? false) as bool,
      voidReason: data['void_reason']?.toString(),
      createdAt: parseDateTime(data['created_at']),
    );
  }

  @override
  Stream<List<ProductModel>> watchProducts() {
    return _productsCol.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Fallback to static mock database while initial Firestore seed propagates
        return MockProductDatabase().getAllProducts();
      }
      return snapshot.docs.map(_mapDocToProduct).toList();
    }).handleError((error) {
      // In case of offline error, return mock database products
      return MockProductDatabase().getAllProducts();
    });
  }

  @override
  Future<Result<PosReceiptModel, AppFailure>> completeSaleTransaction(PosCheckoutRequest request) async {
    final isAuthorized = await _isAuthorizedStaffOrAdmin();
    if (!isAuthorized) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: POS checkout is restricted to authorized baristas and administrators.'),
      );
    }

    if (request.items.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Cannot complete transaction with an empty cart.'),
      );
    }

    // Cash tender validation
    if (request.paymentMethod.toLowerCase() == 'cash') {
      if (request.tenderedAmount == null || request.tenderedAmount! < request.totalAmount) {
        return Result.failure(
          ValidationFailure(
            message: 'Tendered cash amount (₱${request.tenderedAmount?.toStringAsFixed(2) ?? "0.00"}) must be greater than or equal to total charged (₱${request.totalAmount.toStringAsFixed(2)}).',
          ),
        );
      }
    }

    try {
      final saleId = 'sale_${request.idempotencyKey}';
      final saleDocRef = _salesCol.doc(saleId);

      // Check for duplicate submission first (Idempotency check)
      final existingCheck = await saleDocRef.get();
      if (existingCheck.exists) {
        final existingSale = _mapDocToSalesRecord(existingCheck);
        return Result.success(
          PosReceiptModel.fromSaleRecord(
            existingSale,
            tenderedAmount: request.tenderedAmount,
            changeAmount: request.changeAmount,
            discountAmount: request.discountAmount,
            discountType: request.discountType,
          ),
        );
      }

      // Execute atomic transaction: validates latest inventory & prices, decrements stock, commits sale
      final receipt = await _firestore.runTransaction<PosReceiptModel>((transaction) async {
        final productDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};

        // 1. Read phase: fetch authoritative product documents
        for (final item in request.items) {
          final pRef = _productsCol.doc(item.product.id);
          final pDoc = await transaction.get(pRef);
          productDocs[item.product.id] = pDoc;
        }

        // 2. Validate phase: verify availability, stock, and pricing consistency
        for (final item in request.items) {
          final pDoc = productDocs[item.product.id];
          if (pDoc == null || !pDoc.exists) {
            throw Exception("Product '${item.product.name}' was removed from the catalog.");
          }

          final data = pDoc.data() ?? {};
          final isEnabled = (data['is_enabled'] ?? data['isEnabled'] ?? true) as bool;
          if (!isEnabled) {
            throw Exception("Product '${item.product.name}' was disabled by an administrator. Please remove it from the cart.");
          }

          final currentStock = (data['stock_quantity'] ?? data['stock'] ?? 0) as int;
          if (currentStock < item.quantity) {
            throw Exception("Insufficient stock for '${item.product.name}'. Requested: ${item.quantity}, Available: $currentStock.");
          }

          final liveBasePrice = ((data['price'] ?? data['base_price'] ?? 0.0) as num).toDouble();
          final sizeDelta = item.sizeVariant?.priceDelta ?? 0.0;
          final grindDelta = item.grindVariant?.priceDelta ?? 0.0;
          final liveExpectedUnitPrice = liveBasePrice + sizeDelta + grindDelta;

          if ((liveExpectedUnitPrice - item.capturedUnitPrice).abs() > 0.01) {
            throw Exception(
              "Price change detected on '${item.product.name}'. Current selling price is ₱${liveExpectedUnitPrice.toStringAsFixed(2)} (Cart had ₱${item.capturedUnitPrice.toStringAsFixed(2)}). Please update prices in the cart.",
            );
          }
        }

        // 3. Write phase A: Atomically decrement product inventory
        for (final item in request.items) {
          final pDoc = productDocs[item.product.id]!;
          final data = pDoc.data() ?? {};
          final currentStock = (data['stock_quantity'] ?? data['stock'] ?? 0) as int;
          final newStock = (currentStock - item.quantity).clamp(0, 999999);
          final newAvailability = newStock == 0 ? 'outOfStock' : (newStock <= 5 ? 'lowStock' : 'available');

          transaction.update(_productsCol.doc(item.product.id), {
            'stock_quantity': newStock,
            'availability': newAvailability,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }

        // 4. Write phase B: Atomically create sales ledger record
        final now = DateTime.now();
        final txNum = 'TX-POS-${now.year}-${request.idempotencyKey.substring(0, request.idempotencyKey.length.clamp(0, 8)).toUpperCase()}';

        final salesRecordItems = request.toSalesRecordItems();
        final saleData = <String, dynamic>{
          'id': saleId,
          'transaction_number': txNum,
          'channel': SalesChannel.walkIn.canonicalKey,
          if (request.customerName != null && request.customerName!.isNotEmpty) 'customer_name': request.customerName,
          if (request.customerPhone != null && request.customerPhone!.isNotEmpty) 'customer_phone': request.customerPhone,
          'items': salesRecordItems.map((i) => i.toJson()).toList(),
          'subtotal': request.subtotal,
          'discount_amount': request.discountAmount,
          'discount_type': request.discountType,
          'total_amount': request.totalAmount,
          'payment_method': request.paymentMethod,
          if (request.tenderedAmount != null) 'tendered_amount': request.tenderedAmount,
          if (request.changeAmount != null) 'change_amount': request.changeAmount,
          if (request.notes != null && request.notes!.isNotEmpty) 'notes': request.notes,
          'staff_id': request.staffId,
          'recorded_by_staff_id': request.staffId,
          'recorded_by_staff_name': request.staffName,
          'is_voided': false,
          'created_at': Timestamp.fromDate(now),
        };

        transaction.set(saleDocRef, saleData);

        return PosReceiptModel(
          receiptNumber: txNum,
          saleId: saleId,
          createdAt: now,
          staffName: request.staffName,
          staffId: request.staffId,
          customerName: request.customerName,
          customerPhone: request.customerPhone,
          items: salesRecordItems,
          subtotal: request.subtotal,
          discountAmount: request.discountAmount,
          discountType: request.discountType,
          totalAmount: request.totalAmount,
          paymentMethod: request.paymentMethod,
          tenderedAmount: request.tenderedAmount,
          changeAmount: request.changeAmount,
          notes: request.notes,
        );
      });

      return Result.success(receipt);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(message: 'Database write error: ${e.message}'));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      return Result.failure(ValidationFailure(message: msg));
    }
  }

  @override
  Future<Result<List<SalesRecordModel>, AppFailure>> getRecentPosTransactions({int limit = 20}) async {
    final isAuthorized = await _isAuthorizedStaffOrAdmin();
    if (!isAuthorized) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Access denied to sales transactions.'),
      );
    }

    try {
      final snapshot = await _salesCol
          .where('channel', whereIn: ['WALK_IN', 'walkIn', 'walk_in'])
          .limit(limit)
          .get();

      final list = snapshot.docs.map(_mapDocToSalesRecord).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Result.success(list);
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to retrieve recent POS transactions: $e'));
    }
  }
}
