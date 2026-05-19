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
                // ── Top bar ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 36, height: 36,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Sign Talk',
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

                // ── Welcome ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
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

                // ── Hero card ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: _HeroCard(
                        onTap: () => context.go('/interpreter')),
                  ),
                ),

                // ── Section label ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                    child: Text('MORE FEATURES',
                        style: AppFonts.labelCaps.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.5))),
                  ),
                ),

                // ── Feature grid ──────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    delegate: SliverChildListDelegate([
                      _FeatureCard(
                        emoji: '✍️',
                        title: 'Word to Sign',
                        subtitle: 'Type a word, see its sign',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1A3A5C), Color(0xFF0F2240)],
                        ),
                        accentColor: AppColors.blue,
                        onTap: () => context.go('/word-to-sign'),
                      ),
                      _FeatureCard(
                        emoji: '🔍',
                        title: 'Sign to Word',
                        subtitle: 'Live interpretation of sign to word',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0A2A2A), Color(0xFF051A1A)],
                        ),
                        accentColor: AppColors.teal,
                        onTap: () => context.go('/sign-to-word'),
                      ),
                      _FeatureCard(
                        emoji: '🔤',
                        title: 'Alphabet To Sign',
                        subtitle: 'See The Sign Of Alphabets',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2A1A3A), Color(0xFF1A0F2A)],
                        ),
                        accentColor: Color(0xFF9B6EFF),
                        onTap: () => context.go('/alphabet'),
                      ),
                      _FeatureCard(
                        emoji: '📹',
                        title: 'Video Call',
                        subtitle: 'Sign language video call',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1A2A1A), Color(0xFF0F1A0F)],
                        ),
                        accentColor: Color(0xFF4CAF50),
                        onTap: () => context.go('/video-call'),
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

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero card — overlap fixed ─────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final VoidCallback onTap;
  const _HeroCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppStyles.radiusLg,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.teal, AppColors.blue],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // ── Left: icon ──────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 72, height: 72,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 16),

            // ── Right: text + badge ─────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: AppStyles.radiusFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5, height: 5,
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text('LIVE',
                            style: AppFonts.labelCaps.copyWith(
                                color: Colors.white, fontSize: 9)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text('Live Interpreter',
                      style: AppFonts.headingSmall
                          .copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Real-time sign language\nrecognition',
                      style: AppFonts.bodySmall
                          .copyWith(color: Colors.white70)),

                  const SizedBox(height: 12),

                  // Start button
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: AppStyles.radiusMd,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text('Start',
                            style: AppFonts.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
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
  final String emoji, title, subtitle;
  final LinearGradient gradient;
  final Color accentColor;
  final VoidCallback onTap;

  const _FeatureCard({
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
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(isDark ? 0.15 : 0.1),
                borderRadius: AppStyles.radiusMd,
              ),
              child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 20))),
            ),
            const Spacer(),
            Text(title,
                style: AppFonts.headingSmall.copyWith(
                  fontSize: 14,
                  color: isDark
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                )),
            const SizedBox(height: 3),
            Text(subtitle,
                style: AppFonts.bodySmall.copyWith(
                  color: isDark
                      ? Colors.white54
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}