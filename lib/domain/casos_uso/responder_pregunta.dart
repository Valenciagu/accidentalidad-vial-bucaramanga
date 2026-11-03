import '../../core/formato.dart';
import '../asistente/interprete_preguntas.dart';
import '../entidades/catalogos.dart';
import '../entidades/conjunto_accidentes.dart';
import '../entidades/filtros.dart';
import '../entidades/resumen.dart';
import 'consultar_accidentes.dart';
import 'generar_ranking.dart';

class RespuestaAsistente {
  const RespuestaAsistente({
    required this.texto,
    this.items = const [],
    this.filtros,
    this.datosInsuficientes = false,
  });

  final String texto;
  final List<ItemRanking> items;

  /// Filtros que se pueden llevar al panel principal.
  final Filtros? filtros;
  final bool datosInsuficientes;
}

/// Responde preguntas calculando sobre los datos reales.
///
/// Complejidad: O(q) para interpretar, O(n) para consultar y O(c log c) para
/// ordenar, con q palabras, n registros y c categorías. Las cifras siempre
/// salen de los datos; nunca de texto generado.
class ResponderPregunta {
  ResponderPregunta(
    this._datos,
    this._consultar,
    this._ranking,
  ) : _interprete = InterpretePreguntas(_datos);

  final ConjuntoAccidentes _datos;
  final ConsultarAccidentes _consultar;
  final GenerarRanking _ranking;
  final InterpretePreguntas _interprete;

  static const List<String> sugerencias = [
    '¿Qué comuna tiene más accidentes?',
    '¿A qué hora ocurren más accidentes con moto?',
    'Compara 2019 y 2020',
    '¿Cuántos accidentes con fallecidos hubo en 2018?',
    'Top 5 barrios con más accidentes graves',
  ];

  RespuestaAsistente call(String pregunta) {
    final consulta = _interprete.interpretar(pregunta);
    return switch (consulta.tipo) {
      TipoPregunta.saludo => const RespuestaAsistente(
        texto: 'Hola. Puedo responder preguntas sobre los accidentes registrados '
            'en Bucaramanga: cuántos, dónde, cuándo, con qué vehículo y con qué '
            'gravedad. Calculo cada respuesta sobre los datos del proyecto.',
      ),
      TipoPregunta.noRegistrado => RespuestaAsistente(
        texto: 'El dataset no registra ${consulta.variableAusente}, así que no '
            'puedo responderlo sin inventar. Sí puedo decirte cuándo, dónde y '
            'con qué vehículos ocurren los accidentes.',
        datosInsuficientes: true,
      ),
      TipoPregunta.fueraDeRango => RespuestaAsistente(
        texto: 'No hay datos de ${consulta.anioFueraDeRango}. El dataset va de '
            '${_datos.anioMinimo} a ${nombresMeses[_datos.ultimoMes - 1].toLowerCase()} '
            'de ${_datos.anioMaximo}.',
        datosInsuficientes: true,
      ),
      TipoPregunta.desconocida => const RespuestaAsistente(
        texto: 'No entendí la pregunta. Prueba mencionando una variable: año, '
            'mes, día, hora, comuna, barrio, gravedad o tipo de vehículo.',
        datosInsuficientes: true,
      ),
      TipoPregunta.consulta => _responderConsulta(consulta),
    };
  }

  RespuestaAsistente _responderConsulta(Interpretacion consulta) {
    if (consulta.comparacion.isNotEmpty) return _comparar(consulta);

    final resumen = _consultar(_datos, consulta.filtros);
    final condiciones = _textoCondiciones(consulta);

    if (resumen.total == 0) {
      return RespuestaAsistente(
        texto: 'No hay accidentes registrados$condiciones.',
        filtros: consulta.filtros,
      );
    }
    if (consulta.promedio != null) return _promedio(consulta, resumen, condiciones);
    if (consulta.porcentaje) return _porcentaje(consulta, resumen, condiciones);
    if (consulta.tendencia) return _tendencia(consulta, resumen, condiciones);
    if (consulta.agrupacion != null) return _agrupar(consulta, resumen, condiciones);
    if (consulta.cuando) return _cuando(consulta, resumen, condiciones);

    return RespuestaAsistente(
      texto: 'Hay ${formatoNumero(resumen.total)} accidentes registrados$condiciones: '
          '${_desgloseGravedad(resumen)}',
      items: _itemsGravedad(resumen),
      filtros: consulta.filtros,
    );
  }

  RespuestaAsistente _comparar(Interpretacion consulta) {
    final items = <ItemRanking>[];
    for (var i = 0; i < consulta.comparacion.length; i++) {
      final (etiqueta, filtros) = consulta.comparacion[i];
      final cantidad = _consultar(_datos, filtros).total;
      items.add(ItemRanking(
        indice: i,
        nombre: _capitalizar(etiqueta),
        cantidad: cantidad,
      ));
    }
    final condiciones = _textoCondiciones(consulta);
    final buffer = StringBuffer('Comparación$condiciones: ');
    buffer.write(items
        .map((i) => '${i.nombre.toLowerCase()}, ${formatoNumero(i.cantidad)}')
        .join('; '));
    if (items.length == 2 && items[0].cantidad > 0) {
      final cambio = (items[1].cantidad - items[0].cantidad) * 100 / items[0].cantidad;
      buffer.write('. Variación de ${formatoVariacion(cambio)}.');
    } else {
      buffer.write('.');
    }
    return RespuestaAsistente(texto: buffer.toString(), items: items);
  }

  RespuestaAsistente _promedio(
    Interpretacion consulta,
    Resumen resumen,
    String condiciones,
  ) {
    final filtros = consulta.filtros;
    final desde = filtros.anioDesde ?? _datos.anioMinimo;
    final hasta = filtros.anioHasta ?? _datos.anioMaximo;
    var meses = 0;
    for (var anio = desde; anio <= hasta; anio++) {
      meses += _datos.ultimoMesDe(anio);
    }
    final (divisor, unidad) = switch (consulta.promedio!) {
      UnidadPromedio.anio => (meses / 12, 'año'),
      UnidadPromedio.mes => (meses.toDouble(), 'mes'),
      UnidadPromedio.dia => (meses * 30.44, 'día'),
    };
    return RespuestaAsistente(
      texto: 'En promedio ocurren ${formatoDecimal(resumen.total / divisor)} '
          'accidentes por $unidad$condiciones, según los '
          '${formatoNumero(resumen.total)} registros del período $desde-$hasta.',
      filtros: filtros,
    );
  }

  RespuestaAsistente _porcentaje(
    Interpretacion consulta,
    Resumen resumen,
    String condiciones,
  ) {
    final filtros = consulta.filtros;
    final base = _filtrosBase(filtros);
    final totalBase = _consultar(_datos, base).total;
    final valor = totalBase == 0 ? 0.0 : resumen.total * 100 / totalBase;
    return RespuestaAsistente(
      texto: 'El ${formatoDecimal(valor)} % de los accidentes de referencia '
          'cumple la condición$condiciones: ${formatoNumero(resumen.total)} de '
          '${formatoNumero(totalBase)}.',
      filtros: filtros,
    );
  }

  /// Quita la condición que define la parte para obtener el todo.
  Filtros _filtrosBase(Filtros f) {
    if (f.mascaraGravedad != null) {
      return Filtros(
        anioDesde: f.anioDesde, anioHasta: f.anioHasta, mes: f.mes,
        mascaraDias: f.mascaraDias, horaDesde: f.horaDesde, horaHasta: f.horaHasta,
        comuna: f.comuna, barrio: f.barrio, vehiculo: f.vehiculo,
      );
    }
    if (f.vehiculo != null) {
      return Filtros(
        anioDesde: f.anioDesde, anioHasta: f.anioHasta, mes: f.mes,
        mascaraDias: f.mascaraDias, horaDesde: f.horaDesde, horaHasta: f.horaHasta,
        comuna: f.comuna, barrio: f.barrio,
      );
    }
    return Filtros.ninguno;
  }

  RespuestaAsistente _tendencia(
    Interpretacion consulta,
    Resumen resumen,
    String condiciones,
  ) {
    final items = <ItemRanking>[
      for (var i = 0; i < resumen.porAnio.length; i++)
        if (resumen.porAnio[i] > 0)
          ItemRanking(
            indice: i,
            nombre: '${resumen.anioBase + i}',
            cantidad: resumen.porAnio[i],
          ),
    ];
    final completos = items
        .where((i) => int.parse(i.nombre) < _datos.anioMaximo || _datos.ultimoMes == 12)
        .toList();
    if (completos.length < 2) {
      return RespuestaAsistente(
        texto: 'No hay suficientes años completos para ver una tendencia$condiciones.',
        items: items,
        filtros: consulta.filtros,
      );
    }
    final primero = completos.first;
    final ultimo = completos.last;
    final cambio = (ultimo.cantidad - primero.cantidad) * 100 / primero.cantidad;
    return RespuestaAsistente(
      texto: 'Los accidentes$condiciones pasaron de ${formatoNumero(primero.cantidad)} '
          'en ${primero.nombre} a ${formatoNumero(ultimo.cantidad)} en ${ultimo.nombre} '
          '(${formatoVariacion(cambio)}). ${_datos.anioMaximo} no se usa porque el '
          'dataset llega hasta ${nombresMeses[_datos.ultimoMes - 1].toLowerCase()}.',
      items: items,
      filtros: consulta.filtros,
    );
  }

  RespuestaAsistente _cuando(
    Interpretacion consulta,
    Resumen resumen,
    String condiciones,
  ) {
    final mes = _ranking(resumen.porMes, (i) => nombresMeses[i]).first;
    final dia = nombresDias[resumen.diaPrincipal!];
    final franja = resumen.franjaPrincipal!;
    return RespuestaAsistente(
      texto: 'Los accidentes$condiciones se concentran los $dia, entre las '
          '${formatoHora(franja)} y las ${formatoHora((franja + 2) % 24)}. El mes '
          'con más registros es ${mes.nombre.toLowerCase()}.',
      filtros: consulta.filtros,
    );
  }

  RespuestaAsistente _agrupar(
    Interpretacion consulta,
    Resumen resumen,
    String condiciones,
  ) {
    final agrupacion = consulta.agrupacion!;
    final items = _ranking(
      _conteos(agrupacion, resumen),
      (i) => _nombreCategoria(agrupacion, i, resumen),
      ascendente: consulta.ascendente,
    );
    if (items.isEmpty) {
      return RespuestaAsistente(
        texto: 'No hay datos para agrupar por ${agrupacion.nombre}$condiciones.',
        filtros: consulta.filtros,
      );
    }
    final primero = items.first;
    final extremo = consulta.ascendente ? 'menos' : 'más';
    return RespuestaAsistente(
      texto: '${_capitalizar(agrupacion.nombre)} con $extremo accidentes'
          '$condiciones: ${primero.nombre}, con ${formatoNumero(primero.cantidad)} '
          '(${formatoDecimal(resumen.porcentaje(primero.cantidad))} %).',
      items: items.take(consulta.cantidadTop ?? 5).toList(),
      filtros: consulta.filtros,
    );
  }

  List<int> _conteos(Agrupacion agrupacion, Resumen resumen) {
    return switch (agrupacion) {
      Agrupacion.comuna => _soloConUbicacion(
        resumen.porComuna,
        (i) => _datos.catalogoComunas[i].tieneUbicacion,
      ),
      Agrupacion.barrio => _soloConUbicacion(
        resumen.porBarrio,
        (i) => _datos.catalogoBarrios[i].tieneUbicacion,
      ),
      Agrupacion.dia => resumen.porDia,
      Agrupacion.mes => resumen.porMes,
      Agrupacion.anio => resumen.porAnio,
      Agrupacion.hora => resumen.porHora,
      Agrupacion.jornada => [
        for (final jornada in jornadas)
          resumen.porHora
              .sublist(jornada.desde, jornada.hasta + 1)
              .fold(0, (suma, valor) => suma + valor),
      ],
      Agrupacion.vehiculo => [
        for (var i = 0; i < resumen.porVehiculo.length; i++)
          i == vehiculoPeaton ? 0 : resumen.porVehiculo[i],
      ],
      Agrupacion.gravedad => resumen.porGravedad,
      Agrupacion.tipo => resumen.porTipo,
      Agrupacion.propietario => [
        resumen.total - resumen.deEmpresa,
        resumen.deEmpresa,
      ],
      Agrupacion.entidad => [
        resumen.total - resumen.reportadosPolicia,
        resumen.reportadosPolicia,
      ],
    };
  }

  List<int> _soloConUbicacion(List<int> conteos, bool Function(int) tieneUbicacion) {
    return [
      for (var i = 0; i < conteos.length; i++) tieneUbicacion(i) ? conteos[i] : 0,
    ];
  }

  String _nombreCategoria(Agrupacion agrupacion, int i, Resumen resumen) {
    return switch (agrupacion) {
      Agrupacion.comuna => _datos.catalogoComunas[i].etiqueta,
      Agrupacion.barrio => _datos.catalogoBarrios[i].nombre,
      Agrupacion.dia => nombresDias[i],
      Agrupacion.mes => nombresMeses[i],
      Agrupacion.anio => '${resumen.anioBase + i}',
      Agrupacion.hora => '${formatoHora(i)} a ${formatoHora((i + 1) % 24)}',
      Agrupacion.jornada => jornadas[i].etiqueta,
      Agrupacion.vehiculo => nombresVehiculos[i],
      Agrupacion.gravedad => nombresGravedad[i],
      Agrupacion.tipo => nombresTipoAccidente[i],
      Agrupacion.propietario => const ['Particular', 'Empresa'][i],
      Agrupacion.entidad => const ['Agentes de tránsito', 'Policía Nacional'][i],
    };
  }

  String _textoCondiciones(Interpretacion consulta) {
    if (consulta.condiciones.isEmpty) return '';
    return ' ${consulta.condiciones.join(', ')}';
  }

  String _desgloseGravedad(Resumen resumen) {
    return '${formatoNumero(resumen.porGravedad[gravedadDanos])} con solo daños, '
        '${formatoNumero(resumen.porGravedad[gravedadHeridos])} con heridos y '
        '${formatoNumero(resumen.porGravedad[gravedadFallecidos])} con fallecidos. '
        'El dataset cuenta accidentes, no personas.';
  }

  List<ItemRanking> _itemsGravedad(Resumen resumen) {
    return [
      for (var i = 0; i < nombresGravedad.length; i++)
        ItemRanking(indice: i, nombre: nombresGravedad[i], cantidad: resumen.porGravedad[i]),
    ];
  }

  String _capitalizar(String texto) =>
      texto.isEmpty ? texto : '${texto[0].toUpperCase()}${texto.substring(1)}';
}
