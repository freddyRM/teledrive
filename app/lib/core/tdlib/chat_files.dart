import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../crypto/vault_small.dart';
import 'telegram_auth.dart';

/// Clave en SharedPreferences donde se guardan los datos ya descifrados, por ID de mensaje.
const _unlockCacheKey = 'unlock_cache_v1';

enum ChatFileKind { photo, video, audio, document }

/// Prefijo de la descripcion de los archivos cifrados subidos por la app.
const encryptedCaptionPrefix = 'DRV1:';

/// Un archivo del supergrupo, leido del historial de TDLib.
class ChatFile {
  ChatFile({
    required this.messageId,
    required this.name,
    required this.size,
    required this.kind,
    required this.date,
    this.fileId,
    this.minithumbnail,
    this.caption = '',
    this.encrypted = false,
    this.assetId,
    this.sha256,
    this.plainSize,
  });

  /// ID de la foto en el telefono que se subio (dentro de los datos cifrados).
  final String? assetId;

  /// Huella SHA-256 del archivo original (dentro de los datos cifrados).
  final String? sha256;

  /// Tamano del archivo original, antes de cifrar (dentro de los datos cifrados).
  final int? plainSize;

  final int messageId;
  final String name;
  final int size;
  final ChatFileKind kind;
  final DateTime date;

  /// Id del archivo en TDLib (para descargarlo).
  final int? fileId;

  /// Miniatura diminuta que Telegram trae dentro del mensaje: se muestra sin descargar nada.
  final Uint8List? minithumbnail;

  /// Descripcion del mensaje tal como esta en Telegram (cifrada si [encrypted] es true).
  final String caption;

  /// True si la app subio el archivo cifrado y sus datos ya se leyeron con la frase.
  final bool encrypted;

  ChatFile copyWith({
    String? name,
    ChatFileKind? kind,
    bool? encrypted,
    String? assetId,
    String? sha256,
    int? plainSize,
  }) {
    return ChatFile(
      messageId: messageId,
      name: name ?? this.name,
      size: size,
      kind: kind ?? this.kind,
      date: date,
      fileId: fileId,
      minithumbnail: minithumbnail,
      caption: caption,
      encrypted: encrypted ?? this.encrypted,
      assetId: assetId ?? this.assetId,
      sha256: sha256 ?? this.sha256,
      plainSize: plainSize ?? this.plainSize,
    );
  }
}

/// Lee los mensajes del chat y devuelve solo los que son fotos, videos, audios o documentos.
class ChatFiles {
  ChatFiles({required this.auth, required this.chatId});

  final TelegramAuth auth;
  final int chatId;

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

  /// Si se pasa [passphrase], descifra los nombres y tipos de los archivos cifrados.
  Future<List<ChatFile>> load({String? passphrase}) async {
    for (final list in ['chatListMain', 'chatListArchive']) {
      await _call({'@type': 'loadChats', 'chat_list': {'@type': list}, 'limit': 200});
    }

    final files = <ChatFile>[];
    var fromMessageId = 0;
    while (true) {
      final history = await _call({
        '@type': 'getChatHistory',
        'chat_id': chatId,
        'from_message_id': fromMessageId,
        'offset': 0,
        'limit': 100,
        'only_local': false,
      });
      if (history['@type'] != 'messages') {
        throw StateError('Error leyendo el grupo: ${history['message']}');
      }
      final messages = (history['messages'] as List?) ?? [];
      if (messages.isEmpty) break;
      for (final raw in messages) {
        final file = _toChatFile(raw as Map<String, dynamic>);
        if (file != null) files.add(file);
      }
      fromMessageId = (messages.last as Map<String, dynamic>)['id'] as int;
    }

    if (passphrase == null) return files;

    // Descifrar cada descripcion antigua es lento (Argon2). Se guarda el resultado para no repetirlo.
    final prefs = await SharedPreferences.getInstance();
    final cache = _readCache(prefs);
    var changed = false;
    final resolved = <ChatFile>[];
    for (final file in files) {
      final cached = cache['${file.messageId}'];
      if (cached is Map<String, dynamic> && cached.containsKey('size')) {
        resolved.add(file.copyWith(
          name: cached['name'] as String,
          kind: ChatFileKind.values.byName(cached['kind'] as String),
          encrypted: true,
          assetId: cached['asset'] as String?,
          sha256: cached['sha'] as String?,
          plainSize: cached['size'] as int?,
        ));
        continue;
      }
      final unlocked = await _unlock(file, passphrase);
      resolved.add(unlocked);
      if (unlocked.encrypted && unlocked.name != _failedName) {
        cache['${file.messageId}'] = {
          'name': unlocked.name,
          'kind': unlocked.kind.name,
          'asset': unlocked.assetId,
          'sha': unlocked.sha256,
          'size': unlocked.plainSize,
        };
        changed = true;
      }
    }
    if (changed) await prefs.setString(_unlockCacheKey, jsonEncode(cache));
    return resolved;
  }

  /// Guarda el ID del archivo local que coincide con un mensaje, para no volver a compararlo.
  static Future<void> saveAssetMatch(int messageId, String assetId) async {
    final prefs = await SharedPreferences.getInstance();
    final cache = _readCache(prefs);
    final entry = cache['$messageId'];
    if (entry is! Map) return;
    cache['$messageId'] = {...entry, 'asset': assetId};
    await prefs.setString(_unlockCacheKey, jsonEncode(cache));
  }

  static const _failedName = 'Archivo cifrado';

  static Map<String, dynamic> _readCache(SharedPreferences prefs) {
    try {
      final text = prefs.getString(_unlockCacheKey);
      if (text == null) return {};
      return Map<String, dynamic>.from(jsonDecode(text) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<ChatFile> _unlock(ChatFile file, String passphrase) async {
    if (!file.caption.startsWith(encryptedCaptionPrefix) &&
        !file.caption.startsWith(VaultSmall.v2Prefix)) {
      return file;
    }
    try {
      final json = await VaultSmall.decryptCaption(file.caption, passphrase);
      final meta = jsonDecode(json) as Map<String, dynamic>;
      return file.copyWith(
        name: meta['name'] as String,
        kind: ChatFileKind.values.byName(meta['kind'] as String),
        encrypted: true,
        assetId: meta['asset'] as String?,
        sha256: meta['sha'] as String?,
        plainSize: meta['size'] as int?,
      );
    } catch (_) {
      // Frase incorrecta o metadatos danados: se deja el archivo como cifrado sin nombre.
      return file.copyWith(name: _failedName, encrypted: true);
    }
  }

  /// Borra mensajes del grupo para todos los miembros.
  Future<bool> deleteMessages(List<int> messageIds) async {
    final response = await _call({
      '@type': 'deleteMessages',
      'chat_id': chatId,
      'message_ids': messageIds,
      'revoke': true,
    });
    return response['@type'] == 'ok';
  }

  /// Descarga un archivo del grupo y devuelve la ruta local cuando termina.
  Future<String?> download(int fileId) async {
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
    final response = await _call({
      '@type': 'downloadFile',
      'file_id': fileId,
      'priority': 32,
      'offset': 0,
      'limit': 0,
      'synchronous': false,
    });
    final local = response['local'] as Map<String, dynamic>?;
    if (local?['is_downloading_completed'] == true) {
      subscription.cancel();
      return local!['path'] as String;
    }
    return done.future;
  }

  ChatFile? _toChatFile(Map<String, dynamic> message) {
    final content = message['content'] as Map<String, dynamic>?;
    final type = content?['@type'];
    final date = DateTime.fromMillisecondsSinceEpoch(((message['date'] as int?) ?? 0) * 1000);
    final messageId = message['id'] as int;
    final caption = ((content?['caption'] as Map<String, dynamic>?)?['text'] as String?) ?? '';

    switch (type) {
      case 'messagePhoto':
        final photo = content!['photo'] as Map<String, dynamic>;
        final sizes = (photo['sizes'] as List?) ?? [];
        final largest = sizes.isEmpty ? null : sizes.last as Map<String, dynamic>;
        final file = largest?['photo'] as Map<String, dynamic>?;
        return ChatFile(
          messageId: messageId,
          name: 'Foto ${_formatDate(date)}',
          size: (file?['size'] as int?) ?? 0,
          kind: ChatFileKind.photo,
          date: date,
          fileId: file?['id'] as int?,
          minithumbnail: _mini(photo['minithumbnail']),
          caption: caption,
        );
      case 'messageVideo':
        final video = content!['video'] as Map<String, dynamic>;
        final file = video['video'] as Map<String, dynamic>?;
        return ChatFile(
          messageId: messageId,
          name: (video['file_name'] as String?)?.isNotEmpty == true
              ? video['file_name'] as String
              : 'Video ${_formatDate(date)}',
          size: (file?['size'] as int?) ?? 0,
          kind: ChatFileKind.video,
          date: date,
          fileId: file?['id'] as int?,
          minithumbnail: _mini(video['minithumbnail']),
          caption: caption,
        );
      case 'messageDocument':
        final document = content!['document'] as Map<String, dynamic>;
        final file = document['document'] as Map<String, dynamic>?;
        final mime = (document['mime_type'] as String?) ?? '';
        final kind = mime.startsWith('image/')
            ? ChatFileKind.photo
            : mime.startsWith('video/')
                ? ChatFileKind.video
                : mime.startsWith('audio/')
                    ? ChatFileKind.audio
                    : ChatFileKind.document;
        return ChatFile(
          messageId: messageId,
          name: (document['file_name'] as String?) ?? 'Archivo ${_formatDate(date)}',
          size: (file?['size'] as int?) ?? 0,
          kind: kind,
          date: date,
          fileId: file?['id'] as int?,
          minithumbnail: _mini(document['minithumbnail']),
          caption: caption,
        );
      case 'messageAudio':
        final audio = content!['audio'] as Map<String, dynamic>;
        final file = audio['audio'] as Map<String, dynamic>?;
        return ChatFile(
          messageId: messageId,
          name: (audio['file_name'] as String?) ?? 'Audio ${_formatDate(date)}',
          size: (file?['size'] as int?) ?? 0,
          kind: ChatFileKind.audio,
          date: date,
          fileId: file?['id'] as int?,
          caption: caption,
        );
      default:
        return null;
    }
  }

  static Uint8List? _mini(Object? minithumbnail) {
    final data = (minithumbnail as Map<String, dynamic>?)?['data'];
    if (data is! String || data.isEmpty) return null;
    return base64Decode(data);
  }

  static String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
