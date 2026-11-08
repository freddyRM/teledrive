import 'package:shared_preferences/shared_preferences.dart';

/// Guarda la frase maestra en el almacenamiento local de la app.
/// Es temporal para la fase de pruebas: no esta protegida con el almacen seguro del telefono.
class PassphraseStore {
  PassphraseStore._();

  static const _key = 'master_passphrase';

  static Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    return (value == null || value.isEmpty) ? null : value;
  }

  static Future<void> write(String passphrase) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, passphrase);
  }
}
