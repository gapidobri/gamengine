import 'package:gamengine/src/ecs/events/event.dart';

class InputEvent<T> extends GameEvent {
  final T action;
  final bool begin;

  const InputEvent({required this.action, required this.begin});
}
