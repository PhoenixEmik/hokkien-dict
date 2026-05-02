import 'dart:async';
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
  static const _initializationScreenDelay = Duration(milliseconds: 180);

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
  bool _showInitializationScreen = false;
  Timer? _initializationScreenTimer;

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
    _scheduleInitializationScreen();
    unawaited(_startInitialization());
  }

  @override
  void dispose() {
    _initializationScreenTimer?.cancel();
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
    } finally {
      if (mounted &&
          _initializationController.isReady &&
          _showInitializationScreen) {
        setState(() {
          _showInitializationScreen = false;
        });
      }
    }
  }

  Future<void> _retryInitialization() async {
    _scheduleInitializationScreen(forceVisible: true);
    try {
      await _initializationController.retry(AppLocalizations.of(context));
    } catch (_) {
      // The blocking startup screen reads the controller error state directly.
    } finally {
      if (mounted &&
          _initializationController.isReady &&
          _showInitializationScreen) {
        setState(() {
          _showInitializationScreen = false;
        });
      }
    }
  }

  void _scheduleInitializationScreen({bool forceVisible = false}) {
    _initializationScreenTimer?.cancel();

    if (forceVisible) {
      if (_showInitializationScreen) {
        return;
      }
      setState(() {
        _showInitializationScreen = true;
      });
      return;
    }

    _showInitializationScreen = false;
    _initializationScreenTimer = Timer(_initializationScreenDelay, () {
      if (!mounted || _initializationController.isReady || _showInitializationScreen) {
        return;
      }
      setState(() {
        _showInitializationScreen = true;
      });
    });
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

    showAppNotification(
      context,
      message: message,
      isError: result.isError,
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
        if (!_initializationController.isReady && !bypassInitialization) {
          if (!_showInitializationScreen) {
            return ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const SizedBox.expand(),
            );
          }
          return AppInitializationScreen(
            controller: _initializationController,
            dictionaryLibrary: _dictionaryLibrary,
            onRetry: _retryInitialization,
          );
        }

        final screens = _buildTabScreens();

        return Scaffold(
          body: IndexedStack(index: _selectedIndex, children: screens),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
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
