import 'dart:async';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

dynamic _normalizeAdaptiveDialogIcon(dynamic icon) {
  if (icon is IconData || icon is String || icon == null) {
    return icon;
  }
  if (icon is Icon) {
    return icon.icon;
  }
  return null;
}

AlertActionStyle _cancelActionStyle(BuildContext context) {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return AlertActionStyle.secondary;
  }
  return AlertActionStyle.cancel;
}

AlertActionStyle _confirmActionStyle(
  BuildContext context, {
  required bool isDestructiveAction,
}) {
  if (isDestructiveAction) {
    return AlertActionStyle.destructive;
  }

  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return AlertActionStyle.defaultAction;
  }
  return AlertActionStyle.primary;
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
  double iconSize = 28,
  Color? iconColor,
}) async {
  final result = Completer<bool>();

  await AdaptiveAlertDialog.show(
    context: context,
    title: title,
    message: content,
    icon: _normalizeAdaptiveDialogIcon(icon),
    iconSize: iconSize,
    iconColor: iconColor,
    actions: [
      AlertAction(
        title: cancelLabel,
        style: _cancelActionStyle(context),
        onPressed: () {
          if (!result.isCompleted) {
            result.complete(false);
          }
        },
      ),
      AlertAction(
        title: confirmLabel,
        style: _confirmActionStyle(
          context,
          isDestructiveAction: isDestructiveAction,
        ),
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
  double iconSize = 24,
  Color? iconColor,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  var closed = false;

  unawaited(
    AdaptiveAlertDialog.show(
      context: context,
      title: title,
      message: message,
      icon: _normalizeAdaptiveDialogIcon(icon),
      iconSize: iconSize,
      iconColor: iconColor,
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
