import 'package:flutter/widgets.dart';
import 'package:gamengine/src/ecs/events/event.dart';

class RawInputEvent extends GameEvent {
  final KeyEvent keyEvent;

  const RawInputEvent({required this.keyEvent});
}
