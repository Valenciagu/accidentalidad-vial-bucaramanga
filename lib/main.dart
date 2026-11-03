import 'package:flutter/material.dart';

import 'di.dart';
import 'presentation/app.dart';

void main() {
  // Los assets requieren el binding antes de que el controlador empiece a cargar.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AccidentalidadApp(controlador: crearControlador()..iniciar()));
}
