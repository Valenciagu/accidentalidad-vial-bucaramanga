"""ETL: limpia el CSV de accidentes y genera el asset que consume la app.

Cubre RF-01 (carga), RF-02 (depuración) y RF-03 (organización).
Complejidad: O(n log n) por el ordenamiento final por fecha; el resto es O(n).

Uso: python tool/preprocesar_datos.py
"""
import collections
import datetime
import json
import os

from comun import GEO_JSON, NO_DISPONIBLE, SALIDA_JSON, leer_csv, normalizar_barrio

VEHICULOS = ['AUTOMOVIL', 'CAMPERO', 'CAMIONETA', 'MICRO', 'BUSETA', 'BUS',
             'CAMION', 'VOLQUETA', 'MOTO', 'BICICLETA', 'OTRO', 'PEATON']
INDICE_PEATON = VEHICULOS.index('PEATON')
GRAVEDADES = {'solo daños': 0, 'con heridos': 1, 'con muertos': 2}
CATEGORIA_COMUNA = {'CORREG. 1': 'Corregimiento 1', 'CORREG. 2': 'Corregimiento 2',
                    'CORREG. 3': 'Corregimiento 3', NO_DISPONIBLE: 'No disponible'}
# 'Bucaramanga' no es un barrio, pero esos registros sí conservan su comuna.
BARRIOS_INVALIDOS = {'Bucaramanga'}
SIN_BARRIO = 'Sin barrio registrado'
LIMITE_VEHICULOS = 12
# Un punto sin comuna verificada se descarta si queda lejos de su comuna (grados).
DISTANCIA_MAXIMA = 0.03


def parsear_hora(valor, reporte):
    """Devuelve la hora 0-23. '1899-12-31T12:15:00.000' o el formato roto '6.3'."""
    if 'T' in valor:
        return int(valor[11:13])
    reporte['horas_recuperadas'] += 1
    return int(float(valor))


def nombre_comuna(texto):
    if texto in CATEGORIA_COMUNA:
        return CATEGORIA_COMUNA[texto]
    nombre = texto.split('. ', 1)[1].title().replace(' Del ', ' del ').replace(' De ', ' de ')
    return {'Morrorico': 'Morrorrico', 'Garcia Rovira': 'García Rovira'}.get(nombre, nombre)


def promedio_ponderado(puntos):
    total = sum(p for _, _, p in puntos)
    if total == 0:
        return None
    return (round(sum(a * p for a, _, p in puntos) / total, 5),
            round(sum(b * p for _, b, p in puntos) / total, 5))


def main():
    filas, fuente = leer_csv()
    reporte = collections.Counter()
    reporte['filas_originales'] = len(filas)

    with open(GEO_JSON, encoding='utf-8') as archivo:
        geo = json.load(archivo)

    vistos = set()
    registros = []
    for fila in filas:
        huella = tuple(v for k, v in fila.items() if k != 'ORDEN')
        if huella in vistos:
            reporte['duplicados_eliminados'] += 1
            continue
        vistos.add(huella)

        fecha = datetime.date.fromisoformat(fila['FECHA'][:10])
        if int(fila['DÍA'][:2]) != fecha.isoweekday() or int(fila['MES'][:2]) != fecha.month:
            reporte['fechas_inconsistentes'] += 1

        gravedad_texto = fila['GRAVEDAD'].strip()
        if gravedad_texto == 'Con Muertos':
            reporte['gravedades_estandarizadas'] += 1

        barrio_original = fila['BARRIO']
        barrio = normalizar_barrio(barrio_original)
        if barrio != barrio_original:
            reporte['barrios_estandarizados'] += 1
        if barrio in BARRIOS_INVALIDOS:
            reporte['barrios_invalidos'] += 1
            barrio = SIN_BARRIO
        if barrio == NO_DISPONIBLE:
            reporte['sin_ubicacion'] += 1

        mascara = 0
        total_vehiculos = 0
        for i, vehiculo in enumerate(VEHICULOS):
            cantidad = int(fila[vehiculo])
            if cantidad > 0:
                mascara |= 1 << i
            if i != INDICE_PEATON:
                total_vehiculos += cantidad
        if total_vehiculos > LIMITE_VEHICULOS:
            reporte['vehiculos_atipicos'] += 1
            total_vehiculos = LIMITE_VEHICULOS

        registros.append({
            'fecha': int(fecha.strftime('%Y%m%d')),
            'dia': fecha.isoweekday(),
            'hora': parsear_hora(fila['HORA'], reporte),
            'gravedad': GRAVEDADES[gravedad_texto.lower()],
            'barrio': barrio,
            'comuna': fila['COMUNA'],
            'mascara': mascara,
            'vehiculos': total_vehiculos,
            'empresa': 1 if fila['Propietario de Vehículo'] == 'Empresa' else 0,
            'policia': 1 if fila['ENTIDAD'] == 'AGENTES POLICIA NACIONAL' else 0,
        })

    registros.sort(key=lambda r: (r['fecha'], r['hora']))

    comunas_texto = sorted({r['comuna'] for r in registros},
                           key=lambda c: (not c[:2].isdigit(), c))
    id_comuna = {c: i for i, c in enumerate(comunas_texto)}

    conteo_barrio = collections.Counter(
        (r['barrio'], r['comuna']) for r in registros if r['barrio'] != NO_DISPONIBLE)
    barrios = sorted(conteo_barrio, key=lambda b: b[0])
    id_barrio = {b: i for i, b in enumerate(barrios)}
    id_sin_barrio = len(barrios)

    puntos_comuna = collections.defaultdict(list)
    for barrio, comuna in barrios:
        entrada = geo.get(barrio)
        if entrada:
            puntos_comuna[comuna].append((entrada['lat'], entrada['lon'],
                                          conteo_barrio[(barrio, comuna)]))
    centros = {c: promedio_ponderado(p) for c, p in puntos_comuna.items()}

    for barrio, comuna in barrios:
        entrada = geo.get(barrio)
        if entrada and entrada['calidad'] != 'comuna_coincide' and comuna in centros:
            lat, lon = centros[comuna]
            if abs(entrada['lat'] - lat) + abs(entrada['lon'] - lon) > DISTANCIA_MAXIMA:
                reporte['coordenadas_descartadas'] += 1
                geo[barrio] = None

    catalogo_comunas = []
    for comuna in comunas_texto:
        centro = centros.get(comuna)
        catalogo_comunas.append({
            'numero': int(comuna[:2]) if comuna[:2].isdigit() else 0,
            'nombre': nombre_comuna(comuna),
            'lat': centro[0] if centro else None,
            'lon': centro[1] if centro else None,
        })

    catalogo_barrios = []
    for barrio, comuna in barrios:
        entrada = geo.get(barrio)
        exacto = bool(entrada)
        centro = (entrada['lat'], entrada['lon']) if entrada else centros.get(comuna)
        if barrio == SIN_BARRIO:
            centro = None
        elif not exacto:
            reporte['barrios_sin_coordenada'] += 1
        catalogo_barrios.append({
            'nombre': barrio,
            'comuna': id_comuna[comuna],
            'lat': centro[0] if centro else None,
            'lon': centro[1] if centro else None,
            'aprox': not exacto,
        })
    catalogo_barrios.append({'nombre': 'No disponible', 'comuna': id_comuna[NO_DISPONIBLE],
                             'lat': None, 'lon': None, 'aprox': True})

    reporte['filas_limpias'] = len(registros)
    salida = {
        'meta': {
            'fuente': fuente,
            'fecha_min': registros[0]['fecha'],
            'fecha_max': registros[-1]['fecha'],
            'reporte': dict(sorted(reporte.items())),
        },
        'comunas': catalogo_comunas,
        'barrios': catalogo_barrios,
        'columnas': {
            'fecha': [r['fecha'] for r in registros],
            'dia': [r['dia'] for r in registros],
            'hora': [r['hora'] for r in registros],
            'gravedad': [r['gravedad'] for r in registros],
            'barrio': [id_barrio.get((r['barrio'], r['comuna']), id_sin_barrio)
                       for r in registros],
            'mascara': [r['mascara'] for r in registros],
            'vehiculos': [r['vehiculos'] for r in registros],
            'empresa': [r['empresa'] for r in registros],
            'policia': [r['policia'] for r in registros],
        },
    }
    os.makedirs(os.path.dirname(SALIDA_JSON), exist_ok=True)
    with open(SALIDA_JSON, 'w', encoding='utf-8') as archivo:
        json.dump(salida, archivo, ensure_ascii=False, separators=(',', ':'))

    print(json.dumps(salida['meta'], ensure_ascii=False, indent=1))
    print('comunas', len(catalogo_comunas), 'barrios', len(catalogo_barrios))
    print('KB', os.path.getsize(SALIDA_JSON) // 1024)


if __name__ == '__main__':
    main()
