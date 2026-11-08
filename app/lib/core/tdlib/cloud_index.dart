import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../settings/passphrase_store.dart';
import 'chat_files.dart';
import 'telegram_auth.dart';

/// Indice local de las fotos que estan en el grupo (IDs del telefono).
/// Se muestra al instante y se actualiza en segundo plano, para no leer todo el grupo
/// cada vez que abres Fotos, Albumes o un album.
class CloudIndex {
  CloudIndex._();

  static const _key = 'cloud_asset_ids_v1';
  static bool _refreshing = false;

  static Future<Set<String>> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text = prefs.getString(_key);
      if (text == null) return {};
      return Set<String>.from(jsonDecode(text) as List);
    } catch (_) {
      return {};
    }
  }

  static Future<void> _write(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(ids.toList()));
  }

  /// Se llama cuando una subida termina bien.
  static Future<void> add(String assetId) async {
    final ids = await read();
    if (ids.add(assetId)) await _write(ids);
  }

  /// Se llama cuando se borran elementos del grupo.
  static Future<void> remove(Iterable<String> assetIds) async {
    final ids = await read();
    final before = ids.length;
    ids.removeAll(assetIds);
    if (ids.length != before) await _write(ids);
  }

  /// Lee el grupo completo y guarda el indice.
  static Future<Set<String>> refresh(TelegramAuth auth, int chatId) async {
    final passphrase = await PassphraseStore.read();
    if (passphrase == null) return read();
    final files = await ChatFiles(auth: auth, chatId: chatId).load(passphrase: passphrase);
    final ids = {
      for (final file in files)
        if (file.encrypted && file.assetId != null) file.assetId!,
    };
    await _write(ids);
    return ids;
  }

  /// Devuelve el indice guardado al instante. Si esta vacio, lo llena antes de devolverlo;
  /// si no, lo actualiza en segundo plano para la proxima vez.
  static Future<Set<String>> current(TelegramAuth auth, int chatId) async {
    try {
      final cached = await read();
      if (cached.isEmpty) return await refresh(auth, chatId);
      if (!_refreshing) {
        _refreshing = true;
        refresh(auth, chatId)
            .catchError((_) => <String>{})
            .whenComplete(() => _refreshing = false);
      }
      return cached;
    } catch (_) {
      return {};
    }
  }
}
