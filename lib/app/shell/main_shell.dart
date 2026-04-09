import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/app/initialization/app_initialization_controller.dart';
import 'package:hokkien_dictionary/app/initialization/app_initialization_screen.dart';
import 'package:hokkien_dictionary/core/localization/app_localizations.dart';
import 'package:hokkien_dictionary/features/bookmarks/application/bookmark_store.dart';
import 'package:hokkien_dictionary/features/bookmarks/presentation/screens/bookmarks_screen.dart';
import 'package:hokkien_dictionary/features/dictionary/data/dictionary_database_builder_service.dart';
import 'package:hokkien_dictionary/features/dictionary/data/dictionary_repository.dart';
import 'package:hokkien_dictionary/features/dictionary/data/offline_dictionary_library.dart';
import 'package:hokkien_dictionary/features/dictionary/presentation/screens/dictionary_screen.dart';
import 'package:hokkien_dictionary/features/settings/presentation/screens/settings_screen.dart';
import 'package:hokkien_dictionary/features/settings/presentation/widgets/liquid_glass.dart';
import 'package:hokkien_dictionary/offline_audio.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:shared_preferences/shared_preferences.dart';

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
  late final AppInitializationController _initializationController =
      AppInitializationController(
        builderService: _dictionaryDatabaseBuilderService,
        dictionaryLibrary: _dictionaryLibrary,
      );

  int _selectedIndex = 0;
  bool _startupRequested = false;

  @override
  void initState() {
    super.initState();
    unawaited(_audioLibrary.initialize());
    unawaited(_bookmarkStore.initialize());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startupRequested) {
      return;
    }
    _startupRequested = true;
    unawaited(_startInitialization());
  }

  @override
  void dispose() {
    _initializationController.dispose();
    _bookmarkStore.dispose();
    _dictionaryLibrary.dispose();
    _audioLibrary.dispose();
    super.dispose();
  }

  Future<void> _startInitialization() async {
    try {
      await _initializationController.initialize(AppLocalizations.of(context));
    } catch (_) {
      // The blocking startup screen reads the controller error state directly.
    }
  }

  Future<void> _retryInitialization() async {
    try {
      await _initializationController.retry(AppLocalizations.of(context));
    } catch (_) {
      // The blocking startup screen reads the controller error state directly.
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

    final snapshot = _dictionaryLibrary.downloadSnapshot;
    if (result.isError ||
        _dictionaryLibrary.downloadState != DownloadState.completed ||
        !_dictionaryLibrary.isSourceReady ||
        snapshot.totalBytes <= 0 ||
        snapshot.downloadedBytes != snapshot.totalBytes) {
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
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(
      AppInitializationController.databaseReadyPreferenceKey,
      true,
    );
    DictionaryRepository.clearBundleCache();
    if (!mounted) {
      return;
    }
    setState(() {});
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
    if (error is CorruptedDictionarySourceException) {
      return l10n.dictionarySourceCorrupted;
    }
    if (error is MissingDictionarySheetException) {
      return l10n.dictionarySourceSheetMissing(error.sheetName);
    }
    return l10n.dictionaryDatabaseRebuildFailed('$error');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bypassInitialization =
        !DictionaryRepository.preferLocalDatabase &&
        DictionaryRepository.hasDebugFallbackBundle;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _initializationController,
        _dictionaryLibrary,
      ]),
      builder: (context, child) {
        if (!_initializationController.isReady && !bypassInitialization) {
          return AppInitializationScreen(
            controller: _initializationController,
            dictionaryLibrary: _dictionaryLibrary,
            onRetry: _retryInitialization,
          );
        }

        final screens = [
          DictionaryScreen(
            key: ValueKey(
              'dictionary-${_initializationController.databaseGeneration}',
            ),
            repository: _repository,
            audioLibrary: _audioLibrary,
            bookmarkStore: _bookmarkStore,
            onActionResult: _showResult,
          ),
          BookmarksScreen(
            key: ValueKey(
              'bookmarks-${_initializationController.databaseGeneration}',
            ),
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

        if (isApplePlatform(context)) {
          return Scaffold(
            body: IndexedStack(index: _selectedIndex, children: screens),
            bottomNavigationBar: glass.GlassBottomBar(
              selectedIndex: _selectedIndex,
              onTabSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              quality: glass.GlassQuality.premium,
              selectedIconColor: resolveLiquidGlassForeground(context),
              unselectedIconColor: resolveLiquidGlassSecondaryForeground(
                context,
              ),
              indicatorColor: resolveLiquidGlassTint(
                context,
              ).withValues(alpha: 0.20),
              tabs: [
                glass.GlassBottomBarTab(
                  label: l10n.dictionaryTab,
                  icon: const Icon(CupertinoIcons.book),
                  activeIcon: const Icon(CupertinoIcons.book_fill),
                  glowColor: resolveLiquidGlassTint(context),
                ),
                glass.GlassBottomBarTab(
                  label: l10n.bookmarksTab,
                  icon: const Icon(CupertinoIcons.bookmark),
                  activeIcon: const Icon(CupertinoIcons.bookmark_fill),
                  glowColor: resolveLiquidGlassTint(context),
                ),
                glass.GlassBottomBarTab(
                  label: l10n.settingsTab,
                  icon: const Icon(CupertinoIcons.gear),
                  activeIcon: const Icon(CupertinoIcons.gear_solid),
                  glowColor: resolveLiquidGlassTint(context),
                ),
              ],
            ),
          );
        }

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
      },
    );
  }
}
