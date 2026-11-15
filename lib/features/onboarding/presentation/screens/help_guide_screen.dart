import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/customer_luxury_theme.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../data/datasources/customer_tutorial_data.dart';
import '../../data/models/tutorial_category.dart';
import '../providers/tutorial_provider.dart';
import '../spotlight/customer_spotlight_provider.dart';

/// Production Customer Help & Guide Hub
/// Elevated with Apple-inspired minimalist precision, editorial typography,
/// and full retention of all interactive spotlight tutorial replays.
class HelpGuideScreen extends ConsumerStatefulWidget {
  const HelpGuideScreen({super.key});

  @override
  ConsumerState<HelpGuideScreen> createState() => _HelpGuideScreenState();
}

class _HelpGuideScreenState extends ConsumerState<HelpGuideScreen> {
  TutorialCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  final String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _launchTutorialStep(int stepIndex) {
    ref.read(customerSpotlightProvider.notifier).startTour(
          isReplay: true,
          startStep: stepIndex,
        );
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tutorialState = ref.watch(tutorialNotifierProvider);
    final allSteps = CustomerTutorialData.steps;

    final filteredSteps = allSteps.where((step) {
      if (_selectedCategory != null && step.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = step.title.toLowerCase().contains(query);
        final matchesSubtitle = step.subtitle.toLowerCase().contains(query);
        final matchesArea = step.highlightArea.toLowerCase().contains(query);
        final matchesPoints = step.keyPoints.any((p) => p.toLowerCase().contains(query));
        return matchesTitle || matchesSubtitle || matchesArea || matchesPoints;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : CustomerLuxuryTheme.warmCream,
      appBar: const LambacAppBar(
        title: 'Help & Roastery Guide',
        subtitle: 'Tutorials, brewing guides & FAQs',
        fallbackRoute: AppRoutes.profile,
      ),
      body: SafeArea(
        child: ResponsiveContentContainer(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            children: [
              // --------------------------------------------------------------
              // 1. Replay Interactive Tutorial Hero Card
              // --------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF261D17), const Color(0xFF19130F)]
                        : [const Color(0xFF2C211A), const Color(0xFF1E1611)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.radiusXl,
                  border: Border.all(
                    color: isDark ? AppColors.brandAmberLight.withOpacity(0.35) : AppColors.brandAmber.withOpacity(0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppColors.brandAmber,
                            borderRadius: AppRadius.radiusPill,
                          ),
                          child: Text(
                            'INTERACTIVE TUTORIAL',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        if (tutorialState.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.matchaSage.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.matchaSage.withOpacity(0.6)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.matchaSage, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'Completed',
                                  style: GoogleFonts.inter(
                                    color: AppColors.matchaSage,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    AppSpacing.vSpaceMd,
                    Text(
                      'Customer Feature Walkthrough',
                      style: GoogleFonts.newsreader(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    AppSpacing.vSpaceXs,
                    Text(
                      'Replay the step-by-step visual tour covering menu browsing, custom grind selection, pickup scheduling, pay-at-counter, real-time tracking, and AI concierge.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFD4C8BE),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    AppSpacing.vSpaceLg,
                    AppButton.primary(
                      text: 'Replay Interactive Tour (20 Steps)',
                      leadingIcon: const Icon(Icons.replay_rounded, color: Colors.white, size: 18),
                      onPressed: () => _launchTutorialStep(0),
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpaceXxl,

              // --------------------------------------------------------------
              // 2. Search & Category Filters
              // --------------------------------------------------------------
              Text(
                'Explore Feature Guides by Topic',
                style: CustomerLuxuryTheme.editorialStyle(
                  isDark: isDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              AppSpacing.vSpaceSm,

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('All Topics', null, isDark),
                    ...TutorialCategory.values.map(
                      (cat) => _buildCategoryChip(cat.displayName, cat, isDark),
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpaceMd,

              // --------------------------------------------------------------
              // 3. Step Guides Accordion List
              // --------------------------------------------------------------
              ...filteredSteps.map((step) {
                final stepIndex = allSteps.indexOf(step);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: CustomerLuxuryTheme.cardDecoration(isDark: isDark),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.brandAmber : AppColors.brandAmber).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                step.icon,
                                size: 19,
                                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Step ${step.stepNumber} • ${step.category.displayName}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    step.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => _launchTutorialStep(stepIndex),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: const Size(44, 32),
                              ),
                              child: Text(
                                'View',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.vSpaceSm,
                        Text(
                          step.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            height: 1.4,
                          ),
                        ),
                        AppSpacing.vSpaceSm,
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: step.keyPoints.map((point) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : CustomerLuxuryTheme.borderLight,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                point,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              AppSpacing.vSpaceLg,

              // --------------------------------------------------------------
              // 4. Roastery FAQ Accordion Section
              // --------------------------------------------------------------
              Text(
                'Frequently Asked Questions',
                style: CustomerLuxuryTheme.editorialStyle(
                  isDark: isDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              AppSpacing.vSpaceSm,

              _buildFaqItem(
                question: 'How does Pickup Ordering work?',
                answer:
                    'All Lambac orders are prepared fresh for pickup at our Flagship Roastery. When placing your order, select a preset prep slot (+1 hr, +3 hrs, +5 hrs) or custom time. When your order reaches "Ready for Pickup", arrive at our roastery counter to claim it.',
                isDark: isDark,
              ),
              _buildFaqItem(
                question: 'Why do I pay at the counter?',
                answer:
                    'Lambac uses a "Pay at Counter" policy so you can inspect your packaged micro-lots and roast dates before paying. No online credit card charges are processed in the app. We accept Cash, GCash/Maya QR, and Debit/Credit cards at the counter.',
                isDark: isDark,
              ),
              _buildFaqItem(
                question: 'How do I choose the best grind size for my equipment?',
                answer:
                    'We offer 5 precision grind options calibrated on Mahlkönig grinders: Whole Bean (ideal if you grind fresh), Espresso (fine), V60 Pourover (medium-fine), French Press (coarse), and Cold Brew (extra coarse). Feel free to message our baristas in Concierge Chat for personalized advice!',
                isDark: isDark,
              ),
              _buildFaqItem(
                question: 'How does the AI Assistant help me?',
                answer:
                    'Our built-in AI Assistant is specialized in Lambac Coffee Roastery products, brewing guidelines, store operating hours, and order policies. For personalized orders or special requests, the assistant seamlessly routes your conversation to our active barista team.',
                isDark: isDark,
              ),
              _buildFaqItem(
                question: 'What are Coffee Beans loyalty points?',
                answer:
                    'Members earn Coffee Beans points with every completed pickup order. Points can be redeemed for free tasting flights, micro-lot upgrades, and exclusive reserve batches.',
                isDark: isDark,
              ),
              AppSpacing.vSpaceXxl,

              // --------------------------------------------------------------
              // 5. Contact Concierge Card
              // --------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(20),
                decoration: CustomerLuxuryTheme.cardDecoration(isDark: isDark, isElevated: true),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.brandAmber : AppColors.brandAmber).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.forum_rounded,
                        size: 26,
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                      ),
                    ),
                    AppSpacing.vSpaceSm,
                    Text(
                      'Still have questions?',
                      style: CustomerLuxuryTheme.editorialStyle(
                        isDark: isDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.vSpaceXs,
                    Text(
                      'Our master baristas are available on the Roastery Concierge Chat to assist with your brewing and order questions.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.vSpaceMd,
                    AppButton.primary(
                      text: 'Chat with Barista Team',
                      leadingIcon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 16),
                      size: AppButtonSize.small,
                      onPressed: () => context.push(AppRoutes.chat),
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpaceXxxl,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, TutorialCategory? category, bool isDark) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
        selected: isSelected,
        showCheckmark: false,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        selectedColor: isDark ? AppColors.brandAmber : AppColors.brandAmber,
        side: BorderSide(
          color: isSelected
              ? AppColors.brandAmber
              : (isDark ? AppColors.darkBorder : CustomerLuxuryTheme.borderLight),
          width: 0.9,
        ),
        onSelected: (_) {
          setState(() => _selectedCategory = category);
        },
      ),
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? CustomerLuxuryTheme.darkEspressoSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusLg,
          side: BorderSide(
            color: isDark ? CustomerLuxuryTheme.borderDark : CustomerLuxuryTheme.borderLight,
            width: 0.8,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          collapsedIconColor: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
          iconColor: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
          title: Text(
            question,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          children: [
            Text(
              answer,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
