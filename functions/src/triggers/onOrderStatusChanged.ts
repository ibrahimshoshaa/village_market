import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { sendFcmToUser } from '../utils/fcmSender';

const db = getFirestore();

const STATUS_MESSAGES: Record<string, (orderNumber: string) => { title: string; body: string; targetRole: 'customer' | 'vendor' | 'driver' }> = {
  accepted: (n) => ({ title: 'تم قبول طلبك', body: `الطلب ${n} قيد التجهيز الآن`, targetRole: 'customer' }),
  preparing: (n) => ({ title: 'جاري تجهيز طلبك', body: `الطلب ${n} قيد التحضير`, targetRole: 'customer' }),
  in_transit: (n) => ({ title: 'الطلب في الطريق', body: `الطلب ${n} في طريقه إليك الآن`, targetRole: 'customer' }),
  delivered: (n) => ({ title: 'تم التوصيل', body: `تم تسليم الطلب ${n} بنجاح`, targetRole: 'customer' }),
  cancelled: (n) => ({ title: 'تم إلغاء الطلب', body: `تم إلغاء الطلب ${n}`, targetRole: 'customer' }),
};

export const onOrderStatusChanged = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  if (before.status === after.status) return; // only react to actual status transitions

  const orderNumber = after.orderNumber;

  // 1. Notify the customer for the standard lifecycle messages
  const config = STATUS_MESSAGES[after.status];
  if (config) {
    const { title, body } = config(orderNumber);
    await sendFcmToUser(after.customerId, { title, body, data: { type: 'order_update', orderId: event.params.orderId } });
  }

  // 2. New order placed (pending) -> notify the VENDOR to take action
  if (after.status === 'pending' && before.status === undefined) {
    await sendFcmToUser(after.vendorId, {
      title: 'طلب جديد!',
      body: `لديك طلب جديد رقم ${orderNumber}`,
      data: { type: 'new_order', orderId: event.params.orderId },
    });
  }

  // 3. Order accepted by vendor and marked ready -> notify available DRIVERS in range
  if (after.status === 'accepted' && after.delivery?.type === 'delivery' && !after.driverId) {
    const nearbyDriversSnap = await db.collection('users')
      .where('role', '==', 'driver')
      .where('driverProfile.isAvailable', '==', true)
      .limit(20)
      .get();

    const tokens = nearbyDriversSnap.docs.flatMap((d) => d.data().fcmTokens ?? []);
    if (tokens.length > 0) {
      await sendFcmToUser(null, {
        title: 'طلب توصيل متاح',
        body: `طلب جديد بانتظار سائق - ${orderNumber}`,
        data: { type: 'delivery_available', orderId: event.params.orderId },
      }, tokens);
    }
  }
});
