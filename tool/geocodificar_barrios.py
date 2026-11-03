"""Obtiene coordenadas de cada barrio con Nominatim (OpenStreetMap).

El CSV no trae coordenadas. Se consulta una sola vez y el resultado queda en
tool/datos/barrios_geo.json, así el ETL se puede repetir sin conexión.
Respeta el límite de Nominatim de una petición por segundo.

Uso: python tool/geocodificar_barrios.py
"""
import json
import os
import sys
import time
import urllib.parse
import urllib.request

from comun import GEO_JSON, NO_DISPONIBLE, clave, leer_csv, normalizar_barrio

CAJA_LAT = (7.03, 7.19)
CAJA_LON = (-73.20, -73.05)
AGENTE = 'ppi-accidentes-bucaramanga/1.0 (proyecto academico)'


def buscar(consulta):
    parametros = urllib.parse.urlencode({
        'q': consulta,
        'format': 'json',
        'limit': 5,
        'countrycodes': 'co',
        'viewbox': f'{CAJA_LON[0]},{CAJA_LAT[1]},{CAJA_LON[1]},{CAJA_LAT[0]}',
        'bounded': 1,
    })
    url = f'https://nominatim.openstreetmap.org/search?{parametros}'
    peticion = urllib.request.Request(url, headers={'User-Agent': AGENTE})
    with urllib.request.urlopen(peticion, timeout=30) as respuesta:
        return json.load(respuesta)


def comuna_de(resultado):
    """Extrae el número de comuna de 'Comuna 10 - Provenza, ...'."""
    for parte in resultado.get('display_name', '').split(','):
        parte = parte.strip()
        if parte.lower().startswith('comuna '):
            numero = parte.split(' ')[1]
            if numero.isdigit():
                return int(numero)
    return None


def elegir(resultados, comuna_csv):
    """Prefiere el resultado cuya comuna coincide con la del CSV."""
    for resultado in resultados:
        if comuna_de(resultado) == comuna_csv:
            return resultado, 'comuna_coincide'
    for resultado in resultados:
        if comuna_de(resultado) is None:
            return resultado, 'sin_comuna_osm'
    return None, None


def main():
    filas, _ = leer_csv()
    barrios = {}
    for fila in filas:
        barrio = normalizar_barrio(fila['BARRIO'])
        if barrio != NO_DISPONIBLE:
            barrios[barrio] = fila['COMUNA']

    geo = {}
    if os.path.exists(GEO_JSON):
        with open(GEO_JSON, encoding='utf-8') as archivo:
            geo = json.load(archivo)

    for nombre, comuna in sorted(barrios.items()):
        if geo.get(nombre):
            continue
        numero = int(comuna[:2]) if comuna[:2].isdigit() else None
        entrada = None
        simple = nombre.removesuffix(' Centro').removesuffix(' Norte').rstrip(' I')
        consultas = (f'{nombre}, Bucaramanga, Santander', f'Barrio {nombre}, Bucaramanga',
                     nombre, simple, f'Urbanizacion {simple}')
        for consulta in consultas:
            time.sleep(1.1)
            try:
                resultados = buscar(consulta)
            except Exception as error:
                print('ERROR', nombre, error, file=sys.stderr)
                continue
            resultado, calidad = elegir(resultados, numero)
            if resultado:
                entrada = {
                    'lat': round(float(resultado['lat']), 5),
                    'lon': round(float(resultado['lon']), 5),
                    'calidad': calidad,
                    'nombre_osm': resultado['display_name'][:90],
                }
                break
        geo[nombre] = entrada
        print(clave(nombre), '->', entrada['calidad'] if entrada else 'SIN RESULTADO', flush=True)
        os.makedirs(os.path.dirname(GEO_JSON), exist_ok=True)
        with open(GEO_JSON, 'w', encoding='utf-8') as archivo:
            json.dump(geo, archivo, ensure_ascii=False, indent=1, sort_keys=True)


if __name__ == '__main__':
    main()
