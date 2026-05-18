import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_styles.dart';

class IncomingCallListener extends StatefulWidget {
  final Widget child;
  const IncomingCallListener({super.key, required this.child});

  @override
  State<IncomingCallListener> createState() =>
      _IncomingCallListenerState();
}

class _IncomingCallListenerState extends State<IncomingCallListener> {
  StreamSubscription<QuerySnapshot>? _callSub;
  StreamSubscription? _authSub;
  final Set<String> _shownChannels = {};
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _callSub?.cancel();
      if (user != null && user.email != null) {
        _listenForCalls(user.email!);
      }
    });
  }

  void _listenForCalls(String myEmail) {
    debugPrint('CALL_LISTENER: Listening for calls to: $myEmail');

    _callSub = FirebaseFirestore.instance
        .collection('calls')
        .where('calleeEmail', isEqualTo: myEmail)
        .where('status', isEqualTo: 'calling')
        .snapshots()
        .listen((snapshot) {
      debugPrint('CALL_LISTENER: Got ${snapshot.docs.length} docs');

      if (snapshot.docs.isEmpty) return;
      if (_dialogShowing) return;

      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      final doc = docs.first;
      final channelId = doc['channelId'] as String;
      final callerEmail = doc['callerEmail'] as String;

      if (_shownChannels.contains(channelId)) return;
      _shownChannels.add(channelId);
      _dialogShowing = true;

      debugPrint('CALL_LISTENER: Showing dialog for $channelId');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showIncomingDialog(channelId, callerEmail);
      });
    }, onError: (e) {
      debugPrint('CALL_LISTENER Error: $e');
    });
  }

  void _showIncomingDialog(String channelId, String callerEmail) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      debugPrint('CALL_LISTENER: Context null, retrying...');
      Future.delayed(const Duration(milliseconds: 500), () {
        _showIncomingDialog(channelId, callerEmail);
      });
      return;
    }

    debugPrint('CALL_LISTENER: Context ready, showing dialog');

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusLg),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.video_call_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Incoming Video Call',
                style: AppFonts.headingSmall
                    .copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(callerEmail,
                style: AppFonts.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('wants to sign with you',
                style: AppFonts.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      _dialogShowing = false;
                      Navigator.of(dialogCtx).pop();
                      await FirebaseFirestore.instance
                          .collection('calls')
                          .doc(channelId)
                          .update({'status': 'ended'});
                    },
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: AppStyles.radiusMd,
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call_end_rounded, color: Colors.red, size: 22),
                          SizedBox(height: 4),
                          Text('Decline', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _dialogShowing = false;
                      Navigator.of(dialogCtx).pop();
                      ctx.go('/call/$channelId?incoming=true');
                    },
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.15),
                        borderRadius: AppStyles.radiusMd,
                        border: Border.all(color: AppColors.teal.withOpacity(0.5)),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call_rounded, color: AppColors.teal, size: 22),
                          SizedBox(height: 4),
                          Text('Accept', style: TextStyle(color: AppColors.teal, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).then((_) => _dialogShowing = false);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _callSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}