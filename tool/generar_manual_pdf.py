"""Genera docs/Manual_y_Complejidad.pdf con el manual de uso y el análisis de complejidad."""
import os
import sys

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (Image, KeepTogether, PageBreak, Paragraph, SimpleDocTemplate,
                                Spacer, Table, TableStyle)

RAIZ = sys.argv[1]
CAPTURAS = os.path.join(RAIZ, 'docs', 'capturas')
SALIDA = os.path.join(RAIZ, 'docs', 'Manual_y_Complejidad.pdf')

for nombre, archivo in [('Arial', 'arial.ttf'), ('Arial-Bold', 'arialbd.ttf'),
                        ('Arial-Italic', 'ariali.ttf'), ('Consolas', 'consola.ttf')]:
    pdfmetrics.registerFont(TTFont(nombre, f'C:/Windows/Fonts/{archivo}'))
pdfmetrics.registerFontFamily('Arial', normal='Arial', bold='Arial-Bold', italic='Arial-Italic')

AZUL = colors.HexColor('#1B4F86')
PRIMARIO = colors.HexColor('#0B6FE0')
SUAVE = colors.HexColor('#E6F0FC')
BORDE = colors.HexColor('#C9D3DF')
TEXTO = colors.HexColor('#16263A')
GRIS = colors.HexColor('#5B6B7E')
VERDE = colors.HexColor('#1E8E4E')
ROJO = colors.HexColor('#C62828')

base = ParagraphStyle('base', fontName='Arial', fontSize=10, leading=14.5, textColor=TEXTO,
                      spaceAfter=6)
E = {
    'titulo': ParagraphStyle('titulo', parent=base, fontName='Arial-Bold', fontSize=26,
                             leading=32, textColor=colors.white),
    'subtitulo': ParagraphStyle('subtitulo', parent=base, fontSize=13, leading=18,
                                textColor=colors.white),
    'h1': ParagraphStyle('h1', parent=base, fontName='Arial-Bold', fontSize=18, leading=23,
                         textColor=AZUL, spaceBefore=4, spaceAfter=10),
    'h2': ParagraphStyle('h2', parent=base, fontName='Arial-Bold', fontSize=13, leading=17,
                         textColor=AZUL, spaceBefore=12, spaceAfter=6),
    'h3': ParagraphStyle('h3', parent=base, fontName='Arial-Bold', fontSize=10.5, leading=14,
                         spaceBefore=6, spaceAfter=3),
    'p': base,
    'pie': ParagraphStyle('pie', parent=base, fontSize=8.5, leading=11, textColor=GRIS,
                          alignment=TA_CENTER),
    'celda': ParagraphStyle('celda', parent=base, fontSize=9, leading=12, spaceAfter=0),
    'celdab': ParagraphStyle('celdab', parent=base, fontName='Arial-Bold', fontSize=9,
                             leading=12, spaceAfter=0, textColor=colors.white),
    'vineta': ParagraphStyle('vineta', parent=base, leftIndent=14, bulletIndent=3,
                             spaceAfter=3),
    'nota': ParagraphStyle('nota', parent=base, fontSize=9.5, leading=13.5, spaceAfter=0),
    'codigo': ParagraphStyle('codigo', parent=base, fontName='Consolas', fontSize=9,
                             leading=12, spaceAfter=0),
}
ANCHO = A4[0] - 4 * cm
# Columna de texto junto a una captura: ancho total menos imagen y separación.
ANCHO_COLUMNA = ANCHO - 5.9 * cm - 14
# Tablas y notas toman el ancho del lugar donde se insertan.
ANCHO_ACTUAL = [ANCHO]


def P(texto, estilo='p'):
    return Paragraph(texto, E[estilo])


def vinetas(items, numeradas=False):
    return [Paragraph(t, E['vineta'], bulletText=f'{i}.' if numeradas else '•')
            for i, t in enumerate(items, 1)]


def tabla(filas, anchos, alinear_derecha=()):
    datos = [[P(c, 'celdab') for c in filas[0]]]
    for fila in filas[1:]:
        datos.append([P(str(c), 'celda') for c in fila])
    t = Table(datos, colWidths=[ANCHO_ACTUAL[0] * a for a in anchos], repeatRows=1)
    estilo = [
        ('BACKGROUND', (0, 0), (-1, 0), AZUL),
        ('GRID', (0, 0), (-1, -1), 0.5, BORDE),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 5),
        ('RIGHTPADDING', (0, 0), (-1, -1), 5),
    ]
    for i in range(1, len(datos)):
        if i % 2 == 0:
            estilo.append(('BACKGROUND', (0, i), (-1, i), colors.HexColor('#F5F8FC')))
    t.setStyle(TableStyle(estilo))
    return t


def nota(texto, color=SUAVE):
    t = Table([[P(texto, 'nota')]], colWidths=[ANCHO_ACTUAL[0]])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), color),
        ('LEFTPADDING', (0, 0), (-1, -1), 10), ('RIGHTPADDING', (0, 0), (-1, -1), 10),
        ('TOPPADDING', (0, 0), (-1, -1), 7), ('BOTTOMPADDING', (0, 0), (-1, -1), 7),
        ('LINEBEFORE', (0, 0), (0, -1), 3, PRIMARIO),
    ]))
    return t


def captura(nombre, ancho=5.3 * cm):
    ruta = os.path.join(CAPTURAS, nombre)
    imagen = Image(ruta, width=ancho, height=ancho * 860 / 412)
    marco = Table([[imagen]], colWidths=[ancho + 4])
    marco.setStyle(TableStyle([('BOX', (0, 0), (-1, -1), 0.6, BORDE),
                               ('LEFTPADDING', (0, 0), (-1, -1), 2),
                               ('RIGHTPADDING', (0, 0), (-1, -1), 2),
                               ('TOPPADDING', (0, 0), (-1, -1), 2),
                               ('BOTTOMPADDING', (0, 0), (-1, -1), 2)]))
    return marco


def pantalla(titulo, imagen, pie, contenido):
    """Captura a la izquierda y explicación a la derecha."""
    columna_imagen = [captura(imagen), Spacer(1, 4), P(pie, 'pie')]
    t = Table([[columna_imagen, [P(titulo, 'h2')] + contenido]],
              colWidths=[5.9 * cm, ANCHO - 5.9 * cm])
    t.setStyle(TableStyle([('VALIGN', (0, 0), (-1, -1), 'TOP'),
                           ('LEFTPADDING', (0, 0), (-1, -1), 0),
                           ('RIGHTPADDING', (1, 0), (1, 0), 0),
                           ('LEFTPADDING', (1, 0), (1, 0), 14)]))
    return [t, Spacer(1, 10)]


def portada(lienzo, doc):
    lienzo.saveState()
    lienzo.setFillColor(AZUL)
    lienzo.rect(0, 0, A4[0], A4[1], fill=1, stroke=0)
    lienzo.restoreState()


def pie_pagina(lienzo, doc):
    lienzo.saveState()
    lienzo.setFont('Arial', 8)
    lienzo.setFillColor(GRIS)
    lienzo.drawString(2 * cm, 1.2 * cm, 'Accidentalidad Vial Bucaramanga · Manual y complejidad')
    lienzo.drawRightString(A4[0] - 2 * cm, 1.2 * cm, f'Página {doc.page}')
    lienzo.setStrokeColor(BORDE)
    lienzo.line(2 * cm, 1.55 * cm, A4[0] - 2 * cm, 1.55 * cm)
    lienzo.restoreState()


h = []

# Portada
h += [Spacer(1, 6 * cm),
      P('Accidentalidad Vial Bucaramanga', 'titulo'),
      Spacer(1, 8),
      P('Manual de usuario y análisis de complejidad algorítmica', 'subtitulo'),
      Spacer(1, 2.2 * cm),
      P('Proyecto Pedagógico Integrador · Segundo semestre<br/>'
        'Ingeniería en Software · Tecnológico de Antioquia', 'subtitulo'),
      Spacer(1, 0.8 * cm),
      P('Juan Felipe Agudelo Valencia · Diego Alejandro Restrepo Sánchez<br/>'
        'Iván Dario Montoya López · Mateo Saldarriaga Vidales', 'subtitulo'),
      Spacer(1, 0.8 * cm),
      P('Medellín, 2026', 'subtitulo'),
      PageBreak()]

# Contenido
h += [P('Contenido', 'h1')]
h += vinetas([
    '<b>Parte A. Manual de usuario</b>: qué hace la app y cómo usar cada pantalla.',
    '<b>Parte B. Complejidad algorítmica</b>: qué algoritmos usa la app, su complejidad y por qué '
    'las consultas están en P mientras el planificador es NP-difícil.',
    '<b>Anexo</b>: tabla resumen y mediciones.',
])
h += [Spacer(1, 8), P('Sobre la app', 'h2'),
      P('Accidentalidad Vial permite consultar y visualizar los accidentes de tránsito registrados '
        'en Bucaramanga entre enero de 2012 y septiembre de 2023: 39.168 accidentes después de la '
        'limpieza de datos. Está pensada para personas sin formación técnica: autoridades de '
        'tránsito, líderes comunitarios y ciudadanos.'),
      P('Fuente: conjunto de datos abiertos "Accidentes de Tránsito ocurridos en el Municipio de '
        'Bucaramanga", de Datos Abiertos Colombia.'),
      nota('<b>Todo funciona sin internet</b> salvo el fondo del mapa, que se descarga de '
           'OpenStreetMap. Los datos viajan dentro de la app.'),
      PageBreak()]

# Parte A
h += [P('Parte A. Manual de usuario', 'h1'),
      P('Cómo abrir la app', 'h2'),
      tabla([
          ['Dónde', 'Cómo'],
          ['Navegador (Chrome o Edge)', 'En la carpeta del proyecto: <font face="Consolas">flutter run -d chrome</font>'],
          ['Celular Android', 'Instalar <font face="Consolas">build/app/outputs/flutter-apk/app-debug.apk</font> '
           'o ejecutar <font face="Consolas">flutter run</font> con el celular conectado'],
      ], [0.3, 0.7]),
      Spacer(1, 8),
      P('Cómo se navega', 'h2'),
      P('La barra inferior tiene cinco pestañas. La flecha de la parte superior regresa al inicio.'),
      tabla([
          ['Pestaña', 'Para qué sirve'],
          ['Inicio', 'Indicadores principales y caracterización de los accidentes'],
          ['Mapa', 'Dónde ocurren: mapa de calor y listas por comuna y por barrio'],
          ['Tendencias', 'Cuándo ocurren: por año, mes, día de la semana, hora y jornada'],
          ['Filtros', 'Elegir qué accidentes analizar'],
          ['Perfil', 'Acceso al asistente, el planificador, la complejidad y el estado del sistema'],
      ], [0.22, 0.78]),
      Spacer(1, 8),
      nota('<b>Regla importante:</b> los filtros aplican a toda la app. Si filtras 2022, el panel, '
           'el mapa, las tendencias y el planificador muestran solo 2022 hasta que los limpies.'),
      PageBreak()]

ANCHO_ACTUAL[0] = ANCHO_COLUMNA
h += pantalla('1. Pantalla de inicio', 'inicio.png', 'Pantalla de inicio', [
    P('Es la primera pantalla. Muestra el nombre del proyecto mientras se cargan los datos.'),
    *vinetas(['Espera a que el botón cambie de "Cargando datos…" a <b>Ingresar</b>.',
              'Toca <b>Ingresar</b> para abrir el panel principal.'], numeradas=True),
    P('La carga toma menos de un segundo. Si fallara, aparece el motivo y el botón '
      '<b>Reintentar</b>.'),
])
h += pantalla('2. Panel principal', 'panel.png', 'Panel principal sin filtros', [
    P('Resume los accidentes que cumplen los filtros activos.'),
    P('Indicadores', 'h3'),
    *vinetas([
        '<b>Total de accidentes.</b>',
        '<b>Accidentes graves:</b> con heridos o fallecidos.',
        '<b>Mayor frecuencia:</b> el día de la semana con más accidentes y la franja de dos horas '
        'más frecuente.',
        '<b>Vehículo más involucrado</b> y su porcentaje.',
    ]),
    P('Cuando se filtra un solo año, los dos primeros indicadores muestran la variación frente al '
      'año anterior. Verde es una baja y rojo un aumento. Para 2023, que está incompleto, se '
      'compara contra los mismos meses de 2022.'),
    P('Distribución', 'h3'),
    P('Elige <b>Últimos 12 meses</b>, <b>Últimos 3 años</b> o <b>Todo el período</b>. Toca una '
      'barra para ver su valor exacto.'),
    P('El botón de burbuja, arriba a la derecha, abre el asistente.'),
])
h += pantalla('2. Panel principal (continuación)', 'panel_abajo.png', 'Parte inferior del panel', [
    P('Desliza hacia abajo para ver la caracterización de los accidentes:'),
    *vinetas([
        '<b>Gravedad:</b> solo daños, con heridos y con fallecidos, en cantidad y porcentaje.',
        '<b>Vehículos involucrados:</b> ranking de tipos de vehículo.',
        '<b>Cantidad de vehículos por accidente:</b> 1, 2, 3 o 4 y más.',
        '<b>Tipo de accidente:</b> atropello, vehículo solo o entre vehículos.',
    ]),
    nota('Un accidente puede tener varios vehículos, por eso los porcentajes por vehículo suman más '
         'de 100 %. El tipo de accidente no viene en los datos: la app lo deduce de los actores '
         'registrados.'),
    Spacer(1, 6),
    P('Con un filtro activo aparece la barra "1 filtro activo", con los botones <b>Editar</b> y '
      '<b>Limpiar</b>.'),
])
h += pantalla('3. Filtros', 'filtros.png', 'Pantalla de filtros', [
    P('Permite elegir qué accidentes analizar. Los filtros se combinan entre sí.'),
    tabla([
        ['Filtro', 'Opciones'],
        ['Año', '2012 a 2023'],
        ['Mes', 'Enero a diciembre'],
        ['Día', 'Lunes a domingo'],
        ['Hora', 'Una jornada (madrugada, mañana, tarde, noche) o una hora exacta'],
        ['Comuna', 'Las 17 comunas y los corregimientos'],
        ['Gravedad', 'Solo daños, con heridos, con fallecidos o graves'],
        ['Tipo de vehículo', 'Automóvil, motocicleta, bus, bicicleta, peatón, etc.'],
    ], [0.3, 0.7]),
    Spacer(1, 6),
    *vinetas(['Elige las opciones en cada lista.',
              'Toca <b>Aplicar filtros</b>: la app vuelve al panel con los resultados.',
              'Para volver a ver todo, toca <b>Limpiar filtros</b>.'], numeradas=True),
])
h += pantalla('4. Análisis geográfico', 'mapa.png', 'Mapa de calor', [
    P('Muestra dónde se concentran los accidentes. Tiene tres vistas:'),
    *vinetas([
        '<b>Mapa:</b> cada mancha es un barrio, con un color según su densidad, de azul (muy baja) '
        'a rojo (muy alta). Se puede mover y acercar con los dedos. El botón de mira vuelve a '
        'centrar el mapa.',
        '<b>Por comuna:</b> ranking de las comunas con su porcentaje.',
        '<b>Por zona:</b> los 25 barrios con más accidentes.',
    ]),
    P('Debajo del mapa, el resumen muestra el total, el barrio con más accidentes, la comuna con más '
      'eventos y el horario de mayor incidencia.'),
    nota('Los datos originales no traen coordenadas. Cada punto es el barrio donde se registró el '
         'accidente, no la dirección exacta. Los accidentes sin barrio (4,9 %) cuentan en los '
         'totales, pero no aparecen en el mapa.'),
])
h += pantalla('5. Tendencias', 'tendencias.png', 'Tendencias temporales', [
    P('Responde a la pregunta "¿cuándo ocurren los accidentes?" con cinco gráficos:'),
    *vinetas(['Por año (línea)', 'Por mes del año', 'Por día de la semana', 'Por hora del día',
              'Por jornada']),
    P('Toca cualquier punto o barra para ver su valor.'),
    nota('2023 solo llega hasta septiembre, y desde agosto de 2022 los registros caen a casi la '
         'mitad, posiblemente por subregistro. Esos valores no son comparables con los años '
         'anteriores.'),
])
h += pantalla('6. Perfil', 'perfil.png', 'Perfil y herramientas', [
    P('Agrupa las herramientas adicionales:'),
    tabla([
        ['Opción', 'Para qué'],
        ['Asistente de preguntas', 'Preguntar en español sobre los datos'],
        ['Planificador de operativos', 'Saber dónde y cuándo ubicar puntos de control'],
        ['Complejidad algorítmica', 'Ver la clasificación P / NP y medir tiempos'],
        ['Estado del sistema', 'Revisar la conexión y la calidad de los datos'],
    ], [0.45, 0.55]),
])
h += pantalla('7. Asistente de preguntas', 'asistente_inicio.png', 'Respuestas con ranking', [
    P('Escribe una pregunta y toca la flecha de enviar o la tecla Enter. La primera vez, la '
      'pantalla ofrece ejemplos que se pueden tocar.'),
    P('Cada respuesta trae las cifras exactas y, si aplica, una gráfica. El botón <b>Ver en el '
      'panel</b> aplica las mismas condiciones a toda la app.'),
    P('Ejemplos que entiende', 'h3'),
    *vinetas([
        '¿Qué comuna tiene más accidentes?',
        '¿A qué hora ocurren más accidentes con moto?',
        'Top 5 barrios con más accidentes graves',
        '¿Cuántos accidentes con fallecidos hubo en 2018?',
        'Compara 2019 y 2020',
        '¿Qué porcentaje de accidentes en Cabecera son con heridos?',
        '¿Cuándo ocurren más atropellos?',
        '¿Cómo ha sido la tendencia de accidentes de moto?',
    ]),
])
h += pantalla('7. Asistente (continuación)', 'asistente.png', 'Pregunta sobre un dato inexistente', [
    P('Palabras que reconoce', 'h3'),
    tabla([
        ['Tipo', 'Ejemplos'],
        ['Años', '"2019", "entre 2015 y 2018", "pandemia", "último año"'],
        ['Mes y día', '"enero", "los viernes", "fin de semana", "entre semana"'],
        ['Horas', '"a las 7 de la noche", "entre las 7 y las 9", "en la madrugada"'],
        ['Lugar', '"comuna 15", "Cabecera", "barrio Provenza"'],
        ['Gravedad', '"fallecidos", "heridos", "graves", "solo daños"'],
        ['Vehículo', '"moto", "carro", "bus", "bicicleta", "atropellos"'],
        ['Respuesta', '"qué comuna", "más", "menos", "top 5", "compara", "porcentaje", '
                      '"promedio", "tendencia", "cuándo"'],
    ], [0.24, 0.76]),
    Spacer(1, 6),
    P('Lo que no responde', 'h3'),
    P('Preguntas sobre datos que no existen en el registro: clima, edad, sexo, alcohol, velocidad, '
      'causas, direcciones exactas o predicciones. En esos casos dice que el dato no está, en '
      'lugar de inventar una respuesta.'),
    nota('El asistente cuenta <b>accidentes, no personas</b>: "con fallecidos" no es el número de '
         'fallecidos. Y "más seguro" significa "con menos registros", no menos riesgo.'),
])
h += pantalla('8. Planificador de operativos', 'planificador.png', 'Plan recomendado', [
    P('Sugiere dónde, qué día y a qué hora ubicar operativos de control para cubrir la mayor '
      'cantidad de accidentes históricos. Solo recomienda: no actúa sobre la vía.'),
    *vinetas([
        'Si quieres, aplica filtros antes, por ejemplo solo accidentes graves o de moto.',
        'Elige cuántos <b>operativos</b> hay disponibles (1 a 8).',
        'Elige el <b>alcance</b> de cada uno: hasta qué distancia cubre comunas vecinas.',
        'Elige la <b>duración</b> del turno: 2, 4 o 6 horas.',
        'Toca <b>Calcular plan</b>.',
    ], numeradas=True),
    P('El resultado lista cada operativo con su comuna, día, horario y las comunas vecinas que '
      'también cubre. Cada comuna recibe máximo un operativo.'),
    P('La sección "Cómo se calculó" muestra cuántas combinaciones existen, cuántas se revisaron y '
      'si el plan es el óptimo demostrado. Con muchos operativos el cálculo se detiene a los 3 '
      'segundos y entrega el mejor plan encontrado.'),
])
h += pantalla('9. Complejidad algorítmica', 'complejidad.png', 'Tiempos medidos', [
    P('Muestra cada algoritmo de la app con su complejidad y su clase (P o NP-difícil).'),
    P('El botón <b>Medir en este dispositivo</b> cronometra los algoritmos en el teléfono o '
      'navegador. Puede tardar hasta unos 30 segundos, porque prueba el planificador exacto con '
      '1 a 6 operativos.'),
    P('Resultados', 'h3'),
    *vinetas([
        'Gráfica de tiempo contra cantidad de registros, para el filtrado y Merge Sort.',
        'Tiempos de la búsqueda binaria.',
        'Tabla del planificador: estados explorados y tiempo para cada número de operativos.',
    ]),
    P('La Parte B de este documento explica cómo leer estos resultados.'),
])
h += pantalla('10. Estado del sistema', 'estado_sistema.png', 'Conexión y calidad', [
    P('Tiene tres secciones:'),
    *vinetas([
        '<b>Datos locales:</b> registros cargados, tiempo de carga y duración de la última consulta.',
        '<b>Conexión:</b> prueba en vivo a Datos Abiertos Colombia y a los mapas de OpenStreetMap, '
        'con su latencia. El botón de recarga, arriba a la derecha, la repite.',
        '<b>Calidad de los datos:</b> qué corrigió la limpieza, como duplicados, gravedades y '
        'barrios unificados, y horas recuperadas.',
    ]),
    nota('Si no hay internet, las consultas y los gráficos siguen funcionando. Solo el fondo del '
         'mapa deja de cargar.'),
])
ANCHO_ACTUAL[0] = ANCHO
h += [Spacer(1, 6), P('Preguntas frecuentes', 'h2')]
for pregunta, respuesta in [
    ('No veo cambios después de filtrar.',
     'Comprueba que tocaste <b>Aplicar filtros</b>. La barra "filtro activo" del panel confirma que '
     'quedaron aplicados.'),
    ('El mapa sale gris.',
     'El fondo del mapa necesita internet. Revisa Perfil → Estado del sistema. Las manchas de '
     'calor y los rankings siguen funcionando.'),
    ('¿Por qué 2023 tiene tan pocos accidentes?',
     'Los datos llegan solo hasta septiembre de 2023, y desde agosto de 2022 hay menos registros.'),
    ('El asistente no entendió mi pregunta.',
     'Menciona al menos una variable: año, mes, día, hora, comuna, barrio, gravedad o vehículo. '
     'Por ejemplo: "¿qué barrio tiene más accidentes de moto?"'),
    ('El planificador dice "se agotó el tiempo".',
     'Con muchos operativos hay demasiadas combinaciones. El plan mostrado es el mejor encontrado, '
     'pero no está demostrado que sea el óptimo. Es un efecto esperado: la Parte B lo explica.'),
]:
    h += [KeepTogether([P(pregunta, 'h3'), P(respuesta)])]

# Parte B
h += [PageBreak(), P('Parte B. Complejidad algorítmica', 'h1'),
      P('Cada vez que se usa la app se ejecutan uno o varios algoritmos, y cada uno tiene su propia '
        'complejidad. La clase P o NP pertenece a cada problema, no al programa completo.'),
      tabla([
          ['Parte del sistema', 'Clase'],
          ['Consultas: filtros, indicadores, gráficos, mapa, rankings y asistente', '<b>P</b>'],
          ['Planificador de operativos, problema de decisión', '<b>NP-completo</b>'],
          ['Planificador de operativos, problema de optimización', '<b>NP-difícil</b>'],
      ], [0.75, 0.25]),
      Spacer(1, 8),
      P('Notación: <b>n</b> = 39.168 accidentes · <b>c</b> = categorías (17 comunas, 178 barrios, '
        '7 días…) · <b>q</b> = palabras de una pregunta · <b>k</b> = operativos · <b>m</b> = 1.428 '
        'candidatos · <b>s</b> = celdas que cubre un candidato.'),
      ]


def seccion(titulo, donde, parrafos):
    return [P(titulo, 'h2'), P(f'<b>Dónde aparece:</b> {donde}')] + parrafos


h += seccion('1. O(1): leer un dato guardado',
             'en las tarjetas del panel y al leer cualquier registro.', [
                 P('Los datos están guardados en columnas, como arreglos. Leer el accidente número '
                   '20.000 es ir directo a esa posición, sin recorrer los anteriores. Cuesta una '
                   'operación sin importar cuántos datos haya, la misma idea de '
                   '<font face="Consolas">example_lineal_01.py</font>.')])
h += seccion('2. O(log n): búsqueda binaria', 'cuando se filtra por año.', [
    P('Los accidentes están ordenados por fecha. Para ubicar dónde empieza 2019, la app mira la '
      'mitad de la lista, descarta la parte que no sirve y repite.'),
    *vinetas(['Con 39.168 registros bastan unos 16 pasos (log<sub>2</sub> 39.168 ≈ 15,3).',
              'Lo medido no cambia al aumentar los datos: siempre unos 0,15 µs.']),
])
h += seccion('3. O(n): filtrar y contar',
             'cada vez que se aplican filtros. Es el corazón de la app.', [
                 P('La consulta recorre los registros <b>una sola vez</b>. En esa misma pasada llena '
                   'todo lo que muestran las pantallas: totales, gráficos, mapa, gravedad y '
                   'vehículos. Es como la nómina de <font face="Consolas">example_lineal_02.py</font>.'),
                 *vinetas([
                     'Con filtro de año, la búsqueda binaria recorta el rango antes: el costo es '
                     'O(log n + r), con r los registros de ese año. Sin filtro de año, O(n).',
                     'Revisar los 7 filtros en cada registro cuesta siempre lo mismo y no cambia '
                     'la clase.',
                     '<b>Si n se duplica, el tiempo se duplica</b>: 126 µs, 285 µs, 550 µs y 899 µs '
                     'para 4.896, 9.792, 19.584 y 39.168 registros.',
                 ]),
             ])
h += seccion('4. O(n log n): Merge Sort',
             'en los rankings por comuna y por barrio, los vehículos y las listas del asistente.', [
                 P('Tras contar, hay que ordenar de mayor a menor. Se usa Merge Sort, el mismo de '
                   '<font face="Consolas">example_04.py</font>: divide la lista en mitades, ordena '
                   'cada una y las mezcla.'),
                 P('En la app se ordenan <b>categorías, no accidentes</b>: ordenar 178 barrios cuesta '
                   'c log c, unas 1.300 operaciones. La pantalla de complejidad lo mide con n números '
                   'aleatorios para que se vea la curva.'),
             ])
h += seccion('5. O(q): el asistente', 'al escribir una pregunta.', [
    P('Cada palabra se busca en diccionarios hash de meses, días, vehículos, comunas y barrios. Cada '
      'búsqueda cuesta O(1) en promedio, así que interpretar una pregunta de q palabras cuesta O(q). '
      'Luego se calcula con los puntos 3 y 4. El total, O(q + n + c log c), es polinomial.'),
])

h += [P('6. NP-difícil: el planificador de operativos', 'h2'),
      P('<b>Dónde aparece:</b> Perfil → Planificador → Calcular plan.'),
      P('<b>La pregunta:</b> con k operativos, máximo uno por comuna, ¿dónde, qué día y en qué turno '
        'se ubican para cubrir la mayor cantidad de accidentes históricos?'),
      P('<b>Por qué es difícil:</b> los operativos se solapan. Uno en el Centro también cubre las '
        'comunas vecinas, así que elegir los k mejores no es tomar los k más altos: hay que '
        'considerar combinaciones, y estas crecen muy rápido.'),
      tabla([['k', 'Combinaciones posibles'], ['1', '1.428'], ['3', '484 millones'],
             ['6', '11.653 billones']], [0.2, 0.8]),
      Spacer(1, 6),
      P('El problema se modela como <b>Cobertura Máxima ponderada con restricción de partición</b>. '
        'El universo son las celdas (comuna, día, hora), cada una con su número de accidentes. '
        'Hay 1.428 candidatos: 17 comunas × 7 días × 12 turnos. Las comunas se consideran '
        'vecinas según la distancia entre sus centros.'),
      P('Dos formas de resolverlo', 'h3'),
      tabla([
          ['', 'Voraz', 'Exacto (ramificación y poda)'],
          ['Idea', 'Cada ronda toma el operativo que más accidentes nuevos agrega',
           'Explora combinaciones y descarta las que no pueden superar la mejor encontrada'],
          ['Complejidad', 'O(k·m·s), polinomial', 'Exponencial en el peor caso'],
          ['Resultado', 'Aproximado; garantiza al menos 50 % del óptimo',
           'Óptimo demostrado, si termina en 3 s'],
          ['Medido', 'Cerca de 1 ms siempre', 'De 6,8 ms con k = 1 al límite de 3 s con k = 6'],
      ], [0.18, 0.36, 0.46]),
      Spacer(1, 6),
      P('La garantía de 50 % es un resultado clásico para funciones submodulares con este tipo de '
        'restricción (Fisher, Nemhauser y Wolsey, 1978). Sin la regla de una unidad por comuna '
        'sería 1 − 1/e ≈ 63 %.'),
      P('Cómo se demuestra que es NP-completo', 'h3'),
      *vinetas([
          '<b>Está en NP.</b> Si alguien entrega un plan, comprobar cuántos accidentes cubre es '
          'rápido: O(k·s). Verificar es fácil aunque encontrar sea difícil.',
          '<b>Es NP-difícil.</b> Conjunto Dominante, que ya se sabe NP-completo (Karp, 1972), se '
          'puede disfrazar de planificador. Cada vértice del grafo es una comuna con un accidente, '
          'el alcance de cada comuna son sus vecinos y cada comuna es su propio grupo. Existe un plan '
          'de k operativos que cubre todos los accidentes si y solo si el grafo tiene un conjunto '
          'dominante de tamaño k. Un algoritmo rápido para el planificador resolvería Conjunto '
          'Dominante.',
          '<b>Conclusión.</b> La versión de sí o no ("¿se pueden cubrir al menos P accidentes con k '
          'operativos?") es <b>NP-completa</b>. La versión "dame el mejor plan" es '
          '<b>NP-difícil</b>. No se dice NP-completa porque esa clase solo aplica a problemas de sí '
          'o no.',
      ], numeradas=True),
      nota('<b>Dos aclaraciones honestas.</b> La dureza es del caso general, cuando k y la entrada '
           'crecen; con k fijo, probar todo es polinomial, O(m<super>k</super>). Por eso la app limita '
           'k a 8 y el exacto a 3 segundos. Además, los datos de Bucaramanga no son el peor caso: la '
           'poda descarta casi todo y el voraz queda muy cerca del óptimo. No se debe afirmar que '
           '"siempre explota", porque no es lo medido.'),
      ]

# Anexo
h += [PageBreak(), P('Anexo. Resumen y mediciones', 'h1'),
      P('Qué se ejecuta en cada acción', 'h2'),
      tabla([
          ['Acción del usuario', 'Algoritmos', 'Complejidad total', 'Clase'],
          ['Ver un indicador', 'Lectura directa', 'O(1)', 'P'],
          ['Filtrar por año', 'Búsqueda binaria + recorrido', 'O(log n + r)', 'P'],
          ['Filtrar sin año', 'Recorrido', 'O(n)', 'P'],
          ['Ver un ranking', 'Recorrido + Merge Sort', 'O(n + c log c)', 'P'],
          ['Preguntar al asistente', 'Diccionarios + recorrido + orden', 'O(q + n + c log c)', 'P'],
          ['Plan rápido', 'Voraz', 'O(k·m·s)', 'P'],
          ['Plan óptimo', 'Ramificación y poda', 'Exponencial en el peor caso', 'NP-difícil'],
      ], [0.25, 0.32, 0.27, 0.16]),
      Spacer(1, 6),
      P('Tiempo según la cantidad de registros', 'h2'),
      P('Dart VM, mediana de 7 repeticiones. Los tiempos tan pequeños tienen ruido: hay que leer la '
        'tendencia y no cada valor.'),
      tabla([
          ['n', 'Búsqueda binaria', 'Filtrado, O(n)', 'Merge Sort, O(n log n)'],
          ['4.896', '0,12 µs', '126 µs', '3.437 µs'],
          ['9.792', '0,15 µs', '285 µs', '7.648 µs'],
          ['19.584', '0,18 µs', '550 µs', '13.044 µs'],
          ['39.168', '0,16 µs', '899 µs', '23.593 µs'],
      ], [0.19, 0.27, 0.27, 0.27]),
      Spacer(1, 6),
      P('Planificador según el número de operativos', 'h2'),
      P('Todos los accidentes, alcance de 1,5 km, turnos de 4 horas y 1.428 candidatos.'),
      tabla([
          ['k', 'Combinaciones', 'Estados explorados', 'Exacto', 'Voraz', 'Calidad voraz'],
          ['1', '1.428', '1', '6,8 ms', '3,7 ms', '100 %'],
          ['2', '1,0 millones', '18', '27,1 ms', '1,5 ms', '100 %'],
          ['3', '484,3 millones', '32', '33,8 ms', '1,0 ms', '98,6 %'],
          ['4', '172,5 mil millones', '74', '31,1 ms', '0,9 ms', '98,7 %'],
          ['5', '49,1 billones', '501', '195 ms', '0,9 ms', '99,3 %'],
          ['6', '11.653,8 billones', '8.248 o más', '3 s (límite)', '1,4 ms', '99,4 % o menos'],
      ], [0.07, 0.23, 0.18, 0.16, 0.14, 0.22]),
      Spacer(1, 6),
      P('Con k = 6 se agotó el tiempo: ese plan no tiene óptimo demostrado, y la calidad del voraz se '
        'compara con la mejor solución encontrada. Los estados explorados suben de 1 a miles, '
        'mientras el voraz casi no cambia: esa es la diferencia práctica entre P y NP-difícil.'),
      P('Plan recomendado con k = 3: Comuna 13 Oriental, viernes de 14:00 a 18:00; Comuna 6 La '
        'Concordia, martes de 12:00 a 16:00; Comuna 12 Cabecera del Llano, sábado de 10:00 a 14:00. '
        'Cubre 2.372 de 39.168 accidentes.'),
      P('Referencias', 'h2'),
      *vinetas([
          'Karp, R. M. (1972). Reducibility among combinatorial problems. En <i>Complexity of '
          'Computer Computations</i>. Plenum Press.',
          'Nemhauser, G. L., Wolsey, L. A., y Fisher, M. L. (1978). An analysis of approximations for '
          'maximizing submodular set functions—I. <i>Mathematical Programming, 14</i>, 265-294.',
          'Fisher, M. L., Nemhauser, G. L., y Wolsey, L. A. (1978). An analysis of approximations for '
          'maximizing submodular set functions—II. <i>Mathematical Programming Study, 8</i>, 73-87.',
          'Alcaldía de Bucaramanga. Accidentes de Tránsito ocurridos en el Municipio de Bucaramanga '
          '[conjunto de datos]. Datos Abiertos Colombia.',
      ]),
      ]

doc = SimpleDocTemplate(SALIDA, pagesize=A4, leftMargin=2 * cm, rightMargin=2 * cm,
                        topMargin=2 * cm, bottomMargin=2.2 * cm,
                        title='Accidentalidad Vial Bucaramanga: manual y complejidad',
                        author='Agudelo, Restrepo, Montoya y Saldarriaga')
doc.build(h, onFirstPage=portada, onLaterPages=pie_pagina)
print(SALIDA)
