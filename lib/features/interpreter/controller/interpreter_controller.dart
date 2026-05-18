import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/interpreter_result.dart';
import '../service/interpreter_service.dart';

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

  // ── CNN rotation — hardcoded 270° (confirmed working) ─────────────────────
  final int _cnnRotation = 270;
  int get cnnRotation => _cnnRotation;

  // ── Model type ─────────────────────────────────────────────────────────────
  ModelType _modelType = ModelType.fnn;
  ModelType get modelType => _modelType;
  bool get isCnnMode => _modelType == ModelType.cnn;

  // ── Dominant hand ──────────────────────────────────────────────────────────
  bool _isRightHand = false; // default: left hand (matches training data)
  bool get isRightHand => _isRightHand;

  // ── Camera ─────────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;
  bool get isCameraReady =>
      _cameraController != null && _cameraController!.value.isInitialized;

  // ── Hand landmarker ────────────────────────────────────────────────────────
  HandLandmarkerPlugin? _handLandmarker;
  List<Hand> _detectedHands = [];
  List<Hand> get detectedHands => _detectedHands;
  bool _isProcessingFrame = false;

  // ── Prediction ─────────────────────────────────────────────────────────────
  InterpreterResult _currentResult = InterpreterResult.noHand();
  InterpreterResult get currentResult => _currentResult;

  // ── Letter confirmation ────────────────────────────────────────────────────
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

  // ── Initialize ─────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    try {
      _setState(InterpreterState.initializing);

      // Load saved hand preference
      final prefs = await SharedPreferences.getInstance();
      _isRightHand = prefs.getBool('dominant_hand_right') ?? false;
      _modelType = (prefs.getString('model_type') ?? 'fnn') == 'cnn'
          ? ModelType.cnn
          : ModelType.fnn;

      final status = await Permission.camera.request();
      if (!status.isGranted) throw Exception('Camera permission denied');

      await _interpreterService.initialize();
      await _initTts();

      _handLandmarker = HandLandmarkerPlugin.create(
        numHands: 1,
        minHandDetectionConfidence: 0.5,
        delegate: HandLandmarkerDelegate.cpu,
      );

      await _initCamera();
      _setState(InterpreterState.ready);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setState(InterpreterState.error);
    }
  }

  // ── Toggle model type ──────────────────────────────────────────────────────
  Future<void> toggleModelType() async {
    _modelType =
        _modelType == ModelType.fnn ? ModelType.cnn : ModelType.fnn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'model_type', _modelType == ModelType.cnn ? 'cnn' : 'fnn');
    _currentResult = InterpreterResult.noHand();
    _detectedHands = [];
    _resetHoldTimer();
    notifyListeners();
  }

  // ── Toggle dominant hand ───────────────────────────────────────────────────
  Future<void> toggleDominantHand() async {
    _isRightHand = !_isRightHand;

    // Persist preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dominant_hand_right', _isRightHand);

    // Reset current prediction
    _currentResult = InterpreterResult.noHand();
    _resetHoldTimer();
    notifyListeners();
  }

  // ── Camera ─────────────────────────────────────────────────────────────────
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception('No cameras found');

    CameraDescription camera = cameras.first;
    for (final c in cameras) {
      if (c.lensDirection == CameraLensDirection.back) {
        camera = c;
        break;
      }
    }

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      // BGRA is faster for CNN (no YUV conversion), YUV needed for hand_landmarker
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    _cameraController!.startImageStream(_processFrame);
  }

  // ── Process frame ──────────────────────────────────────────────────────────
  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessingFrame || _handLandmarker == null) return;
    if (_state == InterpreterState.error ||
        _state == InterpreterState.initializing) return;

    _isProcessingFrame = true;

    try {
      final sensorOrientation =
          _cameraController!.description.sensorOrientation;
      final hands = _handLandmarker!.detect(image, sensorOrientation);

      if (_modelType == ModelType.fnn) {
        // ── FNN — exactly as working version ────────────────────────────────
        if (hands.isEmpty) {
          _detectedHands = [];
          _currentResult = InterpreterResult.noHand();
          _resetHoldTimer();
          _setState(InterpreterState.ready);
        } else {
          _detectedHands = hands;
          final landmarks = InterpreterService.extractLandmarks(
            hands.first.landmarks, _isRightHand);
          if (landmarks.length == 42) {
            final result = _interpreterService.predict(landmarks);
            _currentResult = result;
            if (result.isConfident) {
              _setState(InterpreterState.detecting);
              _checkHoldConfirmation(result.letter);
            } else {
              _resetHoldTimer();
            }
          }
        }
      } else {
        // ── CNN — fixed box crop, no orientation change ──────────────────────
        _detectedHands = hands;
        final result = _interpreterService.predictCNN(
            image, sensorOrientation, _cnnRotation);
        if (result.isHandDetected) {
          _currentResult = result;
          if (result.isConfident) {
            _setState(InterpreterState.detecting);
            _checkHoldConfirmation(result.letter);
          } else {
            _resetHoldTimer();
          }
        } else if (hands.isEmpty) {
          _currentResult = InterpreterResult.noHand();
          _resetHoldTimer();
          _setState(InterpreterState.ready);
        }
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
    if (_holdStartTime == null) {
      _holdStartTime = now;
      return;
    }
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
      if (_currentWord.isNotEmpty) {
        _recognizedText += '$_currentWord ';
        _currentWord = '';
        _confirmedLetters = [];
        if (_isTtsEnabled) _speakLastWord();
      }
    } else {
      _currentWord += letter;
      _confirmedLetters.add(letter);
    }
    _setState(InterpreterState.confirmed);
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
      _recognizedText += '$_currentWord ';
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
    final text = fullText.trim();
    if (text.isEmpty) return;
    await _tts?.speak(text);
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
    final current = _cameraController!.description.lensDirection;
    final newCam = cameras.firstWhere(
      (c) => c.lensDirection != current,
      orElse: () => cameras.first,
    );
    await _cameraController!.stopImageStream();
    await _cameraController!.dispose();
    _cameraController = CameraController(
      newCam,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _cameraController!.initialize();
    _cameraController!.startImageStream(_processFrame);
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _setState(InterpreterState s) {
    _state = s;
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