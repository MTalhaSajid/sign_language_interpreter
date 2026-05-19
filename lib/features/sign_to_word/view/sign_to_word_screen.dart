import 'dart:typed_data';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_styles.dart';

class SignToWordScreen extends StatefulWidget {
  const SignToWordScreen({super.key});

  @override
  State<SignToWordScreen> createState() => _SignToWordScreenState();
}

class _SignToWordScreenState extends State<SignToWordScreen> {
  // ── Camera ─────────────────────────────────────────────────────────────────
  CameraController? _camera;
  bool _cameraReady = false;
  List<CameraDescription> _cameras = [];
  bool _isFrontCamera = false;

  // ── Model ──────────────────────────────────────────────────────────────────
  Interpreter? _interpreter;
  bool _modelReady = false;

  static const _labels = [
    'Hello', 'Help', 'ILikeIt', 'Please', 'Sorry', 'Yes'
  ];

  // ── Prediction ─────────────────────────────────────────────────────────────
  String _predictedWord = '';
  double _confidence = 0.0;
  bool _isProcessing = false;
  int _frameCount = 0;

  String _holdingWord = '';
  DateTime? _holdStart;
  static const _holdDuration = Duration(milliseconds: 1500);
  double _holdProgress = 0.0;

  final List<String> _recognizedWords = [];

  // ── TTS ────────────────────────────────────────────────────────────────────
  FlutterTts? _tts;
  bool _isTtsEnabled = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Permission.camera.request();
    await _loadModel();
    await _initTts();
    await _initCamera();
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();
    await _tts!.setLanguage('en-US');
    await _tts!.setSpeechRate(0.5);
    _tts!.setStartHandler(() => setState(() => _isSpeaking = true));
    _tts!.setCompletionHandler(
        () => setState(() => _isSpeaking = false));
  }

  Future<void> _loadModel() async {
    final data = await rootBundle
        .load('assets/model/word_cnn_model.tflite');
    final options = InterpreterOptions()..threads = 2;
    _interpreter = Interpreter.fromBuffer(
      data.buffer.asUint8List(),
      options: options,
    );
    setState(() => _modelReady = true);
  }

  Future<void> _initCamera({bool useFront = false}) async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    CameraDescription cam = _cameras.first;
    for (final c in _cameras) {
      if (useFront && c.lensDirection == CameraLensDirection.front) {
        cam = c; break;
      } else if (!useFront && c.lensDirection == CameraLensDirection.back) {
        cam = c; break;
      }
    }

    await _camera?.stopImageStream();
    await _camera?.dispose();

    _camera = CameraController(
      cam,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _camera!.initialize();
    _camera!.startImageStream(_processFrame);
    if (mounted) setState(() { _cameraReady = true; _isFrontCamera = useFront; });
  }

  Future<void> _flipCamera() async {
    setState(() => _cameraReady = false);
    await _initCamera(useFront: !_isFrontCamera);
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessing || !_modelReady) return;

    _frameCount++;
    if (_frameCount % 6 != 0) return; // every 6th frame

    _isProcessing = true;
    try {
      // YUV → RGB
      final rgb = _convertYUV(image);
      if (rgb == null) return;

      // Rotate 90° sensor correction
      img.Image rotated = img.copyRotate(rgb, angle: 90);

      // Apply 270° correction (same as letter CNN)
      rotated = img.copyRotate(rotated, angle: 270);

      // Center square crop
      final fw = rotated.width;
      final fh = rotated.height;
      final size = math.min(fw, fh);
      final x1 = (fw ~/ 2 - size ~/ 2).clamp(0, fw - size);
      final y1 = (fh ~/ 2 - size ~/ 2).clamp(0, fh - size);
      final cropped = img.copyCrop(
          rotated, x: x1, y: y1, width: size, height: size);

      // Resize to 224x224
      final resized =
          img.copyResize(cropped, width: 224, height: 224,
              interpolation: img.Interpolation.linear);

      // Build float32 tensor normalized /255
      final input = Float32List(224 * 224 * 3);
      int idx = 0;
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = resized.getPixel(x, y);
          input[idx++] = pixel.r / 255.0;
          input[idx++] = pixel.g / 255.0;
          input[idx++] = pixel.b / 255.0;
        }
      }

      final output = List.filled(
          1 * _labels.length, 0.0).reshape([1, _labels.length]);
      _interpreter!.run(input.reshape([1, 224, 224, 3]), output);

      final probs = List<double>.from(output[0] as List);
      int maxIdx = 0;
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > probs[maxIdx]) maxIdx = i;
      }

      final word = _labels[maxIdx];
      final confidence = probs[maxIdx];

      if (confidence > 0.70) {
        _checkHold(word, confidence);
      } else {
        _resetHold();
      }
    } catch (e) {
      // Silent
    } finally {
      _isProcessing = false;
    }
  }

  void _checkHold(String word, double confidence) {
    final now = DateTime.now();
    if (_holdingWord != word) {
      _holdingWord = word;
      _holdStart = now;
    }
    final held =
        now.difference(_holdStart ?? now).inMilliseconds;
    final progress =
        (held / _holdDuration.inMilliseconds).clamp(0.0, 1.0);

    if (mounted) {
      setState(() {
        _predictedWord = word;
        _confidence = confidence;
        _holdProgress = progress;
      });
    }

    if (held >= _holdDuration.inMilliseconds) {
      _confirmWord(word);
      _holdStart = now; // reset timer
    }
  }

  void _resetHold() {
    if (mounted) {
      setState(() {
        _holdingWord = '';
        _holdStart = null;
        _holdProgress = 0.0;
        _predictedWord = '';
        _confidence = 0.0;
      });
    }
  }

  void _confirmWord(String word) {
    if (mounted) {
      setState(() {
        _recognizedWords.add(word);
        _holdProgress = 0.0;
      });
      if (_isTtsEnabled) _tts?.speak(word);
    }
  }

  img.Image? _convertYUV(CameraImage cam) {
    try {
      final w = cam.width;
      final h = cam.height;
      final yPlane = cam.planes[0];
      final uPlane = cam.planes[1];
      final vPlane = cam.planes[2];
      final yBytes = yPlane.bytes;
      final uBytes = uPlane.bytes;
      final vBytes = vPlane.bytes;
      final uvRowStride = uPlane.bytesPerRow;
      final uvPixelStride = uPlane.bytesPerPixel ?? 1;
      final image = img.Image(width: w, height: h);

      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final yVal =
              yBytes[y * yPlane.bytesPerRow + x] & 0xFF;
          final uvIdx =
              (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;
          final uVal = uvIdx < uBytes.length
              ? uBytes[uvIdx] & 0xFF
              : 128;
          final vVal = uvIdx < vBytes.length
              ? vBytes[uvIdx] & 0xFF
              : 128;
          final r = (yVal + 1.402 * (vVal - 128))
              .round()
              .clamp(0, 255);
          final g =
              (yVal - 0.344 * (uVal - 128) - 0.714 * (vVal - 128))
                  .round()
                  .clamp(0, 255);
          final b = (yVal + 1.772 * (uVal - 128))
              .round()
              .clamp(0, 255);
          image.setPixelRgb(x, y, r, g, b);
        }
      }
      return image;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _camera?.stopImageStream();
    _camera?.dispose();
    _interpreter?.close();
    _tts?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(flex: 5, child: _buildCamera()),
            _buildPrediction(),
            _buildResults(),
            _buildControls(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              width: 38, height: 38,
              decoration: AppStyles.cardDecoration(),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 15, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sign to Word',
                  style: AppFonts.headingSmall
                      .copyWith(color: AppColors.textPrimary)),
              Text('Show a sign to recognize the word',
                  style: AppFonts.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),

          // TTS toggle
          GestureDetector(
            onTap: () async {
              setState(() => _isTtsEnabled = !_isTtsEnabled);
              if (!_isTtsEnabled) await _tts?.stop();
            },
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: _isTtsEnabled
                    ? AppColors.teal.withOpacity(0.15)
                    : AppColors.bgSurface,
                borderRadius: AppStyles.radiusMd,
                border: Border.all(
                  color: _isTtsEnabled
                      ? AppColors.teal
                      : AppColors.bgBorder,
                  width: 1,
                ),
              ),
              child: Icon(
                _isTtsEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                size: 18,
                color: _isTtsEnabled
                    ? AppColors.teal
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Camera flip
          GestureDetector(
            onTap: _flipCamera,
            child: Container(
              width: 38, height: 38,
              decoration: AppStyles.cardDecoration(),
              child: const Icon(Icons.flip_camera_ios_rounded,
                  size: 18, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCamera() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: AppStyles.radiusLg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_cameraReady && _camera != null)
              CameraPreview(_camera!)
            else
              Container(
                color: AppColors.bgSurface,
                child: const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.teal, strokeWidth: 2),
                ),
              ),

            // Guide box
            CustomPaint(painter: _GuideBoxPainter()),

            // Camera frame corners
            CustomPaint(painter: _FramePainter()),

            // Status badge
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _predictedWord.isNotEmpty
                      ? AppColors.teal.withOpacity(0.85)
                      : AppColors.bgSurface.withOpacity(0.85),
                  borderRadius: AppStyles.radiusFull,
                  border: Border.all(
                    color: _predictedWord.isNotEmpty
                        ? AppColors.teal
                        : AppColors.bgBorder,
                  ),
                ),
                child: Text(
                  _predictedWord.isNotEmpty ? 'DETECTING' : 'WAITING',
                  style: AppFonts.labelCaps.copyWith(
                    color: _predictedWord.isNotEmpty
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontSize: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrediction() {
    final hasWord = _predictedWord.isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: hasWord
                  ? AppColors.teal.withOpacity(0.15)
                  : AppColors.bgDark,
              borderRadius: AppStyles.radiusMd,
              border: Border.all(
                color: hasWord ? AppColors.teal : AppColors.bgBorder,
                width: hasWord ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: hasWord
                  ? Text(
                      _predictedWord.substring(0, 1),
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teal),
                    )
                  : const Icon(Icons.sign_language_rounded,
                      color: AppColors.textSecondary, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasWord ? _predictedWord : 'No sign detected',
                  style: AppFonts.headingSmall.copyWith(
                    color: hasWord
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                if (hasWord) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('Confidence ',
                        style: AppFonts.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    Text(
                      '${(_confidence * 100).toStringAsFixed(0)}%',
                      style: AppFonts.bodySmall
                          .copyWith(color: AppColors.teal),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _confidence,
                      minHeight: 4,
                      backgroundColor: AppColors.bgDark,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _confidence > 0.85
                            ? AppColors.teal
                            : Colors.orangeAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('Hold ',
                        style: AppFonts.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _holdProgress,
                          minHeight: 4,
                          backgroundColor: AppColors.bgDark,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(
                                  AppColors.blue),
                        ),
                      ),
                    ),
                  ]),
                ] else
                  Text('Show: Hello, Help, ILikeIt, Please, Sorry, Yes',
                      style: AppFonts.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(14),
      constraints:
          const BoxConstraints(minHeight: 52, maxHeight: 90),
      decoration: AppStyles.cardDecoration(),
      child: _recognizedWords.isEmpty
          ? Text('Recognized words will appear here...',
              style: AppFonts.bodyMedium
                  .copyWith(color: AppColors.textSecondary))
          : SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _recognizedWords
                    .map((w) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withOpacity(0.15),
                            borderRadius: AppStyles.radiusFull,
                            border: Border.all(
                                color:
                                    AppColors.teal.withOpacity(0.4)),
                          ),
                          child: Text(w,
                              style: AppFonts.bodySmall.copyWith(
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _recognizedWords.clear()),
              child: _ctrlBtn(Icons.clear_all_rounded, 'Clear', AppColors.error),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_recognizedWords.isNotEmpty) {
                  setState(() => _recognizedWords.removeLast());
                }
              },
              child: _ctrlBtn(Icons.backspace_outlined, 'Delete', Colors.orangeAccent),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_recognizedWords.isNotEmpty) {
                  _tts?.speak(_recognizedWords.join(' '));
                }
              },
              child: _ctrlBtn(
                _isSpeaking ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded,
                _isSpeaking ? 'Stop' : 'Speak',
                AppColors.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppStyles.radiusMd,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 3),
          Text(label,
              style: AppFonts.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Guide box ─────────────────────────────────────────────────────────────────
class _GuideBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    final x1 = (size.width - s) / 2;
    final y1 = (size.height - s) / 2;

    canvas.drawRect(
      Rect.fromLTWH(x1, y1, s, s),
      Paint()
        ..color = const Color(0xFF0ABFA3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final tp = TextPainter(
      text: const TextSpan(
        text: 'Place hand here',
        style: TextStyle(
            color: Color(0xFF0ABFA3),
            fontSize: 11,
            fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(x1, y1 - 18));
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Camera frame corners ──────────────────────────────────────────────────────
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
              colors: [AppColors.teal, AppColors.blue])
          .createShader(
              Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const len = 24.0;
    const r = 12.0;

    void corner(double x, double y, double dx1, double dy1,
        double dx2, double dy2) {
      canvas.drawLine(Offset(x, y), Offset(x + dx1, y + dy1), paint);
      canvas.drawLine(Offset(x, y), Offset(x + dx2, y + dy2), paint);
    }

    corner(r, r, len, 0, 0, len);
    corner(size.width - r, r, -len, 0, 0, len);
    corner(r, size.height - r, len, 0, 0, -len);
    corner(size.width - r, size.height - r, -len, 0, 0, -len);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}