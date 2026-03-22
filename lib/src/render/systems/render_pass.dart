import 'package:gamengine/src/ecs/world.dart';
import 'package:gamengine/src/render/camera/camera_state.dart';
import 'package:gamengine/src/render/core/render_queue.dart';

enum RenderPassStage {
  beforeWorld,
  afterWorld,
}

abstract class RenderPass {
  const RenderPass();

  int get priority => 0;

  RenderPassStage get stage => RenderPassStage.afterWorld;

  void write(
    World world, {
    required CameraState camera,
    required RenderQueue queue,
  });
}
