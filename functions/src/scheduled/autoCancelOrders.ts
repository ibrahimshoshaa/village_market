import { onSchedule } from 'firebase-functions/v2/scheduler';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { sendFcmToUser } from '../utils/fcmSender';

const db = getFirestore();
const PENDING_TIMEOUT_MINUTES = 15;

export const autoCancelOrders = onSchedule('every 5 minutes', async () => {
  const cutoff = Timestamp.fromMillis(Date.now() - PENDING_TIMEOUT_MINUTES * 60 * 1000);

  // Uses the [status ASC, createdAt ASC] composite index from Phase 2.8
  const staleOrdersSnap = await db.collection('orders')
    .where('status', '==', 'pending')
    .where('createdAt', '<=', cutoff)
    .limit(100) // batch-process to respect function timeout, picks up stragglers next run
    .get();

  if (staleOrdersSnap.empty) return;

  const batch = db.batch();

  for (const doc of staleOrdersSnap.docs) {
    const order = doc.data();

    batch.update(doc.ref, {
      status: 'cancelled',
      cancellation: {
        reason: 'لم يتم الرد على الطلب من قبل المتجر',
        cancelledBy: 'system',
        cancelledAt: FieldValue.serverTimestamp(),
      },
      statusHistory: FieldValue.arrayUnion({
        status: 'cancelled',
        timestamp: Timestamp.now(), // arrayUnion cannot use serverTimestamp() inside the map
        changedBy: 'system',
        note: 'Auto-cancelled: vendor did not respond in time',
      }),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Restock the items that were decremented at order-creation time
    for (const item of order.items) {
      const productRef = db.doc(`shops/${order.shopId}/products/${item.productId}`);
      batch.update(productRef, {
        stockQuantity: FieldValue.increment(item.quantity),
        isInStock: true,
      });
    }
  }

  await batch.commit();

  // Notify customers after the batch commits successfully
  for (const doc of staleOrdersSnap.docs) {
    const order = doc.data();
    await sendFcmToUser(order.customerId, {
      title: 'تم إلغاء الطلب تلقائياً',
      body: `للأسف، لم يستجب المتجر للطلب ${order.orderNumber} في الوقت المناسب`,
      data: { type: 'order_auto_cancelled', orderId: doc.id },
    });
  }
});
