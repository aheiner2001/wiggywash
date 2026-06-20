import 'package:flutter/material.dart';

/// Shows a snackbar for store errors (Firestore permission failures, etc.).
void showStoreMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? null : Theme.of(context).colorScheme.primary,
    ),
  );
}
