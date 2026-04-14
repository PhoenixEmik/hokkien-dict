import 'dart:async';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taigi_dict/app/app_module.dart';
import 'package:taigi_dict/core/core.dart';
import 'package:taigi_dict/features/audio/audio.dart';
import 'package:taigi_dict/features/bookmarks/bookmarks.dart';
import 'package:taigi_dict/features/dictionary/dictionary.dart';
import 'package:taigi_dict/features/settings/settings.dart';


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
  int? _cachedScreenGeneration;
  List<Widget>? _cachedScreens;
  bool _startupRequested = false;
  bool _startupGateResolved = false;
  bool _shouldBlockInitialization = true;

  @override
  void initState() {
    super.initState();
    unawaited(_audioLibrary.initialize());
    unawaited(_bookmarkStore.initialize());
    unawaited(_prepareStartupGate());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startupRequested || !_startupGateResolved) {
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

  Future<void> _prepareStartupGate() async {
    final preferences = await SharedPreferences.getInstance();
    final readyFlag =
        preferences.getBool(
          AppInitializationController.databaseReadyPreferenceKey,
        ) ??
        false;
    final hasDatabase = await _dictionaryDatabaseBuilderService
        .hasBuiltDatabase();

    if (!mounted) {
      return;
    }

    setState(() {
      _shouldBlockInitialization = !readyFlag || !hasDatabase;
      _startupGateResolved = true;
    });

    if (!_startupRequested) {
      _startupRequested = true;
      unawaited(_startInitialization());
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

    showAppNotification(context, message: message, isError: result.isError);
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

  List<Widget> _buildTabScreens() {
    final generation = _initializationController.databaseGeneration;
    if (_cachedScreens != null && _cachedScreenGeneration == generation) {
      return _cachedScreens!;
    }

    _cachedScreenGeneration = generation;
    _cachedScreens = [
      DictionaryScreen(
        key: ValueKey('dictionary-$generation'),
        repository: _repository,
        audioLibrary: _audioLibrary,
        bookmarkStore: _bookmarkStore,
        onActionResult: _showResult,
        showOwnScaffold: true,
      ),
      BookmarksScreen(
        key: ValueKey('bookmarks-$generation'),
        repository: _repository,
        audioLibrary: _audioLibrary,
        bookmarkStore: _bookmarkStore,
        onActionResult: _showResult,
        showOwnScaffold: true,
      ),
      SettingsScreen(
        audioLibrary: _audioLibrary,
        dictionaryLibrary: _dictionaryLibrary,
        onDownloadArchive: _handleArchiveDownloadAction,
        onDownloadDictionarySource: _handleDictionarySourceDownloadAction,
        onRebuildDictionaryDatabase: _rebuildDictionaryDatabase,
        showOwnScaffold: true,
      ),
    ];
    return _cachedScreens!;
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
        if (!_startupGateResolved && !bypassInitialization) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const SizedBox.expand(),
          );
        }

        if (_shouldBlockInitialization &&
            !_initializationController.isReady &&
            !bypassInitialization) {
          return AppInitializationScreen(
            controller: _initializationController,
            dictionaryLibrary: _dictionaryLibrary,
            onRetry: _retryInitialization,
          );
        }

        final screens = _buildTabScreens();

        return AdaptiveScaffold(
          extendBodyBehindAppBar: false,
          minimizeBehavior: TabBarMinimizeBehavior.never,
          useHeroBackButton: false,
          body: IndexedStack(index: _selectedIndex, children: screens),
          bottomNavigationBar: AdaptiveBottomNavigationBar(
            useNativeBottomBar: true,
            selectedIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: [
              AdaptiveNavigationDestination(
                icon: PlatformInfo.isIOS ? 'book.fill' : Icons.menu_book,
                selectedIcon:
                    PlatformInfo.isIOS ? 'book.fill' : Icons.menu_book,
                label: l10n.dictionaryTab,
              ),
              AdaptiveNavigationDestination(
                icon: PlatformInfo.isIOS ? 'bookmark.fill' : Icons.bookmark,
                selectedIcon:
                    PlatformInfo.isIOS ? 'bookmark.fill' : Icons.bookmark,
                label: l10n.bookmarksTab,
              ),
              AdaptiveNavigationDestination(
                icon: PlatformInfo.isIOS
                    ? 'gearshape'
                    : Icons.settings_outlined,
                selectedIcon:
                    PlatformInfo.isIOS ? 'gearshape.fill' : Icons.settings,
                label: l10n.settingsTab,
              ),
            ],
          ),
        );
      },
    );
  }
}
