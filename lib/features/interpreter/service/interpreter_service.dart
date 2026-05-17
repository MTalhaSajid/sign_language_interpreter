import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../model/interpreter_result.dart';

enum ModelType { fnn, cnn }

class InterpreterService {
  // ── FNN — UNCHANGED ────────────────────────────────────────────────────────
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // ── CNN ────────────────────────────────────────────────────────────────────
  Interpreter? _cnnInterpreter;
  bool _cnnInitialized = false;
  int _frameCount = 0;

  // Exact label order from predict_live.py:
  // ['A','B','C','D','E','F','G','H','I','J','K','L','M','N',
  //  'Nothing','O','P','Q','R','S','Space','T','U','V','W','X','Y','Z']
  static const _cnnLabels = [
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N',
    'Nothing','O','P','Q','R','S','Space','T','U','V','W','X','Y','Z',
  ];

  // ── Initialize ─────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    try {
      final options = InterpreterOptions()..threads = 2;

      // FNN — unchanged
      final modelData =
          await rootBundle.load('assets/model/sign_model.tflite');
      _interpreter = Interpreter.fromBuffer(
        modelData.buffer.asUint8List(),
        options: options,
      );
      final labelsData =
          await rootBundle.loadString('assets/model/labels.txt');
      _labels = labelsData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      _isInitialized = true;

      // CNN — separate, doesn't affect FNN
      try {
        final cnnData =
            await rootBundle.load('assets/model/sign_cnn_model.tflite');
        _cnnInterpreter = Interpreter.fromBuffer(
          cnnData.buffer.asUint8List(),
          options: options,
        );
        _cnnInitialized = true;
      } catch (e) {
        _cnnInitialized = false;
      }
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  // ── FNN predict — UNCHANGED ────────────────────────────────────────────────
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

  // ── FNN extractLandmarks — UNCHANGED ──────────────────────────────────────
  static List<double> extractLandmarks(
      List<dynamic> rawLandmarks, bool isRightHand) {
    if (rawLandmarks.isEmpty || rawLandmarks.length != 21) return [];

    final result = <double>[];
    for (final lm in rawLandmarks) {
      double x = (lm.x as num).toDouble();
      final double y = (lm.y as num).toDouble();
      if (isRightHand) x = 1.0 - x;
      result.add(x);
      result.add(y);
    }
    return result;
  }

  // ── CNN predict ────────────────────────────────────────────────────────────
  InterpreterResult predictCNN(
      CameraImage cameraImage, int sensorOrientation, int cnnRotation) {
    if (!_cnnInitialized || _cnnInterpreter == null) {
      return InterpreterResult.noHand();
    }

    // Every 3rd frame
    _frameCount++;
    if (_frameCount % 3 != 0) return InterpreterResult.noHand();

    try {
      // Convert YUV420 → RGB
      final rgbImage = _convertYUV420toRGB(cameraImage);
      if (rgbImage == null) return InterpreterResult.noHand();

      // Sensor orientation correction
      img.Image rotated;
      if (sensorOrientation == 90) {
        rotated = img.copyRotate(rgbImage, angle: 90);
      } else if (sensorOrientation == 270) {
        rotated = img.copyRotate(rgbImage, angle: -90);
      } else if (sensorOrientation == 180) {
        rotated = img.copyRotate(rgbImage, angle: 180);
      } else {
        rotated = rgbImage;
      }

      // Apply user-selected extra rotation to fix orientation
      img.Image adjusted;
      if (cnnRotation == 0) {
        adjusted = rotated;
      } else {
        adjusted = img.copyRotate(rotated, angle: cnnRotation);
      }

      // Center square crop
      final fw = adjusted.width;
      final fh = adjusted.height;
      final size = fw < fh ? fw : fh;
      final x1 = (fw ~/ 2 - size ~/ 2).clamp(0, fw - size);
      final y1 = (fh ~/ 2 - size ~/ 2).clamp(0, fh - size);

      final cropped = img.copyCrop(
        adjusted, x: x1, y: y1, width: size, height: size,
      );

      // Resize to 224x224
      final upright = img.copyResize(cropped, width: 224, height: 224);

      // Resize to 224x224

      // Build float32 input [1, 224, 224, 3] normalized /255.0
      final inputBuffer = Float32List(224 * 224 * 3);
      int idx = 0;
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = upright.getPixel(x, y);
          inputBuffer[idx++] = pixel.r / 255.0;
          inputBuffer[idx++] = pixel.g / 255.0;
          inputBuffer[idx++] = pixel.b / 255.0;
        }
      }

      final output = List.filled(
          1 * _cnnLabels.length, 0.0).reshape([1, _cnnLabels.length]);

      _cnnInterpreter!.run(
        inputBuffer.reshape([1, 224, 224, 3]),
        output,
      );

      final probs = List<double>.from(output[0] as List);
      int maxIdx = 0;
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > probs[maxIdx]) maxIdx = i;
      }

      final letter = _cnnLabels[maxIdx];

      // Filter Nothing
      if (letter == 'Nothing') return InterpreterResult.noHand();

      return InterpreterResult(
        letter: letter,
        confidence: probs[maxIdx],
        isHandDetected: true,
      );
    } catch (e) {
      return InterpreterResult.noHand();
    }
  }

  // ── YUV420 → RGB ──────────────────────────────────────────────────────────
  img.Image? _convertYUV420toRGB(CameraImage cam) {
    try {
      final w = cam.width;
      final h = cam.height;
      final yPlane = cam.planes[0];
      final uPlane = cam.planes[1];
      final vPlane = cam.planes[2];
      final yBytes = yPlane.bytes;
      final uBytes = uPlane.bytes;
      final vBytes = vPlane.bytes;
      final uvRowStride = uPlane.bytesPerRow;
      final uvPixelStride = uPlane.bytesPerPixel ?? 1;
      final image = img.Image(width: w, height: h);

      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final yVal = yBytes[y * yPlane.bytesPerRow + x] & 0xFF;
          final uvIdx =
              (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;
          final uVal =
              uvIdx < uBytes.length ? uBytes[uvIdx] & 0xFF : 128;
          final vVal =
              uvIdx < vBytes.length ? vBytes[uvIdx] & 0xFF : 128;
          final r = (yVal + 1.402 * (vVal - 128)).round().clamp(0, 255);
          final g =
              (yVal - 0.344 * (uVal - 128) - 0.714 * (vVal - 128))
                  .round()
                  .clamp(0, 255);
          final b = (yVal + 1.772 * (uVal - 128)).round().clamp(0, 255);
          image.setPixelRgb(x, y, r, g, b);
        }
      }
      return image;
    } catch (e) {
      return null;
    }
  }

  // ── Dispose ────────────────────────────────────────────────────────────────
  void dispose() {
    _interpreter?.close();
    _cnnInterpreter?.close();
    _interpreter = null;
    _cnnInterpreter = null;
    _isInitialized = false;
    _cnnInitialized = false;
  }
}