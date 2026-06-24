import 'package:equatable/equatable.dart';

enum MessageType { text, image, orderReference }

class ChatMessage extends Equatable {
  final String messageId;
  final String senderId;
  final MessageType type;
  final String? text;
  final String? imageUrl;
  final String? orderRef;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.type,
    this.text,
    this.imageUrl,
    this.orderRef,
    required this.createdAt,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [messageId];
}

class ChatThread extends Equatable {
  final String threadId;
  final List<String> participantIds;
  final Map<String, ParticipantInfo> participantInfo;
  final ChatMessage? lastMessage;
  final Map<String, int> unreadCount;
  final String? relatedOrderId;
  final DateTime updatedAt;

  const ChatThread({
    required this.threadId,
    required this.participantIds,
    required this.participantInfo,
    this.lastMessage,
    required this.unreadCount,
    this.relatedOrderId,
    required this.updatedAt,
  });

  int unreadFor(String uid) => unreadCount[uid] ?? 0;

  @override
  List<Object?> get props => [threadId];
}

class ParticipantInfo extends Equatable {
  final String name;
  final String? avatarUrl;
  final String role;

  const ParticipantInfo({
    required this.name,
    this.avatarUrl,
    required this.role,
  });

  @override
  List<Object?> get props => [name, role];
}
