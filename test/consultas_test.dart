import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ppi_analisis/data/modelos/conjunto_accidentes_modelo.dart';
import 'package:ppi_analisis/domain/asistente/interprete_preguntas.dart';
import 'package:ppi_analisis/domain/casos_uso/consultar_accidentes.dart';
import 'package:ppi_analisis/domain/casos_uso/generar_ranking.dart';
import 'package:ppi_analisis/domain/casos_uso/planificar_operativos.dart';
import 'package:ppi_analisis/domain/casos_uso/responder_pregunta.dart';
import 'package:ppi_analisis/domain/entidades/catalogos.dart';
import 'package:ppi_analisis/domain/entidades/conjunto_accidentes.dart';
import 'package:ppi_analisis/domain/entidades/filtros.dart';

/// Los valores esperados se calcularon sobre el CSV crudo con un script aparte,
/// sin pasar por el ETL ni por este código.
void main() {
  late ConjuntoAccidentes datos;
  late InterpretePreguntas interprete;
  late ResponderPregunta responder;
  const consultar = ConsultarAccidentes();

  setUpAll(() {
    final texto = File('assets/datos/accidentes.json').readAsStringSync();
    datos = ConjuntoAccidentesModelo.desdeJson(
      jsonDecode(texto) as Map<String, dynamic>,
    );
    interprete = InterpretePreguntas(datos);
    responder = ResponderPregunta(datos, consultar, const GenerarRanking());
  });

  int comunaLlamada(String nombre) =>
      datos.catalogoComunas.indexWhere((c) => c.nombre == nombre);

  group('Datos y consultas contra el CSV crudo', () {
    test('totales generales', () {
      final resumen = consultar(datos, Filtros.ninguno);
      expect(resumen.total, 39168);
      expect(resumen.graves, 19579);
      expect(resumen.porGravedad[gravedadFallecidos], 609);
      expect(resumen.porVehiculo[vehiculoMoto], 20910);
      expect(resumen.porVehiculo[vehiculoAutomovil], 24190);
      expect(resumen.porDia[5], 6456);
      expect(resumen.porComuna[comunaLlamada('Cabecera del Llano')], 6411);
    });

    test('filtros combinados', () {
      final resumen = consultar(
        datos,
        const Filtros(
          anioDesde: 2018,
          anioHasta: 2018,
          vehiculo: vehiculoMoto,
          mascaraGravedad: mascaraGraves,
        ),
      );
      expect(resumen.total, 1792);
    });

    test('la búsqueda binaria no cambia el resultado del recorrido completo', () {
      for (var anio = 2012; anio <= 2023; anio++) {
        final filtros = Filtros(anioDesde: anio, anioHasta: anio);
        expect(
          consultar(datos, filtros).total,
          consultar.recorridoCompleto(datos, filtros).total,
        );
      }
    });

    test('cada agregado suma el total', () {
      final resumen = consultar(datos, const Filtros(mes: 3, horaDesde: 6, horaHasta: 11));
      int suma(List<int> v) => v.fold(0, (a, b) => a + b);
      expect(suma(resumen.porMes), resumen.total);
      expect(suma(resumen.porDia), resumen.total);
      expect(suma(resumen.porHora), resumen.total);
      expect(suma(resumen.porGravedad), resumen.total);
      expect(suma(resumen.porComuna), resumen.total);
      expect(suma(resumen.porBarrio), resumen.total);
      expect(suma(resumen.porTipo), resumen.total);
      expect(suma(resumen.porComunaDiaHora), resumen.total);
    });

    test('2023 se compara con los mismos meses de 2022', () {
      const filtros = Filtros(anioDesde: 2023, anioHasta: 2023);
      final resumen = consultar(datos, filtros);
      final comparacion = consultar.compararConAnioAnterior(datos, filtros, resumen)!;
      expect(resumen.total, 923);
      expect(comparacion.periodoParcial, isTrue);
      expect(comparacion.variacionTotal, closeTo((923 - 1873) * 100 / 1873, 0.001));
    });

    test('el primer año no tiene comparación', () {
      const filtros = Filtros(anioDesde: 2012, anioHasta: 2012);
      expect(
        consultar.compararConAnioAnterior(datos, filtros, consultar(datos, filtros)),
        isNull,
      );
    });
  });

  group('Intérprete de preguntas', () {
    test('año como filtro, no como agrupación', () {
      final consulta = interprete.interpretar('¿Cuántos accidentes hubo en el año 2019?');
      expect(consulta.filtros.anioDesde, 2019);
      expect(consulta.agrupacion, isNull);
    });

    test('agrupa por la variable pedida aunque otra esté filtrada', () {
      final consulta = interprete.interpretar('En el año 2019, ¿qué comuna tuvo más accidentes?');
      expect(consulta.filtros.anioDesde, 2019);
      expect(consulta.agrupacion, Agrupacion.comuna);
    });

    test('tipo de vehículo no es tipo de accidente', () {
      final consulta = interprete.interpretar('¿Qué tipo de vehículo tiene más accidentes?');
      expect(consulta.agrupacion, Agrupacion.vehiculo);
    });

    test('más seguro ordena de menor a mayor y no se toma como costo', () {
      final consulta = interprete.interpretar('¿Cuál es el barrio más seguro?');
      expect(consulta.tipo, TipoPregunta.consulta);
      expect(consulta.agrupacion, Agrupacion.barrio);
      expect(consulta.ascendente, isTrue);
    });

    test('un nombre de barrio no se confunde con una tendencia', () {
      final consulta = interprete.interpretar('¿Cuántos accidentes hay en Norte Bajo?');
      expect(consulta.tendencia, isFalse);
      expect(datos.catalogoBarrios[consulta.filtros.barrio!].nombre, 'Norte Bajo');
    });

    test('comuna por número, por nombre y barrio homónimo', () {
      expect(interprete.interpretar('accidentes en la comuna 15').filtros.comuna,
          comunaLlamada('Centro'));
      expect(interprete.interpretar('accidentes en Provenza').filtros.comuna,
          comunaLlamada('Provenza'));
      final barrio = interprete.interpretar('accidentes en el barrio Provenza').filtros.barrio;
      expect(datos.catalogoBarrios[barrio!].nombre, 'Provenza');
    });

    test('horas', () {
      final tarde = interprete.interpretar('accidentes a las 7 de la noche');
      expect(tarde.filtros.horaDesde, 19);
      final rango = interprete.interpretar('accidentes entre las 7 y las 9');
      expect((rango.filtros.horaDesde, rango.filtros.horaHasta), (7, 9));
      final jornada = interprete.interpretar('accidentes de moto en la noche');
      expect((jornada.filtros.horaDesde, jornada.filtros.horaHasta), (18, 23));
      expect(jornada.filtros.vehiculo, vehiculoMoto);
    });

    test('rango de años y comparación de años', () {
      final rango = interprete.interpretar('accidentes entre 2015 y 2018');
      expect((rango.filtros.anioDesde, rango.filtros.anioHasta), (2015, 2018));
      expect(rango.comparacion, isEmpty);
      expect(interprete.interpretar('compara 2019 y 2020').comparacion, hasLength(2));
    });

    test('día de la semana agrupa aunque pregunte cuántos', () {
      final consulta = interprete.interpretar('¿Cuántos accidentes por día de la semana?');
      expect(consulta.promedio, isNull);
      expect(consulta.agrupacion, Agrupacion.dia);
    });

    test('rechaza lo que el dataset no registra', () {
      for (final pregunta in const [
        '¿Cuántos accidentes hubo por lluvia?',
        '¿Cuántos conductores estaban borrachos?',
        '¿Por qué hay tantos accidentes?',
        '¿Qué edad tienen los heridos?',
        '¿Cuál es la predicción para el próximo año?',
      ]) {
        expect(interprete.interpretar(pregunta).tipo, TipoPregunta.noRegistrado, reason: pregunta);
      }
    });

    test('años fuera del dataset y preguntas sin sentido', () {
      expect(interprete.interpretar('accidentes en 2025').tipo, TipoPregunta.fueraDeRango);
      expect(interprete.interpretar('me gustan las manzanas').tipo, TipoPregunta.desconocida);
    });
  });

  group('Respuestas del asistente', () {
    test('las cifras salen de los datos', () {
      expect(responder('Compara 2019 y 2020').texto, contains('3.710'));
      expect(responder('Compara 2019 y 2020').texto, contains('2.259'));
      final comuna = responder('¿Qué comuna tiene más accidentes?');
      expect(comuna.items.first.cantidad, 6411);
      expect(comuna.texto, contains('Cabecera del Llano'));
    });

    test('todas las sugerencias de la app obtienen respuesta', () {
      for (final sugerencia in ResponderPregunta.sugerencias) {
        final respuesta = responder(sugerencia);
        expect(respuesta.datosInsuficientes, isFalse, reason: sugerencia);
      }
    });

    test('pregunta sin coincidencias no inventa', () {
      final respuesta = responder('accidentes de volqueta en Mutis el domingo a las 3 am en 2013 con fallecidos');
      expect(respuesta.texto, startsWith('No hay accidentes registrados'));
    });

    test('la tendencia excluye el año incompleto', () {
      final respuesta = responder('¿Cómo ha sido la tendencia de accidentes?');
      expect(respuesta.texto, contains('2022'));
      expect(respuesta.texto, contains('2023 no se usa'));
    });
  });

  group('Planificador sobre datos reales', () {
    test('el plan exacto mejora o iguala al voraz y cubre lo que declara', () {
      final resumen = consultar(datos, Filtros.ninguno);
      for (final k in const [1, 2, 3]) {
        final plan = const PlanificarOperativos()(
          datos,
          resumen,
          ParametrosPlan(
            k: k,
            alcanceKm: 1.5,
            duracionHoras: 4,
            limiteMicrosegundos: 2000000,
          ),
        );
        expect(plan.exacto.valor, greaterThanOrEqualTo(plan.voraz.valor));
        expect(plan.operativos, hasLength(k));
        expect(plan.exacto.valor, lessThanOrEqualTo(resumen.total));
      }
    });

    test('la distancia entre comunas es coherente con la geografía', () {
      const planificar = PlanificarOperativos();
      final norte = datos.catalogoComunas[comunaLlamada('Norte')];
      final sur = datos.catalogoComunas[comunaLlamada('Sur')];
      expect(planificar.distanciaKm(norte, sur), inInclusiveRange(7, 12));
    });
  });
}
