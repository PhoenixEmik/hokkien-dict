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
  final colorScheme = Theme.of(context).colorScheme;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? colorScheme.errorContainer
            : colorScheme.inverseSurface,
        action: SnackBarAction(
          label: 'OK',
          textColor: isError ? colorScheme.onErrorContainer : colorScheme.onInverseSurface,
          onPressed: messenger.hideCurrentSnackBar,
        ),
      ),
    );
}
