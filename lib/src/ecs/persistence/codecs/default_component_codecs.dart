import 'package:gamengine/src/ecs/components/transform.dart';
import 'package:gamengine/src/ecs/persistence/codecs/component_codec.dart';
import 'package:gamengine/src/ecs/persistence/serializers/world_state_serializer.dart';
import 'package:gamengine/src/physics/components/colliders/circle_collider.dart';
import 'package:gamengine/src/physics/components/colliders/rectangle_collider.dart';
import 'package:gamengine/src/physics/components/gravity_source.dart';
import 'package:gamengine/src/physics/components/rigid_body.dart';
import 'package:gamengine/src/render/components/animated_sprite.dart';
import 'package:vector_math/vector_math_64.dart';

class DefaultWorldComponentCodecs {
  static void register(WorldStateSerializer serializer) {
    serializer.registerCodec<Transform>(_TransformCodec());
    serializer.registerCodec<RigidBody>(_RigidBodyCodec());
    serializer.registerCodec<CircleCollider>(_CircleColliderCodec());
    serializer.registerCodec<RectangleCollider>(_RectangleColliderCodec());
    serializer.registerCodec<GravitySource>(_GravitySourceCodec());
    serializer.registerCodec<AnimatedSprite>(_AnimatedSpriteCodec());
  }
}

class _TransformCodec extends ComponentCodec<Transform> {
  @override
  String get typeId => 'ecs.transform';

  @override
  Transform decode(Map<String, Object?> data) {
    return Transform(
      position: _readVector2(data, 'position'),
      rotation: _readDouble(data, 'rotation', fallback: 0),
      scale: _readVector2(data, 'scale', fallback: Vector2.all(1)),
    );
  }

  @override
  Map<String, Object?> encode(Transform component) {
    return <String, Object?>{
      'position': _vector2ToList(component.position),
      'rotation': component.rotation,
      'scale': _vector2ToList(component.scale),
    };
  }
}

class _RigidBodyCodec extends ComponentCodec<RigidBody> {
  @override
  String get typeId => 'physics.rigidBody';

  @override
  RigidBody decode(Map<String, Object?> data) {
    final body = RigidBody(
      velocity: _readVector2(data, 'velocity'),
      mass: _readDouble(data, 'mass', fallback: 1),
      angularVelocity: _readDouble(data, 'angularVelocity', fallback: 0),
      linearDamping: _readDouble(data, 'linearDamping', fallback: 0),
      angularDamping: _readDouble(data, 'angularDamping', fallback: 0),
      gravityScale: _readDouble(data, 'gravityScale', fallback: 1),
      useGravity: _readBool(data, 'useGravity', fallback: true),
      isStatic: _readBool(data, 'isStatic', fallback: false),
      angularAcceleration: _readDouble(
        data,
        'angularAcceleration',
        fallback: 0,
      ),
      accumulatedTorque: _readDouble(data, 'accumulatedTorque', fallback: 0),
      momentOfInertia: _readDouble(data, 'momentOfInertia', fallback: 0),
      lockRotation: _readBool(data, 'lockRotation', fallback: false),
    );

    body.acceleration.setFrom(
      _readVector2(data, 'acceleration', fallback: Vector2.zero()),
    );
    body.accumulatedForce.setFrom(
      _readVector2(data, 'accumulatedForce', fallback: Vector2.zero()),
    );

    return body;
  }

  @override
  Map<String, Object?> encode(RigidBody component) {
    return <String, Object?>{
      'velocity': _vector2ToList(component.velocity),
      'acceleration': _vector2ToList(component.acceleration),
      'accumulatedForce': _vector2ToList(component.accumulatedForce),
      'mass': component.mass,
      'angularVelocity': component.angularVelocity,
      'angularAcceleration': component.angularAcceleration,
      'accumulatedTorque': component.accumulatedTorque,
      'momentOfInertia': component.momentOfInertia,
      'lockRotation': component.lockRotation,
      'linearDamping': component.linearDamping,
      'angularDamping': component.angularDamping,
      'gravityScale': component.gravityScale,
      'useGravity': component.useGravity,
      'isStatic': component.isStatic,
    };
  }
}

class _CircleColliderCodec extends ComponentCodec<CircleCollider> {
  @override
  String get typeId => 'physics.circleCollider';

  @override
  CircleCollider decode(Map<String, Object?> data) {
    return CircleCollider(
      radius: _readDouble(data, 'radius', fallback: 1),
      collisionLayer: _readInt(
        data,
        'collisionLayer',
        fallback: CircleCollider.defaultCollisionLayer,
      ),
      collisionMask: _readInt(
        data,
        'collisionMask',
        fallback: CircleCollider.defaultCollisionMask,
      ),
      restitution: _readDouble(data, 'restitution', fallback: 0.4),
      staticFriction: _readDouble(data, 'staticFriction', fallback: 0.6),
      dynamicFriction: _readDouble(data, 'dynamicFriction', fallback: 0.45),
      enabled: _readBool(data, 'enabled', fallback: true),
    );
  }

  @override
  Map<String, Object?> encode(CircleCollider component) {
    return <String, Object?>{
      'radius': component.radius,
      'collisionLayer': component.collisionLayer,
      'collisionMask': component.collisionMask,
      'restitution': component.restitution,
      'staticFriction': component.staticFriction,
      'dynamicFriction': component.dynamicFriction,
      'enabled': component.enabled,
    };
  }
}

class _RectangleColliderCodec extends ComponentCodec<RectangleCollider> {
  @override
  String get typeId => 'physics.rectangleCollider';

  @override
  RectangleCollider decode(Map<String, Object?> data) {
    return RectangleCollider(
      halfWidth: _readDouble(data, 'halfWidth', fallback: 1),
      halfHeight: _readDouble(data, 'halfHeight', fallback: 1),
      collisionLayer: _readInt(
        data,
        'collisionLayer',
        fallback: RectangleCollider.defaultCollisionLayer,
      ),
      collisionMask: _readInt(
        data,
        'collisionMask',
        fallback: RectangleCollider.defaultCollisionMask,
      ),
      restitution: _readDouble(data, 'restitution', fallback: 0.4),
      staticFriction: _readDouble(data, 'staticFriction', fallback: 0.6),
      dynamicFriction: _readDouble(data, 'dynamicFriction', fallback: 0.45),
      enabled: _readBool(data, 'enabled', fallback: true),
    );
  }

  @override
  Map<String, Object?> encode(RectangleCollider component) {
    return <String, Object?>{
      'halfWidth': component.halfWidth,
      'halfHeight': component.halfHeight,
      'collisionLayer': component.collisionLayer,
      'collisionMask': component.collisionMask,
      'restitution': component.restitution,
      'staticFriction': component.staticFriction,
      'dynamicFriction': component.dynamicFriction,
      'enabled': component.enabled,
    };
  }
}

class _GravitySourceCodec extends ComponentCodec<GravitySource> {
  @override
  String get typeId => 'physics.gravitySource';

  @override
  GravitySource decode(Map<String, Object?> data) {
    return GravitySource(
      mass: _readDouble(data, 'mass', fallback: 0),
      minDistance: _readDouble(data, 'minDistance', fallback: 1),
      enabled: _readBool(data, 'enabled', fallback: true),
    );
  }

  @override
  Map<String, Object?> encode(GravitySource component) {
    return <String, Object?>{
      'mass': component.mass,
      'minDistance': component.minDistance,
      'enabled': component.enabled,
    };
  }
}

class _AnimatedSpriteCodec extends ComponentCodec<AnimatedSprite> {
  @override
  String get typeId => 'render.animatedSprite';

  @override
  AnimatedSprite decode(Map<String, Object?> data) {
    final animatedSprite = AnimatedSprite(
      frameWidth: _readInt(data, 'frameWidth', fallback: 0),
      frameHeight: _readInt(data, 'frameHeight', fallback: 0),
      frameCount: _readInt(data, 'frameCount', fallback: 0),
      firstFrame: _readInt(data, 'firstFrame', fallback: 0),
      framesPerSecond: _readDouble(data, 'framesPerSecond', fallback: 0),
      loop: _readBool(data, 'loop', fallback: true),
      playing: _readBool(data, 'playing', fallback: true),
    );

    animatedSprite.currentFrame = _readInt(data, 'currentFrame', fallback: 0);
    animatedSprite.elapsedTime = _readDouble(data, 'elapsedTime', fallback: 0);
    return animatedSprite;
  }

  @override
  Map<String, Object?> encode(AnimatedSprite component) {
    return {
      'frameWidth': component.frameWidth,
      'frameHeight': component.frameHeight,
      'frameCount': component.frameCount,
      'firstFrame': component.firstFrame,
      'framesPerSecond': component.framesPerSecond,
      'loop': component.loop,
      'playing': component.playing,
      'currentFrame': component.currentFrame,
      'elapsedTime': component.elapsedTime,
    };
  }
}

List<Object?> _vector2ToList(Vector2 value) => <Object?>[value.x, value.y];

Vector2 _readVector2(
  Map<String, Object?> data,
  String key, {
  Vector2? fallback,
}) {
  final value = data[key];
  if (value is List && value.length >= 2) {
    final x = (value[0] as num?)?.toDouble();
    final y = (value[1] as num?)?.toDouble();
    if (x != null && y != null) {
      return Vector2(x, y);
    }
  }
  if (fallback != null) {
    return Vector2.copy(fallback);
  }
  return Vector2.zero();
}

double _readDouble(
  Map<String, Object?> data,
  String key, {
  required double fallback,
}) {
  final value = data[key];
  return value is num ? value.toDouble() : fallback;
}

int _readInt(Map<String, Object?> data, String key, {required int fallback}) {
  final value = data[key];
  return value is num ? value.toInt() : fallback;
}

bool _readBool(
  Map<String, Object?> data,
  String key, {
  required bool fallback,
}) {
  final value = data[key];
  return value is bool ? value : fallback;
}
