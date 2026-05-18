import 'dart:convert';
import 'dart:typed_data';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../model/call_session.dart';

const _agoraAppId = 'ac65ed28e8094e3e8b32dca67d1fbe42';
const _partnerEmail = 'omnicosts@gmail.com';

class CallService {
  RtcEngine? _engine;
  RtcEngine? get engine => _engine;
  int? _dataStreamId;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _myEmail => _auth.currentUser?.email ?? '';

  // ── Callbacks ──────────────────────────────────────────────────────────────
  Function(int remoteUid)? onRemoteUserJoined;
  Function(int remoteUid)? onRemoteUserLeft;
  Function(CallCaption caption)? onCaptionReceived;
  Function()? onCallEnded;

  // ── Initialize Agora ───────────────────────────────────────────────────────
  Future<void> initialize() async {
    _engine = createAgoraRtcEngine();

    await _engine!.initialize(RtcEngineContext(
      appId: _agoraAppId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    await _engine!.enableVideo();
    await _engine!.enableAudio();
    await _engine!.startPreview();

    // Register event handler AFTER setting up engine
    // Callbacks are called via the stored function references
    // so they will use whatever is set at time of event
    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        debugPrint('AGORA ✅ Joined channel: ${connection.channelId} '
            'uid: ${connection.localUid}');
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        debugPrint('AGORA ✅ Remote user joined: $remoteUid');
        onRemoteUserJoined?.call(remoteUid);
      },
      onUserOffline: (connection, remoteUid, reason) {
        debugPrint('AGORA ⚠️ Remote user left: $remoteUid reason: $reason');
        onRemoteUserLeft?.call(remoteUid);
        if (reason == UserOfflineReasonType.userOfflineQuit) {
          onCallEnded?.call();
        }
      },
      onError: (err, msg) {
        debugPrint('AGORA ❌ Error: $err - $msg');
      },
      onConnectionStateChanged: (connection, state, reason) {
        debugPrint('AGORA 🔄 Connection: $state reason: $reason');
      },
      onLeaveChannel: (connection, stats) {
        debugPrint('AGORA 👋 Left channel');
      },
      onStreamMessage: (connection, remoteUid, streamId,
          data, length, sentTs) {
        try {
          final json =
              jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
          onCaptionReceived?.call(CallCaption(
            senderId: json['senderId'] as String,
            text: json['text'] as String,
            isLocal: false,
            timestamp: DateTime.now(),
          ));
        } catch (_) {}
      },
    ));

    debugPrint('AGORA ✅ Engine initialized');
  }

  // ── Join channel ───────────────────────────────────────────────────────────
  Future<void> joinChannel(String channelId) async {
    if (_engine == null) await initialize();

    debugPrint('AGORA 📡 Joining channel: $channelId');

    await _engine!.joinChannel(
      token: '',
      channelId: channelId,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile:
            ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );

    _dataStreamId = await _engine!.createDataStream(
      const DataStreamConfig(syncWithAudio: false, ordered: true),
    );
  }

  // ── Leave channel ──────────────────────────────────────────────────────────
  Future<void> leaveChannel() async {
    await _engine?.leaveChannel();
  }

  // ── Send caption ───────────────────────────────────────────────────────────
  Future<void> sendCaption(String channelId, String text) async {
    if (_engine == null || _dataStreamId == null) return;
    try {
      final data = utf8.encode(jsonEncode({
        'senderId': _myEmail,
        'text': text,
      }));
      await _engine!.sendStreamMessage(
        streamId: _dataStreamId!,
        data: Uint8List.fromList(data),
        length: data.length,
      );
    } catch (_) {}
  }

  // ── Start call ─────────────────────────────────────────────────────────────
  Future<String> startCall() async {
    final channelId =
        'signtalk_${DateTime.now().millisecondsSinceEpoch}';

    debugPrint('AGORA 📞 Starting call, channel: $channelId');

    await _firestore.collection('calls').doc(channelId).set({
      'channelId': channelId,
      'callerEmail': _myEmail,
      'calleeEmail': _partnerEmail,
      'status': 'calling',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return channelId;
  }

  // ── Accept call ────────────────────────────────────────────────────────────
  Future<void> acceptCall(String channelId) async {
    debugPrint('AGORA 📞 Accepting call: $channelId');
    await _firestore.collection('calls').doc(channelId).update({
      'status': 'connected',
    });
  }

  // ── Decline call ───────────────────────────────────────────────────────────
  Future<void> declineCall(String channelId) async {
    await _firestore.collection('calls').doc(channelId).update({
      'status': 'ended',
    });
  }

  // ── Listen for incoming calls ──────────────────────────────────────────────
  Stream<QuerySnapshot> listenForIncomingCalls() {
    return _firestore
        .collection('calls')
        .where('calleeEmail', isEqualTo: _myEmail)
        .where('status', isEqualTo: 'calling')
        .snapshots();
  }

  // ── Controls ───────────────────────────────────────────────────────────────
  Future<void> toggleMute(bool muted) async {
    await _engine?.muteLocalAudioStream(muted);
  }

  Future<void> toggleCamera(bool off) async {
    await _engine?.muteLocalVideoStream(off);
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  // ── Dispose ────────────────────────────────────────────────────────────────
  Future<void> dispose() async {
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
  }
}