/// Categories for customer query scope classification
enum ScopeCategory {
  coffeeAndProducts,
  pricingAndMenu,
  storeInfoAndHours,
  pickupAndScheduling,
  customerOrders,
  greetingsAndCourtesies,
  humanAssistanceRequest,
  outOfScope;

  bool get isInScope => this != ScopeCategory.outOfScope;
}

/// Result of scope validation evaluation
class ScopeValidationResult {
  final bool isWithinScope;
  final ScopeCategory category;
  final String? reason;

  const ScopeValidationResult({
    required this.isWithinScope,
    required this.category,
    this.reason,
  });

  factory ScopeValidationResult.inScope(ScopeCategory category, [String? reason]) {
    return ScopeValidationResult(
      isWithinScope: true,
      category: category,
      reason: reason,
    );
  }

  factory ScopeValidationResult.outOfScope(String reason) {
    return ScopeValidationResult(
      isWithinScope: false,
      category: ScopeCategory.outOfScope,
      reason: reason,
    );
  }
}

/// Strict Scope Validation Engine for Lambac Coffee Roastery Assistant
/// Enforces business boundaries and prevents answering non-Lambac general-purpose questions.
class ChatScopeValidator {
  const ChatScopeValidator();

  static final List<RegExp> _outOfScopePatterns = [
    // Politics & Government
    RegExp(r'\b(president|prime minister|senat(or|e)|congress|politics|election|marcos|duterte|biden|trump|putin|government)\b', caseSensitive: false),
    // Coding & Programming & Homework
    RegExp(r'\b(programming|program|java|python|javascript|c\+\+|c#|html|css|php|sql|algorithm|assignment|homework|write a script|debug|code for me|compile)\b', caseSensitive: false),
    // Science & Academic topics
    RegExp(r'\b(quantum|physics|relativity|calculus|photosynthesis|solar system|black hole|astronomy|thermodynamics)\b', caseSensitive: false),
    // General non-coffee tech & shopping
    RegExp(r'\b(laptop|macbook|iphone|android phone|graphics card|gpu|smartphone|sneakers|buy a car)\b', caseSensitive: false),
    // Weather & News
    RegExp(r'\b(weather tomorrow|typhoon forecast|rain today|current news|celebrity)\b', caseSensitive: false),
    // Hacking & Malicious actions
    RegExp(r'\b(hack|exploit|sql injection|bypass password|crack software|ddos|malware)\b', caseSensitive: false),
    // General entertainment & creative writing
    RegExp(r'\b(tell me a joke|write a poem|write a song|write an essay|riddle me)\b', caseSensitive: false),
  ];

  static final List<RegExp> _humanHandoffPatterns = [
    RegExp(r'\b(talk to (a )?human|speak to (a )?(human|person|agent|staff|barista|admin)|real person|human support|operator)\b', caseSensitive: false),
  ];

  static final List<RegExp> _pickupPatterns = [
    RegExp(r'\b(what time can i pick ?up|when can i pick ?up|can i pick ?up|pickup time|pick ?up time|pickup schedule|prepare|preparation|prep time|how long does (my )?order take|advance order|pay at counter)\b', caseSensitive: false),
    RegExp(r'\b(1 hour|3 hours|5 hours|tomorrow|today at|custom time)\b', caseSensitive: false),
    RegExp(r'\b(pick ?up|pick-up)\b', caseSensitive: false),
  ];

  static final List<RegExp> _orderPatterns = [
    RegExp(r'\b(my order status|order status|is my order|order #|order number|lmb-\d+|where is my order|cancel my order|change my order|order ready|ready for pickup|track order|tracking)\b', caseSensitive: false),
    RegExp(r'\b(what is my order|check my order)\b', caseSensitive: false),
  ];

  static final List<RegExp> _storeInfoPatterns = [
    RegExp(r'\b(where is|where are you|where are you located|where located|location|address|branch|session road|baguio|directions|store hours|operating hours|what time do you (open|close)|opening hours|are you open)\b', caseSensitive: false),
    RegExp(r'\b(phone number|contact info|contact number)\b', caseSensitive: false),
  ];

  static final List<RegExp> _pricingPatterns = [
    RegExp(r'\b(price|how much|cost|pricing|pesos|php|expensive|cheapest|how much is)\b', caseSensitive: false),
  ];

  static final List<RegExp> _coffeePatterns = [
    RegExp(r'\b(coffee|espresso|latte|cappuccino|americano|cold brew|pourover|pour-over|v60|anaerobic|honey|typica|geisha|bourbon|peaberry|roast|roastery|beans|whole bean|grind|grinder|tasting notes|flavor|flavour|single origin|blend|decaf|drip bag|micro-lot|kissaten|arabica|brew|brewing|aeropress|french press)\b', caseSensitive: false),
    RegExp(r'\b(what do you sell|do you sell|do you have|do you serve|what drinks|drinks menu|drink options|what products|products you offer|recommend a drink|recommend coffee)\b', caseSensitive: false),
    RegExp(r'\b(tea|matcha|cheesecake|pastry|pastries|cake|croissant|dessert|snack|food)\b', caseSensitive: false),
  ];

  static final List<RegExp> _greetingPatterns = [
    RegExp(r'^(hi|hello|hey|konnichiwa|good (morning|afternoon|evening)|salamat|thank you|thanks|bye|goodbye|how are you)[\s.!]*$', caseSensitive: false),
  ];

  /// Validates whether a message is within the supported Lambac business scope
  ScopeValidationResult validateScope(String message) {
    final text = message.trim();
    if (text.isEmpty) {
      return ScopeValidationResult.inScope(ScopeCategory.greetingsAndCourtesies, 'Empty prompt');
    }

    // 1. Explicit Human Handoff Request takes immediate priority
    for (final pattern in _humanHandoffPatterns) {
      if (pattern.hasMatch(text)) {
        return ScopeValidationResult.inScope(ScopeCategory.humanAssistanceRequest, 'Human handoff requested');
      }
    }

    // 2. Check for Prohibited / Out-of-Scope triggers
    for (final pattern in _outOfScopePatterns) {
      if (pattern.hasMatch(text)) {
        // Exception: if someone asks about coffee physics or roast temperature, coffee takes precedence only if explicitly coffee-specific
        final isCoffeeRelated = _coffeePatterns.any((p) => p.hasMatch(text)) || _orderPatterns.any((p) => p.hasMatch(text));
        final isExplicitProgrammingOrPolitics = text.toLowerCase().contains('president') ||
            text.toLowerCase().contains('programming') ||
            text.toLowerCase().contains('java program') ||
            text.toLowerCase().contains('joke') ||
            text.toLowerCase().contains('weather');

        if (!isCoffeeRelated || isExplicitProgrammingOrPolitics) {
          return ScopeValidationResult.outOfScope('Query belongs to unsupported domain');
        }
      }
    }

    // 3. In-Scope Domain Matchers
    // Pickup and scheduling takes precedence when customer is asking about scheduling rules
    for (final pattern in _pickupPatterns) {
      if (pattern.hasMatch(text)) {
        return ScopeValidationResult.inScope(ScopeCategory.pickupAndScheduling, 'Pickup scheduling');
      }
    }

    for (final pattern in _orderPatterns) {
      if (pattern.hasMatch(text)) {
        return ScopeValidationResult.inScope(ScopeCategory.customerOrders, 'Order inquiry');
      }
    }

    for (final pattern in _storeInfoPatterns) {
      if (pattern.hasMatch(text)) {
        return ScopeValidationResult.inScope(ScopeCategory.storeInfoAndHours, 'Store information');
      }
    }

    for (final pattern in _pricingPatterns) {
      if (pattern.hasMatch(text)) {
        return ScopeValidationResult.inScope(ScopeCategory.pricingAndMenu, 'Pricing inquiry');
      }
    }

    for (final pattern in _coffeePatterns) {
      if (pattern.hasMatch(text)) {
        return ScopeValidationResult.inScope(ScopeCategory.coffeeAndProducts, 'Coffee and roasts');
      }
    }

    for (final pattern in _greetingPatterns) {
      if (pattern.hasMatch(text)) {
        return ScopeValidationResult.inScope(ScopeCategory.greetingsAndCourtesies, 'Greeting/courtesy');
      }
    }

    // Fallback: Check if message contains general coffee-roastery terminology
    final lower = text.toLowerCase();
    if (lower.contains('coffee') ||
        lower.contains('lambac') ||
        lower.contains('roastery') ||
        lower.contains('order') ||
        lower.contains('drink') ||
        lower.contains('cup') ||
        lower.contains('menu') ||
        lower.contains('bean')) {
      return ScopeValidationResult.inScope(ScopeCategory.coffeeAndProducts, 'General Lambac domain');
    }

    // If query has no connection to Lambac roastery operations, safely mark out-of-scope
    return ScopeValidationResult.outOfScope('Unrelated to Lambac Coffee Roastery');
  }
}
