// lib/features/common/pedido_mapa_card.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:chegaja_v2/core/models/pedido.dart';

class PedidoMapaCard extends StatefulWidget {
  final Pedido pedido;
  final bool isCliente;

  const PedidoMapaCard({
    super.key,
    required this.pedido,
    this.isCliente = true, // Default true se nao especificado
  });

  @override
  State<PedidoMapaCard> createState() => _PedidoMapaCardState();
}

class _PedidoMapaCardState extends State<PedidoMapaCard> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _prestadorSub;
  LatLng? _prestadorLocation;
  bool _prestadorOnline = false;

  @override
  void initState() {
    super.initState();
    _initProviderTracking();
  }

  @override
  void didUpdateWidget(covariant PedidoMapaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pedido.prestadorId != widget.pedido.prestadorId ||
        oldWidget.pedido.estado != widget.pedido.estado) {
      _initProviderTracking();
    }
  }

  @override
  void dispose() {
    _prestadorSub?.cancel();
    super.dispose();
  }

  void _initProviderTracking() {
    _prestadorSub?.cancel();
    _prestadorSub = null;
    _prestadorLocation = null;

    final p = widget.pedido;
    if (p.prestadorId == null) return;

    // So mostramos tracking em estados ativos
    final estadosAtivos = {
      'aceito',
      'em_andamento',
      'aguarda_confirmacao_valor',
    };

    if (!estadosAtivos.contains(p.estado)) return;

    _prestadorSub = FirebaseFirestore.instance
        .collection('prestadores')
        .doc(p.prestadorId)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final data = snap.data();
      if (data == null) return;

      final isOnline = (data['isOnline'] as bool?) ?? false;
      final loc = data['lastLocation'] as Map<String, dynamic>?;

      LatLng? newPos;
      if (loc != null) {
        final lat = (loc['lat'] as num?)?.toDouble();
        final lng = (loc['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          newPos = LatLng(lat, lng);
        }
      }

      setState(() {
        _prestadorOnline = isOnline;
        _prestadorLocation = newPos;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;

    // Nota: no futuro vamos usar as coordenadas reais do pedido.
    // Por agora, usamos uma localizacao de demonstracao (Lisboa) se null.
    final hasLocation = pedido.latitude != null && pedido.longitude != null;
    final LatLng center = hasLocation
        ? LatLng(pedido.latitude!, pedido.longitude!)
        : const LatLng(38.7223, -9.1393);

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('pedido'),
        position: center,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        ),
      ),
    };

    if (_prestadorLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('prestador'),
          position: _prestadorLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _prestadorOnline ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: center,
          zoom: 13,
        ),
        markers: markers,
        zoomControlsEnabled: false,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        scrollGesturesEnabled: false,
        zoomGesturesEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
      ),
    );
  }
}
