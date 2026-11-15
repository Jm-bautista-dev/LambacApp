import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../data/models/model_benchmark_result.dart';

/// Premium Candidate Model Comparison Table
/// Shows out-of-sample backtested MAE, RMSE, MAPE, sMAPE, and Scores with Model Inspection trigger.
class BenchmarkingComparisonTable extends StatelessWidget {
  final List<ModelBenchmarkResult> results;
  final ValueChanged<ModelBenchmarkResult> onInspectModel;

  const BenchmarkingComparisonTable({
    super.key,
    required this.results,
    required this.onInspectModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard.elevated(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.brandAmber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.table_chart_rounded, color: AppColors.brandAmber, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Candidate Model Comparison & Backtest Error Leaderboard',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Tap any algorithm row to inspect mathematical parameters, split data, and diagnostics',
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF2ECE6),
                  borderRadius: AppRadius.radiusPill,
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Text(
                  '${results.length} Algorithms Tested',
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

          // Horizontally Scrollable Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: DataTable(
              horizontalMargin: 12,
              columnSpacing: 22,
              headingRowHeight: 40,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 52,
              headingRowColor: WidgetStatePropertyAll(
                isDark ? const Color(0xFF261D17) : const Color(0xFFF9F5F0),
              ),
              columns: const [
                DataColumn(label: Text('Rank', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5))),
                DataColumn(label: Text('Candidate Model', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5))),
                DataColumn(numeric: true, label: Text('MAE (₱)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5))),
                DataColumn(numeric: true, label: Text('RMSE (₱)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5))),
                DataColumn(numeric: true, label: Text('MAPE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5))),
                DataColumn(numeric: true, label: Text('sMAPE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5))),
                DataColumn(numeric: true, label: Text('Score', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5))),
                DataColumn(label: Text('Inspect', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5))),
              ],
              rows: results.map((result) {
                final isWinner = result.isWinner;
                final rowBg = isWinner
                    ? (isDark ? AppColors.brandAmber.withOpacity(0.14) : AppColors.brandAmber.withOpacity(0.08))
                    : Colors.transparent;

                return DataRow(
                  color: WidgetStatePropertyAll(rowBg),
                  onSelectChanged: (_) => onInspectModel(result),
                  cells: [
                    // Rank
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isWinner
                                  ? AppColors.brandAmber
                                  : (isDark ? const Color(0xFF33261D) : const Color(0xFFE4DDD6)),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${result.rank}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: isWinner ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              ),
                            ),
                          ),
                          if (isWinner) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded, size: 14, color: AppColors.brandAmber),
                          ],
                        ],
                      ),
                    ),

                    // Model Name
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            result.modelName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
                              color: isWinner
                                  ? (isDark ? AppColors.cremaGold : AppColors.brandAmberDark)
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            ),
                          ),
                          Text(
                            result.candidateType.shortCode,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // MAE
                    DataCell(
                      Text(
                        '₱${result.mae.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),

                    // RMSE
                    DataCell(
                      Text(
                        '₱${result.rmse.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),

                    // MAPE
                    DataCell(
                      Text(
                        '${result.mape.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),

                    // sMAPE
                    DataCell(
                      Text(
                        '${result.smape.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
                          color: isWinner
                              ? (isDark ? AppColors.cremaGold : AppColors.brandAmberDark)
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                    ),

                    // Score
                    DataCell(
                      Text(
                        result.compositeScore.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isWinner
                              ? (isDark ? AppColors.cremaGold : AppColors.brandAmberDark)
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                    ),

                    // Status
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isWinner
                              ? AppColors.brandAmber
                              : (isDark ? AppColors.darkSurface : const Color(0xFFEDE6E0)),
                          borderRadius: AppRadius.radiusPill,
                          border: isWinner
                              ? null
                              : Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                        ),
                        child: Text(
                          isWinner ? 'BEST' : 'Evaluated',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isWinner ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    ),

                    // Inspect Button
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.info_outline_rounded, size: 18),
                        color: isWinner ? AppColors.brandAmber : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        tooltip: 'Inspect ${result.modelName}',
                        onPressed: () => onInspectModel(result),
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
