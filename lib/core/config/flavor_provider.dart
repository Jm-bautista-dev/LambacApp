import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_config.dart';

/// Active Application Configuration Provider
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

/// Current Environment Provider
final environmentProvider = Provider<Environment>((ref) {
  return ref.watch(appConfigProvider).environment;
});
