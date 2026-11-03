import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/formato.dart';
import '../app.dart';
import '../controladores/controlador_app.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

/// Análisis geográfico (RF-08): mapa de calor y listas por comuna y por barrio.
class GeograficoPantalla extends StatefulWidget {
  const GeograficoPantalla({super.key});

  @override
  State<GeograficoPantalla> createState() => _GeograficoPantallaState();
}

class _GeograficoPantallaState extends State<GeograficoPantalla> {
  static const LatLng _centro = LatLng(7.112, -73.118);
  static const double _zoom = 12.4;

  final MapController _mapa = MapController();
  int _vista = 0;

  @override
  Widget build(BuildContext context) {
    final controlador = ProveedorControlador.de(context);
    final resumen = controlador.resumen;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Segmentos(
          opciones: const ['Mapa', 'Por comuna', 'Por zona'],
          seleccionado: _vista,
          alCambiar: (valor) => setState(() => _vista = valor),
        ),
        const SizedBox(height: 12),
        if (_vista == 0) ...[
          _Mapa(controlador: controlador, mapa: _mapa, centro: _centro, zoom: _zoom),
          const SizedBox(height: 12),
          _ResumenMapa(controlador: controlador),
        ] else if (_vista == 1)
          Tarjeta(
            child: BarrasHorizontales(
              items: controlador.rankingComunas,
              total: resumen.total,
            ),
          )
        else
          Tarjeta(
            child: BarrasHorizontales(
              items: controlador.rankingBarrios.take(25).toList(),
              total: resumen.total,
            ),
          ),
        const SizedBox(height: 10),
        Aviso(_avisoUbicacion(controlador)),
      ],
    );
  }

  String _avisoUbicacion(ControladorApp controlador) {
    final conUbicacion = controlador.rankingBarrios.fold(0, (s, i) => s + i.cantidad);
    final sinUbicacion = controlador.resumen.total - conUbicacion;
    return 'El dataset no trae coordenadas: cada punto es el barrio donde se '
        'registró el accidente, no la dirección exacta. '
        '${formatoNumero(sinUbicacion)} accidentes sin barrio no se muestran.';
  }
}

class _Mapa extends StatelessWidget {
  const _Mapa({
    required this.controlador,
    required this.mapa,
    required this.centro,
    required this.zoom,
  });

  final ControladorApp controlador;
  final MapController mapa;
  final LatLng centro;
  final double zoom;

  /// Clasifica en cinco niveles usando la raíz, porque Centro y Cabecera
  /// concentran tanto que en escala lineal el resto se vería igual.
  int _nivel(int cantidad, int mayor) {
    final relativo = math.sqrt(cantidad / mayor);
    return math.min((relativo * 5).floor(), 4);
  }

  List<CircleMarker> _circulos() {
    final barrios = controlador.datos.catalogoBarrios;
    final conteos = controlador.resumen.porBarrio;
    final indices = [
      for (var i = 0; i < barrios.length; i++)
        if (conteos[i] > 0 && barrios[i].tieneUbicacion) i,
    ]..sort((a, b) => conteos[a].compareTo(conteos[b]));
    if (indices.isEmpty) return const [];

    final mayor = conteos[indices.last];
    final marcadores = <CircleMarker>[];
    for (final i in indices) {
      final nivel = _nivel(conteos[i], mayor);
      final color = Colores.densidad[nivel];
      final punto = LatLng(barrios[i].lat!, barrios[i].lon!);
      final base = 130.0 + nivel * 70;
      for (final (escala, opacidad) in const [(2.4, 0.16), (1.6, 0.26), (1.0, 0.62)]) {
        marcadores.add(CircleMarker(
          point: punto,
          radius: base * escala,
          useRadiusInMeter: true,
          color: color.withValues(alpha: opacidad),
        ));
      }
    }
    return marcadores;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 340,
        child: Stack(
          children: [
            FlutterMap(
              mapController: mapa,
              options: MapOptions(
                initialCenter: centro,
                initialZoom: zoom,
                minZoom: 10,
                maxZoom: 17,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tdea.accidentalidad_vial',
                ),
                CircleLayer(circles: _circulos()),
                const SimpleAttributionWidget(
                  source: Text('OpenStreetMap', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
            const Positioned(top: 8, right: 8, child: _Leyenda()),
            Positioned(
              left: 8,
              bottom: 8,
              child: FloatingActionButton.small(
                heroTag: null,
                tooltip: 'Centrar mapa',
                backgroundColor: Colores.superficie,
                foregroundColor: Colores.primario,
                onPressed: () => mapa.move(centro, zoom),
                child: const Icon(Icons.my_location),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda();

  static const List<String> _niveles = ['Muy baja', 'Baja', 'Media', 'Alta', 'Muy alta'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colores.superficie.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Densidad de accidentes',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          for (var i = 4; i >= 0; i--)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: Colores.densidad[i],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(_niveles[i], style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ResumenMapa extends StatelessWidget {
  const _ResumenMapa({required this.controlador});

  final ControladorApp controlador;

  @override
  Widget build(BuildContext context) {
    final resumen = controlador.resumen;
    final barrio = controlador.rankingBarrios.isEmpty ? null : controlador.rankingBarrios.first;
    final comuna = controlador.rankingComunas.isEmpty ? null : controlador.rankingComunas.first;
    final franja = resumen.franjaPrincipal;

    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del mapa',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Dato(
                  icono: Icons.location_on_outlined,
                  titulo: 'Total de accidentes',
                  valor: formatoNumero(resumen.total),
                ),
              ),
              Expanded(
                child: _Dato(
                  icono: Icons.adjust,
                  color: Colores.peligro,
                  titulo: 'Zona de mayor concentración',
                  valor: barrio?.nombre ?? '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Dato(
                  icono: Icons.north_east,
                  color: Colores.exito,
                  titulo: 'Comuna con más eventos',
                  valor: comuna == null
                      ? '—'
                      : '${comuna.nombre.split(' · ').first} '
                          '(${formatoDecimal(resumen.porcentaje(comuna.cantidad))} %)',
                ),
              ),
              Expanded(
                child: _Dato(
                  icono: Icons.schedule,
                  titulo: 'Horario de mayor incidencia',
                  valor: franja == null
                      ? '—'
                      : '${formatoHora(franja)} a ${formatoHora((franja + 2) % 24)} '
                          '(${formatoDecimal(resumen.porcentaje(resumen.cantidadEnFranja(franja)))} %)',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.color = Colores.primario,
  });

  final IconData icono;
  final String titulo;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 11, color: Colores.textoSuave)),
              const SizedBox(height: 2),
              Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}
