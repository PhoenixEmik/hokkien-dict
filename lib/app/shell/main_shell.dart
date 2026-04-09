import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';
import 'package:hokkien_dictionary/features/bookmarks/application/bookmark_store.dart';
import 'package:hokkien_dictionary/features/bookmarks/presentation/screens/bookmarks_screen.dart';
import 'package:hokkien_dictionary/features/dictionary/data/dictionary_repository.dart';
import 'package:hokkien_dictionary/features/dictionary/presentation/screens/dictionary_screen.dart';
import 'package:hokkien_dictionary/features/settings/presentation/screens/settings_screen.dart';
import 'package:hokkien_dictionary/offline_audio.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final DictionaryRepository _repository = DictionaryRepository();
  final OfflineAudioLibrary _audioLibrary = OfflineAudioLibrary();
  final BookmarkStore _bookmarkStore = BookmarkStore();

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_audioLibrary.initialize());
    unawaited(_bookmarkStore.initialize());
  }

  @override
  void dispose() {
    _bookmarkStore.dispose();
    _audioLibrary.dispose();
    super.dispose();
  }

  Future<void> _downloadArchive(AudioArchiveType type) async {
    final result = await _audioLibrary.downloadArchive(type);
    _showResult(result);
  }

  void _showResult(AudioActionResult result) {
    final message = result.message;
    if (!mounted || message == null || message.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: result.isError
              ? const Color(0xFF8A3B1F)
              : const Color(0xFF0E2F35),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screens = [
      DictionaryScreen(
        repository: _repository,
        audioLibrary: _audioLibrary,
        bookmarkStore: _bookmarkStore,
        onActionResult: _showResult,
      ),
      BookmarksScreen(
        repository: _repository,
        audioLibrary: _audioLibrary,
        bookmarkStore: _bookmarkStore,
        onActionResult: _showResult,
      ),
      SettingsScreen(
        audioLibrary: _audioLibrary,
        onDownloadArchive: _downloadArchive,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: l10n.dictionaryTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bookmark_border),
            selectedIcon: const Icon(Icons.bookmark),
            label: l10n.bookmarksTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settingsTab,
          ),
        ],
      ),
    );
  }
}
