import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import '../model/interpreter_result.dart';
import '../service/interpreter_service.dart';

// ── Interpreter states ─────────────────────────────────────────────────────
enum InterpreterState {
  initializing,
  ready,
  detecting,
  confirmed,
  error,
}

class InterpreterController extends ChangeNotifier {
  final InterpreterService _interpreterService;

  InterpreterController(this._interpreterService);

  // ── State ──────────────────────────────────────────────────────────────────
  InterpreterState _state = InterpreterState.initializing;
  InterpreterState get state => _state;

  // ── Camera ─────────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;
  bool get isCameraReady =>
      _cameraController != null && _cameraController!.value.isInitialized;

  // ── Hand landmarker — v2.2.0 uses HandLandmarkerPlugin ────────────────────
  HandLandmarkerPlugin? _handLandmarker;
  List<Hand> _detectedHands = [];
  List<Hand> get detectedHands => _detectedHands;
  bool _isProcessingFrame = false;

  // ── Prediction ─────────────────────────────────────────────────────────────
  InterpreterResult _currentResult = InterpreterResult.noHand();
  InterpreterResult get currentResult => _currentResult;

  // ── Letter confirmation logic ──────────────────────────────────────────────
  String _holdingLetter = '';
  DateTime? _holdStartTime;
  final Duration _holdDuration = const Duration(milliseconds: 1200);

  // ── Text building ──────────────────────────────────────────────────────────
  String _recognizedText = '';
  String get recognizedText => _recognizedText;

  String _currentWord = '';
  String get currentWord => _currentWord;

  List<String> _confirmedLetters = [];
  List<String> get confirmedLetters => _confirmedLetters;

  // ── TTS ────────────────────────────────────────────────────────────────────
  FlutterTts? _tts;
  bool _isTtsEnabled = false;
  bool get isTtsEnabled => _isTtsEnabled;
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  // ── Error ──────────────────────────────────────────────────────────────────
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Initialize everything ──────────────────────────────────────────────────
  Future<void> initialize() async {
    try {
      _setState(InterpreterState.initializing);

      // 1. Initialize TFLite model
      await _interpreterService.initialize();

      // 2. Initialize TTS
      await _initTts();

      // 3. Initialize hand landmarker — v2.2.0 API
      _handLandmarker = HandLandmarkerPlugin.create(
        numHands: 1,
        minHandDetectionConfidence: 0.7,
        delegate: HandLandmarkerDelegate.gpu,
      );

      // 4. Initialize camera
      await _initCamera();

      _setState(InterpreterState.ready);
    } catch (e) {
      _errorMessage = 'Initialization failed: ${e.toString()}';
      _setState(InterpreterState.error);
    }
  }

  // ── Camera setup ───────────────────────────────────────────────────────────
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception('No cameras found');

    // Prefer front camera for sign language
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

  // ── Process each camera frame ──────────────────────────────────────────────
  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessingFrame || _handLandmarker == null) return;
    if (_state == InterpreterState.error ||
        _state == InterpreterState.initializing) return;

    _isProcessingFrame = true;

    try {
      // Detect using v2.2.0 API — synchronous call
      final hands = _handLandmarker!.detect(
        image,
        _cameraController!.description.sensorOrientation,
      );

      if (hands.isEmpty) {
        _detectedHands = [];
        _currentResult = InterpreterResult.noHand();
        _resetHoldTimer();
        _setState(InterpreterState.ready);
      } else {
        _detectedHands = hands;
        final hand = hands.first;

        // Normalize landmarks → 42 floats
        final normalized =
            InterpreterService.normalizeLandmarks(hand.landmarks);

        if (normalized.length == 42) {
          final result = _interpreterService.predict(normalized);
          _currentResult = result;

          if (result.isConfident) {
            _setState(InterpreterState.detecting);
            _checkHoldConfirmation(result.letter);
          } else {
            _resetHoldTimer();
          }
        }
      }
    } catch (e) {
      // Silent — frame errors are common and shouldn't crash
    } finally {
      _isProcessingFrame = false;
    }
  }

  // ── Letter hold confirmation ───────────────────────────────────────────────
  void _checkHoldConfirmation(String letter) {
    final now = DateTime.now();

    if (_holdingLetter != letter) {
      _holdingLetter = letter;
      _holdStartTime = now;
      return;
    }

    if (_holdStartTime == null) {
      _holdStartTime = now;
      return;
    }

    final held = now.difference(_holdStartTime!);
    if (held >= _holdDuration) {
      _confirmLetter(letter);
      _holdStartTime = now;
    }
  }

  void _resetHoldTimer() {
    _holdingLetter = '';
    _holdStartTime = null;
  }

  // ── Confirm a letter ───────────────────────────────────────────────────────
  void _confirmLetter(String letter) {
    if (letter == 'Space') {
      if (_currentWord.isNotEmpty) {
        _recognizedText += _currentWord + ' ';
        _currentWord = '';
        _confirmedLetters = [];
        _setState(InterpreterState.confirmed);
        if (_isTtsEnabled) _speakLastWord();
      }
    } else {
      _currentWord += letter;
      _confirmedLetters.add(letter);
      _setState(InterpreterState.confirmed);
    }
    notifyListeners();
  }

  // ── Text controls ──────────────────────────────────────────────────────────
  void deleteLastLetter() {
    if (_currentWord.isNotEmpty) {
      _currentWord = _currentWord.substring(0, _currentWord.length - 1);
      if (_confirmedLetters.isNotEmpty) _confirmedLetters.removeLast();
    } else if (_recognizedText.isNotEmpty) {
      _recognizedText =
          _recognizedText.substring(0, _recognizedText.length - 1).trimRight();
    }
    notifyListeners();
  }

  void addSpace() {
    if (_currentWord.isNotEmpty) {
      _recognizedText += _currentWord + ' ';
      _currentWord = '';
      _confirmedLetters = [];
      notifyListeners();
    }
  }

  void clearAll() {
    _recognizedText = '';
    _currentWord = '';
    _confirmedLetters = [];
    _resetHoldTimer();
    notifyListeners();
  }

  // ── TTS ────────────────────────────────────────────────────────────────────
  Future<void> _initTts() async {
    _tts = FlutterTts();
    await _tts!.setLanguage('en-US');
    await _tts!.setSpeechRate(0.5);
    await _tts!.setVolume(1.0);
    _tts!.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });
    _tts!.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });
  }

  Future<void> toggleTts() async {
    _isTtsEnabled = !_isTtsEnabled;
    notifyListeners();
  }

  Future<void> speakAll() async {
    final fullText = (_recognizedText + _currentWord).trim();
    if (fullText.isEmpty) return;
    await _tts?.speak(fullText);
  }

  Future<void> _speakLastWord() async {
    final words = _recognizedText.trim().split(' ');
    if (words.isNotEmpty) await _tts?.speak(words.last);
  }

  Future<void> stopSpeaking() async {
    await _tts?.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  // ── Camera flip ────────────────────────────────────────────────────────────
  Future<void> flipCamera() async {
    if (_cameraController == null) return;

    final cameras = await availableCameras();
    if (cameras.length < 2) return;

    final currentDirection =
        _cameraController!.description.lensDirection;
    final newCamera = cameras.firstWhere(
      (c) => c.lensDirection != currentDirection,
      orElse: () => cameras.first,
    );

    await _cameraController!.stopImageStream();
    await _cameraController!.dispose();

    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    _cameraController!.startImageStream(_processFrame);
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _setState(InterpreterState newState) {
    _state = newState;
    notifyListeners();
  }

  double get holdProgress {
    if (_holdStartTime == null || _holdingLetter.isEmpty) return 0.0;
    final held = DateTime.now().difference(_holdStartTime!).inMilliseconds;
    return (held / _holdDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  String get fullText => _recognizedText + _currentWord;

  // ── Dispose ────────────────────────────────────────────────────────────────
  @override
  Future<void> dispose() async {
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _handLandmarker?.dispose();
    _interpreterService.dispose();
    await _tts?.stop();
    super.dispose();
  }
}