import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { getAuth } from 'firebase-admin/auth';

export const onUserWrite = onDocumentWritten('users/{uid}', async (event) => {
  const after = event.data?.after.data();
  if (!after) return; // document deleted

  const before = event.data?.before.data();
  if (before?.role === after.role) return; // no role change, skip the Auth API call

  await getAuth().setCustomUserClaims(event.params.uid, { role: after.role });
});
