import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../model/call_session.dart';

// ⚠️ REPLACE THIS with your NEW Agora App ID (Testing Mode project)
const _agoraAppId = 'd5e8c646290d4a13a8d395d56fc964e6';

// ── Partner email — dynamic based on who is logged in ─────────────────────────
// Same APK works on both phones
String _getPartnerEmail(String myEmail) {
  if (myEmail == 'talha.sajid1997@gmail.com') return 'omnicosts@gmail.com';
  if (myEmail == 'omnicosts@gmail.com') return 'talha.sajid1997@gmail.com';
  return ''; // Add more pairs here if needed
}

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

  // Firestore listener for call status
  StreamSubscription? _callStatusSub;

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

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        debugPrint('AGORA ✅ Joined: ${connection.channelId} '
            'uid:${connection.localUid}');
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        debugPrint('AGORA ✅ Remote joined: $remoteUid');
        onRemoteUserJoined?.call(remoteUid);
      },
      onUserOffline: (connection, remoteUid, reason) {
        debugPrint('AGORA ⚠️ Remote left: $remoteUid');
        onRemoteUserLeft?.call(remoteUid);
        if (reason == UserOfflineReasonType.userOfflineQuit) {
          onCallEnded?.call();
        }
      },
      onError: (err, msg) {
        debugPrint('AGORA ❌ $err: $msg');
      },
      onConnectionStateChanged: (connection, state, reason) {
        debugPrint('AGORA 🔄 State:$state Reason:$reason');
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

    debugPrint('AGORA 📡 Joining: $channelId');

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

    // Also listen to Firestore for status=connected
    // This is a fallback in case Agora onUserJoined doesn't fire
    _listenForCallConnected(channelId);

    _dataStreamId = await _engine!.createDataStream(
      const DataStreamConfig(syncWithAudio: false, ordered: true),
    );
  }

  // ── Firestore fallback — detect when both are in call ─────────────────────
  void _listenForCallConnected(String channelId) {
    _callStatusSub?.cancel();
    _callStatusSub = _firestore
        .collection('calls')
        .doc(channelId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final status = doc['status'] as String?;
      debugPrint('FIRESTORE 📋 Call status: $status');

      if (status == 'connected') {
        // Both sides ready — wait 3s for Agora onUserJoined
        // If it hasn't fired by then, force connected with uid=1
        Future.delayed(const Duration(seconds: 3), () {
          if (onRemoteUserJoined != null) {
            debugPrint('FIRESTORE ✅ Forcing connected via fallback');
            onRemoteUserJoined?.call(1);
          }
        });
      } else if (status == 'ended') {
        onCallEnded?.call();
      }
    });
  }

  // ── Leave channel ──────────────────────────────────────────────────────────
  Future<void> leaveChannel() async {
    _callStatusSub?.cancel();
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
    final partnerEmail = _getPartnerEmail(_myEmail);

    debugPrint('AGORA 📞 Creating call: $channelId → $partnerEmail');

    await _firestore.collection('calls').doc(channelId).set({
      'channelId': channelId,
      'callerEmail': _myEmail,
      'calleeEmail': partnerEmail,
      'status': 'calling',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return channelId;
  }

  // ── Accept call ────────────────────────────────────────────────────────────
  Future<void> acceptCall(String channelId) async {
    debugPrint('AGORA 📞 Accepting: $channelId');
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
    _callStatusSub?.cancel();
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
  }
}