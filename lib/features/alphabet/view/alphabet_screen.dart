import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_styles.dart';
import '../../../providers/theme_provider.dart';

class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  String? _selectedLetter;

  // All 27 labels matching our model
  static const _letters = [
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','Space','T','U','V','W','X','Y','Z',
  ];

  // Description for each sign
  static const _descriptions = {
    'A': 'Make a fist with thumb resting on the side',
    'B': 'Hold four fingers straight up, thumb tucked across palm',
    'C': 'Curve hand into a C shape',
    'D': 'Index finger points up, other fingers and thumb form a circle',
    'E': 'Curl all fingers down, thumb tucked under',
    'F': 'Connect index finger and thumb, other three fingers up',
    'G': 'Index finger and thumb point sideways like a gun',
    'H': 'Index and middle finger point sideways together',
    'I': 'Pinky finger up, rest of hand in a fist',
    'J': 'Make I shape then trace a J in the air',
    'K': 'Index and middle finger up in a V, thumb between them',
    'L': 'Index finger points up, thumb points out (L shape)',
    'M': 'Three fingers folded over tucked thumb',
    'N': 'Two fingers folded over tucked thumb',
    'O': 'All fingers curve to touch thumb forming an O',
    'P': 'Like K but pointing downward',
    'Q': 'Like G but pointing downward',
    'R': 'Cross index and middle fingers',
    'S': 'Fist with thumb over fingers',
    'Space': 'Open palm facing forward — indicates a space between words',
    'T': 'Fist with thumb between index and middle fingers',
    'U': 'Index and middle finger up together',
    'V': 'Index and middle finger spread in a V (peace sign)',
    'W': 'Three fingers spread up (index, middle, ring)',
    'X': 'Index finger bent like a hook',
    'Y': 'Thumb and pinky out, other fingers curled',
    'Z': 'Index finger traces letter Z in the air',
  };

  // Finger configuration for each letter
  // Format: [thumb, index, middle, ring, pinky] — 0=down, 1=up, 2=bent
  static const _fingerConfig = {
    'A': [0, 0, 0, 0, 0], // fist, thumb on side
    'B': [0, 1, 1, 1, 1], // four fingers up
    'C': [2, 2, 2, 2, 2], // all curved
    'D': [2, 1, 2, 2, 2], // index up, rest curved
    'E': [0, 2, 2, 2, 2], // all bent down
    'F': [2, 0, 1, 1, 1], // index+thumb circle
    'G': [1, 1, 0, 0, 0], // index+thumb sideways
    'H': [0, 1, 1, 0, 0], // index+middle sideways
    'I': [0, 0, 0, 0, 1], // pinky up
    'J': [0, 0, 0, 0, 1], // pinky up + motion
    'K': [1, 1, 1, 0, 0], // index+middle+thumb
    'L': [1, 1, 0, 0, 0], // index up, thumb out
    'M': [0, 2, 2, 2, 0], // three fingers over thumb
    'N': [0, 2, 2, 0, 0], // two fingers over thumb
    'O': [2, 2, 2, 2, 2], // O shape
    'P': [1, 1, 1, 0, 0], // like K pointing down
    'Q': [1, 1, 0, 0, 0], // like G pointing down
    'R': [0, 1, 1, 0, 0], // crossed fingers
    'S': [0, 0, 0, 0, 0], // fist, thumb over
    'Space': [1, 1, 1, 1, 1], // open palm
    'T': [0, 0, 0, 0, 0], // fist, thumb between
    'U': [0, 1, 1, 0, 0], // two fingers up
    'V': [0, 1, 1, 0, 0], // peace sign
    'W': [0, 1, 1, 1, 0], // three fingers
    'X': [0, 2, 0, 0, 0], // hooked index
    'Y': [1, 0, 0, 0, 1], // thumb+pinky
    'Z': [0, 1, 0, 0, 0], // index traces Z
  };

  // Accent color per letter group
  Color _letterColor(String letter) {
    if ('AEIOU'.contains(letter)) return AppColors.teal;
    if (letter == 'Space') return const Color(0xFF9B6EFF);
    const colors = [
      AppColors.blue,
      Color(0xFF2196F3),
      Color(0xFF00BCD4),
      Color(0xFF4CAF50),
      Color(0xFFFF9800),
    ];
    return colors[letter.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        context.watch<ThemeProvider>().themeMode == ThemeMode.dark;

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
              decoration: AppStyles.glowDecoration(
                  AppColors.teal, isDark ? 0.07 : 0.04),
            ),
          ),
          Positioned(
            bottom: -80, left: -60,
            child: Container(
              width: 220, height: 220,
              decoration: AppStyles.glowDecoration(
                  AppColors.blue, isDark ? 0.06 : 0.03),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/'),
                        child: Container(
                          width: 40, height: 40,
                          decoration: AppStyles.cardDecoration(),
                          child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sign Alphabet',
                              style: AppFonts.headingMedium.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface)),
                          Text('ASL A–Z Reference',
                              style: AppFonts.bodySmall.copyWith(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Grid ─────────────────────────────────────────────
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _letters.length,
                    itemBuilder: (context, index) {
                      final letter = _letters[index];
                      final isSelected = _selectedLetter == letter;
                      final color = _letterColor(letter);
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedLetter =
                              isSelected ? null : letter;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.15)
                                : Theme.of(context)
                                    .colorScheme
                                    .surface,
                            borderRadius: AppStyles.radiusMd,
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : Theme.of(context).dividerColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              // Hand illustration
                              SizedBox(
                                width: 52, height: 52,
                                child: CustomPaint(
                                  painter: _HandPainter(
                                    letter: letter,
                                    config: _fingerConfig[letter] ??
                                        [0, 0, 0, 0, 0],
                                    color: color,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Letter label
                              Text(
                                letter,
                                style: AppFonts.headingSmall.copyWith(
                                  fontSize: letter == 'Space' ? 9 : 14,
                                  color: isSelected
                                      ? color
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Detail panel ──────────────────────────────────────
                if (_selectedLetter != null)
                  _buildDetailPanel(_selectedLetter!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(String letter) {
    final color = _letterColor(letter);
    final desc = _descriptions[letter] ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppStyles.radiusLg,
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          // Large hand illustration
          SizedBox(
            width: 80, height: 80,
            child: CustomPaint(
              painter: _HandPainter(
                letter: letter,
                config: _fingerConfig[letter] ?? [0, 0, 0, 0, 0],
                color: color,
                isDark: true,
                scale: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      letter,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: AppStyles.radiusFull,
                      ),
                      child: Text('ASL',
                          style: AppFonts.labelCaps
                              .copyWith(color: color, fontSize: 8)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedLetter = null),
            child: Icon(Icons.close_rounded,
                size: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Hand painter ──────────────────────────────────────────────────────────────
class _HandPainter extends CustomPainter {
  final String letter;
  final List<int> config; // [thumb, index, middle, ring, pinky]
  final Color color;
  final bool isDark;
  final double scale;

  const _HandPainter({
    required this.letter,
    required this.config,
    required this.color,
    required this.isDark,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final palmColor =
        isDark ? const Color(0xFF1E3A4A) : const Color(0xFFE8F5E9);
    final skinColor = isDark ? const Color(0xFF2A4A5A) : const Color(0xFFD4A878);
    final fingerColor = color;

    final palmPaint = Paint()
      ..color = palmColor
      ..style = PaintingStyle.fill;

    final fingerPaint = Paint()
      ..color = fingerColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Palm
    final palmRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(cx, cy + 8 * scale),
          width: 32 * scale,
          height: 22 * scale),
      Radius.circular(8 * scale),
    );
    canvas.drawRRect(palmRect, palmPaint);
    canvas.drawRRect(palmRect, outlinePaint);

    // Finger positions [x offset from center, base y]
    final fingerPositions = [
      [-11.0, 0.0],  // index
      [-3.5,  -2.0], // middle
      [4.0,   -1.0], // ring
      [11.0,  1.0],  // pinky
    ];

    // Draw 4 fingers (index, middle, ring, pinky)
    for (int i = 0; i < 4; i++) {
      final fingerIdx = i + 1; // config index (0=thumb, 1=index...)
      final state = config[fingerIdx]; // 0=down, 1=up, 2=bent
      final fx = cx + fingerPositions[i][0] * scale;
      final baseY = cy + fingerPositions[i][1] * scale;

      if (state == 1) {
        // Up
        final fingerH = (12 + (i == 1 ? 4 : 0)) * scale;
        final fingerW = 5.5 * scale;
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(fx, baseY - fingerH / 2 - 2 * scale),
              width: fingerW,
              height: fingerH),
          Radius.circular(fingerW / 2),
        );
        canvas.drawRRect(rect, fingerPaint);
        canvas.drawRRect(rect, outlinePaint);
      } else if (state == 2) {
        // Bent
        final path = Path();
        final w = 5.5 * scale;
        path.addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(fx, baseY - 4 * scale),
              width: w,
              height: 8 * scale),
          Radius.circular(w / 2),
        ));
        canvas.drawPath(path, fingerPaint);
        canvas.drawPath(path, outlinePaint);
      }
      // state==0: hidden in palm — draw nothing
    }

    // Thumb
    final thumbState = config[0];
    final thumbX = cx - 18 * scale;
    final thumbY = cy + 4 * scale;

    if (thumbState == 1) {
      // Thumb out
      final thumbRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(thumbX - 4 * scale, thumbY),
            width: 7 * scale,
            height: 11 * scale),
        const Radius.circular(4),
      );
      canvas.drawRRect(thumbRect, fingerPaint);
      canvas.drawRRect(thumbRect, outlinePaint);
    } else if (thumbState == 2) {
      // Thumb bent/circle
      canvas.drawCircle(
        Offset(thumbX, thumbY),
        4 * scale,
        fingerPaint,
      );
      canvas.drawCircle(
        Offset(thumbX, thumbY),
        4 * scale,
        outlinePaint,
      );
    }

    // Special letter indicators
    _drawSpecialIndicator(canvas, size, cx, cy);
  }

  void _drawSpecialIndicator(
      Canvas canvas, Size size, double cx, double cy) {
    final indicatorPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    switch (letter) {
      case 'J':
      case 'Z':
        // Motion arrow
        final arrowPath = Path();
        arrowPath.moveTo(cx + 12 * scale, cy - 8 * scale);
        arrowPath.lineTo(cx + 18 * scale, cy - 4 * scale);
        arrowPath.lineTo(cx + 12 * scale, cy);
        canvas.drawPath(arrowPath, indicatorPaint);
        break;
      case 'Space':
        // Open palm indicator lines
        final linePaint = Paint()
          ..color = color.withOpacity(0.4)
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(cx - 14 * scale, cy - 12 * scale),
          Offset(cx - 14 * scale, cy + 4 * scale),
          linePaint,
        );
        canvas.drawLine(
          Offset(cx + 14 * scale, cy - 12 * scale),
          Offset(cx + 14 * scale, cy + 4 * scale),
          linePaint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _HandPainter old) =>
      old.letter != letter || old.color != color || old.isDark != isDark;
}