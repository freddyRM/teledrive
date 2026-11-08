import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/network/network_policy.dart';
import '../../core/settings/passphrase_store.dart';
import '../../core/tdlib/chat_files.dart';
import '../../core/tdlib/encrypted_upload.dart';
import '../../core/tdlib/telegram_auth.dart';

/// Explorador de archivos del supergrupo. Lee nombres cifrados con la frase maestra.
class ArchivosPage extends StatefulWidget {
  const ArchivosPage({super.key, required this.auth, required this.chatId});

  final TelegramAuth auth;
  final int chatId;

  @override
  State<ArchivosPage> createState() => _ArchivosPageState();
}

class _ArchivosPageState extends State<ArchivosPage> {
  List<ChatFile> _files = [];
  final Set<int> _selected = {};
  bool _loading = true;
  bool _busy = false;
  String? _error;

  /// Frase maestra de la sesion. No se guarda en disco.
  String? _passphrase;

  @override
  void initState() {
    super.initState();
    // Se espera al primer dibujo: el dialogo de la frase necesita que la pantalla ya este lista.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  /// La frase se lee de Ajustes cada vez, asi un cambio ahi se aplica aqui sin reiniciar.
  Future<void> _ensurePassphrase() async {
    _passphrase = await PassphraseStore.read();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _ensurePassphrase();
      final files = await ChatFiles(auth: widget.auth, chatId: widget.chatId)
          .load(passphrase: _passphrase);
      if (!mounted) return;
      setState(() {
        _files = files;
        _selected.clear();
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

  /// Elige archivos del telefono y los sube cifrados, uno por uno. Respeta la politica de red.
  Future<void> _pickAndUpload() async {
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty) return;
    setState(() => _busy = true);
    var done = 0;
    try {
      await _ensurePassphrase();
      final passphrase = _passphrase;
      if (passphrase == null) {
        _snack('Necesito la frase maestra para subir cifrado.');
        return;
      }
      final support = await getApplicationSupportDirectory();
      final tdlibFiles = Directory('${support.path}/tdlib_files')..createSync(recursive: true);
      for (final file in picked) {
        final path = file.path;
        if (path == null) continue;
        if (!await NetworkPolicyStore.uploadAllowed()) {
          _snack('La red actual no esta permitida. Se detiene la subida.');
          break;
        }
        final upload = EncryptedUpload(auth: widget.auth, chatId: widget.chatId, log: (_) {});
        final ok = await upload.run(
          sourcePath: path,
          displayName: file.name,
          kind: _kindFor(file.name),
          passphrase: passphrase,
          tdlibFilesDir: tdlibFiles.path,
        );
        if (ok) done++;
      }
      _snack('Subidos $done de ${picked.length}');
    } catch (error) {
      _snack('Error: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
      await _reload();
    }
  }

  /// Tipo segun la extension: fotos, videos, audios o documento.
  static ChatFileKind _kindFor(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (const {'jpg', 'jpeg', 'png', 'webp', 'heic', 'gif'}.contains(ext)) return ChatFileKind.photo;
    if (const {'mp4', 'mov', 'mkv', 'avi', 'webm', '3gp'}.contains(ext)) return ChatFileKind.video;
    if (const {'mp3', 'm4a', 'ogg', 'wav', 'flac', 'aac'}.contains(ext)) return ChatFileKind.audio;
    return ChatFileKind.document;
  }

  void _snack(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _toggle(ChatFile file) {
    setState(() {
      if (!_selected.add(file.messageId)) _selected.remove(file.messageId);
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Borrar $count ${count == 1 ? 'elemento' : 'elementos'}'),
        content: const Text(
          'Se borran del supergrupo para todos los miembros. No se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await _delete(_selected.toList());
    _snack(ok ? 'Borrado' : 'No se pudo borrar');
    await _reload();
  }

  Future<bool> _delete(List<int> ids) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final completer = Completer<bool>();
    late StreamSubscription<Map<String, dynamic>> subscription;
    subscription = widget.auth.events.listen((update) {
      if (update['@extra'] == id && !completer.isCompleted) {
        subscription.cancel();
        completer.complete(update['@type'] == 'ok');
      }
    });
    widget.auth.client.send({
      '@type': 'deleteMessages',
      'chat_id': widget.chatId,
      'message_ids': ids,
      'revoke': true,
      '@extra': id,
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final selecting = _selected.isNotEmpty;
    return Scaffold(
      body: Column(
        children: [
          if (selecting)
            Material(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                title: Text('${_selected.length} seleccionados'),
                trailing: IconButton(
                  tooltip: 'Borrar',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _deleteSelected,
                ),
              ),
            ),
          if (_busy) const LinearProgressIndicator(),
          Expanded(child: _body()),
        ],
      ),
      floatingActionButton: selecting
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'subir',
                  tooltip: 'Subir archivos',
                  onPressed: _loading || _busy ? null : _pickAndUpload,
                  child: const Icon(Icons.upload_file),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'actualizar',
                  tooltip: 'Actualizar',
                  onPressed: _loading || _busy ? null : _reload,
                  child: const Icon(Icons.refresh),
                ),
              ],
            ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    }
    if (_files.isEmpty) {
      return const Center(child: Text('No hay archivos en el grupo.'));
    }
    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        final selected = _selected.contains(file.messageId);
        return ListTile(
          selected: selected,
          leading: _Leading(file: file),
          title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${_formatSize(file.size)} · ${_kindLabel(file.kind)} · '
              '${file.date.day}/${file.date.month}/${file.date.year}'
              '${file.encrypted ? ' · cifrado' : ''}'),
          trailing: selected ? const Icon(Icons.check_circle) : null,
          onTap: _selected.isEmpty ? null : () => _toggle(file),
          onLongPress: () => _toggle(file),
        );
      },
    );
  }

  static String _kindLabel(ChatFileKind kind) {
    switch (kind) {
      case ChatFileKind.photo:
        return 'Imagen';
      case ChatFileKind.video:
        return 'Video';
      case ChatFileKind.audio:
        return 'Audio';
      case ChatFileKind.document:
        return 'Archivo';
    }
  }

  static String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }
}

/// Miniatura diminuta de Telegram si existe; si no, un icono segun el tipo.
class _Leading extends StatelessWidget {
  const _Leading({required this.file});

  final ChatFile file;

  @override
  Widget build(BuildContext context) {
    final mini = file.minithumbnail;
    if (mini != null) {
      return SizedBox(
        width: 56,
        height: 56,
        child: Image.memory(mini, fit: BoxFit.cover, gaplessPlayback: true),
      );
    }
    final icon = switch (file.kind) {
      ChatFileKind.photo => Icons.image_outlined,
      ChatFileKind.video => Icons.movie_outlined,
      ChatFileKind.audio => Icons.audiotrack_outlined,
      ChatFileKind.document => Icons.insert_drive_file_outlined,
    };
    return SizedBox(width: 56, height: 56, child: Icon(icon));
  }
}
