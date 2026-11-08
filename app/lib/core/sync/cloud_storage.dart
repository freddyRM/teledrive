/// Lo que el motor de sincronizacion necesita de un almacen remoto.
/// La implementacion real usara Telegram; las pruebas usan una version en memoria.
abstract interface class CloudStorage {
  /// Guarda [body] (de [length] bytes) con el nombre [name] y devuelve la referencia.
  Future<String> put(String name, Stream<List<int>> body, int length);

  /// Lee el objeto guardado en [ref].
  Stream<List<int>> get(String ref);

  /// Tamano del objeto, o null si no existe.
  Future<int?> sizeOf(String ref);

  Future<void> delete(String ref);
}
