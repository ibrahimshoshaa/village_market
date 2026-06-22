import { getMessaging } from 'firebase-admin/messaging';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const db = getFirestore();
const messaging = getMessaging();

interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

export async function sendFcmToUser(
  userId: string | null,
  payload: NotificationPayload,
  explicitTokens?: string[],
) {
  let tokens = explicitTokens;

  if (!tokens) {
    if (!userId) return;
    const userSnap = await db.collection('users').doc(userId).get();
    tokens = userSnap.data()?.fcmTokens ?? [];
  }
  if (!tokens || tokens.length === 0) return;

  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: { title: payload.title, body: payload.body },
    data: payload.data ?? {},
    android: { priority: 'high' },
    apns: { headers: { 'apns-priority': '10' } },
  });

  // Clean up tokens that are no longer valid (uninstalled app, expired token)
  const staleTokens: string[] = [];
  response.responses.forEach((r, i) => {
    if (!r.success && (r.error?.code === 'messaging/registration-token-not-registered')) {
      staleTokens.push(tokens![i]);
    }
  });

  if (staleTokens.length > 0 && userId) {
    await db.collection('users').doc(userId).update({
      fcmTokens: FieldValue.arrayRemove(...staleTokens),
    });
  }
}
