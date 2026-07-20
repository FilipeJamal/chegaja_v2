import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:chegaja_v2/core/services/notification_service.dart';

enum _PermissionKind { location, notifications, camera }

class PermissionSettingsScreen extends StatefulWidget {
  const PermissionSettingsScreen({super.key});

  @override
  State<PermissionSettingsScreen> createState() =>
      _PermissionSettingsScreenState();
}

class _PermissionSettingsScreenState extends State<PermissionSettingsScreen>
    with WidgetsBindingObserver {
  final Map<_PermissionKind, PermissionStatus> _statuses = {};
  _PermissionKind? _requesting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Permission _permissionFor(_PermissionKind kind) => switch (kind) {
        _PermissionKind.location => Permission.locationWhenInUse,
        _PermissionKind.notifications => Permission.notification,
        _PermissionKind.camera => Permission.camera,
      };

  Future<void> _refresh() async {
    final entries = await Future.wait(
      _PermissionKind.values.map((kind) async {
        return MapEntry(kind, await _permissionFor(kind).status);
      }),
    );
    if (!mounted) return;
    setState(() => _statuses.addEntries(entries));
  }

  Future<void> _request(_PermissionKind kind) async {
    if (_requesting != null) return;
    setState(() => _requesting = kind);
    try {
      if (kind == _PermissionKind.notifications) {
        await NotificationService.instance.requestUserPermission();
      } else {
        await _permissionFor(kind).request();
      }
      await _refresh();
      final status = _statuses[kind];
      if (mounted && status != null && !status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A permissao nao foi concedida. Podes continuar a usar alternativas manuais.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _requesting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permissoes do dispositivo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tu decides quando autorizar',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'O ChegaJa pede cada permissao apenas quando faz sentido. Recusar nao impede explorar a aplicacao e a localizacao pode ser indicada manualmente.',
          ),
          const SizedBox(height: 20),
          _permissionCard(
            kind: _PermissionKind.location,
            icon: Icons.location_on_outlined,
            title: 'Localizacao durante a utilizacao',
            rationale:
                'Usada para sugerir a zona do pedido e encontrar trabalhos proximos. A morada exata nao entra no pedido publico.',
          ),
          _permissionCard(
            kind: _PermissionKind.notifications,
            icon: Icons.notifications_outlined,
            title: 'Notificacoes',
            rationale:
                'Avisa sobre respostas, mensagens e mudancas de estado. Nao e necessaria para consultar o historico.',
          ),
          _permissionCard(
            kind: _PermissionKind.camera,
            icon: Icons.photo_camera_outlined,
            title: 'Camara',
            rationale:
                'Usada somente quando escolhes tirar uma fotografia para perfil, portfolio, anexo ou chat.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: openAppSettings,
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Abrir definicoes do Android'),
          ),
        ],
      ),
    );
  }

  Widget _permissionCard({
    required _PermissionKind kind,
    required IconData icon,
    required String title,
    required String rationale,
  }) {
    final status = _statuses[kind];
    final granted = status?.isGranted == true;
    final permanentlyDenied = status?.isPermanentlyDenied == true;
    final color = granted ? Colors.green : Colors.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  granted ? 'Permitida' : 'Nao permitida',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(rationale),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: _requesting != null
                    ? null
                    : (permanentlyDenied
                        ? openAppSettings
                        : () => _request(kind)),
                child: _requesting == kind
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        granted
                            ? 'Verificar novamente'
                            : (permanentlyDenied
                                ? 'Abrir definicoes'
                                : 'Autorizar'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
