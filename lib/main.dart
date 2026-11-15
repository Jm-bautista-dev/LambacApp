import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/flavor_provider.dart';
import 'core/services/app_check_service.dart';
import 'features/prescriptive/data/datasources/firebase_prescriptive_remote_datasource.dart';
import 'features/products/data/datasources/firebase_product_remote_datasource.dart';
import 'features/sales/data/datasources/firebase_sales_remote_datasource.dart';
import 'firebase_options.dart';

/// Main Application Entry Point
Future<void> main() async {
  // Catch asynchronous errors in the root zone
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase Foundation
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize App Configuration from Environment
      final appConfig = AppConfig.fromEnvironment();

      // Initialize Firebase App Check immediately following core initialization
      // to ensure all downstream Firestore, Storage, and Auth calls carry valid attestation tokens
      await AppCheckService.initialize(
        webRecaptchaSiteKey: appConfig.webRecaptchaSiteKey,
      );

      // Preferred Device Orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Transparent Status Bar with Dark Icons by default
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      );

      // Ensure Firestore collections are initialized if empty
      unawaited(FirebaseProductRemoteDataSource().seedInitialCatalogIfEmpty());
      unawaited(FirebaseSalesRemoteDataSource().seedInitialSalesIfEmpty());
      unawaited(FirebasePrescriptiveRemoteDataSource().seedInitialRoastSchedulesIfEmpty());

      runApp(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(appConfig),
          ],
          child: const LambacApp(),
        ),
      );
    },
    (error, stackTrace) {
      developer.log(
        'Uncaught Root Error: $error',
        name: 'LambacApp.main',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
