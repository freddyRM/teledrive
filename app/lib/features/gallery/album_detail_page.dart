import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/backup/backup_store.dart';
import '../../core/tdlib/cloud_index.dart';
import '../../core/tdlib/telegram_auth.dart';
import 'preview_page.dart';

/// Contenido de un album del telefono: cuadricula, insignias segun el grupo y previsualizador.
class AlbumDetailPage extends StatefulWidget {
  const AlbumDetailPage({
    super.key,
    required this.album,
    required this.backupSelected,
    required this.auth,
    required this.chatId,
  });

  final AssetPathEntity album;
  final bool backupSelected;
  final TelegramAuth auth;
  final int chatId;

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  static const _pageSize = 200;

  List<AssetEntity> _assets = [];
  Set<String> _inGroup = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    BackupStore.changes.addListener(_onBackupChanged);
  }

  @override
  void dispose() {
    BackupStore.changes.removeListener(_onBackupChanged);
    super.dispose();
  }

  /// Actualiza las insignias cada vez que una foto termina de subirse.
  Future<void> _onBackupChanged() async {
    final inGroup = await _cloudIds();
    if (mounted) setState(() => _inGroup = inGroup);
  }

  Future<void> _load() async {
    final inGroup = await _cloudIds();
    final assets = <AssetEntity>[];
    var page = 0;
    while (true) {
      final batch = await widget.album.getAssetListPaged(page: page, size: _pageSize);
      assets.addAll(batch);
      if (batch.length < _pageSize) break;
      page++;
    }
    if (!mounted) return;
    setState(() {
      _assets = assets;
      _inGroup = inGroup;
      _loading = false;
    });
  }

  /// IDs de telefono de lo que esta en el grupo. Si no hay frase o falla, no marca nada.
  Future<Set<String>> _cloudIds() async {
    return CloudIndex.current(widget.auth, widget.chatId);
  }

  /// Nube si la foto esta en el grupo; reloj si el album esta elegido y falta; nada si no aplica.
  bool? _stateFor(AssetEntity asset) {
    if (_inGroup.contains(asset.id)) return true;
    return widget.backupSelected ? false : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.album.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assets.isEmpty
              ? const Center(child: Text('Este album esta vacio.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(2),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: _assets.length,
                  itemBuilder: (context, index) {
                    final asset = _assets[index];
                    return _AlbumThumb(
                      asset: asset,
                      backupState: _stateFor(asset),
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PreviewPage(assets: _assets, index: index),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

/// Miniatura con insignia: nube si ya esta en la nube, reloj si esta pendiente, nada si no aplica.
class _AlbumThumb extends StatefulWidget {
  const _AlbumThumb({required this.asset, required this.onOpen, this.backupState});

  final AssetEntity asset;
  final VoidCallback onOpen;
  final bool? backupState;

  @override
  State<_AlbumThumb> createState() => _AlbumThumbState();
}

class _AlbumThumbState extends State<_AlbumThumb> {
  late final Future<Uint8List?> _thumbnail = widget.asset.thumbnailDataWithSize(
    const ThumbnailSize.square(200),
  );

  @override
  Widget build(BuildContext context) {
    final state = widget.backupState;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: GestureDetector(
      onTap: widget.onOpen,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<Uint8List?>(
            future: _thumbnail,
            builder: (context, snapshot) {
              final bytes = snapshot.data;
              if (bytes == null) return const ColoredBox(color: Color(0xFFE0E0E0));
              return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
            },
          ),
          if (widget.asset.type == AssetType.video)
            const Positioned(
              right: 4,
              bottom: 4,
              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 18),
            ),
          if (state != null)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: state ? const Color(0xFF1E88E5) : Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  state ? Icons.cloud_done : Icons.schedule,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}
