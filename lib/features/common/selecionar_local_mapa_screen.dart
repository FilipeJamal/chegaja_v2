// lib/features/common/selecionar_local_mapa_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

class _SelecionarLocalMapaScreenState extends State<SelecionarLocalMapaScreen> {
  GoogleMapController? _mapController;
  LatLng? _selected;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selected = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _selected ??
        LatLng(
          widget.initialLatitude ?? 38.7223, // Lisboa por defeito
          widget.initialLongitude ?? -9.1393,
        );

    final markers = <Marker>{};
    if (_selected != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: _selected!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

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
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: center,
          zoom: 15,
        ),
        minMaxZoomPreference: const MinMaxZoomPreference(3, 19),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        onTap: (point) {
          setState(() {
            _selected = point;
          });
        },
        markers: markers,
        myLocationButtonEnabled: false,
        myLocationEnabled: false,
        mapToolbarEnabled: false,
      ),
    );
  }
}
