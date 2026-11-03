import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ppi_analisis/core/formato.dart';
import 'package:ppi_analisis/data/modelos/conjunto_accidentes_modelo.dart';
import 'package:ppi_analisis/domain/casos_uso/consultar_accidentes.dart';
import 'package:ppi_analisis/domain/casos_uso/medir_complejidad.dart';
import 'package:ppi_analisis/domain/casos_uso/planificar_operativos.dart';
import 'package:ppi_analisis/domain/entidades/catalogos.dart';
import 'package:ppi_analisis/domain/entidades/filtros.dart';

/// Imprime las tablas de mediciones que se citan en docs/CONTEXTO_TECNICO.md.
void main() {
  test('mediciones sobre el dataset real', () {
    final texto = File('assets/datos/accidentes.json').readAsStringSync();
    final datos = ConjuntoAccidentesModelo.desdeJson(
      jsonDecode(texto) as Map<String, dynamic>,
    );
    const consultar = ConsultarAccidentes();
    const planificar = PlanificarOperativos();
    final general = consultar(datos, Filtros.ninguno);

    final reporte = const MedirComplejidad(consultar, planificar)(datos, general);
    for (final t in reporte.tamanos) {
      // ignore: avoid_print
      print('n=${t.n} busqueda=${t.busquedaUs}us filtrado=${t.filtradoUs}us '
          'ordenamiento=${t.ordenamientoUs}us');
    }
    for (final p in reporte.planes) {
      // ignore: avoid_print
      print('k=${p.k} espacio=${formatoGrande(p.espacio)} nodos=${p.nodos} '
          'exacto=${p.exactoUs}us voraz=${p.vorazUs}us '
          'optimo=${p.optimoDemostrado} calidad=${p.calidadVoraz}');
    }

    final plan = planificar(
      datos,
      general,
      const ParametrosPlan(
        k: 3,
        alcanceKm: 1.5,
        duracionHoras: 4,
        limiteMicrosegundos: 3000000,
      ),
    );
    for (final o in plan.operativos) {
      // ignore: avoid_print
      print('${datos.catalogoComunas[o.comuna].etiqueta} '
          '${nombresDias[o.dia]} ${o.horaInicio}-${o.horaFin}');
    }
    // ignore: avoid_print
    print('cubre ${plan.exacto.valor} de ${plan.pesoTotal} candidatos=${plan.candidatos}');

    expect(plan.candidatos, 17 * 7 * 12);
    final comunas = plan.operativos.map((o) => o.comuna).toSet();
    expect(comunas, hasLength(3));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
