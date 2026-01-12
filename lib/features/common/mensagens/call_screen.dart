import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:chegaja_v2/core/services/call_service.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.callId,
    required this.pedidoId,
    required this.isCaller,
    required this.videoEnabled,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhotoUrl,
  });

  final String callId;
  final String pedidoId;
  final bool isCaller;
  final bool videoEnabled;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _db = FirebaseFirestore.instance;
  final _callService = CallService.instance;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _candidateSub;

  bool _accepted = false;
  bool _connecting = true;
  bool _muted = false;
  bool _videoOn = true;
  bool _remoteHasVideo = false;
  bool _ending = false;
  bool _remoteDescriptionSet = false;

  @override
  void initState() {
    super.initState();
    _videoOn = widget.videoEnabled;
    _init();
  }

  @override
  void dispose() {
    _callSub?.cancel();
    _candidateSub?.cancel();
    _disposeRtc();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    final permissionsOk = await _ensurePermissions();
    if (!permissionsOk) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }

    _listenToCallDoc();

    if (widget.isCaller) {
      await _startAsCaller();
    }
  }

  Future<bool> _ensurePermissions() async {
    if (kIsWeb) return true;
    final perms = <Permission>[Permission.microphone];
    if (widget.videoEnabled) perms.add(Permission.camera);

    final statuses = await perms.request();
    return statuses.values.every((s) => s.isGranted);
  }

  DocumentReference<Map<String, dynamic>> get _callRef =>
      _db.collection('calls').doc(widget.callId);

  Map<String, dynamic> get _rtcConfig {
    return {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };
  }

  Future<void> _listenToCallDoc() async {
    _callSub = _callService.streamCall(widget.callId).listen((snap) async {
      final data = snap.data();
      if (data == null) return;

      final status = (data['status'] ?? '').toString();
      if (status == 'declined' || status == 'ended') {
        if (!_ending) {
          _ending = true;
          if (mounted) Navigator.of(context).maybePop();
        }
        return;
      }

      final answer = data['answer'];
      if (widget.isCaller && answer != null && !_remoteDescriptionSet) {
        final desc = RTCSessionDescription(
          answer['sdp']?.toString(),
          answer['type']?.toString(),
        );
        await _peerConnection?.setRemoteDescription(desc);
        _remoteDescriptionSet = true;
        if (mounted) setState(() => _accepted = true);
      }
    });
  }

  Future<void> _startAsCaller() async {
    await _preparePeerConnection(isCaller: true);

    final offer = await _peerConnection?.createOffer();
    if (offer == null) return;

    await _peerConnection?.setLocalDescription(offer);
    await _callRef.set(
      {
        'offer': offer.toMap(),
        'status': 'ringing',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    _candidateSub = _callRef
        .collection('answerCandidates')
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docChanges) {
        final data = doc.doc.data();
        if (data == null) continue;
        final candidate = RTCIceCandidate(
          data['candidate']?.toString(),
          data['sdpMid']?.toString(),
          data['sdpMLineIndex'] as int?,
        );
        _peerConnection?.addCandidate(candidate);
      }
    });

    if (mounted) setState(() => _connecting = false);
  }

  Future<void> _acceptCall() async {
    await _preparePeerConnection(isCaller: false);

    final snap = await _callRef.get();
    final data = snap.data();
    if (data == null || data['offer'] == null) return;

    final offer = data['offer'];
    final desc = RTCSessionDescription(
      offer['sdp']?.toString(),
      offer['type']?.toString(),
    );
    await _peerConnection?.setRemoteDescription(desc);
    _remoteDescriptionSet = true;

    final answer = await _peerConnection?.createAnswer();
    if (answer == null) return;
    await _peerConnection?.setLocalDescription(answer);

    await _callRef.set(
      {
        'answer': answer.toMap(),
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
        'acceptedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    _candidateSub = _callRef
        .collection('offerCandidates')
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docChanges) {
        final data = doc.doc.data();
        if (data == null) continue;
        final candidate = RTCIceCandidate(
          data['candidate']?.toString(),
          data['sdpMid']?.toString(),
          data['sdpMLineIndex'] as int?,
        );
        _peerConnection?.addCandidate(candidate);
      }
    });

    if (mounted) {
      setState(() {
        _accepted = true;
        _connecting = false;
      });
    }
  }

  Future<void> _preparePeerConnection({required bool isCaller}) async {
    if (_peerConnection != null) return;

    _peerConnection = await createPeerConnection(_rtcConfig);
    _peerConnection?.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams.first;
        if (mounted) setState(() => _remoteHasVideo = true);
      }
    };

    _peerConnection?.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      final target =
          isCaller ? 'offerCandidates' : 'answerCandidates';
      _callRef.collection(target).add(candidate.toMap());
    };

    await _initLocalMedia();

    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await _peerConnection?.addTrack(track, _localStream!);
    }
  }

  Future<void> _initLocalMedia() async {
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': _videoOn
          ? {
              'facingMode': 'user',
              'width': 640,
              'height': 480,
              'frameRate': 30,
            }
          : false,
    };
    final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localStream = stream;
    _localRenderer.srcObject = stream;
  }

  Future<void> _toggleMute() async {
    final tracks = _localStream?.getAudioTracks() ?? <MediaStreamTrack>[];
    for (final t in tracks) {
      t.enabled = _muted;
    }
    if (mounted) setState(() => _muted = !_muted);
  }

  Future<void> _toggleVideo() async {
    final tracks = _localStream?.getVideoTracks() ?? <MediaStreamTrack>[];
    if (tracks.isEmpty) {
      if (_videoOn) return;
      _videoOn = true;
      await _initLocalMedia();
      for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
        await _peerConnection?.addTrack(track, _localStream!);
      }
      if (mounted) setState(() {});
      return;
    }
    for (final t in tracks) {
      t.enabled = !_videoOn;
    }
    if (mounted) setState(() => _videoOn = !_videoOn);
  }

  Future<void> _switchCamera() async {
    if (kIsWeb) return;
    final tracks = _localStream?.getVideoTracks() ?? <MediaStreamTrack>[];
    if (tracks.isEmpty) return;
    await Helper.switchCamera(tracks.first);
  }

  Future<void> _hangUp({String status = 'ended'}) async {
    if (_ending) return;
    _ending = true;
    await _callService.updateStatus(widget.callId, status);
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _disposeRtc() async {
    try {
      await _localStream?.dispose();
    } catch (_) {}
    try {
      await _peerConnection?.close();
    } catch (_) {}
    _peerConnection = null;
    _localStream = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIncoming = !widget.isCaller && !_accepted;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.videoEnabled ? l10n.chatVideoCallAction : l10n.chatVoiceCallAction),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.videoEnabled && _remoteHasVideo
                ? RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : _buildCallBackdrop(context),
          ),
          if (widget.videoEnabled)
            Positioned(
              right: 16,
              top: 16,
              child: SizedBox(
                width: 120,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RTCVideoView(
                    _localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            ),
          if (isIncoming)
            Positioned.fill(
              child: _buildIncomingOverlay(context),
            ),
          if (!isIncoming)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: _buildControls(context),
            ),
          if (_connecting)
            const Positioned(
              left: 0,
              right: 0,
              top: 24,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCallBackdrop(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundImage:
                widget.otherUserPhotoUrl != null ? NetworkImage(widget.otherUserPhotoUrl!) : null,
            child: widget.otherUserPhotoUrl == null
                ? Text(
                    widget.otherUserName.isNotEmpty
                        ? widget.otherUserName.substring(0, 1).toUpperCase()
                        : 'C',
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            widget.otherUserName,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingOverlay(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.chatIncomingCall,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          _buildCallBackdrop(context),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                heroTag: 'decline',
                backgroundColor: Colors.red,
                onPressed: () => _hangUp(status: 'declined'),
                child: const Icon(Icons.call_end),
              ),
              const SizedBox(width: 24),
              FloatingActionButton(
                heroTag: 'accept',
                backgroundColor: Colors.green,
                onPressed: _acceptCall,
                child: const Icon(Icons.call),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          color: Colors.white,
          icon: Icon(_muted ? Icons.mic_off : Icons.mic),
          onPressed: _toggleMute,
        ),
        if (widget.videoEnabled)
          IconButton(
            color: Colors.white,
            icon: Icon(_videoOn ? Icons.videocam : Icons.videocam_off),
            onPressed: _toggleVideo,
          ),
        if (widget.videoEnabled && !kIsWeb)
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.cameraswitch),
            onPressed: _switchCamera,
          ),
        FloatingActionButton(
          heroTag: 'hangup',
          backgroundColor: Colors.red,
          onPressed: _hangUp,
          child: const Icon(Icons.call_end),
        ),
      ],
    );
  }
}
