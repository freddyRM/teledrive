import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'core/tdlib/td_client.dart';
import 'core/tdlib/telegram_auth.dart';
import 'features/home/main_shell.dart';

// Credenciales inyectadas al compilar con --dart-define. No van en el codigo.
const _apiIdText = String.fromEnvironment('TG_API_ID');
const _apiHash = String.fromEnvironment('TG_API_HASH');
const _channelIdText = String.fromEnvironment('TG_CHANNEL_ID');

void main() {
  runApp(const DrivePersonalApp());
}

class DrivePersonalApp extends StatelessWidget {
  const DrivePersonalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drive Personal',
      theme: _themeFor(Brightness.light),
      darkTheme: _themeFor(Brightness.dark),
      // Sigue el tema claro u oscuro del telefono.
      themeMode: ThemeMode.system,
      home: const LoginPage(),
    );
  }
}

/// Tema de la app, con el mismo estilo juvenil en claro y en oscuro.
ThemeData _themeFor(Brightness brightness) {
  return ThemeData(
    brightness: brightness,
    colorSchemeSeed: const Color(0xFF7C4DFF),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0, scrolledUnderElevation: 0),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _input = TextEditingController();
  TelegramAuth? _auth;
  AuthStep? _lastStep;
  String? _fatal;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final apiId = int.tryParse(_apiIdText);
    if (apiId == null || _apiHash.isEmpty) {
      setState(() => _fatal = 'Falta TG_API_ID o TG_API_HASH al compilar.');
      return;
    }
    final dir = await getApplicationSupportDirectory();
    final auth = TelegramAuth(
      client: TdClient.create(),
      apiId: apiId,
      apiHash: _apiHash,
      databaseDir: dir.path,
    )..addListener(() {
        if (!mounted) return;
        // Cada paso pide un dato distinto: limpiar el campo para no reenviar el anterior.
        final current = _auth!.step;
        if (current != _lastStep) {
          _lastStep = current;
          _input.clear();
        }
        setState(() {});
      });
    auth.start();
    if (mounted) setState(() => _auth = auth);
  }

  @override
  void dispose() {
    _input.dispose();
    _auth?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = _auth;
    if (auth?.step == AuthStep.ready) {
      return MainShell(auth: auth!, chatId: int.parse(_channelIdText));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Drive Personal')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(child: _body(auth)),
        ),
      ),
    );
  }

  Widget _body(TelegramAuth? auth) {
    if (_fatal != null) return Text(_fatal!, textAlign: TextAlign.center);
    if (auth == null) return const CircularProgressIndicator();

    final error = auth.error;
    final errorText = error == null
        ? null
        : Text(error, style: const TextStyle(color: Colors.red));

    switch (auth.step) {
      case AuthStep.starting:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Conectando con Telegram...'),
          const SizedBox(height: 16),
          Text('Ultimo evento: ${auth.lastEvent}'),
          if (errorText != null) ...[const SizedBox(height: 16), errorText],
        ]);
      case AuthStep.waitPhone:
        return _form(
          label: 'Numero de telefono con codigo de pais (ej. +58...)',
          keyboard: TextInputType.phone,
          button: 'Enviar codigo',
          onSubmit: () => auth.submitPhone(_input.text),
          extra: errorText,
        );
      case AuthStep.waitCode:
        return _form(
          label: 'Codigo que llego a tu Telegram',
          keyboard: TextInputType.number,
          button: 'Confirmar codigo',
          onSubmit: () => auth.submitCode(_input.text),
          extra: errorText,
        );
      case AuthStep.waitPassword:
        return _form(
          label: 'Contrasena de verificacion en dos pasos',
          keyboard: TextInputType.visiblePassword,
          obscure: true,
          button: 'Entrar',
          onSubmit: () => auth.submitPassword(_input.text),
          extra: errorText,
        );
      case AuthStep.ready:
        return const Text('Conectado a Telegram.', textAlign: TextAlign.center);
      case AuthStep.closed:
        return const Text('La sesion de Telegram se cerro.', textAlign: TextAlign.center);
    }
  }

  Widget _form({
    required String label,
    required TextInputType keyboard,
    required String button,
    required VoidCallback onSubmit,
    bool obscure = false,
    Widget? extra,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _input,
          keyboardType: keyboard,
          obscureText: obscure,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onSubmit, child: Text(button)),
        if (extra != null) ...[const SizedBox(height: 16), extra],
      ],
    );
  }
}
