import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_styles.dart';
import '../controller/interpreter_controller.dart';

class InterpreterScreen extends StatefulWidget {
  const InterpreterScreen({super.key});

  @override
  State<InterpreterScreen> createState() => _InterpreterScreenState();
}

class _InterpreterScreenState extends State<InterpreterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  void _showHint(BuildContext context) {
    final controller = context.read<InterpreterController>();
    final message = controller.isCnnMode
        ? 'Please rotate camera to the left'
        : 'Show your hand clearly in front of the camera';

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0ABFA3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InterpreterController>().initialize();
      // Always show hint every time screen opens
      _showHint(context);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InterpreterController>();

    if (controller.state == InterpreterState.confirmed) {
      _pulseCtrl.forward().then((_) => _pulseCtrl.reverse());
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, controller),
            Expanded(flex: 5, child: _buildCameraSection(controller)),
            _buildPredictionPanel(controller),
            _buildTextOutput(controller),
            _buildControls(controller),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, InterpreterController controller) {
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
              Text('Live Interpreter',
                  style: AppFonts.headingSmall
                      .copyWith(color: AppColors.textPrimary)),
              Text(
                controller.isCnnMode
                    ? 'CNN · Image Model'
                    : 'FNN · Landmark Model',
                style: AppFonts.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),

          // ── Model toggle FNN/CNN ──────────────────────────────────────────
          GestureDetector(
            onTap: controller.toggleModelType,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: controller.isCnnMode
                    ? const Color(0xFF9B6EFF).withOpacity(0.15)
                    : AppColors.bgSurface,
                borderRadius: AppStyles.radiusMd,
                border: Border.all(
                  color: controller.isCnnMode
                      ? const Color(0xFF9B6EFF)
                      : AppColors.bgBorder,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  controller.isCnnMode ? 'CNN' : 'FNN',
                  style: AppFonts.bodySmall.copyWith(
                    color: controller.isCnnMode
                        ? const Color(0xFF9B6EFF)
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ── Dominant hand toggle ──────────────────────────────────────────
          GestureDetector(
            onTap: controller.toggleDominantHand,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: controller.isRightHand
                    ? AppColors.blue.withOpacity(0.15)
                    : AppColors.teal.withOpacity(0.15),
                borderRadius: AppStyles.radiusMd,
                border: Border.all(
                  color: controller.isRightHand
                      ? AppColors.blue
                      : AppColors.teal,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.back_hand_rounded,
                    size: 14,
                    color: controller.isRightHand
                        ? AppColors.blue
                        : AppColors.teal,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    controller.isRightHand ? 'Right' : 'Left',
                    style: AppFonts.bodySmall.copyWith(
                      color: controller.isRightHand
                          ? AppColors.blue
                          : AppColors.teal,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),
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
          GestureDetector(
            onTap: controller.flipCamera,
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

  // ── Camera section ─────────────────────────────────────────────────────────
  Widget _buildCameraSection(InterpreterController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: AppStyles.radiusLg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (controller.state == InterpreterState.error)
              _buildErrorState(controller)
            else if (controller.isCameraReady)
              CameraPreview(controller.cameraController!)
            else
              _buildLoadingState(),

            // Landmark overlay — FNN only
            if (!controller.isCnnMode &&
                controller.detectedHands.isNotEmpty &&
                controller.isCameraReady)
              CustomPaint(
                painter: _LandmarkPainter(
                  controller.detectedHands,
                  sensorOrientation: controller
                      .cameraController!.description.sensorOrientation,
                  isFrontCamera: controller
                          .cameraController!.description.lensDirection ==
                      CameraLensDirection.front,
                ),
              ),

            // CNN guide box — shows where to place hand
            if (controller.isCnnMode)
              CustomPaint(painter: _CnnBoxPainter()),

            // Camera frame corners
            CustomPaint(painter: _CameraFramePainter()),

            // Status badge
            Positioned(
              top: 12, right: 12,
              child: _buildStatusBadge(controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: AppColors.bgSurface,
      child: const Center(
        child: CircularProgressIndicator(
            color: AppColors.teal, strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorState(InterpreterController controller) {
    return Container(
      color: AppColors.bgSurface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.error, size: 40),
              const SizedBox(height: 12),
              Text(
                controller.errorMessage ?? 'Initialization failed',
                style: AppFonts.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(InterpreterController controller) {
    final isDetecting = controller.currentResult.isHandDetected;
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
              color:
                  isDetecting ? Colors.white : AppColors.textSecondary,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ── Prediction panel ───────────────────────────────────────────────────────
  Widget _buildPredictionPanel(InterpreterController controller) {
    final result = controller.currentResult;
    final hasLetter = result.isHandDetected && result.letter.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: AppStyles.cardDecoration(),
      child: Row(
        children: [
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
                if (hasLetter) ...[
                  Row(children: [
                    Text('Confidence ',
                        style: AppFonts.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    Text(
                      '${(result.confidence * 100).toStringAsFixed(0)}%',
                      style:
                          AppFonts.bodySmall.copyWith(color: AppColors.teal),
                    ),
                  ]),
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
                  Row(children: [
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
                  ]),
                ] else
                  Text('Show your hand to the camera',
                      style: AppFonts.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Text output ────────────────────────────────────────────────────────────
  Widget _buildTextOutput(InterpreterController controller) {
    final text = controller.fullText;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(14),
      constraints: const BoxConstraints(minHeight: 60, maxHeight: 100),
      decoration: AppStyles.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: text.isEmpty
                ? Text('Recognized text will appear here...',
                    style: AppFonts.bodyMedium
                        .copyWith(color: AppColors.textSecondary))
                : SingleChildScrollView(
                    child: Text(text,
                        style: AppFonts.bodyLarge
                            .copyWith(color: AppColors.textPrimary))),
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: controller.speakAll,
              child: const Icon(Icons.record_voice_over_rounded,
                  size: 18, color: AppColors.teal),
            ),
          ],
        ],
      ),
    );
  }

  // ── Controls ───────────────────────────────────────────────────────────────
  Widget _buildControls(InterpreterController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Expanded(child: _ControlButton(
              label: 'Space', icon: Icons.space_bar_rounded,
              onTap: controller.addSpace, color: AppColors.blue)),
          const SizedBox(width: 8),
          Expanded(child: _ControlButton(
              label: 'Delete', icon: Icons.backspace_outlined,
              onTap: controller.deleteLastLetter,
              color: Colors.orangeAccent)),
          const SizedBox(width: 8),
          Expanded(child: _ControlButton(
              label: 'Clear', icon: Icons.clear_all_rounded,
              onTap: controller.clearAll, color: AppColors.error)),
          const SizedBox(width: 8),
          Expanded(child: _ControlButton(
              label: controller.isSpeaking ? 'Stop' : 'Speak',
              icon: controller.isSpeaking
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outline_rounded,
              onTap: controller.isSpeaking
                  ? controller.stopSpeaking
                  : controller.speakAll,
              color: AppColors.teal)),
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
    required this.label, required this.icon,
    required this.onTap, required this.color,
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
            Text(label,
                style: AppFonts.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ── Camera frame painter ───────────────────────────────────────────────────────
class _CameraFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(colors: [AppColors.teal, AppColors.blue])
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const len = 24.0;
    const r = 12.0;

    void corner(double x, double y, double dx1, double dy1, double dx2,
        double dy2) {
      canvas.drawLine(Offset(x, y), Offset(x + dx1, y + dy1), paint);
      canvas.drawLine(Offset(x, y), Offset(x + dx2, y + dy2), paint);
    }

    corner(r, r, len, 0, 0, len);
    corner(size.width - r, r, -len, 0, 0, len);
    corner(r, size.height - r, len, 0, 0, -len);
    corner(size.width - r, size.height - r, -len, 0, 0, -len);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── CNN guide box painter ─────────────────────────────────────────────────────
class _CnnBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width < size.height ? size.width : size.height;
    final x1 = (size.width - s) / 2;
    final y1 = (size.height - s) / 2;

    final paint = Paint()
      ..color = const Color(0xFF0ABFA3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRect(Rect.fromLTWH(x1, y1, s, s), paint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Place hand here',
        style: TextStyle(
            color: Color(0xFF0ABFA3),
            fontSize: 11,
            fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x1, y1 - 18));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _LandmarkPainter extends CustomPainter {
  final List<Hand> hands;
  final int sensorOrientation;
  final bool isFrontCamera;

  _LandmarkPainter(
    this.hands, {
    required this.sensorOrientation,
    required this.isFrontCamera,
  });

  static const _connections = [
    [0,1],[1,2],[2,3],[3,4],
    [0,5],[5,6],[6,7],[7,8],
    [0,9],[9,10],[10,11],[11,12],
    [0,13],[13,14],[14,15],[15,16],
    [0,17],[17,18],[18,19],[19,20],
    [5,9],[9,13],[13,17],
  ];

  /// Map a landmark from the raw camera-sensor coordinate space (normalized
  /// 0–1, landscape on most Android devices) into the upright Flutter canvas
  /// coordinate space so it lines up with the rotated `CameraPreview`.
  /// Front-facing cameras are additionally mirrored horizontally to match the
  /// preview's natural selfie mirroring.
  Offset _project(num x, num y, Size size) {
    final nx = x.toDouble();
    final ny = y.toDouble();
    double rx;
    double ry;
    switch (sensorOrientation) {
      case 90:
        rx = 1 - ny;
        ry = nx;
        break;
      case 180:
        rx = 1 - nx;
        ry = 1 - ny;
        break;
      case 270:
        rx = ny;
        ry = 1 - nx;
        break;
      default: // 0
        rx = nx;
        ry = ny;
        break;
    }
    if (isFrontCamera) rx = 1 - rx;
    return Offset(rx * size.width, ry * size.height);
  }

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

    final tipPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final hand in hands) {
      final lms = hand.landmarks;
      if (lms.length < 21) continue;

      for (final conn in _connections) {
        final a = lms[conn[0]];
        final b = lms[conn[1]];
        canvas.drawLine(
          _project(a.x as num, a.y as num, size),
          _project(b.x as num, b.y as num, size),
          linePaint,
        );
      }

      for (int i = 0; i < lms.length; i++) {
        final lm = lms[i];
        final isTip = [4, 8, 12, 16, 20].contains(i);
        canvas.drawCircle(
          _project(lm.x as num, lm.y as num, size),
          isTip ? 5 : 3,
          isTip ? tipPaint : dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LandmarkPainter old) =>
      old.hands != hands ||
      old.sensorOrientation != sensorOrientation ||
      old.isFrontCamera != isFrontCamera;
}