// ── Interpreter Result Model ───────────────────────────────────────────────────
// Returned by InterpreterService after every inference call.
// Keeps the rest of the app decoupled from TFLite details.

class InterpreterResult {
  final String letter;       // predicted label e.g. "A", "Space"
  final double confidence;   // 0.0 – 1.0
  final bool isHandDetected; // false when no hand is in frame

  const InterpreterResult({
    required this.letter,
    required this.confidence,
    required this.isHandDetected,
  });

  /// Empty result when no hand is detected
  factory InterpreterResult.noHand() => const InterpreterResult(
        letter: '',
        confidence: 0.0,
        isHandDetected: false,
      );

  bool get isConfident => confidence >= 0.85;

  @override
  String toString() =>
      'InterpreterResult(letter: $letter, confidence: ${(confidence * 100).toStringAsFixed(1)}%, handDetected: $isHandDetected)';
}