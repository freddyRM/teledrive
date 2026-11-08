import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'vault_cipher.dart';

/// Cifra y descifra las descripciones (metadatos) de los archivos subidos.
///
/// Formato nuevo (DRV2): la clave se deriva una sola vez por sesion con una sal guardada
/// en la app, asi leer el grupo no tarda minutos. Formato anterior (DRV1) se sigue leyendo.
class VaultSmall {
  VaultSmall._();

  static const v2Prefix = 'DRV2:';
  static const _v1Prefix = 'DRV1:';
  static const _saltKey = 'caption_salt';

  static final _aes = AesGcm.with256bits();
  static SecretKey? _key;
  static String? _keyPassphrase;

  static Future<SecretKey> _keyFor(String passphrase) async {
    if (_key != null && _keyPassphrase == passphrase) return _key!;
    final prefs = await SharedPreferences.getInstance();
    var saltText = prefs.getString(_saltKey);
    if (saltText == null) {
      final random = Random.secure();
      saltText = base64Encode(List.generate(16, (_) => random.nextInt(256)));
      await prefs.setString(_saltKey, saltText);
    }
    _key = await VaultCipher.deriveKey(passphrase, base64Decode(saltText));
    _keyPassphrase = passphrase;
    return _key!;
  }

  /// Devuelve el texto cifrado con el prefijo DRV2.
  static Future<String> encryptText(String text, String passphrase) async {
    final key = await _keyFor(passphrase);
    final random = Random.secure();
    final nonce = List.generate(12, (_) => random.nextInt(256));
    final box = await _aes.encrypt(utf8.encode(text), secretKey: key, nonce: nonce);
    return v2Prefix + base64Encode([...nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  /// Descifra una descripcion DRV2 o DRV1 y devuelve el texto original.
  static Future<String> decryptCaption(String caption, String passphrase) async {
    if (caption.startsWith(v2Prefix)) {
      final bytes = base64Decode(caption.substring(v2Prefix.length));
      final key = await _keyFor(passphrase);
      final plain = await _aes.decrypt(
        SecretBox(
          bytes.sublist(12, bytes.length - 16),
          nonce: bytes.sublist(0, 12),
          mac: Mac(bytes.sublist(bytes.length - 16)),
        ),
        secretKey: key,
      );
      return utf8.decode(plain);
    }
    // Formato anterior: cada descripcion tenia su propia sal, por eso es mas lenta.
    final encoded = caption.substring(_v1Prefix.length);
    final out = <int>[];
    await for (final chunk in VaultCipher.decrypt(Stream.value(base64Decode(encoded)), passphrase)) {
      out.addAll(chunk);
    }
    return utf8.decode(out);
  }
}
