import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/tdlib/download_test.dart';
import '../../core/tdlib/telegram_auth.dart';
import '../../core/tdlib/upload_test.dart';
import 'backup_page.dart';
import 'free_space_page.dart';
import 'passphrase_page.dart';
import 'test_runner_page.dart';

/// Ajustes. Las pruebas de Telegram estan en pantallas separadas.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.auth});

  final TelegramAuth auth;

  // Grupo privado de pruebas, inyectado desde .env al compilar.
  static const _channelIdText = String.fromEnvironment('TG_CHANNEL_ID');
  static const _testFileName = 'prueba_2mb.bin';

  int? get _chatId => int.tryParse(_channelIdText);

  Future<String> _externalTestPath() async {
    final dir = await getExternalStorageDirectory();
    return '${dir!.path}/$_testFileName';
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.key_outlined),
          title: const Text('Frase maestra'),
          subtitle: const Text('Cifra tus archivos y lee sus nombres. Temporal, para pruebas.'),
          onTap: () => _open(context, const PassphrasePage()),
        ),
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: const Text('Copias de seguridad'),
          subtitle: const Text('Elige los albumes que respaldas en el grupo.'),
          onTap: () {
            final chatId = _chatId;
            if (chatId == null) return;
            _open(context, BackupPage(auth: auth, chatId: chatId));
          },
        ),
        ListTile(
          leading: const Icon(Icons.phonelink_erase_outlined),
          title: const Text('Liberar espacio'),
          subtitle: const Text('Quita del telefono lo que ya esta en el grupo, o borra del grupo.'),
          onTap: () {
            final chatId = _chatId;
            if (chatId == null) return;
            _open(context, FreeSpacePage(auth: auth, chatId: chatId));
          },
        ),
        ListTile(
          leading: const Icon(Icons.cloud_upload_outlined),
          title: const Text('Prueba de subida'),
          subtitle: const Text('Sube el archivo de 1.5 GB al grupo privado (una sola vez).'),
          onTap: () => _open(
            context,
            TestRunnerPage(
              title: 'Prueba de subida',
              description: 'Sube el archivo de 1.5 GB al grupo privado. '
                  'Solo usala cuando necesites otra copia: cada corrida envia el archivo otra vez.',
              buttonLabel: 'Subir archivo de prueba',
              onRun: (log) async {
                final chatId = _chatId;
                if (chatId == null) {
                  log('Falta TG_CHANNEL_ID al compilar.');
                  return;
                }
                final path = await _externalTestPath();
                if (!File(path).existsSync()) {
                  log('No existe el archivo de prueba: $path');
                  return;
                }
                final support = await getApplicationSupportDirectory();
                final tdlibFiles = Directory('${support.path}/tdlib_files')
                  ..createSync(recursive: true);
                final test = UploadTest(auth: auth, log: log, chatId: chatId);
                await test.run(path, tdlibFilesDir: tdlibFiles.path);
              },
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Cerrar sesion de Telegram'),
          subtitle: const Text('Borra la sesion y la base local de TDLib. Vuelves a pedir codigo.'),
          onTap: () => auth.client.send({'@type': 'logOut'}),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Borrar copias de prueba del grupo'),
          subtitle: const Text('Borra del grupo los mensajes prueba_1500mb.bin.'),
          onTap: () => _open(
            context,
            TestRunnerPage(
              title: 'Borrar copias de prueba',
              description: 'Borra del grupo los mensajes del archivo de prueba.',
              buttonLabel: 'Borrar copias de prueba',
              onRun: (log) async {
                final chatId = _chatId;
                if (chatId == null) {
                  log('Falta TG_CHANNEL_ID al compilar.');
                  return;
                }
                await DownloadTest(auth: auth, log: log, chatId: chatId).deleteTestCopies();
              },
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_download_outlined),
          title: const Text('Prueba de descarga'),
          subtitle: const Text('Descarga la copia que ya esta en el grupo y verifica el hash.'),
          onTap: () => _open(
            context,
            TestRunnerPage(
              title: 'Prueba de descarga',
              description: 'Busca la copia que ya esta en el grupo, la descarga de Telegram '
                  'y compara su hash con el original. No sube nada.',
              buttonLabel: 'Descargar y verificar',
              onRun: (log) async {
                final chatId = _chatId;
                if (chatId == null) {
                  log('Falta TG_CHANNEL_ID al compilar.');
                  return;
                }
                final path = await _externalTestPath();
                if (!File(path).existsSync()) {
                  log('No existe el archivo original para comparar: $path');
                  return;
                }
                final test = DownloadTest(auth: auth, log: log, chatId: chatId);
                await test.run(originalPath: path);
              },
            ),
          ),
        ),
      ],
    );
  }
}
