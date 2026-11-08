import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/backup/backup_store.dart';
import '../../core/tdlib/cloud_index.dart';
import '../../core/tdlib/telegram_auth.dart';
import 'album_detail_page.dart';

/// Lista de todos los albumes del telefono, con portada, cantidad y cuantas de sus fotos estan en el grupo.
class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key, required this.auth, required this.chatId});

  final TelegramAuth auth;
  final int chatId;

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  List<_AlbumInfo> _albums = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    // Cada subida que termina vuelve a leer el estado de los albumes.
    BackupStore.changes.addListener(_load);
  }

  @override
  void dispose() {
    BackupStore.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final selected = await BackupStore.selectedAlbumIds();
    final cloud = await _cloudIds();
    final paths = await PhotoManager.getAssetPathList(type: RequestType.common, onlyAll: false);
    final infos = <_AlbumInfo>[];
    for (final path in paths) {
      final count = await path.assetCountAsync;
      if (count == 0) continue;
      final assets = await path.getAssetListRange(start: 0, end: count);
      infos.add(_AlbumInfo(
        path: path,
        count: count,
        cover: assets.isEmpty ? null : assets.first,
        inGroup: assets.where((asset) => cloud.contains(asset.id)).length,
        backup: selected.contains(path.id),
      ));
    }
    infos.sort((a, b) => b.count.compareTo(a.count));
    if (!mounted) return;
    setState(() {
      _albums = infos;
      _loading = false;
    });
  }

  /// IDs de telefono de lo que esta en el grupo. Si no hay frase o falla, no marca nada.
  Future<Set<String>> _cloudIds() async {
    return CloudIndex.current(widget.auth, widget.chatId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Actualizar',
        onPressed: _loading ? null : _load,
        child: const Icon(Icons.refresh),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _albums.isEmpty
              ? const Center(child: Text('No hay albumes para mostrar.'))
              : ListView.builder(
                  itemCount: _albums.length,
                  itemBuilder: (context, index) {
                    final info = _albums[index];
                    return ListTile(
                      leading: _Cover(asset: info.cover),
                      title: Text(info.path.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${info.count} elementos · ${info.status}'),
                      trailing: Icon(info.icon, color: info.color),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AlbumDetailPage(
                            album: info.path,
                            backupSelected: info.backup,
                            auth: widget.auth,
                            chatId: widget.chatId,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _AlbumInfo {
  _AlbumInfo({
    required this.path,
    required this.count,
    this.cover,
    required this.inGroup,
    required this.backup,
  });

  final AssetPathEntity path;
  final int count;
  final AssetEntity? cover;

  /// Cuantas fotos de este album estan en el grupo.
  final int inGroup;

  /// True si el album esta elegido para respaldo en Ajustes.
  final bool backup;

  String get status {
    if (inGroup == 0) return 'Sin respaldo';
    if (inGroup == count) return 'En el grupo: todas';
    return 'En el grupo: $inGroup de $count';
  }

  IconData get icon {
    if (inGroup == 0) return Icons.cloud_off_outlined;
    if (inGroup == count) return Icons.cloud_done;
    return Icons.cloud_sync_outlined;
  }

  Color get color {
    if (inGroup == 0) return Colors.grey;
    if (inGroup == count) return const Color(0xFF1E88E5);
    return Colors.orange;
  }
}

class _Cover extends StatelessWidget {
  const _Cover({this.asset});

  final AssetEntity? asset;

  @override
  Widget build(BuildContext context) {
    final cover = asset;
    if (cover == null) {
      return const SizedBox(width: 56, height: 56, child: Icon(Icons.photo_album_outlined));
    }
    return SizedBox(
      width: 56,
      height: 56,
      child: FutureBuilder<Uint8List?>(
        future: cover.thumbnailDataWithSize(const ThumbnailSize.square(120)),
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes == null) return const ColoredBox(color: Color(0xFFE0E0E0));
          return Image.memory(bytes, fit: BoxFit.cover);
        },
      ),
    );
  }
}
