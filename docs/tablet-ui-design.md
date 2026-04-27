# Tablet UI Design

This document records the tablet optimization direction for Taigi Dict so the work can be continued in a future session without re-discovery.

## Goal

Keep the app's existing phone navigation model, but make the dictionary experience meaningfully better on tablet-sized screens.

## Design Decision

### Keep bottom navigation

We evaluated switching tablet layout to a left-side navigation rail.

That change was rejected for now because:

- it changes the primary navigation pattern between phone and tablet
- it looked visually off on Android tablets
- it weakened the existing theme balance
- bottom navigation is already part of the current app identity

Current decision:

- keep `AdaptiveBottomNavigationBar` on both phone and tablet
- optimize content layout inside each tab instead of changing global navigation

## Phase 1 Scope

Phase 1 only covers:

1. main navigation decision
2. dictionary split-view experience on tablet

It does **not** yet redesign:

- bookmarks tablet layout
- settings tablet layout
- article/help/detail pages outside dictionary flow

## Phase 2 Progress

Implemented after the initial split-view pass:

1. dictionary tablet spacing refinement
2. bookmarks tablet layout
3. settings tablet layout

### Dictionary spacing refinement

- Tablet dictionary content now uses a centered max-width container.
- Search pane width is capped so the detail pane gets more useful room.
- The empty detail placeholder is constrained to readable line lengths.
- In-place tablet detail content uses tighter internal padding than the phone detail page.

### Bookmarks tablet layout

- Tablet bookmarks now switch to a responsive grid layout.
- Phone keeps the original single-column scrolling list.
- Empty bookmarks state stays centered with a narrower readable width.

### Settings tablet layout

- Tablet settings now switch to a two-column grouped layout.
- Left column holds offline resources and appearance.
- Right column holds about/help actions.
- Phone keeps the original single-column section list.

## Tablet Breakpoints

### Main shell

- Global app shell remains bottom navigation on all sizes.

### Dictionary split view

- Tablet split-view activates at `>= 960px` width in `DictionaryScreen`.
- Narrower widths continue using the existing single-column phone layout.

## Dictionary Split View

### Layout

On tablet, the dictionary tab becomes a two-pane layout:

- Left pane:
  - search field
  - search history
  - result list
- Right pane:
  - selected entry detail
  - bookmark action
  - share action
  - audio playback
  - related-word navigation

### Behavior

- No query:
  - left pane shows the existing empty/start-search state
  - right pane shows a neutral “select an entry” placeholder
- Active query:
  - left pane shows results
  - tapping a result loads the detail into the right pane
- Related words tapped inside the right pane:
  - the right pane updates in place to the linked entry
- Search cleared:
  - tablet selection is cleared
  - right pane returns to placeholder state

### Selection state

Selected result rows in the left pane use a visible selected state:

- tinted container
- subtle border emphasis
- primary-colored chevron

This is tablet-only behavior. Phone list items remain unselected cards.

## Shared Detail Logic

To avoid diverging phone and tablet behavior, entry resolution was centralized.

### Current shared preparation flow

`WordDetailCoordinator` now exposes reusable preparation methods:

- `prepareWordDetail(...)`
- `findNavigableLinkedEntry(...)`

These methods handle:

- alias resolution
- localized display entry translation
- openable related-word resolution
- self-link avoidance

Phone flow still pushes `WordDetailScreen`.
Tablet flow reuses the same preparation logic and renders the result in place.

## Files Changed

### Main shell

- [main_shell.dart](/Users/emik/Documents/Hokkien/lib/app/shell/main_shell.dart)

### Dictionary tablet split view

- [dictionary_screen.dart](/Users/emik/Documents/Hokkien/lib/features/dictionary/presentation/screens/dictionary_screen.dart)
- [entry_list_item.dart](/Users/emik/Documents/Hokkien/lib/features/dictionary/presentation/widgets/entry_list_item.dart)
- [word_detail_screen.dart](/Users/emik/Documents/Hokkien/lib/features/dictionary/presentation/screens/word_detail_screen.dart)

### Bookmarks tablet layout

- [bookmarks_screen.dart](/Users/emik/Documents/Hokkien/lib/features/bookmarks/presentation/screens/bookmarks_screen.dart)

### Settings tablet layout

- [settings_screen.dart](/Users/emik/Documents/Hokkien/lib/features/settings/presentation/screens/settings_screen.dart)

### Shared detail logic

- [word_detail_coordinator.dart](/Users/emik/Documents/Hokkien/lib/features/dictionary/presentation/coordinators/word_detail_coordinator.dart)
- [word_detail_screen.dart](/Users/emik/Documents/Hokkien/lib/features/dictionary/presentation/screens/word_detail_screen.dart)

### Localization

- [app_localizations.dart](/Users/emik/Documents/Hokkien/lib/core/localization/app_localizations.dart)

## New Localization Keys

Added for tablet empty detail pane:

- `tabletPreviewEmptyTitle`
- `tabletPreviewEmptyBody`

## Branch State

Current tablet work is committed on:

- branch: `tablet-ui-optimization`
- commit: `e0720ed`

This work is intentionally not on `main`.

## Validation Performed

Ran successfully:

- `flutter analyze`
- `flutter test test/widget_test.dart`

## Recommended Next Steps

### Phase 2

1. Refine tablet dictionary spacing
   - refine search/history card density further on very large screens
   - verify detail pane typography balance on 11-inch and 13-inch tablets

2. Tablet bookmarks layout
   - evaluate whether dense 3-column mode is worth adding on extra-wide landscape

3. Tablet settings layout
   - evaluate whether advanced settings should also get tablet grouping

4. Device verification
   - verify on Android tablet
   - verify on iPad
   - check landscape and portrait separately

## Notes for Future Session

If continuing this work in a new session:

- start from branch `tablet-ui-optimization`
- do not reintroduce navigation rail unless navigation strategy is intentionally being reconsidered
- preserve shared phone/tablet word-detail resolution through `WordDetailCoordinator`
- keep bottom navigation consistent across device classes unless the product direction changes
