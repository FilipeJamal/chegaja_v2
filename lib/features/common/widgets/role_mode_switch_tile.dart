import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/services/role_mode_service.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/features/common/widgets/settings_list_tile.dart';

class RoleModeSwitchTile extends StatelessWidget {
  const RoleModeSwitchTile({
    super.key,
    required this.currentRole,
    this.roleModeService,
    this.showDivider = false,
  });

  final String currentRole;
  final RoleModeService? roleModeService;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final normalized = RoleModeService.normalizeRole(currentRole) ?? 'cliente';
    final targetRole = normalized == 'prestador' ? 'cliente' : 'prestador';
    final isCliente = normalized == 'cliente';

    return SettingsListTile(
      key: Key(
        isCliente
            ? 'cliente_switch_to_prestador_button'
            : 'prestador_switch_to_cliente_button',
      ),
      icon: isCliente ? Icons.work_outline_rounded : Icons.search_rounded,
      iconColor: isCliente ? AppPalette.success : AppPalette.accentBlue,
      title:
          isCliente ? 'Mudar para modo prestador' : 'Mudar para modo cliente',
      subtitle: isCliente
          ? 'Comeca a receber pedidos e gerir servicos.'
          : 'Pede servicos como cliente.',
      showDivider: showDivider,
      onTap: () async {
        await (roleModeService ?? RoleModeService.instance).setMode(targetRole);
      },
    );
  }
}
