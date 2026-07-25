import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/feature_flags/feature_flag.dart';
import '../../../core/feature_flags/feature_flag_service.dart';
import '../../../core/repositories/prestador_repo.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_content_shell.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../auth/phone_verification_screen.dart';

typedef ProviderUidResolver = Future<String?> Function();
typedef ProviderAgendaAccessGate = Future<bool> Function(
  BuildContext context, {
  required String action,
});

const String prestadorAgendaPhoneGateAction =
    'consultar e gerir a tua agenda privada';

/// Standalone route kept for existing settings links.
///
/// Pass [embedded] when this screen is used as a shell destination so it does
/// not create a nested Scaffold or AppBar.
class PrestadorAgendaScreen extends StatefulWidget {
  const PrestadorAgendaScreen({
    super.key,
    this.embedded = false,
    this.repository,
    this.uidResolver,
    this.experienceV2Override,
    this.accessPreauthorized = false,
    this.accessGate,
  });

  final bool embedded;
  final PrestadorAgendaRepository? repository;
  final ProviderUidResolver? uidResolver;
  final bool? experienceV2Override;

  /// Só deve ser `true` quando o chamador acabou de concluir o mesmo gate.
  final bool accessPreauthorized;

  /// Seam estreito para testar o guard sem iniciar Firebase/Navigator.
  final ProviderAgendaAccessGate? accessGate;

  @override
  State<PrestadorAgendaScreen> createState() => _PrestadorAgendaScreenState();
}

class _PrestadorAgendaScreenState extends State<PrestadorAgendaScreen> {
  bool _accessGranted = false;
  bool _accessAttempted = false;
  bool _requestInFlight = false;

  @override
  void initState() {
    super.initState();
    _accessGranted = widget.accessPreauthorized;
    _accessAttempted = widget.accessPreauthorized;
    if (!widget.accessPreauthorized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _requestAccess();
      });
    }
  }

  Future<void> _requestAccess() async {
    if (_accessGranted || _requestInFlight) return;
    setState(() => _requestInFlight = true);

    var allowed = false;
    try {
      allowed = await (widget.accessGate ?? VerifiedPhoneGate.ensure)(
        context,
        action: prestadorAgendaPhoneGateAction,
      );
    } catch (error, stackTrace) {
      debugPrint('[PrestadorAgenda] verificação de acesso falhou: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    if (!mounted) return;

    setState(() {
      _accessGranted = allowed;
      _accessAttempted = true;
      _requestInFlight = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final experienceV2 = widget.experienceV2Override ??
        FeatureFlagService.instance.isEnabled(
          FeatureFlag.u1NavigationV2,
        );

    if (!_accessGranted) {
      final guardedContent = !_accessAttempted || _requestInFlight
          ? const AppLoadingView(
              key: Key('prestador_agenda_access_checking'),
              label: 'A confirmar acesso à agenda...',
            )
          : AppEmptyView(
              key: const Key('prestador_agenda_access_denied'),
              title: 'Confirma o telefone',
              message:
                  'A agenda contém informação privada. Confirma o telefone para continuar.',
              icon: Icons.phone_android_outlined,
              actionLabel: 'Confirmar telefone',
              onAction: _requestAccess,
            );

      if (widget.embedded) {
        return guardedContent;
      }
      return Scaffold(
        key: const Key('prestador_agenda_access_guard'),
        appBar: AppBar(title: const Text('Minha Agenda')),
        body: guardedContent,
      );
    }

    return PrestadorAgendaContent(
      embedded: widget.embedded,
      experienceV2: experienceV2,
      repository: widget.repository,
      uidResolver: widget.uidResolver,
    );
  }
}

class PrestadorAgendaContent extends StatefulWidget {
  const PrestadorAgendaContent({
    super.key,
    this.embedded = true,
    this.repository,
    this.uidResolver,
    this.experienceV2 = true,
  });

  final bool embedded;
  final bool experienceV2;
  final PrestadorAgendaRepository? repository;
  final ProviderUidResolver? uidResolver;

  @override
  State<PrestadorAgendaContent> createState() => _PrestadorAgendaContentState();
}

class _PrestadorAgendaContentState extends State<PrestadorAgendaContent> {
  static const List<String> _daysOfWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  late final PrestadorAgendaRepository _repository;
  late final ProviderUidResolver _uidResolver;

  final Map<String, List<String>> _workingHours = {};
  String? _uid;
  Object? _loadError;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PrestadorRepo();
    _uidResolver = widget.uidResolver ?? _resolveCurrentProviderUid;
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final uid = (await _uidResolver())?.trim();
      if (uid == null || uid.isEmpty) {
        throw StateError('Provider session is unavailable.');
      }
      final agenda = await _repository.getAgenda(uid);
      if (!mounted) return;

      setState(() {
        _uid = uid;
        _workingHours
          ..clear()
          ..addAll(
            agenda.workingHours.map(
              (day, hours) => MapEntry(day, List<String>.from(hours)),
            ),
          );
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await _repository.updateAgenda(
        uid,
        workingHours: _workingHours.map(
          (day, hours) => MapEntry(day, List<String>.from(hours)),
        ),
      );
      if (!mounted) return;
      _showSnackBar(
        const SnackBar(content: Text('Agenda atualizada com sucesso!')),
      );
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível guardar a agenda. Verifica a ligação e tenta novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(SnackBar snackBar) {
    if (Scaffold.maybeOf(context) == null) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(snackBar);
  }

  void _toggleDay(String day, bool enabled) {
    setState(() {
      if (enabled) {
        _workingHours.putIfAbsent(day, () => ['09:00', '18:00']);
      } else {
        _workingHours.remove(day);
      }
    });
  }

  Future<void> _pickTime(String day, int index) async {
    final current = _workingHours[day];
    if (current == null || current.length < 2) return;

    final parts = current[index].split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
    final initial = TimeOfDay(
      hour: hour != null && hour >= 0 && hour <= 23 ? hour : 9,
      minute: minute != null && minute >= 0 && minute <= 59 ? minute : 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null || !mounted) return;

    setState(() {
      final hours = _workingHours[day];
      if (hours == null || hours.length < 2) return;
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      hours[index] = '$h:$m';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.experienceV2) {
      return _buildLegacyExperience(context);
    }

    final content = _buildContent(context);
    final saveAction = IconButton(
      key: const Key('prestador_agenda_save'),
      tooltip: 'Guardar agenda',
      onPressed: _isLoading || _loadError != null || _isSaving ? null : _save,
      icon: _isSaving
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save_outlined),
    );

    if (!widget.embedded) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Minha Agenda'),
          actions: [saveAction],
        ),
        body: SafeArea(
          child: SingleChildScrollView(child: content),
        ),
      );
    }

    return AppPageScaffold(
      key: const Key('prestador_agenda_embedded'),
      title: 'Minha Agenda',
      subtitle: 'Defina os seus horários de atendimento.',
      width: AppContentWidth.medium,
      actions: [saveAction],
      child: content,
    );
  }

  Widget _buildLegacyExperience(BuildContext context) {
    final saveAction = IconButton(
      key: const Key('prestador_agenda_save'),
      tooltip: 'Guardar agenda',
      onPressed: _isLoading || _loadError != null || _isSaving ? null : _save,
      icon: _isSaving
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save),
    );
    final body = _buildLegacyBody(context);

    if (widget.embedded) {
      return ColoredBox(
        key: const Key('prestador_agenda_embedded_legacy'),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(child: body),
      );
    }

    return Scaffold(
      key: const Key('prestador_agenda_standalone_legacy'),
      appBar: AppBar(
        title: const Text('Minha Agenda'),
        actions: [saveAction],
      ),
      body: body,
    );
  }

  Widget _buildLegacyBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'NÃ£o foi possÃ­vel carregar a agenda.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadData,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      key: const Key('prestador_agenda_days_legacy'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Defina os seus horÃ¡rios de atendimento.',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        for (final day in _daysOfWeek)
          _LegacyAgendaDayCard(
            day: day,
            label: _translateDay(day),
            hours: _workingHours[day],
            onEnabledChanged: (enabled) => _toggleDay(day, enabled),
            onStartPressed: () => _pickTime(day, 0),
            onEndPressed: () => _pickTime(day, 1),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 320,
        child: AppLoadingView(label: 'A carregar agenda...'),
      );
    }

    if (_loadError != null) {
      return SizedBox(
        height: 320,
        child: AppErrorView(
          message:
              'Não conseguimos carregar a agenda. Verifica a ligação e tenta novamente.',
          retryLabel: 'Tentar novamente',
          onRetry: _loadData,
        ),
      );
    }

    return Column(
      key: const Key('prestador_agenda_days'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.embedded) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x4,
              AppSpacing.x4,
              AppSpacing.x4,
              0,
            ),
            child: Text(
              'Defina os seus horários de atendimento.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
        ],
        Padding(
          padding: widget.embedded
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
          child: Column(
            children: [
              for (final day in _daysOfWeek) ...[
                _AgendaDayCard(
                  day: day,
                  label: _translateDay(day),
                  hours: _workingHours[day],
                  onEnabledChanged: (enabled) => _toggleDay(day, enabled),
                  onStartPressed: () => _pickTime(day, 0),
                  onEndPressed: () => _pickTime(day, 1),
                ),
                if (day != _daysOfWeek.last)
                  const SizedBox(height: AppSpacing.x3),
              ],
            ],
          ),
        ),
        if (!widget.embedded) const SizedBox(height: AppSpacing.x6),
      ],
    );
  }

  static Future<String?> _resolveCurrentProviderUid() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) return current.uid;

    try {
      final user = await AuthService.ensureSignedInAnonymously();
      return user.uid;
    } catch (_) {
      return null;
    }
  }

  String _translateDay(String day) {
    return switch (day) {
      'monday' => 'Segunda-feira',
      'tuesday' => 'Terça-feira',
      'wednesday' => 'Quarta-feira',
      'thursday' => 'Quinta-feira',
      'friday' => 'Sexta-feira',
      'saturday' => 'Sábado',
      'sunday' => 'Domingo',
      _ => day,
    };
  }
}

class _LegacyAgendaDayCard extends StatelessWidget {
  const _LegacyAgendaDayCard({
    required this.day,
    required this.label,
    required this.hours,
    required this.onEnabledChanged,
    required this.onStartPressed,
    required this.onEndPressed,
  });

  final String day;
  final String label;
  final List<String>? hours;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onStartPressed;
  final VoidCallback onEndPressed;

  @override
  Widget build(BuildContext context) {
    final isActive = hours != null && hours!.length >= 2;
    return Card(
      key: Key('prestador_agenda_legacy_day_$day'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Switch(
                  key: Key('prestador_agenda_legacy_toggle_$day'),
                  value: isActive,
                  onChanged: onEnabledChanged,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (isActive) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _LegacyTimeChip(
                    label: 'InÃ­cio',
                    time: hours![0],
                    onTap: onStartPressed,
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  _LegacyTimeChip(
                    label: 'Fim',
                    time: hours![1],
                    onTap: onEndPressed,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegacyTimeChip extends StatelessWidget {
  const _LegacyTimeChip({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaDayCard extends StatelessWidget {
  const _AgendaDayCard({
    required this.day,
    required this.label,
    required this.hours,
    required this.onEnabledChanged,
    required this.onStartPressed,
    required this.onEndPressed,
  });

  final String day;
  final String label;
  final List<String>? hours;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onStartPressed;
  final VoidCallback onEndPressed;

  @override
  Widget build(BuildContext context) {
    final isActive = hours != null && hours!.length >= 2;

    return AppCard(
      key: Key('prestador_agenda_day_$day'),
      variant: AppCardVariant.outlined,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            SwitchListTile(
              key: Key('prestador_agenda_toggle_$day'),
              value: isActive,
              onChanged: onEnabledChanged,
              title: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (isActive) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.x3),
                child: Row(
                  children: [
                    Expanded(
                      child: _TimeButton(
                        key: Key('prestador_agenda_start_$day'),
                        label: 'Início',
                        time: hours![0],
                        onPressed: onStartPressed,
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: _TimeButton(
                        key: Key('prestador_agenda_end_$day'),
                        label: 'Fim',
                        time: hours![1],
                        onPressed: onEndPressed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    super.key,
    required this.label,
    required this.time,
    required this.onPressed,
  });

  final String label;
  final String time;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visualTokens = context.chegaJaTheme;

    return Semantics(
      button: true,
      label: '$label, $time',
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(visualTokens.radiusMd),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(visualTokens.radiusMd),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x3,
                vertical: AppSpacing.x2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    time,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
