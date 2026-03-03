import 'package:gamengine/src/ui/ui_command.dart';

class UiCommandQueue {
  final List<UiCommand> _currentFrame = <UiCommand>[];
  final List<UiCommand> _nextFrame = <UiCommand>[];

  bool get isEmpty => _currentFrame.isEmpty;

  void beginFrame() {}

  void endFrame() {
    _currentFrame
      ..clear()
      ..addAll(_nextFrame);
    _nextFrame.clear();
  }

  void push(UiCommand command) {
    _nextFrame.add(command);
  }

  Iterable<T> read<T extends UiCommand>() sync* {
    for (final command in _currentFrame) {
      if (command is T) {
        yield command;
      }
    }
  }

  void clear() {
    _currentFrame.clear();
    _nextFrame.clear();
  }
}
