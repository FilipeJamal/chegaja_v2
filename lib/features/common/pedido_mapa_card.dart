// lib/features/common/pedido_mapa_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:chegaja_v2/core/models/pedido.dart';

class PedidoMapaCard extends StatelessWidget {
  final Pedido pedido;

  const PedidoMapaCard({
    super.key,
    required this.pedido,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Nota: no futuro vamos usar as coordenadas reais do pedido.
    // Por agora, usamos uma localização de demonstração (Lisboa).
    final hasLocation = pedido.latitude != null && pedido.longitude != null;
    final LatLng center = hasLocation
        ? LatLng(pedido.latitude!, pedido.longitude!)
        : const LatLng(38.7223, -9.1393);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.chegaja.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: center,
                width: 40,
                height: 40,
                child: Icon(
                  Icons.location_pin,
                  color: theme.colorScheme.primary,
                  size: 36,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
