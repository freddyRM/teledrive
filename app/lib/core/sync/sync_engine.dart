import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../crypto/vault_cipher.dart';
import '../index/index_database.dart';
import 'cloud_storage.dart';

enum SyncStatus {
  /// Solo en el dispositivo, todavia sin respaldo completo.
  localOnly,

  /// Respaldo completo y copia local presente.
  synced,

  /// Respaldo completo; la copia local ya se libero.
  cloudOnly,
}

extension FileEntryStatus on FileEntry {
  SyncStatus get status {
    if (complete && onDevice) return SyncStatus.synced;
    if (complete) return SyncStatus.cloudOnly;
    return SyncStatus.localOnly;
  }
}

class SyncEngine {
  SyncEngine({
    required this.database,
    required this.storage,
    required this.passphrase,
    required this.workDir,
    this.maxPartBytes = 1900 * 1024 * 1024,
  });

  final IndexDatabase database;
  final CloudStorage storage;
  final String passphrase;
  final Directory workDir;

  /// Tamano maximo de cada trozo en la nube. Telegram acepta hasta 2 GB por archivo
  /// con cuenta gratuita; usamos un margen por debajo.
  final int maxPartBytes;

  /// Respalda [source]. Si el contenido ya existe, no vuelve a subirlo.
  /// Si una subida anterior quedo a medias, continua desde el trozo pendiente.
  Future<FileEntry> backup(
    File source, {
    required String mediaType,
    DateTime? takenAt,
  }) async {
    final stat = await source.stat();
    final sha = await _sha256Of(source.openRead());

    var entry = await _findBySha256(sha);
    if (entry == null) {
      final id = await database.into(database.fileEntries).insert(
            FileEntriesCompanion.insert(
              sha256: sha,
              path: source.path,
              size: stat.size,
              modifiedAt: stat.modified.millisecondsSinceEpoch,
              takenAt: Value(takenAt?.millisecondsSinceEpoch),
              mediaType: mediaType,
            ),
          );
      entry = await _findById(id);
    } else {
      await _updateFile(entry.id, FileEntriesCompanion(
        path: Value(source.path),
        onDevice: const Value(true),
      ));
      entry = await _findById(entry.id);
    }

    if (entry.complete) return entry;

    final encryptedFile = File(p.join(workDir.path, '$sha.enc'));
    if (!await encryptedFile.exists()) {
      // El cifrado es distinto en cada corrida (sal y nonce nuevos).
      // Si el archivo cifrado se perdio, los trozos previos ya no sirven.
      final fileId = entry.id;
      final previous = await _partsOf(fileId);
      for (final part in previous) {
        await storage.delete(part.remoteRef);
      }
      await (database.delete(database.fileParts)
            ..where((t) => t.fileId.equals(fileId)))
          .go();
      await _encryptTo(source, encryptedFile);
    }

    final total = await encryptedFile.length();
    final partCount = max(1, (total + maxPartBytes - 1) ~/ maxPartBytes);
    final done = (await _partsOf(entry.id)).map((part) => part.partIndex).toSet();

    for (var i = 0; i < partCount; i++) {
      if (done.contains(i)) continue;
      final offset = i * maxPartBytes;
      final length = min(maxPartBytes, total - offset);
      final ref = await storage.put(
        '$sha.$i',
        encryptedFile.openRead(offset, offset + length),
        length,
      );
      await database.into(database.fileParts).insertOnConflictUpdate(
            FilePartsCompanion.insert(
              fileId: entry.id,
              partIndex: i,
              remoteRef: ref,
              size: length,
            ),
          );
    }

    await _updateFile(entry.id, FileEntriesCompanion(complete: Value(true)));
    await encryptedFile.delete();
    return _findById(entry.id);
  }

  /// Libera el espacio local solo si la copia remota esta completa y el archivo
  /// local sigue siendo el mismo que se respaldo.
  Future<void> freeLocalSpace(FileEntry entry) async {
    if (!entry.complete) {
      throw StateError('El respaldo no esta completo; no se libera el espacio.');
    }
    final file = File(entry.path);
    if (!await file.exists()) {
      await _updateFile(entry.id, FileEntriesCompanion(onDevice: Value(false)));
      return;
    }
    final sha = await _sha256Of(file.openRead());
    if (sha != entry.sha256) {
      throw StateError('El archivo local cambio desde el respaldo; no se borra.');
    }
    for (final part in await _partsOf(entry.id)) {
      final size = await storage.sizeOf(part.remoteRef);
      if (size != part.size) {
        throw StateError('Falta o no coincide el trozo ${part.partIndex} en la nube.');
      }
    }
    await file.delete();
    await _updateFile(entry.id, FileEntriesCompanion(onDevice: Value(false)));
  }

  /// Descarga y descifra un archivo respaldado en [destination], y verifica su hash.
  Future<void> restore(FileEntry entry, File destination) async {
    if (!entry.complete) {
      throw StateError('El archivo no tiene respaldo completo.');
    }
    final parts = await _partsOf(entry.id);
    final encrypted = _readParts(parts);
    final sink = destination.openWrite();
    await sink.addStream(VaultCipher.decrypt(encrypted, passphrase));
    await sink.close();

    final sha = await _sha256Of(destination.openRead());
    if (sha != entry.sha256) {
      await destination.delete();
      throw StateError('El archivo restaurado no coincide con el hash original.');
    }
  }

  Stream<List<int>> _readParts(List<FilePart> parts) async* {
    for (final part in parts) {
      yield* storage.get(part.remoteRef);
    }
  }

  Future<void> _encryptTo(File source, File target) async {
    final temp = File('${target.path}.tmp');
    await temp.parent.create(recursive: true);
    final sink = temp.openWrite();
    await sink.addStream(VaultCipher.encrypt(source.openRead(), passphrase));
    await sink.close();
    await temp.rename(target.path);
  }

  Future<String> _sha256Of(Stream<List<int>> stream) async {
    final digest = await sha256.bind(stream).first;
    return digest.toString();
  }

  Future<FileEntry?> _findBySha256(String sha) {
    return (database.select(database.fileEntries)
          ..where((t) => t.sha256.equals(sha)))
        .getSingleOrNull();
  }

  Future<FileEntry> _findById(int id) {
    return (database.select(database.fileEntries)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<List<FilePart>> _partsOf(int fileId) {
    return (database.select(database.fileParts)
          ..where((t) => t.fileId.equals(fileId))
          ..orderBy([(t) => OrderingTerm.asc(t.partIndex)]))
        .get();
  }

  Future<void> _updateFile(int id, FileEntriesCompanion changes) {
    return (database.update(database.fileEntries)..where((t) => t.id.equals(id)))
        .write(changes);
  }
}
