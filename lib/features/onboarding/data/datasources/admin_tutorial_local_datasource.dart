import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/storage_service.dart';

/// Local data source interface managing persistent state of the Admin Interactive Tutorial
abstract class AdminTutorialLocalDataSource {
  Future<bool> isAdminTutorialCompleted();
  Future<void> markAdminTutorialCompleted({int version = 1});
  Future<int?> getAdminTutorialVersion();
  Future<DateTime?> getLastCompletedAt();
  Future<void> resetAdminTutorial();
}

/// Production implementation backed by [StorageService]
class AdminTutorialLocalDataSourceImpl implements AdminTutorialLocalDataSource {
  final StorageService _storageService;

  AdminTutorialLocalDataSourceImpl({required StorageService storageService})
      : _storageService = storageService;

  @override
  Future<bool> isAdminTutorialCompleted() async {
    final completed = await _storageService.getBool(AppConstants.adminTutorialCompletedKey);
    return completed ?? false;
  }

  @override
  Future<void> markAdminTutorialCompleted({int version = 1}) async {
    await _storageService.setBool(AppConstants.adminTutorialCompletedKey, true);
    await _storageService.setString(
      AppConstants.adminTutorialVersionKey,
      version.toString(),
    );
    await _storageService.setString(
      AppConstants.adminTutorialCompletedAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<int?> getAdminTutorialVersion() async {
    final val = await _storageService.getString(AppConstants.adminTutorialVersionKey);
    if (val == null) return null;
    return int.tryParse(val);
  }

  @override
  Future<DateTime?> getLastCompletedAt() async {
    final raw = await _storageService.getString(AppConstants.adminTutorialCompletedAtKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Future<void> resetAdminTutorial() async {
    await _storageService.remove(AppConstants.adminTutorialCompletedKey);
    await _storageService.remove(AppConstants.adminTutorialVersionKey);
    await _storageService.remove(AppConstants.adminTutorialCompletedAtKey);
  }
}
