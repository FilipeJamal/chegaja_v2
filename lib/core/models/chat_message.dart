import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de mensagem do chat.
///
/// Compatível com versões antigas que guardavam o texto em `text`/`texto`/`message`/`conteudo`.
///
/// Para suportar anexos (imagem/ficheiro/áudio), este modelo lê também:
/// - `type` (text|image|file|audio|sticker|gif)
/// - `mediaUrl` (URL do Storage)
/// - `fileName`, `fileSize`, `mimeType`, `durationMs`
class ChatMessage {
  final String id;
  final String pedidoId;
  final String text;

  /// Tipo: `text`, `image`, `file`, `audio`...
  final String type;

  /// URL do media no Firebase Storage (quando `type` != text).
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final int? durationMs;
  final String? callType;
  final String? callDuration;
  
  // Novos campos (E3 - Ultimate Chat)
  final Map<String, List<String>> reactions; // {'❤️': ['uid1', 'uid2']}
  final String? replyToId;
  final String? replyToText;
  final bool isDeleted;
  final bool isEdited;
  final DateTime? editedAt;
  final double? locationLat;
  final double? locationLng;

  final String senderRole;
  final String senderId;
  final DateTime createdAt;
  final bool seenByCliente;
  final bool seenByPrestador;
  final bool deliveredToCliente;
  final bool deliveredToPrestador;
  final List<String> starredBy;

  const ChatMessage({
    required this.id,
    required this.pedidoId,
    required this.text,
    required this.senderRole,
    required this.senderId,
    required this.createdAt,
    required this.seenByCliente,
    required this.seenByPrestador,
    required this.deliveredToCliente,
    required this.deliveredToPrestador,
    this.starredBy = const <String>[],
    this.type = 'text',
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.durationMs,
    this.callType,
    this.callDuration,
    this.reactions = const {},
    this.replyToId,
    this.replyToText,
    this.isDeleted = false,
    this.isEdited = false,
    this.editedAt,
    this.locationLat,
    this.locationLng,
  });

  bool get hasMedia => (mediaUrl ?? '').trim().isNotEmpty;
  bool get isImage =>
      (type == 'image' || type == 'sticker' || type == 'gif') && hasMedia;
  bool get isSticker => type == 'sticker' && hasMedia;
  bool get isGif => type == 'gif' && hasMedia;
  bool get isFile => type == 'file' && hasMedia;
  bool get isAudio => type == 'audio' && hasMedia;
  bool get isLocation => locationLat != null && locationLng != null;
  bool isStarredBy(String uid) => starredBy.contains(uid);

  factory ChatMessage.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    // texto pode vir de vários campos por compatibilidade
    final rawText = (data['text'] ?? data['texto'] ?? data['message'] ?? data['conteudo'] ?? '')
        .toString();

    // tipo/metadata (novos)
    final type = (data['type'] as String?)?.trim().isNotEmpty == true
        ? (data['type'] as String).trim()
        : 'text';

    final mediaUrl = (data['mediaUrl'] ?? data['fileUrl'] ?? data['url'])?.toString();
    final fileName = (data['fileName'] ?? data['nomeArquivo'] ?? data['filename'])?.toString();

    final fileSizeRaw = data['fileSize'];
    final fileSize = (fileSizeRaw is num) ? fileSizeRaw.toInt() : null;

    final mimeType = (data['mimeType'] ?? data['contentType'])?.toString();

    final durationRaw = data['durationMs'];
    final durationMs = (durationRaw is num) ? durationRaw.toInt() : null;

    final callType = data['callType']?.toString();
    final callDuration = data['callDuration']?.toString();

    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final starredRaw = (data['starredBy'] as List?) ?? const <dynamic>[];
    final starredBy = starredRaw.map((e) => e.toString()).toList();

    // Parse Reactions
    final Map<String, List<String>> reactionsParsed = {};
    if (data['reactions'] is Map) {
      (data['reactions'] as Map).forEach((k, v) {
        if (v is List) {
          reactionsParsed[k.toString()] = v.map((e) => e.toString()).toList();
        }
      });
    }

    return ChatMessage(
      id: doc.id,
      pedidoId: (data['pedidoId'] ?? '').toString(),
      text: rawText,
      type: type,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      durationMs: durationMs,
      callType: callType,
      callDuration: callDuration,
      reactions: reactionsParsed,
      replyToId: data['replyToId']?.toString(),
      replyToText: data['replyToText']?.toString(),
      isDeleted: data['isDeleted'] == true,
      isEdited: data['isEdited'] == true,
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      locationLat: (data['locationLat'] as num?)?.toDouble(),
      locationLng: (data['locationLng'] as num?)?.toDouble(),
      senderRole: (data['senderRole'] ?? '').toString(),
      senderId: (data['senderId'] ?? '').toString(),
      createdAt: createdAt,
      seenByCliente: data['seenByCliente'] == true,
      seenByPrestador: data['seenByPrestador'] == true,
      deliveredToCliente: data['deliveredToCliente'] == true,
      deliveredToPrestador: data['deliveredToPrestador'] == true,
      starredBy: starredBy,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pedidoId': pedidoId,
      'text': text,
      'type': type,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileSize != null) 'fileSize': fileSize,
      if (mimeType != null) 'mimeType': mimeType,
      if (durationMs != null) 'durationMs': durationMs,
      if (callType != null) 'callType': callType,
      if (callDuration != null) 'callDuration': callDuration,
      if (locationLat != null) 'locationLat': locationLat,
      if (locationLng != null) 'locationLng': locationLng,
      
      'reactions': reactions,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToText != null) 'replyToText': replyToText,
      'isDeleted': isDeleted,
      'isEdited': isEdited,
      if (editedAt != null) 'editedAt': Timestamp.fromDate(editedAt!),

      'senderRole': senderRole,
      'senderId': senderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'seenByCliente': seenByCliente,
      'seenByPrestador': seenByPrestador,
      'deliveredToCliente': deliveredToCliente,
      'deliveredToPrestador': deliveredToPrestador,
      if (starredBy.isNotEmpty) 'starredBy': starredBy,
    };
  }
}
