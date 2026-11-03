import 'package:flutter/material.dart';

import '../app.dart';
import '../tema.dart';
import 'principal_pantalla.dart';

/// Pantalla de inicio del informe: nombre del proyecto y acceso al sistema.
class InicioPantalla extends StatelessWidget {
  const InicioPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final controlador = ProveedorControlador.de(context);

    return Scaffold(
      backgroundColor: Colores.encabezado,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Spacer(),
                  const Icon(Icons.car_crash_outlined, size: 76, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    'Accidentalidad Vial',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bucaramanga',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Factores asociados a la ocurrencia de accidentes de tránsito '
                    'en Bucaramanga',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                  ),
                  const Spacer(),
                  if (controlador.error != null) ...[
                    Text(
                      controlador.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: controlador.iniciar,
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                      child: const Text('Reintentar'),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colores.encabezado,
                          disabledBackgroundColor: Colors.white24,
                          disabledForegroundColor: Colors.white,
                        ),
                        onPressed: controlador.listo
                            ? () => Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const PrincipalPantalla(),
                                  ),
                                )
                            : null,
                        child: Text(
                          controlador.listo ? 'Ingresar' : 'Cargando datos…',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Proyecto Pedagógico Integrador · Tecnológico de Antioquia',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
