import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../data/models/benchmark_history_entry_model.dart';

/// Historical Benchmark Runs Audit Log Table
class BenchmarkingHistoryTable extends StatelessWidget {
  final List<BenchmarkHistoryEntryModel> history;

  const BenchmarkingHistoryTable({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    final df = DateFormat('MMM d, yyyy • h:mm a');

    return AppCard.elevated(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.brandAmber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history_edu_rounded, color: AppColors.brandAmber, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Benchmark Audit History Log',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'Auditable record of historical benchmark iterations proving dynamic model adaptation',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF2ECE6),
                  borderRadius: AppRadius.radiusPill,
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Text(
                  '${history.length} Audit Entries',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceMd,

          // Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: DataTable(
              horizontalMargin: 12,
              columnSpacing: 24,
              headingRowHeight: 38,
              dataRowMinHeight: 46,
              dataRowMaxHeight: 50,
              headingRowColor: WidgetStatePropertyAll(
                isDark ? const Color(0xFF261D17) : const Color(0xFFF9F5F0),
              ),
              columns: const [
                DataColumn(label: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5))),
                DataColumn(label: Text('Evaluation Period', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5))),
                DataColumn(label: Text('Best Model Selected', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5))),
                DataColumn(numeric: true, label: Text('Score', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5))),
                DataColumn(numeric: true, label: Text('MAE (₱)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5))),
                DataColumn(numeric: true, label: Text('sMAPE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5))),
              ],
              rows: history.map((entry) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        df.format(entry.timestamp),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        entry.evaluationPeriodLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events_rounded, size: 14, color: AppColors.brandAmber),
                          const SizedBox(width: 6),
                          Text(
                            entry.winningModelName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        entry.compositeScore.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.cremaGold : AppColors.brandAmberDark,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '₱${entry.mae.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${entry.smape.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3828) : const Color(0xFFE8F5E9),
                          borderRadius: AppRadius.radiusPill,
                          border: Border.all(
                            color: isDark ? const Color(0xFF4CAF50) : const Color(0xFF81C784),
                          ),
                        ),
                        child: Text(
                          entry.status,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
