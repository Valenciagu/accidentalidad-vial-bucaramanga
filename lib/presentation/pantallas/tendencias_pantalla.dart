import 'package:flutter/material.dart';

import '../../domain/entidades/catalogos.dart';
import '../app.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import '../widgets/graficos.dart';

/// Tendencias temporales (RF-07), siempre según los filtros activos.
class TendenciasPantalla extends StatelessWidget {
  const TendenciasPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final controlador = ProveedorControlador.de(context);
    final resumen = controlador.resumen;
    final datos = controlador.datos;
    final anios = [
      for (var i = 0; i < resumen.porAnio.length; i++)
        "'${(datos.anioMinimo + i).toString().substring(2)}",
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const TituloSeccion('Por año'),
        Tarjeta(
          child: GraficoLineas(
            series: [
              SerieLinea(
                'Accidentes',
                Colores.primario,
                [for (final valor in resumen.porAnio) valor.toDouble()],
              ),
            ],
            etiquetas: anios,
          ),
        ),
        const SizedBox(height: 8),
        Aviso(
          '2023 llega hasta ${nombresMeses[datos.ultimoMes - 1].toLowerCase()} y los '
          'registros caen desde agosto de 2022, posiblemente por subregistro. '
          'Esos valores no son comparables con años anteriores.',
          icono: Icons.warning_amber_rounded,
        ),
        const TituloSeccion('Por mes del año'),
        Tarjeta(child: BarrasVerticales(valores: resumen.porMes, etiquetas: mesesCortos)),
        const TituloSeccion('Por día de la semana'),
        Tarjeta(child: BarrasVerticales(valores: resumen.porDia, etiquetas: diasCortos)),
        const TituloSeccion('Por hora del día'),
        Tarjeta(
          child: BarrasVerticales(
            valores: resumen.porHora,
            etiquetas: [for (var h = 0; h < 24; h++) '$h'],
            cadaEtiquetas: 3,
          ),
        ),
        const TituloSeccion('Por jornada'),
        Tarjeta(
          child: BarrasVerticales(
            valores: [
              for (final jornada in jornadas)
                resumen.porHora
                    .sublist(jornada.desde, jornada.hasta + 1)
                    .fold(0, (suma, valor) => suma + valor),
            ],
            etiquetas: [for (final jornada in jornadas) jornada.nombre],
            alto: 150,
          ),
        ),
      ],
    );
  }
}
