import 'package:flutter/material.dart';

import '../../core/formato.dart';
import '../../domain/casos_uso/medir_complejidad.dart';
import '../app.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import '../widgets/graficos.dart';

class _Algoritmo {
  const _Algoritmo(this.nombre, this.uso, this.complejidad, this.clase);

  final String nombre;
  final String uso;
  final String complejidad;
  final String clase;
}

/// Clasificación de los algoritmos del sistema y tiempos medidos en el equipo.
class ComplejidadPantalla extends StatefulWidget {
  const ComplejidadPantalla({super.key});

  @override
  State<ComplejidadPantalla> createState() => _ComplejidadPantallaState();
}

class _ComplejidadPantallaState extends State<ComplejidadPantalla> {
  static const List<_Algoritmo> _algoritmos = [
    _Algoritmo('Acceso a un conteo', 'Leer un indicador ya calculado', 'O(1)', 'P'),
    _Algoritmo('Búsqueda binaria', 'Ubicar un año en los datos ordenados', 'O(log n)', 'P'),
    _Algoritmo('Filtrado y agregación', 'Actualizar panel, gráficos y mapa', 'O(n)', 'P'),
    _Algoritmo('Merge Sort', 'Rankings de comunas y barrios', 'O(n log n)', 'P'),
    _Algoritmo('Planificador voraz', 'Plan aproximado, mínimo 50 % del óptimo', 'O(k·m·s)', 'P'),
    _Algoritmo('Verificar un plan', 'Comprobar cuánto cubre un plan dado', 'O(k·s)', 'P'),
    _Algoritmo('Planificador exacto', 'Plan óptimo de operativos', 'O(C(m,k))', 'NP-difícil'),
  ];

  bool _midiendo = false;
  ReporteComplejidad? _reporte;

  Future<void> _medir() async {
    setState(() => _midiendo = true);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;
    final reporte = await ProveedorControlador.de(context).medirComplejidad();
    if (!mounted) return;
    setState(() {
      _reporte = reporte;
      _midiendo = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reporte = _reporte;

    return Scaffold(
      appBar: AppBar(title: const Text('Complejidad algorítmica', style: TextStyle(fontSize: 17))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const TituloSeccion('Conclusión'),
          const Tarjeta(
            child: Text(
              'Todas las consultas de la app están en P. El planificador resuelve '
              'Cobertura Máxima: su versión de optimización es NP-difícil y su '
              'versión de decisión es NP-completa.',
              style: TextStyle(fontSize: 14, height: 1.45),
            ),
          ),
          const TituloSeccion(
            'Algoritmos del sistema',
            detalle: 'n: registros · k: operativos · m: candidatos · s: celdas por candidato',
          ),
          for (final algoritmo in _algoritmos)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Tarjeta(
                relleno: 10,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            algoritmo.nombre,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            algoritmo.uso,
                            style: const TextStyle(fontSize: 12, color: Colores.textoSuave),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          algoritmo.complejidad,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          algoritmo.clase,
                          style: TextStyle(
                            fontSize: 12,
                            color: algoritmo.clase == 'P' ? Colores.exito : Colores.peligro,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: _midiendo ? null : _medir,
              icon: const Icon(Icons.speed),
              label: Text(_midiendo ? 'Midiendo…' : 'Medir en este dispositivo'),
            ),
          ),
          if (reporte != null) ..._resultados(reporte),
        ],
      ),
    );
  }

  List<Widget> _resultados(ReporteComplejidad reporte) {
    return [
      const TituloSeccion(
        'Tiempo según la cantidad de registros',
        detalle: 'Mediana de 7 repeticiones, en microsegundos.',
      ),
      Tarjeta(
        child: GraficoLineas(
          etiquetas: [for (final t in reporte.tamanos) formatoNumero(t.n)],
          series: [
            SerieLinea(
              'Merge Sort, O(n log n)',
              Colores.peligro,
              [for (final t in reporte.tamanos) t.ordenamientoUs],
            ),
            SerieLinea(
              'Filtrado, O(n)',
              Colores.primario,
              [for (final t in reporte.tamanos) t.filtradoUs],
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Tarjeta(
        child: Column(
          children: [
            for (final t in reporte.tamanos)
              _Fila(
                'Búsqueda binaria, n = ${formatoNumero(t.n)}',
                '${formatoDecimal(t.busquedaUs, decimales: 3)} µs',
              ),
          ],
        ),
      ),
      const TituloSeccion(
        'Planificador según los operativos',
        detalle: 'El exacto se detiene a los 3 segundos si no termina.',
      ),
      Tarjeta(
        child: Column(
          children: [
            for (final p in reporte.planes)
              _Fila(
                'k = ${p.k} · ${formatoNumero(p.nodos)} estados',
                '${formatoMicrosegundos(p.exactoUs)}${p.optimoDemostrado ? '' : ' (límite)'} · '
                    'voraz ${formatoDecimal(p.calidadVoraz * 100)} %',
              ),
          ],
        ),
      ),
    ];
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.titulo, this.valor);

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(titulo, style: const TextStyle(fontSize: 12))),
          const SizedBox(width: 8),
          Text(valor, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
