import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'telegram_auth.dart';

/// Prueba de subida: crea un canal privado, sube un archivo grande, lo descarga
/// de vuelta y compara su SHA-256 con el original.
class UploadTest {
  UploadTest({required this.auth, required this.log, required this.chatId});

  final TelegramAuth auth;
  final void Function(String message) log;

  /// Grupo o canal privado de destino (TG_CHANNEL_ID del .env).
  final int chatId;

  int _extra = 0;

  /// Envia una peticion a TDLib y espera su respuesta (identificada con @extra).
  Future<Map<String, dynamic>> _call(Map<String, dynamic> request) {
    final id = '${++_extra}';
    final completer = Completer<Map<String, dynamic>>();
    late StreamSubscription<Map<String, dynamic>> subscription;
    subscription = auth.events.listen((update) {
      if (update['@extra'] == id && !completer.isCompleted) {
        subscription.cancel();
        completer.complete(update);
      }
    });
    auth.client.send({...request, '@extra': id});
    return completer.future;
  }

  /// [tdlibFilesDir] es la carpeta privada de TDLib: solo ahi TDLib puede borrar su copia local.
  Future<void> run(String path, {required String tdlibFilesDir}) async {
    final file = File(path);
    final size = await file.length();
    log('Archivo: ${_mb(size)} MB');

    final originalHash = (await sha256.bind(file.openRead()).first).toString();
    log('SHA-256 original: ${originalHash.substring(0, 16)}...');

    final owned = File('$tdlibFilesDir/${path.split('/').last}');
    if (!await owned.exists()) {
      log('Copiando a la carpeta de TDLib...');
      await file.copy(owned.path);
    }
    path = owned.path;

    // TDLib solo conoce los chats que ya cargo: pedimos la lista principal y la de archivados.
    for (final list in ['chatListMain', 'chatListArchive']) {
      await _call({
        '@type': 'loadChats',
        'chat_list': {'@type': list},
        'limit': 200,
      });
    }

    final chat = await _call({'@type': 'getChat', 'chat_id': chatId});
    if (chat['@type'] != 'chat') {
      log('No encuentro el grupo $chatId: ${chat['message']}');
      return;
    }
    log('Grupo destino: ${chat['title']}');

    final uploadStart = DateTime.now();
    final sent = await _call({
      '@type': 'sendMessage',
      'chat_id': chatId,
      'message_thread_id': 0,
      'input_message_content': {
        '@type': 'inputMessageDocument',
        'document': {
          '@type': 'inputDocument',
          'document': {'@type': 'inputFileLocal', 'path': path},
          'disable_content_type_detection': true,
        },
        'caption': {'@type': 'formattedText', 'text': ''},
      },
    });
    if (sent['@type'] != 'message') {
      log('Error enviando el archivo: ${sent['message']}');
      return;
    }
    final tempId = sent['id'] as int;
    final localFileId = sent['content']['document']['document']['id'] as int;
    log('Subida iniciada');

    final uploaded = await _waitForUpload(tempId, localFileId, size);
    if (uploaded == null) return;
    final uploadSeconds = DateTime.now().difference(uploadStart).inSeconds;
    final mbps = uploadSeconds == 0 ? 0.0 : (size / (1024 * 1024)) / uploadSeconds;
    log('Subida terminada en ${uploadSeconds}s (${mbps.toStringAsFixed(2)} MB/s)');

    log('Listo. Para verificar la descarga usa la prueba de descarga.');
  }

  Future<Map<String, dynamic>?> _waitForUpload(int tempId, int fileId, int size) {
    final done = Completer<Map<String, dynamic>?>();
    var lastDecile = -1;
    late StreamSubscription<Map<String, dynamic>> subscription;
    subscription = auth.events.listen((update) {
      switch (update['@type']) {
        case 'updateFile':
          final file = update['file'] as Map<String, dynamic>;
          if (file['id'] != fileId) return;
          final remote = file['remote'] as Map<String, dynamic>;
          final uploadedBytes = (remote['uploaded_size'] as int?) ?? 0;
          final percent = size == 0 ? 100 : uploadedBytes * 100 ~/ size;
          final decile = percent ~/ 10;
          if (decile != lastDecile) {
            lastDecile = decile;
            log('Subido $percent%');
          }
        case 'updateMessageSendSucceeded':
          if (update['old_message_id'] == tempId && !done.isCompleted) {
            subscription.cancel();
            done.complete(update['message'] as Map<String, dynamic>);
          }
        case 'updateMessageSendFailed':
          if (update['old_message_id'] == tempId && !done.isCompleted) {
            subscription.cancel();
            log('Fallo la subida: ${update['error_message']}');
            done.complete(null);
          }
      }
    });
    return done.future;
  }

  static String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);
}
