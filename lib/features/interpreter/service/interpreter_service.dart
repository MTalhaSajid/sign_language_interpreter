import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../model/interpreter_result.dart';

class InterpreterService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // ── Initialize: load model + labels from assets ────────────────────────────
  Future<void> initialize() async {
    try {
      // Load TFLite model
      final interpreterOptions = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        'assets/model/sign_model.tflite',
        options: interpreterOptions,
      );

      // Load labels
      final labelsData =
          await rootBundle.loadString('assets/model/labels.txt');
      _labels = labelsData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  // ── Run inference on 42 landmark floats ────────────────────────────────────
  // Input:  21 landmarks flattened → [x0,y0, x1,y1, ... x20,y20] = 42 floats
  // Output: InterpreterResult with predicted letter and confidence
  InterpreterResult predict(List<double> landmarks) {
    if (!_isInitialized || _interpreter == null) {
      return InterpreterResult.noHand();
    }

    if (landmarks.length != 42) {
      return InterpreterResult.noHand();
    }

    try {
      // Input tensor shape [1, 42]
      final input = [landmarks.map((e) => e.toDouble()).toList()];

      // Output tensor shape [1, 27]
      final output =
          List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

      _interpreter!.run(input, output);

      final probabilities = List<double>.from(output[0] as List);

      // Argmax
      double maxProb = 0.0;
      int maxIndex = 0;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      final predictedLabel =
          maxIndex < _labels.length ? _labels[maxIndex] : '?';

      return InterpreterResult(
        letter: predictedLabel,
        confidence: maxProb,
        isHandDetected: true,
      );
    } catch (e) {
      return InterpreterResult.noHand();
    }
  }

  // ── Normalize landmarks relative to wrist ─────────────────────────────────
  // Centers around wrist (landmark 0) and scales to [-1, 1]
  static List<double> normalizeLandmarks(List<dynamic> rawLandmarks) {
    if (rawLandmarks.isEmpty) return [];

    List<double> xs = [];
    List<double> ys = [];

    for (final lm in rawLandmarks) {
      xs.add((lm.x as num).toDouble());
      ys.add((lm.y as num).toDouble());
    }

    // Center around wrist (index 0)
    final wristX = xs[0];
    final wristY = ys[0];

    xs = xs.map((x) => x - wristX).toList();
    ys = ys.map((y) => y - wristY).toList();

    // Scale to [-1, 1]
    final allValues = [...xs, ...ys];
    final maxAbs =
        allValues.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);

    if (maxAbs == 0) return List.filled(42, 0.0);

    xs = xs.map((x) => x / maxAbs).toList();
    ys = ys.map((y) => y / maxAbs).toList();

    // Interleave: [x0, y0, x1, y1, ...]
    final result = <double>[];
    for (int i = 0; i < xs.length; i++) {
      result.add(xs[i]);
      result.add(ys[i]);
    }

    return result;
  }

  // ── Dispose ────────────────────────────────────────────────────────────────
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}