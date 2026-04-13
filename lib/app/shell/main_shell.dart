import 'dart:async';

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
import 'package:taigi_dict/features/settings/presentation/widgets/liquid_glass.dart';
import 'package:taigi_dict/offline_audio.dart';
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

  Widget _buildAppleFloatingDock(BuildContext context, AppLocalizations l10n) {
    final barWidth = (MediaQuery.sizeOf(context).width - 64)
        .clamp(248.0, 320.0)
        .toDouble();
    final selectedItemColor = _dockSelectedItemColor(context);
    final unselectedItemColor = _dockUnselectedItemColor(context);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(left: 32, right: 32),
          child: SizedBox(
            width: barWidth,
            child: glass.GlassBottomBar(
              selectedIndex: _selectedIndex,
              glassSettings: _dockGlassSettings(context),
              indicatorColor: _dockIndicatorColor(context),
              selectedIconColor: selectedItemColor,
              unselectedIconColor: unselectedItemColor,
              onTabSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              tabs: [
                glass.GlassBottomBarTab(
                  label: l10n.dictionaryTab,
                  icon: Icon(CupertinoIcons.book, color: unselectedItemColor),
                  activeIcon: Icon(
                    CupertinoIcons.book_fill,
                    color: selectedItemColor,
                  ),
                ),
                glass.GlassBottomBarTab(
                  label: l10n.bookmarksTab,
                  icon: Icon(
                    CupertinoIcons.bookmark,
                    color: unselectedItemColor,
                  ),
                  activeIcon: Icon(
                    CupertinoIcons.bookmark_fill,
                    color: selectedItemColor,
                  ),
                ),
                glass.GlassBottomBarTab(
                  label: l10n.settingsTab,
                  icon: Icon(CupertinoIcons.gear, color: unselectedItemColor),
                  activeIcon: Icon(
                    CupertinoIcons.gear_solid,
                    color: selectedItemColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  glass.LiquidGlassSettings _dockGlassSettings(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return glass.LiquidGlassSettings(
      glassColor: isLight
          ? Colors.white.withValues(alpha: 0.58)
          : const Color(0xFF2C2C2E).withValues(alpha: 0.72),
      thickness: 30,
      blur: isLight ? 3 : 22,
      chromaticAberration: isLight ? 0.3 : 0.08,
      lightIntensity: isLight ? 0.6 : 0.72,
      refractiveIndex: isLight ? 1.59 : 1.22,
      saturation: isLight ? 0.7 : 1.08,
      ambientStrength: isLight ? 1 : 0.55,
    );
  }

  Color _dockSelectedItemColor(BuildContext context) {
    return CupertinoDynamicColor.resolve(CupertinoColors.activeBlue, context);
  }

  Color _dockUnselectedItemColor(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return isLight ? Colors.black87 : Colors.white;
  }

  Color _dockIndicatorColor(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return isLight
        ? Colors.black.withValues(alpha: 0.06)
        : const Color(0xFF3A3A3C).withValues(alpha: 0.84);
  }

  PreferredSizeWidget? _buildRootAppBar(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    switch (_selectedIndex) {
      case 1:
        if (isApplePlatform(context)) {
          return glass.GlassAppBar(
            useOwnLayer: true,
            quality: glass.GlassQuality.premium,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              l10n.bookmarksTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: resolveLiquidGlassForeground(context),
              ),
            ),
          );
        }
        return AppBar(title: Text(l10n.bookmarksTitle));
      case 2:
        if (isApplePlatform(context)) {
          return glass.GlassAppBar(
            useOwnLayer: true,
            quality: glass.GlassQuality.premium,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              l10n.settingsTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: resolveLiquidGlassForeground(context),
              ),
            ),
          );
        }
        return AppBar(title: Text(l10n.settingsTitle));
      default:
        return null;
    }
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

        if (isApplePlatform(context)) {
          return Scaffold(
            extendBody: true,
            backgroundColor: Colors.transparent,
            appBar: _buildRootAppBar(context, l10n),
            body: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: IndexedStack(index: _selectedIndex, children: screens),
                ),
                _buildAppleFloatingDock(context, l10n),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: _buildRootAppBar(context, l10n),
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
