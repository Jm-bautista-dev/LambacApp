/// Password Strength Evaluation Result
class PasswordStrength {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecialChar;
  final int score;
  final String label;

  const PasswordStrength({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecialChar,
    required this.score,
    required this.label,
  });

  bool get isPolicySatisfied => hasMinLength && hasUppercase && hasLowercase && hasNumber;
}

/// Standardized Form Input Validators with Robust Business & Security Rules
class Validators {
  Validators._();

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phoneRegExp = RegExp(
    r'^(09|\+639)\d{9}$',
  );

  static final RegExp _nameRegExp = RegExp(
    r"^[a-zA-Z\u00C0-\u024F\u1E00-\u1EFF\s'\-\.]+$",
  );

  /// Validates full name with international and accented character support
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Full name must be at least 2 characters';
    }
    if (trimmed.length > 100) {
      return 'Full name cannot exceed 100 characters';
    }
    if (!_nameRegExp.hasMatch(trimmed)) {
      return 'Full name contains invalid characters';
    }
    return null;
  }

  /// Validates required fields
  static String? required(String? value, [String message = 'This field is required']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  /// Validates email address format and length constraints
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    final trimmed = value.trim();
    if (trimmed.length > 254) {
      return 'Email address cannot exceed 254 characters';
    }
    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates login password non-emptiness
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  /// Validates registration password policy (Min 8 chars, uppercase, lowercase, number)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (value.length > 128) {
      return 'Password cannot exceed 128 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter (A-Z)';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter (a-z)';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number (0-9)';
    }
    return null;
  }

  /// Evaluates dynamic password strength for real-time visual feedback
  static PasswordStrength evaluatePassword(String password) {
    if (password.isEmpty) {
      return const PasswordStrength(
        hasMinLength: false,
        hasUppercase: false,
        hasLowercase: false,
        hasNumber: false,
        hasSpecialChar: false,
        score: 0,
        label: 'Empty',
      );
    }

    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>\-_]'));

    int score = 0;
    if (hasMinLength) score++;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    if (hasNumber) score++;
    if (hasSpecialChar || password.length >= 12) score++;

    final label = switch (score) {
      0 || 1 => 'Weak',
      2 || 3 => 'Fair',
      4 => 'Strong',
      _ => 'Very Strong',
    };

    return PasswordStrength(
      hasMinLength: hasMinLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasNumber: hasNumber,
      hasSpecialChar: hasSpecialChar,
      score: score,
      label: label,
    );
  }

  /// Validates phone number (Philippine format: 09XXXXXXXXX or +639XXXXXXXXX)
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your mobile number';
    }
    final clean = value.replaceAll(RegExp(r'[\s-]'), '');
    if (!_phoneRegExp.hasMatch(clean)) {
      return 'Please enter a valid mobile number (e.g. 09123456789)';
    }
    return null;
  }

  /// Validates confirmation password match
  static String? confirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates product name (2-120 chars)
  static String? productName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter product name';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Product name must be at least 2 characters';
    }
    if (trimmed.length > 120) {
      return 'Product name cannot exceed 120 characters';
    }
    return null;
  }

  /// Validates product/line-item price (positive number <= 50,000)
  static String? price(String? value, {double min = 0.01, double max = 50000.0, String fieldName = 'Price'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      return '$fieldName must be a valid number';
    }
    if (parsed < 0) {
      return '$fieldName cannot be negative';
    }
    if (parsed < min) {
      return '$fieldName must be at least ₱${min.toStringAsFixed(2)}';
    }
    if (parsed > max) {
      return '$fieldName cannot exceed ₱$max';
    }
    return null;
  }

  /// Validates inventory stock quantity (non-negative integer <= 1,000,000)
  static String? stock(String? value, {int min = 0, int max = 1000000, String fieldName = 'Stock quantity'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return '$fieldName must be a valid whole number';
    }
    if (parsed < min) {
      return '$fieldName cannot be negative';
    }
    if (parsed > max) {
      return '$fieldName cannot exceed $max';
    }
    return null;
  }

  /// Validates review comment (min 3 chars, max 1000 chars)
  static String? reviewComment(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please share your tasting feedback';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Review comment must be at least 3 characters';
    }
    if (trimmed.length > 1000) {
      return 'Review comment cannot exceed 1000 characters';
    }
    return null;
  }

  /// Validates chat message (non-empty, max 2000 chars)
  static String? chatMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Cannot send an empty message';
    }
    final trimmed = value.trim();
    if (trimmed.length > 2000) {
      return 'Message cannot exceed 2000 characters';
    }
    return null;
  }

  /// Validates order notes (optional, max 500 chars)
  static String? orderNotes(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.length > 500) {
      return 'Order notes cannot exceed 500 characters';
    }
    return null;
  }

  /// Validates maximum string length
  static String? Function(String?) maxLength(int max, [String? fieldName]) {
    return (String? value) {
      if (value == null) return null;
      if (value.trim().length > max) {
        final prefix = fieldName != null ? '$fieldName cannot' : 'Cannot';
        return '$prefix exceed $max characters';
      }
      return null;
    };
  }

  /// Validates minimum string length
  static String? Function(String?) minLength(int min, [String? fieldName]) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return null;
      if (value.trim().length < min) {
        final prefix = fieldName != null ? '$fieldName must' : 'Must';
        return '$prefix be at least $min characters';
      }
      return null;
    };
  }
}
