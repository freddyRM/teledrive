import 'package:flutter/material.dart';

/// Pantalla de prueba con un boton y un registro de lo que va pasando.
class TestRunnerPage extends StatefulWidget {
  const TestRunnerPage({
    super.key,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onRun,
  });

  final String title;
  final String description;
  final String buttonLabel;

  /// Recibe la funcion de registro y ejecuta la prueba.
  final Future<void> Function(void Function(String) log) onRun;

  @override
  State<TestRunnerPage> createState() => _TestRunnerPageState();
}

class _TestRunnerPageState extends State<TestRunnerPage> {
  final List<String> _lines = [];
  bool _running = false;

  void _add(String line) {
    if (mounted) setState(() => _lines.add(line));
  }

  Future<void> _run() async {
    setState(() {
      _running = true;
      _lines.clear();
    });
    try {
      await widget.onRun(_add);
    } catch (error) {
      _add('Error inesperado: $error');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.description),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _running ? null : _run,
              child: Text(_running ? 'Probando...' : widget.buttonLabel),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _lines.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(_lines[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
