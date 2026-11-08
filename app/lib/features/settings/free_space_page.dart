import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/settings/passphrase_store.dart';
import '../../core/tdlib/chat_files.dart';
import '../../core/tdlib/cloud_index.dart';
import '../../core/tdlib/telegram_auth.dart';
import '../gallery/nube_page.dart';

/// Liberar espacio. Dos acciones separadas, cada una con su confirmacion:
/// quitar del telefono lo que ya esta en el grupo, o borrar del grupo.
class FreeSpacePage extends StatefulWidget {
  const FreeSpacePage({super.key, required this.auth, required this.chatId});

  final TelegramAuth auth;
  final int chatId;

  @override
  State<FreeSpacePage> createState() => _FreeSpacePageState();
}

class _FreeSpacePageState extends State<FreeSpacePage> {
  bool _loading = true;
  bool _busy = false;
  String? _error;

  /// En el telefono y en el grupo: se pueden quitar del telefono sin perder nada.
  List<ChatFile> _synced = [];

  /// Solo en el grupo: borrarlas aqui las elimina para siempre.
  List<ChatFile> _cloudOnly = [];

  final Set<int> _syncedSel = {};
  final Set<int> _cloudSel = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final passphrase = await PassphraseStore.read();
      if (passphrase == null) {
        setState(() {
          _error = 'Configura la frase maestra en Ajustes.';
          _loading = false;
        });
        return;
      }
      final files = (await ChatFiles(auth: widget.auth, chatId: widget.chatId)
              .load(passphrase: passphrase))
          .where((file) => file.encrypted)
          .toList();
      final local = await _localIds();
      final synced = <ChatFile>[];
      final cloudOnly = <ChatFile>[];
      for (final file in files) {
        final assetId = file.assetId;
        if (assetId != null && local.contains(assetId)) {
          synced.add(file);
        } else {
          cloudOnly.add(file);
        }
      }
      if (!mounted) return;
      setState(() {
        _synced = synced;
        _cloudOnly = cloudOnly;
        _syncedSel.clear();
        _cloudSel.clear();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  /// IDs de todas las fotos y videos del telefono.
  Future<Set<String>> _localIds() async {
    final ids = <String>{};
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
    );
    if (paths.isEmpty) return ids;
    var page = 0;
    while (true) {
      final batch = await paths.first.getAssetListPaged(page: page, size: 200);
      ids.addAll(batch.map((asset) => asset.id));
      if (batch.length < 200) break;
      page++;
    }
    return ids;
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
        ],
      ),
    );
    return ok == true;
  }

  void _snack(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _removeFromPhone() async {
    final chosen = _synced.where((file) => _syncedSel.contains(file.messageId)).toList();
    if (chosen.isEmpty) return;
    final ok = await _confirm(
      title: 'Quitar ${chosen.length} del telefono',
      body: 'Se quitan del telefono. Siguen en el grupo y puedes bajarlas despues. '
          'Android te pedira confirmar el borrado.',
      action: 'Quitar del telefono',
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      final deleted = await PhotoManager.editor.deleteWithIds(
        chosen.map((file) => file.assetId!).toList(),
      );
      _snack('Quitadas del telefono: ${deleted.length}');
    } catch (error) {
      _snack('No se pudo quitar: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _load();
  }

  Future<void> _deleteFromCloud() async {
    final chosen = _cloudOnly.where((file) => _cloudSel.contains(file.messageId)).toList();
    if (chosen.isEmpty) return;
    final ok = await _confirm(
      title: 'Borrar ${chosen.length} del grupo',
      body: 'Se borran del grupo para todos los miembros, para siempre. No se puede deshacer. '
          'Si alguna tiene copia en el telefono que no pudimos comparar, esa copia no se toca.',
      action: 'Borrar para siempre',
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      final done = await ChatFiles(auth: widget.auth, chatId: widget.chatId)
          .deleteMessages(chosen.map((file) => file.messageId).toList());
      if (done) {
        await CloudIndex.remove(chosen.map((file) => file.assetId).whereType<String>());
      }
      _snack(done ? 'Borradas del grupo' : 'No se pudo borrar del grupo');
    } catch (error) {
      _snack('No se pudo borrar: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _load();
  }

  static String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  Widget _section(String title, String help) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(help, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  /// Tocar la fila marca el elemento; el ojo abre la vista previa, antes de cualquier borrado.
  Widget _tile(ChatFile file, Set<int> selection) {
    final checked = selection.contains(file.messageId);
    void toggle() => setState(() {
          if (checked) {
            selection.remove(file.messageId);
          } else {
            selection.add(file.messageId);
          }
        });
    return ListTile(
      onTap: _busy ? null : toggle,
      leading: Checkbox(value: checked, onChanged: _busy ? null : (_) => toggle()),
      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${_formatSize(file.size)} · ${file.date.day}/${file.date.month}/${file.date.year}'),
      trailing: IconButton(
        tooltip: 'Ver',
        icon: const Icon(Icons.visibility_outlined),
        onPressed: _busy
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CloudViewerPage(
                      auth: widget.auth,
                      chatId: widget.chatId,
                      file: file,
                    ),
                  ),
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liberar espacio')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : ListView(
                  children: [
                    _section(
                      'En el telefono y en el grupo (${_synced.length})',
                      'Puedes quitarlas del telefono. Siguen en el grupo.',
                    ),
                    for (final file in _synced) _tile(file, _syncedSel),
                    _section(
                      'Solo en el grupo (${_cloudOnly.length})',
                      'Borrarlas aqui las elimina para siempre, tambien del grupo.',
                    ),
                    for (final file in _cloudOnly) _tile(file, _cloudSel),
                    const SizedBox(height: 80),
                  ],
                ),
      bottomNavigationBar: _loading || _error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy || _syncedSel.isEmpty ? null : _removeFromPhone,
                        child: Text('Quitar del telefono (${_syncedSel.length})'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: _busy || _cloudSel.isEmpty ? null : _deleteFromCloud,
                        child: Text('Borrar del grupo (${_cloudSel.length})'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
