import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/backup/backup_store.dart';
import '../../core/tdlib/cloud_index.dart';
import '../../core/tdlib/telegram_auth.dart';
import 'preview_page.dart';

/// Galeria del telefono, agrupada por dia. Si hay albumes elegidos para respaldo,
/// muestra solo esos con una insignia: nube si ya esta en la nube, reloj si falta.
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key, required this.auth, required this.chatId});

  final TelegramAuth auth;
  final int chatId;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  static const _pageSize = 1000;

  List<AssetEntity> _assets = [];
  /// IDs de fotos que de verdad estan en el grupo (segun las descripciones descifradas).
  Set<String> _cloudIds = {};
  Set<String> _backupIds = {};
  bool _loading = true;
  bool _denied = false;

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

  /// Vuelve a leer las fotos subidas cada vez que una termina, sin recargar la galeria.
  Future<void> _onBackupChanged() async {
    final cloud = await _loadCloudIds();
    if (mounted) setState(() => _cloudIds = cloud);
  }

  Future<void> _load() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      setState(() {
        _denied = true;
        _loading = false;
      });
      return;
    }
    final selected = await BackupStore.selectedAlbumIds();
    final cloud = await _loadCloudIds();

    // Siempre se muestra todo el contenido del telefono.
    // Android ordena por fecha de creacion desde el inicio: lo mas nuevo primero.
    final all = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
      filterOption: FilterOptionGroup(
        orders: [OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );
    // Se leen todas las paginas, no solo la primera.
    final assets = <AssetEntity>[];
    if (all.isNotEmpty) {
      var page = 0;
      while (true) {
        final batch = await all.first.getAssetListPaged(page: page, size: _pageSize);
        assets.addAll(batch);
        if (batch.length < _pageSize) break;
        page++;
      }
    }
    assets.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

    // Solo los albumes elegidos en Ajustes reciben estado de respaldo.
    final backupIds = <String>{};
    if (selected.isNotEmpty) {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        onlyAll: false,
      );
      for (final album in albums.where((a) => selected.contains(a.id))) {
        final count = await album.assetCountAsync;
        for (final asset in await album.getAssetListRange(
          start: 0,
          end: count,
        )) {
          backupIds.add(asset.id);
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _assets = assets;
      _cloudIds = cloud;
      _backupIds = backupIds;
      _loading = false;
    });
  }

  /// Lee el grupo y devuelve los IDs de telefono de los archivos que estan ahi.
  /// Si no hay frase o falla la lectura, no marca nada como nube.
  Future<Set<String>> _loadCloudIds() async {
    return CloudIndex.current(widget.auth, widget.chatId);
  }

  Map<String, List<AssetEntity>> _groupByDay() {
    final groups = <String, List<AssetEntity>>{};
    for (final asset in _assets) {
      final date = asset.createDateTime;
      final key = '${date.year}-${_two(date.month)}-${_two(date.day)}';
      groups.putIfAbsent(key, () => []).add(asset);
    }
    return groups;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_denied) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Necesito permiso para ver tus fotos y videos. '
            'Activalo en Ajustes del telefono y vuelve a abrir la app.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_assets.isEmpty) {
      return const Center(child: Text('No hay fotos ni videos para mostrar.'));
    }

    final groups = _groupByDay();
    final days = groups.keys.toList();

    return CustomScrollView(
      slivers: [
        for (final day in days) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                _formatDay(day),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final asset = groups[day]![index];
                return _Thumb(
                  asset: asset,
                  onOpen: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PreviewPage(
                        assets: _assets,
                        index: _assets.indexOf(asset),
                      ),
                    ),
                  ),
                  // Solo se marca el estado cuando el album esta elegido para respaldo.
                  backupState: !_backupIds.contains(asset.id)
                      ? null
                      : _cloudIds.contains(asset.id)
                      ? _BackupState.inCloud
                      : _BackupState.pending,
                );
              }, childCount: groups[day]!.length),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  static String _formatDay(String key) {
    final parts = key.split('-');
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }
}

enum _BackupState { inCloud, pending }

class _Thumb extends StatefulWidget {
  const _Thumb({required this.asset, required this.onOpen, this.backupState});

  final AssetEntity asset;
  final VoidCallback onOpen;
  final _BackupState? backupState;

  @override
  State<_Thumb> createState() => _ThumbState();
}

class _ThumbState extends State<_Thumb> {
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
              if (bytes == null) {
                return const ColoredBox(color: Color(0xFFE0E0E0));
              }
              return Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              );
            },
          ),
          if (widget.asset.type == AssetType.video)
            const Positioned(
              right: 4,
              bottom: 4,
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 18,
              ),
            ),
          if (state != null)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: state == _BackupState.inCloud
                      ? const Color(0xFF1E88E5)
                      : Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  state == _BackupState.inCloud
                      ? Icons.cloud_done
                      : Icons.schedule,
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
