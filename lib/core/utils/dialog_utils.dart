import 'dart:async';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  required String cancelLabel,
  required String confirmLabel,
  bool barrierDismissible = true,
  bool isDestructiveAction = false,
}) async {
  final result = Completer<bool>();

  await AdaptiveAlertDialog.show(
    context: context,
    title: title,
    message: content,
    actions: [
      AlertAction(
        title: cancelLabel,
        style: AlertActionStyle.cancel,
        onPressed: () {
          if (!result.isCompleted) {
            result.complete(false);
          }
        },
      ),
      AlertAction(
        title: confirmLabel,
        style: isDestructiveAction
            ? AlertActionStyle.destructive
            : AlertActionStyle.primary,
        onPressed: () {
          if (!result.isCompleted) {
            result.complete(true);
          }
        },
      ),
    ],
  );

  if (!result.isCompleted) {
    return false;
  }

  return result.future;
}

Future<VoidCallback> showAdaptiveBlockingProgressDialog({
  required BuildContext context,
  required String title,
  String? message,
  required String actionLabel,
  dynamic icon,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  var closed = false;

  unawaited(
    AdaptiveAlertDialog.show(
      context: context,
      title: title,
      message: message,
      icon: icon,
      actions: [
        AlertAction(
          title: actionLabel,
          enabled: false,
          style: AlertActionStyle.disabled,
          onPressed: () {},
        ),
      ],
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
