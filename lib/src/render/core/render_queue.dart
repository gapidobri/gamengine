import 'package:flutter/foundation.dart';
import 'package:gamengine/src/render/commands/render_commands.dart';

class RenderQueue extends ChangeNotifier {
  final _commands = <RenderCommand>[];

  List<RenderCommand> get commands => _commands;

  void beginFrame() {
    _commands.clear();
  }

  void add(RenderCommand command) {
    _commands.add(command);
  }

  void endFrame() {
    final insertionOrder = Expando<int>('renderOrder');
    for (var i = 0; i < _commands.length; i++) {
      insertionOrder[_commands[i]] = i;
    }

    _commands.sort((a, b) {
      final byZ = a.z.compareTo(b.z);
      if (byZ != 0) {
        return byZ;
      }

      final ai = insertionOrder[a] ?? 0;
      final bi = insertionOrder[b] ?? 0;
      return ai.compareTo(bi);
    });
    notifyListeners();
  }
}
