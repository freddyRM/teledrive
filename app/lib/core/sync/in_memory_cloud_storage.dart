import 'dart:typed_data';

import 'cloud_storage.dart';

/// Almacen remoto falso para pruebas. Guarda los objetos en memoria.
class InMemoryCloudStorage implements CloudStorage {
  final Map<String, Uint8List> _objects = {};
  int _counter = 0;

  /// Si devuelve true para un nombre, el put de ese objeto falla (simula corte de red).
  bool Function(String name)? failPut;

  int get objectCount => _objects.length;

  @override
  Future<String> put(String name, Stream<List<int>> body, int length) async {
    if (failPut?.call(name) ?? false) {
      throw StateError('Fallo simulado al subir $name');
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in body) {
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    if (bytes.length != length) {
      throw StateError('Longitud inesperada para $name');
    }
    final ref = 'mem-${++_counter}';
    _objects[ref] = bytes;
    return ref;
  }

  @override
  Stream<List<int>> get(String ref) {
    final bytes = _objects[ref];
    if (bytes == null) return Stream.error(StateError('No existe $ref'));
    return Stream.value(bytes);
  }

  @override
  Future<int?> sizeOf(String ref) async => _objects[ref]?.length;

  @override
  Future<void> delete(String ref) async {
    _objects.remove(ref);
  }
}
