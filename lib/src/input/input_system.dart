import 'package:flutter/services.dart';
import 'package:gamengine/gamengine.dart';

class InputSystem<T> extends System {
  final InputKeymap<T> keymap;
  final InputActionState<T> actionState;
  final EventBus eventBus;

  InputSystem({
    super.priority,
    required this.eventBus,
    required this.keymap,
    required this.actionState,
  });

  @override
  int get priority => 100;

  @override
  void update(double dt, World world, Commands commands) {
    actionState.beginFrame();

    final rawEvents = eventBus.read<RawInputEvent>().toList(growable: false);
    for (final event in rawEvents) {
      final action = keymap.getAction(event.keyEvent.logicalKey);
      if (action != null) {
        final isPressed = event.keyEvent is! KeyUpEvent;
        actionState.setPressed(action, isPressed);
        eventBus.emitImmediate(InputEvent<T>(action: action, begin: isPressed));
      }
    }
  }
}
