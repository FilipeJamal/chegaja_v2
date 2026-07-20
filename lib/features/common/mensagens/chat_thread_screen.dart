import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/models/chat_message.dart';
import 'package:chegaja_v2/core/models/moderation_types.dart';
import 'package:chegaja_v2/core/services/call_service.dart';
import 'package:chegaja_v2/core/services/chat_service.dart';
import 'package:chegaja_v2/core/services/private_storage_media_service.dart';
import 'package:chegaja_v2/core/services/storage_path_policy.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/utils/url_bytes_loader.dart';
import 'package:chegaja_v2/core/widgets/app_avatar.dart';
import 'package:chegaja_v2/core/widgets/private_storage_image.dart';
import 'package:chegaja_v2/features/common/mensagens/call_screen.dart';
import 'package:chegaja_v2/features/common/mensagens/chat_favorites_screen.dart';
import 'package:chegaja_v2/features/common/mensagens/chat_media_screen.dart';
import 'package:chegaja_v2/features/common/mensagens/chat_search_screen.dart';
import 'package:chegaja_v2/features/common/perfil_publico_screen.dart';
import 'package:chegaja_v2/features/common/trust_safety/block_user_dialog.dart';
import 'package:chegaja_v2/features/common/trust_safety/report_content_sheet.dart';
import 'package:chegaja_v2/features/common/widgets/media_viewer_screen.dart';
import 'package:chegaja_v2/features/auth/phone_verification_screen.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

/// Chat (aba Mensagens) com layout semelhante ao chat nos detalhes do pedido.
///
/// ✅ Inclui:
/// - Separadores de dia (Hoje/Ontem/data)
/// - Estado enviado/entregue/visto
/// - Anexos: foto (galeria/câmara), ficheiros, áudio (como ficheiro)
/// - Top bar com chamadas/videochamadas (placeholder) + online/"visto por último"
class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.pedidoId,
    required this.viewerRole,
    required this.otherUserId,
    this.otherUserName,
    this.otherUserPhotoUrl,
    this.pedidoTitulo,
    this.onReportSubmit,
    this.onBlockUser,
  });

  /// ID do pedido (é também o ID do chat)
  final String pedidoId;

  /// Papel de quem está a ver o chat: `cliente` ou `prestador`
  final String viewerRole;

  /// UID do outro utilizador (lado oposto)
  final String otherUserId;

  /// Nome do outro utilizador (se já estiver disponível)
  final String? otherUserName;

  /// Foto do outro utilizador (se já estiver disponível)
  final String? otherUserPhotoUrl;

  /// Título do pedido (mostra por baixo do nome)
  final String? pedidoTitulo;

  final ReportSubmitCallback? onReportSubmit;
  final BlockUserCallback? onBlockUser;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _WebRecordConfig {
  const _WebRecordConfig({
    required this.encoder,
    required this.mimeType,
    required this.extension,
  });

  final AudioEncoder encoder;
  final String mimeType;
  final String extension;
}

class _MediaItem {
  const _MediaItem({
    required this.id,
    required this.url,
  });

  final String id;
  final String url;
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();

  final TextEditingController _messageCtrl = TextEditingController();
  final FocusNode _messageFocus = FocusNode();

  bool _sending = false;
  bool _uploading = false;
  bool _recording = false;
  StreamSubscription<Uint8List>? _recordSub;
  Completer<void>? _recordDone;
  BytesBuilder? _recordBuffer;
  _WebRecordConfig? _activeWebConfig;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _incomingCallSub;
  String? _activeIncomingCallId;
  bool _callScreenOpen = false;
  String? _lastOtherName;
  String? _lastOtherPhoto;

  String get _otherRole =>
      widget.viewerRole == 'prestador' ? 'cliente' : 'prestador';
  String get _otherCollection =>
      _otherRole == 'prestador' ? 'provider_public' : 'public_profiles';
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  static const int _maxAudioBytes = 20 * 1024 * 1024; // 20MB
  static const RecordConfig _recordConfig = RecordConfig(
    encoder: AudioEncoder.aacLc,
    numChannels: 1,
    bitRate: 96000,
    sampleRate: 44100,
  );
  static const List<String> _emojiList = [
    '\u{1F600}',
    '\u{1F603}',
    '\u{1F604}',
    '\u{1F601}',
    '\u{1F609}',
    '\u{1F60D}',
    '\u{1F618}',
    '\u{1F60E}',
    '\u{1F622}',
    '\u{1F62D}',
    '\u{1F605}',
    '\u{1F914}',
    '\u{1F44D}',
    '\u{1F64C}',
    '\u{1F44F}',
    '\u{1F525}',
    '\u{1F4AA}',
    '\u{1F6E0}',
    '\u{1F527}',
    '\u{1F9F0}',
    '\u{1F9F9}',
    '\u{1F4A1}',
    '\u{2705}',
    '\u{23F0}',
  ];
  static const List<_MediaItem> _stickerItems = [
    _MediaItem(
      id: 'thumbs_up',
      url:
          'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f44d.png',
    ),
    _MediaItem(
      id: 'celebrate',
      url:
          'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f64c.png',
    ),
    _MediaItem(
      id: 'tools',
      url:
          'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f6e0.png',
    ),
    _MediaItem(
      id: 'wrench',
      url:
          'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f527.png',
    ),
    _MediaItem(
      id: 'toolbox',
      url:
          'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f9f0.png',
    ),
    _MediaItem(
      id: 'broom',
      url:
          'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f9f9.png',
    ),
    _MediaItem(
      id: 'light',
      url:
          'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f4a1.png',
    ),
    _MediaItem(
      id: 'box',
      url:
          'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f4e6.png',
    ),
    _MediaItem(
      id: 'check',
      url:
          'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/2705.png',
    ),
    _MediaItem(
      id: 'alarm',
      url:
          'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/23f0.png',
    ),
    _MediaItem(
      id: 'car',
      url:
          'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f697.png',
    ),
    _MediaItem(
      id: 'fire',
      url:
          'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f525.png',
    ),
  ];
  static const List<_MediaItem> _gifItems = [
    _MediaItem(
      id: 'thumbs_up',
      url: 'https://media.giphy.com/media/111ebonMs90YLu/giphy.gif',
    ),
    _MediaItem(
      id: 'clap',
      url: 'https://media.giphy.com/media/26ufdipQqU2lhNA4g/giphy.gif',
    ),
    _MediaItem(
      id: 'thanks',
      url: 'https://media.giphy.com/media/3o6ZtpxSZbQRRnwCKQ/giphy.gif',
    ),
    _MediaItem(
      id: 'working',
      url: 'https://media.giphy.com/media/l0HlBO7eyXzSZkJri/giphy.gif',
    ),
    _MediaItem(
      id: 'ok',
      url: 'https://media.giphy.com/media/3o7aD2saalBwwftBIY/giphy.gif',
    ),
    _MediaItem(
      id: 'nice',
      url: 'https://media.giphy.com/media/5GoVLqeAOo6PK/giphy.gif',
    ),
  ];

  Stream<DocumentSnapshot<Map<String, dynamic>>> get _otherUserStream {
    final id = widget.otherUserId.trim();
    if (id.isEmpty) return const Stream.empty();
    return _db.collection(_otherCollection).doc(id).snapshots();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _startSecureChat());
  }

  Future<void> _startSecureChat() async {
    final allowed = await VerifiedPhoneGate.ensure(
      context,
      action: 'abrir o chat',
    );
    if (!mounted) return;
    if (!allowed) {
      Navigator.of(context).pop();
      return;
    }

    // garante meta do chat e marca como entregue para o viewerRole
    await ChatService.instance.ensureChatMeta(widget.pedidoId);
    await ChatService.instance.marcarEntreguesParaRole(
      pedidoId: widget.pedidoId,
      role: widget.viewerRole,
    );

    // presença (simples)
    _setMyPresence(isOnline: true);
    _listenForIncomingCalls();
  }

  @override
  void dispose() {
    _incomingCallSub?.cancel();
    _setMyPresence(isOnline: false);
    _recordSub?.cancel();
    _recorder.dispose();
    _messageCtrl.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Presença (online / visto por último)
  // ---------------------------------------------------------------------------

  Future<void> _setMyPresence({required bool isOnline}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final now = FieldValue.serverTimestamp();

    // users/{uid}
    try {
      await _db.collection('users_private').doc(uid).set(
        {
          'isOnline': isOnline,
          'lastSeenAt': now,
        },
        SetOptions(merge: true),
      );
    } catch (_) {}

    // Estado operacional privado do prestador.
    if (widget.viewerRole == 'prestador') {
      try {
        await _db.collection('provider_dispatch_private').doc(uid).set(
          {
            'isOnline': isOnline,
            'lastSeenAt': now,
          },
          SetOptions(merge: true),
        );
      } catch (_) {}
    }
  }

  String _resolveOtherName(Map<String, dynamic>? otherData) {
    final fromDoc =
        (otherData?['nome'] ?? otherData?['displayName'] ?? otherData?['name'])
            ?.toString()
            .trim();
    if (fromDoc != null && fromDoc.isNotEmpty) return fromDoc;

    final fromParam = widget.otherUserName?.toString().trim();
    if (fromParam != null && fromParam.isNotEmpty) return fromParam;

    return _otherRole == 'prestador'
        ? _l10n.roleLabelProvider
        : _l10n.roleLabelCustomer;
  }

  String? _resolveOtherPhoto(Map<String, dynamic>? otherData) {
    final fromDoc = (otherData?['photoUrl'] ??
            otherData?['fotoUrl'] ??
            otherData?['avatarUrl'])
        ?.toString()
        .trim();
    if (fromDoc != null && fromDoc.startsWith('http')) return fromDoc;

    final fromParam = widget.otherUserPhotoUrl?.toString().trim();
    if (fromParam != null && fromParam.startsWith('http')) return fromParam;

    return null;
  }

  String _formatPresence(Map<String, dynamic>? otherData) {
    final isOnline = otherData?['isOnline'] == true;
    if (isOnline) return _l10n.chatPresenceOnline;

    Timestamp? ts;
    final raw = otherData?['lastSeenAt'] ?? otherData?['updatedAt'];
    if (raw is Timestamp) ts = raw;
    if (ts == null) return '';

    final dt = ts.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(day).inDays;

    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');

    if (diffDays == 0) return _l10n.chatPresenceLastSeenAt('$hh:$mm');
    if (diffDays == 1) {
      return _l10n.chatPresenceLastSeenYesterdayAt('$hh:$mm');
    }

    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final date = '$dd/$mo';
    return _l10n.chatPresenceLastSeenOn(date, '$hh:$mm');
  }

  // ---------------------------------------------------------------------------
  // Helpers de data/hora
  // ---------------------------------------------------------------------------

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDayHeader(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) return _l10n.todayLabel;
    if (diff == 1) return _l10n.yesterdayLabel;

    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _formatTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  // ---------------------------------------------------------------------------
  // Envio de mensagens
  // ---------------------------------------------------------------------------

  Future<void> _sendText() async {
    final txt = _messageCtrl.text.trim();
    if (txt.isEmpty) return;

    setState(() => _sending = true);
    try {
      await ChatService.instance.sendMessage(
        pedidoId: widget.pedidoId,
        senderRole: widget.viewerRole,
        text: txt,
      );

      _messageCtrl.clear();
      _messageFocus.requestFocus();

      await ChatService.instance.marcarVistasParaRole(
        pedidoId: widget.pedidoId,
        role: widget.viewerRole,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.chatSendError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<String> _uploadBytes({
    required Uint8List bytes,
    required String path,
    String? contentType,
  }) async {
    final ref = _storage.ref().child(path);
    final meta =
        contentType == null ? null : SettableMetadata(contentType: contentType);
    final task = await ref.putData(bytes, meta);
    try {
      await PrivateStorageMediaService.instance.finalizeUpload(path);
    } catch (_) {
      try {
        await task.ref.delete();
      } catch (_) {
        // O backend também rejeita media sem finalização; não mascara o erro original.
      }
      rethrow;
    }
    return path;
  }

  String _safeFileName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'file';
    return trimmed.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  Future<void> _pickAndSendImage({required ImageSource source}) async {
    if (_uploading) return;

    try {
      final x = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (x == null) return;

      setState(() => _uploading = true);

      final bytes = await x.readAsBytes();
      if (bytes.isEmpty) return;

      const maxBytes = 15 * 1024 * 1024; // 15MB
      if (bytes.lengthInBytes > maxBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.chatImageTooLarge)),
        );
        return;
      }

      final originalName = x.name.isNotEmpty ? x.name : 'photo.jpg';
      final fileName = _safeFileName(originalName);
      final ts = DateTime.now().millisecondsSinceEpoch;

      final lower = fileName.toLowerCase();
      final contentType = lower.endsWith('.png') ? 'image/png' : 'image/jpeg';

      final mediaPath = await _uploadBytes(
        bytes: bytes,
        path: 'chats/${widget.pedidoId}/images/${ts}_$fileName',
        contentType: contentType,
      );

      // Se houver texto no campo, usa como legenda
      final caption = _messageCtrl.text.trim();
      if (caption.isNotEmpty) _messageCtrl.clear();

      await ChatService.instance.sendMessage(
        pedidoId: widget.pedidoId,
        senderRole: widget.viewerRole,
        text: caption.isNotEmpty ? caption : null,
        extra: {
          'type': 'image',
          'mediaPath': mediaPath,
          'fileName': fileName,
          'fileSize': bytes.lengthInBytes,
          'mimeType': contentType,
        },
      );

      await ChatService.instance.marcarVistasParaRole(
        pedidoId: widget.pedidoId,
        role: widget.viewerRole,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.chatImageSendError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickAndSendFile() async {
    if (_uploading) return;

    try {
      final res = await FilePicker.platform.pickFiles(
        withData: true,
        allowMultiple: false,
      );
      if (res == null || res.files.isEmpty) return;

      final f = res.files.first;
      final bytes = f.bytes;

      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.chatFileReadError)),
        );
        return;
      }

      const maxBytes = 20 * 1024 * 1024; // 20MB
      if (bytes.lengthInBytes > maxBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.chatFileTooLarge)),
        );
        return;
      }

      setState(() => _uploading = true);

      final fileName = _safeFileName(f.name.isNotEmpty ? f.name : 'file');
      final contentType =
          StoragePathPolicy.attachmentContentTypeForFileName(fileName);
      if (contentType == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tipo de ficheiro nao suportado.')),
        );
        return;
      }

      final ts = DateTime.now().millisecondsSinceEpoch;

      final mediaPath = await _uploadBytes(
        bytes: bytes,
        path: 'chats/${widget.pedidoId}/files/${ts}_$fileName',
        contentType: contentType,
      );

      await ChatService.instance.sendMessage(
        pedidoId: widget.pedidoId,
        senderRole: widget.viewerRole,
        extra: {
          'type': 'file',
          'mediaPath': mediaPath,
          'fileName': fileName,
          'fileSize': bytes.lengthInBytes,
        },
      );

      await ChatService.instance.marcarVistasParaRole(
        pedidoId: widget.pedidoId,
        role: widget.viewerRole,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.chatFileSendError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickAndSendAudioFile() async {
    if (_uploading) return;

    try {
      final res = await FilePicker.platform.pickFiles(
        withData: true,
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['mp3', 'm4a', 'aac', 'wav', 'ogg'],
      );
      if (res == null || res.files.isEmpty) return;

      final f = res.files.first;
      final bytes = f.bytes;

      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.chatAudioReadError)),
        );
        return;
      }

      const maxBytes = 20 * 1024 * 1024; // 20MB
      if (bytes.lengthInBytes > maxBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.chatAudioTooLarge)),
        );
        return;
      }

      setState(() => _uploading = true);

      final fileName = _safeFileName(f.name.isNotEmpty ? f.name : 'audio.m4a');
      final ts = DateTime.now().millisecondsSinceEpoch;

      final lower = fileName.toLowerCase();
      final contentType = lower.endsWith('.mp3')
          ? 'audio/mpeg'
          : lower.endsWith('.wav')
              ? 'audio/wav'
              : lower.endsWith('.ogg')
                  ? 'audio/ogg'
                  : lower.endsWith('.aac')
                      ? 'audio/aac'
                      : 'audio/mp4';
      final mediaPath = await _uploadBytes(
        bytes: bytes,
        path: 'chats/${widget.pedidoId}/audio/${ts}_$fileName',
        contentType: contentType,
      );

      await ChatService.instance.sendMessage(
        pedidoId: widget.pedidoId,
        senderRole: widget.viewerRole,
        extra: {
          'type': 'audio',
          'mediaPath': mediaPath,
          'fileName': fileName,
          'fileSize': bytes.lengthInBytes,
        },
      );

      await ChatService.instance.marcarVistasParaRole(
        pedidoId: widget.pedidoId,
        role: widget.viewerRole,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.chatAudioSendError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<_WebRecordConfig> _resolveWebRecordConfig() async {
    const candidates = [
      _WebRecordConfig(
        encoder: AudioEncoder.opus,
        mimeType: 'audio/webm',
        extension: 'webm',
      ),
      _WebRecordConfig(
        encoder: AudioEncoder.aacLc,
        mimeType: 'audio/mp4',
        extension: 'm4a',
      ),
      _WebRecordConfig(
        encoder: AudioEncoder.wav,
        mimeType: 'audio/wav',
        extension: 'wav',
      ),
    ];

    for (final candidate in candidates) {
      final supported = await _recorder.isEncoderSupported(candidate.encoder);
      if (supported) return candidate;
    }

    return candidates.first;
  }

  String _buildAudioFileName(String extension) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return _safeFileName('audio_$ts.$extension');
  }

  Future<void> _startRecording() async {
    if (_recording || _uploading || _sending) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.chatAudioReadError)),
      );
      return;
    }

    try {
      if (kIsWeb) {
        final webConfig = await _resolveWebRecordConfig();
        _activeWebConfig = webConfig;
        await _recorder.start(
          RecordConfig(
            encoder: webConfig.encoder,
            numChannels: 1,
            bitRate: 96000,
            sampleRate: 44100,
          ),
          path: _buildAudioFileName(webConfig.extension),
        );
      } else {
        _recordBuffer = BytesBuilder(copy: false);
        _recordDone = Completer<void>();
        final stream = await _recorder.startStream(_recordConfig);
        _recordSub = stream.listen(
          (data) {
            final buffer = _recordBuffer;
            if (buffer == null) return;
            buffer.add(data);

            if (buffer.length >= _maxAudioBytes && _recording) {
              _stopRecording(tooLarge: true);
            }
          },
          onError: (error) {
            final done = _recordDone;
            if (done != null && !done.isCompleted) {
              done.completeError(error);
            }
          },
          onDone: () {
            final done = _recordDone;
            if (done != null && !done.isCompleted) {
              done.complete();
            }
          },
        );
      }

      if (mounted) {
        setState(() {
          _recording = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.chatAudioReadError)),
      );
    }
  }

  Future<void> _stopRecording({bool tooLarge = false}) async {
    if (!_recording) return;

    if (mounted) {
      setState(() {
        _recording = false;
      });
    }
    if (kIsWeb) {
      try {
        final url = await _recorder.stop();
        final webConfig = _activeWebConfig;
        _activeWebConfig = null;

        if (url == null || webConfig == null) return;
        final bytes = await loadBytesFromUrl(url);
        revokeObjectUrl(url);

        if (!mounted) return;
        if (bytes.length > _maxAudioBytes) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_l10n.chatAudioTooLarge)),
          );
          return;
        }

        await _sendAudioBytes(
          bytes,
          fileName: _buildAudioFileName(webConfig.extension),
          mimeType: webConfig.mimeType,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.chatAudioReadError)),
        );
      } finally {
        await _recordSub?.cancel();
        _recordSub = null;
      }
      return;
    }

    final buffer = _recordBuffer;
    _recordBuffer = null;
    final done = _recordDone;
    _recordDone = null;

    try {
      await _recorder.stop();
      if (done != null) {
        await done.future;
      }
    } catch (_) {
      // ignore
    } finally {
      await _recordSub?.cancel();
      _recordSub = null;
    }

    if (!mounted) return;
    if (tooLarge) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.chatAudioTooLarge)),
      );
      return;
    }

    if (buffer == null) return;
    final bytes = buffer.takeBytes();
    if (bytes.isEmpty) return;

    if (bytes.length > _maxAudioBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.chatAudioTooLarge)),
      );
      return;
    }

    await _sendAudioBytes(
      bytes,
      fileName: _buildAudioFileName('m4a'),
      mimeType: 'audio/m4a',
    );
  }

  Future<void> _sendAudioBytes(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
  }) async {
    if (_uploading) return;

    setState(() => _uploading = true);
    try {
      final mediaPath = await _uploadBytes(
        bytes: bytes,
        path: 'chats/${widget.pedidoId}/audio/$fileName',
        contentType: mimeType,
      );

      await ChatService.instance.sendMessage(
        pedidoId: widget.pedidoId,
        senderRole: widget.viewerRole,
        extra: {
          'type': 'audio',
          'mediaPath': mediaPath,
          'fileName': fileName,
          'fileSize': bytes.length,
          'mimeType': mimeType,
        },
      );

      await ChatService.instance.marcarVistasParaRole(
        pedidoId: widget.pedidoId,
        role: widget.viewerRole,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.chatAudioSendError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<Position?> _getCurrentPosition() async {
    final l10n = _l10n;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.locationServiceDisabled)),
      );
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.locationPermissionDenied)),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.locationPermissionDeniedForever)),
      );
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.locationFetchError(e.toString()))),
      );
      return null;
    }
  }

  Future<void> _sendLocation() async {
    if (_sending || _uploading) return;
    setState(() => _sending = true);

    try {
      final pos = await _getCurrentPosition();
      if (pos == null) return;

      final lat = pos.latitude;
      final lng = pos.longitude;
      final url = 'https://maps.google.com/?q=$lat,$lng';
      final label = _l10n.locationApproxLabel;

      await ChatService.instance.sendMessage(
        pedidoId: widget.pedidoId,
        senderRole: widget.viewerRole,
        text: '$label: $url',
        extra: {
          'type': 'location',
          'locationLat': lat,
          'locationLng': lng,
          'latitude': lat,
          'longitude': lng,
        },
      );

      await ChatService.instance.marcarVistasParaRole(
        pedidoId: widget.pedidoId,
        role: widget.viewerRole,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.chatSendError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _insertEmoji(String emoji) {
    final text = _messageCtrl.text;
    final selection = _messageCtrl.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final updated = text.replaceRange(start, end, emoji);
    _messageCtrl.value = _messageCtrl.value.copyWith(
      text: updated,
      selection: TextSelection.collapsed(offset: start + emoji.length),
      composing: TextRange.empty,
    );
    _messageFocus.requestFocus();
  }

  Future<void> _sendMediaUrlMessage({
    required String type,
    required String url,
  }) async {
    if (_sending || _uploading) return;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;

    setState(() => _sending = true);
    try {
      final bytes = await loadBytesFromUrl(trimmed);
      const maxBytes = 15 * 1024 * 1024;
      if (bytes.isEmpty || bytes.lengthInBytes > maxBytes) {
        throw StateError('Media externa vazia ou demasiado grande.');
      }
      final isGif = type == 'gif';
      final extension = isGif ? 'gif' : 'webp';
      final mediaPath = await _uploadBytes(
        bytes: bytes,
        path:
            'chats/${widget.pedidoId}/images/${type}_${DateTime.now().millisecondsSinceEpoch}.$extension',
        contentType: isGif ? 'image/gif' : 'image/webp',
      );
      await ChatService.instance.sendMessage(
        pedidoId: widget.pedidoId,
        senderRole: widget.viewerRole,
        extra: {
          'type': type,
          'mediaPath': mediaPath,
        },
      );

      await ChatService.instance.marcarVistasParaRole(
        pedidoId: widget.pedidoId,
        role: widget.viewerRole,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.chatSendError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendSticker(String url) async {
    await _sendMediaUrlMessage(type: 'sticker', url: url);
  }

  Future<void> _sendGif(String url) async {
    await _sendMediaUrlMessage(type: 'gif', url: url);
  }

  Future<void> _openMediaPicker() async {
    if (!mounted) return;
    _messageFocus.unfocus();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final height = MediaQuery.of(ctx).size.height * 0.48;
        return SizedBox(
          height: height,
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Emojis'),
                    Tab(text: 'Stickers'),
                    Tab(text: 'GIFs'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildEmojiGrid(ctx),
                      _buildStickerGrid(ctx),
                      _buildGifGrid(ctx),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmojiGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _emojiList.length,
      itemBuilder: (context, index) {
        final emoji = _emojiList[index];
        return InkWell(
          onTap: () => _insertEmoji(emoji),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStickerGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _stickerItems.length,
      itemBuilder: (context, index) {
        final item = _stickerItems[index];
        return InkWell(
          onTap: () {
            Navigator.of(context).pop();
            _sendSticker(item.url);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGifGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: _gifItems.length,
      itemBuilder: (context, index) {
        final item = _gifItems[index];
        return InkWell(
          onTap: () {
            Navigator.of(context).pop();
            _sendGif(item.url);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAttachMenu() async {
    if (!mounted) return;
    _messageFocus.unfocus();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachItem(
                    icon: Icons.insert_drive_file,
                    color: Colors.indigo,
                    label: _l10n.chatAttachFile,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _pickAndSendFile();
                    },
                  ),
                  _buildAttachItem(
                    icon: Icons.camera_alt,
                    color: Colors.pink,
                    label: _l10n.chatAttachCamera,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _pickAndSendImage(source: ImageSource.camera);
                    },
                  ),
                  _buildAttachItem(
                    icon: Icons.image,
                    color: Colors.purple,
                    label: _l10n.chatAttachGallery,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _pickAndSendImage(source: ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachItem(
                    icon: Icons.headset,
                    color: Colors.orange,
                    label: _l10n.chatAttachAudio,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _pickAndSendAudioFile();
                    },
                  ),
                  _buildAttachItem(
                    icon: Icons.location_on,
                    color: Colors.green,
                    label: _l10n.locationUseCurrent,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _sendLocation();
                    },
                  ),
                  _buildAttachItem(
                    icon: Icons.person,
                    color: Colors.blue,
                    label: 'Contacto', // localized in real app
                    onTap: () {
                      Navigator.of(ctx).pop();
                      // Contact picker pending implementation.
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _listenForIncomingCalls() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _incomingCallSub?.cancel();
    _incomingCallSub = CallService.instance
        .streamIncomingCalls(pedidoId: widget.pedidoId, calleeId: uid)
        .listen(
      (snapshot) {
        if (!mounted || _callScreenOpen) return;
        if (snapshot.docs.isEmpty) return;

        final doc = snapshot.docs.first;
        if (_activeIncomingCallId == doc.id) return;

        final data = doc.data();
        final videoEnabled = data['videoEnabled'] == true;

        _activeIncomingCallId = doc.id;
        _openCallScreen(
          callId: doc.id,
          videoEnabled: videoEnabled,
          isCaller: false,
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        if (error is FirebaseException && error.code == 'permission-denied') {
          return;
        }
        if (kDebugMode) {
          debugPrint('[ChatThread] incoming call stream error: $error');
        }
      },
    );
  }

  Future<void> _openCallScreen({
    required String callId,
    required bool videoEnabled,
    required bool isCaller,
  }) async {
    if (_callScreenOpen || !mounted) return;
    _callScreenOpen = true;

    final name = (_lastOtherName ?? widget.otherUserName ?? '').trim();
    final safeName = name.isNotEmpty
        ? name
        : (_otherRole == 'prestador'
            ? _l10n.roleLabelProvider
            : _l10n.roleLabelCustomer);

    final photo = _lastOtherPhoto ?? widget.otherUserPhotoUrl;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callId: callId,
          pedidoId: widget.pedidoId,
          isCaller: isCaller,
          videoEnabled: videoEnabled,
          otherUserId: widget.otherUserId,
          otherUserName: safeName,
          otherUserPhotoUrl: photo,
        ),
      ),
    );

    _callScreenOpen = false;
    _activeIncomingCallId = null;
  }

  void _openProfile() {
    final name = (_lastOtherName ?? widget.otherUserName ?? '').trim();
    final photo = _lastOtherPhoto ?? widget.otherUserPhotoUrl;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          userId: widget.otherUserId,
          role: _otherRole,
          initialName: name.isNotEmpty ? name : null,
          initialPhotoUrl: photo,
        ),
      ),
    );
  }

  Future<void> _startCall({required bool videoEnabled}) async {
    final otherId = widget.otherUserId.trim();
    if (otherId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.chatCallMissingParticipant)),
      );
      return;
    }

    try {
      final callId = await CallService.instance.createCall(
        pedidoId: widget.pedidoId,
        calleeId: otherId,
        callerRole: widget.viewerRole,
        calleeRole: _otherRole,
        videoEnabled: videoEnabled,
      );

      await ChatService.instance.sendMessage(
        pedidoId: widget.pedidoId,
        senderRole: widget.viewerRole,
        text: videoEnabled
            ? _l10n.chatCallStartedVideo
            : _l10n.chatCallStartedVoice,
        extra: {
          'type': 'call',
          'callType': videoEnabled ? 'video' : 'voice',
          'callId': callId,
        },
      );
      if (!mounted) return;
      await _openCallScreen(
        callId: callId,
        videoEnabled: videoEnabled,
        isCaller: true,
      );
    } catch (_) {
      // Call is already open; ignore chat send errors.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.chatCallStartError)),
      );
    }
  }

  Future<void> _reportConversation() {
    return ReportContentSheet.show(
      context,
      title: 'Denunciar conversa',
      targetType: ReportTargetType.chatMessage,
      targetId: widget.pedidoId,
      targetOwnerId: widget.otherUserId,
      sourceContext: 'chat_thread',
      chatId: widget.pedidoId,
      onSubmit: widget.onReportSubmit,
    );
  }

  Future<void> _reportMessage(ChatMessage msg, {required bool isMine}) {
    return ReportContentSheet.show(
      context,
      title: 'Denunciar mensagem',
      targetType: ReportTargetType.chatMessage,
      targetId: msg.id,
      targetOwnerId: isMine ? _auth.currentUser?.uid : widget.otherUserId,
      sourceContext: 'chat_message',
      chatId: widget.pedidoId,
      messageId: msg.id,
      onSubmit: widget.onReportSubmit,
    );
  }

  Future<void> _blockOtherUser() {
    return BlockUserDialog.show(
      context,
      blockedUid: widget.otherUserId,
      userLabel: _lastOtherName ?? widget.otherUserName,
      onConfirm: widget.onBlockUser,
    );
  }

  Widget _buildDayHeader(String label) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x3,
            vertical: AppSpacing.x2,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: theme.colorScheme.outline),
            boxShadow: AppShadows.level1,
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageActions(ChatMessage msg) {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final isStarred = msg.isStarredBy(uid);
    final isMine = msg.senderRole == widget.viewerRole;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply),
                title: Text(_l10n.chatReplyAction),
                onTap: () {
                  Navigator.of(ctx).pop();
                  // Reply banner/state pending implementation.
                  _messageFocus.requestFocus();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(_l10n.chatCopyAction),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  if (msg.text.isNotEmpty) {
                    await Clipboard.setData(ClipboardData(text: msg.text));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mensagem copiada')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: Icon(isStarred ? Icons.star : Icons.star_border),
                title: Text(
                  isStarred ? _l10n.chatUnstarAction : _l10n.chatStarAction,
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ChatService.instance.setMessageStarred(
                    pedidoId: widget.pedidoId,
                    messageId: msg.id,
                    starred: !isStarred,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Denunciar mensagem'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _reportMessage(msg, isMine: isMine);
                },
              ),
              if (isMine)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    _l10n.chatDeleteAction,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    // Confirm delete
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Apagar mensagem?'),
                        content: const Text('Esta ação não pode ser desfeita.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ChatService.instance.deleteMessage(
                                pedidoId: widget.pedidoId,
                                messageId: msg.id,
                              );
                            },
                            child: const Text(
                              'Apagar',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBubble({required ChatMessage msg, required bool isMine}) {
    final theme = Theme.of(context);
    final createdAt = msg.createdAt;
    final time = _formatTime(createdAt);
    final uid = _auth.currentUser?.uid ?? '';
    final isStarred = uid.isNotEmpty && msg.isStarredBy(uid);

    final bubbleColor = isMine
        ? theme.colorScheme.primary.withValues(alpha: 0.12)
        : theme.colorScheme.surface;
    final bubbleBorder = isMine
        ? theme.colorScheme.primary.withValues(alpha: 0.18)
        : theme.colorScheme.outline;

    // Status Icon Logic
    IconData? statusIcon;
    Color? statusColor;
    if (isMine) {
      final delivered = widget.viewerRole == 'cliente'
          ? msg.deliveredToPrestador
          : msg.deliveredToCliente;

      final seen = widget.viewerRole == 'cliente'
          ? msg.seenByPrestador
          : msg.seenByCliente;

      if (seen) {
        statusIcon = Icons.done_all;
        statusColor = Colors.blue;
      } else if (delivered) {
        statusIcon = Icons.done_all;
        statusColor = Colors.grey;
      } else {
        statusIcon = Icons.check;
        statusColor = Colors.grey;
      }
    }

    Widget content;
    // ... Content building logic remains mostly same but we optimize layout ...
    final mediaReference = msg.mediaReference;
    if (msg.isImage && mediaReference != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => MediaViewerScreen.open(
              context,
              urls: [mediaReference],
              title: 'Image',
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: PrivateStorageImage(
                reference: mediaReference,
                error: const Icon(Icons.error),
              ),
            ),
          ),
          if (msg.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(msg.text, style: const TextStyle(fontSize: 16)),
            ),
        ],
      );
    } else if (msg.type == 'call') {
      final isVideo = msg.callType == 'video';
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVideo ? Icons.videocam : Icons.call,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                msg.text,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (msg.callDuration != null) Text(msg.callDuration!),
            ],
          ),
        ],
      );
    } else if (msg.isLocation && msg.mapsUri != null) {
      content = _LocationMessageContent(
        text: msg.text,
        uri: msg.mapsUri!,
        isMine: isMine,
      );
    } else {
      // Default text or other types
      content = Text(
        msg.text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontSize: 16,
        ),
      );
    }

    // Layout for bubble with time/status at bottom right
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageActions(msg),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x3,
            vertical: AppSpacing.x2,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadius.lg),
              topRight: const Radius.circular(AppRadius.lg),
              bottomLeft: Radius.circular(isMine ? AppRadius.lg : AppRadius.xs),
              bottomRight:
                  Radius.circular(isMine ? AppRadius.xs : AppRadius.lg),
            ),
            border: Border.all(color: bubbleBorder),
            boxShadow: AppShadows.level1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min, // Shrink to fit content
            children: [
              // Content Row (to allow left alignment of text)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4, right: 4),
                      child: content,
                    ),
                  ),
                ],
              ),
              // Metadata Row (Time + Star + Status)
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isStarred) ...[
                    const Icon(Icons.star, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    time,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (statusIcon != null) ...[
                    const SizedBox(width: 4),
                    Icon(statusIcon, size: 14, color: statusColor),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    final theme = Theme.of(context);
    final inputDisabled = _sending || _uploading || _recording;

    // Check if we show Mic or Send button
    final showSend = _messageCtrl.text.trim().isNotEmpty || _uploading;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x3,
          AppSpacing.x2,
          AppSpacing.x3,
          AppSpacing.x2,
        ),
        color: theme.scaffoldBackgroundColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: theme.colorScheme.outline),
                  boxShadow: AppShadows.level1,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.emoji_emotions_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: inputDisabled ? null : _openMediaPicker,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageCtrl,
                        focusNode: _messageFocus,
                        minLines: 1,
                        maxLines: 6,
                        enabled: !inputDisabled,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: _l10n.chatInputHint,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(10),
                        ),
                        onChanged: (val) {
                          setState(() {}); // Trigger rebuild to toggle Mic/Send
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.attach_file,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: inputDisabled ? null : _openAttachMenu,
                    ),
                    if (_messageCtrl.text.isEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: inputDisabled
                            ? null
                            : () =>
                                _pickAndSendImage(source: ImageSource.camera),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            GestureDetector(
              onLongPress: (_recording || showSend) ? null : _startRecording,
              onLongPressUp: _recording
                  ? _stopRecording
                  : null, // Simple visual cue, logic needs more robust touch handling
              child: FloatingActionButton(
                onPressed: () {
                  if (showSend) {
                    _sendText();
                  } else {
                    // Tap on mic: could be hint "Hold to record" or toggle mode
                    // For now, simpler implementation: Tap to start/stop if we wanted, but Long Press is better.
                    // But standard FAB doesn't support Long Press easily without wrapper.
                    // We'll use the button for Send, and if Mic, we handle Tap as "Start/Stop" or wrapper.
                    if (_recording) {
                      _stopRecording();
                    } else {
                      // Implementing 'tap to record' fallback if long press not clear
                      _startRecording();
                    }
                  }
                },
                backgroundColor: theme.colorScheme.primary,
                mini: false,
                elevation: 2,
                child: Icon(
                  showSend ? Icons.send : (_recording ? Icons.stop : Icons.mic),
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // evita crash em web refresh
    if (_auth.currentUser == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_l10n.chatNoSession),
          ),
        ),
      );
    }

    final pedidoTitle = (widget.pedidoTitulo ?? '').trim();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _otherUserStream,
      builder: (context, otherSnap) {
        final otherData = otherSnap.data?.data();
        final otherName = _resolveOtherName(otherData);
        final otherPhoto = _resolveOtherPhoto(otherData);
        final presence = _formatPresence(otherData);

        _lastOtherName = otherName;
        _lastOtherPhoto = otherPhoto;

        final fallbackTitle = _l10n.chatTitleFallback;
        final title = pedidoTitle.isNotEmpty ? pedidoTitle : fallbackTitle;
        final sub = presence.isNotEmpty ? '$title • $presence' : title;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 0,
            title: Row(
              children: [
                GestureDetector(
                  onTap: _openProfile,
                  child: AppAvatar(
                    imageUrl: otherPhoto,
                    label: otherName,
                    isOnline: otherData?['isOnline'] == true,
                    size: AppAvatarSize.sm,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: _l10n.chatSearchAction,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatSearchScreen(pedidoId: widget.pedidoId),
                    ),
                  );
                },
                icon: const Icon(Icons.search),
              ),
              if (AppConfig.callsEnabled) ...[
                IconButton(
                  tooltip: _l10n.chatVideoCallAction,
                  onPressed: () => _startCall(videoEnabled: true),
                  icon: const Icon(Icons.videocam_outlined),
                ),
                IconButton(
                  tooltip: _l10n.chatVoiceCallAction,
                  onPressed: () => _startCall(videoEnabled: false),
                  icon: const Icon(Icons.call_outlined),
                ),
              ],
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'perfil') {
                    _openProfile();
                  } else if (v == 'media') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatMediaScreen(pedidoId: widget.pedidoId),
                      ),
                    );
                  } else if (v == 'favoritos') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatFavoritesScreen(pedidoId: widget.pedidoId),
                      ),
                    );
                  } else if (v == 'denunciar_conversa') {
                    _reportConversation();
                  } else if (v == 'bloquear_utilizador') {
                    _blockOtherUser();
                  } else if (v == 'marcar_lidas') {
                    ChatService.instance.marcarVistasParaRole(
                      pedidoId: widget.pedidoId,
                      role: widget.viewerRole,
                    );
                  } else if (v == 'anexar') {
                    _openAttachMenu();
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'perfil',
                    child: Text(
                      _otherRole == 'prestador'
                          ? _l10n.chatViewProviderProfileAction
                          : _l10n.chatViewCustomerProfileAction,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'media',
                    child: Text(_l10n.chatMediaAction),
                  ),
                  PopupMenuItem(
                    value: 'favoritos',
                    child: Text(_l10n.chatFavoritesAction),
                  ),
                  const PopupMenuItem(
                    value: 'denunciar_conversa',
                    child: Text('Denunciar conversa'),
                  ),
                  const PopupMenuItem(
                    value: 'bloquear_utilizador',
                    child: Text('Bloquear utilizador'),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'marcar_lidas',
                    child: Text(_l10n.chatMarkReadAction),
                  ),
                  PopupMenuItem(
                    value: 'anexar',
                    child: Text(_l10n.chatAttachTooltip),
                  ),
                ],
              ),
            ],
          ),
          body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: ChatService.instance
                        .streamMessages(widget.pedidoId, limit: 500),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Center(
                          child:
                              Text(_l10n.chatLoadError(snap.error.toString())),
                        );
                      }
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snap.data ?? <ChatMessage>[];

                      // marca vistas se houver msgs do outro lado ainda não vistas
                      final hasUnseenIncoming = messages.any((m) {
                        final isMine = m.senderRole == widget.viewerRole;
                        if (isMine) return false;

                        return widget.viewerRole == 'cliente'
                            ? !m.seenByCliente
                            : !m.seenByPrestador;
                      });

                      if (hasUnseenIncoming) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ChatService.instance.marcarVistasParaRole(
                            pedidoId: widget.pedidoId,
                            role: widget.viewerRole,
                          );
                        });
                      }

                      if (messages.isEmpty) {
                        return Center(child: Text(_l10n.chatEmptyMessage));
                      }

                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final m = messages[index];
                          final createdAt = m.createdAt;
                          final isMine = m.senderRole == widget.viewerRole;

                          final next = (index + 1 < messages.length)
                              ? messages[index + 1]
                              : null;
                          final nextDate = next?.createdAt ?? createdAt;
                          final showHeader =
                              next == null || !_isSameDay(createdAt, nextDate);

                          return Column(
                            children: [
                              if (showHeader)
                                _buildDayHeader(_formatDayHeader(createdAt)),
                              _buildBubble(msg: m, isMine: isMine),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildInput(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LocationMessageContent extends StatelessWidget {
  const _LocationMessageContent({
    required this.text,
    required this.uri,
    required this.isMine,
  });

  final String text;
  final Uri uri;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final actionColor = isMine ? colorScheme.primary : colorScheme.secondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _openMaps(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x1,
            vertical: AppSpacing.x1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_rounded,
                color: actionColor,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.x2),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Abrir localizacao',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: actionColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (text.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMaps(BuildContext context) async {
    final ok = await launchUrl(
      uri,
      mode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_blank' : null,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao conseguimos abrir a localizacao.')),
      );
    }
  }
}
