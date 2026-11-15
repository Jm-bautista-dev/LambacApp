import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/security/audit_logger.dart';
import '../../../../shared/models/user_model.dart';
import '../../../orders/data/models/order_model.dart';

/// Structured Customer Data Export Container for GDPR/DPA Data Portability Compliance
class CustomerDataExport extends Equatable {
  final DateTime exportTimestamp;
  final String formatVersion;
  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> reviews;
  final List<Map<String, dynamic>> notifications;

  const CustomerDataExport({
    required this.exportTimestamp,
    this.formatVersion = '1.0',
    required this.profile,
    required this.orders,
    required this.reviews,
    required this.notifications,
  });

  Map<String, dynamic> toJson() {
    return {
      'export_timestamp': exportTimestamp.toIso8601String(),
      'format_version': formatVersion,
      'profile': profile,
      'orders': orders,
      'reviews': reviews,
      'notifications': notifications,
    };
  }

  @override
  List<Object?> get props => [
        exportTimestamp,
        formatVersion,
        profile,
        orders,
        reviews,
        notifications,
      ];
}

/// Service handling Account Privacy, Data Portability (Export), and Account Deletion with Anonymization
class AccountPrivacyService {
  static final AccountPrivacyService _instance = AccountPrivacyService._internal();
  factory AccountPrivacyService() => _instance;
  AccountPrivacyService._internal();

  /// Generates a complete data export for the authenticated customer
  CustomerDataExport generateExport({
    required UserModel user,
    required List<OrderModel> orders,
    List<Map<String, dynamic>> reviews = const [],
    List<Map<String, dynamic>> notifications = const [],
  }) {
    final profileData = {
      'id': user.id,
      'full_name': user.fullName,
      'email': user.email,
      'phone_number': user.phoneNumber,
      'role': user.role.name,
      'status': user.status.name,
      'loyalty_points': user.loyaltyPoints,
      'terms_accepted': user.termsAccepted,
      'created_at': user.createdAt?.toIso8601String(),
    };

    final orderData = orders.map((o) => {
      'order_number': o.orderNumber,
      'status': o.status.name,
      'subtotal': o.subtotal,
      'total_amount': o.totalAmount,
      'pickup_date': o.pickupDate,
      'pickup_time_slot': o.pickupTimeSlot,
      'pickup_location': o.pickupLocation.name,
      'payment_method': o.paymentMethod,
      'payment_status': o.paymentStatus,
      'created_at': o.createdAt.toIso8601String(),
      'items': o.items.map((i) => {
        'product_name': i.productName,
        'quantity': i.quantity,
        'unit_price': i.unitPrice,
        'total_price': i.totalPrice,
      }).toList(),
    }).toList();

    return CustomerDataExport(
      exportTimestamp: DateTime.now(),
      profile: profileData,
      orders: orderData,
      reviews: reviews,
      notifications: notifications,
    );
  }

  /// Executes safe customer account deletion by stripping PII and preserving statutory business records
  ///
  /// Statutory Preservation Rule (National Internal Revenue Code & Commercial Law):
  /// Completed financial orders and sales records MUST be preserved for 7 years for tax and audit compliance.
  /// Customer profile PII is anonymized while transaction IDs and line items remain immutable.
  UserModel anonymizeProfile(UserModel user) {
    final shortId = user.id.length > 8 ? user.id.substring(0, 8) : user.id;

    return UserModel(
      id: user.id,
      email: 'deleted-user-$shortId@anonymized.lambac',
      fullName: 'Former Customer',
      phoneNumber: null,
      avatarUrl: null,
      role: UserRole.customer,
      status: UserStatus.disabled,
      mustChangePassword: false,
      permissions: const [],
      loyaltyPoints: 0,
      termsAccepted: false,
      createdAt: user.createdAt,
    );
  }

  /// Anonymizes customer-identifying fields on an order while keeping financial ledger fields intact
  OrderModel anonymizeOrder(OrderModel order) {
    return order.copyWith(
      customerName: 'Former Customer',
      customerPhone: '0000000000',
    );
  }

  /// Records an administrative audit log for the account deletion & anonymization action
  void logAccountAnonymization({
    required String actorUid,
    required String actorEmail,
    required String targetUserId,
  }) {
    AuditLogger().log(
      action: AuditActionType.accountDisabled,
      actorEmail: actorEmail,
      actorRole: 'customer',
      actorUid: actorUid,
      entityId: targetUserId,
      details: 'Customer self-initiated account deletion & PII anonymization completed; statutory financial records preserved per 7-year retention policy',
    );
  }
}

/// Riverpod provider for AccountPrivacyService
final accountPrivacyServiceProvider = Provider<AccountPrivacyService>((ref) {
  return AccountPrivacyService();
});
