import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Cryptographic Password Hashing & Verification Service
class PasswordHasher {
  PasswordHasher._();

  static const String _defaultPepper = 'lambac_coffee_roastery_pepper_key_2026';

  /// Hashes a plaintext password using SHA-256 with a unique cryptographic salt
  static String hashPassword(String password, {String? customSalt}) {
    final salt = customSalt ?? _generateRandomSalt();
    final combined = '$salt:$_defaultPepper:$password';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }

  /// Verifies whether a candidate plaintext password matches a stored hashed string
  static bool verifyPassword(String candidatePassword, String storedHash) {
    if (!storedHash.contains(':')) {
      // Legacy plaintext comparison fallback during seamless migration
      return candidatePassword == storedHash;
    }

    final parts = storedHash.split(':');
    if (parts.length < 2) return false;

    final salt = parts[0];
    final expectedHash = parts[1];

    final candidateCalculatedHash = hashPassword(candidatePassword, customSalt: salt);
    final candidateDigestOnly = candidateCalculatedHash.split(':')[1];

    return _constantTimeEquals(candidateDigestOnly, expectedHash);
  }

  /// Generates a random 16-byte hex salt
  static String _generateRandomSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Constant-time string equality comparison to protect against timing attacks
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Generates an 8-character high-entropy temporary password for initial user provisioning
  static String generateTemporaryPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%*';
    final random = Random.secure();
    return List.generate(10, (index) => chars[random.nextInt(chars.length)]).join();
  }
}
