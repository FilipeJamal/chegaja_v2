// lib/core/models/servico.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Serviço (documento da coleção `servicos`)
///
/// Exemplo de documento no Firestore:
/// {
///   "name": "Canalizador",
///   "mode": "IMEDIATO", // ou "AGENDADO", "POR_PROPOSTA"
///   "keywords": ["água", "cano", "fuga"],
///   "iconKey": "canalizador",
///   "isActive": true,
///   "createdAt": FieldValue.serverTimestamp()
/// }
class Servico {
  /// ID do documento no Firestore
  final String id;

  /// Nome visível da categoria/serviço (ex.: "Canalizador", "Confeitaria")
  final String name;

  /// Modo: "IMEDIATO", "AGENDADO" ou "POR_PROPOSTA"
  final String mode;

  /// Palavras-chave usadas para pesquisa
  final List<String> keywords;

  /// Chave de ícone (para futura UI), pode ser null
  final String? iconKey;

  /// Se o serviço está ativo (mostrado na app)
  final bool isActive;

  /// Data de criação no Firestore
  final DateTime? createdAt;

  const Servico({
    required this.id,
    required this.name,
    required this.mode,
    required this.keywords,
    required this.isActive,
    this.iconKey,
    this.createdAt,
  });

  /// Construtor a partir de um DocumentSnapshot do Firestore
  factory Servico.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Servico.fromMap(data, doc.id);
  }

  /// Construtor a partir de um Map (por ex. data() do Firestore)
  factory Servico.fromMap(Map<String, dynamic> map, String id) {
    final ts = map['createdAt'];
    DateTime? created;
    if (ts is Timestamp) {
      created = ts.toDate();
    }

    final rawKeywords = map['keywords'];
    List<String> kws = const [];
    if (rawKeywords is List) {
      kws = rawKeywords.map((e) => e.toString()).toList();
    }

    return Servico(
      id: id,
      name: map['name']?.toString() ?? '',
      mode: map['mode']?.toString() ?? 'IMEDIATO',
      keywords: kws,
      iconKey: map['iconKey']?.toString(),
      isActive: map['isActive'] == true,
      createdAt: created,
    );
  }

  /// Converte para Map para guardar/atualizar no Firestore
  Map<String, dynamic> toMap({bool includeCreatedAt = false}) {
    return <String, dynamic>{
      'name': name,
      'mode': mode,
      'keywords': keywords,
      'iconKey': iconKey,
      'isActive': isActive,
      if (includeCreatedAt && createdAt != null)
        'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  /// Cria uma cópia com algumas propriedades alteradas
  Servico copyWith({
    String? id,
    String? name,
    String? mode,
    List<String>? keywords,
    String? iconKey,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Servico(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      keywords: keywords ?? this.keywords,
      iconKey: iconKey ?? this.iconKey,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
