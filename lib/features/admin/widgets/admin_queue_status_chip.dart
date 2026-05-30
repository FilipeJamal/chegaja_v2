import 'package:flutter/material.dart';

class AdminQueueStatusChip extends StatelessWidget {
  const AdminQueueStatusChip({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalized = value.trim().toLowerCase();
    final display = adminQueueDisplayValue(normalized);
    final tone = _toneFor(normalized);

    final Color background;
    final Color foreground;
    switch (tone) {
      case _QueueChipTone.danger:
        background = colorScheme.errorContainer;
        foreground = colorScheme.onErrorContainer;
        break;
      case _QueueChipTone.warning:
        background = colorScheme.tertiaryContainer;
        foreground = colorScheme.onTertiaryContainer;
        break;
      case _QueueChipTone.success:
        background = colorScheme.primaryContainer;
        foreground = colorScheme.onPrimaryContainer;
        break;
      case _QueueChipTone.neutral:
        background = colorScheme.surfaceContainerHighest;
        foreground = colorScheme.onSurfaceVariant;
        break;
    }

    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: background,
      label: Text(
        '$label: $display',
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum _QueueChipTone { danger, warning, success, neutral }

_QueueChipTone _toneFor(String value) {
  if (const {
    'critical',
    'high',
    'fraud',
    'sexual_content',
    'drugs',
    'violence',
    'child_safety',
  }.contains(value)) {
    return _QueueChipTone.danger;
  }
  if (const {
    'pending',
    'pending_review',
    'in_progress',
    'escalated',
    'medium',
  }.contains(value)) {
    return _QueueChipTone.warning;
  }
  if (const {
    'reviewed',
    'resolved',
    'closed',
    'approved',
    'low',
  }.contains(value)) {
    return _QueueChipTone.success;
  }
  return _QueueChipTone.neutral;
}

String adminQueueDisplayValue(String value) {
  if (value.isEmpty) return '-';
  return _labels[value] ?? value;
}

const Map<String, String> _labels = {
  'all': 'Todos',
  'pending': 'Pendente',
  'pending_review': 'Pendente',
  'reviewed': 'Analisado',
  'dismissed': 'Descartado',
  'escalated': 'Escalado',
  'open': 'Aberto',
  'in_progress': 'Em andamento',
  'resolved': 'Resolvido',
  'closed': 'Fechado',
  'approved': 'Aprovado',
  'rejected': 'Rejeitado',
  'active': 'Ativo',
  'deleted': 'Apagado',
  'missing': 'Inexistente',
  'low': 'Baixa',
  'medium': 'Media',
  'high': 'Alta',
  'critical': 'Critica',
  'provider_profile': 'Perfil prestador',
  'client_profile': 'Perfil cliente',
  'portfolio_media': 'Imagem portfolio',
  'story': 'Historia',
  'chat_message': 'Mensagem chat',
  'review': 'Avaliacao',
  'service_category': 'Categoria servico',
  'service_request': 'Pedido servico',
  'user': 'Utilizador',
  'other': 'Outro',
  'illegal_service': 'Servico ilegal',
  'sexual_content': 'Conteudo sexual',
  'drugs': 'Drogas',
  'fraud': 'Fraude/golpe',
  'harassment': 'Assedio',
  'hate_speech': 'Discurso de odio',
  'violence': 'Violencia',
  'child_safety': 'Seguranca infantil',
  'personal_data': 'Dados pessoais',
  'spam': 'Spam',
  'scam': 'Golpe',
  'impersonation': 'Finge ser outra pessoa',
  'unsafe_service': 'Servico inseguro',
  'copyright_or_stolen_media': 'Media sem autorizacao',
  'off_platform_circumvention': 'Contorno da plataforma',
};
