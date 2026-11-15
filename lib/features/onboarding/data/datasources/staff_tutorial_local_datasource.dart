import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/storage_service.dart';

/// Contract for persisting Staff / Barista Tutorial & Guided Onboarding State
abstract class StaffTutorialLocalDataSource {
  Future<bool> isStaffTutorialCompleted();
  Future<void> markStaffTutorialCompleted({int version = 1});
  Future<void> resetStaffTutorial();
  Future<int?> getStaffTutorialVersion();
  Future<DateTime?> getLastCompletedAt();
}

/// Concrete implementation using StorageService
class StaffTutorialLocalDataSourceImpl implements StaffTutorialLocalDataSource {
  final StorageService _storageService;

  StaffTutorialLocalDataSourceImpl({required StorageService storageService})
      : _storageService = storageService;

  @override
  Future<bool> isStaffTutorialCompleted() async {
    final completed = await _storageService.getBool(AppConstants.staffTutorialCompletedKey);
    return completed ?? false;
  }

  @override
  Future<void> markStaffTutorialCompleted({int version = 1}) async {
    await _storageService.setBool(AppConstants.staffTutorialCompletedKey, true);
    await _storageService.setString(
      AppConstants.staffTutorialVersionKey,
      version.toString(),
    );
    await _storageService.setString(
      AppConstants.staffTutorialCompletedAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<void> resetStaffTutorial() async {
    await _storageService.remove(AppConstants.staffTutorialCompletedKey);
    await _storageService.remove(AppConstants.staffTutorialCompletedAtKey);
  }

  @override
  Future<int?> getStaffTutorialVersion() async {
    final val = await _storageService.getString(AppConstants.staffTutorialVersionKey);
    if (val == null) return null;
    return int.tryParse(val);
  }

  @override
  Future<DateTime?> getLastCompletedAt() async {
    final val = await _storageService.getString(AppConstants.staffTutorialCompletedAtKey);
    if (val == null) return null;
    return DateTime.tryParse(val);
  }
}
