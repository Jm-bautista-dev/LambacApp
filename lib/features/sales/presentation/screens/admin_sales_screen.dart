import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/chips/app_chip.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../data/datasources/firebase_sales_remote_datasource.dart';
import '../../data/models/sales_channel.dart';
import '../providers/sales_provider.dart';
import '../widgets/sales_channel_badge.dart';
import '../widgets/sales_record_detail_sheet.dart';

/// Production Centralized Sales Data Management Screen
class AdminSalesScreen extends ConsumerStatefulWidget {
  const AdminSalesScreen({super.key});

  @override
  ConsumerState<AdminSalesScreen> createState() => _AdminSalesScreenState();
}

class _AdminSalesScreenState extends ConsumerState<AdminSalesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final salesState = ref.watch(salesNotifierProvider);
    final channelFilter = ref.watch(salesChannelFilterProvider);
    final dateRange = ref.watch(salesDateRangeFilterProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: LambacAppBar(
        title: 'Centralized Sales Ledger',
        subtitle: '${salesState.sales.length} Transactions Recorded',
        fallbackRoute: AppRoutes.adminDashboard,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync & Reconcile Orders',
            onPressed: () async {
              final remote = ref.read(salesRemoteDataSourceProvider);
              if (remote is FirebaseSalesRemoteDataSource) {
                final count = await remote.reconcileCompletedOrders();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reconciled $count completed orders.')),
                  );
                }
              }
              await ref.read(salesNotifierProvider.notifier).loadSales();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContentContainer(
          maxWidth: 840,
          child: Column(
            children: [
              // Search & Channel Filter Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(salesSearchQueryProvider.notifier).state = val;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search transaction #, customer, or product...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),

              // Channel Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    AppChip(
                      label: 'All Transactions',
                      isSelected: channelFilter == null,
                      isSmall: true,
                      onSelected: (_) {
                        ref.read(salesChannelFilterProvider.notifier).state = null;
                      },
                    ),
                    const SizedBox(width: 6),
                    AppChip(
                      label: 'Walk-In Store (POS)',
                      isSelected: channelFilter == SalesChannel.walkIn,
                      isSmall: true,
                      onSelected: (_) {
                        ref.read(salesChannelFilterProvider.notifier).state = SalesChannel.walkIn;
                      },
                    ),
                    const SizedBox(width: 6),
                    AppChip(
                      label: 'Mobile App Pickups',
                      isSelected: channelFilter == SalesChannel.mobileApp,
                      isSmall: true,
                      onSelected: (_) {
                        ref.read(salesChannelFilterProvider.notifier).state = SalesChannel.mobileApp;
                      },
                    ),
                  ],
                ),
              ),

              // Date Range Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    AppChip(
                      label: 'Today',
                      isSelected: dateRange.toLowerCase() == 'today',
                      isSmall: true,
                      onSelected: (_) {
                        ref.read(salesDateRangeFilterProvider.notifier).state = 'Today';
                      },
                    ),
                    const SizedBox(width: 6),
                    AppChip(
                      label: 'Last 7 Days',
                      isSelected: dateRange.toLowerCase() == '7d' || dateRange.toLowerCase() == 'last 7 days',
                      isSmall: true,
                      onSelected: (_) {
                        ref.read(salesDateRangeFilterProvider.notifier).state = '7D';
                      },
                    ),
                    const SizedBox(width: 6),
                    AppChip(
                      label: 'Last 30 Days',
                      isSelected: dateRange.toLowerCase() == '30d' || dateRange.toLowerCase() == 'last 30 days',
                      isSmall: true,
                      onSelected: (_) {
                        ref.read(salesDateRangeFilterProvider.notifier).state = '30D';
                      },
                    ),
                    const SizedBox(width: 6),
                    AppChip(
                      label: 'All Time',
                      isSelected: dateRange.toLowerCase() == 'all' || dateRange.toLowerCase() == 'all time',
                      isSmall: true,
                      onSelected: (_) {
                        ref.read(salesDateRangeFilterProvider.notifier).state = 'All';
                      },
                    ),
                  ],
                ),
              ),

              // Sales Summary Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Ledger Revenue:',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(salesState.totalRevenue),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                      ),
                    ),
                  ],
                ),
              ),

              // Transactions List
              Expanded(
                child: salesState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : salesState.failure != null
                        ? AppErrorView(
                            title: 'Unable to Load Sales',
                            message: salesState.failure!.message,
                            onRetry: () => ref.read(salesNotifierProvider.notifier).loadSales(),
                          )
                        : salesState.sales.isEmpty
                            ? Center(
                                child: Text(
                                  'No sales records found.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async => ref.read(salesNotifierProvider.notifier).loadSales(),
                                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                                child: ListView.separated(
                                  padding: AppSpacing.screenPadding,
                                  itemCount: salesState.sales.length,
                                  separatorBuilder: (_, __) => AppSpacing.vSpaceMd,
                                  itemBuilder: (context, index) {
                                    final sale = salesState.sales[index];

                                    return AppCard(
                                      padding: const EdgeInsets.all(16),
                                      onTap: () => SalesRecordDetailSheet.show(context, sale),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  sale.transactionNumber,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              SalesChannelBadge(channel: sale.channel),
                                            ],
                                          ),
                                          AppSpacing.vSpaceSm,
                                          Text(
                                            'Customer: ${sale.customerName ?? "Walk-In Customer"}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${sale.totalItemCount} items • ${sale.paymentMethod}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                            ),
                                          ),
                                          const Divider(height: 20),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              if (sale.isVoided)
                                                const Text('VOIDED', style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w700))
                                              else
                                                Text(
                                                  _formatDate(sale.createdAt),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                                  ),
                                                ),
                                              Text(
                                                CurrencyFormatter.format(sale.totalAmount),
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
