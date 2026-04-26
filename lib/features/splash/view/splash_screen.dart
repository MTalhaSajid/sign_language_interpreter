import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _loaderCtrl;

  // ── Animations ─────────────────────────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _pulseScale;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  // ── Colors ─────────────────────────────────────────────────────────────────
  static const _bg        = Color(0xFF080E1C);
  static const _teal      = Color(0xFF0ABFA3);
  static const _blue      = Color(0xFF3D6BFF);
  static const _dotColor  = Color(0xFF1E2A40);
  static const _mutedText = Color(0xFF4A5880);
  static const _loaderBg  = Color(0xFF1A2236);
  static const _dimText   = Color(0xFF222D44);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _initAnimations();
    _runSequence();
  }

  void _initAnimations() {
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _loaderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  Future<void> _runSequence() async {
    // 1. Logo animates in
    await _logoCtrl.forward();

    // 2. Short pause then text slides up
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _textCtrl.forward();

    // 3. Minimum splash display time
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // 4. Navigate — router redirect guard handles auth check
    context.go('/login');
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    _textCtrl.dispose();
    _loaderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Dot grid background
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter(_dotColor)),
          ),
          // Top-left teal glow
          Positioned(
            top: -80,
            left: -60,
            child: _glowCircle(_teal, 260, 0.10),
          ),
          // Bottom-right blue glow
          Positioned(
            bottom: -100,
            right: -70,
            child: _glowCircle(_blue, 300, 0.09),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogo(),
                const SizedBox(height: 32),
                _buildText(),
                const SizedBox(height: 64),
                _buildLoader(),
              ],
            ),
          ),
          // Version
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textOpacity,
              child: const Text(
                'v1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: _dimText,
                  letterSpacing: 2.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoOpacity,
      child: ScaleTransition(
        scale: _logoScale,
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, child) =>
              Transform.scale(scale: _pulseScale.value, child: child),
          child: Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _teal.withOpacity(0.20), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_teal, _blue],
                  ),
                ),
                child: const Center(
                  child: Text('🤟', style: TextStyle(fontSize: 40)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildText() {
    return SlideTransition(
      position: _textSlide,
      child: FadeTransition(
        opacity: _textOpacity,
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_teal, _blue],
              ).createShader(bounds),
              child: const Text(
                'SignBridge',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'SIGN LANGUAGE · INTERPRETED',
              style: TextStyle(
                fontSize: 10,
                color: _mutedText,
                letterSpacing: 3.5,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return FadeTransition(
      opacity: _textOpacity,
      child: Column(
        children: [
          SizedBox(
            width: 110,
            height: 2,
            child: AnimatedBuilder(
              animation: _loaderCtrl,
              builder: (_, __) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(color: _loaderBg),
                      FractionallySizedBox(
                        widthFactor: 0.45,
                        child: Transform.translate(
                          offset: Offset(
                            (_loaderCtrl.value * 110 * 2.5) - 50,
                            0,
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_teal, _blue],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'INITIALIZING',
            style: TextStyle(
              fontSize: 9,
              color: _dimText,
              letterSpacing: 2.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color dotColor;
  const _DotGridPainter(this.dotColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    const spacing = 22.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter old) =>
      old.dotColor != dotColor;
}