"""Utilidades compartidas por las herramientas de preparación de datos."""
import csv
import glob
import os
import re
import unicodedata

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_GLOB = os.path.join(RAIZ, '3._Accidentes_de_Transito_*.csv')
GEO_JSON = os.path.join(RAIZ, 'tool', 'datos', 'barrios_geo.json')
SALIDA_JSON = os.path.join(RAIZ, 'assets', 'datos', 'accidentes.json')

NO_DISPONIBLE = 'NO DISPONIBLE'

# Variantes que no se resuelven solo con mayúsculas/minúsculas.
ALIAS_BARRIOS = {
    'rosablanca': 'Rosablanca',
    'quebrada la iglesia i': 'Quebrada La Iglesia I',
    'bosque norte': 'Bosque Norte',
}

ROMANOS = {'i', 'ii', 'iii', 'iv', 'v', 'xii', 'xxiii', 'i-v'}
MENORES = {'de', 'del', 'la', 'las', 'los', 'y'}


def leer_csv():
    ruta = glob.glob(CSV_GLOB)[0]
    with open(ruta, encoding='utf-8-sig', newline='') as archivo:
        return list(csv.DictReader(archivo)), os.path.basename(ruta)


def clave(texto):
    """Clave sin tildes ni mayúsculas, para comparar nombres."""
    limpio = unicodedata.normalize('NFD', texto.strip().lower())
    return ''.join(c for c in limpio if unicodedata.category(c) != 'Mn')


def normalizar_barrio(nombre):
    """Unifica variantes de un barrio: 'Real de Minas' y 'Real De Minas'."""
    base = re.sub(r'\s+', ' ', nombre.strip())
    if base == NO_DISPONIBLE:
        return base
    bajo = base.lower()
    if bajo in ALIAS_BARRIOS:
        return ALIAS_BARRIOS[bajo]
    palabras = []
    for i, palabra in enumerate(bajo.split(' ')):
        if palabra in ROMANOS:
            palabras.append(palabra.upper())
        elif i > 0 and palabra in MENORES:
            palabras.append(palabra)
        else:
            palabras.append(palabra.capitalize())
    return ' '.join(palabras)
