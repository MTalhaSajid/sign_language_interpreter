class InterpreterResult {
  final String letter;
  final double confidence;
  final bool isHandDetected;

  const InterpreterResult({
    required this.letter,
    required this.confidence,
    required this.isHandDetected,
  });

  factory InterpreterResult.noHand() => const InterpreterResult(
        letter: '',
        confidence: 0.0,
        isHandDetected: false,
      );

  bool get isConfident => confidence >= 0.85;

  @override
  String toString() =>
      'InterpreterResult(letter: $letter, '
      'confidence: ${(confidence * 100).toStringAsFixed(1)}%, '
      'handDetected: $isHandDetected)';
}