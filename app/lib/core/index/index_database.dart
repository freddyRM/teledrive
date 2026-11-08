import 'package:drift/drift.dart';

part 'index_database.g.dart';

/// Un archivo respaldado o pendiente de respaldar.
/// [sha256] es el hash del contenido original y sirve para no subir duplicados.
class FileEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sha256 => text().unique()();
  TextColumn get path => text()();
  IntColumn get size => integer()();
  IntColumn get modifiedAt => integer()();
  IntColumn get takenAt => integer().nullable()();
  TextColumn get mediaType => text()();
  BoolColumn get onDevice => boolean().withDefault(const Constant(true))();
  BoolColumn get complete => boolean().withDefault(const Constant(false))();
}

/// Trozos cifrados de un archivo en la nube (un archivo grande se parte en varios).
class FileParts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fileId => integer().references(FileEntries, #id)();
  IntColumn get partIndex => integer()();
  TextColumn get remoteRef => text()();
  IntColumn get size => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {fileId, partIndex},
      ];
}

@DriftDatabase(tables: [FileEntries, FileParts])
class IndexDatabase extends _$IndexDatabase {
  IndexDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
