import 'package:flutter/material.dart';

import '../../domain/casos_uso/responder_pregunta.dart';
import '../app.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

class _Mensaje {
  const _Mensaje.usuario(this.texto) : respuesta = null;
  const _Mensaje.asistente(RespuestaAsistente valor)
    : texto = '',
      respuesta = valor;

  final String texto;
  final RespuestaAsistente? respuesta;
}

/// Preguntas en español resueltas de forma local sobre los datos.
class AsistentePantalla extends StatefulWidget {
  const AsistentePantalla({super.key});

  @override
  State<AsistentePantalla> createState() => _AsistentePantallaState();
}

class _AsistentePantallaState extends State<AsistentePantalla> {
  final TextEditingController _campo = TextEditingController();
  final ScrollController _desplazamiento = ScrollController();
  final List<_Mensaje> _mensajes = [];

  @override
  void dispose() {
    _campo.dispose();
    _desplazamiento.dispose();
    super.dispose();
  }

  void _preguntar(String texto) {
    final pregunta = texto.trim();
    if (pregunta.isEmpty) return;
    final respuesta = ProveedorControlador.de(context).responder(pregunta);
    setState(() {
      _mensajes.add(_Mensaje.usuario(pregunta));
      _mensajes.add(_Mensaje.asistente(respuesta));
    });
    _campo.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_desplazamiento.hasClients) {
        _desplazamiento.animateTo(
          _desplazamiento.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistente', style: TextStyle(fontSize: 17))),
      body: Column(
        children: [
          Expanded(
            child: _mensajes.isEmpty
                ? _Inicio(alElegir: _preguntar)
                : ListView.builder(
                    controller: _desplazamiento,
                    padding: const EdgeInsets.all(14),
                    itemCount: _mensajes.length,
                    itemBuilder: (context, i) {
                      final mensaje = _mensajes[i];
                      return mensaje.respuesta == null
                          ? _BurbujaUsuario(mensaje.texto)
                          : _BurbujaRespuesta(mensaje.respuesta!);
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: Colores.superficie,
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _campo,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _preguntar,
                      decoration: const InputDecoration(hintText: 'Escribe tu pregunta'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Enviar',
                    icon: const Icon(Icons.send, color: Colores.primario),
                    onPressed: () => _preguntar(_campo.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Inicio extends StatelessWidget {
  const _Inicio({required this.alElegir});

  final ValueChanged<String> alElegir;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Pregunta sobre los accidentes de Bucaramanga',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Las respuestas se calculan sobre los datos del proyecto, sin internet. '
          'Si algo no está registrado, el asistente te lo dice.',
          style: TextStyle(fontSize: 13, color: Colores.textoSuave, height: 1.4),
        ),
        const SizedBox(height: 14),
        for (final sugerencia in ResponderPregunta.sugerencias)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: OutlinedButton(
              onPressed: () => alElegir(sugerencia),
              style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
              child: Text(sugerencia, style: const TextStyle(fontSize: 13)),
            ),
          ),
      ],
    );
  }
}

class _BurbujaUsuario extends StatelessWidget {
  const _BurbujaUsuario(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colores.primario,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(texto, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
    );
  }
}

class _BurbujaRespuesta extends StatelessWidget {
  const _BurbujaRespuesta(this.respuesta);

  final RespuestaAsistente respuesta;

  @override
  Widget build(BuildContext context) {
    final controlador = ProveedorControlador.de(context);
    final filtros = respuesta.filtros;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 24),
      child: Tarjeta(
        relleno: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(respuesta.texto, style: const TextStyle(fontSize: 14, height: 1.4)),
            if (respuesta.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              BarrasHorizontales(items: respuesta.items),
            ],
            if (filtros != null && !filtros.vacio)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    controlador.aplicarFiltros(filtros);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Filtros aplicados al panel')),
                    );
                  },
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Ver en el panel'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
