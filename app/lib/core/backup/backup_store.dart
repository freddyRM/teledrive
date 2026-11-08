import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda que albumes del telefono estan elegidos para respaldo y que fotos ya estan en la nube.
/// Es temporal: mas adelante esto vive en la base de datos local (drift).
class BackupStore {
  BackupStore._();

  static const _albumsKey = 'backup_albums';
  static const _uploadedKey = 'backup_uploaded';

  /// Cambia cada vez que una foto termina de subirse, para que las pantallas se actualicen.
  static final changes = ValueNotifier<int>(0);

  static Future<Set<String>> selectedAlbumIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_albumsKey) ?? []).toSet();
  }

  static Future<void> setSelectedAlbumIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_albumsKey, ids.toList());
  }

  static Future<Set<String>> uploadedAssetIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_uploadedKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as List).cast<String>().toSet();
  }

  static Future<void> addUploaded(String assetId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await uploadedAssetIds();
    current.add(assetId);
    await prefs.setString(_uploadedKey, jsonEncode(current.toList()));
    changes.value++;
  }
}
