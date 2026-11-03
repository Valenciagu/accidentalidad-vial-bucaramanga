import 'package:flutter/foundation.dart';

import '../../domain/casos_uso/consultar_accidentes.dart';
import '../../domain/casos_uso/generar_ranking.dart';
import '../../domain/casos_uso/medir_complejidad.dart';
import '../../domain/casos_uso/planificar_operativos.dart';
import '../../domain/casos_uso/responder_pregunta.dart';
import '../../domain/entidades/catalogos.dart';
import '../../domain/entidades/conjunto_accidentes.dart';
import '../../domain/entidades/estado_servicio.dart';
import '../../domain/entidades/filtros.dart';
import '../../domain/entidades/resumen.dart';
import '../../domain/repositorios/repositorio_accidentes.dart';
import '../../domain/repositorios/repositorio_conectividad.dart';

/// Estado de la app. Coordina casos de uso; no contiene reglas de negocio.
class ControladorApp extends ChangeNotifier {
  ControladorApp({
    required RepositorioAccidentes repositorioAccidentes,
    required RepositorioConectividad repositorioConectividad,
    required ConsultarAccidentes consultar,
    required GenerarRanking ranking,
    required PlanificarOperativos planificar,
    required MedirComplejidad medir,
  }) : _repositorioAccidentes = repositorioAccidentes,
       _repositorioConectividad = repositorioConectividad,
       _consultar = consultar,
       _ranking = ranking,
       _planificar = planificar,
       _medir = medir;

  final RepositorioAccidentes _repositorioAccidentes;
  final RepositorioConectividad _repositorioConectividad;
  final ConsultarAccidentes _consultar;
  final GenerarRanking _ranking;
  final PlanificarOperativos _planificar;
  final MedirComplejidad _medir;

  ConjuntoAccidentes? _datos;
  ResponderPregunta? _responder;

  Filtros filtros = Filtros.ninguno;
  late Resumen resumen;
  Comparacion? comparacion;
  List<ItemRanking> rankingComunas = const [];
  List<ItemRanking> rankingBarrios = const [];

  bool cargando = true;
  String? error;
  int tiempoCargaMs = 0;
  int tiempoConsultaUs = 0;

  List<EstadoServicio>? servicios;
  bool verificandoServicios = false;

  ConjuntoAccidentes get datos => _datos!;
  ResponderPregunta get responder => _responder!;
  bool get listo => _datos != null;

  Future<void> iniciar() async {
    cargando = true;
    error = null;
    notifyListeners();
    final reloj = Stopwatch()..start();
    try {
      final datos = await _repositorioAccidentes.cargar();
      _datos = datos;
      _responder = ResponderPregunta(datos, _consultar, _ranking);
      tiempoCargaMs = reloj.elapsedMilliseconds;
      _recalcular();
    } catch (e) {
      // También FlutterError: la pantalla de inicio no debe quedar cargando para siempre.
      error = 'No fue posible cargar los datos: $e';
    }
    cargando = false;
    notifyListeners();
  }

  void aplicarFiltros(Filtros nuevos) {
    filtros = nuevos;
    _recalcular();
    notifyListeners();
  }

  void limpiarFiltros() => aplicarFiltros(Filtros.ninguno);

  /// RF-10: todas las pantallas se actualizan a partir de este único cálculo.
  void _recalcular() {
    final reloj = Stopwatch()..start();
    resumen = _consultar(datos, filtros);
    comparacion = _consultar.compararConAnioAnterior(datos, filtros, resumen);
    rankingComunas = _ranking.comunas(datos, resumen);
    rankingBarrios = _ranking.barrios(datos, resumen);
    tiempoConsultaUs = reloj.elapsedMicroseconds;
  }

  List<ItemRanking> vehiculosOrdenados() {
    final conteos = List<int>.of(resumen.porVehiculo)..[vehiculoPeaton] = 0;
    return _ranking(conteos, (i) => nombresVehiculos[i]);
  }

  Future<void> verificarServicios() async {
    verificandoServicios = true;
    notifyListeners();
    servicios = await _repositorioConectividad.verificar();
    verificandoServicios = false;
    notifyListeners();
  }

  Future<PlanOperativos> planificar(ParametrosPlan parametros) {
    return compute(_ejecutarPlan, (_planificar, datos, resumen, parametros));
  }

  Future<ReporteComplejidad> medirComplejidad() {
    return compute(_ejecutarMedicion, (
      _medir,
      datos,
      _consultar(datos, Filtros.ninguno),
    ));
  }
}

PlanOperativos _ejecutarPlan(
  (PlanificarOperativos, ConjuntoAccidentes, Resumen, ParametrosPlan) entrada,
) {
  final (planificar, datos, resumen, parametros) = entrada;
  return planificar(datos, resumen, parametros);
}

ReporteComplejidad _ejecutarMedicion(
  (MedirComplejidad, ConjuntoAccidentes, Resumen) entrada,
) {
  final (medir, datos, resumen) = entrada;
  return medir(datos, resumen);
}
