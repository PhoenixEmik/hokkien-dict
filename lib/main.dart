import 'package:flutter/material.dart';
import 'package:hokkien_dictionary/app/app.dart';

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

void main() {
  runApp(const HokkienDictionaryApp());
}
