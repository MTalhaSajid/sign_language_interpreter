import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_styles.dart';
import '../../../providers/theme_provider.dart';
import '../controller/auth_controller.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = context.read<AuthController>();
    final success = await controller.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (success && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
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
    final textDim =
        isDark ? AppColors.textDim : const Color(0xFFADB5BD);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Glows
          Positioned(
            top: -80, left: -80,
            child: Container(
              width: 280, height: 280,
              decoration: AppStyles.glowDecoration(
                  AppColors.teal, isDark ? 0.10 : 0.06),
            ),
          ),
          Positioned(
            bottom: -80, right: -80,
            child: Container(
              width: 280, height: 280,
              decoration: AppStyles.glowDecoration(
                  AppColors.blue, isDark ? 0.10 : 0.06),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ── Top hero section ─────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 48, 24, 36),
                      child: Column(
                        children: [
                          // Icon with glow ring
                          Container(
                            width: 88, height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.teal.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // App name with gradient
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                                    colors: [
                                  AppColors.teal,
                                  AppColors.blue
                                ]).createShader(bounds),
                            child: Text(
                              'Sign Talk',
                              style: AppFonts.displayLarge.copyWith(
                                color: Colors.white,
                                fontSize: 30,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Sign in to your account',
                            style: AppFonts.bodyMedium
                                .copyWith(color: textSecondary),
                          ),
                        ],
                      ),
                    ),

                    // ── Form card ────────────────────────────────────
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: AppStyles.radiusLg,
                        border:
                            Border.all(color: borderColor, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EMAIL', style: AppFonts.labelCaps),
                          const SizedBox(height: 6),
                          ThemedField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            nextFocus: _passwordFocus,
                            hintText: 'you@example.com',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: Icons.mail_outline_rounded,
                            surfaceColor: isDark
                                ? AppColors.bgDark
                                : const Color(0xFFF5F7FA),
                            borderColor: borderColor,
                            textColor: textPrimary,
                            hintColor: textDim,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Email is required';
                              }
                              if (!v.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          Text('PASSWORD', style: AppFonts.labelCaps),
                          const SizedBox(height: 6),
                          ThemedField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            hintText: '••••••••',
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            prefixIcon: Icons.lock_outline_rounded,
                            surfaceColor: isDark
                                ? AppColors.bgDark
                                : const Color(0xFFF5F7FA),
                            borderColor: borderColor,
                            textColor: textPrimary,
                            hintColor: textDim,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: textSecondary,
                              ),
                              onPressed: () => setState(() =>
                                  _obscurePassword = !_obscurePassword),
                            ),
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password is required';
                              }
                              if (v.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 0, vertical: 6)),
                              child: Text('Forgot password?',
                                  style: AppFonts.link),
                            ),
                          ),

                          // Error
                          if (controller.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: AppStyles.errorDecoration(),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      size: 16, color: AppColors.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      controller.errorMessage!,
                                      style: AppFonts.bodySmall.copyWith(
                                          color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          const SizedBox(height: 4),

                          GradientButton(
                            label: 'Sign In',
                            isLoading: controller.isLoading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),

                    // ── Sign up ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ",
                              style: AppFonts.bodyMedium
                                  .copyWith(color: textDim)),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child:
                                Text('Sign up', style: AppFonts.link),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}