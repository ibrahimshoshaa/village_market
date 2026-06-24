import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/firebase_service.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';

part 'review_providers.g.dart';

class Review {
  final String reviewId;
  final String authorId;
  final String authorName;
  final int rating;
  final String comment;
  final String? relatedOrderId;
  final String? vendorReply;
  final DateTime createdAt;

  const Review({
    required this.reviewId,
    required this.authorId,
    required this.authorName,
    required this.rating,
    required this.comment,
    this.relatedOrderId,
    this.vendorReply,
    required this.createdAt,
  });

  static Review fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Review(
      reviewId: doc.id,
      authorId: d['authorId'] ?? '',
      authorName: d['authorName'] ?? '',
      rating: (d['rating'] as num? ?? 5).toInt(),
      comment: d['comment'] ?? '',
      relatedOrderId: d['relatedOrderId'],
      vendorReply: (d['vendorReply'] as Map?)?['text'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// قراءة تقييمات محل
@riverpod
Stream<List<Review>> shopReviews(Ref ref, String shopId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('shops')
      .doc(shopId)
      .collection('reviews')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((s) => s.docs.map(Review.fromDoc).toList());
}

/// إضافة تقييم
@riverpod
class ReviewController extends _$ReviewController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submitReview({
    required String shopId,
    required int rating,
    required String comment,
    String? orderId,
  }) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    state = const AsyncLoading();
    try {
      final firestore = ref.read(firestoreProvider);
      final reviewRef =
          firestore.collection('shops').doc(shopId).collection('reviews').doc();

      await reviewRef.set({
        'reviewId': reviewRef.id,
        'authorId': user.uid,
        'authorName': user.displayName,
        'authorAvatarUrl': user.profileImageUrl,
        'rating': rating,
        'comment': comment.trim(),
        'relatedOrderId': orderId,
        'vendorReply': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// رد التاجر على تقييم
  Future<void> replyToReview({
    required String shopId,
    required String reviewId,
    required String replyText,
  }) async {
    state = const AsyncLoading();
    try {
      final firestore = ref.read(firestoreProvider);
      await firestore
          .collection('shops')
          .doc(shopId)
          .collection('reviews')
          .doc(reviewId)
          .update({
        'vendorReply': {
          'text': replyText.trim(),
          'repliedAt': FieldValue.serverTimestamp(),
        },
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
