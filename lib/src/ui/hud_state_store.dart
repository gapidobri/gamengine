import 'package:flutter/foundation.dart';

class HudStateStore<T> extends ValueNotifier<T> {
  HudStateStore(super.value);

  void setIfChanged(T next) {
    if (value == next) {
      return;
    }
    value = next;
  }
}
