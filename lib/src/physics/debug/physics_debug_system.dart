import 'dart:math' as math;

import 'package:gamengine/src/ecs/system.dart';
import 'package:gamengine/src/ecs/components/transform.dart';
import 'package:gamengine/src/ecs/world.dart';
import 'package:gamengine/src/physics/components/gravity_source.dart';
import 'package:gamengine/src/physics/components/rigid_body.dart';
import 'package:gamengine/src/physics/physics_system.dart';
import 'package:gamengine/src/render/debug/debug_stats.dart';

class PhysicsDebugSystem extends System {
  final World world;
  final DebugStats stats;
  final PhysicsSystem? physicsSystem;

  PhysicsDebugSystem({
    required this.world,
    required this.stats,
    this.physicsSystem,
  });

  @override
  int get priority => 450;

  @override
  void update(double dt) {
    var totalBodies = 0;
    var dynamicBodies = 0;
    var staticBodies = 0;
    var totalSpeed = 0.0;
    var maxSpeed = 0.0;

    for (final entity in world.query2<Transform, RigidBody>()) {
      final body = world.get<RigidBody>(entity);
      totalBodies++;
      if (body.isStatic) {
        staticBodies++;
      } else {
        dynamicBodies++;
      }

      final speed = body.velocity.length;
      totalSpeed += speed;
      maxSpeed = math.max(maxSpeed, speed);
    }

    var gravitySources = 0;
    for (final _ in world.query2<Transform, GravitySource>()) {
      gravitySources++;
    }

    final avgSpeed = totalBodies == 0 ? 0.0 : totalSpeed / totalBodies;
    stats.setLines(<String, String>{
      'Physics Bodies':
          '$totalBodies (dyn $dynamicBodies / static $staticBodies)',
      'Gravity Sources': '$gravitySources',
      'Velocity avg/max':
          '${avgSpeed.toStringAsFixed(2)} / ${maxSpeed.toStringAsFixed(2)}',
      if (physicsSystem != null)
        'Gravity G': physicsSystem!.gravitationalConstant.toStringAsExponential(
          3,
        ),
    });
  }
}
