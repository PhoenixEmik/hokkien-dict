import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';
import 'package:hokkien_dictionary/features/bookmarks/application/bookmark_store.dart';
import 'package:hokkien_dictionary/features/bookmarks/presentation/screens/bookmarks_screen.dart';
import 'package:hokkien_dictionary/features/dictionary/data/dictionary_database_builder_service.dart';
import 'package:hokkien_dictionary/features/dictionary/data/offline_dictionary_library.dart';
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
  final DictionaryDatabaseBuilderService _dictionaryDatabaseBuilderService =
      const DictionaryDatabaseBuilderService();
  final OfflineDictionaryLibrary _dictionaryLibrary =
      OfflineDictionaryLibrary();
  final OfflineAudioLibrary _audioLibrary = OfflineAudioLibrary();
  final BookmarkStore _bookmarkStore = BookmarkStore();

  int _selectedIndex = 0;
  int _dictionaryDataVersion = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeDictionaryResources());
    unawaited(_audioLibrary.initialize());
    unawaited(_bookmarkStore.initialize());
  }

  @override
  void dispose() {
    _bookmarkStore.dispose();
    _dictionaryLibrary.dispose();
    _audioLibrary.dispose();
    super.dispose();
  }

  Future<void> _initializeDictionaryResources() async {
    await _dictionaryLibrary.initialize();
    final needsRebuild = await _dictionaryDatabaseBuilderService.needsRebuild();
    if (!needsRebuild) {
      return;
    }

    try {
      await _rebuildDictionaryDatabaseInternal();
    } catch (_) {
      // Leave the explicit rebuild action in Settings as the recovery path.
    }
  }

  Future<void> _handleArchiveDownloadAction(AudioArchiveType type) async {
    final l10n = AppLocalizations.of(context);
    final result = await _audioLibrary.handleDownloadAction(type, l10n);
    _showResult(result);
  }

  Future<void> _handleDictionarySourceDownloadAction() async {
    final l10n = AppLocalizations.of(context);
    final result = await _dictionaryLibrary.handleDownloadAction(l10n);
    _showResult(result);

    if (result.isError ||
        _dictionaryLibrary.downloadState != DownloadState.completed) {
      return;
    }

    try {
      await _rebuildDictionaryDatabaseInternal();
      _showResult(AudioActionResult(message: l10n.dictionaryDatabaseRebuilt));
    } catch (error) {
      _showResult(
        AudioActionResult(
          message: _describeDatabaseRebuildError(error, l10n),
          isError: true,
        ),
      );
    }
  }

  Future<void> _rebuildDictionaryDatabase() async {
    await _rebuildDictionaryDatabaseInternal();
  }

  Future<void> _rebuildDictionaryDatabaseInternal() async {
    await _dictionaryDatabaseBuilderService.rebuildFromDownloadedOds();
    DictionaryRepository.clearBundleCache();
    if (!mounted) {
      return;
    }
    setState(() {
      _dictionaryDataVersion++;
    });
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

  String _describeDatabaseRebuildError(Object error, AppLocalizations l10n) {
    if (error is MissingDictionarySourceException) {
      return l10n.downloadDictionarySourceFirst;
    }
    if (error is MissingDictionarySheetException) {
      return l10n.dictionarySourceSheetMissing(error.sheetName);
    }
    return l10n.dictionaryDatabaseRebuildFailed('$error');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screens = [
      DictionaryScreen(
        key: ValueKey('dictionary-$_dictionaryDataVersion'),
        repository: _repository,
        audioLibrary: _audioLibrary,
        bookmarkStore: _bookmarkStore,
        onActionResult: _showResult,
      ),
      BookmarksScreen(
        key: ValueKey('bookmarks-$_dictionaryDataVersion'),
        repository: _repository,
        audioLibrary: _audioLibrary,
        bookmarkStore: _bookmarkStore,
        onActionResult: _showResult,
      ),
      SettingsScreen(
        audioLibrary: _audioLibrary,
        dictionaryLibrary: _dictionaryLibrary,
        onDownloadArchive: _handleArchiveDownloadAction,
        onDownloadDictionarySource: _handleDictionarySourceDownloadAction,
        onRebuildDictionaryDatabase: _rebuildDictionaryDatabase,
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
