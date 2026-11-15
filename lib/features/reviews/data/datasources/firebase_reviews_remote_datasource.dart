import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/monitoring/operational_monitoring_service.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/user_model.dart';
import '../models/create_review_request.dart';
import '../models/product_review_model.dart';
import 'reviews_remote_datasource.dart';

/// Cloud Firestore Data Source for Product Reviews and Community Moderation
class FirebaseReviewsRemoteDataSource implements ReviewsRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseReviewsRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ===========================================================================
  // REVIEWS RETRIEVAL
  // ===========================================================================

  @override
  Future<Result<List<ProductReviewModel>, AppFailure>> getProductReviews(
    String productId, {
    int limit = 20,
    dynamic lastDocument,
  }) async {
    try {
      // Query non-flagged reviews for public product view
      final snapshot = await _firestore
          .collection('reviews')
          .where('is_flagged', isEqualTo: false)
          .get();

      var reviews = snapshot.docs
          .map((doc) => _mapDocToReview(doc))
          .where((r) => r.productId == productId)
          .toList();

      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      String? cursorId;
      if (lastDocument is DocumentSnapshot) {
        cursorId = lastDocument.id;
      } else if (lastDocument is String && lastDocument.isNotEmpty) {
        cursorId = lastDocument;
      }

      int startIndex = 0;
      if (cursorId != null) {
        final idx = reviews.indexWhere((r) => r.id == cursorId);
        if (idx != -1) startIndex = idx + 1;
      }

      final endIndex = (startIndex + limit) > reviews.length ? reviews.length : (startIndex + limit);
      final sliced = startIndex < reviews.length ? reviews.sublist(startIndex, endIndex) : <ProductReviewModel>[];

      return Result.success(List.unmodifiable(sliced));
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to load product reviews: $e'));
    }
  }

  @override
  Future<Result<List<ProductReviewModel>, AppFailure>> getAllReviews({
    bool includeFlagged = true,
  }) async {
    try {
      final user = _auth.currentUser;
      final isStaff = user != null && await _isStaffUser(user.uid);

      Query<Map<String, dynamic>> query = _firestore.collection('reviews');
      if (!isStaff && !includeFlagged) {
        query = query.where('is_flagged', isEqualTo: false);
      }

      final snapshot = await query.get();
      final reviews = snapshot.docs
          .map((doc) => _mapDocToReview(doc))
          .where((r) => includeFlagged || !r.isFlagged)
          .toList();

      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Result.success(List.unmodifiable(reviews));
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to load all reviews: $e'));
    }
  }

  @override
  Stream<List<ProductReviewModel>> watchAllReviews({
    bool includeFlagged = true,
  }) {
    final query = _firestore.collection('reviews');
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => _mapDocToReview(doc))
          .where((r) => includeFlagged || !r.isFlagged)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List.unmodifiable(list);
    });
  }

  // ===========================================================================
  // REVIEW SUBMISSION
  // ===========================================================================

  @override
  Future<Result<ProductReviewModel, AppFailure>> submitReview(CreateReviewRequest request) async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'You must be signed in to submit a review.'),
      );
    }

    final effectiveUserId = user.uid;
    final effectiveUserName = user.displayName?.isNotEmpty == true ? user.displayName! : 'Verified Roastery Buyer';

    // Validate rating range
    if (request.rating < 1 || request.rating > 5) {
      return const Result.failure(
        ValidationFailure(message: 'Rating must be between 1 and 5 stars.'),
      );
    }

    final cleanComment = request.comment.trim();
    if (cleanComment.length < 2) {
      return const Result.failure(
        ValidationFailure(message: 'Review comment must be at least 2 characters.'),
      );
    }

    if (cleanComment.length > 1000) {
      return const Result.failure(
        ValidationFailure(message: 'Review comment cannot exceed 1000 characters.'),
      );
    }

    if (request.productId.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Product identifier cannot be empty.'),
      );
    }

    try {
      // Check for existing review by this customer for this product (idempotent / single review per product)
      final existingQuery = await _firestore
          .collection('reviews')
          .where('product_id', isEqualTo: request.productId)
          .where('customer_id', isEqualTo: effectiveUserId)
          .limit(1)
          .get();

      final now = DateTime.now();
      final reviewId = existingQuery.docs.isNotEmpty
          ? existingQuery.docs.first.id
          : 'rev_${now.millisecondsSinceEpoch}_${effectiveUserId.substring(0, effectiveUserId.length.clamp(0, 6))}';

      final reviewModel = ProductReviewModel(
        id: reviewId,
        productId: request.productId,
        customerId: effectiveUserId,
        customerName: effectiveUserName,
        rating: request.rating.clamp(1, 5),
        comment: request.comment.trim(),
        isVerifiedPurchase: true,
        isFlagged: false,
        orderId: request.orderId,
        createdAt: now,
        updatedAt: now,
      );

      final reviewData = reviewModel.toJson();
      reviewData['customer_id'] = effectiveUserId;
      reviewData['updated_at'] = now.toIso8601String();

      await _firestore.collection('reviews').doc(reviewId).set(
        reviewData,
        SetOptions(merge: true),
      );

      return Result.success(reviewModel);
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to submit review: $e'));
    }
  }

  // ===========================================================================
  // ELIGIBILITY & MODERATION
  // ===========================================================================

  @override
  Future<Result<bool, AppFailure>> checkReviewEligibility(String productId) async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.success(false);
    }

    final effectiveUserId = user.uid;

    try {
      // Check if user has at least one completed order containing this product
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('customer_id', isEqualTo: effectiveUserId)
          .get();

      for (final doc in ordersSnapshot.docs) {
        final data = doc.data();
        final items = data['items'] as List<dynamic>? ?? [];
        final hasProduct = items.any((item) {
          if (item is Map) {
            return (item['product_id'] ?? item['productId']) == productId;
          }
          return false;
        });

        if (hasProduct) {
          return const Result.success(true);
        }
      }

      return const Result.success(false);
    } catch (_) {
      return const Result.success(false);
    }
  }

  @override
  Future<Result<ProductReviewModel, AppFailure>> flagReview(String reviewId) async {
    try {
      final docRef = _firestore.collection('reviews').doc(reviewId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        return const Result.failure(NotFoundFailure(message: 'Review not found.'));
      }

      await docRef.update({
        'is_flagged': true,
        'flagged_at': DateTime.now().toIso8601String(),
      });

      final updated = _mapDocToReview(docSnap).copyWith(isFlagged: true);
      return Result.success(updated);
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to flag review: $e'));
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  Future<bool> _isStaffUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final role = UserRole.fromString(doc.data()?['role']?.toString());
        return role == UserRole.admin || role == UserRole.employee;
      }
    } catch (_) {}
    return false;
  }

  ProductReviewModel _mapDocToReview(DocumentSnapshot doc) {
    final rawData = doc.data() as Map<String, dynamic>? ?? {};
    final map = Map<String, dynamic>.from(rawData);
    map['id'] = doc.id;

    if (map['created_at'] is Timestamp) {
      map['created_at'] = (map['created_at'] as Timestamp).toDate().toIso8601String();
    }
    if (map['updated_at'] is Timestamp) {
      map['updated_at'] = (map['updated_at'] as Timestamp).toDate().toIso8601String();
    }
    return ProductReviewModel.fromJson(map);
  }

  AppFailure _mapFirebaseException(FirebaseException e, [StackTrace? stackTrace]) {
    return ErrorHandler.handle(
      e,
      stackTrace: stackTrace,
      domain: FailureDomain.firestoreAccess,
      operation: 'product_reviews',
    );
  }
}
