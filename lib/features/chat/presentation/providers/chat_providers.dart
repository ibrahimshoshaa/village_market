import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/firebase_service.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/chat.dart';

part 'chat_providers.g.dart';

// ===== Firestore Mappers =====

ChatThread _threadFromDoc(DocumentSnapshot doc) {
  final d = doc.data() as Map<String, dynamic>;
  final info = (d['participantInfo'] as Map<String, dynamic>? ?? {})
      .map((k, v) => MapEntry(
            k,
            ParticipantInfo(
              name: v['name'] ?? '',
              avatarUrl: v['avatarUrl'],
              role: v['role'] ?? '',
            ),
          ));

  final lastMsg = d['lastMessage'] as Map<String, dynamic>?;
  ChatMessage? last;
  if (lastMsg != null) {
    last = ChatMessage(
      messageId: '',
      senderId: lastMsg['senderId'] ?? '',
      type: MessageType.text,
      text: lastMsg['text'],
      createdAt: (lastMsg['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  return ChatThread(
    threadId: doc.id,
    participantIds: List<String>.from(d['participantIds'] ?? []),
    participantInfo: info,
    lastMessage: last,
    unreadCount: Map<String, int>.from(
      (d['unreadCount'] as Map?)?.map((k, v) => MapEntry(k, v as int)) ?? {},
    ),
    relatedOrderId: d['relatedOrderId'],
    updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

ChatMessage _messageFromDoc(DocumentSnapshot doc) {
  final d = doc.data() as Map<String, dynamic>;
  return ChatMessage(
    messageId: doc.id,
    senderId: d['senderId'] ?? '',
    type: MessageType.values.firstWhere(
      (t) => t.name == (d['type'] ?? 'text'),
      orElse: () => MessageType.text,
    ),
    text: d['text'],
    imageUrl: d['imageUrl'],
    orderRef: d['orderRef'],
    createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    isRead: d['status'] == 'read',
  );
}

// ===== Providers =====

/// قائمة المحادثات بتاعت المستخدم الحالي
@riverpod
Stream<List<ChatThread>> myThreads(Ref ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('chats')
      .where('participantIds', arrayContains: user.uid)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(_threadFromDoc).toList());
}

/// رسائل محادثة معينة
@riverpod
Stream<List<ChatMessage>> threadMessages(Ref ref, String threadId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('chats')
      .doc(threadId)
      .collection('messages')
      .orderBy('createdAt', descending: false)
      .limitToLast(50)
      .snapshots()
      .map((s) => s.docs.map(_messageFromDoc).toList());
}

/// Controller للإرسال والتفاعل مع الشات
@riverpod
class ChatController extends _$ChatController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// إنشاء أو فتح thread بين مستخدمين
  Future<String> getOrCreateThread({
    required String otherUserId,
    required String otherUserName,
    required String otherUserRole,
    String? relatedOrderId,
  }) async {
    final me = ref.read(authStateProvider).valueOrNull!;
    final firestore = ref.read(firestoreProvider);

    // Thread ID ثابت بترتيب أبجدي
    final ids = [me.uid, otherUserId]..sort();
    final threadId = '${ids[0]}_${ids[1]}';

    final ref2 = firestore.collection('chats').doc(threadId);
    final snap = await ref2.get();

    if (!snap.exists) {
      await ref2.set({
        'threadId': threadId,
        'participantIds': ids,
        'participantInfo': {
          me.uid: {
            'name': me.displayName,
            'avatarUrl': me.profileImageUrl,
            'role': me.role.name,
          },
          otherUserId: {
            'name': otherUserName,
            'avatarUrl': null,
            'role': otherUserRole,
          },
        },
        'relatedOrderId': relatedOrderId,
        'lastMessage': null,
        'unreadCount': {me.uid: 0, otherUserId: 0},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return threadId;
  }

  /// إرسال رسالة نصية
  Future<void> sendMessage(String threadId, String text) async {
    if (text.trim().isEmpty) return;

    final me = ref.read(authStateProvider).valueOrNull!;
    final firestore = ref.read(firestoreProvider);

    final msgRef = firestore
        .collection('chats')
        .doc(threadId)
        .collection('messages')
        .doc();

    final batch = firestore.batch();

    // أضف الرسالة
    batch.set(msgRef, {
      'messageId': msgRef.id,
      'senderId': me.uid,
      'type': 'text',
      'text': text.trim(),
      'imageUrl': null,
      'orderRef': null,
      'status': 'sent',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // حدّث الـ thread (lastMessage + unread)
    final threadRef = firestore.collection('chats').doc(threadId);
    final threadSnap = await threadRef.get();
    final participants =
        List<String>.from(threadSnap.data()?['participantIds'] ?? []);
    final otherUid = participants.firstWhere((id) => id != me.uid, orElse: () => '');

    batch.update(threadRef, {
      'lastMessage': {
        'text': text.trim(),
        'senderId': me.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      },
      'updatedAt': FieldValue.serverTimestamp(),
      if (otherUid.isNotEmpty) 'unreadCount.$otherUid': FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// مسح الـ unread counter لما المستخدم يفتح الشات
  Future<void> markAsRead(String threadId) async {
    final me = ref.read(authStateProvider).valueOrNull!;
    final firestore = ref.read(firestoreProvider);
    await firestore.collection('chats').doc(threadId).update({
      'unreadCount.${me.uid}': 0,
    });
  }
}
