import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkStore extends ChangeNotifier {
  static const _bookmarkIdsKey = 'bookmarked_entry_ids';

  List<int> _bookmarkedIds = const <int>[];

  List<int> get bookmarkedIds => List<int>.unmodifiable(_bookmarkedIds);

  bool isBookmarked(int entryId) {
    return _bookmarkedIds.contains(entryId);
  }

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final storedIds = preferences.getStringList(_bookmarkIdsKey) ?? const [];
    _bookmarkedIds = storedIds
        .map(int.tryParse)
        .whereType<int>()
        .toList(growable: false);
    notifyListeners();
  }

  Future<void> toggleBookmark(int entryId) async {
    final nextIds = isBookmarked(entryId)
        ? _bookmarkedIds.where((id) => id != entryId).toList(growable: false)
        : <int>[entryId, ..._bookmarkedIds.where((id) => id != entryId)];
    _bookmarkedIds = nextIds;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _bookmarkIdsKey,
      _bookmarkedIds.map((id) => '$id').toList(growable: false),
    );
    notifyListeners();
  }
}
