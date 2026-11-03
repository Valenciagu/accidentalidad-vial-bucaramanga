import '../algoritmos/busqueda_binaria.dart';
import '../entidades/catalogos.dart';
import '../entidades/conjunto_accidentes.dart';
import '../entidades/filtros.dart';
import '../entidades/resumen.dart';

/// Filtra y agrega los accidentes en una sola pasada (RF-05, RF-07, RF-09, RF-10).
///
/// Complejidad: O(log n + r), donde r son los registros del rango de años. Sin
/// filtro de año, r = n y la consulta es O(n). Comprobar cada registro cuesta
/// O(1) porque el número de filtros es constante.
class ConsultarAccidentes {
  const ConsultarAccidentes();

  Resumen call(ConjuntoAccidentes datos, Filtros filtros) {
    final inicio = filtros.anioDesde == null
        ? 0
        : limiteInferior(datos.fechas, filtros.anioDesde! * 10000);
    final fin = filtros.anioHasta == null
        ? datos.n
        : limiteInferior(datos.fechas, (filtros.anioHasta! + 1) * 10000);
    return _recorrer(datos, filtros, inicio, fin);
  }

  /// Misma consulta recorriendo toda la tabla. Sirve de referencia O(n) en las
  /// mediciones de complejidad.
  Resumen recorridoCompleto(ConjuntoAccidentes datos, Filtros filtros, {int? hasta}) {
    return _recorrer(datos, filtros, 0, hasta ?? datos.n);
  }

  Resumen _recorrer(ConjuntoAccidentes datos, Filtros filtros, int inicio, int fin) {
    final resumen = Resumen(
      anioBase: datos.anioMinimo,
      cantidadAnios: datos.cantidadAnios,
      cantidadComunas: datos.catalogoComunas.length,
      cantidadBarrios: datos.catalogoBarrios.length,
    );
    final catalogoBarrios = datos.catalogoBarrios;
    final mascaraVehiculo = filtros.vehiculo == null ? 0 : 1 << filtros.vehiculo!;

    for (var i = inicio; i < fin; i++) {
      final fecha = datos.fechas[i];
      final anio = fecha ~/ 10000;
      final mes = fecha ~/ 100 % 100;
      final dia = datos.dias[i];
      final hora = datos.horas[i];
      final gravedad = datos.gravedades[i];
      final barrio = datos.barrios[i];
      final comuna = catalogoBarrios[barrio].comuna;
      final mascara = datos.mascaras[i];

      if (filtros.anioDesde != null && anio < filtros.anioDesde!) continue;
      if (filtros.anioHasta != null && anio > filtros.anioHasta!) continue;
      if (filtros.mes != null && mes != filtros.mes) continue;
      if (filtros.mascaraDias != null && filtros.mascaraDias! & (1 << (dia - 1)) == 0) continue;
      if (filtros.horaDesde != null && hora < filtros.horaDesde!) continue;
      if (filtros.horaHasta != null && hora > filtros.horaHasta!) continue;
      if (filtros.comuna != null && comuna != filtros.comuna) continue;
      if (filtros.barrio != null && barrio != filtros.barrio) continue;
      if (filtros.mascaraGravedad != null &&
          filtros.mascaraGravedad! & (1 << gravedad) == 0) {
        continue;
      }
      if (mascaraVehiculo != 0 && mascara & mascaraVehiculo == 0) continue;

      final cantidadVehiculos = datos.vehiculos[i];
      resumen.total++;
      resumen.porAnio[anio - datos.anioMinimo]++;
      resumen.porMes[mes - 1]++;
      resumen.porDia[dia - 1]++;
      resumen.porHora[hora]++;
      resumen.porGravedad[gravedad]++;
      resumen.porComuna[comuna]++;
      resumen.porBarrio[barrio]++;
      resumen.serieMensual[(anio - datos.anioMinimo) * 12 + mes - 1]++;
      resumen.porComunaDiaHora[comuna * horasPorSemana + (dia - 1) * 24 + hora]++;
      if (gravedad != gravedadDanos) {
        resumen.graves++;
        resumen.gravesPorMes[mes - 1]++;
      }
      for (var v = 0; v < nombresVehiculos.length; v++) {
        if (mascara & (1 << v) != 0) resumen.porVehiculo[v]++;
      }
      if (mascara & (1 << vehiculoPeaton) != 0) {
        resumen.porTipo[0]++;
      } else if (cantidadVehiculos <= 1) {
        resumen.porTipo[1]++;
      } else {
        resumen.porTipo[2]++;
      }
      if (cantidadVehiculos >= 1) {
        resumen.porCantidadVehiculos[cantidadVehiculos >= 4 ? 3 : cantidadVehiculos - 1]++;
      }
      resumen.deEmpresa += datos.empresas[i];
      resumen.reportadosPolicia += datos.policias[i];
    }
    return resumen;
  }

  /// Compara un año consultado con los mismos meses del año anterior.
  ///
  /// Un solo año puede estar incompleto: 2023 llega hasta septiembre y
  /// compararlo contra todo 2022 daría una caída falsa.
  Comparacion? compararConAnioAnterior(
    ConjuntoAccidentes datos,
    Filtros filtros,
    Resumen actual,
  ) {
    if (!filtros.anioUnico) return null;
    final anio = filtros.anioDesde!;
    final anterior = anio - 1;
    if (anterior < datos.anioMinimo) return null;

    final referencia = call(
      datos,
      Filtros(
        anioDesde: anterior,
        anioHasta: anterior,
        mes: filtros.mes,
        mascaraDias: filtros.mascaraDias,
        horaDesde: filtros.horaDesde,
        horaHasta: filtros.horaHasta,
        comuna: filtros.comuna,
        barrio: filtros.barrio,
        mascaraGravedad: filtros.mascaraGravedad,
        vehiculo: filtros.vehiculo,
      ),
    );

    final ultimoMes = datos.ultimoMesDe(anio);
    var totalAnterior = 0;
    var gravesAnterior = 0;
    for (var mes = 0; mes < ultimoMes; mes++) {
      totalAnterior += referencia.porMes[mes];
      gravesAnterior += referencia.gravesPorMes[mes];
    }

    return Comparacion(
      anioReferencia: anterior,
      variacionTotal: _variacion(actual.total, totalAnterior),
      variacionGraves: _variacion(actual.graves, gravesAnterior),
      periodoParcial: ultimoMes < 12,
    );
  }

  double? _variacion(int actual, int anterior) {
    if (anterior == 0) return null;
    return (actual - anterior) * 100 / anterior;
  }
}
