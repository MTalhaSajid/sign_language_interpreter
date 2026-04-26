import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_styles.dart';
import '../../../providers/theme_provider.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/settings_controller.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settingsController = context.watch<SettingsController>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Top glow
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: AppStyles.glowDecoration(AppColors.blue, 0.06),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: AppStyles.cardDecoration(),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text('Settings', style: AppFonts.headingMedium),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Expanded(
                  child: ListView(
                    padding: AppStyles.paddingPage,
                    children: [
                      // ── Appearance ──────────────────────────────────────
                      _SectionLabel(label: 'Appearance'),
                      const SizedBox(height: 8),
                      _SettingsCard(
                        children: [
                          _ToggleTile(
                            icon: isDark
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                            title: 'Dark Mode',
                            subtitle: isDark
                                ? 'Dark theme enabled'
                                : 'Light theme enabled',
                            value: isDark,
                            onChanged: (_) => themeProvider.toggleTheme(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Account ─────────────────────────────────────────
                      _SectionLabel(label: 'Account'),
                      const SizedBox(height: 8),
                      _SettingsCard(
                        children: [
                          _ActionTile(
                            icon: Icons.logout_rounded,
                            iconColor: AppColors.error,
                            title: 'Log out',
                            titleColor: AppColors.error,
                            onTap: () => _confirmLogout(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── About ────────────────────────────────────────────
                      _SectionLabel(label: 'About'),
                      const SizedBox(height: 8),
                      _SettingsCard(
                        children: [
                          _InfoTile(
                            icon: Icons.apps_rounded,
                            title: 'App',
                            value: settingsController.appName,
                          ),
                          _Divider(),
                          _InfoTile(
                            icon: Icons.tag_rounded,
                            title: 'Version',
                            value: settingsController.appVersion,
                          ),
                          _Divider(),
                          _InfoTile(
                            icon: Icons.shield_outlined,
                            title: 'Build',
                            value: 'Stable',
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // ── Footer ────────────────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: AppStyles.logoDecoration(),
                              child: const Center(
                                child:
                                    Text('🤟', style: TextStyle(fontSize: 18)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'SignBridge',
                              style: AppFonts.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'v${settingsController.appVersion}',
                              style: AppFonts.caption,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log out', style: AppFonts.headingSmall),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to log out?',
                style: AppFonts.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ctx.pop(false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.bgBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppStyles.radiusMd),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppFonts.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => ctx.pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: AppStyles.radiusMd),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Log out',
                        style: AppFonts.bodyMedium
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthController>().logout();
      if (context.mounted) context.go('/login');
    }
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(), style: AppFonts.labelCaps);
  }
}

// ── Settings card wrapper ─────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppStyles.cardDecoration(),
      child: Column(children: children),
    );
  }
}

// ── Toggle tile ───────────────────────────────────────────────────────────────
class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: AppStyles.radiusSm,
            ),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppFonts.bodyLarge.copyWith(fontSize: 14)),
                Text(subtitle, style: AppFonts.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.teal,
            inactiveTrackColor: AppColors.bgBorder,
            inactiveThumbColor: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

// ── Action tile (e.g. logout) ─────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppStyles.radiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                borderRadius: AppStyles.radiusSm,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppFonts.bodyLarge
                  .copyWith(fontSize: 14, color: titleColor),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Info tile ─────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: AppStyles.radiusSm,
            ),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: AppFonts.bodyLarge.copyWith(fontSize: 14),
          ),
          const Spacer(),
          Text(value, style: AppFonts.bodyMedium),
        ],
      ),
    );
  }
}

// ── Thin divider ──────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.bgBorder,
      indent: 64,
    );
  }
}