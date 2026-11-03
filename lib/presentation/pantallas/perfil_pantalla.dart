import 'package:flutter/material.dart';

import '../../core/formato.dart';
import '../../domain/entidades/catalogos.dart';
import '../app.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import 'asistente_pantalla.dart';
import 'complejidad_pantalla.dart';
import 'estado_sistema_pantalla.dart';
import 'planificador_pantalla.dart';

class PerfilPantalla extends StatelessWidget {
  const PerfilPantalla({super.key});

  void _abrir(BuildContext context, Widget pantalla) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    final datos = ProveedorControlador.de(context).datos;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Tarjeta(
          child: Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Colores.primarioSuave,
                child: Icon(Icons.person, color: Colores.primario, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Usuario',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${formatoNumero(datos.n)} accidentes · ${datos.anioMinimo} a '
                      '${nombresMeses[datos.ultimoMes - 1].toLowerCase()} de ${datos.anioMaximo}',
                      style: const TextStyle(fontSize: 12, color: Colores.textoSuave),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const TituloSeccion('Herramientas'),
        _Opcion(
          icono: Icons.chat_bubble_outline,
          titulo: 'Asistente de preguntas',
          detalle: 'Pregunta en español sobre los datos',
          alTocar: () => _abrir(context, const AsistentePantalla()),
        ),
        _Opcion(
          icono: Icons.shield_outlined,
          titulo: 'Planificador de operativos',
          detalle: 'Dónde y cuándo ubicar puntos de control',
          alTocar: () => _abrir(context, const PlanificadorPantalla()),
        ),
        const TituloSeccion('Sistema'),
        _Opcion(
          icono: Icons.speed,
          titulo: 'Complejidad algorítmica',
          detalle: 'Clases P y NP, y tiempos medidos',
          alTocar: () => _abrir(context, const ComplejidadPantalla()),
        ),
        _Opcion(
          icono: Icons.wifi_tethering,
          titulo: 'Estado del sistema',
          detalle: 'Conexión, datos y calidad',
          alTocar: () => _abrir(context, const EstadoSistemaPantalla()),
        ),
      ],
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.alTocar,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colores.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colores.borde),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(icono, color: Colores.primario),
          title: Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(detalle, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: alTocar,
        ),
      ),
    );
  }
}
