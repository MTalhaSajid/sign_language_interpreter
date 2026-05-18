import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_styles.dart';
import '../controller/call_controller.dart';
import '../model/call_session.dart';

class CallScreen extends StatefulWidget {
  final String channelId;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.channelId,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('SCREEN: initState channelId=${widget.channelId} '
        'isIncoming=${widget.isIncoming}');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<CallController>();

      // Step 1: initialize everything
      await controller.initialize();

      // Step 2: join call based on role
      if (widget.isIncoming && widget.channelId.isNotEmpty) {
        debugPrint('SCREEN: Accepting call on ${widget.channelId}');
        await controller.acceptCall(widget.channelId);
      } else {
        debugPrint('SCREEN: Starting new call');
        await controller.startCall();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CallController>();

    if (controller.callState == CallState.ended) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Remote video fullscreen ────────────────────────────────────────
          _buildRemoteVideo(controller),

          // ── Their caption ──────────────────────────────────────────────────
          if (controller.remoteCaption.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16, right: 16,
              child: _buildCaptionBubble(
                label: 'Their signs',
                text: controller.remoteCaption,
                color: AppColors.teal,
                onSpeak: controller.speakRemoteCaption,
              ),
            ),

          // ── Top bar ────────────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _statusBadge(controller),
                    const Spacer(),
                    _iconButton(
                      icon: controller.isTtsEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: controller.isTtsEnabled
                          ? AppColors.teal
                          : Colors.white54,
                      onTap: controller.toggleTts,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Local PiP ─────────────────────────────────────────────────────
          Positioned(
            bottom: 170, right: 16,
            child: _buildLocalPiP(controller),
          ),

          // ── My caption ────────────────────────────────────────────────────
          Positioned(
            bottom: 110, left: 16, right: 120,
            child: _buildCaptionBubble(
              label: 'My signs',
              text: controller.myCaption.isEmpty
                  ? 'Sign to communicate...'
                  : controller.myCaption,
              color: controller.myCaption.isEmpty
                  ? Colors.white24
                  : AppColors.blue,
              onSpeak: controller.myCaption.isEmpty
                  ? null
                  : controller.speakMyCaption,
              dimmed: controller.myCaption.isEmpty,
            ),
          ),

          // ── Controls ───────────────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildControls(controller),
          ),

          // ── Connecting overlay ─────────────────────────────────────────────
          if (controller.callState == CallState.calling ||
              controller.callState == CallState.idle)
            _buildConnectingOverlay(controller),
        ],
      ),
    );
  }

  // ── Remote video ───────────────────────────────────────────────────────────
  Widget _buildRemoteVideo(CallController controller) {
    final engine = controller.callService.engine;
    final remoteUid = controller.remoteUid;
    final ch = controller.channelId;

    if (engine == null || remoteUid == null || ch == null) {
      return Container(
        color: const Color(0xFF0D1B2A),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_rounded,
                  color: Colors.white24, size: 80),
              SizedBox(height: 12),
              Text('Waiting for partner...',
                  style: TextStyle(color: Colors.white38)),
            ],
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine,
          // uid=0 renders the first available remote user in 1-to-1 calls
          canvas: const VideoCanvas(uid: 0),
          connection: RtcConnection(channelId: ch),
        ),
      ),
    );
  }

  // ── Local PiP ──────────────────────────────────────────────────────────────
  Widget _buildLocalPiP(CallController controller) {
    final engine = controller.callService.engine;
    return GestureDetector(
      onTap: controller.switchCamera,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 100, height: 140,
          color: Colors.grey[900],
          child: engine != null
              ? AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                )
              : const Center(
                  child: Icon(Icons.person_rounded,
                      color: Colors.white30, size: 32)),
        ),
      ),
    );
  }

  // ── Caption bubble ─────────────────────────────────────────────────────────
  Widget _buildCaptionBubble({
    required String label,
    required String text,
    required Color color,
    VoidCallback? onSpeak,
    bool dimmed = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: dimmed
            ? Colors.black.withOpacity(0.3)
            : color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(text,
                    style: TextStyle(
                        color: dimmed ? Colors.white38 : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (onSpeak != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSpeak,
              child: const Icon(Icons.volume_up_rounded,
                  color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  // ── Connecting overlay ─────────────────────────────────────────────────────
  Widget _buildConnectingOverlay(CallController controller) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 56, height: 56,
              child: CircularProgressIndicator(
                  color: AppColors.teal, strokeWidth: 2),
            ),
            const SizedBox(height: 24),
            const Text('Connecting...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              controller.channelId ?? '',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: controller.endCall,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: Colors.red.withOpacity(0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.call_end_rounded,
                        color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Cancel',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Controls ───────────────────────────────────────────────────────────────
  Widget _buildControls(CallController controller) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.95),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlBtn(
            icon: controller.isMuted
                ? Icons.mic_off_rounded
                : Icons.mic_rounded,
            label: controller.isMuted ? 'Unmute' : 'Mute',
            active: controller.isMuted,
            onTap: controller.toggleMute,
          ),
          // End call
          GestureDetector(
            onTap: controller.endCall,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call_end_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 4),
                const Text('End Call',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
          _controlBtn(
            icon: controller.isCameraOff
                ? Icons.videocam_off_rounded
                : Icons.videocam_rounded,
            label: controller.isCameraOff ? 'Cam Off' : 'Camera',
            active: controller.isCameraOff,
            onTap: controller.toggleCamera,
          ),
          _controlBtn(
            icon: Icons.delete_sweep_rounded,
            label: 'Clear',
            active: false,
            onTap: controller.clearMyCaption,
          ),
        ],
      ),
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: active
                  ? Colors.red.withOpacity(0.3)
                  : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: active ? Colors.red[300] : Colors.white,
                size: 20),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _statusBadge(CallController controller) {
    final isConnected = controller.callState == CallState.connected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? AppColors.teal : Colors.orange,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'Connected' : 'Connecting...',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}