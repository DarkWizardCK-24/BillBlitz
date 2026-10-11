import 'package:billing_system/theme/app_theme.dart';
import 'package:flutter/material.dart';

enum SnackKind { success, warning, error, info }

/// One place for every snackbar, replacing the ~10 copy-pasted blocks.
void showAppSnack(
  BuildContext context,
  String message, {
  SnackKind kind = SnackKind.info,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final color = switch (kind) {
    SnackKind.success => AppColors.success,
    SnackKind.warning => AppColors.warning,
    SnackKind.error => AppColors.danger,
    SnackKind.info => AppColors.textPrimary,
  };
  final icon = switch (kind) {
    SnackKind.success => Icons.check_circle_outline,
    SnackKind.warning => Icons.info_outline,
    SnackKind.error => Icons.error_outline,
    SnackKind.info => Icons.info_outline,
  };

  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              ),
      ),
    );
}
