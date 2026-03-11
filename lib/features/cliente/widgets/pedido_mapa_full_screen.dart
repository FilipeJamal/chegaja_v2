import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:chegaja_v2/core/services/routing_service.dart';

/// Ecra de mapa em ecra inteiro, com zoom, arrastar e botoes + / - / recentrar
class PedidoMapaFullScreen extends StatefulWidget {
  final LatLng center;
  final LatLng? destination;
  final double initialZoom;

  const PedidoMapaFullScreen({
    super.key,
    required this.center,
    this.destination,
    this.initialZoom = 16,
  });

  @override
  State<PedidoMapaFullScreen> createState() => _PedidoMapaFullScreenState();
}

class _PedidoMapaFullScreenState extends State<PedidoMapaFullScreen> {
  GoogleMapController? _mapController;
  late double _zoom;

  List<LatLng> _routePoints = [];
  double? _distanceKm;
  double? _durationMin;
  bool _loadingRoute = false;

  @override
  void initState() {
    super.initState();
    _zoom = widget.initialZoom;
    if (widget.destination != null) {
      _fetchRoute();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchRoute() async {
    setState(() => _loadingRoute = true);
    final result = await RoutingService.instance
        .getRoute(widget.center, widget.destination!);
    if (!mounted) return;

    if (result != null) {
      setState(() {
        _routePoints = result.points;
        _distanceKm = result.distanceKm;
        _durationMin = result.durationMinutes;
        _loadingRoute = false;
      });
      _fitBounds();
    } else {
      setState(() => _loadingRoute = false);
    }
  }

  void _fitBounds() {
    final dest = widget.destination;
    if (dest == null) return;
    final minLat = [widget.center.latitude, dest.latitude].reduce(
      (a, b) => a < b ? a : b,
    );
    final maxLat = [widget.center.latitude, dest.latitude].reduce(
      (a, b) => a > b ? a : b,
    );
    final minLng = [widget.center.longitude, dest.longitude].reduce(
      (a, b) => a < b ? a : b,
    );
    final maxLng = [widget.center.longitude, dest.longitude].reduce(
      (a, b) => a > b ? a : b,
    );

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void _recenter() {
    if (widget.destination != null && _routePoints.isNotEmpty) {
      _fitBounds();
      return;
    }
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: widget.center, zoom: widget.initialZoom),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('origem'),
        position: widget.center,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
      ),
    };

    if (widget.destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destino'),
          position: widget.destination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    final polylines = <Polyline>{};
    if (_routePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          color: Colors.blueAccent,
          width: 4,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa do pedido'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.center,
              zoom: _zoom,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: (position) {
              _zoom = position.zoom;
            },
            minMaxZoomPreference: const MinMaxZoomPreference(3, 19),
            markers: markers,
            polylines: polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
          ),
          if (_distanceKm != null && _durationMin != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.timer, color: Colors.blue),
                          const SizedBox(height: 4),
                          Text(
                            '${_durationMin!.ceil()} min',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      Column(
                        children: [
                          const Icon(
                            Icons.directions_car,
                            color: Colors.black54,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_distanceKm!.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
          if (_loadingRoute)
            const Positioned(
              right: 16,
              top: 16,
              child: CircularProgressIndicator(),
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
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon),
        ),
      ),
    );
  }
}
