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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
              width: 220, height: 220,
              decoration:
                  AppStyles.glowDecoration(AppColors.blue, 0.06),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/'),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: AppStyles.radiusMd,
                            border: Border.all(
                              color: theme.dividerColor,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text('Settings',
                          style: theme.textTheme.headlineMedium),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Expanded(
                  child: ListView(
                    padding: AppStyles.paddingPage,
                    children: [
                      // ── Appearance ──────────────────────────────────
                      _SectionLabel('Appearance'),
                      const SizedBox(height: 8),
                      _SettingsCard(children: [
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
                      ]),

                      const SizedBox(height: 24),

                      // ── Account ─────────────────────────────────────
                      _SectionLabel('Account'),
                      const SizedBox(height: 8),
                      _SettingsCard(children: [
                        _ActionTile(
                          icon: Icons.logout_rounded,
                          iconColor: AppColors.error,
                          title: 'Log out',
                          titleColor: AppColors.error,
                          onTap: () => _confirmLogout(context),
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // ── About ────────────────────────────────────────
                      _SectionLabel('About'),
                      const SizedBox(height: 8),
                      _SettingsCard(children: [
                        _InfoTile(
                          icon: Icons.apps_rounded,
                          title: 'App',
                          value: settingsController.appName,
                        ),
                        const _CardDivider(),
                        _InfoTile(
                          icon: Icons.tag_rounded,
                          title: 'Version',
                          value: settingsController.appVersion,
                        ),
                        const _CardDivider(),
                        _InfoTile(
                          icon: Icons.shield_outlined,
                          title: 'Build',
                          value: 'Stable',
                        ),
                      ]),

                      const SizedBox(height: 40),

                      // ── Footer ───────────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: AppStyles.logoDecoration(),
                              child: const Center(
                                child: Text('🤟',
                                    style: TextStyle(fontSize: 18)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'SignBridge',
                              style: theme.textTheme.labelSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'v${settingsController.appVersion}',
                              style: theme.textTheme.bodySmall,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
            borderRadius: AppStyles.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log out',
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to log out?',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ctx.pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: theme.dividerColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppStyles.radiusMd),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                      ),
                      child: Text('Cancel',
                          style: theme.textTheme.bodyMedium),
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        minimumSize: Size.zero,
                      ),
                      child: Text('Log out',
                          style: AppFonts.bodyMedium
                              .copyWith(color: Colors.white)),
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
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}

// ── Card wrapper ──────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppStyles.radiusMd,
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(children: children),
    );
  }
}

// ── Toggle tile ───────────────────────────────────────────────────────────────
class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: AppStyles.radiusSm,
            ),
            child: Icon(icon, size: 18,
                color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontSize: 14)),
                Text(subtitle,
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.teal,
            inactiveTrackColor: theme.dividerColor,
            inactiveThumbColor:
                theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ],
      ),
    );
  }
}

// ── Action tile ───────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, titleColor;
  final String title;
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
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppStyles.radiusMd,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                borderRadius: AppStyles.radiusSm,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Text(title,
                style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 14, color: titleColor)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

// ── Info tile ─────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title, value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: AppStyles.radiusSm,
            ),
            child: Icon(icon, size: 18,
                color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
          const SizedBox(width: 12),
          Text(title,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontSize: 14)),
          const Spacer(),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ── Divider ───────────────────────────────────────────────────────────────────
class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor,
      indent: 64,
    );
  }
}