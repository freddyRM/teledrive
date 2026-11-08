import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/backup/backup_runner.dart';
import '../../core/backup/backup_store.dart';
import '../../core/network/network_policy.dart';
import '../../core/tdlib/telegram_auth.dart';

/// Elige que albumes del telefono se respaldan y sube los pendientes, cifrados.
class BackupPage extends StatefulWidget {
  const BackupPage({super.key, required this.auth, required this.chatId});

  final TelegramAuth auth;
  final int chatId;

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  List<AssetPathEntity> _albums = [];
  Set<String> _selected = {};
  final List<String> _lines = [];
  bool _loading = true;
  bool _running = false;
  NetworkPolicy _policy = NetworkPolicy.wifi;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      setState(() => _loading = false);
      return;
    }
    final albums = await PhotoManager.getAssetPathList(type: RequestType.common, onlyAll: false);
    final selected = await BackupStore.selectedAlbumIds();
    final policy = await NetworkPolicyStore.read();
    if (!mounted) return;
    setState(() {
      _albums = albums;
      _selected = selected;
      _policy = policy;
      _loading = false;
    });
  }

  Future<void> _setPolicy(NetworkPolicy policy) async {
    await NetworkPolicyStore.write(policy);
    if (mounted) setState(() => _policy = policy);
  }

  Future<void> _saveSelection() async {
    await BackupStore.setSelectedAlbumIds(_selected);
    _add('Seleccion guardada: ${_selected.length} albumes');
    // Al guardar, sube lo pendiente de inmediato si la red lo permite.
    BackupRunner.runIfAllowed(auth: widget.auth, chatId: widget.chatId, onLine: _add);
  }

  void _add(String line) {
    if (mounted) setState(() => _lines.add(line));
  }

  Future<void> _syncPending() async {
    // Lo elegido en pantalla cuenta aunque no se haya guardado.
    await BackupStore.setSelectedAlbumIds(_selected);
    setState(() {
      _running = true;
      _lines.clear();
    });
    try {
      await BackupRunner.run(auth: widget.auth, chatId: widget.chatId, onLine: _add);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Copias de seguridad')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Elige los albumes que quieres respaldar. Nada se sube sin que lo pidas.'),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final album in _albums)
                          CheckboxListTile(
                            value: _selected.contains(album.id),
                            title: Text(album.name),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selected.add(album.id);
                                } else {
                                  _selected.remove(album.id);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  SegmentedButton<NetworkPolicy>(
                    segments: const [
                      ButtonSegment(value: NetworkPolicy.wifi, label: Text('Solo Wi-Fi')),
                      ButtonSegment(value: NetworkPolicy.mobile, label: Text('Solo datos')),
                      ButtonSegment(value: NetworkPolicy.both, label: Text('Wi-Fi y datos')),
                    ],
                    selected: {_policy},
                    onSelectionChanged: (value) => _setPolicy(value.first),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(onPressed: _saveSelection, child: const Text('Guardar')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _running ? null : _syncPending,
                          child: Text(_running ? 'Subiendo...' : 'Subir pendientes'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ListView(children: [for (final line in _lines) Text(line)]),
                  ),
                ],
              ),
            ),
    );
  }
}
