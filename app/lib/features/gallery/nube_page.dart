import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../core/crypto/vault_cipher.dart';
import '../../core/settings/passphrase_store.dart';
import '../../core/tdlib/chat_files.dart';
import '../../core/tdlib/telegram_auth.dart';

/// Archivos que estan en el supergrupo pero no en este telefono.
class NubePage extends StatefulWidget {
  const NubePage({super.key, required this.auth, required this.chatId});

  final TelegramAuth auth;
  final int chatId;

  @override
  State<NubePage> createState() => _NubePageState();
}

class _NubePageState extends State<NubePage> {
  List<ChatFile> _cloudOnly = [];
  int _verified = 0;
  bool _loading = true;
  String? _error;

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
          _error = 'Configura la frase maestra en Ajustes para ver la nube.';
          _loading = false;
        });
        return;
      }
      final files = (await ChatFiles(auth: widget.auth, chatId: widget.chatId)
              .load(passphrase: passphrase))
          .where((file) => file.encrypted)
          .toList();
      final local = await _localIndex();
      final cloudOnly = <ChatFile>[];
      var verified = 0;
      for (final file in files) {
        var assetId = file.assetId;
        if (assetId == null) {
          assetId = await _findLocalMatch(file, local.byTitle);
          if (assetId != null) await ChatFiles.saveAssetMatch(file.messageId, assetId);
        }
        if (assetId != null && local.ids.contains(assetId)) {
          verified++;
        } else {
          cloudOnly.add(file);
        }
      }
      if (!mounted) return;
      setState(() {
        _cloudOnly = cloudOnly;
        _verified = verified;
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

  /// Todas las fotos y videos del telefono: IDs, y agrupados por nombre.
  Future<({Set<String> ids, Map<String, List<AssetEntity>> byTitle})> _localIndex() async {
    final ids = <String>{};
    final byTitle = <String, List<AssetEntity>>{};
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
    );
    if (paths.isEmpty) return (ids: ids, byTitle: byTitle);
    var page = 0;
    while (true) {
      final batch = await paths.first.getAssetListPaged(page: page, size: 200);
      for (final asset in batch) {
        ids.add(asset.id);
        byTitle.putIfAbsent(asset.title ?? '', () => []).add(asset);
      }
      if (batch.length < 200) break;
      page++;
    }
    return (ids: ids, byTitle: byTitle);
  }

  /// Busca en el telefono un archivo con el mismo nombre y tamano. Si el archivo tiene hash
  /// SHA-256 guardado (subidas nuevas), tambien debe coincidir; las subidas antiguas no lo tienen.
  Future<String?> _findLocalMatch(ChatFile file, Map<String, List<AssetEntity>> byTitle) async {
    final plainSize = file.plainSize;
    if (plainSize == null) return null;
    final hash = file.sha256;
    for (final asset in byTitle[file.name] ?? const <AssetEntity>[]) {
      final local = await asset.originFile;
      if (local == null || await local.length() != plainSize) continue;
      if (hash == null) return asset.id;
      final digest = await sha256.bind(local.openRead()).first;
      if (digest.toString() == hash) return asset.id;
    }
    return null;
  }

  void _open(ChatFile file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CloudViewerPage(auth: widget.auth, chatId: widget.chatId, file: file),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nube')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : ListView(
                  children: [
                    _section('Solo en la nube (${_cloudOnly.length})'),
                    if (_cloudOnly.isEmpty)
                      const ListTile(title: Text('No hay archivos que falten en el telefono.')),
                    for (final file in _cloudOnly) _tile(file),
                    ListTile(title: Text('Ya estan en el telefono y en la nube: $_verified')),
                  ],
                ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }

  Widget _tile(ChatFile file) {
    return ListTile(
      leading: Icon(_iconFor(file.kind)),
      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${_formatSize(file.size)} · ${file.date.day}/${file.date.month}/${file.date.year}'),
      trailing: const Icon(Icons.cloud_outlined),
      onTap: () => _open(file),
    );
  }

  static IconData _iconFor(ChatFileKind kind) {
    switch (kind) {
      case ChatFileKind.photo:
        return Icons.image_outlined;
      case ChatFileKind.video:
        return Icons.movie_outlined;
      case ChatFileKind.audio:
        return Icons.audiotrack_outlined;
      case ChatFileKind.document:
        return Icons.insert_drive_file_outlined;
    }
  }

  static String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }
}

/// Descarga un archivo de la nube y lo muestra. Las fotos se ven directas; los videos se reproducen.
class CloudViewerPage extends StatefulWidget {
  const CloudViewerPage({super.key, required this.auth, required this.chatId, required this.file});

  final TelegramAuth auth;
  final int chatId;
  final ChatFile file;

  @override
  State<CloudViewerPage> createState() => _CloudViewerPageState();
}

class _CloudViewerPageState extends State<CloudViewerPage> {
  String? _path;
  VideoPlayerController? _video;
  String? _error;

  @override
  void initState() {
    super.initState();
    _download();
  }

  Future<void> _download() async {
    final fileId = widget.file.fileId;
    if (fileId == null) {
      setState(() => _error = 'No hay archivo para descargar.');
      return;
    }
    try {
      final downloaded = await ChatFiles(auth: widget.auth, chatId: widget.chatId).download(fileId);
      if (downloaded == null) {
        setState(() => _error = 'No se pudo descargar.');
        return;
      }
      final path = widget.file.encrypted ? await _decryptToTemp(downloaded) : downloaded;
      if (widget.file.kind == ChatFileKind.video) {
        final controller = VideoPlayerController.file(File(path));
        await controller.initialize();
        await controller.play();
        if (!mounted) {
          await controller.dispose();
          return;
        }
        setState(() => _video = controller);
      }
      if (mounted) setState(() => _path = path);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  /// Descifra el archivo descargado (copia cifrada del grupo) a un temporal y devuelve su ruta.
  Future<String> _decryptToTemp(String encryptedPath) async {
    final passphrase = await PassphraseStore.read();
    if (passphrase == null) throw StateError('Configura la frase maestra en Ajustes.');
    final dir = await getTemporaryDirectory();
    final safeName = widget.file.name.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final out = File('${dir.path}/${widget.file.messageId}_$safeName');
    final sink = out.openWrite();
    await sink.addStream(VaultCipher.decrypt(File(encryptedPath).openRead(), passphrase));
    await sink.close();
    return out.path;
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: _error != null
            ? Text(_error!, style: const TextStyle(color: Colors.white))
            : path == null
                ? const CircularProgressIndicator(color: Colors.white)
                : widget.file.kind == ChatFileKind.photo
                    ? InteractiveViewer(child: Image.file(File(path), fit: BoxFit.contain))
                    : widget.file.kind == ChatFileKind.video && _video != null
                        ? GestureDetector(
                            onTap: () {
                              final video = _video!;
                              video.value.isPlaying ? video.pause() : video.play();
                              setState(() {});
                            },
                            child: AspectRatio(
                              aspectRatio: _video!.value.aspectRatio,
                              child: VideoPlayer(_video!),
                            ),
                          )
                        : Text(
                            'Descargado en:\n$path',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
      ),
    );
  }
}
