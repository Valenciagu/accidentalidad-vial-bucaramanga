import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/formato.dart';
import '../tema.dart';
import 'comunes.dart';

const TextStyle _estiloEje = TextStyle(fontSize: 10, color: Colores.textoSuave);

/// Múltiplo "redondo" para que el eje vertical sea legible.
double _intervaloEje(double maximo) {
  if (maximo <= 5) return 1;
  final base = math.pow(10, (math.log(maximo) / math.ln10).floor()).toDouble();
  for (final factor in const [0.1, 0.2, 0.25, 0.5, 1.0, 2.0]) {
    if (maximo / (base * factor) <= 5) return base * factor;
  }
  return base * 2;
}

SideTitles _ejeVertical(double intervalo, {String Function(double)? formato}) {
  return SideTitles(
    showTitles: true,
    reservedSize: 40,
    interval: intervalo,
    getTitlesWidget: (valor, meta) {
      if (valor == meta.max && valor % intervalo != 0) return const SizedBox.shrink();
      return Text(
        formato?.call(valor) ?? formatoNumero(valor.round()),
        style: _estiloEje,
      );
    },
  );
}

class BarrasVerticales extends StatelessWidget {
  const BarrasVerticales({
    super.key,
    required this.valores,
    required this.etiquetas,
    this.alto = 170,
    this.cadaEtiquetas = 1,
  });

  final List<int> valores;
  final List<String> etiquetas;
  final double alto;

  /// Muestra una de cada n etiquetas cuando hay muchas barras.
  final int cadaEtiquetas;

  @override
  Widget build(BuildContext context) {
    if (valores.every((v) => v == 0)) return const SinDatos();
    final maximo = valores.reduce(math.max).toDouble();
    final intervalo = _intervaloEje(maximo);

    return SizedBox(
      height: alto,
      child: LayoutBuilder(
        builder: (context, limites) {
          final ancho = (limites.maxWidth - 40) / valores.length * 0.62;
          return BarChart(
            BarChartData(
              maxY: maximo * 1.1,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: intervalo,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Colores.borde, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(sideTitles: _ejeVertical(intervalo)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (valor, meta) {
                      final i = valor.toInt();
                      if (i % cadaEtiquetas != 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(etiquetas[i], style: _estiloEje),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (grupo, _, vara, _) => BarTooltipItem(
                    '${etiquetas[grupo.x]}\n${formatoNumero(vara.toY.round())}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < valores.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: valores[i].toDouble(),
                        width: math.max(ancho, 2),
                        color: Colores.primario,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SerieLinea {
  const SerieLinea(this.nombre, this.color, this.valores);

  final String nombre;
  final Color color;
  final List<double> valores;
}

class GraficoLineas extends StatelessWidget {
  const GraficoLineas({
    super.key,
    required this.series,
    required this.etiquetas,
    this.alto = 180,
    this.formatoEje,
    this.cadaEtiquetas = 1,
  });

  final List<SerieLinea> series;
  final List<String> etiquetas;
  final double alto;
  final String Function(double)? formatoEje;
  final int cadaEtiquetas;

  @override
  Widget build(BuildContext context) {
    final todos = [for (final serie in series) ...serie.valores];
    if (todos.every((v) => v == 0)) return const SinDatos();
    final maximo = todos.reduce(math.max);
    final intervalo = _intervaloEje(maximo);

    return Column(
      children: [
        SizedBox(
          height: alto,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maximo * 1.1,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: intervalo,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Colores.borde, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: _ejeVertical(intervalo, formato: formatoEje),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (valor, meta) {
                      final i = valor.toInt();
                      if (i != valor || i % cadaEtiquetas != 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(etiquetas[i], style: _estiloEje),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                for (final serie in series)
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < serie.valores.length; i++)
                        FlSpot(i.toDouble(), serie.valores[i]),
                    ],
                    color: serie.color,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                  ),
              ],
            ),
          ),
        ),
        if (series.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 14,
              children: [
                for (final serie in series)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 10, height: 10, color: serie.color),
                      const SizedBox(width: 5),
                      Text(serie.nombre, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
