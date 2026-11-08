import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:drive_personal/core/crypto/vault_cipher.dart';

const _passphrase = 'frase de prueba larga';

Uint8List _randomData(int length, {int seed = 1}) {
  final random = Random(seed);
  return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
}

Future<Uint8List> _collect(Stream<List<int>> stream) async {
  final out = BytesBuilder(copy: false);
  await for (final chunk in stream) {
    out.add(chunk);
  }
  return out.takeBytes();
}

Future<Uint8List> _encrypt(Uint8List data, String passphrase) {
  return _collect(VaultCipher.encrypt(Stream.value(data), passphrase));
}

Future<Uint8List> _decrypt(Uint8List encrypted, String passphrase) {
  return _collect(VaultCipher.decrypt(Stream.value(encrypted), passphrase));
}

void main() {
  const size = VaultCipher.chunkSize;

  group('VaultCipher', () {
    test('ida y vuelta en tamanos cercanos al borde de bloque', () async {
      for (final length in [0, 1, size - 1, size, size + 1, 3 * size + 7]) {
        final data = _randomData(length, seed: length);
        final encrypted = await _encrypt(data, _passphrase);
        final decrypted = await _decrypt(encrypted, _passphrase);
        expect(decrypted, equals(data), reason: 'longitud $length');
      }
    });

    test('el texto cifrado no contiene el original', () async {
      final data = Uint8List.fromList(List.filled(4096, 0x41));
      final encrypted = await _encrypt(data, _passphrase);
      expect(encrypted.length, greaterThan(data.length));
      expect(_contains(encrypted, List.filled(64, 0x41)), isFalse);
    });

    test('frase incorrecta falla', () async {
      final encrypted = await _encrypt(_randomData(1000), _passphrase);
      expect(() => _decrypt(encrypted, 'otra frase'), throwsA(anything));
    });

    test('un byte alterado falla', () async {
      final encrypted = await _encrypt(_randomData(2 * size + 10), _passphrase);
      final tampered = Uint8List.fromList(encrypted);
      tampered[tampered.length ~/ 2] ^= 0x01;
      expect(() => _decrypt(tampered, _passphrase), throwsA(anything));
    });

    test('un archivo truncado falla', () async {
      final encrypted = await _encrypt(_randomData(2 * size + 10), _passphrase);
      final truncated = Uint8List.sublistView(encrypted, 0, encrypted.length - 100);
      expect(() => _decrypt(truncated, _passphrase), throwsA(anything));
    });

    test('datos extra al final fallan', () async {
      final encrypted = await _encrypt(_randomData(1000), _passphrase);
      final extended = Uint8List.fromList([...encrypted, 0, 1, 2, 3]);
      expect(() => _decrypt(extended, _passphrase), throwsA(anything));
    });

    test('archivo que no es de este formato falla', () async {
      final garbage = Uint8List.fromList(List.filled(200, 7));
      expect(() => _decrypt(garbage, _passphrase), throwsA(isA<FormatException>()));
    });
  });
}

bool _contains(Uint8List haystack, List<int> needle) {
  outer:
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return true;
  }
  return false;
}
