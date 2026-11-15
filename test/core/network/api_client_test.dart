import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/core/network/result.dart';

void main() {
  group('Result Container Tests', () {
    test('Result.success holds data and isSuccess is true', () {
      const result = Result<String, AppFailure>.success('Mount Apo Roast');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, equals('Mount Apo Roast'));
      expect(result.failureOrNull, isNull);

      final mapped = result.map((data) => data.toUpperCase());
      expect(mapped.dataOrNull, equals('MOUNT APO ROAST'));
    });

    test('Result.failure holds AppFailure and isFailure is true', () {
      const failure = NetworkFailure(message: 'Connection timed out');
      const result = Result<String, AppFailure>.failure(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.failureOrNull, equals(failure));

      final value = result.when(
        success: (d) => 'got data: $d',
        failure: (f) => 'got failure: ${f.message}',
      );
      expect(value, equals('got failure: Connection timed out'));
    });
  });

  group('AppFailure Hierarchy Tests', () {
    test('ValidationFailure equality and field errors', () {
      const failure1 = ValidationFailure(
        message: 'Invalid email',
        statusCode: 422,
        fieldErrors: {'email': ['Invalid format']},
      );
      const failure2 = ValidationFailure(
        message: 'Invalid email',
        statusCode: 422,
        fieldErrors: {'email': ['Invalid format']},
      );

      expect(failure1, equals(failure2));
      expect(failure1.statusCode, equals(422));
    });

    test('ServerFailure and NetworkFailure equality', () {
      const serverFail = ServerFailure();
      expect(serverFail.statusCode, equals(500));
      expect(serverFail.errorCode, equals('SERVER_ERROR'));

      const netFail = NetworkFailure();
      expect(netFail.errorCode, equals('NETWORK_ERROR'));
    });
  });
}
