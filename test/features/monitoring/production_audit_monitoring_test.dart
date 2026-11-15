import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/security/audit_logger.dart';
import 'package:lambac_app/core/monitoring/operational_monitoring_service.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/features/orders/data/models/order_model.dart';

void main() {
  late AuditLogger auditLogger;
  late OperationalMonitoringService monitoringService;

  setUp(() {
    auditLogger = AuditLogger();
    auditLogger.clearForTest();
    monitoringService = OperationalMonitoringService();
    monitoringService.clearForTest();
  });

  group('Production Audit Trail & Operational Monitoring Suite', () {
    test('1. Privileged Business Actions generate comprehensive, structured audit records', () {
      // 1. Product price and availability changes
      auditLogger.log(
        action: AuditActionType.productPriceChanged,
        actorEmail: 'master.roaster@lambaccoffee.com',
        actorRole: 'admin',
        actorUid: 'usr_admin_001',
        entityId: 'prod_benguet_001',
        beforeState: {'name': 'Benguet Arabica', 'price': 450.0},
        afterState: {'name': 'Benguet Arabica', 'price': 480.0},
        details: 'Annual green coffee crop price adjustment',
      );

      auditLogger.log(
        action: AuditActionType.productAvailabilityChanged,
        actorEmail: 'barista.clara@lambaccoffee.com',
        actorRole: 'employee',
        actorUid: 'usr_staff_002',
        entityId: 'prod_coldbrew_002',
        beforeState: {'availability': 'available'},
        afterState: {'availability': 'outOfStock'},
        details: 'Batch sold out during morning rush',
      );

      // 2. Employee account creation and role/permissions change
      auditLogger.log(
        action: AuditActionType.employeeCreated,
        actorEmail: 'executive.admin@lambaccoffee.com',
        actorRole: 'admin',
        actorUid: 'usr_admin_001',
        targetEmail: 'new.barista@lambaccoffee.com',
        targetRole: 'employee',
        entityId: 'usr_staff_003',
        details: 'Onboarded new weekend shift barista',
      );

      auditLogger.log(
        action: AuditActionType.roleChanged,
        actorEmail: 'executive.admin@lambaccoffee.com',
        actorRole: 'admin',
        actorUid: 'usr_admin_001',
        targetEmail: 'new.barista@lambaccoffee.com',
        entityId: 'usr_staff_003',
        beforeState: {'role': 'customer'},
        afterState: {'role': 'employee', 'permissions': ['manageOrders', 'recordSales']},
      );

      // 3. Authorized order status change
      auditLogger.log(
        action: AuditActionType.orderStatusChanged,
        actorEmail: 'barista.clara@lambaccoffee.com',
        actorRole: 'employee',
        actorUid: 'usr_staff_002',
        entityId: 'ord_2026_0901',
        beforeState: {'status': OrderStatus.preparing.name},
        afterState: {'status': OrderStatus.readyForPickup.name},
        details: 'Order packaged and ready at pickup station',
      );

      // 4. POS walk-in sale completion and void correction
      auditLogger.log(
        action: AuditActionType.posSaleCompleted,
        actorEmail: 'barista.clara@lambaccoffee.com',
        actorRole: 'employee',
        actorUid: 'usr_staff_002',
        entityId: 'sale_2026_1001',
        afterState: {'total': 810.0, 'payment_method': 'GCash'},
        details: 'Counter checkout transaction completed',
      );

      auditLogger.log(
        action: AuditActionType.posSaleVoided,
        actorEmail: 'master.roaster@lambaccoffee.com',
        actorRole: 'admin',
        actorUid: 'usr_admin_001',
        entityId: 'sale_2026_1001',
        beforeState: {'is_voided': false},
        afterState: {'is_voided': true, 'void_reason': 'Accidental duplicate entry by cashier'},
        details: 'Admin authorized transaction void',
      );

      // 5. Inventory adjustment
      auditLogger.log(
        action: AuditActionType.inventoryAdjusted,
        actorEmail: 'master.roaster@lambaccoffee.com',
        actorRole: 'admin',
        actorUid: 'usr_admin_001',
        entityId: 'prod_benguet_001',
        beforeState: {'stock': 45},
        afterState: {'stock': 75},
        details: 'Received new 30kg roasted batch into inventory',
      );

      // Verify all 8 events are logged
      final logs = auditLogger.getLogs(limit: 50);
      expect(logs.length, equals(8));

      // Verify specific field properties
      final priceChangeLog = logs.firstWhere((l) => l.action == AuditActionType.productPriceChanged);
      expect(priceChangeLog.actorUid, equals('usr_admin_001'));
      expect(priceChangeLog.entityId, equals('prod_benguet_001'));
      expect(priceChangeLog.beforeState?['price'], equals(450.0));
      expect(priceChangeLog.afterState?['price'], equals(480.0));

      final orderStatusLog = logs.firstWhere((l) => l.action == AuditActionType.orderStatusChanged);
      expect(orderStatusLog.entityId, equals('ord_2026_0901'));
      expect(orderStatusLog.afterState?['status'], equals('readyForPickup'));
    });

    test('2. Secret & Sensitive Data Sanitization: Passwords, tokens, and OTPs are strictly redacted', () {
      auditLogger.log(
        action: AuditActionType.securityConfigChanged,
        actorEmail: 'admin@lambaccoffee.com',
        actorRole: 'admin',
        actorUid: 'usr_admin_001',
        beforeState: {
          'config_name': 'auth_settings',
          'password_policy': 'strict',
          'initial_password': 'SuperSecretPassword123!', // SENSITIVE
          'token_secret': 'jwt-super-secret-key-xyz',    // SENSITIVE
          'otp_code': '948201',                         // SENSITIVE
        },
        afterState: {
          'config_name': 'auth_settings',
          'private_key': 'BEGIN RSA PRIVATE KEY...',     // SENSITIVE
        },
        details: 'Updated auth settings with token=abc123secret and otp: 582910',
      );

      final logged = auditLogger.getLogs().first;

      // Passwords, tokens, OTPs, and private keys must be REDACTED
      expect(logged.beforeState?['initial_password'], equals('[REDACTED]'));
      expect(logged.beforeState?['token_secret'], equals('[REDACTED]'));
      expect(logged.beforeState?['otp_code'], equals('[REDACTED]'));
      expect(logged.afterState?['private_key'], equals('[REDACTED]'));

      // Non-sensitive keys remain intact
      expect(logged.beforeState?['config_name'], equals('auth_settings'));
      expect(logged.beforeState?['password_policy'], equals('strict'));

      // Details string sanitization
      expect(logged.details, isNot(contains('abc123secret')));
      expect(logged.details, isNot(contains('582910')));
      expect(logged.details, contains('[REDACTED]'));
    });

    test('3. Operational Monitoring: Domain failure reporting correctly categorizes expected vs unexpected failures', () {
      // 1. Expected validation error (e.g. invalid form field or 400 Bad Request)
      final valErr = monitoringService.reportFailure(
        domain: FailureDomain.orderCreation,
        error: const BadRequestFailure(message: 'Quantity must be at least 1'),
      );

      expect(valErr.isExpected, isTrue);
      expect(valErr.severity, equals(FailureSeverity.warning));
      expect(valErr.type, equals(FailureType.validationError));

      // 2. Expected authentication failure (e.g. invalid password)
      final authErr = monitoringService.reportFailure(
        domain: FailureDomain.authentication,
        error: const UnauthorizedFailure(message: 'Invalid email or password credentials'),
      );

      expect(authErr.isExpected, isTrue);
      expect(authErr.severity, equals(FailureSeverity.warning));

      // 3. Unexpected server error (e.g. 500 internal server failure)
      final serverErr = monitoringService.reportFailure(
        domain: FailureDomain.firestoreAccess,
        error: const ServerFailure(message: 'Firestore internal deadline exceeded', statusCode: 500),
      );

      expect(serverErr.isExpected, isFalse);
      expect(serverErr.severity, equals(FailureSeverity.error));
      expect(serverErr.type, equals(FailureType.serverError));

      // 4. Unexpected crash / unhandled exception
      final crashErr = monitoringService.reportFailure(
        domain: FailureDomain.applicationStartup,
        error: StateError('Uncaught null dereference during service provider initialization'),
      );

      expect(crashErr.isExpected, isFalse);
      expect(crashErr.severity, equals(FailureSeverity.critical));
      expect(crashErr.type, equals(FailureType.unexpectedCrash));
    });

    test('4. Operational Monitoring Deduplication: Rapid transient errors are debounced to prevent spam & cost inflation', () {
      const repeatedError = TimeoutFailure(message: 'Network connection timeout contacting payment service');

      // Simulate 5 rapid timeouts in a tight retry loop
      for (int i = 0; i < 5; i++) {
        monitoringService.reportFailure(
          domain: FailureDomain.checkout,
          error: repeatedError,
        );
      }

      // Buffer should only have ONE record with repeatCount = 5
      final recent = monitoringService.getRecentErrors(domain: FailureDomain.checkout);
      expect(recent.length, equals(1), reason: 'Rapid identical errors should be deduplicated into a single entry');
      expect(recent.first.repeatCount, equals(5));
    });

    test('5. Operational Alert Threshold: Triggers operational alert callback on burst of unexpected critical failures', () {
      String? receivedAlert;
      int criticalCounter = 0;

      monitoringService.onOperationalAlert = (alertMsg, count) {
        receivedAlert = alertMsg;
        criticalCounter = count;
      };

      // Generate 5 distinct unexpected server errors
      for (int i = 1; i <= 5; i++) {
        monitoringService.reportFailure(
          domain: FailureDomain.firestoreAccess,
          error: ServerFailure(message: 'Firestore connection dropped on transaction #$i', statusCode: 500),
        );
      }

      expect(receivedAlert, isNotNull);
      expect(receivedAlert, contains('OPERATIONAL ALERT'));
      expect(criticalCounter, greaterThanOrEqualTo(5));
    });

    test('6. Stack Trace & Error Message Sanitization: Sensitive tokens are scrubbed from diagnostic traces', () {
      const leakedTrace = '''
#0 ApiClient._dispatch (package:lambac_app/core/network/api_client.dart:45:12)
#1 HttpTransport.send (headers: Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI... token=secret_auth_token_999)
#2 main (file:///test.dart:12:3)
''';

      final reported = monitoringService.reportFailure(
        domain: FailureDomain.upload,
        error: const ServerFailure(message: 'Upload failed for auth=super_secret_session_token'),
        stackTrace: StackTrace.fromString(leakedTrace),
      );

      expect(reported.message, isNot(contains('super_secret_session_token')));
      expect(reported.message, contains('[REDACTED]'));

      expect(reported.stackTraceSanitized, isNot(contains('eyJhbGciOiJIUzI1NiIsInR5cCI')));
      expect(reported.stackTraceSanitized, isNot(contains('secret_auth_token_999')));
      expect(reported.stackTraceSanitized, contains('[REDACTED]'));
    });

    test('7. Filter & Diagnostic Querying: Administrator can query audit logs by entity ID or action for troubleshooting', () {
      auditLogger.log(
        action: AuditActionType.productPriceChanged,
        actorEmail: 'admin@lambac.com',
        actorRole: 'admin',
        entityId: 'prod_target_123',
        details: 'Price increase',
      );

      auditLogger.log(
        action: AuditActionType.productAvailabilityChanged,
        actorEmail: 'admin@lambac.com',
        actorRole: 'admin',
        entityId: 'prod_other_456',
        details: 'Stock depleted',
      );

      final filteredByEntity = auditLogger.getLogs(entityId: 'prod_target_123');
      expect(filteredByEntity.length, equals(1));
      expect(filteredByEntity.first.action, equals(AuditActionType.productPriceChanged));

      final filteredByAction = auditLogger.getLogs(action: AuditActionType.productAvailabilityChanged);
      expect(filteredByAction.length, equals(1));
      expect(filteredByAction.first.entityId, equals('prod_other_456'));
    });
  });
}
