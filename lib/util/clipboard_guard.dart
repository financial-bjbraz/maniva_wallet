import 'dart:async';
import 'package:flutter/services.dart';

/// Copies [text] to the system clipboard and schedules a clear after
/// [timeout] (default 60 seconds) by overwriting the clipboard with an
/// empty string.
///
/// Returns the [Timer] so the caller can cancel it early (e.g. on dispose).
Timer copyWithTimeout(
  String text, {
  Duration timeout = const Duration(seconds: 60),
}) {
  Clipboard.setData(ClipboardData(text: text));
  return Timer(timeout, () {
    Clipboard.setData(const ClipboardData(text: ''));
  });
}
