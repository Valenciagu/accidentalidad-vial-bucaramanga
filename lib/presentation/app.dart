import 'package:flutter/material.dart';

import 'controladores/controlador_app.dart';
import 'pantallas/inicio_pantalla.dart';
import 'tema.dart';

/// Da acceso al controlador desde cualquier pantalla.
class ProveedorControlador extends InheritedNotifier<ControladorApp> {
  const ProveedorControlador({
    super.key,
    required ControladorApp controlador,
    required super.child,
  }) : super(notifier: controlador);

  static ControladorApp de(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ProveedorControlador>()!
        .notifier!;
  }
}

class AccidentalidadApp extends StatelessWidget {
  const AccidentalidadApp({super.key, required this.controlador});

  final ControladorApp controlador;

  @override
  Widget build(BuildContext context) {
    return ProveedorControlador(
      controlador: controlador,
      child: MaterialApp(
        title: 'Accidentalidad Vial',
        debugShowCheckedModeBanner: false,
        theme: crearTema(),
        home: const InicioPantalla(),
      ),
    );
  }
}
