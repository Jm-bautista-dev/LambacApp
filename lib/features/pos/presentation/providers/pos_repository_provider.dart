import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/firebase_pos_remote_datasource.dart';
import '../../data/datasources/mock_pos_remote_datasource.dart';
import '../../data/datasources/pos_remote_datasource.dart';
import '../../data/repositories/pos_repository_impl.dart';
import '../../domain/repositories/pos_repository.dart';

/// Provider for POS Remote Data Source
final posRemoteDataSourceProvider = Provider<PosRemoteDataSource>((ref) {
  try {
    if (Firebase.apps.isEmpty) {
      return MockPosRemoteDataSource();
    }
  } catch (_) {
    return MockPosRemoteDataSource();
  }
  return FirebasePosRemoteDataSource();
});

/// Provider for Domain PosRepository
final posRepositoryProvider = Provider<PosRepository>((ref) {
  final remoteDataSource = ref.watch(posRemoteDataSourceProvider);
  return PosRepositoryImpl(remoteDataSource: remoteDataSource);
});
