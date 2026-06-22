import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const db = getFirestore();

export const onReviewCreated = onDocumentCreated(
  '{parentCollection}/{parentId}/reviews/{reviewId}',
  async (event) => {
    const { parentCollection, parentId } = event.params;

    // Guard: only apply to the two valid parent types — collectionGroup wildcards
    // match ANY top-level collection named differently, so we whitelist explicitly.
    if (!['shops', 'craftsmen'].includes(parentCollection)) return;

    const review = event.data?.data();
    if (!review) return;

    const rating: number = review.rating;
    const parentRef = db.collection(parentCollection).doc(parentId);

    await db.runTransaction(async (tx) => {
      const parentSnap = await tx.get(parentRef);
      if (!parentSnap.exists) return;

      const currentSum = parentSnap.data()?.ratingSum ?? 0;
      const currentCount = parentSnap.data()?.reviewCount ?? 0;

      const newSum = currentSum + rating;
      const newCount = currentCount + 1;

      tx.update(parentRef, {
        ratingSum: newSum,
        reviewCount: newCount,
        avgRating: Math.round((newSum / newCount) * 10) / 10, // 1 decimal place
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
  }
);
