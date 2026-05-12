import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_styles.dart';
import '../controller/interpreter_controller.dart';
import '../model/interpreter_result.dart';

class InterpreterScreen extends StatefulWidget {
  const InterpreterScreen({super.key});

  @override
  State<InterpreterScreen> createState() => _InterpreterScreenState();
}

class _InterpreterScreenState extends State<InterpreterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Pulse animation for confirmed letter
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );

    // Initialize the controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InterpreterController>().initialize();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InterpreterController>();

    // Pulse when letter confirmed
    if (controller.state == InterpreterState.confirmed) {
      _pulseCtrl.forward().then((_) => _pulseCtrl.reverse());
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────────
            _buildTopBar(context, controller),

            // ── Camera view + overlay ─────────────────────────────────────────
            Expanded(
              flex: 5,
              child: _buildCameraSection(controller),
            ),

            // ── Prediction panel ──────────────────────────────────────────────
            _buildPredictionPanel(controller),

            // ── Text output ────────────────────────────────────────────────────
            _buildTextOutput(controller),

            // ── Controls ───────────────────────────────────────────────────────
            _buildControls(context, controller),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, InterpreterController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: AppStyles.radiusMd,
                border: Border.all(color: AppColors.bgBorder, width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 15, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Live Interpreter',
                  style: AppFonts.headingSmall
                      .copyWith(color: AppColors.textPrimary)),
              Text('ASL A–Z + Space',
                  style: AppFonts.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          // TTS toggle
          GestureDetector(
            onTap: controller.toggleTts,
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: controller.isTtsEnabled
                    ? AppColors.teal.withOpacity(0.15)
                    : AppColors.bgSurface,
                borderRadius: AppStyles.radiusMd,
                border: Border.all(
                  color: controller.isTtsEnabled
                      ? AppColors.teal
                      : AppColors.bgBorder,
                  width: 1,
                ),
              ),
              child: Icon(
                controller.isTtsEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                size: 18,
                color: controller.isTtsEnabled
                    ? AppColors.teal
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Flip camera
          GestureDetector(
            onTap: controller.flipCamera,
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: AppStyles.radiusMd,
                border: Border.all(color: AppColors.bgBorder, width: 1),
              ),
              child: const Icon(Icons.flip_camera_ios_rounded,
                  size: 18, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Camera section ───────────────────────────────────────────────────────
  Widget _buildCameraSection(InterpreterController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: AppStyles.radiusLg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera preview
            if (controller.isCameraReady)
              CameraPreview(controller.cameraController!)
            else
              _buildCameraPlaceholder(controller),

            // Hand landmark overlay
            if (controller.detectedHands.isNotEmpty)
              CustomPaint(
                painter: _LandmarkPainter(controller.detectedHands),
              ),

            // Camera frame corners
            _buildCameraFrame(),

            // Status badge top-right
            Positioned(
              top: 12, right: 12,
              child: _buildStatusBadge(controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPlaceholder(InterpreterController controller) {
    return Container(
      color: AppColors.bgSurface,
      child: Center(
        child: controller.state == InterpreterState.error
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    controller.errorMessage ?? 'Error',
                    style: AppFonts.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                      color: AppColors.teal, strokeWidth: 2),
                  const SizedBox(height: 12),
                  Text('Initializing camera...',
                      style: AppFonts.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
      ),
    );
  }

  Widget _buildCameraFrame() {
    return CustomPaint(painter: _CameraFramePainter());
  }

  Widget _buildStatusBadge(InterpreterController controller) {
    final isDetecting =
        controller.currentResult.isHandDetected &&
            controller.currentResult.isConfident;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDetecting
            ? AppColors.teal.withOpacity(0.85)
            : AppColors.bgSurface.withOpacity(0.85),
        borderRadius: AppStyles.radiusFull,
        border: Border.all(
          color: isDetecting ? AppColors.teal : AppColors.bgBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDetecting ? Colors.white : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isDetecting ? 'DETECTING' : 'WAITING',
            style: AppFonts.labelCaps.copyWith(
              color: isDetecting
                  ? Colors.white
                  : AppColors.textSecondary,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ── Prediction panel ──────────────────────────────────────────────────────
  Widget _buildPredictionPanel(InterpreterController controller) {
    final result = controller.currentResult;
    final hasLetter = result.isHandDetected && result.letter.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppStyles.radiusMd,
        border: Border.all(color: AppColors.bgBorder, width: 1),
      ),
      child: Row(
        children: [
          // Current letter (big)
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: hasLetter
                    ? AppColors.teal.withOpacity(0.15)
                    : AppColors.bgDark,
                borderRadius: AppStyles.radiusMd,
                border: Border.all(
                  color:
                      hasLetter ? AppColors.teal : AppColors.bgBorder,
                  width: hasLetter ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  hasLetter
                      ? (result.letter == 'Space' ? '␣' : result.letter)
                      : '?',
                  style: TextStyle(
                    fontSize: hasLetter ? 32 : 24,
                    fontWeight: FontWeight.w800,
                    color: hasLetter
                        ? AppColors.teal
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Confidence + hold progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasLetter ? result.letter : 'No hand detected',
                  style: AppFonts.headingSmall.copyWith(
                    color: hasLetter
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),

                // Confidence bar
                if (hasLetter) ...[
                  Row(
                    children: [
                      Text('Confidence ',
                          style: AppFonts.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                      Text(
                        '${(result.confidence * 100).toStringAsFixed(0)}%',
                        style: AppFonts.bodySmall
                            .copyWith(color: AppColors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: result.confidence,
                      minHeight: 4,
                      backgroundColor: AppColors.bgDark,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        result.confidence > 0.9
                            ? AppColors.teal
                            : Colors.orangeAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Hold progress bar
                  Row(
                    children: [
                      Text('Hold ',
                          style: AppFonts.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: controller.holdProgress,
                            minHeight: 4,
                            backgroundColor: AppColors.bgDark,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.blue),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    'Show your hand to the camera',
                    style: AppFonts.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Text output ──────────────────────────────────────────────────────────
  Widget _buildTextOutput(InterpreterController controller) {
    final text = controller.fullText;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(14),
      constraints: const BoxConstraints(minHeight: 60, maxHeight: 100),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppStyles.radiusMd,
        border: Border.all(color: AppColors.bgBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: text.isEmpty
                ? Text(
                    'Recognized text will appear here...',
                    style: AppFonts.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  )
                : SingleChildScrollView(
                    child: Text(
                      text,
                      style: AppFonts.bodyLarge
                          .copyWith(color: AppColors.textPrimary),
                    ),
                  ),
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: controller.speakAll,
              child: Icon(
                Icons.record_voice_over_rounded,
                size: 18,
                color: AppColors.teal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Controls ─────────────────────────────────────────────────────────────
  Widget _buildControls(
      BuildContext context, InterpreterController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          // Space
          Expanded(
            child: _ControlButton(
              label: 'Space',
              icon: Icons.space_bar_rounded,
              onTap: controller.addSpace,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(width: 8),
          // Delete
          Expanded(
            child: _ControlButton(
              label: 'Delete',
              icon: Icons.backspace_outlined,
              onTap: controller.deleteLastLetter,
              color: Colors.orangeAccent,
            ),
          ),
          const SizedBox(width: 8),
          // Clear all
          Expanded(
            child: _ControlButton(
              label: 'Clear',
              icon: Icons.clear_all_rounded,
              onTap: controller.clearAll,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: 8),
          // Speak
          Expanded(
            child: _ControlButton(
              label: controller.isSpeaking ? 'Stop' : 'Speak',
              icon: controller.isSpeaking
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outline_rounded,
              onTap: controller.isSpeaking
                  ? controller.stopSpeaking
                  : controller.speakAll,
              color: AppColors.teal,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Control button ────────────────────────────────────────────────────────────
class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: AppStyles.radiusMd,
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppFonts.bodySmall.copyWith(
                  color: color, fontWeight: FontWeight.w600, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Camera frame corner painter ───────────────────────────────────────────────
class _CameraFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.teal, AppColors.blue],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const len = 24.0;
    const r = 12.0;

    // Top-left
    canvas.drawLine(Offset(r, 0), Offset(r + len, 0), paint);
    canvas.drawLine(Offset(0, r), Offset(0, r + len), paint);
    canvas.drawArc(const Rect.fromLTWH(0, 0, r * 2, r * 2),
        3.14159, 3.14159 / 2, false, paint);

    // Top-right
    canvas.drawLine(
        Offset(size.width - r - len, 0), Offset(size.width - r, 0), paint);
    canvas.drawLine(Offset(size.width, r), Offset(size.width, r + len), paint);
    canvas.drawArc(
        Rect.fromLTWH(size.width - r * 2, 0, r * 2, r * 2),
        3.14159 * 1.5,
        3.14159 / 2,
        false,
        paint);

    // Bottom-left
    canvas.drawLine(
        Offset(r, size.height), Offset(r + len, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height - r - len), Offset(0, size.height - r), paint);
    canvas.drawArc(
        Rect.fromLTWH(0, size.height - r * 2, r * 2, r * 2),
        3.14159 / 2,
        3.14159 / 2,
        false,
        paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - r - len, size.height),
        Offset(size.width - r, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - r - len),
        Offset(size.width, size.height - r), paint);
    canvas.drawArc(
        Rect.fromLTWH(size.width - r * 2, size.height - r * 2, r * 2, r * 2),
        0,
        3.14159 / 2,
        false,
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Hand landmark painter ─────────────────────────────────────────────────────
class _LandmarkPainter extends CustomPainter {
  final List<dynamic> hands;

  _LandmarkPainter(this.hands);

  // MediaPipe hand landmark connections
  static const _connections = [
    [0, 1], [1, 2], [2, 3], [3, 4],       // thumb
    [0, 5], [5, 6], [6, 7], [7, 8],       // index
    [0, 9], [9, 10], [10, 11], [11, 12],  // middle
    [0, 13], [13, 14], [14, 15], [15, 16], // ring
    [0, 17], [17, 18], [18, 19], [19, 20], // pinky
    [5, 9], [9, 13], [13, 17],             // palm
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (hands.isEmpty) return;

    final linePaint = Paint()
      ..color = AppColors.teal.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = AppColors.teal
      ..style = PaintingStyle.fill;

    final dotPaintTip = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final hand in hands) {
      final landmarks = hand.landmarks as List;
      if (landmarks.length < 21) continue;

      // Draw connections
      for (final conn in _connections) {
        final a = landmarks[conn[0]];
        final b = landmarks[conn[1]];
        canvas.drawLine(
          Offset((a.x as num) * size.width, (a.y as num) * size.height),
          Offset((b.x as num) * size.width, (b.y as num) * size.height),
          linePaint,
        );
      }

      // Draw dots
      for (int i = 0; i < landmarks.length; i++) {
        final lm = landmarks[i];
        final x = (lm.x as num) * size.width;
        final y = (lm.y as num) * size.height;
        // Fingertips (4, 8, 12, 16, 20) are white, others teal
        final isTip = [4, 8, 12, 16, 20].contains(i);
        canvas.drawCircle(
          Offset(x, y),
          isTip ? 5 : 3,
          isTip ? dotPaintTip : dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LandmarkPainter old) => true;
}