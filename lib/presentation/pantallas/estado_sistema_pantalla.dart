import 'package:flutter/material.dart';

import '../../core/formato.dart';
import '../app.dart';
import '../controladores/controlador_app.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

/// Estado del sistema (RF-11) y resultado de la depuración de datos (RF-02).
class EstadoSistemaPantalla extends StatefulWidget {
  const EstadoSistemaPantalla({super.key});

  @override
  State<EstadoSistemaPantalla> createState() => _EstadoSistemaPantallaState();
}

class _EstadoSistemaPantallaState extends State<EstadoSistemaPantalla> {
  ControladorApp? _controlador;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controlador == null) {
      _controlador = ProveedorControlador.de(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controlador!.verificarServicios();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controlador = ProveedorControlador.de(context);
    final datos = controlador.datos;
    final reporte = datos.reporte;
    final servicios = controlador.servicios;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado del sistema', style: TextStyle(fontSize: 17)),
        actions: [
          IconButton(
            tooltip: 'Verificar de nuevo',
            icon: const Icon(Icons.refresh),
            onPressed: controlador.verificandoServicios ? null : controlador.verificarServicios,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const TituloSeccion('Datos locales'),
          Tarjeta(
            child: Column(
              children: [
                _Fila('Estado', 'Disponibles sin conexión', color: Colores.exito),
                _Fila('Registros cargados', formatoNumero(datos.n)),
                _Fila('Reales (CSV)', formatoNumero(datos.reales)),
                _Fila('Sintéticos', formatoNumero(datos.sinteticos)),
                _Fila(
                  'Cantidad configurada',
                  formatoNumero(controlador.cantidad.pedida),
                  color: controlador.cantidad.corregida ? Colores.peligro : Colores.texto,
                ),
                _Fila('Tiempo de carga', '${formatoNumero(controlador.tiempoCargaMs)} ms'),
                _Fila('Última consulta', formatoMicrosegundos(controlador.tiempoConsultaUs)),
              ],
            ),
          ),
          const TituloSeccion(
            'Conexión',
            detalle: 'Solo el mapa la necesita. Consultas y gráficos funcionan sin internet.',
          ),
          if (servicios == null)
            const Tarjeta(child: Center(child: CircularProgressIndicator()))
          else
            for (final servicio in servicios)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Tarjeta(
                  child: Row(
                    children: [
                      Icon(
                        servicio.disponible ? Icons.check_circle : Icons.error_outline,
                        color: servicio.disponible ? Colores.exito : Colores.peligro,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              servicio.nombre,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              servicio.descripcion,
                              style: const TextStyle(fontSize: 12, color: Colores.textoSuave),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        servicio.disponible ? '${servicio.latenciaMs} ms' : 'Sin conexión',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          const TituloSeccion('Calidad de los datos', detalle: 'Resultado de la limpieza (RF-02)'),
          Tarjeta(
            child: Column(
              children: [
                _Fila('Filas del archivo original', formatoNumero(reporte.valor('filas_originales'))),
                _Fila('Duplicados eliminados', formatoNumero(reporte.valor('duplicados_eliminados'))),
                _Fila('Gravedades estandarizadas', formatoNumero(reporte.valor('gravedades_estandarizadas'))),
                _Fila('Barrios estandarizados', formatoNumero(reporte.valor('barrios_estandarizados'))),
                _Fila('Horas recuperadas', formatoNumero(reporte.valor('horas_recuperadas'))),
                _Fila('Fechas inconsistentes', formatoNumero(reporte.valor('fechas_inconsistentes'))),
                _Fila('Vehículos atípicos', formatoNumero(reporte.valor('vehiculos_atipicos'))),
                _Fila('Sin comuna ni barrio', formatoNumero(reporte.valor('sin_ubicacion'))),
                _Fila('Con comuna, sin barrio', formatoNumero(reporte.valor('barrios_invalidos'))),
                _Fila('Filas finales', formatoNumero(reporte.valor('filas_limpias'))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.titulo, this.valor, {this.color = Colores.texto});

  final String titulo;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(titulo, style: const TextStyle(fontSize: 13))),
          Text(
            valor,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
