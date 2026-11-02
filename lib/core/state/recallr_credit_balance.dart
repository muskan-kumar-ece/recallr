import 'package:flutter/foundation.dart';

/// Bridges the trusted backend's post-request credit balance to the shell UI.
/// The Firestore subscription stream remains authoritative; this value only
/// prevents the app bar from waiting for the snapshot round-trip after Ask.
class RecallrCreditBalance {
  RecallrCreditBalance._();

  static final ValueNotifier<int?> current = ValueNotifier<int?>(null);

  static void updateFromAnswer(int? remainingCredits) {
    if (remainingCredits != null) current.value = remainingCredits;
  }

  static void clear() => current.value = null;
}
