/// Valores fijos de las variables de análisis (RF-03).
library;

const List<String> nombresMeses = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto',
  'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

const List<String> mesesCortos = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov',
  'Dic',
];

const List<String> nombresDias = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
];

const List<String> diasCortos = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

const List<String> nombresGravedad = ['Solo daños', 'Con heridos', 'Con fallecidos'];

const int gravedadDanos = 0;
const int gravedadHeridos = 1;
const int gravedadFallecidos = 2;

/// Graves: accidentes con víctimas, es decir, con heridos o fallecidos.
const int mascaraGraves = (1 << gravedadHeridos) | (1 << gravedadFallecidos);

/// Mismo orden de los bits de la columna `mascara` generada por el ETL.
const List<String> nombresVehiculos = [
  'Automóvil', 'Campero', 'Camioneta', 'Microbús', 'Buseta', 'Bus', 'Camión',
  'Volqueta', 'Motocicleta', 'Bicicleta', 'Otro', 'Peatón',
];

const int vehiculoAutomovil = 0;
const int vehiculoMoto = 8;
const int vehiculoPeaton = 11;

const List<String> nombresTipoAccidente = [
  'Atropello',
  'Vehículo solo',
  'Entre vehículos',
];

const List<String> etiquetasCantidadVehiculos = ['1', '2', '3', '4 o más'];

class Jornada {
  const Jornada(this.nombre, this.desde, this.hasta);

  final String nombre;
  final int desde;
  final int hasta;

  String get etiqueta =>
      '$nombre (${_dosDigitos(desde)}:00-${_dosDigitos(hasta)}:59)';
}

const List<Jornada> jornadas = [
  Jornada('Madrugada', 0, 5),
  Jornada('Mañana', 6, 11),
  Jornada('Tarde', 12, 17),
  Jornada('Noche', 18, 23),
];

String _dosDigitos(int valor) => valor.toString().padLeft(2, '0');
