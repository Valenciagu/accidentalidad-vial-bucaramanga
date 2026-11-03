import 'package:flutter/material.dart';

import '../../core/formato.dart';
import '../../domain/entidades/resumen.dart';
import '../tema.dart';

class Tarjeta extends StatelessWidget {
  const Tarjeta({super.key, required this.child, this.relleno = 14});

  final Widget child;
  final double relleno;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(relleno),
      decoration: BoxDecoration(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colores.borde),
      ),
      child: child,
    );
  }
}

class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key, this.detalle});

  final String texto;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texto,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colores.texto,
            ),
          ),
          if (detalle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                detalle!,
                style: const TextStyle(fontSize: 12, color: Colores.textoSuave),
              ),
            ),
        ],
      ),
    );
  }
}

class Aviso extends StatelessWidget {
  const Aviso(this.texto, {super.key, this.icono = Icons.info_outline});

  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colores.primarioSuave,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: Colores.primario),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 12, color: Colores.texto, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de barras horizontales con nombre y cantidad.
class BarrasHorizontales extends StatelessWidget {
  const BarrasHorizontales({super.key, required this.items, this.total});

  final List<ItemRanking> items;

  /// Si se indica, muestra el porcentaje de cada barra sobre este total.
  final int? total;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SinDatos();
    final mayor = items.map((i) => i.cantidad).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.nombre,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Colores.texto),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      total == null || total == 0
                          ? formatoNumero(item.cantidad)
                          : '${formatoNumero(item.cantidad)} · '
                              '${formatoDecimal(item.cantidad * 100 / total!)} %',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colores.texto,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: mayor == 0 ? 0 : item.cantidad / mayor,
                    minHeight: 6,
                    backgroundColor: Colores.primarioSuave,
                    color: Colores.primario,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class SinDatos extends StatelessWidget {
  const SinDatos({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'No hay accidentes con los filtros aplicados.',
          style: TextStyle(color: Colores.textoSuave, fontSize: 13),
        ),
      ),
    );
  }
}

/// Selector de opciones excluyentes, como en los mockups.
class Segmentos extends StatelessWidget {
  const Segmentos({
    super.key,
    required this.opciones,
    required this.seleccionado,
    required this.alCambiar,
  });

  final List<String> opciones;
  final int seleccionado;
  final ValueChanged<int> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < opciones.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
              child: Material(
                color: i == seleccionado ? Colores.primario : Colores.superficie,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => alCambiar(i),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: i == seleccionado ? Colores.primario : Colores.borde,
                      ),
                    ),
                    child: Text(
                      opciones[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: i == seleccionado ? Colors.white : Colores.textoSuave,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
