import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_styles.dart';
import '../../../providers/theme_provider.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/home_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().loadUsers();
    });
  }

  // ── Pagination — logic unchanged ───────────────────────────────────────────
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<HomeController>().loadUsers(isLoadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();
    final authController = context.watch<AuthController>();
    final isDark =
        context.watch<ThemeProvider>().themeMode == ThemeMode.dark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));

    final bgColor =
        isDark ? AppColors.bgDark : const Color(0xFFF5F7FA);
    final surfaceColor =
        isDark ? AppColors.bgSurface : Colors.white;
    final borderColor =
        isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final textPrimary =
        isDark ? AppColors.textPrimary : const Color(0xFF0A0E1A);
    final textSecondary =
        isDark ? AppColors.textSecondary : const Color(0xFF4A5568);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Glow
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: AppStyles.glowDecoration(
                  AppColors.teal, isDark ? 0.07 : 0.04),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Header ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      // Logo + app name
                      Container(
                        width: 36, height: 36,
                        decoration: AppStyles.logoDecoration(),
                        child: const Center(
                            child: Text('🤟',
                                style: TextStyle(fontSize: 18))),
                      ),
                      const SizedBox(width: 10),
                      Text('SignBridge',
                          style: AppFonts.headingSmall
                              .copyWith(color: textPrimary)),

                      const Spacer(),

                      // Settings icon
                      GestureDetector(
                        onTap: () => context.go('/settings'),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: AppStyles.radiusMd,
                            border: Border.all(
                                color: borderColor, width: 1),
                          ),
                          child: Icon(Icons.settings_outlined,
                              size: 18, color: textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Welcome banner ──────────────────────────────────────
                Padding(
                  padding: AppStyles.paddingPage,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: AppStyles.radiusLg,
                      gradient: AppColors.brandGradient,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${authController.currentUser?.displayName?.split(' ').first ?? 'there'} 👋',
                          style: AppFonts.headingSmall
                              .copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ready to interpret sign language?',
                          style: AppFonts.bodyMedium
                              .copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () =>
                              context.go('/interpreter'), // TODO: interpreter route
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: AppStyles.radiusMd,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_arrow_rounded,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text('Start interpreting',
                                    style: AppFonts.bodyMedium.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Section header ──────────────────────────────────────
                Padding(
                  padding: AppStyles.paddingPage,
                  child: Row(
                    children: [
                      Text('Recent Users',
                          style: AppFonts.headingSmall
                              .copyWith(color: textPrimary)),
                      const Spacer(),
                      Text('${controller.users.length} total',
                          style: AppFonts.bodySmall
                              .copyWith(color: textSecondary)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Users list — logic unchanged ────────────────────────
                Expanded(
                  child: controller.isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.teal,
                            strokeWidth: 2,
                          ),
                        )
                      : controller.users.isEmpty
                          ? _EmptyState(isDark: isDark)
                          : ListView.separated(
                              controller: _scrollController,
                              padding: AppStyles.paddingPage,
                              itemCount: controller.users.length +
                                  (controller.isFetchingMore ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                if (index == controller.users.length) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: CircularProgressIndicator(
                                        color: AppColors.teal,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }
                                final user = controller.users[index];
                                return _UserCard(
                                  name: user.name,
                                  email: user.email,
                                  index: index,
                                  surfaceColor: surfaceColor,
                                  borderColor: borderColor,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── User card ─────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final String name, email;
  final int index;
  final Color surfaceColor, borderColor, textPrimary, textSecondary;

  const _UserCard({
    required this.name,
    required this.email,
    required this.index,
    required this.surfaceColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  // Cycle through brand colors for avatars
  Color get _avatarColor {
    const colors = [AppColors.teal, AppColors.blue];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppStyles.radiusMd,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _avatarColor.withOpacity(0.15),
              borderRadius: AppStyles.radiusMd,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _avatarColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppFonts.bodyLarge.copyWith(
                        fontSize: 14, color: textPrimary)),
                const SizedBox(height: 2),
                Text(email,
                    style:
                        AppFonts.bodySmall.copyWith(color: textSecondary),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: textSecondary),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.1),
              borderRadius: AppStyles.radiusLg,
            ),
            child: const Icon(Icons.people_outline_rounded,
                size: 28, color: AppColors.teal),
          ),
          const SizedBox(height: 16),
          Text('No users yet',
              style: AppFonts.headingSmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondary
                      : const Color(0xFF4A5568))),
          const SizedBox(height: 4),
          Text('Users will appear here once loaded.',
              style: AppFonts.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textDim
                      : const Color(0xFFADB5BD))),
        ],
      ),
    );
  }
}