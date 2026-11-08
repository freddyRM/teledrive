import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../crypto/vault_cipher.dart';
import '../crypto/vault_small.dart';
import 'chat_files.dart';
import 'telegram_auth.dart';

/// Sube un archivo cifrado al supergrupo. El nombre real, tipo y tamano van cifrados en la descripcion.
class EncryptedUpload {
  EncryptedUpload({required this.auth, required this.chatId, required this.log});

  final TelegramAuth auth;
  final int chatId;
  final void Function(String message) log;

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

  /// Devuelve true si la subida termino bien.
  Future<bool> run({
    required String sourcePath,
    required String displayName,
    required ChatFileKind kind,
    required String passphrase,
    required String tdlibFilesDir,
    String? assetId,
  }) async {
    final source = File(sourcePath);
    final size = await source.length();
    final hash = (await sha256.bind(source.openRead()).first).toString();
    log('Archivo: ${(size / (1024 * 1024)).toStringAsFixed(1)} MB');

    final encrypted = File('$tdlibFilesDir/${_randomHex(16)}.bin');
    log('Cifrando...');
    final sink = encrypted.openWrite();
    await sink.addStream(VaultCipher.encrypt(source.openRead(), passphrase));
    await sink.close();

    final meta = jsonEncode({
      'name': displayName,
      'kind': kind.name,
      'size': size,
      'date': DateTime.now().millisecondsSinceEpoch,
      'sha': hash,
      'asset': assetId,
    });
    final caption = await VaultSmall.encryptText(meta, passphrase);

    final sent = await _call({
      '@type': 'sendMessage',
      'chat_id': chatId,
      'message_thread_id': 0,
      'input_message_content': {
        '@type': 'inputMessageDocument',
        'document': {
          '@type': 'inputDocument',
          'document': {'@type': 'inputFileLocal', 'path': encrypted.path},
          'disable_content_type_detection': true,
        },
        'caption': {'@type': 'formattedText', 'text': caption},
      },
    });
    if (sent['@type'] != 'message') {
      log('Error enviando: ${sent['message']}');
      await encrypted.delete();
      return false;
    }
    final tempId = sent['id'] as int;
    final fileId = (sent['content']['document']['document']['id']) as int;
    log('Subida iniciada');

    final ok = await _waitForSend(tempId, fileId, size);
    await encrypted.delete();
    if (ok) log('Listo: subido como archivo cifrado');
    return ok;
  }

  Future<bool> _waitForSend(int tempId, int fileId, int size) {
    final done = Completer<bool>();
    var lastDecile = -1;
    late StreamSubscription<Map<String, dynamic>> subscription;
    subscription = auth.events.listen((update) {
      switch (update['@type']) {
        case 'updateFile':
          final file = update['file'] as Map<String, dynamic>;
          if (file['id'] != fileId) return;
          final remote = file['remote'] as Map<String, dynamic>;
          final uploaded = (remote['uploaded_size'] as int?) ?? 0;
          final percent = size == 0 ? 100 : uploaded * 100 ~/ size;
          if (percent ~/ 10 != lastDecile) {
            lastDecile = percent ~/ 10;
            log('Subido $percent%');
          }
        case 'updateMessageSendSucceeded':
          if (update['old_message_id'] == tempId && !done.isCompleted) {
            subscription.cancel();
            done.complete(true);
          }
        case 'updateMessageSendFailed':
          if (update['old_message_id'] == tempId && !done.isCompleted) {
            subscription.cancel();
            log('Fallo la subida: ${update['error_message']}');
            done.complete(false);
          }
      }
    });
    return done.future;
  }

  static String _randomHex(int bytes) {
    final random = Random.secure();
    return List.generate(bytes, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
