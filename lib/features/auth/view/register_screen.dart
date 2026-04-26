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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = context.read<AuthController>();
    final success = await controller.register(
      _nameController.text.trim(),
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
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: AppStyles.glowDecoration(
                  AppColors.blue, isDark ? 0.07 : 0.04),
            ),
          ),
          Positioned(
            bottom: -80, left: -60,
            child: Container(
              width: 240, height: 240,
              decoration: AppStyles.glowDecoration(
                  AppColors.teal, isDark ? 0.06 : 0.03),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: AppStyles.paddingPage,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Back button
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: AppStyles.radiusMd,
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: textSecondary),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Logo
                    Container(
                      width: 44, height: 44,
                      decoration: AppStyles.logoDecoration(),
                      child: const Center(
                          child: Text('🤟',
                              style: TextStyle(fontSize: 22))),
                    ),

                    const SizedBox(height: 20),

                    Text('Create account',
                        style: AppFonts.headingLarge
                            .copyWith(color: textPrimary)),
                    const SizedBox(height: 4),
                    Text('Start interpreting sign language today',
                        style: AppFonts.bodyMedium
                            .copyWith(color: textSecondary)),

                    const SizedBox(height: 32),

                    // Name
                    Text('FULL NAME', style: AppFonts.labelCaps),
                    const SizedBox(height: 6),
                    ThemedField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      nextFocus: _emailFocus,
                      hintText: 'John Doe',
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.person_outline_rounded,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textPrimary,
                      hintColor: textDim,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Name is required';
                        }
                        if (v.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Email
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
                      surfaceColor: surfaceColor,
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

                    // Password
                    Text('PASSWORD', style: AppFonts.labelCaps),
                    const SizedBox(height: 6),
                    ThemedField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      nextFocus: _confirmFocus,
                      hintText: '••••••••',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.lock_outline_rounded,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textPrimary,
                      hintColor: textDim,
                      onChanged: (_) => setState(() {}),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18, color: textSecondary,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
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

                    if (_passwordController.text.isNotEmpty)
                      _PasswordStrength(
                          password: _passwordController.text),

                    const SizedBox(height: 16),

                    // Confirm password
                    Text('CONFIRM PASSWORD', style: AppFonts.labelCaps),
                    const SizedBox(height: 6),
                    ThemedField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmFocus,
                      hintText: '••••••••',
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icons.lock_outline_rounded,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textPrimary,
                      hintColor: textDim,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18, color: textSecondary,
                        ),
                        onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (v != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

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
                                style: AppFonts.bodySmall
                                    .copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Create account button
                    GradientButton(
                      label: 'Create Account',
                      isLoading: controller.isLoading,
                      onPressed: _submit,
                    ),

                    const SizedBox(height: 24),

                    // Sign in redirect
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Already have an account? ',
                              style: AppFonts.bodyMedium
                                  .copyWith(color: textDim)),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Text('Sign in', style: AppFonts.link),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
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

// ── Password strength ─────────────────────────────────────────────────────────
class _PasswordStrength extends StatelessWidget {
  final String password;
  const _PasswordStrength({required this.password});

  int get _score {
    int s = 0;
    if (password.length >= 6) s++;
    if (password.length >= 10) s++;
    if (password.contains(RegExp(r'[A-Z]'))) s++;
    if (password.contains(RegExp(r'[0-9]'))) s++;
    if (password.contains(RegExp(r'[!@#\$%^&*]'))) s++;
    return s;
  }

  String get _label =>
      _score <= 1 ? 'Weak' : _score <= 3 ? 'Fair' : 'Strong';

  Color get _color => _score <= 1
      ? AppColors.error
      : _score <= 3
          ? Colors.orangeAccent
          : AppColors.teal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          ...List.generate(
            5,
            (i) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                height: 3,
                decoration: BoxDecoration(
                  color: i < _score ? _color : AppColors.bgLoader,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(_label,
              style: AppFonts.bodySmall.copyWith(
                  color: _color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}