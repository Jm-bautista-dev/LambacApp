import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../data/datasources/mock_order_remote_datasource.dart';
import '../../data/models/first_order_eligibility_model.dart';
import '../../data/models/order_model.dart';

/// Signature for injectable URL launcher used by [PaymongoService]
typedef PaymongoUrlLauncher = Future<bool> Function(
  Uri uri, {
  LaunchMode mode,
  String? webOnlyWindowName,
});

/// Response payload from creating a PayMongo checkout session
class PaymongoCheckoutResponse {
  final String orderId;
  final String orderNumber;
  final String checkoutSessionId;
  final String checkoutUrl;
  final double amount;
  final String currency;
  final String paymentMethod;
  final bool reusedExistingSession;

  const PaymongoCheckoutResponse({
    required this.orderId,
    required this.orderNumber,
    required this.checkoutSessionId,
    required this.checkoutUrl,
    required this.amount,
    this.currency = 'PHP',
    this.paymentMethod = 'GCash',
    this.reusedExistingSession = false,
  });

  factory PaymongoCheckoutResponse.fromJson(Map<String, dynamic> json) {
    return PaymongoCheckoutResponse(
      orderId: json['orderId']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      checkoutSessionId: json['checkoutSessionId']?.toString() ?? '',
      checkoutUrl: json['checkoutUrl']?.toString() ?? '',
      amount: ((json['amount'] ?? 0.0) as num).toDouble(),
      currency: json['currency']?.toString() ?? 'PHP',
      paymentMethod: json['paymentMethod']?.toString() ?? 'GCash',
      reusedExistingSession: json['reusedExistingSession'] == true,
    );
  }
}

/// Production PayMongo GCash Service
/// Connects to the standalone Node.js Express PayMongo backend (compatible with Firebase Spark)
/// to manage PayMongo Checkout Sessions, first-order GCash enforcement, and payment verification.
class PaymongoService {
  /// Configurable via `--dart-define=PAYMONGO_BACKEND_URL=https://your-backend-host.onrender.com/api`
  static const String _configuredBackendUrl = String.fromEnvironment(
    'PAYMONGO_BACKEND_URL',
    defaultValue: 'https://lambac-paymongo-backend.onrender.com/api',
  );

  static const bool _hasExplicitBackendUrlDefine = bool.hasEnvironment('PAYMONGO_BACKEND_URL');

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final Dio _dio;
  final bool _hasCustomDio;
  final String _backendBaseUrl;
  final bool _allowLocalDevFallback;
  final PaymongoUrlLauncher? _urlLauncher;
  final bool? _isWebOverride;

  /// Guards against duplicate concurrent checkout session requests for the same orderId
  final Map<String, Future<Result<PaymongoCheckoutResponse, AppFailure>>> _inFlightCheckouts = {};

  /// Caches the most recently verified reachable candidate URL in this session
  String? _verifiedWorkingBaseUrl;

  PaymongoService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    Dio? dio,
    String? backendBaseUrl,
    bool? allowLocalDevFallback,
    PaymongoUrlLauncher? urlLauncher,
    bool? isWebOverride,
  })  : _auth = auth ?? _resolveAuth(),
        _firestore = firestore ?? _resolveFirestore(),
        _hasCustomDio = dio != null,
        _dio = dio ??
            Dio(
              BaseOptions(
                // Extended timeouts to tolerate free-tier Node.js host cold starts (30-45s)
                connectTimeout: const Duration(seconds: 45),
                receiveTimeout: const Duration(seconds: 45),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ),
        _backendBaseUrl = _normalizeBaseUrl(
          backendBaseUrl ?? _resolveBackendBaseUrl(),
        ),
        _allowLocalDevFallback = allowLocalDevFallback ??
            (backendBaseUrl == null && !_hasExplicitBackendUrlDefine && kDebugMode),
        _urlLauncher = urlLauncher,
        _isWebOverride = isWebOverride;

  /// Exposed for diagnostics and testing
  String get backendBaseUrl => _backendBaseUrl;

  static FirebaseAuth? _resolveAuth() {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseAuth.instance;
    } catch (_) {}
    return null;
  }

  static FirebaseFirestore? _resolveFirestore() {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return 'https://lambac-paymongo-backend.onrender.com/api';
    }
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static String _resolveBackendBaseUrl() {
    return _normalizeBaseUrl(_configuredBackendUrl);
  }

  static String _resolveLocalDevBackendUrl() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  /// Candidate backend base URLs in priority order (verified reachable URL first, then primary configured URL, plus local dev server in debug mode if primary is unreachable)
  List<String> _candidateBaseUrls() {
    final urls = <String>[];
    if (_verifiedWorkingBaseUrl != null && _verifiedWorkingBaseUrl!.isNotEmpty) {
      urls.add(_verifiedWorkingBaseUrl!);
    }
    if (!urls.contains(_backendBaseUrl)) {
      urls.add(_backendBaseUrl);
    }
    if (_allowLocalDevFallback) {
      final localUrl = _resolveLocalDevBackendUrl();
      if (!urls.contains(localUrl)) {
        urls.add(localUrl);
      }
    }
    return urls;
  }

  bool _isUnreachableOrGatewayError(DioException err) {
    final status = err.response?.statusCode;
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.unknown) {
      return true;
    }
    // 404 with no JSON error body (e.g. un-deployed Render route) or 502/503/504 cold-start gateway errors
    if (status == 502 || status == 503 || status == 504) {
      return true;
    }
    if (status == 404 && err.response?.data is! Map) {
      return true;
    }
    return false;
  }

  /// Maps DioExceptions into understandable, non-technical customer error messages
  ServerFailure _mapDioFailure(DioException dioErr, {required String fallbackMessage}) {
    final status = dioErr.response?.statusCode;
    final errData = dioErr.response?.data;

    if (errData is Map) {
      final serverMsg = errData['message']?.toString().trim();
      final errorCode = errData['error']?.toString().trim();
      if (errorCode == 'PaymongoNotConfigured' || errorCode == 'FirebaseCredentialsNotConfigured') {
        return const ServerFailure(
          message: 'Online GCash payment gateway is temporarily undergoing configuration. Your order is saved—please try again shortly.',
          statusCode: 503,
        );
      }
      if (serverMsg != null && serverMsg.isNotEmpty) {
        return ServerFailure(message: serverMsg, statusCode: status);
      }
    }

    if (status == 401) {
      return const ServerFailure(
        message: 'Your session expired. Please sign in again to continue with GCash payment.',
        statusCode: 401,
      );
    }

    if (_isUnreachableOrGatewayError(dioErr)) {
      return ServerFailure(
        message: 'Unable to reach the GCash payment server right now (it may be waking up). Your order is safely saved—please tap "Retry GCash Payment" in a few seconds.',
        statusCode: status,
      );
    }

    return ServerFailure(message: fallbackMessage, statusCode: status);
  }

  /// Ping the standalone backend `/health` endpoint (also useful to warm up a sleeping free-tier instance)
  Future<Result<Map<String, dynamic>, AppFailure>> checkBackendHealth() async {
    if (_auth == null && !_hasCustomDio) {
      return const Result.success({'status': 'ok', 'mode': 'mock'});
    }

    DioException? lastDioErr;
    for (final baseUrl in _candidateBaseUrls()) {
      try {
        final response = await _dio.get<Map<String, dynamic>>('$baseUrl/health');
        if (response.statusCode == 200 && response.data != null) {
          _verifiedWorkingBaseUrl = baseUrl;
          return Result.success(Map<String, dynamic>.from(response.data!));
        }
      } on DioException catch (e) {
        lastDioErr = e;
        if (!_isUnreachableOrGatewayError(e)) break;
      } catch (_) {}
    }

    if (lastDioErr != null) {
      return Result.failure(
        _mapDioFailure(
          lastDioErr,
          fallbackMessage: 'The GCash payment service is currently unavailable.',
        ),
      );
    }

    return const Result.failure(
      ServerFailure(message: 'The GCash payment service is currently unavailable.'),
    );
  }

  /// Evaluate first-order GCash eligibility via backend
  Future<Result<FirstOrderEligibility, AppFailure>> checkFirstOrderEligibility() async {
    final auth = _auth;
    if (auth == null) {
      return MockOrderRemoteDataSource().checkFirstOrderEligibility();
    }

    final user = auth.currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to verify payment eligibility.'),
      );
    }

    try {
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        return const Result.failure(
          UnauthorizedFailure(message: 'Unable to verify your login session. Please sign in again.'),
        );
      }

      for (final baseUrl in _candidateBaseUrls()) {
        try {
          final response = await _dio.get<Map<String, dynamic>>(
            '$baseUrl/first-order-eligibility',
            options: Options(
              headers: {
                'Authorization': 'Bearer $idToken',
              },
            ),
          );

          if (response.statusCode == 200 && response.data != null) {
            _verifiedWorkingBaseUrl = baseUrl;
            return Result.success(FirstOrderEligibility.fromJson(response.data!));
          }
        } on DioException catch (e) {
          if (!_isUnreachableOrGatewayError(e)) break;
        }
      }

      return const Result.failure(
        ServerFailure(message: 'Unable to verify payment eligibility from the server.'),
      );
    } catch (_) {
      return MockOrderRemoteDataSource().checkFirstOrderEligibility();
    }
  }

  /// Request the secure backend to create a PayMongo Checkout Session for GCash.
  /// Prevents duplicate concurrent requests for the same [orderId].
  Future<Result<PaymongoCheckoutResponse, AppFailure>> createCheckoutSession(
    String orderId, {
    bool forceNew = false,
  }) async {
    final trimmedOrderId = orderId.trim();
    if (trimmedOrderId.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'A valid order ID is required to start GCash payment.'),
      );
    }

    // Deduplicate concurrent in-flight checkout session requests for the same order
    final existingInFlight = _inFlightCheckouts[trimmedOrderId];
    if (existingInFlight != null) {
      return existingInFlight;
    }

    final future = _createCheckoutSessionInternal(trimmedOrderId, forceNew: forceNew);
    _inFlightCheckouts[trimmedOrderId] = future;
    try {
      return await future;
    } finally {
      _inFlightCheckouts.remove(trimmedOrderId);
    }
  }

  Future<Result<PaymongoCheckoutResponse, AppFailure>> _createCheckoutSessionInternal(
    String orderId, {
    required bool forceNew,
  }) async {
    final auth = _auth;
    if (auth == null) {
      final mockResult = await MockOrderRemoteDataSource().createPaymongoCheckoutSession(orderId);
      return mockResult.when(
        success: (order) => Result.success(
          PaymongoCheckoutResponse(
            orderId: order.id,
            orderNumber: order.orderNumber,
            checkoutSessionId: order.paymentReference ?? 'cs_lmb_${order.id}',
            checkoutUrl: order.checkoutUrl ?? 'https://checkout.paymongo.com/cs_lmb_${order.id}',
            amount: order.totalAmount,
          ),
        ),
        failure: (f) => Result.failure(f),
      );
    }

    final user = auth.currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Please sign in to proceed with GCash payment.'),
      );
    }

    try {
      String? idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        idToken = await user.getIdToken(true);
      }
      if (idToken == null || idToken.isEmpty) {
        return const Result.failure(
          UnauthorizedFailure(message: 'Unable to verify your login session. Please sign in again.'),
        );
      }

      DioException? lastDioErr;
      final candidates = _candidateBaseUrls();

      for (var i = 0; i < candidates.length; i++) {
        final baseUrl = candidates[i];
        final url = '$baseUrl/create-checkout-session';

        for (var attempt = 0; attempt < 2; attempt++) {
          try {
            final response = await _dio.post<Map<String, dynamic>>(
              url,
              data: {
                'orderId': orderId,
                if (forceNew) 'forceNew': true,
              },
              options: Options(
                headers: {
                  'Authorization': 'Bearer $idToken',
                },
              ),
            );

            if (response.statusCode == 200 && response.data != null) {
              _verifiedWorkingBaseUrl = baseUrl;
              final data = response.data!;
              final checkoutResponse = PaymongoCheckoutResponse.fromJson(data);
              if (checkoutResponse.checkoutUrl.isEmpty ||
                  !checkoutResponse.checkoutUrl.startsWith('https://')) {
                return const Result.failure(
                  ServerFailure(
                    message: 'Received an invalid GCash checkout link from the payment server. Please try again.',
                  ),
                );
              }
              return Result.success(checkoutResponse);
            }
          } on DioException catch (dioErr) {
            lastDioErr = dioErr;
            // If token expired (401) on first attempt, force-refresh Firebase ID token and retry once
            if (dioErr.response?.statusCode == 401 && attempt == 0) {
              idToken = await user.getIdToken(true);
              if (idToken != null && idToken.isNotEmpty) {
                continue;
              }
            }
            // If business validation error (400, 403, 404 with JSON body, 409), return immediately without retrying
            if (!_isUnreachableOrGatewayError(dioErr)) {
              return Result.failure(
                _mapDioFailure(
                  dioErr,
                  fallbackMessage: 'Unable to initiate GCash checkout. Please try again.',
                ),
              );
            }
            // Break inner attempt loop to try next candidate URL if available
            break;
          }
        }
      }

      if (lastDioErr != null) {
        return Result.failure(
          _mapDioFailure(
            lastDioErr,
            fallbackMessage: 'Unable to initiate GCash checkout. Please try again.',
          ),
        );
      }

      return const Result.failure(
        ServerFailure(message: 'Unable to initiate GCash checkout. Please try again.'),
      );
    } catch (_) {
      return const Result.failure(
        ServerFailure(
          message: 'Unable to connect to the GCash payment gateway right now. Please try again.',
        ),
      );
    }
  }

  /// Launch the PayMongo hosted checkout URL with platform-appropriate navigation:
  /// - On Flutter Web: attempts new tab (`_blank`) first and falls back to same-tab (`_self`)
  ///   when the browser blocks popups after an async network call.
  /// - On Android/iOS: opens in external browser/app (`LaunchMode.externalApplication`) and falls back
  ///   to `LaunchMode.platformDefault`.
  Future<Result<bool, AppFailure>> launchCheckoutUrl(String checkoutUrl) async {
    final trimmed = checkoutUrl.trim();
    if (trimmed.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'GCash checkout link is missing. Please tap "Retry GCash Payment".'),
      );
    }

    final Uri? uri = Uri.tryParse(trimmed);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http') || uri.host.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Invalid GCash checkout link received. Please tap "Retry GCash Payment".'),
      );
    }

    final launcher = _urlLauncher ??
        (Uri targetUri, {LaunchMode mode = LaunchMode.platformDefault, String? webOnlyWindowName}) {
          return launchUrl(
            targetUri,
            mode: mode,
            webOnlyWindowName: webOnlyWindowName,
          );
        };

    final isWebPlatform = _isWebOverride ?? kIsWeb;

    try {
      if (isWebPlatform) {
        // 1. Try opening in a new tab (_blank); if blocked by browser popup blocker after async call,
        //    immediately fall back to same-window navigation (_self).
        final openedBlank = await launcher(
          uri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
        if (openedBlank) {
          return const Result.success(true);
        }

        final openedSelf = await launcher(
          uri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_self',
        );
        if (openedSelf) {
          return const Result.success(true);
        }

        return const Result.failure(
          ServerFailure(
            message: 'Your browser blocked the GCash checkout window. Please tap "Open GCash Checkout" to continue.',
          ),
        );
      }

      // Mobile / Desktop native platforms
      final openedExternal = await launcher(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (openedExternal) {
        return const Result.success(true);
      }

      final openedDefault = await launcher(
        uri,
        mode: LaunchMode.platformDefault,
      );
      if (openedDefault) {
        return const Result.success(true);
      }

      return const Result.failure(
        ServerFailure(
          message: 'Could not open the GCash payment page. Please tap "Open GCash Checkout" to try again.',
        ),
      );
    } catch (_) {
      return const Result.failure(
        ServerFailure(
          message: 'Could not open the GCash payment page. Please tap "Open GCash Checkout" to try again.',
        ),
      );
    }
  }

  /// Verify payment status via backend
  Future<Result<Map<String, dynamic>, AppFailure>> verifyPaymentSession(
    String orderId, {
    String? checkoutSessionId,
  }) async {
    final auth = _auth;
    if (auth == null) {
      final orderResult = await MockOrderRemoteDataSource().getOrderById(orderId);
      return orderResult.when(
        success: (order) => Result.success({
          'orderId': order.id,
          'paymentStatus': order.paymentStatus,
          'verified': order.isPaid,
          'firstOrderGcashCompleted': order.isPaid,
        }),
        failure: (f) => Result.failure(f),
      );
    }

    final user = auth.currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Please sign in to verify your payment status.'),
      );
    }

    try {
      String? idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        idToken = await user.getIdToken(true);
      }

      DioException? lastDioErr;
      for (final baseUrl in _candidateBaseUrls()) {
        try {
          final response = await _dio.post<Map<String, dynamic>>(
            '$baseUrl/verify-payment-session',
            data: {
              'orderId': orderId,
              if (checkoutSessionId != null) 'checkoutSessionId': checkoutSessionId,
            },
            options: Options(
              headers: {
                'Authorization': 'Bearer $idToken',
              },
            ),
          );

          if (response.statusCode == 200 && response.data != null) {
            _verifiedWorkingBaseUrl = baseUrl;
            return Result.success(Map<String, dynamic>.from(response.data as Map));
          }
        } on DioException catch (dioErr) {
          lastDioErr = dioErr;
          if (!_isUnreachableOrGatewayError(dioErr)) {
            return Result.failure(
              _mapDioFailure(
                dioErr,
                fallbackMessage: 'Unable to verify payment status right now. Please try again.',
              ),
            );
          }
        }
      }

      if (lastDioErr != null) {
        return Result.failure(
          _mapDioFailure(
            lastDioErr,
            fallbackMessage: 'Unable to verify payment status right now. Please try again.',
          ),
        );
      }

      return const Result.failure(
        ServerFailure(message: 'Unable to verify payment status right now. Please try again.'),
      );
    } catch (_) {
      return const Result.failure(
        ServerFailure(message: 'Unable to verify payment status right now. Please try again.'),
      );
    }
  }

  /// Live Firestore Stream watching payment status updates for an order
  Stream<OrderModel?> watchOrderPayment(String orderId) {
    final firestore = _firestore;
    if (firestore == null) {
      return const Stream.empty();
    }
    try {
      if (Firebase.apps.isEmpty) {
        return const Stream.empty();
      }
    } catch (_) {
      return const Stream.empty();
    }
    return firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      final rawData = snap.data() ?? {};
      final map = Map<String, dynamic>.from(rawData);
      map['id'] = snap.id;
      if (map['created_at'] is Timestamp) {
        map['created_at'] = (map['created_at'] as Timestamp).toDate().toIso8601String();
      }
      if (map['paid_at'] is Timestamp) {
        map['paid_at'] = (map['paid_at'] as Timestamp).toDate().toIso8601String();
      }
      return OrderModel.fromJson(map);
    });
  }
}
