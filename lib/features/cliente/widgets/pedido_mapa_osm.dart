// lib/features/cliente/widgets/pedido_mapa_osm.dart
//
// OpenStreetMap-based map card and fullscreen viewer for order details.
// Uses flutter_map + latlong2 (not Google Maps).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

// --------- helpers ---------

const double _kEtaAvgSpeedKmh = 30.0;

double _distanceKm(LatLng a, LatLng b) {
  const calculator = Distance();
  return calculator.as(LengthUnit.Kilometer, a, b);
}

String _formatDistance(double km, AppLocalizations l10n) {
  if (km < 1) {
    final meters = (km * 1000).round();
    return l10n.distanceMeters(meters.toString());
  }
  final kmLabel = NumberFormat('0.0', l10n.localeName).format(km);
  return l10n.distanceKilometers(kmLabel);
}

String _formatEta(double km, AppLocalizations l10n) {
  final minutes = (km / _kEtaAvgSpeedKmh * 60).round();
  if (minutes <= 1) return l10n.etaLessThanMinute;
  if (minutes < 60) return l10n.etaMinutes(minutes);
  final hours = minutes ~/ 60;
  final rem = minutes % 60;
  if (rem == 0) return l10n.etaHours(hours);
  return l10n.etaHoursMinutes(hours, rem);
}

// --------- MAP CARD (preview) ---------

/// Small preview map card that links to full-screen.
class PedidoMapaOsmCard extends StatelessWidget {
  final Pedido pedido;
  final bool isCliente;

  const PedidoMapaOsmCard({
    super.key,
    required this.pedido,
    required this.isCliente,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // If there are no coordinates yet, use Lisbon as fallback.
    final pedidoPoint = (pedido.latitude != null && pedido.longitude != null)
        ? LatLng(pedido.latitude!, pedido.longitude!)
        : const LatLng(38.7223, -9.1393);

    final prestadorId = pedido.prestadorId;
    if (prestadorId == null || prestadorId.trim().isEmpty) {
      return _buildMapa(
        context,
        pedidoPoint: pedidoPoint,
        prestadorPoint: null,
        l10n: l10n,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('prestadores')
          .doc(prestadorId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final lastLocation = data?['lastLocation'] as Map<String, dynamic>?;
        final lat = (lastLocation?['lat'] as num?)?.toDouble();
        final lng = (lastLocation?['lng'] as num?)?.toDouble();

        final prestadorPoint =
            (lat != null && lng != null) ? LatLng(lat, lng) : null;

        return _buildMapa(
          context,
          pedidoPoint: pedidoPoint,
          prestadorPoint: prestadorPoint,
          l10n: l10n,
        );
      },
    );
  }

  Widget _buildMapa(
    BuildContext context, {
    required LatLng pedidoPoint,
    required LatLng? prestadorPoint,
    required AppLocalizations l10n,
  }) {
    final routePoints = prestadorPoint != null
        ? <LatLng>[prestadorPoint, pedidoPoint]
        : const <LatLng>[];
    final distanceKm = prestadorPoint != null
        ? _distanceKm(prestadorPoint, pedidoPoint)
        : null;
    final etaText = distanceKm != null ? _formatEta(distanceKm, l10n) : null;
    final distanceText =
        distanceKm != null ? _formatDistance(distanceKm, l10n) : null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PedidoMapaOsmFullScreen(
              pedidoPoint: pedidoPoint,
              prestadorPoint: prestadorPoint,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 180,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: pedidoPoint,
                  initialZoom: 13,
                  // Preview: so mostra o mapa, sem interacao
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.chegaja.app',
                  ),
                  if (routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          color: Colors.blueAccent,
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: pedidoPoint,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.redAccent,
                          size: 34,
                        ),
                      ),
                      if (prestadorPoint != null)
                        Marker(
                          point: prestadorPoint,
                          width: 36,
                          height: 36,
                          child: const Icon(
                            Icons.directions_car,
                            color: Colors.blueAccent,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (etaText != null && distanceText != null)
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.mapEtaLabel(etaText, distanceText),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.open_in_full,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.mapOpenAction,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------- MAP FULL SCREEN ---------

/// Full-screen OpenStreetMap view of order location and provider.
class PedidoMapaOsmFullScreen extends StatefulWidget {
  final LatLng pedidoPoint;
  final LatLng? prestadorPoint;

  const PedidoMapaOsmFullScreen({
    super.key,
    required this.pedidoPoint,
    this.prestadorPoint,
  });

  @override
  State<PedidoMapaOsmFullScreen> createState() =>
      _PedidoMapaOsmFullScreenState();
}

class _PedidoMapaOsmFullScreenState extends State<PedidoMapaOsmFullScreen> {
  late final MapController _mapController;
  double _zoom = 15;

  LatLng get _mapCenter {
    final prestador = widget.prestadorPoint;
    if (prestador == null) {
      return widget.pedidoPoint;
    }
    return LatLng(
      (widget.pedidoPoint.latitude + prestador.latitude) / 2,
      (widget.pedidoPoint.longitude + prestador.longitude) / 2,
    );
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + 1).clamp(3.0, 19.0);
    });
    final center = _mapCenter;
    _mapController.move(center, _zoom);
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - 1).clamp(3.0, 19.0);
    });
    final center = _mapCenter;
    _mapController.move(center, _zoom);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final center = _mapCenter;
    final prestadorPoint = widget.prestadorPoint;
    final routePoints = prestadorPoint != null
        ? <LatLng>[prestadorPoint, widget.pedidoPoint]
        : const <LatLng>[];
    final distanceKm = prestadorPoint != null
        ? _distanceKm(prestadorPoint, widget.pedidoPoint)
        : null;
    final etaText = distanceKm != null ? _formatEta(distanceKm, l10n) : null;
    final distanceText =
        distanceKm != null ? _formatDistance(distanceKm, l10n) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderMapTitle),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: _zoom,
              minZoom: 3,
              maxZoom: 19,
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
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: Colors.blueAccent,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.pedidoPoint,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      size: 44,
                      color: Colors.redAccent,
                    ),
                  ),
                  if (prestadorPoint != null)
                    Marker(
                      point: prestadorPoint,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.directions_car,
                        size: 34,
                        color: Colors.blueAccent,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (etaText != null && distanceText != null)
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.mapEtaLabel(etaText, distanceText),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomInMapaPedido',
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOutMapaPedido',
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
