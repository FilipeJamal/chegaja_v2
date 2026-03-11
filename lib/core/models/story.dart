import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String prestadorId;
  final String prestadorNome;
  final String? prestadorFoto;
  final String mediaUrl; // URL da imagem/vídeo
  final String? descricao;
  final String? countryCode;
  final List<String> categoryIds;
  final DateTime createdAt;
  final DateTime expiresAt;

  Story({
    required this.id,
    required this.prestadorId,
    required this.prestadorNome,
    this.prestadorFoto,
    required this.mediaUrl,
    this.descricao,
    this.countryCode,
    this.categoryIds = const [],
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() {
    return {
      'prestadorId': prestadorId,
      'prestadorNome': prestadorNome,
      'prestadorFoto': prestadorFoto,
      'mediaUrl': mediaUrl,
      'descricao': descricao,
      if (countryCode != null) 'countryCode': countryCode,
      if (categoryIds.isNotEmpty) 'categoryIds': categoryIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  factory Story.fromMap(String id, Map<String, dynamic> map) {
    return Story(
      id: id,
      prestadorId: map['prestadorId'] ?? '',
      prestadorNome: map['prestadorNome'] ?? 'Prestador',
      prestadorFoto: map['prestadorFoto'],
      mediaUrl: map['mediaUrl'] ?? '',
      descricao: map['descricao'],
      countryCode: map['countryCode'],
      categoryIds: List<String>.from(map['categoryIds'] ?? const []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      expiresAt: (map['expiresAt'] as Timestamp).toDate(),
    );
  }
}
