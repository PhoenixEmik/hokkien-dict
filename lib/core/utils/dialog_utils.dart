import 'dart:async';
import 'package:flutter/material.dart';

IconData? _sfSymbolToMaterialIcon(String symbol) {
  return switch (symbol) {
    'book.fill' => Icons.menu_book,
    'bookmark.fill' => Icons.bookmark,
    'gearshape.fill' => Icons.settings,
    'gearshape' => Icons.settings_outlined,
    'chevron.up.chevron.down' => Icons.unfold_more,
    _ => null,
  };
}

Widget? _buildDialogIcon(dynamic icon, {double? iconSize, Color? iconColor}) {
  if (icon == null) {
    return null;
  }

  if (icon is Icon) {
    return Icon(
      icon.icon,
      size: iconSize ?? icon.size,
      color: iconColor ?? icon.color,
    );
  }

  if (icon is IconData) {
    return Icon(icon, size: iconSize, color: iconColor);
  }

  if (icon is String) {
    final mappedIcon = _sfSymbolToMaterialIcon(icon);
    if (mappedIcon != null) {
      return Icon(mappedIcon, size: iconSize, color: iconColor);
    }
  }

  return null;
}

Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  required String cancelLabel,
  required String confirmLabel,
  bool barrierDismissible = true,
  bool isDestructiveAction = false,
  dynamic icon,
  double? iconSize,
  Color? iconColor,
}) async {
  final dialogIcon = _buildDialogIcon(
    icon,
    iconSize: iconSize,
    iconColor: iconColor,
  );

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: true,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;

      return AlertDialog(
        icon: dialogIcon,
        title: Text(title),
        content: content.isEmpty ? null : Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          if (isDestructiveAction)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              child: Text(confirmLabel),
            )
          else
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
        ],
      );
    },
  );

  return result ?? false;
}

Future<VoidCallback> showAdaptiveBlockingProgressDialog({
  required BuildContext context,
  required String title,
  String? message,
  required String actionLabel,
  dynamic icon,
  double? iconSize,
  Color? iconColor,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  var closed = false;
  final dialogIcon = _buildDialogIcon(
    icon,
    iconSize: iconSize,
    iconColor: iconColor,
  );

  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            icon: dialogIcon,
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2.5),
                ),
                if (message != null && message.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(message),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: null, child: Text(actionLabel)),
            ],
          ),
        );
      },
    ),
  );

  await Future<void>.delayed(Duration.zero);

  return () {
    if (closed) {
      return;
    }

    closed = true;
    unawaited(navigator.maybePop());
  };
}
