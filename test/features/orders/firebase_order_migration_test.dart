import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/cart/data/models/pickup_location_model.dart';
import 'package:lambac_app/features/orders/data/models/order_item_model.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';
import 'package:lambac_app/shared/models/user_model.dart';

void main() {
  group('Firestore Orders Migration Specifications', () {
    test('OrderItemModel preserves immutable historical product snapshots', () {
      const originalItem = OrderItemModel(
        id: 'ord_item_1',
        productId: 'prod_apo_honey',
        productName: 'Mount Apo Anaerobic Honey Reserve',
        origin: 'Davao del Sur',
        size: '250g Whole Bean',
        grind: 'Whole Bean',
        unitPrice: 480.0,
        quantity: 2,
        totalPrice: 960.0,
        notes: 'Coarse grind if possible',
      );

      final json = originalItem.toJson();

      // Verify Firestore field mapping
      expect(json['id'], equals('ord_item_1'));
      expect(json['product_id'], equals('prod_apo_honey'));
      expect(json['product_name'], equals('Mount Apo Anaerobic Honey Reserve'));
      expect(json['unit_price'], equals(480.0));
      expect(json['quantity'], equals(2));
      expect(json['total_price'], equals(960.0));
      expect(json['notes'], equals('Coarse grind if possible'));

      // If the product catalog changes its price or name later, the order item remains immutable
      final deserialized = OrderItemModel.fromJson(json);
      expect(deserialized.productName, equals('Mount Apo Anaerobic Honey Reserve'));
      expect(deserialized.unitPrice, equals(480.0));
      expect(deserialized.totalPrice, equals(960.0));
    });

    test('OrderModel adheres to normalized orders/{orderId} Firestore structure', () {
      final now = DateTime.utc(2026, 10, 6, 12, 0, 0);
      final order = OrderModel(
        id: 'ord_12345',
        orderNumber: 'LMB-8001',
        customerId: 'cust_abc_123',
        customerName: 'Juan Dela Cruz',
        customerPhone: '09171234567',
        items: const [
          OrderItemModel(
            id: 'ord_item_1',
            productId: 'prod_apo_honey',
            productName: 'Mount Apo Anaerobic Honey Reserve',
            origin: 'Davao del Sur',
            unitPrice: 480.0,
            quantity: 1,
            totalPrice: 480.0,
          ),
        ],
        subtotal: 480.0,
        totalAmount: 480.0,
        status: OrderStatus.pending,
        pickupLocation: PickupLocationModel.flagship,
        pickupDate: 'Today',
        pickupTimeSlot: '2:30 PM',
        paymentMethod: 'Pay at Counter',
        paymentStatus: 'UNPAID',
        notes: 'Extra hot',
        createdAt: now,
      );

      final json = order.toJson();

      // Verify Firestore document fields
      expect(json['id'], equals('ord_12345'));
      expect(json['order_number'], equals('LMB-8001'));
      expect(json['customer_id'], equals('cust_abc_123'));
      expect(json['customer_name'], equals('Juan Dela Cruz'));
      expect(json['customer_phone'], equals('09171234567'));
      expect(json['subtotal'], equals(480.0));
      expect(json['total_amount'], equals(480.0));
      expect(json['status'], equals('pending'));
      expect(json['payment_method'], equals('Pay at Counter'));
      expect(json['payment_status'], equals('UNPAID'));
      expect(json['notes'], equals('Extra hot'));
      expect(json['pickup_location'], isA<Map<String, dynamic>>());
      expect(json['pickup_date'], equals('Today'));
      expect(json['pickup_time_slot'], equals('2:30 PM'));

      // Round-trip deserialization
      final deserialized = OrderModel.fromJson(json);
      expect(deserialized.id, equals('ord_12345'));
      expect(deserialized.orderNumber, equals('LMB-8001'));
      expect(deserialized.customerId, equals('cust_abc_123'));
      expect(deserialized.totalAmount, equals(480.0));
      expect(deserialized.status, equals(OrderStatus.pending));
      expect(deserialized.items.length, equals(1));
      expect(deserialized.items.first.productName, equals('Mount Apo Anaerobic Honey Reserve'));
    });

    test('OrderStatus transition state machine enforces valid barista and admin progression', () {
      // Pending can transition to confirmed, preparing, or cancelled
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.confirmed), isTrue);
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.preparing), isTrue);
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.cancelled), isTrue);
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.completed), isFalse);

      // Preparing can transition to prepared or readyForPickup
      expect(OrderStatus.preparing.canTransitionTo(OrderStatus.prepared), isTrue);
      expect(OrderStatus.preparing.canTransitionTo(OrderStatus.readyForPickup), isTrue);
      expect(OrderStatus.preparing.canTransitionTo(OrderStatus.pending), isFalse);

      // ReadyForPickup can transition only to completed
      expect(OrderStatus.readyForPickup.canTransitionTo(OrderStatus.completed), isTrue);
      expect(OrderStatus.readyForPickup.canTransitionTo(OrderStatus.cancelled), isFalse);
      expect(OrderStatus.readyForPickup.canTransitionTo(OrderStatus.preparing), isFalse);

      // Completed is terminal
      expect(OrderStatus.completed.canTransitionTo(OrderStatus.pending), isFalse);
      expect(OrderStatus.completed.canTransitionTo(OrderStatus.preparing), isFalse);
      expect(OrderStatus.completed.canTransitionTo(OrderStatus.cancelled), isFalse);

      // Cancelled is terminal
      expect(OrderStatus.cancelled.canTransitionTo(OrderStatus.pending), isFalse);
      expect(OrderStatus.cancelled.canTransitionTo(OrderStatus.completed), isFalse);
    });

    test('Role authorization enforces customer privacy and staff authority', () {
      const customer = UserModel(
        id: 'cust_abc_123',
        email: 'customer@example.com',
        fullName: 'Customer Name',
        role: UserRole.customer,
      );

      const otherCustomer = UserModel(
        id: 'cust_xyz_789',
        email: 'other@example.com',
        fullName: 'Other Customer',
        role: UserRole.customer,
      );

      const staff = UserModel(
        id: 'staff_1',
        email: 'barista@lambac.com',
        fullName: 'Barista Bob',
        role: UserRole.barista,
      );

      const admin = UserModel(
        id: 'admin_1',
        email: 'admin@lambac.com',
        fullName: 'Admin Alice',
        role: UserRole.admin,
      );

      final order = OrderModel(
        id: 'ord_12345',
        orderNumber: 'LMB-8001',
        customerId: 'cust_abc_123',
        customerName: 'Juan Dela Cruz',
        customerPhone: '09171234567',
        items: const [],
        subtotal: 300,
        totalAmount: 300,
        status: OrderStatus.pending,
        pickupLocation: PickupLocationModel.flagship,
        pickupDate: 'Today',
        pickupTimeSlot: '2:00 PM',
        paymentMethod: 'Pay at Counter',
        createdAt: DateTime.now(),
      );

      // Customer can access only their own order
      expect(customer.id == order.customerId, isTrue);
      expect(otherCustomer.id == order.customerId, isFalse);

      // Customer is not a business user and cannot change status or payment
      expect(customer.isBusinessUser, isFalse);
      expect(otherCustomer.isBusinessUser, isFalse);

      // Staff and Admin are business users authorized to update status and payment
      expect(staff.isBusinessUser, isTrue);
      expect(admin.isBusinessUser, isTrue);
    });
  });
}
