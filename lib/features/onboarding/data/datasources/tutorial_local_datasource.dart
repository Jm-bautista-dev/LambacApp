import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/storage_service.dart';

/// Contract for persisting Customer Tutorial & Guided Onboarding State
abstract class TutorialLocalDataSource {
  Future<bool> isTutorialCompleted();
  Future<void> markTutorialCompleted({int version = 1});
  Future<void> resetTutorial();
  Future<int?> getTutorialVersion();
  Future<DateTime?> getLastCompletedAt();
}

/// Concrete implementation of TutorialLocalDataSource using StorageService
class TutorialLocalDataSourceImpl implements TutorialLocalDataSource {
  final StorageService _storageService;

  TutorialLocalDataSourceImpl({required StorageService storageService})
      : _storageService = storageService;

  @override
  Future<bool> isTutorialCompleted() async {
    final completed = await _storageService.getBool(AppConstants.customerTutorialCompletedKey);
    return completed ?? false;
  }

  @override
  Future<void> markTutorialCompleted({int version = 1}) async {
    await _storageService.setBool(AppConstants.customerTutorialCompletedKey, true);
    await _storageService.setBool(AppConstants.onboardingSeenKey, true);
    await _storageService.setString(
      AppConstants.customerTutorialVersionKey,
      version.toString(),
    );
    await _storageService.setString(
      AppConstants.customerTutorialCompletedAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<void> resetTutorial() async {
    await _storageService.remove(AppConstants.customerTutorialCompletedKey);
    await _storageService.remove(AppConstants.customerTutorialCompletedAtKey);
  }

  @override
  Future<int?> getTutorialVersion() async {
    final val = await _storageService.getString(AppConstants.customerTutorialVersionKey);
    if (val == null) return null;
    return int.tryParse(val);
  }

  @override
  Future<DateTime?> getLastCompletedAt() async {
    final val = await _storageService.getString(AppConstants.customerTutorialCompletedAtKey);
    if (val == null) return null;
    return DateTime.tryParse(val);
  }
}
