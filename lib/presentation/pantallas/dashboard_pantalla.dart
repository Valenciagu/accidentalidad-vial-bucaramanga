import 'package:flutter/material.dart';

import '../../core/formato.dart';
import '../../domain/entidades/catalogos.dart';
import '../../domain/entidades/conjunto_accidentes.dart';
import '../../domain/entidades/resumen.dart';
import '../app.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import '../widgets/graficos.dart';

/// Panel principal (RF-04, RF-09). Todo sale del resumen de los filtros activos.
class DashboardPantalla extends StatefulWidget {
  const DashboardPantalla({super.key, required this.alAbrirFiltros});

  final VoidCallback alAbrirFiltros;

  @override
  State<DashboardPantalla> createState() => _DashboardPantallaState();
}

class _DashboardPantallaState extends State<DashboardPantalla> {
  int _periodo = 0;

  @override
  Widget build(BuildContext context) {
    final controlador = ProveedorControlador.de(context);
    final resumen = controlador.resumen;
    final comparacion = controlador.comparacion;
    final datos = controlador.datos;
    final dia = resumen.diaPrincipal;
    final franja = resumen.franjaPrincipal;
    final vehiculo = resumen.vehiculoPrincipal;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '¡Hola, usuario!',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Consulta y analiza la información de accidentes de tránsito en Bucaramanga.',
          style: TextStyle(fontSize: 13, color: Colores.textoSuave, height: 1.35),
        ),
        const SizedBox(height: 12),
        if (!controlador.filtros.vacio) ...[
          _BarraFiltros(
            cantidad: controlador.filtros.cantidadActivos,
            alEditar: widget.alAbrirFiltros,
            alLimpiar: controlador.limpiarFiltros,
          ),
          const SizedBox(height: 12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Indicador(
                icono: Icons.directions_car_outlined,
                valor: formatoNumero(resumen.total),
                titulo: 'Total de accidentes',
                variacion: comparacion?.variacionTotal,
                detalle: comparacion == null ? '${datos.anioMinimo}–${datos.anioMaximo}' : null,
                referencia: comparacion,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Indicador(
                icono: Icons.warning_amber_rounded,
                colorIcono: Colores.peligro,
                valor: formatoNumero(resumen.graves),
                titulo: 'Accidentes graves',
                variacion: comparacion?.variacionGraves,
                detalle: comparacion == null ? 'Con heridos o fallecidos' : null,
                referencia: comparacion,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Indicador(
                icono: Icons.calendar_month_outlined,
                valor: dia == null ? '—' : nombresDias[dia],
                titulo: 'Mayor frecuencia',
                detalle: franja == null
                    ? null
                    : '${formatoHora(franja)} a ${formatoHora((franja + 2) % 24)}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Indicador(
                icono: vehiculo?.indice == vehiculoMoto
                    ? Icons.two_wheeler
                    : Icons.directions_car_filled_outlined,
                valor: vehiculo?.nombre ?? '—',
                titulo: 'Vehículo más involucrado',
                detalle: vehiculo == null
                    ? null
                    : '${formatoDecimal(resumen.porcentaje(vehiculo.cantidad))} % de los accidentes',
              ),
            ),
          ],
        ),
        if (comparacion?.periodoParcial ?? false) ...[
          const SizedBox(height: 10),
          Aviso(
            '${comparacion!.anioReferencia + 1} está incompleto: se compara '
            'contra los mismos meses de ${comparacion.anioReferencia}.',
          ),
        ],
        const TituloSeccion('Distribución de accidentes'),
        Segmentos(
          opciones: const ['Últimos 12 meses', 'Últimos 3 años', 'Todo el período'],
          seleccionado: _periodo,
          alCambiar: (valor) => setState(() => _periodo = valor),
        ),
        const SizedBox(height: 10),
        Tarjeta(child: _distribucion(resumen, datos, controlador.filtros.anioHasta)),
        const TituloSeccion('Gravedad'),
        Tarjeta(child: _Gravedad(resumen: resumen)),
        const TituloSeccion('Vehículos involucrados'),
        Tarjeta(
          child: BarrasHorizontales(
            items: controlador.vehiculosOrdenados(),
            total: resumen.total,
          ),
        ),
        const TituloSeccion('Cantidad de vehículos por accidente'),
        Tarjeta(
          child: BarrasVerticales(
            valores: resumen.porCantidadVehiculos,
            etiquetas: etiquetasCantidadVehiculos,
            alto: 140,
          ),
        ),
        const TituloSeccion(
          'Tipo de accidente',
          detalle: 'Derivado de los actores registrados: el dataset no trae este campo.',
        ),
        Tarjeta(
          child: BarrasHorizontales(
            items: [
              for (var i = 0; i < nombresTipoAccidente.length; i++)
                ItemRanking(indice: i, nombre: nombresTipoAccidente[i], cantidad: resumen.porTipo[i]),
            ],
            total: resumen.total,
          ),
        ),
      ],
    );
  }

  /// La ventana termina en el último mes del año filtrado o del dataset.
  Widget _distribucion(Resumen resumen, ConjuntoAccidentes datos, int? anioFiltrado) {
    final anioMinimo = datos.anioMinimo;
    final anioFinal = anioFiltrado ?? datos.anioMaximo;
    final finSerie = (anioFinal - anioMinimo) * 12 + datos.ultimoMesDe(anioFinal);

    if (_periodo == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SubtituloGrafico('Accidentes por año'),
          BarrasVerticales(
            valores: resumen.porAnio,
            etiquetas: [
              for (var i = 0; i < resumen.porAnio.length; i++)
                "'${(anioMinimo + i).toString().substring(2)}",
            ],
          ),
        ],
      );
    }

    final meses = _periodo == 0 ? 12 : 36;
    final inicio = finSerie > meses ? finSerie - meses : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SubtituloGrafico('Accidentes por mes'),
        BarrasVerticales(
          valores: resumen.serieMensual.sublist(inicio, finSerie),
          etiquetas: [
            for (var i = inicio; i < finSerie; i++) mesesCortos[i % 12],
          ],
          cadaEtiquetas: _periodo == 0 ? 1 : 6,
        ),
      ],
    );
  }
}

class _SubtituloGrafico extends StatelessWidget {
  const _SubtituloGrafico(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(texto, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

class _BarraFiltros extends StatelessWidget {
  const _BarraFiltros({
    required this.cantidad,
    required this.alEditar,
    required this.alLimpiar,
  });

  final int cantidad;
  final VoidCallback alEditar;
  final VoidCallback alLimpiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: Colores.primarioSuave,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune, size: 16, color: Colores.primario),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cantidad == 1 ? '1 filtro activo' : '$cantidad filtros activos',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(onPressed: alEditar, child: const Text('Editar')),
          TextButton(onPressed: alLimpiar, child: const Text('Limpiar')),
        ],
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.icono,
    required this.valor,
    required this.titulo,
    this.colorIcono = Colores.encabezado,
    this.variacion,
    this.detalle,
    this.referencia,
  });

  final IconData icono;
  final Color colorIcono;
  final String valor;
  final String titulo;
  final double? variacion;
  final String? detalle;
  final Comparacion? referencia;

  @override
  Widget build(BuildContext context) {
    final cambio = variacion;
    return Tarjeta(
      child: SizedBox(
        height: 122,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 28, color: colorIcono),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                valor,
                maxLines: 1,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colores.texto),
            ),
            const SizedBox(height: 4),
            if (cambio != null)
              Row(
                children: [
                  Icon(
                    cambio >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 13,
                    // Menos accidentes es una buena noticia.
                    color: cambio >= 0 ? Colores.peligro : Colores.exito,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      '${formatoDecimal(cambio.abs())} % vs. ${referencia!.anioReferencia}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: cambio >= 0 ? Colores.peligro : Colores.exito,
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(
                detalle ?? 'Sin año anterior para comparar',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colores.textoSuave),
              ),
          ],
        ),
      ),
    );
  }
}

class _Gravedad extends StatelessWidget {
  const _Gravedad({required this.resumen});

  final Resumen resumen;

  static const List<Color> _colores = [
    Colores.primario,
    Colores.alerta,
    Colores.peligro,
  ];

  @override
  Widget build(BuildContext context) {
    if (resumen.total == 0) return const SinDatos();

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  if (resumen.porGravedad[i] > 0)
                    Expanded(
                      flex: resumen.porGravedad[i],
                      child: Container(color: _colores[i]),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: _colores[i], shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(nombresGravedad[i], style: const TextStyle(fontSize: 13))),
                Text(
                  '${formatoNumero(resumen.porGravedad[i])} · '
                  '${formatoDecimal(resumen.porcentaje(resumen.porGravedad[i]))} %',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
