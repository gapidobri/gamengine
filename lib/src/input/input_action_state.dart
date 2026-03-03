class InputActionFrameState {
  bool isPressed = false;
  bool justPressed = false;
  bool justReleased = false;
}

class InputActionState<T> {
  final Map<T, InputActionFrameState> _states = <T, InputActionFrameState>{};

  void beginFrame() {
    for (final state in _states.values) {
      state.justPressed = false;
      state.justReleased = false;
    }
  }

  void setPressed(T action, bool isPressed) {
    final state = _states.putIfAbsent(action, InputActionFrameState.new);
    if (state.isPressed == isPressed) {
      return;
    }

    state.isPressed = isPressed;
    if (isPressed) {
      state.justPressed = true;
      state.justReleased = false;
      return;
    }
    state.justReleased = true;
    state.justPressed = false;
  }

  bool isPressed(T action) => _states[action]?.isPressed ?? false;
  bool justPressed(T action) => _states[action]?.justPressed ?? false;
  bool justReleased(T action) => _states[action]?.justReleased ?? false;

  void clear() {
    _states.clear();
  }
}
