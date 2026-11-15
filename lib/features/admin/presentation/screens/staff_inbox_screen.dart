import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../../core/widgets/visuals/lambac_roastery_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/data/models/conversation_model.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../onboarding/presentation/spotlight/spotlight_keys.dart';

/// Business Staff & Admin Customer Communication Inbox Screen
/// Displays shared customer conversations with order references, unread badges, and real-time updates.
class StaffInboxScreen extends ConsumerWidget {
  const StaffInboxScreen({super.key});

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.month}/${time.day}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentUser = ref.watch(currentUserProvider);
    final inboxState = ref.watch(inboxNotifierProvider);
    final inboxNotifier = ref.read(inboxNotifierProvider.notifier);

    final isAdmin = currentUser?.isAdmin == true;
    final roleKey = currentUser?.role.name ?? 'employee';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: LambacAppBar(
        showBackButton: isAdmin,
        fallbackRoute: isAdmin ? AppRoutes.adminDashboard : null,
        title: 'Customer Concierge Inbox',
        subtitle: isAdmin
            ? 'Shared Operational & Admin Access'
            : 'Direct Barista Staff Support',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh Inbox',
            onPressed: () => inboxNotifier.loadInbox(),
          ),
        ],
      ),
      body: CinematicRoasteryBackground(
        mode: RoasteryAtmosphereMode.subtleOperations,
        child: SafeArea(
          child: ResponsiveContentContainer(
            maxWidth: 720,
            child: Column(
              children: [
                // Shared Multi-Role Alert Banner
                Container(
                  key: SpotlightKeys.staffInboxBanner,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: isDark
                      ? AppColors.brandAmber.withOpacity(0.15)
                      : AppColors.brandAmber.withOpacity(0.08),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mark_chat_unread_rounded,
                        size: 18,
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Direct shared messaging lets Barista and Admin coordinate customer inquiries in real time.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Conversation Threads List
                Expanded(
                  child: inboxState.isLoading && inboxState.conversations.isEmpty
                      ? const Center(
                          child: LambacRoasteryLoader(message: 'Loading concierge inbox...'),
                        )
                      : inboxState.failure != null && inboxState.conversations.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: AppErrorView(
                                failure: inboxState.failure!,
                                onRetry: () => inboxNotifier.loadInbox(),
                              ),
                            )
                          : inboxState.conversations.isEmpty
                              ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.forum_outlined,
                                      size: 48,
                                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No Customer Conversations Yet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Incoming customer inquiries and order messages will appear here in real time.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => inboxNotifier.loadInbox(),
                              child: ListView.separated(
                                padding: AppSpacing.screenPadding,
                                itemCount: inboxState.conversations.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final conv = inboxState.conversations[index];
                                  final unreadCount = conv.unreadForRole(roleKey);
                                  final hasUnread = unreadCount > 0;

                                  return _ConversationCard(
                                    conversation: conv,
                                    hasUnread: hasUnread,
                                    unreadCount: unreadCount,
                                    isDark: isDark,
                                    formattedTime: _formatRelativeTime(conv.updatedAt),
                                    onTap: () {
                                      inboxNotifier.markAsRead(conv.id);
                                      context.push(
                                        '${AppRoutes.chat}?customerId=${conv.customerId}',
                                        extra: conv.customerId,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final ConversationModel conversation;
  final bool hasUnread;
  final int unreadCount;
  final bool isDark;
  final String formattedTime;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.conversation,
    required this.hasUnread,
    required this.unreadCount,
    required this.isDark,
    required this.formattedTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = conversation.customerName.isNotEmpty
        ? conversation.customerName[0].toUpperCase()
        : 'C';

    final lastMessageText = conversation.lastMessage?.text ?? 'No messages yet';

    return AppCard.elevated(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Initial Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              shape: BoxShape.circle,
              border: hasUnread
                  ? Border.all(
                      color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                      width: 2,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
              ),
            ),
          ),
          AppSpacing.hSpaceMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Name + Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        conversation.customerName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                        color: hasUnread
                            ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark)
                            : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                      ),
                    ),
                  ],
                ),

                // Order Reference Chip (Requirement 11)
                if (conversation.orderReference != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.brandAmber.withOpacity(0.18)
                          : AppColors.brandAmber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_rounded,
                          size: 11,
                          color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          conversation.orderReference!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 4),

                // Last Message Preview
                Text(
                  lastMessageText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                    color: hasUnread
                        ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Unread indicator dot/badge (Requirement 10)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasUnread)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkCanvas : Colors.white,
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.chevron_right_rounded, size: 20),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
