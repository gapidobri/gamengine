import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:gamengine/src/ecs/engine.dart';
import 'package:gamengine/src/input/events/raw_input_event.dart';
import 'package:gamengine/src/render/camera/camera_state.dart';
import 'package:gamengine/src/render/debug/debug_overlay.dart';
import 'package:gamengine/src/render/debug/debug_stats.dart';
import 'package:gamengine/src/render/backends/painter.dart';
import 'package:gamengine/src/render/core/render_queue.dart';

class GameView extends StatefulWidget {
  final Engine engine;
  final RenderQueue queue;
  final CameraState camera;
  final DebugStats? debugStats;
  final bool autoStart;

  const GameView({
    super.key,
    required this.engine,
    required this.queue,
    required this.camera,
    this.debugStats,
    this.autoStart = true,
  });

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView>
    with SingleTickerProviderStateMixin {
  final _focusNode = FocusNode();

  late final Ticker _ticker;
  Duration? _lastTick;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.autoStart) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final lastTick = _lastTick;
    _lastTick = elapsed;

    if (lastTick == null) {
      return;
    }

    final dt = (elapsed - lastTick).inMicroseconds / 1000000.0;
    widget.engine.update(dt);
  }

  @override
  void didUpdateWidget(covariant GameView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoStart && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.autoStart && _ticker.isActive) {
      _ticker.stop();
      _lastTick = null;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    widget.engine.events.emit(RawInputEvent(keyEvent: event));
    return .handled;
  }

  @override
  Widget build(BuildContext context) {
    final gameCanvas = Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: Painter(queue: widget.queue, camera: widget.camera),
          size: Size.infinite,
        ),
      ),
    );

    final debugStats = widget.debugStats;
    if (debugStats == null) {
      return gameCanvas;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        gameCanvas,
        DebugOverlay(stats: debugStats),
      ],
    );
  }
}
