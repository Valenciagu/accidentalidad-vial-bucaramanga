import 'package:flutter/material.dart';

import '../../core/formato.dart';
import '../../domain/casos_uso/planificar_operativos.dart';
import '../../domain/entidades/catalogos.dart';
import '../app.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

/// Recomienda dónde ubicar operativos. Solo informa: no actúa sobre la vía.
class PlanificadorPantalla extends StatefulWidget {
  const PlanificadorPantalla({super.key});

  @override
  State<PlanificadorPantalla> createState() => _PlanificadorPantallaState();
}

class _PlanificadorPantallaState extends State<PlanificadorPantalla> {
  static const List<double> _alcances = [1, 1.5, 2, 3];
  static const List<int> _duraciones = [2, 4, 6];
  static const int _limiteMicrosegundos = 3000000;

  int _k = 3;
  int _alcance = 1;
  int _duracion = 1;
  bool _calculando = false;
  PlanOperativos? _plan;

  Future<void> _calcular() async {
    setState(() => _calculando = true);
    // Deja pintar el indicador antes de ocupar el hilo en la versión web.
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;
    final plan = await ProveedorControlador.de(context).planificar(
      ParametrosPlan(
        k: _k,
        alcanceKm: _alcances[_alcance],
        duracionHoras: _duraciones[_duracion],
        limiteMicrosegundos: _limiteMicrosegundos,
      ),
    );
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _calculando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controlador = ProveedorControlador.de(context);
    final plan = _plan;

    return Scaffold(
      appBar: AppBar(title: const Text('Planificador de operativos', style: TextStyle(fontSize: 17))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '¿Dónde, qué día y a qué hora ubicar los operativos para cubrir la mayor '
            'cantidad de accidentes históricos?',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 8),
          Aviso(
            controlador.filtros.vacio
                ? 'Usa todos los accidentes. Aplica filtros para planificar, por '
                    'ejemplo, solo accidentes graves o de moto.'
                : 'Usa los ${formatoNumero(controlador.resumen.total)} accidentes '
                    'de los filtros activos.',
          ),
          const SizedBox(height: 12),
          Tarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operativos disponibles: $_k',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: _k.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  label: '$_k',
                  onChanged: (valor) => setState(() => _k = valor.round()),
                ),
                const Text(
                  'Alcance de cada operativo',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Segmentos(
                  opciones: [for (final a in _alcances) '${formatoDecimal(a)} km'],
                  seleccionado: _alcance,
                  alCambiar: (valor) => setState(() => _alcance = valor),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Duración',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Segmentos(
                  opciones: [for (final d in _duraciones) '$d horas'],
                  seleccionado: _duracion,
                  alCambiar: (valor) => setState(() => _duracion = valor),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: _calculando || controlador.resumen.total == 0 ? null : _calcular,
                    icon: const Icon(Icons.shield_outlined),
                    label: Text(_calculando ? 'Calculando…' : 'Calcular plan'),
                  ),
                ),
              ],
            ),
          ),
          if (plan != null) ..._resultado(plan),
        ],
      ),
    );
  }

  List<Widget> _resultado(PlanOperativos plan) {
    final comunas = ProveedorControlador.de(context).datos.catalogoComunas;
    return [
      TituloSeccion(
        'Plan recomendado',
        detalle: 'Cubre ${formatoNumero(plan.exacto.valor)} de '
            '${formatoNumero(plan.pesoTotal)} accidentes '
            '(${formatoDecimal(plan.porcentajeCubierto)} %)',
      ),
      for (var i = 0; i < plan.operativos.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Tarjeta(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: Colores.primarioSuave,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colores.primario,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comunas[plan.operativos[i].comuna].etiqueta,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${nombresDias[plan.operativos[i].dia]}, '
                        '${formatoHora(plan.operativos[i].horaInicio)} a '
                        '${formatoHora(plan.operativos[i].horaFin)} · también cubre: '
                        '${_vecinas(plan.operativos[i])}',
                        style: const TextStyle(fontSize: 12, color: Colores.textoSuave),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      const TituloSeccion('Cómo se calculó'),
      Tarjeta(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Linea('Combinaciones posibles', formatoGrande(plan.espacioBusqueda)),
            _Linea('Estados explorados (exacto)', formatoNumero(plan.exacto.nodos)),
            _Linea('Tiempo exacto', formatoMicrosegundos(plan.exacto.microsegundos)),
            _Linea('Tiempo voraz', formatoMicrosegundos(plan.voraz.microsegundos)),
            _Linea('Calidad del voraz', '${formatoDecimal(plan.calidadVoraz * 100)} % del óptimo'),
            const SizedBox(height: 8),
            Aviso(
              plan.exacto.optimoDemostrado
                  ? 'Óptimo demostrado: ningún otro plan cubre más. La poda evitó '
                      'revisar todas las combinaciones.'
                  : 'Se agotó el tiempo: es el mejor plan encontrado, pero no está '
                      'demostrado que sea el óptimo.',
            ),
          ],
        ),
      ),
    ];
  }

  String _vecinas(Operativo operativo) {
    final comunas = ProveedorControlador.de(context).datos.catalogoComunas;
    final otras = [
      for (final indice in operativo.comunasCubiertas)
        if (indice != operativo.comuna) comunas[indice].nombre,
    ];
    return otras.isEmpty ? 'ninguna otra comuna' : otras.join(', ');
  }
}

class _Linea extends StatelessWidget {
  const _Linea(this.titulo, this.valor);

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(titulo, style: const TextStyle(fontSize: 13))),
          const SizedBox(width: 8),
          Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
