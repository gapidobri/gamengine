import 'package:gamengine/src/ecs/events/event.dart';

class EventBus {
  final List<GameEvent> _currentFrame = <GameEvent>[];
  final List<GameEvent> _nextFrame = <GameEvent>[];
  bool _isFrameActive = false;

  bool get isEmpty => _currentFrame.isEmpty;
  int get currentFrameCount => _currentFrame.length;
  int get queuedCount => _nextFrame.length;

  void beginFrame() {
    _isFrameActive = true;
    _currentFrame
      ..clear()
      ..addAll(_nextFrame);
    _nextFrame.clear();
  }

  void endFrame() {
    _isFrameActive = false;
    _currentFrame.clear();
  }

  void emit(GameEvent event) {
    _nextFrame.add(event);
  }

  void emitImmediate(GameEvent event) {
    if (_isFrameActive) {
      _currentFrame.add(event);
      return;
    }
    _nextFrame.add(event);
  }

  Iterable<T> read<T extends GameEvent>() sync* {
    final snapshot = List<GameEvent>.of(_currentFrame);
    for (final event in snapshot) {
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
