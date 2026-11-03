import 'package:flutter/material.dart';

import '../tema.dart';
import 'asistente_pantalla.dart';
import 'dashboard_pantalla.dart';
import 'filtros_pantalla.dart';
import 'geografico_pantalla.dart';
import 'perfil_pantalla.dart';
import 'tendencias_pantalla.dart';

/// Contenedor con la barra de navegación inferior de los mockups.
class PrincipalPantalla extends StatefulWidget {
  const PrincipalPantalla({super.key});

  @override
  State<PrincipalPantalla> createState() => _PrincipalPantallaState();
}

class _PrincipalPantallaState extends State<PrincipalPantalla> {
  static const int _inicio = 0;
  static const int _filtros = 3;

  int _indice = _inicio;

  void _ir(int indice) => setState(() => _indice = indice);

  @override
  Widget build(BuildContext context) {
    final vistas = [
      DashboardPantalla(alAbrirFiltros: () => _ir(_filtros)),
      const GeograficoPantalla(),
      const TendenciasPantalla(),
      FiltrosPantalla(alAplicar: () => _ir(_inicio)),
      const PerfilPantalla(),
    ];

    return Scaffold(
      appBar: _indice == _inicio
          ? AppBar(
              leading: const Padding(
                padding: EdgeInsets.only(left: 14),
                child: Icon(Icons.car_crash_outlined, size: 28),
              ),
              titleSpacing: 12,
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accidentalidad Vial',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  Text('Bucaramanga', style: TextStyle(fontSize: 12)),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Preguntar al asistente',
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AsistentePantalla()),
                  ),
                ),
              ],
            )
          : AppBar(
              leading: IconButton(
                tooltip: 'Volver al inicio',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _ir(_inicio),
              ),
              title: Text(
                const ['', 'Análisis geográfico', 'Tendencias', 'Filtros de consulta', 'Perfil'][_indice],
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
      body: IndexedStack(index: _indice, children: vistas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: _ir,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: Colores.primario), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map, color: Colores.primario), label: 'Mapa'),
          NavigationDestination(icon: Icon(Icons.show_chart), selectedIcon: Icon(Icons.show_chart, color: Colores.primario), label: 'Tendencias'),
          NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune, color: Colores.primario), label: 'Filtros'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: Colores.primario), label: 'Perfil'),
        ],
      ),
    );
  }
}
