import 'package:equatable/equatable.dart';
import 'sales_channel.dart';
import 'sales_record_item_model.dart';

/// Unified Centralized Sales Transaction Record
class SalesRecordModel extends Equatable {
  final String id;
  final String transactionNumber; // e.g. "TX-2026-8091"
  final SalesChannel channel;
  final String? orderId; // Links back to mobile pickup order if channel == mobileApp
  final String? customerName;
  final String? customerPhone;
  final List<SalesRecordItemModel> items;
  final double subtotal;
  final double totalAmount;
  final String paymentMethod;
  final String? notes;
  final String? recordedByStaffId;
  final String? recordedByStaffName;
  final bool isVoided;
  final String? voidReason;
  final DateTime createdAt;

  const SalesRecordModel({
    required this.id,
    required this.transactionNumber,
    required this.channel,
    this.orderId,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    required this.totalAmount,
    required this.paymentMethod,
    this.notes,
    this.recordedByStaffId,
    this.recordedByStaffName,
    this.isVoided = false,
    this.voidReason,
    required this.createdAt,
  });

  bool get isMobileApp => channel == SalesChannel.mobileApp;
  bool get isWalkIn => channel == SalesChannel.walkIn;

  int get totalItemCount => items.fold(0, (sum, i) => sum + i.quantity);

  SalesRecordModel copyWith({
    String? id,
    String? transactionNumber,
    SalesChannel? channel,
    String? orderId,
    String? customerName,
    String? customerPhone,
    List<SalesRecordItemModel>? items,
    double? subtotal,
    double? totalAmount,
    String? paymentMethod,
    String? notes,
    String? recordedByStaffId,
    String? recordedByStaffName,
    bool? isVoided,
    String? voidReason,
    DateTime? createdAt,
  }) {
    return SalesRecordModel(
      id: id ?? this.id,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      channel: channel ?? this.channel,
      orderId: orderId ?? this.orderId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      recordedByStaffId: recordedByStaffId ?? this.recordedByStaffId,
      recordedByStaffName: recordedByStaffName ?? this.recordedByStaffName,
      isVoided: isVoided ?? this.isVoided,
      voidReason: voidReason ?? this.voidReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory SalesRecordModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];

    return SalesRecordModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      transactionNumber: (json['transaction_number'] ?? 'TX-2026-0000').toString(),
      channel: SalesChannel.fromString(json['channel']?.toString()),
      orderId: json['order_id']?.toString(),
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      items: rawItems.map((e) => SalesRecordItemModel.fromJson(e as Map<String, dynamic>)).toList(),
      subtotal: ((json['subtotal'] ?? 0.0) as num).toDouble(),
      totalAmount: ((json['total_amount'] ?? 0.0) as num).toDouble(),
      paymentMethod: (json['payment_method'] ?? 'Cash').toString(),
      notes: json['notes']?.toString(),
      recordedByStaffId: json['recorded_by_staff_id']?.toString(),
      recordedByStaffName: json['recorded_by_staff_name']?.toString(),
      isVoided: (json['is_voided'] ?? false) as bool,
      voidReason: json['void_reason']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_number': transactionNumber,
      'channel': channel.canonicalKey,
      if (orderId != null) 'order_id': orderId,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      if (notes != null) 'notes': notes,
      if (recordedByStaffId != null) 'staff_id': recordedByStaffId,
      if (recordedByStaffId != null) 'recorded_by_staff_id': recordedByStaffId,
      if (recordedByStaffName != null) 'recorded_by_staff_name': recordedByStaffName,
      'is_voided': isVoided,
      if (voidReason != null) 'void_reason': voidReason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        transactionNumber,
        channel,
        orderId,
        customerName,
        customerPhone,
        items,
        subtotal,
        totalAmount,
        paymentMethod,
        notes,
        recordedByStaffId,
        recordedByStaffName,
        isVoided,
        voidReason,
        createdAt,
      ];
}
