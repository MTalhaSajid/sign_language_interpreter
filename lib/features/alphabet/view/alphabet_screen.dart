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

  static const _letters = [
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','Space','T','U','V','W','X','Y','Z',
  ];

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

  // Image path: assets/images/datase_for_hand_to_alphabet/A/A_right_1.jpg
  String _imagePath(String letter) =>
      'assets/images/datase_for_hand_to_alphabet/$letter/${letter}_right_1.jpg';

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
                // ── Header ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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

                // ── Grid ────────────────────────────────────────────────────
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: _letters.length,
                    itemBuilder: (context, index) {
                      final letter = _letters[index];
                      final isSelected = _selectedLetter == letter;
                      final color = _letterColor(letter);

                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedLetter = isSelected ? null : letter;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.15)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: AppStyles.radiusMd,
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : Theme.of(context).dividerColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // ── Real hand image ──────────────────────────
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.asset(
                                      _imagePath(letter),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      // Fallback if image missing
                                      errorBuilder: (_, __, ___) => Container(
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Center(
                                          child: Text(
                                            letter == 'Space' ? '␣' : letter,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: color,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // ── Letter label ─────────────────────────────
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 6, top: 2),
                                child: Text(
                                  letter,
                                  style: AppFonts.headingSmall.copyWith(
                                    fontSize: letter == 'Space' ? 8 : 13,
                                    color: isSelected
                                        ? color
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Detail panel ─────────────────────────────────────────
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppStyles.radiusLg,
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          // Large real image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              _imagePath(letter),
              width: 80, height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    letter == 'Space' ? '␣' : letter,
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: color),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(letter,
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: color)),
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
                Text(desc,
                    style: AppFonts.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedLetter = null),
            child: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}