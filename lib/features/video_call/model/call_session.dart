class CallSession {
  final String channelId;
  final String callerId;
  final String calleeId;
  final int localUid;

  const CallSession({
    required this.channelId,
    required this.callerId,
    required this.calleeId,
    required this.localUid,
  });
}

class CallCaption {
  final String senderId;
  final String text;
  final bool isLocal;
  final DateTime timestamp;

  const CallCaption({
    required this.senderId,
    required this.text,
    required this.isLocal,
    required this.timestamp,
  });
}

enum CallState {
  idle,
  calling,      // outgoing ringing
  incoming,     // incoming ringing
  connected,
  ended,
  error,
}