// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'index_database.dart';

// ignore_for_file: type=lint
class $FileEntriesTable extends FileEntries
    with TableInfo<$FileEntriesTable, FileEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FileEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<int> takenAt = GeneratedColumn<int>(
    'taken_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _onDeviceMeta = const VerificationMeta(
    'onDevice',
  );
  @override
  late final GeneratedColumn<bool> onDevice = GeneratedColumn<bool>(
    'on_device',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("on_device" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _completeMeta = const VerificationMeta(
    'complete',
  );
  @override
  late final GeneratedColumn<bool> complete = GeneratedColumn<bool>(
    'complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sha256,
    path,
    size,
    modifiedAt,
    takenAt,
    mediaType,
    onDevice,
    complete,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'file_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FileEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('on_device')) {
      context.handle(
        _onDeviceMeta,
        onDevice.isAcceptableOrUnknown(data['on_device']!, _onDeviceMeta),
      );
    }
    if (data.containsKey('complete')) {
      context.handle(
        _completeMeta,
        complete.isAcceptableOrUnknown(data['complete']!, _completeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FileEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FileEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}taken_at'],
      ),
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      onDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}on_device'],
      )!,
      complete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}complete'],
      )!,
    );
  }

  @override
  $FileEntriesTable createAlias(String alias) {
    return $FileEntriesTable(attachedDatabase, alias);
  }
}

class FileEntry extends DataClass implements Insertable<FileEntry> {
  final int id;
  final String sha256;
  final String path;
  final int size;
  final int modifiedAt;
  final int? takenAt;
  final String mediaType;
  final bool onDevice;
  final bool complete;
  const FileEntry({
    required this.id,
    required this.sha256,
    required this.path,
    required this.size,
    required this.modifiedAt,
    this.takenAt,
    required this.mediaType,
    required this.onDevice,
    required this.complete,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sha256'] = Variable<String>(sha256);
    map['path'] = Variable<String>(path);
    map['size'] = Variable<int>(size);
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || takenAt != null) {
      map['taken_at'] = Variable<int>(takenAt);
    }
    map['media_type'] = Variable<String>(mediaType);
    map['on_device'] = Variable<bool>(onDevice);
    map['complete'] = Variable<bool>(complete);
    return map;
  }

  FileEntriesCompanion toCompanion(bool nullToAbsent) {
    return FileEntriesCompanion(
      id: Value(id),
      sha256: Value(sha256),
      path: Value(path),
      size: Value(size),
      modifiedAt: Value(modifiedAt),
      takenAt: takenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(takenAt),
      mediaType: Value(mediaType),
      onDevice: Value(onDevice),
      complete: Value(complete),
    );
  }

  factory FileEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FileEntry(
      id: serializer.fromJson<int>(json['id']),
      sha256: serializer.fromJson<String>(json['sha256']),
      path: serializer.fromJson<String>(json['path']),
      size: serializer.fromJson<int>(json['size']),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      takenAt: serializer.fromJson<int?>(json['takenAt']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      onDevice: serializer.fromJson<bool>(json['onDevice']),
      complete: serializer.fromJson<bool>(json['complete']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sha256': serializer.toJson<String>(sha256),
      'path': serializer.toJson<String>(path),
      'size': serializer.toJson<int>(size),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'takenAt': serializer.toJson<int?>(takenAt),
      'mediaType': serializer.toJson<String>(mediaType),
      'onDevice': serializer.toJson<bool>(onDevice),
      'complete': serializer.toJson<bool>(complete),
    };
  }

  FileEntry copyWith({
    int? id,
    String? sha256,
    String? path,
    int? size,
    int? modifiedAt,
    Value<int?> takenAt = const Value.absent(),
    String? mediaType,
    bool? onDevice,
    bool? complete,
  }) => FileEntry(
    id: id ?? this.id,
    sha256: sha256 ?? this.sha256,
    path: path ?? this.path,
    size: size ?? this.size,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    takenAt: takenAt.present ? takenAt.value : this.takenAt,
    mediaType: mediaType ?? this.mediaType,
    onDevice: onDevice ?? this.onDevice,
    complete: complete ?? this.complete,
  );
  FileEntry copyWithCompanion(FileEntriesCompanion data) {
    return FileEntry(
      id: data.id.present ? data.id.value : this.id,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      path: data.path.present ? data.path.value : this.path,
      size: data.size.present ? data.size.value : this.size,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      onDevice: data.onDevice.present ? data.onDevice.value : this.onDevice,
      complete: data.complete.present ? data.complete.value : this.complete,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FileEntry(')
          ..write('id: $id, ')
          ..write('sha256: $sha256, ')
          ..write('path: $path, ')
          ..write('size: $size, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('takenAt: $takenAt, ')
          ..write('mediaType: $mediaType, ')
          ..write('onDevice: $onDevice, ')
          ..write('complete: $complete')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sha256,
    path,
    size,
    modifiedAt,
    takenAt,
    mediaType,
    onDevice,
    complete,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FileEntry &&
          other.id == this.id &&
          other.sha256 == this.sha256 &&
          other.path == this.path &&
          other.size == this.size &&
          other.modifiedAt == this.modifiedAt &&
          other.takenAt == this.takenAt &&
          other.mediaType == this.mediaType &&
          other.onDevice == this.onDevice &&
          other.complete == this.complete);
}

class FileEntriesCompanion extends UpdateCompanion<FileEntry> {
  final Value<int> id;
  final Value<String> sha256;
  final Value<String> path;
  final Value<int> size;
  final Value<int> modifiedAt;
  final Value<int?> takenAt;
  final Value<String> mediaType;
  final Value<bool> onDevice;
  final Value<bool> complete;
  const FileEntriesCompanion({
    this.id = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.path = const Value.absent(),
    this.size = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.onDevice = const Value.absent(),
    this.complete = const Value.absent(),
  });
  FileEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String sha256,
    required String path,
    required int size,
    required int modifiedAt,
    this.takenAt = const Value.absent(),
    required String mediaType,
    this.onDevice = const Value.absent(),
    this.complete = const Value.absent(),
  }) : sha256 = Value(sha256),
       path = Value(path),
       size = Value(size),
       modifiedAt = Value(modifiedAt),
       mediaType = Value(mediaType);
  static Insertable<FileEntry> custom({
    Expression<int>? id,
    Expression<String>? sha256,
    Expression<String>? path,
    Expression<int>? size,
    Expression<int>? modifiedAt,
    Expression<int>? takenAt,
    Expression<String>? mediaType,
    Expression<bool>? onDevice,
    Expression<bool>? complete,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sha256 != null) 'sha256': sha256,
      if (path != null) 'path': path,
      if (size != null) 'size': size,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (takenAt != null) 'taken_at': takenAt,
      if (mediaType != null) 'media_type': mediaType,
      if (onDevice != null) 'on_device': onDevice,
      if (complete != null) 'complete': complete,
    });
  }

  FileEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? sha256,
    Value<String>? path,
    Value<int>? size,
    Value<int>? modifiedAt,
    Value<int?>? takenAt,
    Value<String>? mediaType,
    Value<bool>? onDevice,
    Value<bool>? complete,
  }) {
    return FileEntriesCompanion(
      id: id ?? this.id,
      sha256: sha256 ?? this.sha256,
      path: path ?? this.path,
      size: size ?? this.size,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      takenAt: takenAt ?? this.takenAt,
      mediaType: mediaType ?? this.mediaType,
      onDevice: onDevice ?? this.onDevice,
      complete: complete ?? this.complete,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<int>(takenAt.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (onDevice.present) {
      map['on_device'] = Variable<bool>(onDevice.value);
    }
    if (complete.present) {
      map['complete'] = Variable<bool>(complete.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FileEntriesCompanion(')
          ..write('id: $id, ')
          ..write('sha256: $sha256, ')
          ..write('path: $path, ')
          ..write('size: $size, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('takenAt: $takenAt, ')
          ..write('mediaType: $mediaType, ')
          ..write('onDevice: $onDevice, ')
          ..write('complete: $complete')
          ..write(')'))
        .toString();
  }
}

class $FilePartsTable extends FileParts
    with TableInfo<$FilePartsTable, FilePart> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilePartsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<int> fileId = GeneratedColumn<int>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES file_entries (id)',
    ),
  );
  static const VerificationMeta _partIndexMeta = const VerificationMeta(
    'partIndex',
  );
  @override
  late final GeneratedColumn<int> partIndex = GeneratedColumn<int>(
    'part_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteRefMeta = const VerificationMeta(
    'remoteRef',
  );
  @override
  late final GeneratedColumn<String> remoteRef = GeneratedColumn<String>(
    'remote_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fileId,
    partIndex,
    remoteRef,
    size,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'file_parts';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilePart> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('part_index')) {
      context.handle(
        _partIndexMeta,
        partIndex.isAcceptableOrUnknown(data['part_index']!, _partIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_partIndexMeta);
    }
    if (data.containsKey('remote_ref')) {
      context.handle(
        _remoteRefMeta,
        remoteRef.isAcceptableOrUnknown(data['remote_ref']!, _remoteRefMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteRefMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {fileId, partIndex},
  ];
  @override
  FilePart map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilePart(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_id'],
      )!,
      partIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}part_index'],
      )!,
      remoteRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_ref'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
    );
  }

  @override
  $FilePartsTable createAlias(String alias) {
    return $FilePartsTable(attachedDatabase, alias);
  }
}

class FilePart extends DataClass implements Insertable<FilePart> {
  final int id;
  final int fileId;
  final int partIndex;
  final String remoteRef;
  final int size;
  const FilePart({
    required this.id,
    required this.fileId,
    required this.partIndex,
    required this.remoteRef,
    required this.size,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_id'] = Variable<int>(fileId);
    map['part_index'] = Variable<int>(partIndex);
    map['remote_ref'] = Variable<String>(remoteRef);
    map['size'] = Variable<int>(size);
    return map;
  }

  FilePartsCompanion toCompanion(bool nullToAbsent) {
    return FilePartsCompanion(
      id: Value(id),
      fileId: Value(fileId),
      partIndex: Value(partIndex),
      remoteRef: Value(remoteRef),
      size: Value(size),
    );
  }

  factory FilePart.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilePart(
      id: serializer.fromJson<int>(json['id']),
      fileId: serializer.fromJson<int>(json['fileId']),
      partIndex: serializer.fromJson<int>(json['partIndex']),
      remoteRef: serializer.fromJson<String>(json['remoteRef']),
      size: serializer.fromJson<int>(json['size']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fileId': serializer.toJson<int>(fileId),
      'partIndex': serializer.toJson<int>(partIndex),
      'remoteRef': serializer.toJson<String>(remoteRef),
      'size': serializer.toJson<int>(size),
    };
  }

  FilePart copyWith({
    int? id,
    int? fileId,
    int? partIndex,
    String? remoteRef,
    int? size,
  }) => FilePart(
    id: id ?? this.id,
    fileId: fileId ?? this.fileId,
    partIndex: partIndex ?? this.partIndex,
    remoteRef: remoteRef ?? this.remoteRef,
    size: size ?? this.size,
  );
  FilePart copyWithCompanion(FilePartsCompanion data) {
    return FilePart(
      id: data.id.present ? data.id.value : this.id,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      partIndex: data.partIndex.present ? data.partIndex.value : this.partIndex,
      remoteRef: data.remoteRef.present ? data.remoteRef.value : this.remoteRef,
      size: data.size.present ? data.size.value : this.size,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilePart(')
          ..write('id: $id, ')
          ..write('fileId: $fileId, ')
          ..write('partIndex: $partIndex, ')
          ..write('remoteRef: $remoteRef, ')
          ..write('size: $size')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fileId, partIndex, remoteRef, size);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilePart &&
          other.id == this.id &&
          other.fileId == this.fileId &&
          other.partIndex == this.partIndex &&
          other.remoteRef == this.remoteRef &&
          other.size == this.size);
}

class FilePartsCompanion extends UpdateCompanion<FilePart> {
  final Value<int> id;
  final Value<int> fileId;
  final Value<int> partIndex;
  final Value<String> remoteRef;
  final Value<int> size;
  const FilePartsCompanion({
    this.id = const Value.absent(),
    this.fileId = const Value.absent(),
    this.partIndex = const Value.absent(),
    this.remoteRef = const Value.absent(),
    this.size = const Value.absent(),
  });
  FilePartsCompanion.insert({
    this.id = const Value.absent(),
    required int fileId,
    required int partIndex,
    required String remoteRef,
    required int size,
  }) : fileId = Value(fileId),
       partIndex = Value(partIndex),
       remoteRef = Value(remoteRef),
       size = Value(size);
  static Insertable<FilePart> custom({
    Expression<int>? id,
    Expression<int>? fileId,
    Expression<int>? partIndex,
    Expression<String>? remoteRef,
    Expression<int>? size,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileId != null) 'file_id': fileId,
      if (partIndex != null) 'part_index': partIndex,
      if (remoteRef != null) 'remote_ref': remoteRef,
      if (size != null) 'size': size,
    });
  }

  FilePartsCompanion copyWith({
    Value<int>? id,
    Value<int>? fileId,
    Value<int>? partIndex,
    Value<String>? remoteRef,
    Value<int>? size,
  }) {
    return FilePartsCompanion(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      partIndex: partIndex ?? this.partIndex,
      remoteRef: remoteRef ?? this.remoteRef,
      size: size ?? this.size,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<int>(fileId.value);
    }
    if (partIndex.present) {
      map['part_index'] = Variable<int>(partIndex.value);
    }
    if (remoteRef.present) {
      map['remote_ref'] = Variable<String>(remoteRef.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilePartsCompanion(')
          ..write('id: $id, ')
          ..write('fileId: $fileId, ')
          ..write('partIndex: $partIndex, ')
          ..write('remoteRef: $remoteRef, ')
          ..write('size: $size')
          ..write(')'))
        .toString();
  }
}

abstract class _$IndexDatabase extends GeneratedDatabase {
  _$IndexDatabase(QueryExecutor e) : super(e);
  $IndexDatabaseManager get managers => $IndexDatabaseManager(this);
  late final $FileEntriesTable fileEntries = $FileEntriesTable(this);
  late final $FilePartsTable fileParts = $FilePartsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [fileEntries, fileParts];
}

typedef $$FileEntriesTableCreateCompanionBuilder =
    FileEntriesCompanion Function({
      Value<int> id,
      required String sha256,
      required String path,
      required int size,
      required int modifiedAt,
      Value<int?> takenAt,
      required String mediaType,
      Value<bool> onDevice,
      Value<bool> complete,
    });
typedef $$FileEntriesTableUpdateCompanionBuilder =
    FileEntriesCompanion Function({
      Value<int> id,
      Value<String> sha256,
      Value<String> path,
      Value<int> size,
      Value<int> modifiedAt,
      Value<int?> takenAt,
      Value<String> mediaType,
      Value<bool> onDevice,
      Value<bool> complete,
    });

final class $$FileEntriesTableReferences
    extends BaseReferences<_$IndexDatabase, $FileEntriesTable, FileEntry> {
  $$FileEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FilePartsTable, List<FilePart>>
  _filePartsRefsTable(_$IndexDatabase db) => MultiTypedResultKey.fromTable(
    db.fileParts,
    aliasName: 'file_entries__id__file_parts__file_id',
  );

  $$FilePartsTableProcessedTableManager get filePartsRefs {
    final manager = $$FilePartsTableTableManager(
      $_db,
      $_db.fileParts,
    ).filter((f) => f.fileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_filePartsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FileEntriesTableFilterComposer
    extends Composer<_$IndexDatabase, $FileEntriesTable> {
  $$FileEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onDevice => $composableBuilder(
    column: $table.onDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> filePartsRefs(
    Expression<bool> Function($$FilePartsTableFilterComposer f) f,
  ) {
    final $$FilePartsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fileParts,
      getReferencedColumn: (t) => t.fileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilePartsTableFilterComposer(
            $db: $db,
            $table: $db.fileParts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FileEntriesTableOrderingComposer
    extends Composer<_$IndexDatabase, $FileEntriesTable> {
  $$FileEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onDevice => $composableBuilder(
    column: $table.onDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FileEntriesTableAnnotationComposer
    extends Composer<_$IndexDatabase, $FileEntriesTable> {
  $$FileEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<bool> get onDevice =>
      $composableBuilder(column: $table.onDevice, builder: (column) => column);

  GeneratedColumn<bool> get complete =>
      $composableBuilder(column: $table.complete, builder: (column) => column);

  Expression<T> filePartsRefs<T extends Object>(
    Expression<T> Function($$FilePartsTableAnnotationComposer a) f,
  ) {
    final $$FilePartsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fileParts,
      getReferencedColumn: (t) => t.fileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilePartsTableAnnotationComposer(
            $db: $db,
            $table: $db.fileParts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FileEntriesTableTableManager
    extends
        RootTableManager<
          _$IndexDatabase,
          $FileEntriesTable,
          FileEntry,
          $$FileEntriesTableFilterComposer,
          $$FileEntriesTableOrderingComposer,
          $$FileEntriesTableAnnotationComposer,
          $$FileEntriesTableCreateCompanionBuilder,
          $$FileEntriesTableUpdateCompanionBuilder,
          (FileEntry, $$FileEntriesTableReferences),
          FileEntry,
          PrefetchHooks Function({bool filePartsRefs})
        > {
  $$FileEntriesTableTableManager(_$IndexDatabase db, $FileEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FileEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FileEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FileEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<int?> takenAt = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<bool> onDevice = const Value.absent(),
                Value<bool> complete = const Value.absent(),
              }) => FileEntriesCompanion(
                id: id,
                sha256: sha256,
                path: path,
                size: size,
                modifiedAt: modifiedAt,
                takenAt: takenAt,
                mediaType: mediaType,
                onDevice: onDevice,
                complete: complete,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sha256,
                required String path,
                required int size,
                required int modifiedAt,
                Value<int?> takenAt = const Value.absent(),
                required String mediaType,
                Value<bool> onDevice = const Value.absent(),
                Value<bool> complete = const Value.absent(),
              }) => FileEntriesCompanion.insert(
                id: id,
                sha256: sha256,
                path: path,
                size: size,
                modifiedAt: modifiedAt,
                takenAt: takenAt,
                mediaType: mediaType,
                onDevice: onDevice,
                complete: complete,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FileEntriesTable, FileEntry>(table),
                  $$FileEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({filePartsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (filePartsRefs) db.fileParts],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (filePartsRefs)
                    await $_getPrefetchedDataByColumns<
                      FileEntry,
                      $FileEntriesTable,
                      FilePart,
                      $FilePartsTable
                    >(
                      currentTable: table,
                      referencedTable: $$FileEntriesTableReferences
                          ._filePartsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FileEntriesTableReferences(
                            db,
                            table,
                            p0,
                          ).filePartsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'file_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FileEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$IndexDatabase,
      $FileEntriesTable,
      FileEntry,
      $$FileEntriesTableFilterComposer,
      $$FileEntriesTableOrderingComposer,
      $$FileEntriesTableAnnotationComposer,
      $$FileEntriesTableCreateCompanionBuilder,
      $$FileEntriesTableUpdateCompanionBuilder,
      (FileEntry, $$FileEntriesTableReferences),
      FileEntry,
      PrefetchHooks Function({bool filePartsRefs})
    >;
typedef $$FilePartsTableCreateCompanionBuilder = FilePartsCompanion Function({
  Value<int> id,
  required int fileId,
  required int partIndex,
  required String remoteRef,
  required int size,
});
typedef $$FilePartsTableUpdateCompanionBuilder = FilePartsCompanion Function({
  Value<int> id,
  Value<int> fileId,
  Value<int> partIndex,
  Value<String> remoteRef,
  Value<int> size,
});

final class $$FilePartsTableReferences
    extends BaseReferences<_$IndexDatabase, $FilePartsTable, FilePart> {
  $$FilePartsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FileEntriesTable _fileIdTable(_$IndexDatabase db) =>
      db.fileEntries.createAlias('file_parts__file_id__file_entries__id');

  $$FileEntriesTableProcessedTableManager get fileId {
    final $_column = $_itemColumn<int>('file_id')!;

    final manager = $$FileEntriesTableTableManager(
      $_db,
      $_db.fileEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FilePartsTableFilterComposer
    extends Composer<_$IndexDatabase, $FilePartsTable> {
  $$FilePartsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partIndex => $composableBuilder(
    column: $table.partIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteRef => $composableBuilder(
    column: $table.remoteRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  $$FileEntriesTableFilterComposer get fileId {
    final $$FileEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fileId,
      referencedTable: $db.fileEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FileEntriesTableFilterComposer(
            $db: $db,
            $table: $db.fileEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FilePartsTableOrderingComposer
    extends Composer<_$IndexDatabase, $FilePartsTable> {
  $$FilePartsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partIndex => $composableBuilder(
    column: $table.partIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteRef => $composableBuilder(
    column: $table.remoteRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  $$FileEntriesTableOrderingComposer get fileId {
    final $$FileEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fileId,
      referencedTable: $db.fileEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FileEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.fileEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FilePartsTableAnnotationComposer
    extends Composer<_$IndexDatabase, $FilePartsTable> {
  $$FilePartsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get partIndex =>
      $composableBuilder(column: $table.partIndex, builder: (column) => column);

  GeneratedColumn<String> get remoteRef =>
      $composableBuilder(column: $table.remoteRef, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  $$FileEntriesTableAnnotationComposer get fileId {
    final $$FileEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fileId,
      referencedTable: $db.fileEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FileEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.fileEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FilePartsTableTableManager
    extends
        RootTableManager<
          _$IndexDatabase,
          $FilePartsTable,
          FilePart,
          $$FilePartsTableFilterComposer,
          $$FilePartsTableOrderingComposer,
          $$FilePartsTableAnnotationComposer,
          $$FilePartsTableCreateCompanionBuilder,
          $$FilePartsTableUpdateCompanionBuilder,
          (FilePart, $$FilePartsTableReferences),
          FilePart,
          PrefetchHooks Function({bool fileId})
        > {
  $$FilePartsTableTableManager(_$IndexDatabase db, $FilePartsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilePartsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilePartsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilePartsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> fileId = const Value.absent(),
                Value<int> partIndex = const Value.absent(),
                Value<String> remoteRef = const Value.absent(),
                Value<int> size = const Value.absent(),
              }) => FilePartsCompanion(
                id: id,
                fileId: fileId,
                partIndex: partIndex,
                remoteRef: remoteRef,
                size: size,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int fileId,
                required int partIndex,
                required String remoteRef,
                required int size,
              }) => FilePartsCompanion.insert(
                id: id,
                fileId: fileId,
                partIndex: partIndex,
                remoteRef: remoteRef,
                size: size,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FilePartsTable, FilePart>(table),
                  $$FilePartsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({fileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (fileId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.fileId,
                        referencedTable: $$FilePartsTableReferences
                            ._fileIdTable(db),
                        referencedColumn: $$FilePartsTableReferences
                            ._fileIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FilePartsTableProcessedTableManager =
    ProcessedTableManager<
      _$IndexDatabase,
      $FilePartsTable,
      FilePart,
      $$FilePartsTableFilterComposer,
      $$FilePartsTableOrderingComposer,
      $$FilePartsTableAnnotationComposer,
      $$FilePartsTableCreateCompanionBuilder,
      $$FilePartsTableUpdateCompanionBuilder,
      (FilePart, $$FilePartsTableReferences),
      FilePart,
      PrefetchHooks Function({bool fileId})
    >;

class $IndexDatabaseManager {
  final _$IndexDatabase _db;
  $IndexDatabaseManager(this._db);
  $$FileEntriesTableTableManager get fileEntries =>
      $$FileEntriesTableTableManager(_db, _db.fileEntries);
  $$FilePartsTableTableManager get fileParts =>
      $$FilePartsTableTableManager(_db, _db.fileParts);
}
