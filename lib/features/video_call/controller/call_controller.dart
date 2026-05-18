import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../model/call_session.dart';
import '../service/call_service.dart';

class CallController extends ChangeNotifier {
  final CallService _callService;
  CallController(this._callService);

  CallService get callService => _callService;

  // ── State ──────────────────────────────────────────────────────────────────
  CallState _callState = CallState.idle;
  CallState get callState => _callState;

  int? _remoteUid;
  int? get remoteUid => _remoteUid;

  String? _channelId;
  String? get channelId => _channelId;

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  bool _isCameraOff = false;
  bool get isCameraOff => _isCameraOff;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Captions ───────────────────────────────────────────────────────────────
  String _myCurrentWord = '';
  String _myFullText = '';
  String get myCaption => _myFullText + _myCurrentWord;

  String _remoteCaption = '';
  String get remoteCaption => _remoteCaption;

  // ── TTS ────────────────────────────────────────────────────────────────────
  FlutterTts? _tts;
  bool _isTtsEnabled = false;
  bool get isTtsEnabled => _isTtsEnabled;

  Timer? _captionTimer;
  String _lastSentCaption = '';

  // ── Initialize ─────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    await Permission.camera.request();
    await Permission.microphone.request();

    _tts = FlutterTts();
    await _tts!.setLanguage('en-US');
    await _tts!.setSpeechRate(0.5);

    // Set callbacks BEFORE initializing Agora
    _callService.onRemoteUserJoined = (uid) {
      debugPrint('CONTROLLER: Remote user joined \$uid');
      _remoteUid = uid;
      _setState(CallState.connected);
    };

    _callService.onRemoteUserLeft = (_) {
      _remoteUid = null;
      notifyListeners();
    };

    _callService.onCaptionReceived = (caption) {
      _remoteCaption = caption.text;
      notifyListeners();
    };

    _callService.onCallEnded = () {
      _setState(CallState.ended);
    };

    // Agora manages camera internally
    await _callService.initialize();

    _captionTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _sendCaptionIfChanged(),
    );
  }

  Future<void> _sendCaptionIfChanged() async {
    final current = myCaption;
    if (current != _lastSentCaption && _channelId != null) {
      _lastSentCaption = current;
      await _callService.sendCaption(_channelId!, current);
    }
  }

  // ── Start call ─────────────────────────────────────────────────────────────
  Future<void> startCall() async {
    try {
      _setState(CallState.calling);
      _channelId = await _callService.startCall();
      debugPrint('CONTROLLER: Starting call on \$_channelId');
      await _callService.joinChannel(_channelId!);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('CONTROLLER: Error: \$e');
      _setState(CallState.error);
    }
  }

  // ── Accept call ────────────────────────────────────────────────────────────
  Future<void> acceptCall(String channelId) async {
    try {
      _channelId = channelId;
      debugPrint('CONTROLLER: Accepting call on \$channelId');
      await _callService.acceptCall(channelId);
      await _callService.joinChannel(channelId);
      _setState(CallState.connected);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('CONTROLLER: Error: \$e');
      _setState(CallState.error);
    }
  }

  // ── End call ───────────────────────────────────────────────────────────────
  Future<void> endCall() async {
    if (_channelId != null) {
      await _callService.declineCall(_channelId!);
    }
    await _callService.leaveChannel();
    _remoteUid = null;
    _channelId = null;
    _setState(CallState.ended);
  }

  // ── Controls ───────────────────────────────────────────────────────────────
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _callService.toggleMute(_isMuted);
    notifyListeners();
  }

  Future<void> toggleCamera() async {
    _isCameraOff = !_isCameraOff;
    await _callService.toggleCamera(_isCameraOff);
    notifyListeners();
  }

  Future<void> switchCamera() async {
    await _callService.switchCamera();
  }

  void clearMyCaption() {
    _myCurrentWord = '';
    _myFullText = '';
    notifyListeners();
  }

  Future<void> toggleTts() async {
    _isTtsEnabled = !_isTtsEnabled;
    notifyListeners();
  }

  Future<void> speakRemoteCaption() async {
    if (_remoteCaption.isNotEmpty) await _tts?.speak(_remoteCaption);
  }

  Future<void> speakMyCaption() async {
    if (myCaption.isNotEmpty) await _tts?.speak(myCaption);
  }

  void _setState(CallState s) {
    debugPrint('CONTROLLER: State → \$s');
    _callState = s;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    _captionTimer?.cancel();
    await _callService.dispose();
    await _tts?.stop();
    super.dispose();
  }
}