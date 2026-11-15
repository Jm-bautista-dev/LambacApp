import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/routing/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../chat/data/models/conversation_model.dart';
import '../../../../onboarding/presentation/spotlight/spotlight_keys.dart';

/// Executive Messages Summary Card for Admin Dashboard
class ExecutiveMessagesSummaryCard extends StatelessWidget {
  final int unreadCount;
  final List<ConversationModel> conversations;

  const ExecutiveMessagesSummaryCard({
    super.key,
    required this.unreadCount,
    required this.conversations,
  });

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final unreadThreads = conversations.where((c) => c.unreadCount > 0).toList();
    final displayThreads = unreadThreads.isNotEmpty
        ? unreadThreads.take(2).toList()
        : conversations.take(2).toList();

    return AppCard.elevated(
      key: SpotlightKeys.adminInboxSummaryCard,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompactHeader = constraints.maxWidth < 220;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.chat_bubble_rounded,
                              size: 18,
                              color: AppColors.brandAmber,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Messages Requiring Attention',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          unreadCount > 0
                              ? '$unreadCount unread customer inquiries waiting for support'
                              : 'Concierge inbox is up to date',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => context.push(AppRoutes.staffInbox),
                    borderRadius: AppRadius.radiusSm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCompactHeader) ...[
                            Text(
                              'Open Inbox',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                              ),
                            ),
                            const SizedBox(width: 2),
                          ],
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          AppSpacing.vSpaceMd,

          if (displayThreads.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mark_chat_read_rounded, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'No pending customer inquiries at this time.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: displayThreads.map((thread) {
                final isUnread = thread.unreadCount > 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUnread
                        ? AppColors.brandAmber.withValues(alpha: isDark ? 0.12 : 0.06)
                        : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(
                      color: isUnread
                          ? AppColors.brandAmber.withValues(alpha: 0.35)
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: 0.8,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.staffInbox),
                    child: LayoutBuilder(
                      builder: (context, itemConstraints) {
                        final rowContent = Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar Badge
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isUnread
                                    ? AppColors.brandAmber.withValues(alpha: 0.2)
                                    : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isUnread ? AppColors.brandAmber : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                thread.customerName.isNotEmpty ? thread.customerName[0].toUpperCase() : 'C',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isUnread ? AppColors.brandAmber : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Name, Message Snippet & Time
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          thread.customerName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          _formatRelativeTime(thread.updatedAt),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                                            color: isUnread ? AppColors.brandAmber : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    thread.lastMessage?.text ?? 'Customer inquiry thread',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: const BoxDecoration(
                                  color: AppColors.brandAmber,
                                  borderRadius: AppRadius.radiusPill,
                                ),
                                child: Text(
                                  '${thread.unreadCount}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );

                        if (itemConstraints.maxWidth < 220) {
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 220,
                              child: rowContent,
                            ),
                          );
                        }
                        return rowContent;
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
