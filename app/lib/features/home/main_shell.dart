import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../core/backup/backup_runner.dart';
import '../../core/tdlib/telegram_auth.dart';
import '../drive/archivos_page.dart';
import '../gallery/albums_page.dart';
import '../gallery/nube_page.dart';
import '../gallery/gallery_page.dart';
import '../settings/settings_page.dart';

/// Navegacion principal: Fotos, Albumes, Drive y Ajustes.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.auth, required this.chatId});

  final TelegramAuth auth;
  final int chatId;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;
  StreamSubscription<List<ConnectivityResult>>? _network;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Sube solo al abrir, al reanudar la app y cuando vuelve una red permitida.
    _network = Connectivity().onConnectivityChanged.listen((_) => _autoBackup());
    _autoBackup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _network?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _autoBackup();
  }

  void _autoBackup() {
    BackupRunner.runIfAllowed(auth: widget.auth, chatId: widget.chatId);
  }

  /// Cambia cada vez que abres Fotos, para que la galeria vuelva a leer los albumes elegidos.
  int _galleryVersion = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          if (_index == 0)
            IconButton(
              tooltip: 'Nube',
              icon: const Icon(Icons.cloud_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NubePage(auth: widget.auth, chatId: widget.chatId),
                ),
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          GalleryPage(
            key: ValueKey(_galleryVersion),
            auth: widget.auth,
            chatId: widget.chatId,
          ),
          AlbumsPage(auth: widget.auth, chatId: widget.chatId),
          ArchivosPage(auth: widget.auth, chatId: widget.chatId),
          SettingsPage(auth: widget.auth),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() {
          _index = value;
          if (value == 0) _galleryVersion++;
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined, color: Color(0xFFE91E63)),
            selectedIcon: Icon(Icons.photo_library, color: Color(0xFFE91E63)),
            label: 'Fotos',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_outlined, color: Color(0xFF00BFA5)),
            selectedIcon: Icon(Icons.collections, color: Color(0xFF00BFA5)),
            label: 'Albumes',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined, color: Color(0xFFFF9100)),
            selectedIcon: Icon(Icons.folder, color: Color(0xFFFF9100)),
            label: 'Drive',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: Color(0xFF7C4DFF)),
            selectedIcon: Icon(Icons.settings, color: Color(0xFF7C4DFF)),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  static const _titles = ['Fotos', 'Albumes', 'Drive', 'Ajustes'];
}

