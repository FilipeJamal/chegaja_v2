import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/core/widgets/app_button.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_metric_tile.dart';
import 'package:chegaja_v2/core/widgets/app_responsive_grid.dart';
import 'package:chegaja_v2/core/widgets/app_section_header.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_card.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_presenter.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrestadorAvailabilityPanel extends StatelessWidget {
  const PrestadorAvailabilityPanel({
    super.key,
    required this.online,
    required this.onChanged,
  });

  final bool online;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = online ? 'Online' : 'Offline';
    final message = online
        ? 'Pronto para receber pedidos compativeis.'
        : 'Ativa para receber novos pedidos.';
    final accent = online ? AppPalette.success : theme.colorScheme.secondary;

    return AppCard(
      key: const Key('prestador_home_availability_panel'),
      variant: AppCardVariant.elevated,
      size: AppCardSize.large,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final copy = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  online
                      ? Icons.radio_button_checked_rounded
                      : Icons.power_settings_new_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppStatusPill(
                      label: statusLabel,
                      tone: online
                          ? AppStatusTone.success
                          : AppStatusTone.neutral,
                      icon: online
                          ? Icons.bolt_rounded
                          : Icons.radio_button_off_rounded,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      online
                          ? 'Estas visivel para clientes perto de ti.'
                          : 'Ficas oculto ate voltares a ficar online.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final control = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                online ? 'Receber pedidos' : 'Ativar',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(width: AppSpacing.x2),
              Switch(value: online, onChanged: onChanged),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                copy,
                const SizedBox(height: AppSpacing.x4),
                Align(alignment: Alignment.centerLeft, child: control),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: copy),
              const SizedBox(width: AppSpacing.x5),
              control,
            ],
          );
        },
      ),
    );
  }
}

class PrestadorMetricStrip extends StatelessWidget {
  const PrestadorMetricStrip({
    super.key,
    required this.liquidoHoje,
    required this.brutoHoje,
    required this.taxaHoje,
    required this.servicosMes,
  });

  final String liquidoHoje;
  final String brutoHoje;
  final String taxaHoje;
  final String servicosMes;

  @override
  Widget build(BuildContext context) {
    return AppResponsiveGrid(
      key: const Key('prestador_home_metric_strip'),
      minItemWidth: 240,
      spacing: AppSpacing.x3,
      runSpacing: AppSpacing.x3,
      children: [
        AppMetricTile(
          label: 'Ganhos hoje',
          value: liquidoHoje,
          supportingText: 'Bruto: $brutoHoje | Taxa: $taxaHoje',
          icon: Icons.euro_rounded,
          tone: AppStatusTone.success,
        ),
        AppMetricTile(
          label: 'Servicos este mes',
          value: servicosMes,
          supportingText: 'Concluidos e confirmados',
          icon: Icons.work_outline_rounded,
          tone: AppStatusTone.info,
        ),
      ],
    );
  }
}

class PrestadorNextWorkPanel extends StatelessWidget {
  const PrestadorNextWorkPanel({
    super.key,
    required this.pedido,
    required this.actionText,
    required this.onOpen,
  });

  final Pedido pedido;
  final String actionText;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AppActionPanel(
      key: const Key('prestador_home_next_work_panel'),
      title: 'Tens um trabalho para gerir',
      message: '$actionText\n${pedido.titulo}',
      icon: Icons.notifications_active_outlined,
      tone: AppStatusTone.warning,
      primaryAction: AppActionPanelAction(
        label: 'Abrir trabalho',
        icon: Icons.arrow_forward_rounded,
        onPressed: onOpen,
      ),
    );
  }
}

class PrestadorCategoriesPanel extends StatelessWidget {
  const PrestadorCategoriesPanel({
    super.key,
    required this.categories,
    required this.loading,
    required this.onEdit,
  });

  final List<String> categories;
  final bool loading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCategories = categories.isNotEmpty;

    return AppCard(
      key: const Key('prestador_home_categories_panel'),
      variant: AppCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSectionHeader(
            title: 'Categorias de atuacao',
            subtitle: hasCategories
                ? '${categories.length} selecionadas'
                : 'Seleciona categorias para receber pedidos compativeis.',
            trailing: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : AppStatusPill(
                    label: hasCategories ? 'Configurado' : 'Pendente',
                    tone: hasCategories
                        ? AppStatusTone.success
                        : AppStatusTone.warning,
                    size: AppStatusPillSize.sm,
                  ),
          ),
          Text(
            'Usamos isto para filtrar os pedidos que aparecem no painel.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (hasCategories) ...[
            const SizedBox(height: AppSpacing.x3),
            PrestadorCategoriesChips(categories: categories),
          ],
          const SizedBox(height: AppSpacing.x4),
          AppButton(
            label:
                hasCategories ? 'Editar categorias' : 'Selecionar categorias',
            onPressed: loading ? null : onEdit,
            leadingIcon: Icons.tune_rounded,
            variant: hasCategories
                ? AppButtonVariant.secondary
                : AppButtonVariant.primary,
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class PrestadorCategoriesChips extends StatelessWidget {
  const PrestadorCategoriesChips({
    super.key,
    required this.categories,
  });

  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.x2,
      runSpacing: AppSpacing.x2,
      children: [
        for (final category in categories.take(6))
          AppStatusPill(
            label: category,
            tone: AppStatusTone.neutral,
            size: AppStatusPillSize.sm,
          ),
      ],
    );
  }
}

class PrestadorAvailableOrdersSection extends StatelessWidget {
  const PrestadorAvailableOrdersSection({
    super.key,
    required this.count,
    required this.child,
  });

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final subtitle = count == 0
        ? 'Quando houver pedidos compativeis, eles aparecem aqui.'
        : '$count pedido${count == 1 ? '' : 's'} compativel${count == 1 ? '' : 'eis'} para analisar.';

    return Column(
      key: const Key('prestador_home_available_orders_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Pedidos perto de ti',
          subtitle: subtitle,
        ),
        child,
      ],
    );
  }
}

class PrestadorAvailableOrderCard extends StatelessWidget {
  const PrestadorAvailableOrderCard({
    super.key,
    required this.pedido,
    required this.descricao,
    required this.agendadoPara,
    required this.modo,
    required this.tipoPrecoLabel,
    required this.tipoPagamentoLabel,
    required this.df,
    required this.onAceitar,
    required this.onIgnorar,
  });

  final Pedido pedido;
  final String? descricao;
  final DateTime? agendadoPara;
  final String modo;
  final String tipoPrecoLabel;
  final String tipoPagamentoLabel;
  final DateFormat df;
  final VoidCallback onAceitar;
  final VoidCallback onIgnorar;

  @override
  Widget build(BuildContext context) {
    final linhaAgendamento = modo == 'AGENDADO' && agendadoPara != null
        ? 'Agendado: ${df.format(agendadoPara!)}'
        : 'Servico imediato';
    final desc = (descricao ?? '').trim();
    final listData = PedidoListPresenter.dataFor(
      pedido,
      role: PedidoViewerRole.prestador,
    );

    return PedidoListCard(
      key: Key('prestador_pedido_card_${pedido.id}'),
      data: listData,
      metaLabels: [
        tipoPrecoLabel,
        tipoPagamentoLabel,
        linhaAgendamento,
      ],
      trailingActions: [
        AppButton(
          key: Key('prestador_ignorar_pedido_${pedido.id}'),
          label: 'Ignorar',
          onPressed: onIgnorar,
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.sm,
        ),
        AppButton(
          key: Key('prestador_aceitar_pedido_${pedido.id}'),
          label: 'Aceitar',
          onPressed: onAceitar,
          leadingIcon: Icons.check_rounded,
          size: AppButtonSize.sm,
        ),
      ],
      footer: desc.isEmpty
          ? null
          : Text(
              desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
    );
  }
}
