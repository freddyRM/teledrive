import 'dart:async';

import 'package:flutter/foundation.dart';

import 'td_client.dart';

enum AuthStep { starting, waitPhone, waitCode, waitPassword, ready, closed }

/// Lleva el inicio de sesion de Telegram: parametros, telefono, codigo y contrasena.
class TelegramAuth extends ChangeNotifier {
  TelegramAuth({
    required this.client,
    required this.apiId,
    required this.apiHash,
    required this.databaseDir,
  });

  final TdClient client;
  final int apiId;
  final String apiHash;
  final String databaseDir;

  AuthStep step = AuthStep.starting;
  String? error;
  String lastEvent = 'ninguno';
  StreamSubscription<Map<String, dynamic>>? _subscription;

  final _events = StreamController<Map<String, dynamic>>.broadcast();

  /// Todas las actualizaciones y respuestas de TDLib, para que otras partes de la app escuchen.
  Stream<Map<String, dynamic>> get events => _events.stream;

  void start() {
    _subscription = client.updates.listen(_onUpdate);
    client.send({'@type': 'getAuthorizationState'});
  }

  void submitPhone(String phone) {
    error = null;
    client.send({'@type': 'setAuthenticationPhoneNumber', 'phone_number': phone.trim()});
  }

  void submitCode(String code) {
    error = null;
    client.send({'@type': 'checkAuthenticationCode', 'code': code.trim()});
  }

  void submitPassword(String password) {
    error = null;
    client.send({'@type': 'checkAuthenticationPassword', 'password': password});
  }

  void _onUpdate(Map<String, dynamic> update) {
    _events.add(update);
    final type = update['@type'] as String?;
    lastEvent = type ?? 'sin tipo';
    if (type == 'updateAuthorizationState') {
      final state = (update['authorization_state'] as Map<String, dynamic>)['@type'];
      _onAuthState(state as String);
    } else if (type == 'error' || type == 'diagnostic') {
      error = update['message']?.toString() ?? 'Error desconocido';
      notifyListeners();
    }
  }

  void _onAuthState(String state) {
    switch (state) {
      case 'authorizationStateWaitTdlibParameters':
        // Al cerrar sesion TDLib vuelve a este estado: volvemos a la pantalla de inicio.
        step = AuthStep.starting;
        client.send(_tdlibParameters());
      case 'authorizationStateWaitPhoneNumber':
        step = AuthStep.waitPhone;
      case 'authorizationStateWaitCode':
        step = AuthStep.waitCode;
      case 'authorizationStateWaitPassword':
        step = AuthStep.waitPassword;
      case 'authorizationStateReady':
        step = AuthStep.ready;
      case 'authorizationStateClosed':
        step = AuthStep.closed;
    }
    notifyListeners();
  }

  Map<String, dynamic> _tdlibParameters() {
    // TDLib 1.8.x espera los parametros como campos directos, no dentro de un objeto.
    return {
      '@type': 'setTdlibParameters',
      'use_test_dc': false,
      'database_directory': '$databaseDir/tdlib',
      'files_directory': '$databaseDir/tdlib_files',
      'use_file_database': true,
      'use_chat_info_database': true,
      'use_message_database': true,
      'use_secret_chats': false,
      'api_id': apiId,
      'api_hash': apiHash,
      'system_language_code': 'es',
      'device_model': 'Android',
      'system_version': 'Android',
      'application_version': '0.1.0',
      'enable_storage_optimizer': true,
      'ignore_file_names': false,
    };
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _events.close();
    super.dispose();
  }
}
