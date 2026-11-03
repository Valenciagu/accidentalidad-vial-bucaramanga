import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regla de dependencias de Clean Architecture: apunta siempre hacia el dominio.
void main() {
  List<(String, String)> importaciones(String carpeta) {
    final resultado = <(String, String)>[];
    final archivos = Directory(carpeta).listSync(recursive: true).whereType<File>();
    for (final archivo in archivos.where((a) => a.path.endsWith('.dart'))) {
      for (final linea in archivo.readAsLinesSync()) {
        final coincidencia = RegExp(r"^import '([^']+)'").firstMatch(linea);
        if (coincidencia != null) {
          resultado.add((archivo.path, coincidencia.group(1)!));
        }
      }
    }
    return resultado;
  }

  test('domain no depende de Flutter ni de otras capas', () {
    for (final (archivo, uri) in importaciones('lib/domain')) {
      expect(uri.contains('flutter'), isFalse, reason: '$archivo importa $uri');
      expect(uri.startsWith('package:'), isFalse, reason: '$archivo importa $uri');
      expect(uri.contains('/data/'), isFalse, reason: '$archivo importa $uri');
      expect(uri.contains('/presentation/'), isFalse, reason: '$archivo importa $uri');
    }
  });

  test('data no depende de presentation', () {
    for (final (archivo, uri) in importaciones('lib/data')) {
      expect(uri.contains('presentation'), isFalse, reason: '$archivo importa $uri');
    }
  });

  test('presentation no depende de data', () {
    for (final (archivo, uri) in importaciones('lib/presentation')) {
      expect(uri.contains('/data/'), isFalse, reason: '$archivo importa $uri');
    }
  });
}
