enum ServiceIntent {
  now,
  scheduled,
  quote,
}

extension ServiceIntentDisplay on ServiceIntent {
  String get label {
    switch (this) {
      case ServiceIntent.now:
        return 'Preciso agora';
      case ServiceIntent.scheduled:
        return 'Quero agendar';
      case ServiceIntent.quote:
        return 'Quero receber orcamento';
    }
  }

  String get legacyMode {
    switch (this) {
      case ServiceIntent.now:
        return 'IMEDIATO';
      case ServiceIntent.scheduled:
        return 'AGENDADO';
      case ServiceIntent.quote:
        return 'POR_PROPOSTA';
    }
  }
}

class ServiceIntentX {
  const ServiceIntentX._();

  static ServiceIntent fromLegacyMode(String? rawMode) {
    final mode = (rawMode ?? '').toUpperCase().trim();
    if (mode == 'AGENDADO') return ServiceIntent.scheduled;
    if (mode == 'POR_PROPOSTA' ||
        mode == 'POR_ORCAMENTO' ||
        mode == 'ORCAMENTO') {
      return ServiceIntent.quote;
    }
    return ServiceIntent.now;
  }
}
