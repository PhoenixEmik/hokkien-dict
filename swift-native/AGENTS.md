# AGENTS.md — 台語辭典 iOS Native Migration

This repository is a native Swift iOS rewrite of the Flutter app “台語辭典”.

The main UI goal is to build a truly native iOS app, not a pixel-by-pixel port of the Flutter UI.

Use Apple-native SwiftUI and UIKit components wherever possible so the app automatically benefits from future iOS appearance updates, including Liquid Glass, Dynamic Type, accessibility improvements, adaptive layouts, and platform-standard interactions.

## Core UI Rule

Prefer native system components over custom UI.

Do not recreate Flutter widgets manually in Swift.

Before creating any custom view, ask:

“Can this be expressed with a standard SwiftUI or UIKit component?”

If yes, use the native component.

If no, explain why a custom component is necessary and keep it small, isolated, accessible, and visually restrained.

## Preferred UI Framework

Use SwiftUI as the primary UI framework unless there is a strong technical reason to use UIKit.

Prefer these native components and patterns:

- `NavigationStack`
- `NavigationSplitView`
- `TabView`
- `List`
- `Section`
- `Form`
- `ToolbarItem`
- `.toolbar`
- `.searchable`
- `.sheet`
- `.popover`
- `.alert`
- `.confirmationDialog`
- `Menu`
- `Button`
- `Picker`
- `Toggle`
- `TextField`
- `ShareLink`
- `Label`
- SF Symbols
- system colors
- system fonts
- semantic spacing

## Avoid Custom Replacements

Do not create custom replacements for standard Apple UI unless explicitly requested.

Avoid creating files or components like:

- `CustomTabBar`
- `CustomNavigationBar`
- `CustomSearchBar`
- `CustomToolbar`
- `CustomSheet`
- `CustomAlert`
- `GlassButton`
- `LiquidGlassPanel`
- `BlurredCard`
- `AppThemeButton`
- `UniversalCard`

If you think one is needed, first propose the native SwiftUI alternative and explain why it is insufficient.

The default answer should be: use the system component.

## Liquid Glass / Future iOS Compatibility

Do not manually fake Liquid Glass.

Avoid custom blur layers, transparent panels, hand-tuned glassmorphism, excessive shadows, decorative borders, gradients, or artificial material effects.

Rely on system navigation, tab bars, toolbars, search, sheets, menus, alerts, and controls so iOS can update their appearance automatically in future releases.

The app should look good using standard system UI before any custom styling is added.

## App Structure Guidance

Design “台語辭典” around native iOS information architecture.

Recommended structure:

### Dictionary Search

Use:

- `NavigationStack`
- `.searchable`
- `List`
- `Section` where useful
- native empty states where appropriate

Do not build a custom search bar.

### Search Results

Use native `List` rows.

Rows may contain:

- main Taiwanese term
- pronunciation / romanization
- short definition preview
- small secondary metadata

Use native typography such as `.headline`, `.body`, `.subheadline`, `.caption`, `.secondary`.

Avoid heavy custom cards unless they solve a clear readability problem.

### Entry Detail

Use native navigation push.

Prefer:

- `List`
- `Section`
- readable SwiftUI content blocks
- system text styles
- copy/share actions where useful
- `ShareLink` for sharing entries

Dictionary content is text-heavy, so prioritize readability over decoration.

### Favorites / Saved Words

Use:

- `List`
- native swipe actions
- native edit mode if deletion or reordering is needed

### Settings

Use:

- `Form`
- `Section`
- `Toggle`
- `Picker`
- `Button`
- `Link`

Do not design a custom settings screen from scratch.

### iPad

Use `NavigationSplitView` where appropriate.

A good iPad layout is:

- left column: search/results/favorites
- right column: selected dictionary entry detail

## Visual Design Rules

Use Apple Human Interface Guidelines style by default.

Prefer:

- system font styles
- Dynamic Type
- semantic colors such as `.primary`, `.secondary`, `.background`, `.tint`
- SF Symbols
- native list and form grouping
- adaptive layout
- simple hierarchy

Avoid:

- hard-coded font sizes
- fixed pixel-perfect layouts copied from Flutter
- custom global themes that fight the system
- excessive rounded rectangles
- custom shadows everywhere
- fake glass panels
- custom gradients as default backgrounds
- overriding navigation appearance globally
- dense decorative cards for simple text rows

## Accessibility Requirements

Every screen must support:

- Dynamic Type
- VoiceOver
- Dark Mode
- sufficient contrast
- large text sizes without clipping
- Reduce Motion where relevant
- keyboard navigation where appropriate, especially on iPad

Do not sacrifice readability for Liquid Glass aesthetics.

## Migration Mindset

Do not port Flutter widget-by-widget.

For every screen:

1. Identify the user intent.
2. Map it to the closest native iOS pattern.
3. Implement with standard SwiftUI/UIKit components.
4. Remove Flutter-era visual workarounds.
5. Add custom styling only after the native version works.
6. Keep product-specific design focused on dictionary content, not system chrome.

The Taiwanese dictionary content is the app’s personality.

Navigation bars, search bars, sheets, tabs, forms, buttons, and alerts should mostly belong to the system.

## Acceptance Criteria

A migrated screen is acceptable only if:

- it uses native navigation
- it uses native search when search is present
- it uses native list/form structures where appropriate
- it avoids custom replacements for Apple controls
- it works in Light Mode and Dark Mode
- it supports Dynamic Type
- it has reasonable VoiceOver labels
- it remains readable with large text
- it looks acceptable without custom blur or glass effects
- it can plausibly benefit from future iOS visual updates automatically

## When Unsure

Choose the boring native iOS solution first.

Custom UI is allowed only when it improves the dictionary experience, not when it merely imitates Apple system chrome.