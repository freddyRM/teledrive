import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Cifrado por bloques de archivos antes de subirlos a Telegram.
///
/// Formato:
///   cabecera: "DRV1" (4) + sal (16) + nonce base (8)
///   bloque:   bandera ultimo (1) + longitud (4) + texto cifrado + etiqueta GCM (16)
///
/// La bandera y el indice del bloque van en los datos asociados (AAD), asi que
/// no se puede reordenar, recortar ni alterar bloques sin que falle la verificacion.
class VaultCipher {
  VaultCipher._();

  static const chunkSize = 1024 * 1024;

  static const _magic = [0x44, 0x52, 0x56, 0x31]; // "DRV1"
  static const _saltLength = 16;
  static const _baseNonceLength = 8;
  static const _headerLength = 4 + _saltLength + _baseNonceLength;
  static const _frameHeaderLength = 5;
  static const _tagLength = 16;

  static final _kdf = Argon2id(
    memory: 65536, // 64 MiB (en KiB)
    parallelism: 1,
    iterations: 3,
    hashLength: 32,
  );
  static final _aes = AesGcm.with256bits();

  static Future<SecretKey> deriveKey(String passphrase, List<int> salt) {
    return _kdf.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  /// Cifra [plain] y entrega el archivo cifrado en trozos.
  static Stream<List<int>> encrypt(Stream<List<int>> plain, String passphrase) async* {
    final random = Random.secure();
    final salt = _randomBytes(random, _saltLength);
    final baseNonce = _randomBytes(random, _baseNonceLength);
    final key = await deriveKey(passphrase, salt);

    yield [..._magic, ...salt, ...baseNonce];

    // Se espera un bloque de adelanto para saber cual es el ultimo.
    var index = 0;
    Uint8List? current;
    await for (final block in _blocks(plain)) {
      if (current != null) {
        yield await _seal(current, index++, key, baseNonce, isLast: false);
      }
      current = block;
    }
    yield await _seal(current ?? Uint8List(0), index, key, baseNonce, isLast: true);
  }

  /// Descifra [encrypted] y entrega el contenido original en trozos.
  /// Lanza error si la frase es incorrecta, si hay datos alterados o truncados.
  static Stream<List<int>> decrypt(Stream<List<int>> encrypted, String passphrase) async* {
    final reader = _ByteReader(encrypted);
    try {
      final header = await reader.take(_headerLength);
      for (var i = 0; i < _magic.length; i++) {
        if (header[i] != _magic[i]) {
          throw const FormatException('No es un archivo cifrado valido');
        }
      }
      final salt = header.sublist(4, 4 + _saltLength);
      final baseNonce = header.sublist(4 + _saltLength, _headerLength);
      final key = await deriveKey(passphrase, salt);

      var index = 0;
      while (true) {
        final frameHeader = await reader.take(_frameHeaderLength);
        final isLast = frameHeader[0] == 1;
        final length = ByteData.sublistView(frameHeader).getUint32(1);
        if (length < _tagLength || length > chunkSize + _tagLength) {
          throw const FormatException('Bloque con longitud invalida');
        }

        final frame = await reader.take(length);
        final cipherText = frame.sublist(0, length - _tagLength);
        final mac = frame.sublist(length - _tagLength);

        final plainBlock = await _aes.decrypt(
          SecretBox(cipherText, nonce: _nonce(baseNonce, index), mac: Mac(mac)),
          secretKey: key,
          aad: _aad(index, isLast: isLast),
        );
        yield plainBlock;

        index++;
        if (isLast) {
          if (!await reader.atEnd()) {
            throw const FormatException('Hay datos despues del ultimo bloque');
          }
          return;
        }
      }
    } finally {
      await reader.close();
    }
  }

  static Stream<Uint8List> _blocks(Stream<List<int>> input) async* {
    final buffer = BytesBuilder(copy: false);
    await for (final data in input) {
      buffer.add(data);
      while (buffer.length >= chunkSize) {
        final all = buffer.takeBytes();
        yield Uint8List.fromList(all.sublist(0, chunkSize));
        buffer.add(all.sublist(chunkSize));
      }
    }
    final rest = buffer.takeBytes();
    if (rest.isNotEmpty) yield rest;
  }

  static Future<Uint8List> _seal(
    Uint8List data,
    int index,
    SecretKey key,
    Uint8List baseNonce, {
    required bool isLast,
  }) async {
    final box = await _aes.encrypt(
      data,
      secretKey: key,
      nonce: _nonce(baseNonce, index),
      aad: _aad(index, isLast: isLast),
    );
    final cipherLength = box.cipherText.length;
    final length = cipherLength + _tagLength;

    final frame = Uint8List(_frameHeaderLength + length);
    final view = ByteData.sublistView(frame);
    view.setUint8(0, isLast ? 1 : 0);
    view.setUint32(1, length);
    frame.setAll(_frameHeaderLength, box.cipherText);
    frame.setAll(_frameHeaderLength + cipherLength, box.mac.bytes);
    return frame;
  }

  static Uint8List _nonce(Uint8List baseNonce, int index) {
    final nonce = Uint8List(12);
    nonce.setAll(0, baseNonce);
    ByteData.sublistView(nonce).setUint32(_baseNonceLength, index);
    return nonce;
  }

  static Uint8List _aad(int index, {required bool isLast}) {
    final aad = Uint8List(9);
    aad[0] = isLast ? 1 : 0;
    ByteData.sublistView(aad).setUint64(1, index);
    return aad;
  }

  static Uint8List _randomBytes(Random random, int length) {
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }
}

/// Lee bytes exactos desde un stream de trozos.
class _ByteReader {
  _ByteReader(Stream<List<int>> source) : _iterator = StreamIterator(source);

  final StreamIterator<List<int>> _iterator;
  Uint8List _buffer = Uint8List(0);
  int _position = 0;

  Future<bool> _fill() async {
    if (!await _iterator.moveNext()) return false;
    _buffer = Uint8List.fromList(_iterator.current);
    _position = 0;
    return true;
  }

  Future<Uint8List> take(int count) async {
    final out = BytesBuilder(copy: false);
    var needed = count;
    while (needed > 0) {
      if (_position >= _buffer.length && !await _fill()) {
        throw const FormatException('Archivo truncado');
      }
      final available = min(needed, _buffer.length - _position);
      out.add(Uint8List.sublistView(_buffer, _position, _position + available));
      _position += available;
      needed -= available;
    }
    return out.takeBytes();
  }

  Future<bool> atEnd() async {
    while (_position >= _buffer.length) {
      if (!await _fill()) return true;
    }
    return false;
  }

  Future<void> close() => _iterator.cancel();
}
