# Contexto del proyecto

Qué es el proyecto, qué se pactó en el informe, qué dicen los datos y qué se decidió. La parte de código y complejidad está en [CONTEXTO_TECNICO.md](CONTEXTO_TECNICO.md). El avance está en [TAREAS.md](TAREAS.md).

## Resumen

- **Proyecto:** Proyecto Pedagógico Integrador, segundo semestre, Ingeniería en Software, Tecnológico de Antioquia.
- **Título:** Factores asociados a la ocurrencia de accidentes de tránsito en Bucaramanga.
- **Integrantes:** Juan Felipe Agudelo Valencia, Diego Alejandro Restrepo Sánchez, Iván Dario Montoya López y Mateo Saldarriaga Vidales.
- **Producto:** aplicación Flutter para consultar y visualizar accidentes históricos, dirigida a personas sin formación técnica.
- **Fuente de verdad del alcance:** `FORMATO PPI INFRESTRUCTURA Y PROYECTOS PPI (2).docx`.
- **Datos:** `3._Accidentes_de_Transito_ocurridos_en_el_Municipio_de_Bucaramanga_20260907.csv`, de Datos Abiertos Colombia.

## Requerimientos y cómo se cumplen

| Código | Requerimiento | Cumplimiento |
|---|---|---|
| RF-01 | Carga de datos históricos | Asset dentro de la app, generado desde el CSV |
| RF-02 | Limpieza y depuración | `tool/preprocesar_datos.py`; resultado visible en Estado del sistema |
| RF-03 | Organización por variables | Tabla columnar ordenada por fecha |
| RF-04 | Indicadores generales | Panel principal |
| RF-05 | Filtros individuales o combinados | Pantalla Filtros (año, mes, día, hora, comuna, gravedad, vehículo) |
| RF-06 | Restablecer filtros | Botón Limpiar filtros |
| RF-07 | Análisis temporal | Pantalla Tendencias |
| RF-08 | Análisis geográfico | Pantalla Mapa: mapa de calor, ranking por comuna y por zona |
| RF-09 | Caracterización | Panel principal: gravedad, tipo y cantidad de vehículos |
| RF-10 | Resultados coherentes | Un solo cálculo alimenta todas las pantallas |
| RF-11 | Estado de la conexión | Pantalla Estado del sistema, con peticiones reales |

Las seis pantallas del informe existen: inicio, panel, filtros, geográfico, tendencias y estado del sistema.

## Funciones agregadas al informe

Estas funciones no están en el Word. Si se conservan, deben agregarse a los requerimientos:

- **Asistente de preguntas:** responde en español calculando sobre los datos.
- **Planificador de operativos:** recomienda dónde, qué día y a qué hora ubicar operativos. Aporta el problema NP-difícil y concreta la "acción correctiva" del lazo cerrado de la sección 2.2. Solo informa: no actúa sobre la vía, así que respeta el alcance.
- **Pantalla de complejidad:** muestra la clasificación y mide tiempos en el dispositivo.

## Qué dicen los datos

39.193 filas originales; 39.168 después de quitar duplicados exactos. Los accidentes van del 1 de enero de 2012 al 30 de septiembre de 2023.

| Indicador | Valor |
|---|---|
| Accidentes con solo daños | 19.589 (50,0 %) |
| Accidentes con heridos | 18.970 (48,4 %) |
| Accidentes con fallecidos | 609 (1,6 %) |
| Vehículo más involucrado | Automóvil, 61,8 % |
| Motocicleta | 53,4 % |
| Comuna con más accidentes | Comuna 12, Cabecera del Llano (16,4 %) |
| Barrio con más accidentes | Centro |

Un accidente puede tener varios vehículos, por eso los porcentajes por vehículo suman más de 100 %.

### Limpieza aplicada

| Problema | Registros | Tratamiento |
|---|---:|---|
| Duplicados exactos | 25 | Eliminados |
| `Con Muertos` y `Con muertos` | 106 | Unificados |
| Barrios con mayúsculas distintas | 4.598 | Unificados |
| Horas mal escritas (`2`, `6.3`, `7.4`) | 3 | Recuperadas como hora entera |
| Barrio con el valor `Bucaramanga` | 357 | Se conserva la comuna; quedan sin barrio |
| Sin comuna ni barrio | 1.553 | Se conservan; cuentan en totales, no en el mapa |
| DÍA o MES contradicen a FECHA | 188 | Manda FECHA; casi todos son de 2014 |
| Más de 12 vehículos en un accidente | 3 | Tope de 12 (hay uno con 29 automóviles) |

### Limitaciones que hay que decir en la sustentación

- **El dataset no trae coordenadas.** Se geolocalizaron los barrios con OpenStreetMap y se validaron contra la comuna del CSV. El 92,3 % de los accidentes tiene punto de barrio, el 2,8 % usa el centro de su comuna y el 4,9 % no aparece en el mapa. El mapa muestra barrios, no direcciones exactas.
- **2023 está incompleto:** llega a septiembre. Por eso se compara contra los mismos meses de 2022.
- **Caída desde agosto de 2022:** pasa de cerca de 220 a 120 registros mensuales. Parece subregistro, no una mejora real; es una hipótesis que el dataset no permite confirmar. 2020 también cae, y coincide con la pandemia.
- **Se cuentan accidentes, no personas.** "Con fallecidos" no es el número de fallecidos.
- **Pocos registros no significan seguridad.** No hay datos de tráfico para calcular un riesgo real por zona.

## Diferencias entre el Word y la realidad

Conviene corregirlas antes de la versión final del informe:

1. **Tipo de accidente:** RF-03 y los objetivos lo mencionan, pero no existe en el dataset. La app lo deriva: atropello, vehículo solo o entre vehículos. El informe debe decir que es derivado.
2. **Coordenadas:** la sección 2.2 habla de "coordenadas de la comuna". No existen en la fuente.
3. **Tiempo real y alertas:** las secciones 2.2, 2.2.1 y 5.1 hablan de alertas visuales y respuesta en tiempo real, pero la sección 1.4 lo excluye. La app no genera alertas ni usa datos en vivo.
4. **Conectividad:** el informe dice que la consulta depende de Wi-Fi o 4G. La app funciona sin internet con sus datos locales; solo el mapa base requiere conexión.
5. **Cifras de los mockups:** 2.843 accidentes, Comuna 14 o motos con 42 % son ilustrativas. Las capturas finales deben ser las de la app.
6. **Barra inferior:** el mockup tiene cuatro pestañas; se agregó Tendencias, que es una pantalla exigida.
7. **Campana de notificaciones:** se reemplazó por el acceso al asistente, porque no hay alertas.
8. **RF-02:** el nombre tiene un error de edición ("Consulta Limpieza y depuración de datos del estado del sistema").
9. **Sección 4.2:** sigue con el texto de la plantilla sobre microcontroladores. Se puede llenar con [CONTEXTO_TECNICO.md](CONTEXTO_TECNICO.md).
10. **Costos:** la tabla de componentes de la sección 4.1 sigue sin precios.

## Decisiones

| Decisión | Motivo |
|---|---|
| No usar OpenAI | El informe exige herramientas gratuitas; una llave en la app no es segura; un modelo puede inventar cifras; se pierde el funcionamiento sin internet |
| Asistente local con diccionarios | Responde con cifras exactas y declara lo que el dataset no registra |
| Datos dentro de la app | Sin servidor ni costos; carga inmediata |
| Clean Architecture | Pedido del equipo; verificada con un test |
| Máximo un operativo por comuna | Sin esa regla todos caen en la misma zona central |
| "Graves" = con heridos o fallecidos | El dataset solo tiene tres niveles de gravedad |

### Alcance real del asistente

Responde cualquier pregunta que se pueda calcular con las variables del dataset: año, mes, día, hora, comuna, barrio, gravedad, vehículo, tipo derivado, propietario y entidad. Hace conteos, rankings, comparaciones, porcentajes, promedios y tendencias.

No responde preguntas abiertas ni causas, porque esa información no existe en los datos: clima, edad, sexo, alcohol, velocidad, dirección exacta o predicciones. En esos casos lo dice en lugar de inventar. Una redacción muy distinta a las previstas puede no entenderse, y la app lo indica.
