import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_styles.dart';
import '../../../providers/theme_provider.dart';

class WordToSignScreen extends StatefulWidget {
  const WordToSignScreen({super.key});

  @override
  State<WordToSignScreen> createState() => _WordToSignScreenState();
}

class _WordToSignScreenState extends State<WordToSignScreen> {
  final _searchController = TextEditingController();
  String _selectedWord = '';
  String _searchQuery = '';

  static const _words = [
    'Hello', 'Help', 'ILoveYou', 'Please', 'Sorry', 'Yes',
  ];

  // Display label for each word
  static const _labels = {
    'Hello':   'Hello',
    'Help':    'Help',
    'ILoveYou': 'I Love You',
    'Please':  'Please',
    'Sorry':   'Sorry',
    'Yes':     'Yes',
  };

  static const _colors = {
    'Hello':   AppColors.teal,
    'Help':    AppColors.blue,
    'ILoveYou': Color(0xFF9B6EFF),
    'Please':  Color(0xFF4CAF50),
    'Sorry':   Color(0xFFFF9800),
    'Yes':     Color(0xFF2196F3),
  };

  static const _emojis = {
    'Hello':   '👋',
    'Help':    '🆘',
    'ILoveYou': '👍',
    'Please':  '🙏',
    'Sorry':   '😔',
    'Yes':     '✅',
  };

  String _imagePath(String word) =>
      'assets/images/dataset_words/$word/${word}_1.jpg';

  List<String> get _filteredWords {
    if (_searchQuery.isEmpty) return _words;
    return _words
        .where((w) =>
            (_labels[w] ?? w)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                // ── Header ──────────────────────────────────────────────
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
                          Text('Word to Sign',
                              style: AppFonts.headingMedium.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface)),
                          Text('Tap a word to see its sign',
                              style: AppFonts.bodySmall.copyWith(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Search ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v),
                    style: AppFonts.bodyMedium
                        .copyWith(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Search words...',
                      hintStyle: AppFonts.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 18, color: AppColors.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(Icons.clear_rounded,
                                  size: 16,
                                  color: AppColors.textSecondary),
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: AppStyles.radiusMd,
                        borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppStyles.radiusMd,
                        borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppStyles.radiusMd,
                        borderSide: const BorderSide(
                            color: AppColors.teal, width: 1.5),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Word grid ────────────────────────────────────────────
                Expanded(
                  child: _filteredWords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off_rounded,
                                  size: 48,
                                  color: AppColors.textSecondary),
                              const SizedBox(height: 12),
                              Text('No word found',
                                  style: AppFonts.bodyMedium.copyWith(
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: _filteredWords.length,
                          itemBuilder: (context, index) {
                            final word = _filteredWords[index];
                            final isSelected = _selectedWord == word;
                            final color =
                                _colors[word] ?? AppColors.teal;
                            final label = _labels[word] ?? word;
                            final emoji = _emojis[word] ?? '';

                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedWord =
                                    isSelected ? '' : word;
                              }),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color.withOpacity(0.12)
                                      : Theme.of(context)
                                          .colorScheme
                                          .surface,
                                  borderRadius: AppStyles.radiusLg,
                                  border: Border.all(
                                    color: isSelected
                                        ? color
                                        : Theme.of(context).dividerColor,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Sign image
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.fromLTRB(
                                                8, 8, 8, 4),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.asset(
                                            _imagePath(word),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder:
                                                (_, __, ___) =>
                                                    Container(
                                              decoration: BoxDecoration(
                                                color: color
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        8),
                                              ),
                                              child: Center(
                                                child: Text(emoji,
                                                    style: const TextStyle(
                                                        fontSize: 40)),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Word label
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 10, top: 2),
                                      child: Text(
                                        label,
                                        style: AppFonts.headingSmall
                                            .copyWith(
                                          fontSize: 13,
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

                // ── Full image detail panel ───────────────────────────────
                if (_selectedWord.isNotEmpty)
                  _buildDetailPanel(_selectedWord),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(String word) {
    final color = _colors[word] ?? AppColors.teal;
    final label = _labels[word] ?? word;
    final emoji = _emojis[word] ?? '';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppStyles.radiusLg,
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          // Large sign image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              _imagePath(word),
              width: 90, height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 40))),
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
                    Text(label,
                        style: TextStyle(
                            fontSize: 24,
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
                      child: Text('ASL WORD',
                          style: AppFonts.labelCaps
                              .copyWith(color: color, fontSize: 7)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Hold the sign steady for 1.5s\nin Sign to Word screen to recognize it.',
                    style: AppFonts.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedWord = ''),
            child: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}