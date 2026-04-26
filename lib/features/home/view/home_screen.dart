import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_styles.dart';
import '../../../providers/theme_provider.dart';
import '../../auth/controller/auth_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final isDark =
        context.watch<ThemeProvider>().themeMode == ThemeMode.dark;
    final theme = Theme.of(context);
    final firstName = authController.currentUser?.displayName
            ?.split(' ')
            .first ??
        'there';

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      body: Stack(
        children: [
          // Glows
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 260, height: 260,
              decoration: AppStyles.glowDecoration(
                  AppColors.teal, isDark ? 0.08 : 0.05),
            ),
          ),
          Positioned(
            bottom: -100, left: -60,
            child: Container(
              width: 260, height: 260,
              decoration: AppStyles.glowDecoration(
                  AppColors.blue, isDark ? 0.07 : 0.04),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Top bar ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: AppStyles.logoDecoration(),
                          child: const Center(
                              child: Text('🤟',
                                  style: TextStyle(fontSize: 18))),
                        ),
                        const SizedBox(width: 10),
                        Text('SignBridge',
                            style: AppFonts.headingSmall.copyWith(
                                color: theme.colorScheme.onSurface)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.go('/settings'),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: AppStyles.radiusMd,
                              border: Border.all(
                                  color: theme.dividerColor, width: 1),
                            ),
                            child: Icon(Icons.settings_outlined,
                                size: 18,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Welcome ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $firstName 👋',
                          style: AppFonts.displayLarge.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'What would you like to do today?',
                          style: AppFonts.bodyMedium.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.5)),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Hero feature card ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: _HeroCard(
                      onTap: () =>
                          context.go('/interpreter'),
                    ),
                  ),
                ),

                // ── Section label ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 28, 24, 8),
                    child: Text(
                      'MORE FEATURES',
                      style: AppFonts.labelCaps.copyWith(
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.5)),
                    ),
                  ),
                ),

                // ── Feature grid ─────────────────────────────────────
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    delegate: SliverChildListDelegate([
                      _FeatureCard(
                        icon: Icons.text_fields_rounded,
                        emoji: '✍️',
                        title: 'Word to Sign',
                        subtitle: 'Type a word, see its sign',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1A3A5C),
                            Color(0xFF0F2240),
                          ],
                        ),
                        accentColor: AppColors.blue,
                        onTap: () =>
                            context.go('/word-to-sign'),
                      ),
                      _FeatureCard(
                        icon: Icons.image_search_rounded,
                        emoji: '🔍',
                        title: 'Sign to Word',
                        subtitle: 'Upload a sign image',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0A2A2A),
                            Color(0xFF051A1A),
                          ],
                        ),
                        accentColor: AppColors.teal,
                        onTap: () =>
                            context.go('/sign-to-word'),
                      ),
                      _FeatureCard(
                        icon: Icons.sort_by_alpha_rounded,
                        emoji: '🔤',
                        title: 'Sign Alphabet',
                        subtitle: 'Browse A–Z signs',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2A1A3A),
                            Color(0xFF1A0F2A),
                          ],
                        ),
                        accentColor: Color(0xFF9B6EFF),
                        onTap: () =>
                            context.go('/alphabet'),
                      ),
                    ]),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                    child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero card — live interpreter ──────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final VoidCallback onTap;
  const _HeroCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: AppStyles.radiusLg,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.teal, AppColors.blue],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20, top: -20,
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              right: 20, bottom: -30,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: AppStyles.radiusFull,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text('LIVE',
                                style: AppFonts.labelCaps.copyWith(
                                    color: Colors.white,
                                    fontSize: 9)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Live Interpreter',
                    style: AppFonts.headingMedium
                        .copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time sign language recognition',
                    style: AppFonts.bodyMedium
                        .copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Arrow
            Positioned(
              right: 20, bottom: 20,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: AppStyles.radiusMd,
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 18),
              ),
            ),

            // Large hand emoji
            Positioned(
              right: 24, top: 0, bottom: 0,
              child: Center(
                child: Text('🤟',
                    style: const TextStyle(fontSize: 64)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feature card ──────────────────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String emoji, title, subtitle;
  final LinearGradient gradient;
  final Color accentColor;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        context.watch<ThemeProvider>().themeMode == ThemeMode.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: AppStyles.radiusLg,
          // dark: rich gradient bg, light: clean surface with accent border
          color: isDark ? null : Theme.of(context).colorScheme.surface,
          gradient: isDark ? gradient : null,
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon box
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(isDark ? 0.15 : 0.1),
                borderRadius: AppStyles.radiusMd,
              ),
              child: Center(
                child: Text(emoji,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: AppFonts.headingSmall.copyWith(
                fontSize: 14,
                color: isDark
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: AppFonts.bodySmall.copyWith(
                color: isDark
                    ? Colors.white54
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}