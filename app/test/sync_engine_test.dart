import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drive_personal/core/index/index_database.dart';
import 'package:drive_personal/core/sync/in_memory_cloud_storage.dart';
import 'package:drive_personal/core/sync/sync_engine.dart';

const _passphrase = 'frase de prueba para el motor';
const _partBytes = 200;

void main() {
  late Directory tempDir;
  late IndexDatabase database;
  late InMemoryCloudStorage storage;
  late SyncEngine engine;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('drive_sync_test_');
    database = IndexDatabase(NativeDatabase.memory());
    storage = InMemoryCloudStorage();
    engine = SyncEngine(
      database: database,
      storage: storage,
      passphrase: _passphrase,
      workDir: Directory('${tempDir.path}/work'),
      maxPartBytes: _partBytes,
    );
  });

  tearDown(() async {
    await database.close();
    await tempDir.delete(recursive: true);
  });

  File writeFile(String name, Uint8List bytes) {
    final file = File('${tempDir.path}/$name')..writeAsBytesSync(bytes);
    return file;
  }

  Uint8List randomBytes(int length, {int seed = 42}) {
    final random = Random(seed);
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  test('respalda en varios trozos y restaura identico', () async {
    final original = randomBytes(1000);
    final source = writeFile('foto.jpg', original);

    final entry = await engine.backup(source, mediaType: 'photo');
    expect(entry.complete, isTrue);
    expect(entry.status, SyncStatus.synced);
    expect(storage.objectCount, greaterThan(1));

    final restored = File('${tempDir.path}/restaurada.jpg');
    await engine.restore(entry, restored);
    expect(restored.readAsBytesSync(), equals(original));
  });

  test('no vuelve a subir contenido que ya existe', () async {
    final bytes = randomBytes(600);
    final first = await engine.backup(writeFile('a.jpg', bytes), mediaType: 'photo');
    final countAfterFirst = storage.objectCount;

    final second = await engine.backup(writeFile('copia.jpg', bytes), mediaType: 'photo');

    expect(second.id, equals(first.id));
    expect(storage.objectCount, equals(countAfterFirst));
  });

  test('continua una subida interrumpida sin repetir los trozos ya subidos', () async {
    final original = randomBytes(1000);
    final source = writeFile('video.mp4', original);

    var failing = true;
    storage.failPut = (name) => failing && name.endsWith('.2');
    await expectLater(
      engine.backup(source, mediaType: 'video'),
      throwsA(isA<StateError>()),
    );

    final partial = await database.select(database.fileEntries).getSingle();
    expect(partial.complete, isFalse);
    final uploadedBeforeResume = storage.objectCount;
    expect(uploadedBeforeResume, greaterThan(0));

    failing = false;
    final entry = await engine.backup(source, mediaType: 'video');
    expect(entry.complete, isTrue);

    final restored = File('${tempDir.path}/restaurado.mp4');
    await engine.restore(entry, restored);
    expect(restored.readAsBytesSync(), equals(original));
  });

  test('libera el espacio local y deja el archivo solo en la nube', () async {
    final original = randomBytes(800);
    final source = writeFile('documento.pdf', original);
    final entry = await engine.backup(source, mediaType: 'other');

    await engine.freeLocalSpace(entry);

    expect(source.existsSync(), isFalse);
    final updated = await database.select(database.fileEntries).getSingle();
    expect(updated.status, SyncStatus.cloudOnly);

    final restored = File('${tempDir.path}/recuperado.pdf');
    await engine.restore(updated, restored);
    expect(restored.readAsBytesSync(), equals(original));
  });

  test('respaldar nunca borra el archivo local; liberar espacio es un paso aparte', () async {
    final source = writeFile('recuerdo.mp4', randomBytes(900));

    final entry = await engine.backup(source, mediaType: 'video');

    expect(entry.complete, isTrue);
    expect(source.existsSync(), isTrue);
    expect(entry.status, SyncStatus.synced);
  });

  test('no borra el local si falta un trozo en la nube', () async {
    final source = writeFile('nota.txt', randomBytes(700));
    final entry = await engine.backup(source, mediaType: 'other');

    final part = await (database.select(database.fileParts)..limit(1)).getSingle();
    await storage.delete(part.remoteRef);

    await expectLater(engine.freeLocalSpace(entry), throwsA(isA<StateError>()));
    expect(source.existsSync(), isTrue);
  });

  test('no borra el local si el archivo cambio desde el respaldo', () async {
    final source = writeFile('editado.txt', randomBytes(500));
    final entry = await engine.backup(source, mediaType: 'other');

    source.writeAsBytesSync(randomBytes(500, seed: 7));

    await expectLater(engine.freeLocalSpace(entry), throwsA(isA<StateError>()));
    expect(source.existsSync(), isTrue);
  });
}
