import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_styles.dart';
import '../../../providers/theme_provider.dart';

class WordToSignScreen extends StatefulWidget {
  const WordToSignScreen({super.key});

  @override
  State<WordToSignScreen> createState() => _WordToSignScreenState();
}

class _WordToSignScreenState extends State<WordToSignScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Reference tab ──────────────────────────────────────────────────────────
  final _searchController = TextEditingController();
  String _selectedWord = '';
  String _searchQuery = '';

  static const _words = ['Hello', 'Help', 'ILoveYou', 'Please', 'Sorry', 'Yes'];
  static const _labels = {
    'Hello': 'Hello', 'Help': 'Help', 'I Love You': 'I Love You',
    'Please': 'Please', 'Sorry': 'Sorry', 'Yes': 'Yes',
  };
  static const _colors = {
    'Hello': AppColors.teal, 'Help': AppColors.blue,
    'I Love You': Color(0xFF9B6EFF), 'Please': Color(0xFF4CAF50),
    'Sorry': Color(0xFFFF9800), 'Yes': Color(0xFF2196F3),
  };
  static const _emojis = {
    'Hello': '👋', 'Help': '🆘', 'I Love You': '👍',
    'Please': '🙏', 'Sorry': '😔', 'Yes': '✅',
  };

  String _imagePath(String word) =>
      'assets/images/dataset_words/$word/${word}_1.jpg';

  List<String> get _filteredWords {
    if (_searchQuery.isEmpty) return _words;
    return _words
        .where((w) => (_labels[w] ?? w)
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // ── Upload & identify tab ──────────────────────────────────────────────────
  Interpreter? _interpreter;
  File? _uploadedImage;
  String? _predictedLabel;
  double _confidence = 0.0;
  bool _isProcessing = false;
  String? _uploadError;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      final data =
          await rootBundle.load('assets/model/word_cnn_model.tflite');
      _interpreter = Interpreter.fromBuffer(
        data.buffer.asUint8List(),
        options: InterpreterOptions()..threads = 2,
      );
      setState(() {});
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked =
        await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    setState(() {
      _uploadedImage = File(picked.path);
      _predictedLabel = null;
      _confidence = 0.0;
      _uploadError = null;
    });
    await _predict();
  }

  Future<void> _predict() async {
    if (_uploadedImage == null || _interpreter == null) return;
    setState(() => _isProcessing = true);
    try {
      final bytes = await _uploadedImage!.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        setState(() => _uploadError = 'Could not decode image');
        return;
      }
      final size = image.width < image.height ? image.width : image.height;
      image = img.copyCrop(image,
          x: (image.width - size) ~/ 2,
          y: (image.height - size) ~/ 2,
          width: size, height: size);
      image = img.copyResize(image, width: 224, height: 224,
          interpolation: img.Interpolation.linear);

      final input = Float32List(224 * 224 * 3);
      int idx = 0;
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final p = image.getPixel(x, y);
          input[idx++] = p.r / 255.0;
          input[idx++] = p.g / 255.0;
          input[idx++] = p.b / 255.0;
        }
      }
      final output =
          List.filled(_words.length, 0.0).reshape([1, _words.length]);
      _interpreter!.run(input.reshape([1, 224, 224, 3]), output);
      final probs = List<double>.from(output[0] as List);
      int maxIdx = 0;
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > probs[maxIdx]) maxIdx = i;
      }
      setState(() {
        _predictedLabel = _words[maxIdx];
        _confidence = probs[maxIdx];
      });
    } catch (e) {
      setState(() => _uploadError = 'Prediction failed');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _interpreter?.close();
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
          Positioned(top: -80, right: -60,
            child: Container(width: 220, height: 220,
              decoration: AppStyles.glowDecoration(
                  AppColors.teal, isDark ? 0.07 : 0.04))),
          Positioned(bottom: -80, left: -60,
            child: Container(width: 220, height: 220,
              decoration: AppStyles.glowDecoration(
                  AppColors.blue, isDark ? 0.06 : 0.03))),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/'),
                        child: Container(
                          width: 40, height: 40,
                          decoration: AppStyles.cardDecoration(),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 16, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Word to Sign',
                              style: AppFonts.headingMedium.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface)),
                          Text('Browse signs or identify from photo',
                              style: AppFonts.bodySmall
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Tab bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: AppStyles.radiusMd,
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: AppStyles.radiusMd,
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: AppFonts.bodySmall
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: '  Sign Reference  '),
                        Tab(text: '  Identify Sign  '),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReferenceTab(),
                      _buildUploadTab(),
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

  // ── Tab 1: Reference ───────────────────────────────────────────────────────
  Widget _buildReferenceTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: AppFonts.bodyMedium.copyWith(color: AppColors.textPrimary),
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
                          size: 16, color: AppColors.textSecondary))
                  : null,
              filled: true,
              fillColor: AppColors.bgSurface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: AppStyles.radiusMd,
                  borderSide:
                      const BorderSide(color: AppColors.bgBorder, width: 1)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: AppStyles.radiusMd,
                  borderSide:
                      const BorderSide(color: AppColors.bgBorder, width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: AppStyles.radiusMd,
                  borderSide:
                      const BorderSide(color: AppColors.teal, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _filteredWords.isEmpty
              ? Center(
                  child: Text('No word found',
                      style: AppFonts.bodyMedium
                          .copyWith(color: AppColors.textSecondary)))
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: _filteredWords.length,
                  itemBuilder: (context, index) {
                    final word = _filteredWords[index];
                    final isSelected = _selectedWord == word;
                    final color = _colors[word] ?? AppColors.teal;
                    final label = _labels[word] ?? word;
                    final emoji = _emojis[word] ?? '';
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedWord = isSelected ? '' : word;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.12)
                              : AppColors.bgSurface,
                          borderRadius: AppStyles.radiusLg,
                          border: Border.all(
                            color: isSelected ? color : AppColors.bgBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(8, 8, 8, 4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    _imagePath(word),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => Container(
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                          child: Text(emoji,
                                              style: const TextStyle(
                                                  fontSize: 40))),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 10, top: 2),
                              child: Text(label,
                                  style: AppFonts.headingSmall.copyWith(
                                    fontSize: 13,
                                    color: isSelected
                                        ? color
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_selectedWord.isNotEmpty) _buildDetailPanel(_selectedWord),
      ],
    );
  }

  // ── Tab 2: Upload & Identify ───────────────────────────────────────────────
  Widget _buildUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Upload area
          GestureDetector(
            onTap: () => _pickImage(ImageSource.gallery),
            child: Container(
              height: 240, width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: AppStyles.radiusLg,
                border: Border.all(
                  color: _uploadedImage != null
                      ? AppColors.teal.withOpacity(0.4)
                      : AppColors.bgBorder,
                  width: _uploadedImage != null ? 1.5 : 1,
                ),
              ),
              child: _uploadedImage != null
                  ? ClipRRect(
                      borderRadius: AppStyles.radiusLg,
                      child: Stack(fit: StackFit.expand, children: [
                        Image.file(_uploadedImage!, fit: BoxFit.cover),
                        if (_isProcessing)
                          Container(
                            color: Colors.black.withOpacity(0.55),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                      color: AppColors.teal, strokeWidth: 2),
                                  SizedBox(height: 12),
                                  Text('Identifying sign...',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                      ]),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.teal.withOpacity(0.1),
                            borderRadius: AppStyles.radiusLg,
                          ),
                          child: const Icon(Icons.upload_rounded,
                              size: 28, color: AppColors.teal),
                        ),
                        const SizedBox(height: 14),
                        Text('Tap to upload a sign photo',
                            style: AppFonts.headingSmall
                                .copyWith(color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text('or use buttons below',
                            style: AppFonts.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 14),

          // Pick buttons
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.1),
                    borderRadius: AppStyles.radiusMd,
                    border: Border.all(
                        color: AppColors.teal.withOpacity(0.35)),
                  ),
                  child: const Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.photo_library_rounded,
                        color: AppColors.teal, size: 20),
                    SizedBox(height: 5),
                    Text('Gallery',
                        style: TextStyle(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickImage(ImageSource.camera),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.1),
                    borderRadius: AppStyles.radiusMd,
                    border: Border.all(
                        color: AppColors.blue.withOpacity(0.35)),
                  ),
                  child: const Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.camera_alt_rounded,
                        color: AppColors.blue, size: 20),
                    SizedBox(height: 5),
                    Text('Camera',
                        style: TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ]),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 16),

          if (_uploadError != null)
            _buildErrorBadge(_uploadError!)
          else if (_predictedLabel != null && !_isProcessing)
            _buildPredictionResult(),

          const SizedBox(height: 16),
          _buildSupportedSigns(),
        ],
      ),
    );
  }

  Widget _buildPredictionResult() {
    final label = _labels[_predictedLabel] ?? _predictedLabel!;
    final emoji = _emojis[_predictedLabel] ?? '';
    final isHigh = _confidence > 0.80;
    final isMed = _confidence > 0.60;
    final confColor =
        isHigh ? AppColors.teal : isMed ? Colors.orangeAccent : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppStyles.radiusLg,
        border: Border.all(color: confColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 44)),
        const SizedBox(height: 10),
        Text(label,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900, color: confColor)),
        const SizedBox(height: 12),
        Row(children: [
          Text('Confidence',
              style: AppFonts.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Text('${(_confidence * 100).toStringAsFixed(1)}%',
              style: AppFonts.bodySmall.copyWith(
                  color: confColor, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _confidence, minHeight: 6,
            backgroundColor: AppColors.bgDark,
            valueColor: AlwaysStoppedAnimation<Color>(confColor),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isHigh
              ? '✓ High confidence result'
              : isMed
                  ? '⚠ Medium confidence — try a clearer photo'
                  : '✗ Low confidence — better lighting recommended',
          style: AppFonts.bodySmall.copyWith(color: confColor),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  Widget _buildErrorBadge(String error) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: AppStyles.radiusMd,
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(error,
                style: AppFonts.bodySmall.copyWith(color: AppColors.error))),
      ]),
    );
  }

  Widget _buildSupportedSigns() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppStyles.radiusMd,
        border: Border.all(color: AppColors.bgBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Supported signs',
            style: AppFonts.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 6,
          children: _words.map((w) {
            final e = _emojis[w] ?? '';
            final d = _labels[w] ?? w;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.08),
                borderRadius: AppStyles.radiusFull,
                border:
                    Border.all(color: AppColors.teal.withOpacity(0.2)),
              ),
              child: Text('$e $d',
                  style: AppFonts.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Text('💡 Clear background + good lighting = better accuracy',
            style: AppFonts.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildDetailPanel(String word) {
    final color = _colors[word] ?? AppColors.teal;
    final label = _labels[word] ?? word;
    final emoji = _emojis[word] ?? '';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppStyles.radiusLg,
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(_imagePath(word),
              width: 80, height: 80, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 36))),
              )),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: color)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: AppStyles.radiusFull,
                  ),
                  child: Text('ASL WORD',
                      style: AppFonts.labelCaps
                          .copyWith(color: color, fontSize: 7)),
                ),
              ]),
              const SizedBox(height: 4),
              Text('Switch to "Identify Sign" tab to recognize from photo',
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
      ]),
    );
  }
}