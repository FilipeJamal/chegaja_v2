// lib/features/common/selecionar_local_mapa_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SelecionarLocalMapaScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const SelecionarLocalMapaScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<SelecionarLocalMapaScreen> createState() =>
      _SelecionarLocalMapaScreenState();
}

class _SelecionarLocalMapaScreenState
    extends State<SelecionarLocalMapaScreen> {
  late final MapController _mapController;
  LatLng? _selected;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selected = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _selected ??
        LatLng(
          widget.initialLatitude ?? 38.7223, // Lisboa por defeito
          widget.initialLongitude ?? -9.1393,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolher localização'),
        actions: [
          TextButton(
            onPressed: _selected == null
                ? null
                : () {
                    Navigator.of(context).pop(_selected);
                  },
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 15,
          minZoom: 3,
          maxZoom: 19,
          onTap: (tapPosition, point) {
            setState(() {
              _selected = point;
            });
          },
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.pinchZoom |
                InteractiveFlag.drag |
                InteractiveFlag.doubleTapZoom |
                InteractiveFlag.scrollWheelZoom,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.chegaja.app',
          ),
          if (_selected != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _selected!,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.location_pin,
                    size: 44,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
