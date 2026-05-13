import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../model/interpreter_result.dart';

class InterpreterService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // ── Initialize ─────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    try {
      // Load model bytes from assets
      final modelData =
          await rootBundle.load('assets/model/sign_model.tflite');
      final modelBytes = modelData.buffer.asUint8List();

      // Create interpreter with no delegates — plain CPU, most compatible
      _interpreter = Interpreter.fromBuffer(modelBytes);

      // Allocate tensors
      _interpreter!.allocateTensors();

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

  // ── Predict ────────────────────────────────────────────────────────────────
  InterpreterResult predict(List<double> landmarks) {
    if (!_isInitialized || _interpreter == null) {
      return InterpreterResult.noHand();
    }
    if (landmarks.length != 42) return InterpreterResult.noHand();

    try {
      // Input: [[x0,y0,x1,y1,...,x20,y20]] shape [1, 42]
      final input = [landmarks];

      // Output: [[p0, p1, ..., p26]] shape [1, 27]
      final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

      _interpreter!.run(input, output);

      final probabilities = output[0];
      double maxProb = 0.0;
      int maxIndex = 0;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      return InterpreterResult(
        letter: maxIndex < _labels.length ? _labels[maxIndex] : '?',
        confidence: maxProb,
        isHandDetected: true,
      );
    } catch (e) {
      return InterpreterResult.noHand();
    }
  }

  // ── Normalize landmarks ────────────────────────────────────────────────────
  static List<double> normalizeLandmarks(List<dynamic> rawLandmarks) {
    if (rawLandmarks.length != 21) return [];

    final xs = rawLandmarks.map((lm) => (lm.x as num).toDouble()).toList();
    final ys = rawLandmarks.map((lm) => (lm.y as num).toDouble()).toList();

    final wristX = xs[0];
    final wristY = ys[0];
    final cx = xs.map((x) => x - wristX).toList();
    final cy = ys.map((y) => y - wristY).toList();

    final all = [...cx, ...cy];
    final maxAbs = all.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);
    if (maxAbs == 0) return List.filled(42, 0.0);

    final sx = cx.map((x) => x / maxAbs).toList();
    final sy = cy.map((y) => y / maxAbs).toList();

    final result = <double>[];
    for (int i = 0; i < 21; i++) {
      result.add(sx[i]);
      result.add(sy[i]);
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