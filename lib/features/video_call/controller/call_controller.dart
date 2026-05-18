import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../interpreter/model/interpreter_result.dart';
import '../../interpreter/service/interpreter_service.dart';
import '../model/call_session.dart';
import '../service/call_service.dart';

class CallController extends ChangeNotifier {
  final CallService _callService;
  final InterpreterService _interpreterService;

  CallController(this._callService, this._interpreterService);

  // ── Expose callService for AgoraVideoView ──────────────────────────────────
  CallService get callService => _callService;

  // ── Call state ─────────────────────────────────────────────────────────────
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

  // ── FNN ────────────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;
  HandLandmarkerPlugin? _handLandmarker;
  bool _isProcessingFrame = false;
  bool _isRightHand = false;

  // ── Letter confirmation ────────────────────────────────────────────────────
  String _holdingLetter = '';
  DateTime? _holdStartTime;
  final Duration _holdDuration = const Duration(milliseconds: 1200);

  // ── TTS ────────────────────────────────────────────────────────────────────
  FlutterTts? _tts;
  bool _isTtsEnabled = false;
  bool get isTtsEnabled => _isTtsEnabled;

  // Caption send timer
  Timer? _captionTimer;
  String _lastSentCaption = '';

  // ── Initialize ─────────────────────────────────────────────────────────────
  Future<void> initialize({bool isRightHand = false}) async {
    _isRightHand = isRightHand;

    await Permission.camera.request();
    await Permission.microphone.request();

    await _interpreterService.initialize();

    _tts = FlutterTts();
    await _tts!.setLanguage('en-US');
    await _tts!.setSpeechRate(0.5);

    _handLandmarker = HandLandmarkerPlugin.create(
      numHands: 1,
      minHandDetectionConfidence: 0.5,
      delegate: HandLandmarkerDelegate.cpu,
    );

    await _initCamera();
    await _callService.initialize();

    _callService.onRemoteUserJoined = (uid) {
      _remoteUid = uid;
      _setState(CallState.connected);
    };

    _callService.onRemoteUserLeft = (_) {
      _remoteUid = null;
    };

    _callService.onCaptionReceived = (caption) {
      _remoteCaption = caption.text;
      notifyListeners();
    };

    _callService.onCallEnded = () {
      _setState(CallState.ended);
    };

    _captionTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _sendCaptionIfChanged(),
    );
  }

  // ── Camera ─────────────────────────────────────────────────────────────────
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Use front camera for video calls
    CameraDescription camera = cameras.first;
    for (final c in cameras) {
      if (c.lensDirection == CameraLensDirection.front) {
        camera = c;
        break;
      }
    }

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    _cameraController!.startImageStream(_processFrame);
  }

  // ── FNN frame processing ───────────────────────────────────────────────────
  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessingFrame || _handLandmarker == null) return;
    if (_callState != CallState.connected) return;

    _isProcessingFrame = true;
    try {
      final sensorOrientation =
          _cameraController!.description.sensorOrientation;
      final hands =
          _handLandmarker!.detect(image, sensorOrientation);

      if (hands.isNotEmpty) {
        final landmarks = InterpreterService.extractLandmarks(
          hands.first.landmarks,
          _isRightHand,
        );
        if (landmarks.length == 42) {
          final result = _interpreterService.predict(landmarks);
          if (result.isConfident) {
            _checkHoldConfirmation(result.letter);
          } else {
            _resetHoldTimer();
          }
        }
      } else {
        _resetHoldTimer();
      }
    } catch (e) {
      // Silent
    } finally {
      _isProcessingFrame = false;
    }
  }

  // ── Hold confirmation ──────────────────────────────────────────────────────
  void _checkHoldConfirmation(String letter) {
    final now = DateTime.now();
    if (_holdingLetter != letter) {
      _holdingLetter = letter;
      _holdStartTime = now;
      return;
    }
    if (_holdStartTime == null) { _holdStartTime = now; return; }
    if (now.difference(_holdStartTime!) >= _holdDuration) {
      _confirmLetter(letter);
      _holdStartTime = now;
    }
  }

  void _resetHoldTimer() {
    _holdingLetter = '';
    _holdStartTime = null;
  }

  void _confirmLetter(String letter) {
    if (letter == 'Space') {
      if (_myCurrentWord.isNotEmpty) {
        _myFullText += '$_myCurrentWord ';
        _myCurrentWord = '';
      }
    } else {
      _myCurrentWord += letter;
    }
    notifyListeners();
  }

  // ── Send caption to remote ─────────────────────────────────────────────────
  Future<void> _sendCaptionIfChanged() async {
    final current = myCaption;
    if (current != _lastSentCaption && _channelId != null) {
      _lastSentCaption = current;
      await _callService.sendCaption(_channelId!, current);
    }
  }

  // ── Start call — simplified, no user selection ─────────────────────────────
  Future<void> startCall() async {
    try {
      _setState(CallState.calling);
      _channelId = await _callService.startCall();
      await _callService.joinChannel(_channelId!);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(CallState.error);
    }
  }

  // ── Accept incoming call ───────────────────────────────────────────────────
  Future<void> acceptCall(String channelId) async {
    try {
      _channelId = channelId;
      await _callService.acceptCall(channelId);
      await _callService.joinChannel(channelId);
      _setState(CallState.connected);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(CallState.error);
    }
  }

  // ── End call ───────────────────────────────────────────────────────────────
  Future<void> endCall() async {
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

  // ── TTS ────────────────────────────────────────────────────────────────────
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

  void _setState(CallState s) { _callState = s; notifyListeners(); }

  @override
  Future<void> dispose() async {
    _captionTimer?.cancel();
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _handLandmarker?.dispose();
    _interpreterService.dispose();
    await _callService.dispose();
    await _tts?.stop();
    super.dispose();
  }
}