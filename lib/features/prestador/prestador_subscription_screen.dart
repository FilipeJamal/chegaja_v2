import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chegaja_v2/core/services/subscription_service.dart';

class PrestadorSubscriptionScreen extends StatefulWidget {
  const PrestadorSubscriptionScreen({super.key});

  @override
  State<PrestadorSubscriptionScreen> createState() =>
      _PrestadorSubscriptionScreenState();
}

class _PrestadorSubscriptionScreenState
    extends State<PrestadorSubscriptionScreen> {
  bool _busy = false;

  String _moneyCents(int cents) {
    final euros = cents / 100.0;
    return '€ ${euros.toStringAsFixed(2)}';
  }

  String _formatMillis(Object? msValue) {
    final ms = int.tryParse('${msValue ?? ''}') ?? 0;
    if (ms <= 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) throw Exception('URL inválida.');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) throw Exception('Não foi possível abrir URL.');
  }

  Future<void> _startCheckout(String planId) async {
    setState(() => _busy = true);
    try {
      final url = await SubscriptionService.instance.createCheckoutUrl(
        planId: planId,
      );
      await _openUrl(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checkout de assinatura aberto.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao iniciar assinatura: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPortal() async {
    setState(() => _busy = true);
    try {
      final url = await SubscriptionService.instance.createBillingPortalUrl();
      await _openUrl(url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao abrir portal: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _planCard({
    required String title,
    required String price,
    required List<String> bullets,
    required VoidCallback onTap,
    required bool highlighted,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted ? Colors.blue : Colors.black12,
          width: highlighted ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '$price / mês',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: highlighted ? Colors.blue[700] : null,
            ),
          ),
          const SizedBox(height: 10),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(bullet)),
                ],
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : onTap,
              child: const Text('Escolher plano'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assinatura')),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: SubscriptionService.instance.watchCurrentSubscription(),
        builder: (context, snap) {
          final sub = snap.data;
          final status = '${sub?['status'] ?? 'none'}'.toLowerCase();
          final planId = '${sub?['planId'] ?? '-'}';
          final monthly =
              int.tryParse('${sub?['monthlyAmountCents'] ?? '0'}') ?? 0;
          final periodEnd = _formatMillis(sub?['currentPeriodEnd']);
          final active = status == 'active' || status == 'trialing';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado atual',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text('Status: $status'),
                    Text('Plano: $planId'),
                    Text('Valor mensal: ${_moneyCents(monthly)}'),
                    Text('Período até: $periodEnd'),
                    const SizedBox(height: 10),
                    if (active)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _openPortal,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Gerir cobrança no Stripe'),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _planCard(
                title: 'Plano Basic',
                price: _moneyCents(990),
                bullets: const [
                  'Perfil com destaque básico',
                  'Métricas de pedidos essenciais',
                  'Suporte prioritário padrão',
                ],
                onTap: () => _startCheckout('basic'),
                highlighted: false,
              ),
              _planCard(
                title: 'Plano Pro',
                price: _moneyCents(1990),
                bullets: const [
                  'Maior exposição no matching',
                  'Métricas e retenção avançadas',
                  'Prioridade em campanhas internas',
                ],
                onTap: () => _startCheckout('pro'),
                highlighted: true,
              ),
            ],
          );
        },
      ),
    );
  }
}
