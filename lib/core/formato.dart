/// Formatos en español de Colombia. Dart puro: lo usan todas las capas.
library;

String formatoNumero(int valor) {
  final signo = valor < 0 ? '-' : '';
  final digitos = valor.abs().toString();
  final salida = StringBuffer(signo);
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) salida.write('.');
    salida.write(digitos[i]);
  }
  return salida.toString();
}

String formatoDecimal(double valor, {int decimales = 1}) =>
    valor.toStringAsFixed(decimales).replaceAll('.', ',');

String formatoVariacion(double valor) {
  final signo = valor > 0 ? '+' : '';
  return '$signo${formatoDecimal(valor)} %';
}

String formatoHora(int hora) => '${hora.toString().padLeft(2, '0')}:00';

/// Número grande en palabras cortas: 2,8 miles de millones.
String formatoGrande(double valor) {
  if (valor >= 1e12) return '${formatoDecimal(valor / 1e12)} billones';
  if (valor >= 1e9) return '${formatoDecimal(valor / 1e9)} mil millones';
  if (valor >= 1e6) return '${formatoDecimal(valor / 1e6)} millones';
  return formatoNumero(valor.round());
}

String formatoMicrosegundos(int microsegundos) {
  if (microsegundos >= 1000000) {
    return '${formatoDecimal(microsegundos / 1000000, decimales: 2)} s';
  }
  if (microsegundos >= 1000) {
    return '${formatoDecimal(microsegundos / 1000, decimales: 2)} ms';
  }
  return '$microsegundos µs';
}
