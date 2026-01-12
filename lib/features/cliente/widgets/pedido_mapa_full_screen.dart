import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Ecrã de mapa em ecrã inteiro, com zoom, arrastar e botões + / - / recentrar
class PedidoMapaFullScreen extends StatefulWidget {
  final LatLng center;
  final double initialZoom;

  const PedidoMapaFullScreen({
    super.key,
    required this.center,
    this.initialZoom = 16,
  });

  @override
  State<PedidoMapaFullScreen> createState() => _PedidoMapaFullScreenState();
}

class _PedidoMapaFullScreenState extends State<PedidoMapaFullScreen> {
  late final MapController _mapController;
  late double _zoom;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _zoom = widget.initialZoom;
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + 1).clamp(3, 19);
    });
    _mapController.move(widget.center, _zoom);
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - 1).clamp(3, 19);
    });
    _mapController.move(widget.center, _zoom);
  }

  void _recenter() {
    _mapController.move(widget.center, _zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa do pedido'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.center,
              initialZoom: _zoom,
              // 👉 Aqui desbloqueias tudo: pinch, arrastar, dois toques, etc.
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              minZoom: 3,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.chegaja.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.center,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      size: 40,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Botões de controlo de zoom
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RoundMapButton(
                  icon: Icons.add,
                  onTap: _zoomIn,
                ),
                const SizedBox(height: 8),
                _RoundMapButton(
                  icon: Icons.remove,
                  onTap: _zoomOut,
                ),
                const SizedBox(height: 8),
                _RoundMapButton(
                  icon: Icons.my_location,
                  onTap: _recenter,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundMapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundMapButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: Colors.white,
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.add, // será substituído pelo ícone passado no filho
          ),
        ),
      ),
    );
  }
}

