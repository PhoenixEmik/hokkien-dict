import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/app/app.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;

export 'app/app.dart';
export 'core/localization/app_localizations.dart';
export 'core/localization/locale_provider.dart';
export 'core/preferences/app_preferences.dart';
export 'features/bookmarks/application/bookmark_store.dart';
export 'features/bookmarks/presentation/screens/bookmarks_screen.dart';
export 'features/dictionary/data/dictionary_repository.dart';
export 'features/dictionary/domain/dictionary_models.dart';
export 'features/dictionary/domain/dictionary_search_service.dart';
export 'features/dictionary/presentation/screens/dictionary_screen.dart';
export 'features/dictionary/presentation/screens/word_detail_screen.dart';
export 'features/dictionary/presentation/widgets/entry_list_item.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await glass.LiquidGlassWidgets.initialize();
  runApp(glass.LiquidGlassWidgets.wrap(const HokkienDictionaryApp()));
}
