import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../model/interpreter_result.dart';

class InterpreterService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      final modelData =
          await rootBundle.load('assets/model/sign_model.tflite');
      final modelBytes = modelData.buffer.asUint8List();

      final interpreterOptions = InterpreterOptions()..threads = 2;
      _interpreter = Interpreter.fromBuffer(
        modelBytes,
        options: interpreterOptions,
      );

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

  InterpreterResult predict(List<double> landmarks) {
    if (!_isInitialized || _interpreter == null) {
      return InterpreterResult.noHand();
    }
    if (landmarks.length != 42) return InterpreterResult.noHand();

    try {
      final input = [landmarks.map((e) => e.toDouble()).toList()];
      final output =
          List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

      _interpreter!.run(input, output);

      final probabilities = List<double>.from(output[0] as List);
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

  // RAW - no transform - pass exactly as hand_landmarker gives
  static List<double> extractLandmarks(List<dynamic> rawLandmarks) {
    if (rawLandmarks.isEmpty || rawLandmarks.length != 21) return [];

    final result = <double>[];
    for (final lm in rawLandmarks) {
      result.add((lm.x as num).toDouble());
      result.add((lm.y as num).toDouble());
    }
    return result;
  }

  void resetDebug() {}

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}