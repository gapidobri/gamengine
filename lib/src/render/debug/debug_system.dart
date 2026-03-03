import 'package:gamengine/src/ecs/system.dart';
import 'package:gamengine/src/render/debug/debug_stats.dart';
import 'package:gamengine/src/render/core/render_metrics.dart';

class DebugSystem extends System {
  final DebugStats stats;
  final RenderMetrics renderMetrics;

  double _smoothedFps = 0;

  DebugSystem({
    required this.stats,
    required this.renderMetrics,
  });

  @override
  int get priority => 900;

  @override
  void update(double dt) {
    if (dt > 0) {
      final instantFps = 1 / dt;
      _smoothedFps = _smoothedFps == 0
          ? instantFps
          : (_smoothedFps * 0.9) + (instantFps * 0.1);
    }

    stats.updateFrame(
      fps: _smoothedFps,
      sceneItems: renderMetrics.sceneItems,
      drawnItems: renderMetrics.drawnItems,
    );
  }
}
