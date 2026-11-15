import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../data/models/terms_and_conditions_data.dart';
import '../providers/auth_provider.dart';

/// Full-Screen Mandatory First-Login Terms & Conditions Acceptance Screen
///
/// Enforces scroll-to-bottom reading requirement before the agreement checkbox
/// and Continue button become enabled. Also supports non-destructive "review mode"
/// when launched from Settings.
class TermsAndConditionsScreen extends ConsumerStatefulWidget {
  final bool isReviewMode;

  const TermsAndConditionsScreen({
    super.key,
    this.isReviewMode = false,
  });

  @override
  ConsumerState<TermsAndConditionsScreen> createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends ConsumerState<TermsAndConditionsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TermsAndConditionsDocument _doc = TermsAndConditionsDocument.current;

  bool _hasReachedBottom = false;
  bool _isAgreed = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfScrollable();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _checkIfScrollable() {
    if (!mounted || !_scrollController.hasClients) return;
    // If content fits completely on screen without scrolling (or in landscape)
    if (_scrollController.position.maxScrollExtent <= 12) {
      setState(() => _hasReachedBottom = true);
    }
  }

  void _onScroll() {
    if (_hasReachedBottom || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 24) {
      setState(() => _hasReachedBottom = true);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleContinue() async {
    if (!_hasReachedBottom) {
      AppToast.warning(context, 'Please scroll through the entire document to the bottom.');
      return;
    }
    if (!_isAgreed) {
      AppToast.warning(context, 'Please check the agreement checkbox to continue.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await ref.read(authNotifierProvider.notifier).acceptTerms(
      version: _doc.version,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (user) {
        AppToast.success(context, 'Terms & Conditions accepted. Welcome to Lambac Roastery!');
        // Note: AuthRouterListenable automatically notifies GoRouter and appRouteGuard
        // redirects user to getRoleHomeRoute(user).
      },
      failure: (failure) {
        setState(() {
          _errorMessage = failure.message;
        });
      },
    );
  }

  Future<void> _handleDecline() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Terms & Conditions?'),
        content: const Text(
          'If you decline, you will be signed out of your account. '
          'You will not be able to access coffee ordering, concierge chat, or account services until the Terms & Conditions are accepted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Decline & Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12100E) : const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1613) : Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? AppColors.brandAmber.withValues(alpha: 0.15) : AppColors.brandAmber.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusSm,
              ),
              child: const Icon(
                Icons.local_cafe_rounded,
                size: 18,
                color: AppColors.brandAmber,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LAMBAC COFFEE ROASTERY',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                    ),
                  ),
                  Text(
                    'Terms & Conditions',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.isReviewMode)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            )
          else
            TextButton(
              onPressed: _isSubmitting ? null : _handleDecline,
              child: Text(
                'Decline',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContentContainer(
          maxWidth: ResponsiveLayout.maxReadingWidth,
          child: Column(
            children: [
              // Top Metadata Header Banner
              _buildVersionBanner(isDark),

              // Error Banner if persistence failed
              if (_errorMessage != null) _buildErrorBanner(isDark),

              // Scrollable Document Content Box
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1613) : Colors.white,
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C241E) : const Color(0xFFE8E0D5),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.radiusMd,
                    child: RawScrollbar(
                      controller: _scrollController,
                      thumbColor: isDark ? AppColors.brandAmber.withValues(alpha: 0.5) : AppColors.brandAmber.withValues(alpha: 0.4),
                      thickness: 5,
                      radius: const Radius.circular(8),
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Document Title & Effective Date
                            Text(
                              _doc.title,
                              style: GoogleFonts.cinzel(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Version ${_doc.version} • Effective ${_doc.effectiveDate}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Introduction
                            Text(
                              _doc.introduction,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                height: 1.6,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Divider(
                              color: isDark ? const Color(0xFF2C241E) : const Color(0xFFE8E0D5),
                              height: 1,
                            ),
                            const SizedBox(height: 20),

                            // 10 Detailed Sections
                            ..._doc.sections.map((section) => _buildSection(section, isDark)),

                            // Closing Statement
                            Container(
                              margin: const EdgeInsets.only(top: 10, bottom: 20),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF241E1A) : const Color(0xFFF5EFE6),
                                borderRadius: AppRadius.radiusSm,
                                border: Border.all(
                                  color: isDark ? AppColors.brandAmber.withValues(alpha: 0.3) : AppColors.brandAmber.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.verified_user_outlined,
                                    size: 20,
                                    color: AppColors.brandAmber,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _doc.closingStatement,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        height: 1.5,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Bottom Anchor Marker
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  '— End of Document —',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    letterSpacing: 1.1,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Action Area
              if (widget.isReviewMode)
                _buildReviewModeBottom(isDark)
              else
                _buildMandatoryAcceptanceBottom(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      color: isDark ? const Color(0xFF1E1A16) : const Color(0xFFF0EAE1),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.isReviewMode
                  ? 'Reviewing active roastery terms & policies.'
                  : 'Please read the entire document to unlock acceptance.',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          if (!_hasReachedBottom && !widget.isReviewMode)
            GestureDetector(
              onTap: _scrollToBottom,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.brandAmber.withValues(alpha: 0.15) : AppColors.brandAmber.withValues(alpha: 0.1),
                  borderRadius: AppRadius.radiusXs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Scroll down',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 12,
                      color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: AppRadius.radiusSm,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage ?? 'Failed to save acceptance. Please check connection and retry.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: _isSubmitting ? null : _handleContinue,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(TermsSection section, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.content,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.55,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          if (section.bulletPoints.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...section.bulletPoints.map(
              (point) => Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 10),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          height: 1.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMandatoryAcceptanceBottom(bool isDark) {
    final canContinue = _hasReachedBottom && _isAgreed && !_isSubmitting;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1613) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2C241E) : const Color(0xFFE8E0D5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Agreement Checkbox Row
          InkWell(
            onTap: _hasReachedBottom
                ? () {
                    setState(() => _isAgreed = !_isAgreed);
                  }
                : () {
                    AppToast.info(context, 'Please scroll through to the bottom to unlock agreement.');
                  },
            borderRadius: AppRadius.radiusSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _isAgreed,
                      onChanged: _hasReachedBottom
                          ? (val) {
                              setState(() => _isAgreed = val ?? false);
                            }
                          : null,
                      activeColor: AppColors.brandAmber,
                      checkColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'I have read and agree to the Terms & Conditions.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _hasReachedBottom
                            ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                            : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scroll Guidance Helper Status
          if (!_hasReachedBottom)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 2, bottom: 8),
              child: Text(
                'Scroll to the end of the document to enable agreement.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark ? AppColors.brandAmberLight : AppColors.brandAmberDark,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Primary Continue Button
          AppButton(
            text: 'Continue',
            onPressed: canContinue ? _handleContinue : null,
            isLoading: _isSubmitting,
            variant: AppButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewModeBottom(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1613) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2C241E) : const Color(0xFFE8E0D5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Active Document • Version ${_doc.version}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppButton(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            variant: AppButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}
