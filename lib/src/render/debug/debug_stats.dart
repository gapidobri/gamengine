import 'package:flutter/foundation.dart';

class DebugStats extends ChangeNotifier {
  double fps = 0;
  int sceneItems = 0;
  int drawnItems = 0;

  final Map<String, String> _lines = <String, String>{};

  Map<String, String> get lines => _lines;

  void updateFrame({
    required double fps,
    required int sceneItems,
    required int drawnItems,
  }) {
    this.fps = fps;
    this.sceneItems = sceneItems;
    this.drawnItems = drawnItems;
    notifyListeners();
  }

  void setLine(String key, String value) {
    _lines[key] = value;
    notifyListeners();
  }

  void setLines(Map<String, String> lines) {
    var changed = _lines.length != lines.length;
    if (!changed) {
      for (final entry in lines.entries) {
        if (_lines[entry.key] != entry.value) {
          changed = true;
          break;
        }
      }
    }

    if (!changed) {
      return;
    }

    _lines
      ..clear()
      ..addAll(lines);
    notifyListeners();
  }

  void removeLine(String key) {
    if (_lines.remove(key) != null) {
      notifyListeners();
    }
  }
}
