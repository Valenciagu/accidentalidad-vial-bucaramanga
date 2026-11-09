import 'configuracion.dart';
import 'data/repositorios/repositorio_accidentes_asset.dart';
import 'data/repositorios/repositorio_conectividad_http.dart';
import 'domain/casos_uso/consultar_accidentes.dart';
import 'domain/casos_uso/generar_ranking.dart';
import 'domain/casos_uso/medir_complejidad.dart';
import 'domain/casos_uso/planificar_operativos.dart';
import 'presentation/controladores/controlador_app.dart';

/// Raíz de composición: el único archivo que conoce todas las capas.
ControladorApp crearControlador() {
  const consultar = ConsultarAccidentes();
  const planificar = PlanificarOperativos();

  return ControladorApp(
    repositorioAccidentes: const RepositorioAccidentesAsset(),
    cantidadSolicitada: cantidadAccidentes,
    repositorioConectividad: const RepositorioConectividadHttp(),
    consultar: consultar,
    ranking: const GenerarRanking(),
    planificar: planificar,
    medir: const MedirComplejidad(consultar, planificar),
  );
}
