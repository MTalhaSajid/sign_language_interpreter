import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controller/auth_controller.dart';

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

  // ── Colors (matches splash + login palette) ────────────────────────────────
  static const _bg      = Color(0xFF080E1C);
  static const _surface = Color(0xFF0F1623);
  static const _border  = Color(0xFF1E2A40);
  static const _teal    = Color(0xFF0ABFA3);
  static const _blue    = Color(0xFF3D6BFF);
  static const _textPri = Color(0xFFE8EDF5);
  static const _textMid = Color(0xFF4A5880);
  static const _textDim = Color(0xFF2E3D5A);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

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

    if (success && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Top-right blue glow
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_blue.withOpacity(0.07), Colors.transparent],
                ),
              ),
            ),
          ),
          // Bottom-left teal glow
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_teal.withOpacity(0.06), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ── Back button ──────────────────────────────────────
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border, width: 1),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: _textMid,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Logo mark ────────────────────────────────────────
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_teal, _blue],
                        ),
                      ),
                      child: const Center(
                        child: Text('🤟', style: TextStyle(fontSize: 22)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Heading ──────────────────────────────────────────
                    const Text(
                      'Create account',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: _textPri,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Start interpreting sign language today',
                      style: TextStyle(fontSize: 13, color: _textMid),
                    ),

                    const SizedBox(height: 32),

                    // ── Full name ────────────────────────────────────────
                    _FieldLabel(text: 'Full name', color: _textMid),
                    const SizedBox(height: 6),
                    _AppField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      nextFocus: _emailFocus,
                      hintText: 'John Doe',
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      surface: _surface,
                      border: _border,
                      teal: _teal,
                      textColor: _textPri,
                      hintColor: _textDim,
                      prefixIcon: Icons.person_outline_rounded,
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

                    // ── Email ────────────────────────────────────────────
                    _FieldLabel(text: 'Email', color: _textMid),
                    const SizedBox(height: 6),
                    _AppField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      nextFocus: _passwordFocus,
                      hintText: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      surface: _surface,
                      border: _border,
                      teal: _teal,
                      textColor: _textPri,
                      hintColor: _textDim,
                      prefixIcon: Icons.mail_outline_rounded,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Password ─────────────────────────────────────────
                    _FieldLabel(text: 'Password', color: _textMid),
                    const SizedBox(height: 6),
                    _AppField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      nextFocus: _confirmFocus,
                      hintText: '••••••••',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      surface: _surface,
                      border: _border,
                      teal: _teal,
                      textColor: _textPri,
                      hintColor: _textDim,
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: _textMid,
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

                    const SizedBox(height: 16),

                    // ── Confirm password ─────────────────────────────────
                    _FieldLabel(text: 'Confirm password', color: _textMid),
                    const SizedBox(height: 6),
                    _AppField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmFocus,
                      hintText: '••••••••',
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      surface: _surface,
                      border: _border,
                      teal: _teal,
                      textColor: _textPri,
                      hintColor: _textDim,
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: _textMid,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
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

                    const SizedBox(height: 8),

                    // ── Password strength hint ───────────────────────────
                    _PasswordStrengthRow(
                      password: _passwordController.text,
                      teal: _teal,
                      blue: _blue,
                      dimColor: _textDim,
                    ),

                    const SizedBox(height: 20),

                    // ── Error message ────────────────────────────────────
                    if (controller.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.red.withOpacity(0.25), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                size: 16, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                controller.errorMessage!,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Create account button ────────────────────────────
                    _GradientButton(
                      label: 'Create Account',
                      isLoading: controller.isLoading,
                      teal: _teal,
                      blue: _blue,
                      onPressed: _submit,
                    ),

                    const SizedBox(height: 24),

                    // ── Sign in redirect ─────────────────────────────────
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(fontSize: 13, color: _textDim),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: const Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 13,
                                color: _teal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

// ── Password strength indicator ───────────────────────────────────────────────
class _PasswordStrengthRow extends StatelessWidget {
  final String password;
  final Color teal, blue, dimColor;

  const _PasswordStrengthRow({
    required this.password,
    required this.teal,
    required this.blue,
    required this.dimColor,
  });

  int get _strength {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 10) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$%^&*]'))) score++;
    return score;
  }

  String get _label {
    if (password.isEmpty) return '';
    if (_strength <= 1) return 'Weak';
    if (_strength <= 3) return 'Fair';
    return 'Strong';
  }

  Color get _color {
    if (_strength <= 1) return Colors.redAccent;
    if (_strength <= 3) return Colors.orangeAccent;
    return teal;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          ...List.generate(5, (i) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                height: 3,
                decoration: BoxDecoration(
                  color: i < _strength ? _color : const Color(0xFF1A2236),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          Text(
            _label,
            style: TextStyle(
              fontSize: 11,
              color: _color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets (same as login_screen.dart) ────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _FieldLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        color: color,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _AppField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Color surface, border, teal, textColor, hintColor;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _AppField({
    required this.controller,
    required this.focusNode,
    this.nextFocus,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    required this.textInputAction,
    required this.surface,
    required this.border,
    required this.teal,
    required this.textColor,
    required this.hintColor,
    required this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  State<_AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<_AppField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(
        () => setState(() => _focused = widget.focusNode.hasFocus));
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted ??
          (_) {
            if (widget.nextFocus != null) {
              FocusScope.of(context).requestFocus(widget.nextFocus);
            }
          },
      validator: widget.validator,
      style: TextStyle(fontSize: 14, color: widget.textColor),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(fontSize: 14, color: widget.hintColor),
        prefixIcon: Icon(
          widget.prefixIcon,
          size: 18,
          color: _focused ? widget.teal : widget.hintColor,
        ),
        suffixIcon: widget.suffixIcon,
        filled: true,
        fillColor: widget.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.teal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(
            fontSize: 11, color: Colors.redAccent, height: 1.4),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final Color teal, blue;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    required this.teal,
    required this.blue,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: isLoading
                ? [teal.withOpacity(0.5), blue.withOpacity(0.5)]
                : [teal, blue],
          ),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}