import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controller/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  // ── Colors (matches splash palette) ───────────────────────────────────────
  static const _bg       = Color(0xFF080E1C);
  static const _surface  = Color(0xFF0F1623);
  static const _border   = Color(0xFF1E2A40);
  static const _teal     = Color(0xFF0ABFA3);
  static const _blue     = Color(0xFF3D6BFF);
  static const _textPri  = Color(0xFFE8EDF5);
  static const _textMid  = Color(0xFF4A5880);
  static const _textDim  = Color(0xFF2E3D5A);

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
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Submit — logic unchanged from original ─────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<AuthController>();
    final success = await controller.login(
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
          // Top-right teal glow (matches splash)
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_teal.withOpacity(0.07), Colors.transparent],
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
                    _BackButton(
                      border: _border,
                      surface: _surface,
                      iconColor: _textMid,
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
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: _textPri,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sign in to continue interpreting',
                      style: TextStyle(
                        fontSize: 13,
                        color: _textMid,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Email field ──────────────────────────────────────
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

                    // ── Password field ───────────────────────────────────
                    _FieldLabel(text: 'Password', color: _textMid),
                    const SizedBox(height: 6),
                    _AppField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      hintText: '••••••••',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
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
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    // ── Forgot password ──────────────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {}, // TODO: wire forgot password
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 8),
                        ),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            fontSize: 12,
                            color: _teal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // ── Error message (unchanged logic) ──────────────────
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
                                  fontSize: 12,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Sign in button ───────────────────────────────────
                    _GradientButton(
                      label: 'Sign In',
                      isLoading: controller.isLoading,
                      teal: _teal,
                      blue: _blue,
                      onPressed: _submit,
                    ),

                    const SizedBox(height: 24),

                    // ── Divider ──────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(child: Divider(color: _border, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or continue with',
                            style: TextStyle(
                                fontSize: 11, color: _textDim),
                          ),
                        ),
                        Expanded(child: Divider(color: _border, thickness: 1)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Social buttons ───────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            label: 'Google',
                            surface: _surface,
                            border: _border,
                            textColor: _textMid,
                            icon: _googleIcon(),
                            onPressed: () {}, // TODO: Google sign in
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SocialButton(
                            label: 'GitHub',
                            surface: _surface,
                            border: _border,
                            textColor: _textMid,
                            icon: _githubIcon(_textMid),
                            onPressed: () {}, // TODO: GitHub sign in
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ── Sign up redirect ─────────────────────────────────
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style:
                                TextStyle(fontSize: 13, color: _textDim),
                          ),
                          GestureDetector(
                            onTap: () =>
                                context.go('/register'), // TODO: register route
                            child: const Text(
                              'Sign up',
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

  Widget _googleIcon() => SizedBox(
        width: 16,
        height: 16,
        child: CustomPaint(painter: _GooglePainter()),
      );

  Widget _githubIcon(Color color) => Icon(Icons.code, size: 16, color: color);
}

// ── Reusable widgets ────────────────────────────────────────────────────────

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
    widget.focusNode.addListener(() {
      setState(() => _focused = widget.focusNode.hasFocus);
    });
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
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
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

class _SocialButton extends StatelessWidget {
  final String label;
  final Color surface, border, textColor;
  final Widget icon;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.surface,
    required this.border,
    required this.textColor,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: surface,
        side: BorderSide(color: border, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 13),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
                fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final Color border, surface, iconColor;
  const _BackButton(
      {required this.border, required this.surface, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (Navigator.canPop(context)) Navigator.pop(context);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1),
        ),
        child: Icon(Icons.arrow_back_ios_new_rounded,
            size: 16, color: iconColor),
      ),
    );
  }
}

// ── Google G painter ──────────────────────────────────────────────────────────
class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paints = [
      Paint()..color = const Color(0xFF4285F4),
      Paint()..color = const Color(0xFF34A853),
      Paint()..color = const Color(0xFFFBBC05),
      Paint()..color = const Color(0xFFEA4335),
    ];

    // Simple 4-quadrant G approximation
    canvas.drawArc(Rect.fromLTWH(0, 0, s, s), -0.3, 1.9, false,
        paints[0]..style = PaintingStyle.stroke..strokeWidth = s * 0.28);
    canvas.drawArc(Rect.fromLTWH(0, 0, s, s), 1.6, 1.1, false,
        paints[1]..style = PaintingStyle.stroke..strokeWidth = s * 0.28);
    canvas.drawArc(Rect.fromLTWH(0, 0, s, s), 2.7, 0.9, false,
        paints[2]..style = PaintingStyle.stroke..strokeWidth = s * 0.28);
    canvas.drawArc(Rect.fromLTWH(0, 0, s, s), 3.6, 0.9, false,
        paints[3]..style = PaintingStyle.stroke..strokeWidth = s * 0.28);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}