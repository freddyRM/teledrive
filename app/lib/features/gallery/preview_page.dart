import 'dart:typed_data';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

/// Previsualizador a pantalla completa. Se desliza entre todas las fotos de la galeria.
class PreviewPage extends StatefulWidget {
  const PreviewPage({super.key, required this.assets, required this.index});

  final List<AssetEntity> assets;
  final int index;

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  late final PageController _controller = PageController(initialPage: widget.index);
  late int _current = widget.index;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.assets[_current];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          asset.title ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('${_current + 1} / ${widget.assets.length}'),
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.assets.length,
        onPageChanged: (value) => setState(() => _current = value),
        itemBuilder: (context, index) => _Page(asset: widget.assets[index]),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.asset});

  final AssetEntity asset;

  @override
  Widget build(BuildContext context) {
    if (asset.type == AssetType.video) {
      return _VideoPage(asset: asset);
    }
    return FutureBuilder<Uint8List?>(
      future: asset.originBytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        return InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
        );
      },
    );
  }
}

/// Reproductor de video: toca la pantalla para pausar o reanudar.
class _VideoPage extends StatefulWidget {
  const _VideoPage({required this.asset});

  final AssetEntity asset;

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final File? file = await widget.asset.originFile;
    if (file == null) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);
    await controller.play();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed) {
      return const Center(
        child: Text('No se pudo abrir el video.', style: TextStyle(color: Colors.white)),
      );
    }
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return GestureDetector(
      onTap: () {
        controller.value.isPlaying ? controller.pause() : controller.play();
        setState(() {});
      },
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
