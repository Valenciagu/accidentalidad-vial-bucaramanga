/// Ajustes que el equipo cambia a mano antes de ejecutar la app.
library;

/// Cantidad de accidentes que carga la app.
///
/// Los primeros 39.168 son los reales del CSV; el resto son sintéticos, hasta
/// un total de 1.100.000. Si el valor es menor o igual a 0 la app muestra un
/// aviso y carga 1; si es mayor que 1.100.000 muestra el aviso y carga 1.100.000.
const int cantidadAccidentes = 123456;
