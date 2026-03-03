import 'package:gamengine/src/ecs/events/event.dart';

class EventBus {
  final List<GameEvent> _currentFrame = <GameEvent>[];
  final List<GameEvent> _nextFrame = <GameEvent>[];

  bool get isEmpty => _currentFrame.isEmpty;
  int get currentFrameCount => _currentFrame.length;
  int get queuedCount => _nextFrame.length;

  void beginFrame() {}

  void endFrame() {
    _currentFrame
      ..clear()
      ..addAll(_nextFrame);
    _nextFrame.clear();
  }

  void emit(GameEvent event) {
    _nextFrame.add(event);
  }

  Iterable<T> read<T extends GameEvent>() sync* {
    for (final event in _currentFrame) {
      if (event is T) {
        yield event;
      }
    }
  }

  void clear() {
    _currentFrame.clear();
    _nextFrame.clear();
  }
}
