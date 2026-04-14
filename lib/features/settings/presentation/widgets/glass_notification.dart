import 'package:flutter/material.dart';

void showGlassNotification(
  BuildContext context, {
  required String message,
  bool isError = false,
  Duration duration = const Duration(milliseconds: 2600),
}) {
  if (message.isEmpty) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: duration),
  );
}
