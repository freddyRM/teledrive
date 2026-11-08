import 'package:flutter/material.dart';

import '../../core/settings/passphrase_store.dart';

/// Pantalla para ver y cambiar la frase maestra. Temporal, mientras estamos en pruebas.
class PassphrasePage extends StatefulWidget {
  const PassphrasePage({super.key});

  @override
  State<PassphrasePage> createState() => _PassphrasePageState();
}

class _PassphrasePageState extends State<PassphrasePage> {
  final _controller = TextEditingController();
  bool _visible = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    PassphraseStore.read().then((value) {
      if (!mounted) return;
      _controller.text = value ?? '';
      setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('La frase no puede estar vacia.')));
      return;
    }
    await PassphraseStore.write(text);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Frase guardada.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Frase maestra')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Con esta frase se cifran los archivos que subes y se leen sus nombres. '
                    'Si la pierdes, no hay forma de recuperarlos.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    obscureText: !_visible,
                    decoration: InputDecoration(
                      labelText: 'Frase',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _visible ? 'Ocultar' : 'Mostrar',
                        icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _visible = !_visible),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _save, child: const Text('Guardar')),
                ],
              ),
      ),
    );
  }
}
