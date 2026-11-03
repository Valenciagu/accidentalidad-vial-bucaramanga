import '../entidades/catalogos.dart';
import '../entidades/conjunto_accidentes.dart';
import '../entidades/filtros.dart';

enum Agrupacion {
  comuna('comuna'),
  barrio('barrio'),
  dia('día'),
  mes('mes'),
  anio('año'),
  hora('hora'),
  jornada('jornada'),
  vehiculo('vehículo'),
  gravedad('gravedad'),
  tipo('tipo de accidente'),
  propietario('propietario'),
  entidad('entidad');

  const Agrupacion(this.nombre);
  final String nombre;
}

enum UnidadPromedio { dia, mes, anio }

enum TipoPregunta { saludo, noRegistrado, fueraDeRango, desconocida, consulta }

class Interpretacion {
  Interpretacion(this.tipo);

  TipoPregunta tipo;
  Filtros filtros = Filtros.ninguno;
  final List<String> condiciones = [];
  Agrupacion? agrupacion;
  bool ascendente = false;
  int? cantidadTop;
  bool tendencia = false;
  bool cuando = false;
  bool porcentaje = false;
  UnidadPromedio? promedio;
  String? variableAusente;
  int? anioFueraDeRango;

  /// Dos o más valores de una misma variable: se responde comparándolos.
  final List<(String, Filtros)> comparacion = [];
}

/// Convierte una pregunta en español en una consulta estructurada.
///
/// No usa modelos de lenguaje: cada palabra se busca en diccionarios hash, por
/// lo que interpretar una pregunta de q palabras cuesta O(q). Si una pregunta
/// pide un dato que no existe en el dataset, se reporta en lugar de adivinar.
class InterpretePreguntas {
  InterpretePreguntas(this._datos) {
    final comunas = _datos.catalogoComunas;
    for (var i = 0; i < comunas.length; i++) {
      if (!comunas[i].urbana) continue;
      _porNumeroComuna[comunas[i].numero] = i;
      final nombre = normalizarTexto(comunas[i].nombre);
      _comunas[nombre] = i;
      _comunas[nombre.replaceFirst(RegExp(r'^(la|el|los|las) '), '')] = i;
    }
    _comunas['morrorico'] = _comunas['morrorrico'] ?? 0;

    final barrios = _datos.catalogoBarrios;
    for (var i = 0; i < barrios.length; i++) {
      if (!barrios[i].tieneUbicacion) continue;
      final nombre = normalizarTexto(barrios[i].nombre);
      if (!_barriosAmbiguos.contains(nombre)) _barrios[nombre] = i;
    }
  }

  final ConjuntoAccidentes _datos;
  final Map<int, int> _porNumeroComuna = {};
  final Map<String, int> _comunas = {};
  final Map<String, int> _barrios = {};

  static const int _maximoPalabrasNombre = 5;

  /// Barrios cuyo nombre es una palabra corriente de una pregunta.
  static const Set<String> _barriosAmbiguos = {
    'bucaramanga', 'santander', 'modelo', 'universidad', 'mercedes',
    'sin barrio registrado',
  };

  static const Map<String, int> _meses = {
    'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4, 'mayo': 5, 'junio': 6,
    'julio': 7, 'agosto': 8, 'septiembre': 9, 'setiembre': 9, 'octubre': 10,
    'noviembre': 11, 'diciembre': 12,
  };

  static const Map<String, int> _dias = {
    'lunes': 1, 'martes': 2, 'miercoles': 3, 'jueves': 4, 'viernes': 5,
    'sabado': 6, 'sabados': 6, 'domingo': 7, 'domingos': 7,
  };

  static const Map<String, int> _vehiculos = {
    'automovil': 0, 'automoviles': 0, 'carro': 0, 'carros': 0, 'auto': 0,
    'autos': 0, 'coche': 0, 'coches': 0, 'campero': 1, 'camperos': 1,
    'camioneta': 2, 'camionetas': 2, 'microbus': 3, 'microbuses': 3, 'micro': 3,
    'buseta': 4, 'busetas': 4, 'bus': 5, 'buses': 5, 'camion': 6, 'camiones': 6,
    'volqueta': 7, 'volquetas': 7, 'moto': 8, 'motos': 8, 'motocicleta': 8,
    'motocicletas': 8, 'motociclista': 8, 'motociclistas': 8, 'bicicleta': 9,
    'bicicletas': 9, 'bici': 9, 'ciclista': 9, 'ciclistas': 9, 'peaton': 11,
    'peatones': 11, 'atropello': 11, 'atropellos': 11, 'atropellado': 11,
    'atropellados': 11,
  };

  static const Map<String, Agrupacion> _agrupadores = {
    'comuna': Agrupacion.comuna, 'comunas': Agrupacion.comuna,
    'zona': Agrupacion.comuna, 'zonas': Agrupacion.comuna,
    'sector': Agrupacion.comuna, 'sectores': Agrupacion.comuna,
    'lugar': Agrupacion.comuna, 'lugares': Agrupacion.comuna,
    'donde': Agrupacion.comuna, 'barrio': Agrupacion.barrio,
    'barrios': Agrupacion.barrio, 'dia': Agrupacion.dia, 'dias': Agrupacion.dia,
    'mes': Agrupacion.mes, 'meses': Agrupacion.mes, 'ano': Agrupacion.anio,
    'anos': Agrupacion.anio, 'hora': Agrupacion.hora, 'horas': Agrupacion.hora,
    'horario': Agrupacion.hora, 'horarios': Agrupacion.hora,
    'franja': Agrupacion.hora, 'jornada': Agrupacion.jornada,
    'jornadas': Agrupacion.jornada, 'vehiculo': Agrupacion.vehiculo,
    'vehiculos': Agrupacion.vehiculo, 'transporte': Agrupacion.vehiculo,
    'gravedad': Agrupacion.gravedad, 'tipo': Agrupacion.tipo,
    'tipos': Agrupacion.tipo, 'propietario': Agrupacion.propietario,
    'propietarios': Agrupacion.propietario, 'dueno': Agrupacion.propietario,
    'entidad': Agrupacion.entidad, 'entidades': Agrupacion.entidad,
    'autoridad': Agrupacion.entidad,
  };

  static final List<(RegExp, String)> _noRegistrados = [
    (RegExp(r'\b(clima|lluvia|lluvias|llovia|llueve|temperatura)\b'), 'el clima'),
    (RegExp(r'\b(edad|edades|jovenes|ancianos|ninos|menores)\b'), 'la edad de las personas'),
    (RegExp(r'\b(sexo|genero|mujer|mujeres|hombre|hombres)\b'), 'el sexo de las personas'),
    (RegExp(r'\b(alcohol|borracho|borrachos|embriaguez|ebrio|ebrios|drogas)\b'), 'el consumo de alcohol o drogas'),
    (RegExp(r'\b(velocidad|exceso)\b'), 'la velocidad'),
    (RegExp(r'\b(causa|causas|culpa|culpable|culpables|motivo|motivos)\b'), 'la causa del accidente'),
    (RegExp(r'\b(costo|costos|dinero|precio|soat)\b'), 'los costos'),
    (RegExp(r'\b(placa|placas|cedula|conductor|conductores)\b'), 'datos personales'),
    (RegExp(r'\b(semaforo|semaforos|cruce|cruces|calle|calles|carrera|avenida|autopista)\b'), 'la dirección exacta'),
    (RegExp(r'\b(predic\w*|pronostic\w*|proximo ano|futuro|va a pasar|pasara)\b'), 'predicciones (el proyecto solo analiza datos históricos)'),
    (RegExp(r'\bpor que\b(?! (comuna|barrio|dia|mes|ano|hora|vehiculo|zona|jornada))'), 'la causa de los accidentes'),
  ];

  /// Minúsculas, sin tildes y sin signos.
  static String normalizarTexto(String texto) {
    const conTilde = 'áéíóúüñ';
    const sinTilde = 'aeiouun';
    final salida = StringBuffer();
    for (final letra in texto.toLowerCase().split('')) {
      final posicion = conTilde.indexOf(letra);
      salida.write(posicion >= 0 ? sinTilde[posicion] : letra);
    }
    return salida
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9:%\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Interpretacion interpretar(String pregunta) {
    var texto = normalizarTexto(pregunta);
    if (texto.isEmpty ||
        RegExp(r'^(hola|buenas|buenos dias|buenas tardes|buenas noches|gracias|ayuda|que puedes hacer)$')
            .hasMatch(texto)) {
      return Interpretacion(TipoPregunta.saludo);
    }

    for (final (patron, variable) in _noRegistrados) {
      if (patron.hasMatch(texto)) {
        return Interpretacion(TipoPregunta.noRegistrado)..variableAusente = variable;
      }
    }

    final resultado = Interpretacion(TipoPregunta.consulta);
    final valoresPorDimension = <String, List<(String, Filtros)>>{};
    var filtros = Filtros.ninguno;

    void agregar(String dimension, String etiqueta, Filtros Function(Filtros) aplicar) {
      valoresPorDimension.putIfAbsent(dimension, () => []).add((etiqueta, aplicar(Filtros.ninguno)));
      if (valoresPorDimension[dimension]!.length == 1) {
        filtros = aplicar(filtros);
        resultado.condiciones.add(etiqueta);
      }
    }

    resultado.porcentaje = RegExp(r'porcentaje|proporcion|%').hasMatch(texto);
    resultado.ascendente = RegExp(r'\b(menos|menor|minimo|segur[oa]s?)\b').hasMatch(texto);
    resultado.cuando = RegExp(r'\bcuando\b').hasMatch(texto);

    final promedio = RegExp(r'\bpromedio\b').hasMatch(texto) ||
        RegExp(r'\b(al|por|cada) (dia|mes|ano)\b(?! de la semana)').hasMatch(texto) &&
            RegExp(r'\bcuant').hasMatch(texto);
    if (promedio) {
      if (RegExp(r'\bdia|diari').hasMatch(texto)) {
        resultado.promedio = UnidadPromedio.dia;
      } else if (RegExp(r'\bano|anual').hasMatch(texto)) {
        resultado.promedio = UnidadPromedio.anio;
      } else {
        resultado.promedio = UnidadPromedio.mes;
      }
      texto = texto.replaceAll(RegExp(r'\b(al|por|cada) (dia|mes|ano)\b'), ' ');
    }

    final top = RegExp(r'\btop (\d+)\b|\blos (\d+)\b|\blas (\d+)\b|\b(\d+) (comunas|barrios|meses|dias|horas|vehiculos)\b')
        .firstMatch(texto);
    if (top != null) {
      final valor = top.group(1) ?? top.group(2) ?? top.group(3) ?? top.group(4);
      final n = int.parse(valor!);
      if (n > 0 && n < 100) resultado.cantidadTop = n;
    }

    // Años.
    texto = texto.replaceAllMapped(RegExp(r'\b(ultimo ano|pandemia)\b'), (m) {
      return m.group(0) == 'pandemia' ? '2020' : '${_datos.anioMaximo}';
    });
    final anios = [
      for (final m in RegExp(r'\b(19|20)\d\d\b').allMatches(texto)) int.parse(m.group(0)!),
    ];
    for (final anio in anios) {
      if (anio < _datos.anioMinimo || anio > _datos.anioMaximo) {
        return Interpretacion(TipoPregunta.fueraDeRango)..anioFueraDeRango = anio;
      }
    }
    final esRango = anios.length == 2 &&
        RegExp(r'\b(entre|desde|hasta|de ' '${anios[0]}' r' a)\b').hasMatch(texto) &&
        !RegExp(r'compar|diferencia|\bvs\b|versus').hasMatch(texto);
    if (esRango) {
      final desde = anios[0] < anios[1] ? anios[0] : anios[1];
      final hasta = anios[0] < anios[1] ? anios[1] : anios[0];
      filtros = filtros.copiarCon(anioDesde: desde, anioHasta: hasta);
      resultado.condiciones.add('entre $desde y $hasta');
    } else {
      for (final anio in anios) {
        agregar('anio', 'en $anio', (f) => f.copiarCon(anioDesde: anio, anioHasta: anio));
      }
    }
    texto = texto.replaceAll(RegExp(r'\b(19|20)\d\d\b'), ' ');

    // Horas explícitas, antes de las jornadas: "7 de la noche" no es un filtro de noche.
    int ajustar(int hora, String? sufijo) {
      final tarde = sufijo != null &&
          RegExp(r'pm|tarde|noche').hasMatch(sufijo) &&
          hora < 12;
      return tarde ? hora + 12 : hora % 24;
    }

    const sufijoHora = r'(?::\d\d)?( ?am| ?pm| de la manana| de la tarde| de la noche)?';
    final rangoHoras = RegExp('(?:entre|de|desde) (?:las )?(\\d{1,2})$sufijoHora (?:y|a|hasta) (?:las )?(\\d{1,2})$sufijoHora')
        .firstMatch(texto);
    final horaSuelta = RegExp('\\b(?:a las|las) (\\d{1,2})$sufijoHora|\\b(\\d{1,2})( ?am| ?pm)\\b')
        .firstMatch(texto);
    if (rangoHoras != null) {
      final sufijoFinal = rangoHoras.group(4);
      final desde = ajustar(int.parse(rangoHoras.group(1)!), rangoHoras.group(2) ?? sufijoFinal);
      final hasta = ajustar(int.parse(rangoHoras.group(3)!), sufijoFinal);
      if (desde <= hasta) {
        filtros = filtros.copiarCon(horaDesde: desde, horaHasta: hasta);
        resultado.condiciones.add('entre las $desde:00 y las $hasta:59');
        texto = texto.replaceFirst(rangoHoras.group(0)!, ' ');
      }
    } else if (horaSuelta != null) {
      final hora = ajustar(
        int.parse((horaSuelta.group(1) ?? horaSuelta.group(3))!),
        horaSuelta.group(2) ?? horaSuelta.group(4),
      );
      filtros = filtros.copiarCon(horaDesde: hora, horaHasta: hora);
      resultado.condiciones.add('a las $hora:00');
      texto = texto.replaceFirst(horaSuelta.group(0)!, ' ');
    }

    // Grupos de varias palabras.
    if (RegExp(r'\bfin(es)? de semana\b').hasMatch(texto)) {
      agregar('dia', 'en fin de semana', (f) => f.copiarCon(mascaraDias: 0x60));
      texto = texto.replaceAll(RegExp(r'\bfin(es)? de semana\b'), ' ');
    } else if (RegExp(r'\bentre semana\b').hasMatch(texto)) {
      agregar('dia', 'entre semana', (f) => f.copiarCon(mascaraDias: 0x1F));
      texto = texto.replaceAll(RegExp(r'\bentre semana\b'), ' ');
    }
    if (RegExp(r'\bsolo danos\b|\bdanos materiales\b|\bsin heridos\b').hasMatch(texto)) {
      agregar('gravedad', 'con solo daños', (f) => f.copiarCon(mascaraGravedad: 1 << gravedadDanos));
    }
    if (RegExp(r'\bde dia\b|\bdiurno\w*').hasMatch(texto)) {
      agregar('hora', 'de día', (f) => f.copiarCon(horaDesde: 6, horaHasta: 17));
      texto = texto.replaceAll(RegExp(r'\bde dia\b|\bdiurno\w*'), ' ');
    }
    if (RegExp(r'\bnocturno\w*').hasMatch(texto)) {
      agregar('hora', 'de noche', (f) => f.copiarCon(horaDesde: 18, horaHasta: 23));
      texto = texto.replaceAll(RegExp(r'\bnocturno\w*'), ' ');
    }

    // Comuna por número.
    texto = texto.replaceAllMapped(RegExp(r'\bcomuna (\d{1,2})\b'), (m) {
      final indice = _porNumeroComuna[int.parse(m.group(1)!)];
      if (indice != null) {
        agregar('zona', 'en ${_datos.catalogoComunas[indice].etiqueta}',
            (f) => f.copiarCon(comuna: indice));
      }
      return ' ';
    });

    // Nombres de comunas y barrios: primero las coincidencias más largas.
    final palabras = texto.split(' ').where((p) => p.isNotEmpty).toList();
    final usadas = List<bool>.filled(palabras.length, false);
    for (var largo = _maximoPalabrasNombre; largo >= 1; largo--) {
      for (var inicio = 0; inicio + largo <= palabras.length; inicio++) {
        if (usadas.getRange(inicio, inicio + largo).contains(true)) continue;
        final nombre = palabras.sublist(inicio, inicio + largo).join(' ');
        final anterior = inicio > 0 ? palabras[inicio - 1] : '';
        final pideBarrio = anterior == 'barrio' && _barrios.containsKey(nombre);
        final comuna = pideBarrio ? null : _comunas[nombre];
        final barrio = comuna == null ? _barrios[nombre] : null;
        if (comuna == null && barrio == null) continue;

        for (var i = inicio; i < inicio + largo; i++) {
          usadas[i] = true;
        }
        if (anterior == 'barrio' || anterior == 'comuna') usadas[inicio - 1] = true;
        if (comuna != null) {
          agregar('zona', 'en ${_datos.catalogoComunas[comuna].etiqueta}',
              (f) => f.copiarCon(comuna: comuna));
        } else {
          agregar('zona', 'en el barrio ${_datos.catalogoBarrios[barrio!].nombre}',
              (f) => f.copiarCon(barrio: barrio));
        }
      }
    }

    var hayCuenta = false;
    final agrupadores = <Agrupacion>[];
    final restantes = <String>[];
    for (var i = 0; i < palabras.length; i++) {
      if (usadas[i]) continue;
      final palabra = palabras[i];
      restantes.add(palabra);

      final mes = _meses[palabra];
      final dia = _dias[palabra];
      final vehiculo = _vehiculos[palabra];
      if (mes != null) {
        agregar('mes', 'en ${nombresMeses[mes - 1].toLowerCase()}', (f) => f.copiarCon(mes: mes));
      } else if (dia != null) {
        agregar('dia', 'los ${nombresDias[dia - 1].toLowerCase()}',
            (f) => f.copiarCon(mascaraDias: 1 << (dia - 1)));
      } else if (vehiculo != null) {
        agregar('vehiculo', 'con ${nombresVehiculos[vehiculo].toLowerCase()}',
            (f) => f.copiarCon(vehiculo: vehiculo));
      } else if (RegExp(r'^(muert|fallecid|mortal|letal|muri)').hasMatch(palabra)) {
        agregar('gravedad', 'con fallecidos',
            (f) => f.copiarCon(mascaraGravedad: 1 << gravedadFallecidos));
      } else if (RegExp(r'^(herid|lesionad)').hasMatch(palabra)) {
        agregar('gravedad', 'con heridos',
            (f) => f.copiarCon(mascaraGravedad: 1 << gravedadHeridos));
      } else if (RegExp(r'^(grave|graves|victimas)$').hasMatch(palabra)) {
        agregar('gravedad', 'graves', (f) => f.copiarCon(mascaraGravedad: mascaraGraves));
      } else if (palabra == 'madrugada') {
        agregar('hora', 'en la madrugada', (f) => f.copiarCon(horaDesde: 0, horaHasta: 5));
      } else if (palabra == 'manana') {
        agregar('hora', 'en la mañana', (f) => f.copiarCon(horaDesde: 6, horaHasta: 11));
      } else if (palabra == 'tarde') {
        agregar('hora', 'en la tarde', (f) => f.copiarCon(horaDesde: 12, horaHasta: 17));
      } else if (palabra == 'noche' || palabra == 'noches') {
        agregar('hora', 'en la noche', (f) => f.copiarCon(horaDesde: 18, horaHasta: 23));
      } else if (_agrupadores.containsKey(palabra)) {
        final tipoDeVehiculo = palabra.startsWith('tipo') &&
            i + 2 < palabras.length &&
            palabras[i + 2].startsWith('vehiculo');
        if (!tipoDeVehiculo) agrupadores.add(_agrupadores[palabra]!);
      } else if (RegExp(r'^(cuant\w*|accidente\w*|total|numero|cantidad|siniestro\w*|choque\w*|mas|mayor|hay|ocurr\w*)$')
          .hasMatch(palabra)) {
        hayCuenta = true;
      }
    }

    resultado.filtros = filtros;
    // Las palabras ya resueltas ("Norte Bajo") no cuentan como verbos de tendencia.
    resultado.tendencia = RegExp(
      r'\b(tendencia|evolucion|aument\w*|disminu\w*|baj[oa]\w*|subi\w*|crec\w*|reduj\w*)\b',
    ).hasMatch(restantes.join(' '));
    if (resultado.promedio == null) {
      // "En el año 2019, ¿qué comuna...?" agrupa por comuna, no por año.
      for (final agrupador in agrupadores) {
        if (!_estaFiltrada(agrupador, filtros)) {
          resultado.agrupacion = agrupador;
          break;
        }
      }
    }

    for (final valores in valoresPorDimension.values) {
      if (valores.length < 2) continue;
      final base = _quitarDimension(filtros, valores.first.$2);
      resultado.comparacion.addAll([
        for (final (etiqueta, parcial) in valores) (etiqueta, _combinar(base, parcial)),
      ]);
      resultado.condiciones.remove(valores.first.$1);
      resultado.filtros = base;
      break;
    }

    final comprendida = !resultado.filtros.vacio ||
        resultado.agrupacion != null ||
        resultado.tendencia ||
        resultado.cuando ||
        resultado.porcentaje ||
        resultado.promedio != null ||
        resultado.comparacion.isNotEmpty ||
        hayCuenta;
    if (!comprendida) resultado.tipo = TipoPregunta.desconocida;
    return resultado;
  }

  bool _estaFiltrada(Agrupacion agrupacion, Filtros filtros) {
    return switch (agrupacion) {
      Agrupacion.anio => filtros.anioUnico,
      Agrupacion.mes => filtros.mes != null,
      Agrupacion.dia => filtros.mascaraDias != null,
      Agrupacion.hora => filtros.horaDesde != null,
      Agrupacion.comuna => filtros.comuna != null || filtros.barrio != null,
      Agrupacion.barrio => filtros.barrio != null,
      Agrupacion.gravedad => filtros.mascaraGravedad != null,
      _ => false,
    };
  }

  Filtros _quitarDimension(Filtros filtros, Filtros valor) {
    return Filtros(
      anioDesde: valor.anioDesde == null ? filtros.anioDesde : null,
      anioHasta: valor.anioHasta == null ? filtros.anioHasta : null,
      mes: valor.mes == null ? filtros.mes : null,
      mascaraDias: valor.mascaraDias == null ? filtros.mascaraDias : null,
      horaDesde: valor.horaDesde == null ? filtros.horaDesde : null,
      horaHasta: valor.horaHasta == null ? filtros.horaHasta : null,
      comuna: valor.comuna == null && valor.barrio == null ? filtros.comuna : null,
      barrio: valor.comuna == null && valor.barrio == null ? filtros.barrio : null,
      mascaraGravedad: valor.mascaraGravedad == null ? filtros.mascaraGravedad : null,
      vehiculo: valor.vehiculo == null ? filtros.vehiculo : null,
    );
  }

  Filtros _combinar(Filtros base, Filtros valor) {
    return base.copiarCon(
      anioDesde: valor.anioDesde,
      anioHasta: valor.anioHasta,
      mes: valor.mes,
      mascaraDias: valor.mascaraDias,
      horaDesde: valor.horaDesde,
      horaHasta: valor.horaHasta,
      comuna: valor.comuna,
      barrio: valor.barrio,
      mascaraGravedad: valor.mascaraGravedad,
      vehiculo: valor.vehiculo,
    );
  }
}
