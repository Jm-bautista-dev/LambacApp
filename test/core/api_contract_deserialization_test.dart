import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/core/errors/app_failure.dart';
import 'package:lambac_app/core/errors/error_handler.dart';
import 'package:lambac_app/core/network/api_response.dart';
import 'package:lambac_app/core/network/paginated_result.dart';

void main() {
  group('API Contract & Envelope Deserialization Unit Tests', () {
    test('ApiResponse parses standardized success envelope', () {
      final json = {
        'success': true,
        'data': {'id': 'prod_101', 'name': 'Mount Apo Anaerobic'},
        'message': 'Product retrieved successfully',
        'errors': null,
        'meta': {
          'page': 1,
          'limit': 20,
          'total_items': 1,
          'total_pages': 1,
        },
      };

      final response = ApiResponse.fromJson(json, (d) => d as Map<String, dynamic>);

      expect(response.success, isTrue);
      expect(response.message, equals('Product retrieved successfully'));
      expect(response.data!['name'], equals('Mount Apo Anaerobic'));
      expect(response.meta?.totalItems, equals(1));
    });

    test('PaginatedResult correctly calculates total pages and hasMore boolean', () {
      final json = {
        'items': [
          {'id': '1'},
          {'id': '2'},
        ],
        'page': 1,
        'limit': 2,
        'total_items': 10,
        'total_pages': 5,
      };

      final result = PaginatedResult.fromJson(json, (item) => item['id'].toString());

      expect(result.items.length, equals(2));
      expect(result.hasMore, isTrue);
      expect(result.totalPages, equals(5));
    });

    test('ErrorHandler maps HTTP status codes into specific AppFailure instances', () {
      final badRequest = ErrorHandler.handleException(
        const BadRequestFailure(message: 'Invalid payload'),
      );
      expect(badRequest, isA<BadRequestFailure>());

      final forbidden = ErrorHandler.handleException(
        const ForbiddenFailure(message: 'Admin access required'),
      );
      expect(forbidden, isA<ForbiddenFailure>());
      expect(forbidden.message, equals('Admin access required'));
    });
  });
}
