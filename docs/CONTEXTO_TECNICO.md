# Contexto técnico

Arquitectura, algoritmos, clase de complejidad y operación del proyecto. Sirve como base para la sección 4.2 del informe.

## Conclusión de complejidad

| Parte del sistema | Clase |
|---|---|
| Consultas: filtros, indicadores, gráficos, mapa, rankings, asistente | **P** |
| Planificador de operativos, problema de decisión | **NP-completo** |
| Planificador de operativos, problema de optimización | **NP-difícil** |

La app no es "NP" en bloque: la clase pertenece a cada problema, no al programa. Filtrar y ordenar están en P. Técnicamente también están en NP, porque P ⊆ NP, pero decir solo "NP" sería engañoso. Lo interesante aparece únicamente en el planificador.

## Algoritmos

n: registros · c: categorías · q: palabras · k: operativos · m: candidatos · s: celdas por candidato

| Algoritmo | Uso | Complejidad | Archivo |
|---|---|---|---|
| Acceso por posición | Leer un conteo o un registro | O(1) | [conjunto_accidentes.dart](../lib/domain/entidades/conjunto_accidentes.dart) |
| Búsqueda binaria | Ubicar un año en los datos ordenados | O(log n) | [busqueda_binaria.dart](../lib/domain/algoritmos/busqueda_binaria.dart) |
| Filtrado y agregación | Actualizar todas las pantallas | O(log n + r), peor caso O(n) | [consultar_accidentes.dart](../lib/domain/casos_uso/consultar_accidentes.dart) |
| Merge Sort | Rankings | O(c log c) | [merge_sort.dart](../lib/domain/algoritmos/merge_sort.dart) |
| Intérprete | Entender una pregunta | O(q) esperado, con tablas hash | [interprete_preguntas.dart](../lib/domain/asistente/interprete_preguntas.dart) |
| Verificar un plan | Certificado de NP | O(k·s) | [cobertura_maxima.dart](../lib/domain/algoritmos/cobertura_maxima.dart) |
| Planificador voraz | Plan aproximado | O(k·m·s) | [cobertura_maxima.dart](../lib/domain/algoritmos/cobertura_maxima.dart) |
| Ramificación y poda | Plan óptimo | O(C(m, k)·m·s) en el peor caso | [cobertura_maxima.dart](../lib/domain/algoritmos/cobertura_maxima.dart) |

r son los registros del rango de años consultado. El número de filtros es constante, por eso no aparece en la fórmula.

## El problema NP-difícil

**Planificación de operativos.** Un operativo es un punto base en una comuna, un día de la semana, durante un turno de varias horas. Cubre los accidentes históricos de las comunas a su alcance durante el turno. Con k operativos, y máximo uno por comuna, hay que elegir los que cubran más accidentes.

Modelo: **Cobertura Máxima ponderada con restricción de partición**.

- Universo: celdas (comuna, día, hora), con peso igual a sus accidentes. Son 168 celdas por comuna.
- Subconjuntos: 17 comunas × 7 días × 12 turnos = 1.428 candidatos. Se solapan en zona y en horario.
- Las comunas se consideran vecinas según la distancia entre sus centros, con la fórmula de Haversine.

**Versión de decisión.** Dados k y un valor P, ¿existe un plan de k operativos que cubra al menos P accidentes?

**Pertenece a NP.** El certificado es el plan mismo. `verificarCobertura` calcula lo que cubre en O(k·s), tiempo polinomial.

**Es NP-difícil.** Reducción desde Conjunto Dominante, que es NP-completo (Karp, 1972). Dado un grafo G = (V, E) y un entero k:

1. Cada vértice se vuelve una comuna con un accidente, todos en una misma franja horaria.
2. El alcance de cada comuna es su vecindad cerrada en G.
3. Cada comuna es su propio grupo, y P = |V|.

La construcción es polinomial. Existe un plan de k operativos que cubre |V| accidentes si y solo si G tiene un conjunto dominante de tamaño k. Por tanto, resolver el planificador en tiempo polinomial resolvería Conjunto Dominante, y el problema es NP-completo.

**Optimización.** Encontrar el mejor plan es al menos tan difícil como decidir, así que es NP-difícil. No se dice NP-completo porque esa clase solo aplica a problemas de sí o no.

**Dos precisiones para la sustentación:**

- La dureza es del caso general, con k y el tamaño de la entrada creciendo. Con k fijo, probar todo es polinomial: O(mᵏ). Por eso la app limita k a 8 y el exacto a 3 segundos.
- Nuestros datos no son una instancia "peor caso". La poda explora una fracción mínima del espacio. Decir que el exacto siempre explota sería falso; lo medido está abajo.

### Por qué hay dos algoritmos

| | Voraz | Exacto |
|---|---|---|
| Tiempo | Polinomial | Exponencial en el peor caso |
| Resultado | Aproximado | Óptimo, si termina a tiempo |
| Garantía | Mínimo 50 % del óptimo | Óptimo demostrado |

La garantía de 50 % es para optimizar una función submodular monótona sobre un matroide (Fisher, Nemhauser y Wolsey, 1978). Sin la regla de una unidad por comuna sería 1 − 1/e ≈ 63 % (Nemhauser, Wolsey y Fisher, 1978). El test con 300 instancias comprueba las dos.

La poda funciona porque la ganancia es submodular: lo que falta por cubrir no supera la suma de las mayores ganancias individuales restantes.

## Mediciones

Dart VM, en el computador de desarrollo. Mediana de 7 repeticiones. Se reproducen con:

```
flutter test test/medicion_planificador_test.dart --reporter=expanded
```

### Según la cantidad de registros

| n | Búsqueda binaria | Filtrado | Merge Sort |
|---:|---:|---:|---:|
| 4.896 | 0,12 µs | 126 µs | 3.437 µs |
| 9.792 | 0,15 µs | 285 µs | 7.648 µs |
| 19.584 | 0,18 µs | 550 µs | 13.044 µs |
| 39.168 | 0,16 µs | 899 µs | 23.593 µs |

Con los 1.100.000 registros (reales + sintéticos):

| n | Búsqueda binaria | Filtrado | Merge Sort |
|---:|---:|---:|---:|
| 137.500 | 0,13 µs | 3.542 µs | 102.296 µs |
| 275.000 | 0,10 µs | 4.319 µs | 262.064 µs |
| 550.000 | 0,22 µs | 9.319 µs | 482.894 µs |
| 1.100.000 | 0,12 µs | 19.003 µs | 1.026.831 µs |

La búsqueda binaria casi no cambia con n 28 veces mayor, el filtrado sigue creciendo de forma lineal y Merge Sort crece como n log n. El planificador tarda lo mismo con 39.168 o con 1.100.000 registros, porque trabaja sobre los conteos por celda (comuna, día, hora) y no sobre los registros: su tamaño es m, no n.

Merge Sort se mide con n números aleatorios, igual que `example_04.py`. En la app ordena categorías, que son muchas menos. El filtrado se duplica cuando n se duplica, como se espera de O(n). Los tiempos tan pequeños tienen ruido del compilador, así que hay que leer la tendencia y no cada valor.

### Planificador según los operativos

Todos los accidentes, alcance de 1,5 km, turnos de 4 horas y 1.428 candidatos.

| k | Combinaciones posibles | Estados explorados | Exacto | Voraz | Calidad del voraz |
|---:|---:|---:|---:|---:|---:|
| 1 | 1.428 | 1 | 6,8 ms | 3,7 ms | 100 % |
| 2 | 1,0 millones | 18 | 27,1 ms | 1,5 ms | 100 % |
| 3 | 484,3 millones | 32 | 33,8 ms | 1,0 ms | 98,6 % |
| 4 | 172,5 mil millones | 74 | 31,1 ms | 0,9 ms | 98,7 % |
| 5 | 49,1 billones | 501 | 195 ms | 0,9 ms | 99,3 % |
| 6 | 11.653,8 billones | 8.248 o más | 3 s (límite) | 1,4 ms | 99,4 % o menos |

En k = 6 se agotó el tiempo: ese plan no tiene óptimo demostrado, y la calidad del voraz se compara con la mejor solución encontrada, no con el óptimo. El tiempo del exacto no crece de forma perfectamente regular porque depende de cuánto pode cada instancia. Lo importante es la tendencia: los estados suben de 1 a miles, mientras el voraz casi no cambia.

Plan para k = 3: Comuna 13 Oriental el viernes de 14:00 a 18:00, Comuna 6 La Concordia el martes de 12:00 a 16:00 y Comuna 12 Cabecera del Llano el sábado de 10:00 a 14:00. Cubre 2.372 de 39.168 accidentes.

## Clean Architecture

```
presentation  ──►  domain  ◄──  data
                     ▲
              di.dart compone las capas
```

| Capa | Carpeta | Contiene | Puede importar |
|---|---|---|---|
| Dominio | [lib/domain](../lib/domain) | Entidades, contratos, casos de uso, algoritmos, intérprete | Solo Dart y `core` |
| Datos | [lib/data](../lib/data) | Lectura del asset y comprobación HTTP | `domain` |
| Presentación | [lib/presentation](../lib/presentation) | Pantallas, widgets, controlador | `domain` |
| Núcleo | [lib/core](../lib/core) | Formatos en Dart puro | Nada |
| Composición | [lib/di.dart](../lib/di.dart) | Une las implementaciones | Todo |

[arquitectura_test.dart](../test/arquitectura_test.dart) falla si alguien rompe la regla de dependencias.

Flujo de una consulta: la pantalla llama a `ControladorApp`, este ejecuta `ConsultarAccidentes`, y todas las pantallas se redibujan desde el mismo `Resumen`. Así se cumple RF-10.

### Estructura de datos

`ConjuntoAccidentes` guarda una columna por variable en arreglos tipados, ordenados por fecha. El orden habilita la búsqueda binaria; los arreglos tipados dan acceso O(1) y usan poca memoria.

## Datos y herramientas

```
CSV → tool/geocodificar_barrios.py → tool/datos/barrios_geo.json
CSV + barrios_geo.json → tool/preprocesar_datos.py → assets/datos/accidentes.json
```

El ETL es O(n log n) por el ordenamiento final. Para regenerar el asset (Python 3, sin dependencias):

```
python tool/preprocesar_datos.py
```

El PDF de manual y complejidad se regenera después de actualizar `docs/capturas/` (requiere `pip install reportlab`):

```
python tool/generar_manual_pdf.py .
```

`barrios_geo.json` se conserva en el proyecto para no volver a consultar Nominatim, que limita a una petición por segundo.

### Datos sintéticos y cantidad de registros

La cantidad que carga la app se define en [lib/configuracion.dart](../lib/configuracion.dart):

```dart
const int cantidadAccidentes = 1000000; // por defecto
```

Se comporta como una lista fija de 1.100.000 accidentes de la que se toman los primeros `cantidadAccidentes`:

- Los primeros 39.168 son los reales. Si se piden menos, se toma una muestra aleatoria de los reales.
- El resto son sintéticos generados en el arranque por [generador_sintetico.dart](../lib/data/generadores/generador_sintetico.dart). La semilla es fija, así que siempre salen los mismos y pedir 300.000 incluye los sintéticos de pedir 102.356.
- Cada sintético copia los atributos de un accidente real al azar (hora, barrio, gravedad, vehículos, empresa, policía) y recibe otra fecha del mismo mes y día de la semana. Así conserva las distribuciones y las correlaciones reales.
- Si el valor es menor o igual a 0, la pantalla de inicio muestra "No hay esa cantidad de elementos en la lista" y carga 1. Si es mayor que 1.100.000, muestra el mismo aviso y carga 1.100.000. La regla está en [cantidad_registros.dart](../lib/domain/entidades/cantidad_registros.dart).

Generar 1.100.000 registros tarda unos 0,3 s en la VM de Dart: O(n + d), porque se ordenan por fecha con conteo sobre los d días del calendario. Los sintéticos no se guardan en un archivo: un JSON de ese tamaño pesaría decenas de MB. En Estado del sistema se ve cuántos registros son reales y cuántos sintéticos.

## Cómo ejecutar

```
flutter pub get
flutter run -d chrome
flutter test
```

Para Android se requiere un emulador o dispositivo. Primero hay que aceptar las licencias:

```
flutter doctor --android-licenses
flutter run
```

## CI/CD

[.github/workflows/ci_cd.yml](../.github/workflows/ci_cd.yml) corre en GitHub Actions:

```
push o pull request a main
  └─ CI: flutter pub get → flutter analyze → flutter test
       └─ si pasa y es push a main
            └─ CD: flutter build web → publica build/web en la rama gh-pages
```

- **CI (integración continua):** cada cambio se verifica solo, en una máquina limpia. Un pull request con pruebas rotas queda en rojo.
- **CD (despliegue continuo):** si la CI pasa, el sitio de GitHub Pages se actualiza sin pasos manuales. Si la CI falla, no se despliega.
- `main` guarda el código fuente; `gh-pages` guarda solo la app compilada, porque GitHub Pages sirve archivos estáticos y no compila Dart.
- La prueba de la cantidad configurada hace fallar la CI si se sube un `cantidadAccidentes` fuera de 1..1.100.000.
- El historial de ejecuciones está en la pestaña **Actions** del repositorio.

## Pruebas

| Archivo | Comprueba |
|---|---|
| [algoritmos_test.dart](../test/algoritmos_test.dart) | Exacto contra fuerza bruta, garantías del voraz, reducción desde Conjunto Dominante |
| [consultas_test.dart](../test/consultas_test.dart) | Cifras contra el CSV crudo, intérprete, respuestas, planificador |
| [arquitectura_test.dart](../test/arquitectura_test.dart) | Regla de dependencias |
| [sinteticos_test.dart](../test/sinteticos_test.dart) | Validación de la cantidad, generador reproducible, ordenado y con proporciones reales |
| [medicion_planificador_test.dart](../test/medicion_planificador_test.dart) | Imprime las mediciones de este documento |

## Dependencias

`flutter_map` y `latlong2` para el mapa, `fl_chart` para gráficos y `http` para el estado del sistema. El mapa usa teselas de OpenStreetMap, y su política pide atribución visible; la app la muestra. Para un despliegue público con mucho tráfico habría que cambiar de proveedor.

## Referencias de algoritmos

- Karp, R. M. (1972). Reducibility among combinatorial problems. En *Complexity of Computer Computations*. Plenum Press.
- Nemhauser, G. L., Wolsey, L. A., y Fisher, M. L. (1978). An analysis of approximations for maximizing submodular set functions—I. *Mathematical Programming, 14*, 265-294.
- Fisher, M. L., Nemhauser, G. L., y Wolsey, L. A. (1978). An analysis of approximations for maximizing submodular set functions—II. *Mathematical Programming Study, 8*, 73-87.
