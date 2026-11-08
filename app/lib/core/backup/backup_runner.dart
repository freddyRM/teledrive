import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../network/network_policy.dart';
import '../settings/passphrase_store.dart';
import '../tdlib/chat_files.dart';
import '../tdlib/cloud_index.dart';
import '../tdlib/encrypted_upload.dart';
import '../tdlib/telegram_auth.dart';
import 'backup_store.dart';

/// Sube los archivos pendientes de los albumes elegidos. Solo una corrida a la vez.
class BackupRunner {
  BackupRunner._();

  /// Sin limite: sube todas las pendientes de los albumes elegidos, una por una.
  static const _batchSize = 100000;

  static bool _running = false;

  static bool get isRunning => _running;

  /// Arranca solo si hay albumes elegidos y la red actual esta permitida.
  static Future<void> runIfAllowed({
    required TelegramAuth auth,
    required int chatId,
    void Function(String line)? onLine,
  }) async {
    if (_running) return;
    if (!await NetworkPolicyStore.uploadAllowed()) return;
    final selected = await BackupStore.selectedAlbumIds();
    if (selected.isEmpty) return;
    await run(auth: auth, chatId: chatId, onLine: onLine);
  }

  /// Sube lo que falta en el grupo de los albumes elegidos. Cada linea de estado va a [onLine].
  static Future<void> run({
    required TelegramAuth auth,
    required int chatId,
    void Function(String line)? onLine,
  }) async {
    void add(String line) => onLine?.call(line);
    if (_running) {
      add('Ya hay una subida en curso.');
      return;
    }
    final passphrase = await PassphraseStore.read();
    if (passphrase == null) {
      add('Configura la frase maestra en Ajustes primero.');
      return;
    }
    if (!await NetworkPolicyStore.uploadAllowed()) {
      add('La red actual no esta permitida. Conecta Wi-Fi o cambia la opcion de red.');
      return;
    }

    _running = true;
    try {
      final selected = await BackupStore.selectedAlbumIds();
      final cloud = await _cloudIds(auth, chatId, passphrase);
      final albums = await PhotoManager.getAssetPathList(type: RequestType.common, onlyAll: false);
      final pending = <AssetEntity>[];
      for (final album in albums.where((a) => selected.contains(a.id))) {
        final count = await album.assetCountAsync;
        final assets = await album.getAssetListRange(start: 0, end: count);
        for (final asset in assets) {
          if (!cloud.contains(asset.id)) pending.add(asset);
        }
      }
      add('Pendientes: ${pending.length}. Subo hasta $_batchSize.');

      final support = await getApplicationSupportDirectory();
      final tdlibFiles = Directory('${support.path}/tdlib_files')..createSync(recursive: true);
      for (final asset in pending.take(_batchSize)) {
        if (!await NetworkPolicyStore.uploadAllowed()) {
          add('Se perdio la red permitida. Me detengo; sigue al volver a conectar.');
          break;
        }
        final file = await asset.originFile;
        if (file == null) {
          add('Sin archivo: ${asset.title ?? asset.id}');
          continue;
        }
        add('Subiendo ${asset.title ?? asset.id}...');
        final upload = EncryptedUpload(auth: auth, chatId: chatId, log: (_) {});
        final ok = await upload.run(
          sourcePath: file.path,
          displayName: asset.title ?? 'foto_${asset.id}.jpg',
          kind: asset.type == AssetType.video ? ChatFileKind.video : ChatFileKind.photo,
          passphrase: passphrase,
          tdlibFilesDir: tdlibFiles.path,
          assetId: asset.id,
        );
        if (ok) {
          await BackupStore.addUploaded(asset.id);
          await CloudIndex.add(asset.id);
          add('Listo');
        } else {
          add('Fallo, sigo con la siguiente');
        }
      }
    } catch (error) {
      add('Error: $error');
    } finally {
      _running = false;
    }
  }

  /// IDs de telefono de lo que ya esta en el grupo: la fuente de verdad para no resubir.
  static Future<Set<String>> _cloudIds(TelegramAuth auth, int chatId, String passphrase) async {
    final files = await ChatFiles(auth: auth, chatId: chatId).load(passphrase: passphrase);
    return {for (final file in files) if (file.encrypted && file.assetId != null) file.assetId!};
  }
}
