import 'package:flutter/material.dart';

void showAppNotification(
  BuildContext context, {
  required String message,
  bool isError = false,
  Duration duration = const Duration(milliseconds: 2600),
}) {
  if (message.isEmpty) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  final theme = Theme.of(context);
  final snackBarTheme = theme.snackBarTheme;
  final colorScheme = theme.colorScheme;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: snackBarTheme.behavior ?? SnackBarBehavior.floating,
        backgroundColor: isError
            ? colorScheme.primary
            : snackBarTheme.backgroundColor,
        shape: snackBarTheme.shape,
        elevation: snackBarTheme.elevation,
        action: SnackBarAction(
          label: 'OK',
          textColor: isError
              ? snackBarTheme.actionTextColor ?? colorScheme.onPrimary
              : snackBarTheme.actionTextColor,
          onPressed: messenger.hideCurrentSnackBar,
        ),
      ),
    );
}
