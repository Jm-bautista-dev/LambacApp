import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/dialogs/app_dialog.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_skeleton.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/account_management_provider.dart';
import '../widgets/audit_log_sheet.dart';
import '../widgets/create_admin_sheet.dart';
import '../widgets/create_employee_sheet.dart';

/// Business Account & Access Management Screen
class AccountManagementScreen extends ConsumerStatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  ConsumerState<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends ConsumerState<AccountManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    final notifier = ref.read(accountManagementNotifierProvider.notifier);
    switch (_tabController.index) {
      case 0:
        notifier.setRoleFilter(null);
        break;
      case 1:
        notifier.setRoleFilter(UserRole.admin);
        break;
      case 2:
        notifier.setRoleFilter(UserRole.employee);
        break;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDisableUser(UserModel user) async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Disable Account',
      message: 'Are you sure you want to disable ${user.fullName} (${user.email})?\n\nThey will be immediately blocked from signing in and accessing business tools.',
      confirmText: 'Disable Account',
      cancelText: 'Cancel',
      isDestructive: true,
      icon: Icons.block_rounded,
    );

    if (confirmed == true && mounted) {
      final result = await ref
          .read(accountManagementNotifierProvider.notifier)
          .disableUser(user.id);

      if (!mounted) return;
      result.when(
        success: (_) => AppToast.info(context, '${user.fullName} has been disabled.'),
        failure: (f) => AppToast.error(context, f.message),
      );
    }
  }

  Future<void> _handleEnableUser(UserModel user) async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Re-enable Account',
      message: 'Restore business access for ${user.fullName} (${user.email})?',
      confirmText: 'Enable Account',
      cancelText: 'Cancel',
      icon: Icons.check_circle_outline_rounded,
    );

    if (confirmed == true && mounted) {
      final result = await ref
          .read(accountManagementNotifierProvider.notifier)
          .enableUser(user.id);

      if (!mounted) return;
      result.when(
        success: (_) => AppToast.success(context, '${user.fullName} is now active.'),
        failure: (f) => AppToast.error(context, f.message),
      );
    }
  }

  Future<void> _handleResetPassword(UserModel user) async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Reset Password',
      message: 'Generate a new temporary password for ${user.fullName}?\n\nThey will be required to create a new password on their next login.',
      confirmText: 'Generate Temporary Password',
      cancelText: 'Cancel',
      icon: Icons.lock_reset_rounded,
    );

    if (confirmed == true && mounted) {
      final result = await ref
          .read(accountManagementNotifierProvider.notifier)
          .resetPassword(user.id);

      if (!mounted) return;
      result.when(
        success: (tempPassword) {
          _showTemporaryPasswordDialog(user, tempPassword);
        },
        failure: (f) => AppToast.error(context, f.message),
      );
    }
  }

  void _showTemporaryPasswordDialog(UserModel user, String tempPassword) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
          title: const Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: AppColors.brandAmber, size: 22),
              SizedBox(width: 8),
              Text('Temporary Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A temporary password has been set for ${user.fullName}. Share this with the user securely:',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              AppSpacing.vSpaceMd,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(color: AppColors.brandAmber.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tempPassword,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandAmber,
                        letterSpacing: 1.5,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy to Clipboard',
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: tempPassword));
                        AppToast.info(ctx, 'Temporary password copied to clipboard.');
                      },
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpaceSm,
              Text(
                '• The user must change this password immediately on next login.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final state = ref.watch(accountManagementNotifierProvider);
    final notifier = ref.read(accountManagementNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: LambacAppBar(
        title: 'Account Management',
        subtitle: 'Business Staff & Administrator Roles',
        fallbackRoute: AppRoutes.adminDashboard,
        actions: [
          IconButton(
            tooltip: 'Security Audit Logs',
            icon: const Icon(Icons.history_edu_rounded, size: 20),
            onPressed: () => AuditLogSheet.show(context),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => notifier.loadUsers(),
          ),
        ],
      ),
      body: CinematicRoasteryBackground(
        mode: RoasteryAtmosphereMode.subtleOperations,
        child: SafeArea(
          child: ResponsiveContentContainer(
          maxWidth: 900,
          child: Column(
            children: [
              // Search & Provision Actions Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => notifier.setSearchQuery(val),
                            decoration: InputDecoration(
                              hintText: 'Search by name, email, or phone...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 20),
                              isDense: true,
                              filled: true,
                              fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.radiusMd,
                                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppRadius.radiusMd,
                                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.hSpaceSm,
                        PopupMenuButton<String>(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.brandAmber,
                              borderRadius: AppRadius.radiusMd,
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                          ),
                          tooltip: 'Provision Account',
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'admin',
                              child: Row(
                                children: [
                                  Icon(Icons.admin_panel_settings_rounded, color: AppColors.brandAmber, size: 18),
                                  SizedBox(width: 8),
                                  Text('+ Provision Administrator'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'employee',
                              child: Row(
                                children: [
                                  Icon(Icons.badge_rounded, color: AppColors.matchaSage, size: 18),
                                  SizedBox(width: 8),
                                  Text('+ Provision Employee'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (val) {
                            if (val == 'admin') {
                              CreateAdminSheet.show(context);
                            } else if (val == 'employee') {
                              CreateEmployeeSheet.show(context);
                            }
                          },
                        ),
                      ],
                    ),
                    AppSpacing.vSpaceSm,

                    // Tabs
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.brandAmber,
                      labelColor: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                      unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      tabs: [
                        Tab(text: 'All (${state.users.length})'),
                        Tab(text: 'Admins (${state.admins.length})'),
                        Tab(text: 'Employees (${state.employees.length})'),
                      ],
                    ),
                  ],
                ),
              ),

              // KPI Stats Header Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildStatPill('Active: ${state.activeCount}', AppColors.success, isDark),
                    const SizedBox(width: 8),
                    _buildStatPill('Disabled: ${state.disabledCount}', AppColors.error, isDark),
                    const SizedBox(width: 8),
                    _buildStatPill('Total: ${state.users.length}', AppColors.info, isDark),
                  ],
                ),
              ),

              // User List View
              Expanded(
                child: state.isLoading
                    ? ListView.builder(
                        padding: AppSpacing.screenPadding,
                        itemCount: 4,
                        itemBuilder: (_, __) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppSkeleton(height: 100, borderRadius: AppRadius.radiusMd),
                        ),
                      )
                    : state.errorMessage != null
                        ? AppErrorView(
                            title: 'Unable to Load Accounts',
                            message: state.errorMessage!,
                            onRetry: () => notifier.loadUsers(),
                          )
                        : state.users.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.group_outlined,
                                      size: 56,
                                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                    ),
                                    AppSpacing.vSpaceMd,
                                    Text(
                                      'No business accounts found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    AppSpacing.vSpaceSm,
                                    Text(
                                      'Use the "+" button above to provision a new business account.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () => notifier.loadUsers(),
                                child: ListView.separated(
                                  padding: AppSpacing.screenPadding,
                                  itemCount: state.users.length,
                                  separatorBuilder: (_, __) => AppSpacing.vSpaceSm,
                                  itemBuilder: (context, index) {
                                    final user = state.users[index];
                                    final isMe = user.id == currentUser?.id;
                                    return _buildUserCard(user, isMe, isDark);
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

  Widget _buildStatPill(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppRadius.radiusPill,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user, bool isMe, bool isDark) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: user.isAdmin
                      ? (isDark ? AppColors.brandAmberDark.withOpacity(0.3) : AppColors.brandAmberLight.withOpacity(0.3))
                      : (isDark ? AppColors.matchaSage.withOpacity(0.2) : AppColors.matchaSage.withOpacity(0.15)),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: user.isAdmin ? AppColors.brandAmber : AppColors.matchaSage,
                  ),
                ),
              ),
              AppSpacing.hSpaceMd,

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.fullName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.15),
                              borderRadius: AppRadius.radiusPill,
                            ),
                            child: const Text('YOU', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.info)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    if (user.phoneNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.phoneNumber!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Action Menu Button
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                itemBuilder: (ctx) => [
                  if (user.isEmployee)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Permissions'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'reset_password',
                    child: Row(
                      children: [
                        Icon(Icons.lock_reset_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Reset Password'),
                      ],
                    ),
                  ),
                  if (!isMe)
                    PopupMenuItem(
                      value: user.isDisabled ? 'enable' : 'disable',
                      child: Row(
                        children: [
                          Icon(
                            user.isDisabled ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                            color: user.isDisabled ? AppColors.success : AppColors.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user.isDisabled ? 'Enable Account' : 'Disable Account',
                            style: TextStyle(color: user.isDisabled ? AppColors.success : AppColors.error),
                          ),
                        ],
                      ),
                    ),
                ],
                onSelected: (val) {
                  if (val == 'edit') {
                    CreateEmployeeSheet.show(context, employee: user);
                  } else if (val == 'reset_password') {
                    _handleResetPassword(user);
                  } else if (val == 'disable') {
                    _handleDisableUser(user);
                  } else if (val == 'enable') {
                    _handleEnableUser(user);
                  }
                },
              ),
            ],
          ),
          AppSpacing.vSpaceMd,

          // Badges and Meta Information
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              // Role & Status Badges
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: user.isAdmin
                          ? AppColors.brandAmber.withOpacity(0.18)
                          : AppColors.matchaSage.withOpacity(0.18),
                      borderRadius: AppRadius.radiusPill,
                    ),
                    child: Text(
                      user.isAdmin ? 'ADMINISTRATOR' : 'EMPLOYEE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: user.isAdmin ? AppColors.brandAmber : AppColors.matchaSage,
                      ),
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: user.isDisabled
                          ? AppColors.error.withOpacity(0.15)
                          : user.mustChangePassword
                              ? AppColors.warning.withOpacity(0.18)
                              : AppColors.success.withOpacity(0.15),
                      borderRadius: AppRadius.radiusPill,
                    ),
                    child: Text(
                      user.isDisabled
                          ? 'DISABLED'
                          : user.mustChangePassword
                              ? 'MUST CHANGE PASSWORD'
                              : 'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: user.isDisabled
                            ? AppColors.error
                            : user.mustChangePassword
                                ? AppColors.warning
                                : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),

              // Created date
              if (user.createdAt != null)
                Text(
                  'Created: ${dateFormat.format(user.createdAt!)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
            ],
          ),

          // Operational permissions chips (for Employees)
          if (user.isEmployee && user.permissions.isNotEmpty) ...[
            AppSpacing.vSpaceSm,
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: user.permissions.map((p) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Text(
                    p.toFormattedString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
