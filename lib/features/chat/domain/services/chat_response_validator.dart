/// Result of AI response validation
class ResponseValidationResult {
  final bool isValid;
  final String sanitizedResponse;
  final String? failureReason;

  const ResponseValidationResult({
    required this.isValid,
    required this.sanitizedResponse,
    this.failureReason,
  });

  factory ResponseValidationResult.valid(String text) => ResponseValidationResult(
        isValid: true,
        sanitizedResponse: text,
      );

  factory ResponseValidationResult.fallback(String fallbackMessage, String reason) =>
      ResponseValidationResult(
        isValid: false,
        sanitizedResponse: fallbackMessage,
        failureReason: reason,
      );
}

/// Output Guardrails & Safety Validator for Lambac AI Assistant
/// Validates AI responses before dispatch to customer to ensure safety, privacy, and truthfulness.
class ChatResponseValidator {
  const ChatResponseValidator();

  static const String safeFallbackMessage =
      'I can only assist with questions about Lambac Coffee Roastery, our specialty roasts, pickup orders, and store services. How can we help you with your coffee ritual today?';

  static const String humanHandoffMessage =
      'I want to make sure you get the exact and verified details. Let me direct this to our Barista and Roastery team for assistance.';

  // Leakage triggers for system prompts, models, internal instructions
  static final List<RegExp> _systemLeakagePatterns = [
    RegExp(r'\b(as an ai language model|as an ai|my system prompt|developer instructions|openai|anthropic|chatgpt|model weights)\b', caseSensitive: false),
    RegExp(r'\b(internal classification|token limit|my instructions are to)\b', caseSensitive: false),
  ];

  // Actions AI must never claim to have completed on its own
  static final List<RegExp> _actionHallucinationPatterns = [
    RegExp(r'\b(i have cancelled your order|i cancelled the order|i refunded your payment|i have updated your pickup schedule|i modified your order in our database)\b', caseSensitive: false),
  ];

  // PII / Credential leak checks
  static final List<RegExp> _sensitiveDataPatterns = [
    RegExp(r'\b(sk-[a-zA-Z0-9]{20,}|password123|api[_-]?key)\b', caseSensitive: false),
  ];

  /// Validates the generated response against business guardrails
  ResponseValidationResult validate({
    required String query,
    required String response,
    required bool wasScopeApproved,
  }) {
    // 1. If scope was rejected, enforce standard fallback
    if (!wasScopeApproved) {
      return ResponseValidationResult.fallback(
        safeFallbackMessage,
        'Scope validation was rejected for this query',
      );
    }

    final trimmed = response.trim();
    if (trimmed.isEmpty) {
      return ResponseValidationResult.fallback(
        humanHandoffMessage,
        'Generated response was empty',
      );
    }

    // 2. Prevent System Prompt / Model Instruction Leakage
    for (final pattern in _systemLeakagePatterns) {
      if (pattern.hasMatch(trimmed)) {
        return ResponseValidationResult.fallback(
          safeFallbackMessage,
          'Response contained system prompt or AI model leakage',
        );
      }
    }

    // 3. Prevent Action Hallucination (claiming order modifications not actually performed)
    for (final pattern in _actionHallucinationPatterns) {
      if (pattern.hasMatch(trimmed)) {
        return ResponseValidationResult.fallback(
          'For your security, order modifications must be confirmed directly with our counter staff. Our Barista team is notified and will assist you.',
          'Response claimed direct unauthorized database modification',
        );
      }
    }

    // 4. Prevent Sensitive Data / Secret Key Leakage
    for (final pattern in _sensitiveDataPatterns) {
      if (pattern.hasMatch(trimmed)) {
        return ResponseValidationResult.fallback(
          humanHandoffMessage,
          'Response contained potential sensitive credential data',
        );
      }
    }

    return ResponseValidationResult.valid(trimmed);
  }
}
