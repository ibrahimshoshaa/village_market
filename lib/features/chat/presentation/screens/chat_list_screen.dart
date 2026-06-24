import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/chat.dart';
import '../providers/chat_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(myThreadsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المحادثات')),
      body: threadsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (threads) => threads.isEmpty
            ? _buildEmpty(context)
            : ListView.separated(
                itemCount: threads.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) => _ThreadTile(thread: threads[i]),
              ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline,
              size: 72, color: AppColors.imagePlaceholderIcon,),
          const SizedBox(height: 16),
          Text('مفيش محادثات لحد دلوقتي',
              style: Theme.of(context).textTheme.bodyLarge,),
          const SizedBox(height: 8),
          Text('تقدر تتواصل مع التجار من صفحة المحل',
              style: Theme.of(context).textTheme.bodyMedium,),
        ],
      ),
    );
  }
}

class _ThreadTile extends ConsumerWidget {
  final ChatThread thread;
  const _ThreadTile({required this.thread});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    final otherUid =
        thread.participantIds.firstWhere((id) => id != myUid, orElse: () => '');
    final other = thread.participantInfo[otherUid];
    final unread = thread.unreadFor(myUid);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        child: Text(
          other?.name.isNotEmpty == true ? other!.name[0] : '؟',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      title: Text(
        other?.name ?? 'مجهول',
        style: TextStyle(
          fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      subtitle: Text(
        thread.lastMessage?.text ?? 'بدأت المحادثة',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: unread > 0 ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: unread > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      onTap: () => context.push(
        '/chat/${thread.threadId}',
        extra: other?.name ?? 'محادثة',
      ),
    );
  }
}
