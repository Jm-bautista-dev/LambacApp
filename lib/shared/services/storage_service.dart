import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

/// Abstract storage service contract
abstract class StorageService {
  Future<void> setToken(String token);
  Future<String?> getToken();
  Future<void> setRefreshToken(String refreshToken);
  Future<String?> getRefreshToken();
  Future<void> clearAuthTokens();

  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
  Future<void> setBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<void> remove(String key);
  Future<void> clearAll();
}

/// Concrete implementation combining SecureStorage for tokens and SharedPreferences for preferences
class StorageServiceImpl implements StorageService {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences? _prefs;

  StorageServiceImpl({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? prefs,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _prefs = prefs;

  @override
  Future<void> setToken(String token) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
  }

  @override
  Future<String?> getToken() async {
    return _secureStorage.read(key: AppConstants.tokenKey);
  }

  @override
  Future<void> setRefreshToken(String refreshToken) async {
    await _secureStorage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  @override
  Future<void> clearAuthTokens() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    await _secureStorage.delete(key: AppConstants.userIdKey);
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Future<bool?> getBool(String key) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  @override
  Future<void> remove(String key) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(key);
    await _secureStorage.delete(key: key);
  }

  @override
  Future<void> clearAll() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.clear();
    await _secureStorage.deleteAll();
  }
}

/// InMemory Storage Service for tests and fallback
class InMemoryStorageService implements StorageService {
  final Map<String, String> _secureStore = {};
  final Map<String, dynamic> _prefsStore = {};

  @override
  Future<void> setToken(String token) async {
    _secureStore[AppConstants.tokenKey] = token;
  }

  @override
  Future<String?> getToken() async {
    return _secureStore[AppConstants.tokenKey];
  }

  @override
  Future<void> setRefreshToken(String refreshToken) async {
    _secureStore[AppConstants.refreshTokenKey] = refreshToken;
  }

  @override
  Future<String?> getRefreshToken() async {
    return _secureStore[AppConstants.refreshTokenKey];
  }

  @override
  Future<void> clearAuthTokens() async {
    _secureStore.remove(AppConstants.tokenKey);
    _secureStore.remove(AppConstants.refreshTokenKey);
    _secureStore.remove(AppConstants.userIdKey);
  }

  @override
  Future<void> setString(String key, String value) async {
    _prefsStore[key] = value;
  }

  @override
  Future<String?> getString(String key) async {
    return _prefsStore[key] as String?;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _prefsStore[key] = value;
  }

  @override
  Future<bool?> getBool(String key) async {
    return _prefsStore[key] as bool?;
  }

  @override
  Future<void> remove(String key) async {
    _prefsStore.remove(key);
    _secureStore.remove(key);
  }

  @override
  Future<void> clearAll() async {
    _prefsStore.clear();
    _secureStore.clear();
  }
}

/// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageServiceImpl();
});
