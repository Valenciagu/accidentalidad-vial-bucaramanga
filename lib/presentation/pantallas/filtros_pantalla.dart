import 'package:flutter/material.dart';

import '../../domain/entidades/catalogos.dart';
import '../../domain/entidades/filtros.dart';
import '../app.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

/// Pantalla de filtros (RF-05, RF-06). Los cambios se aplican con el botón.
class FiltrosPantalla extends StatefulWidget {
  const FiltrosPantalla({super.key, required this.alAplicar});

  final VoidCallback alAplicar;

  @override
  State<FiltrosPantalla> createState() => _FiltrosPantallaState();
}

class _FiltrosPantallaState extends State<FiltrosPantalla> {
  int? _anio;
  int? _mes;
  int? _dia;
  int? _hora;
  int? _comuna;
  int? _gravedad;
  int? _vehiculo;
  Filtros? _ultimos;

  // Códigos del desplegable de hora: las jornadas van después de las 24 horas.
  static const int _baseJornadas = 100;
  static const int _opcionGraves = 3;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final actuales = ProveedorControlador.de(context).filtros;
    if (!identical(actuales, _ultimos)) _sincronizar(actuales);
  }

  /// Muestra lo que está aplicado, incluso si vino del asistente.
  void _sincronizar(Filtros f) {
    _ultimos = f;
    _anio = f.anioUnico ? f.anioDesde : null;
    _mes = f.mes;
    _dia = null;
    for (var i = 0; i < 7; i++) {
      if (f.mascaraDias == 1 << i) _dia = i + 1;
    }
    _hora = null;
    if (f.horaDesde != null) {
      if (f.horaDesde == f.horaHasta) {
        _hora = f.horaDesde;
      } else {
        for (var i = 0; i < jornadas.length; i++) {
          if (jornadas[i].desde == f.horaDesde && jornadas[i].hasta == f.horaHasta) {
            _hora = _baseJornadas + i;
          }
        }
      }
    }
    _comuna = f.comuna;
    _gravedad = null;
    if (f.mascaraGravedad == mascaraGraves) {
      _gravedad = _opcionGraves;
    } else {
      for (var i = 0; i < 3; i++) {
        if (f.mascaraGravedad == 1 << i) _gravedad = i;
      }
    }
    _vehiculo = f.vehiculo;
  }

  Filtros _construir() {
    final jornada = _hora != null && _hora! >= _baseJornadas
        ? jornadas[_hora! - _baseJornadas]
        : null;
    return Filtros(
      anioDesde: _anio,
      anioHasta: _anio,
      mes: _mes,
      mascaraDias: _dia == null ? null : 1 << (_dia! - 1),
      horaDesde: jornada?.desde ?? _hora,
      horaHasta: jornada?.hasta ?? _hora,
      comuna: _comuna,
      mascaraGravedad: _gravedad == null
          ? null
          : _gravedad == _opcionGraves
              ? mascaraGraves
              : 1 << _gravedad!,
      vehiculo: _vehiculo,
    );
  }

  void _aplicar() {
    final controlador = ProveedorControlador.de(context);
    final filtros = _construir();
    _ultimos = filtros;
    controlador.aplicarFiltros(filtros);
    widget.alAplicar();
  }

  void _limpiar() {
    final controlador = ProveedorControlador.de(context);
    setState(() => _sincronizar(Filtros.ninguno));
    _ultimos = Filtros.ninguno;
    controlador.limpiarFiltros();
  }

  @override
  Widget build(BuildContext context) {
    final datos = ProveedorControlador.de(context).datos;
    final comunas = datos.catalogoComunas;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            children: [
              _Campo<int>(
                icono: Icons.calendar_today_outlined,
                titulo: 'Año',
                todos: 'Todos',
                valor: _anio,
                opciones: {
                  for (var a = datos.anioMaximo; a >= datos.anioMinimo; a--) a: '$a',
                },
                alCambiar: (v) => setState(() => _anio = v),
              ),
              _Campo<int>(
                icono: Icons.calendar_month_outlined,
                titulo: 'Mes',
                todos: 'Todos',
                valor: _mes,
                opciones: {
                  for (var m = 1; m <= 12; m++) m: nombresMeses[m - 1],
                },
                alCambiar: (v) => setState(() => _mes = v),
              ),
              _Campo<int>(
                icono: Icons.today_outlined,
                titulo: 'Día',
                todos: 'Todos',
                valor: _dia,
                opciones: {
                  for (var d = 1; d <= 7; d++) d: nombresDias[d - 1],
                },
                alCambiar: (v) => setState(() => _dia = v),
              ),
              _Campo<int>(
                icono: Icons.schedule,
                titulo: 'Hora',
                todos: 'Todas',
                valor: _hora,
                opciones: {
                  for (var i = 0; i < jornadas.length; i++)
                    _baseJornadas + i: jornadas[i].etiqueta,
                  for (var h = 0; h < 24; h++)
                    h: '${h.toString().padLeft(2, '0')}:00-${h.toString().padLeft(2, '0')}:59',
                },
                alCambiar: (v) => setState(() => _hora = v),
              ),
              _Campo<int>(
                icono: Icons.location_on_outlined,
                titulo: 'Comuna',
                todos: 'Todas',
                valor: _comuna,
                opciones: {
                  for (var i = 0; i < comunas.length; i++) i: comunas[i].etiqueta,
                },
                alCambiar: (v) => setState(() => _comuna = v),
              ),
              _Campo<int>(
                icono: Icons.warning_amber_rounded,
                titulo: 'Gravedad',
                todos: 'Todas',
                valor: _gravedad,
                opciones: {
                  for (var i = 0; i < nombresGravedad.length; i++) i: nombresGravedad[i],
                  _opcionGraves: 'Graves (heridos o fallecidos)',
                },
                alCambiar: (v) => setState(() => _gravedad = v),
              ),
              _Campo<int>(
                icono: Icons.directions_car_outlined,
                titulo: 'Tipo de vehículo',
                todos: 'Todos',
                valor: _vehiculo,
                opciones: {
                  for (var i = 0; i < nombresVehiculos.length; i++) i: nombresVehiculos[i],
                },
                alCambiar: (v) => setState(() => _vehiculo = v),
              ),
            ],
          ),
        ),
        Container(
          color: Colores.superficie,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: _aplicar,
                  icon: const Icon(Icons.search),
                  label: const Text('Aplicar filtros'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _limpiar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Limpiar filtros'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Campo<T> extends StatelessWidget {
  const _Campo({
    required this.icono,
    required this.titulo,
    required this.todos,
    required this.valor,
    required this.opciones,
    required this.alCambiar,
  });

  final IconData icono;
  final String titulo;
  final String todos;
  final T? valor;
  final Map<T, String> opciones;
  final ValueChanged<T?> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Tarjeta(
        relleno: 10,
        child: Row(
          children: [
            Icon(icono, color: Colores.encabezado),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<T?>(
                    key: ValueKey('$titulo-$valor'),
                    initialValue: valor,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 13, color: Colores.texto),
                    items: [
                      DropdownMenuItem<T?>(value: null, child: Text(todos)),
                      for (final opcion in opciones.entries)
                        DropdownMenuItem<T?>(
                          value: opcion.key,
                          child: Text(opcion.value, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: alCambiar,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
