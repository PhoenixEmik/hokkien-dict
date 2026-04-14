import 'dart:async';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taigi_dict/app/initialization/app_initialization_controller.dart';
import 'package:taigi_dict/app/initialization/app_initialization_screen.dart';
import 'package:taigi_dict/core/localization/app_localizations.dart';
import 'package:taigi_dict/features/bookmarks/application/bookmark_store.dart';
import 'package:taigi_dict/features/bookmarks/presentation/screens/bookmarks_screen.dart';
import 'package:taigi_dict/features/dictionary/data/dictionary_database_builder_service.dart';
import 'package:taigi_dict/features/dictionary/data/dictionary_repository.dart';
import 'package:taigi_dict/features/dictionary/data/offline_dictionary_library.dart';
import 'package:taigi_dict/features/dictionary/presentation/screens/dictionary_screen.dart';
import 'package:taigi_dict/features/settings/presentation/screens/settings_screen.dart';
import 'package:taigi_dict/features/settings/presentation/widgets/glass_notification.dart';
import 'package:taigi_dict/offline_audio.dart';
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

    showGlassNotification(context, message: message, isError: result.isError);
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

  AdaptiveAppBar? _buildRootAppBar(AppLocalizations l10n) {
    switch (_selectedIndex) {
      case 1:
        return AdaptiveAppBar(title: l10n.bookmarksTitle);
      case 2:
        return AdaptiveAppBar(title: l10n.settingsTitle);
      default:
        return null;
    }
  }

  List<AdaptiveNavigationDestination> _buildNavigationDestinations(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final isIOS26 = PlatformInfo.isIOS26OrHigher();
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIOS26) {
      return [
        AdaptiveNavigationDestination(
          icon: 'book',
          selectedIcon: 'book.fill',
          label: l10n.dictionaryTab,
        ),
        AdaptiveNavigationDestination(
          icon: 'bookmark',
          selectedIcon: 'bookmark.fill',
          label: l10n.bookmarksTab,
        ),
        AdaptiveNavigationDestination(
          icon: 'gearshape',
          selectedIcon: 'gearshape.fill',
          label: l10n.settingsTab,
        ),
      ];
    }

    if (isIOS) {
      return [
        AdaptiveNavigationDestination(
          icon: CupertinoIcons.book,
          selectedIcon: CupertinoIcons.book_fill,
          label: l10n.dictionaryTab,
        ),
        AdaptiveNavigationDestination(
          icon: CupertinoIcons.bookmark,
          selectedIcon: CupertinoIcons.bookmark_fill,
          label: l10n.bookmarksTab,
        ),
        AdaptiveNavigationDestination(
          icon: CupertinoIcons.settings,
          selectedIcon: CupertinoIcons.settings,
          label: l10n.settingsTab,
        ),
      ];
    }

    return [
      AdaptiveNavigationDestination(
        icon: Icons.menu_book,
        selectedIcon: Icons.menu_book,
        label: l10n.dictionaryTab,
      ),
      AdaptiveNavigationDestination(
        icon: Icons.bookmark_border,
        selectedIcon: Icons.bookmark,
        label: l10n.bookmarksTab,
      ),
      AdaptiveNavigationDestination(
        icon: Icons.settings,
        selectedIcon: Icons.settings,
        label: l10n.settingsTab,
      ),
    ];
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
            showOwnScaffold: false,
          ),
          SettingsScreen(
            audioLibrary: _audioLibrary,
            dictionaryLibrary: _dictionaryLibrary,
            onDownloadArchive: _handleArchiveDownloadAction,
            onDownloadDictionarySource: _handleDictionarySourceDownloadAction,
            onRebuildDictionaryDatabase: _rebuildDictionaryDatabase,
            showOwnScaffold: false,
          ),
        ];

        return AdaptiveScaffold(
          appBar: _buildRootAppBar(l10n),
          body: IndexedStack(index: _selectedIndex, children: screens),
          bottomNavigationBar: AdaptiveBottomNavigationBar(
            items: _buildNavigationDestinations(context, l10n),
            selectedIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}
