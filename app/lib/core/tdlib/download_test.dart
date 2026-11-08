import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'telegram_auth.dart';

/// Prueba de descarga sin subir nada: busca en el grupo el archivo ya enviado,
/// borra la copia local de TDLib, lo descarga de Telegram y compara el SHA-256.
class DownloadTest {
  DownloadTest({required this.auth, required this.log, required this.chatId});

  final TelegramAuth auth;
  final void Function(String message) log;
  final int chatId;

  static const fileName = 'prueba_1500mb.bin';

  int _extra = 0;

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

  /// Borra del grupo los mensajes de prueba (solo los que se llaman [fileName]).
  Future<void> deleteTestCopies() async {
    for (final list in ['chatListMain', 'chatListArchive']) {
      await _call({'@type': 'loadChats', 'chat_list': {'@type': list}, 'limit': 200});
    }
    final history = await _call({
      '@type': 'getChatHistory',
      'chat_id': chatId,
      'from_message_id': 0,
      'offset': 0,
      'limit': 100,
      'only_local': false,
    });
    if (history['@type'] != 'messages') {
      log('Error leyendo el grupo: ${history['message']}');
      return;
    }
    final ids = <int>[];
    for (final raw in (history['messages'] as List?) ?? []) {
      final message = raw as Map<String, dynamic>?;
      final content = message?['content'] as Map<String, dynamic>?;
      if (content?['@type'] != 'messageDocument') continue;
      final document = content!['document'] as Map<String, dynamic>;
      if (document['file_name'] == fileName) ids.add(message!['id'] as int);
    }
    log('Mensajes de $fileName a borrar: ${ids.length}');
    if (ids.isEmpty) return;
    final result = await _call({
      '@type': 'deleteMessages',
      'chat_id': chatId,
      'message_ids': ids,
      'revoke': true,
    });
    log('Resultado: ${result['@type']} ${result['message'] ?? ''}');
  }

  /// [originalPath] es el archivo original del telefono, para comparar hashes.
  Future<void> run({required String originalPath}) async {
    final originalHash = (await sha256.bind(File(originalPath).openRead()).first).toString();
    log('SHA-256 original: ${originalHash.substring(0, 16)}...');

    for (final list in ['chatListMain', 'chatListArchive']) {
      await _call({'@type': 'loadChats', 'chat_list': {'@type': list}, 'limit': 200});
    }

    final history = await _call({
      '@type': 'getChatHistory',
      'chat_id': chatId,
      'from_message_id': 0,
      'offset': 0,
      'limit': 100,
      'only_local': false,
    });
    if (history['@type'] != 'messages') {
      log('Error leyendo el grupo: ${history['message']}');
      return;
    }

    final messages = (history['messages'] as List?) ?? [];
    Map<String, dynamic>? found;
    var copies = 0;
    for (final raw in messages) {
      final message = raw as Map<String, dynamic>?;
      if (message == null) continue;
      final content = message['content'] as Map<String, dynamic>?;
      if (content?['@type'] != 'messageDocument') continue;
      final document = content!['document'] as Map<String, dynamic>;
      if (document['file_name'] != fileName) continue;
      copies++;
      found ??= message; // el primero es el mas reciente
    }
    log('Copias de $fileName en el grupo: $copies');
    if (found == null) {
      log('No encuentro $fileName en el grupo. Primero corre la prueba de subida.');
      return;
    }

    final content = found['content'] as Map<String, dynamic>;
    final remote = (content['document'] as Map<String, dynamic>)['document'] as Map<String, dynamic>;
    final fileId = remote['id'] as int;
    log('Descargando la copia mas reciente (${remote['size']} bytes)');

    final deleted = await _call({'@type': 'deleteFile', 'file_id': fileId});
    log('Copia local de TDLib borrada: ${deleted['@type']}');

    final downloadStart = DateTime.now();
    final downloaded = _waitForDownload(fileId);
    final response = await _call({
      '@type': 'downloadFile',
      'file_id': fileId,
      'priority': 32,
      'offset': 0,
      'limit': 0,
      'synchronous': false,
    });
    log('downloadFile respuesta: ${response['@type']} '
        'completa=${(response['local'] as Map?)?['is_downloading_completed']}');

    final downloadedPath = await downloaded;
    if (downloadedPath == null) return;
    final seconds = DateTime.now().difference(downloadStart).inSeconds;
    log('Descarga terminada en ${seconds}s');

    final downloadedHash = (await sha256.bind(File(downloadedPath).openRead()).first).toString();
    log(downloadedHash == originalHash
        ? 'RESULTADO: OK, el hash coincide'
        : 'RESULTADO: FALLO, el hash no coincide');
    log('Copia descargada en: $downloadedPath');
  }

  Future<String?> _waitForDownload(int fileId) {
    final done = Completer<String?>();
    late StreamSubscription<Map<String, dynamic>> subscription;
    subscription = auth.events.listen((update) {
      if (update['@type'] != 'updateFile') return;
      final file = update['file'] as Map<String, dynamic>;
      if (file['id'] != fileId) return;
      final local = file['local'] as Map<String, dynamic>;
      if (local['is_downloading_completed'] == true && !done.isCompleted) {
        subscription.cancel();
        done.complete(local['path'] as String);
      }
    });
    return done.future;
  }
}
