import 'package:flutter/services.dart';

class InputKeymap<T> {
  final _keymap = <LogicalKeyboardKey, T>{};

  void registerAction({
    required T action,
    required List<LogicalKeyboardKey> keys,
  }) {
    for (final key in keys) {
      _keymap[key] = action;
    }
  }

  T? getAction(LogicalKeyboardKey key) {
    return _keymap[key];
  }
}
