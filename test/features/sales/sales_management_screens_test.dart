import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/sales/data/datasources/mock_sales_remote_datasource.dart';
import 'package:lambac_app/features/sales/data/repositories/sales_repository_impl.dart';
import 'package:lambac_app/features/sales/presentation/providers/sales_provider.dart';
import 'package:lambac_app/features/sales/presentation/screens/admin_sales_screen.dart';

void main() {
  late MockSalesRemoteDataSource remoteDataSource;
  late SalesRepositoryImpl repository;

  setUp(() {
    remoteDataSource = MockSalesRemoteDataSource();
    repository = SalesRepositoryImpl(remoteDataSource: remoteDataSource);
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        salesRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('AdminSalesScreen Widget Tests', () {
    testWidgets('AdminSalesScreen renders search bar, channel filter chips, and transaction log', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const AdminSalesScreen()));

      expect(find.text('Centralized Sales Ledger'), findsOneWidget);
      expect(find.text('All Transactions'), findsOneWidget);
      expect(find.text('Mobile App Pickups'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('TX-MOB-8092'), findsOneWidget);
    });
  });
}
