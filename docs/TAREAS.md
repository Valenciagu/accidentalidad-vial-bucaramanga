# Tablero de tareas

Estados: ⬜ Pendiente · 🔄 En curso · ✅ Hecha · ⛔ Bloqueada

Se actualiza cada vez que una tarea termina. Si retomas el proyecto, empieza por aquí.

## Fase 0: Análisis

| # | Tarea | Estado |
|---|-------|--------|
| 0.1 | Leer el Word y extraer requerimientos RF-01 a RF-11 | ✅ |
| 0.2 | Perfilar el dataset y detectar problemas de calidad | ✅ |
| 0.3 | Decidir clase de complejidad, IA y arquitectura | ✅ |

## Fase 1: Datos (ETL)

| # | Tarea | Estado |
|---|-------|--------|
| 1.1 | Geocodificar barrios con Nominatim | ✅ |
| 1.2 | Script de limpieza `tool/preprocesar_datos.py` | ✅ |
| 1.3 | Generar `assets/datos/accidentes.json` | ✅ |

## Fase 2: Dominio (Clean Architecture)

| # | Tarea | Estado |
|---|-------|--------|
| 2.1 | Entidades, contratos y filtros | ✅ |
| 2.2 | Algoritmos: filtrado, búsqueda binaria, merge sort | ✅ |
| 2.3 | Planificador NP-difícil (exacto y voraz) | ✅ |
| 2.4 | Intérprete de preguntas en español | ✅ |

## Fase 3: Datos e interfaz

| # | Tarea | Estado |
|---|-------|--------|
| 3.1 | Capa `data`: fuente de assets y conectividad | ✅ |
| 3.2 | Inicio y dashboard | ✅ |
| 3.3 | Filtros | ✅ |
| 3.4 | Análisis geográfico | ✅ |
| 3.5 | Tendencias | ✅ |
| 3.6 | Perfil, estado del sistema, asistente, planificador, complejidad | ✅ |

## Fase 4: Verificación y documentación

| # | Tarea | Estado |
|---|-------|--------|
| 4.1 | Tests de dominio y regla de dependencias | ✅ |
| 4.2 | Compilar y revisar la app corriendo en Chrome | ✅ |
| 4.3 | `docs/CONTEXTO_PROYECTO.md` | ✅ |
| 4.4 | `docs/CONTEXTO_TECNICO.md` | ✅ |
| 4.5 | Capturas para el informe en `docs/capturas/` | ✅ |
| 4.6 | Compilar APK de Android (debug) | ✅ |
| 4.7 | PDF con manual de usuario y complejidad (`docs/Manual_y_Complejidad.pdf`) | ✅ |

## Fase 5: Pendientes del equipo

| # | Tarea | Estado |
|---|-------|--------|
| 5.1 | Probar en un celular o emulador Android | ⬜ |
| 5.2 | Corregir en el Word las diferencias listadas en `CONTEXTO_PROYECTO.md` | ⬜ |
| 5.3 | Agregar al Word el asistente, el planificador y la complejidad | ⬜ |
| 5.4 | Llenar la sección 4.2 del Word | ⬜ |
| 5.5 | Insertar las capturas en las figuras 5.4 a 5.8 | ⬜ |

## Fase 6: Mejoras opcionales

| # | Tarea | Estado |
|---|-------|--------|
| 6.1 | Mejorar coordenadas de los 46 barrios aproximados | ⬜ |
| 6.2 | Refinar el intérprete con preguntas reales de los usuarios | ⬜ |

## Fase 7: Escala con datos sintéticos

| # | Tarea | Estado |
|---|-------|--------|
| 7.1 | Generador de hasta 1.100.000 accidentes sintéticos a partir de los reales | ✅ |
| 7.2 | Variable `cantidadAccidentes` en `lib/configuracion.dart` con validación y aviso | ✅ |
| 7.3 | Mostrar reales y sintéticos en Estado del sistema y Perfil | ✅ |
| 7.4 | Mediciones con 1.100.000 registros en `CONTEXTO_TECNICO.md` | ✅ |
| 7.5 | Probar la app en Chrome y Android con 1.000.000 (tiempo de carga y pantalla de complejidad) | ⬜ |
| 7.6 | Actualizar capturas y el PDF si se presentan cifras con sintéticos | ⬜ |
