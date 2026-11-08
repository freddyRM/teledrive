import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

typedef _CreateNative = Pointer<Void> Function();
typedef _Create = Pointer<Void> Function();
typedef _SendNative = Void Function(Pointer<Void>, Pointer<Utf8>);
typedef _Send = void Function(Pointer<Void>, Pointer<Utf8>);
typedef _ReceiveNative = Pointer<Utf8> Function(Pointer<Void>, Double);
typedef _Receive = Pointer<Utf8> Function(Pointer<Void>, double);

/// Cliente de TDLib por JSON. Las respuestas y actualizaciones llegan por [updates].
class TdClient {
  TdClient._(this._client, this._send) {
    Isolate.spawn(
      _receiveLoop,
      [_port.sendPort, _client.address],
      onError: _errors.sendPort,
    );
    _port.listen((message) {
      _updates.add(jsonDecode(message as String) as Map<String, dynamic>);
    });
    _errors.listen((error) {
      _updates.add({'@type': 'diagnostic', 'message': error.toString()});
    });
  }

  final ReceivePort _errors = ReceivePort();

  final Pointer<Void> _client;
  final _Send _send;
  final ReceivePort _port = ReceivePort();
  // Un solo suscriptor: guarda los eventos que llegan antes de que alguien escuche,
  // por ejemplo el primer estado de autorizacion que TDLib emite al crear el cliente.
  final StreamController<Map<String, dynamic>> _updates = StreamController<Map<String, dynamic>>();

  Stream<Map<String, dynamic>> get updates => _updates.stream;

  static TdClient create() {
    final library = DynamicLibrary.open('libtdjson.so');
    final create = library.lookupFunction<_CreateNative, _Create>('td_json_client_create');
    final send = library.lookupFunction<_SendNative, _Send>('td_json_client_send');
    return TdClient._(create(), send);
  }

  /// Envia una peticion asincrona a TDLib. La respuesta llega por [updates].
  void send(Map<String, dynamic> request) {
    final pointer = jsonEncode(request).toNativeUtf8();
    try {
      _send(_client, pointer);
    } finally {
      malloc.free(pointer);
    }
  }

  static void _receiveLoop(List<Object> args) {
    final port = args[0] as SendPort;
    final address = args[1] as int;
    final library = DynamicLibrary.open('libtdjson.so');
    final receive = library.lookupFunction<_ReceiveNative, _Receive>('td_json_client_receive');
    final client = Pointer<Void>.fromAddress(address);
    while (true) {
      final response = receive(client, 1.0);
      if (response == nullptr) continue;
      port.send(response.toDartString());
    }
  }
}
