import 'dart:ui';

import 'package:gamengine/src/ecs/components/transform.dart';
import 'package:gamengine/src/ecs/persistence/codecs/component_codec.dart';
import 'package:gamengine/src/ecs/persistence/serializers/world_state_serializer.dart';
import 'package:gamengine/src/physics/components/collider.dart';
import 'package:gamengine/src/physics/components/gravity_source.dart';
import 'package:gamengine/src/physics/components/rigid_body.dart';
import 'package:gamengine/src/render/components/animated_sprite.dart';
import 'package:gamengine/src/render/components/particle_emitter.dart';
import 'package:vector_math/vector_math_64.dart';

class DefaultWorldComponentCodecs {
  static void register(WorldStateSerializer serializer) {
    serializer.registerCodec<Transform>(_TransformCodec());
    serializer.registerCodec<RigidBody>(_RigidBodyCodec());
    serializer.registerCodec<Collider>(_ColliderCodec());
    serializer.registerCodec<GravitySource>(_GravitySourceCodec());
    serializer.registerCodec<ParticleEmitter>(_ParticleEmitterCodec());
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
    );

    body.acceleration.setFrom(
      _readVector2(data, 'acceleration', fallback: Vector2.zero()),
    );
    body.accumulatedForce.setFrom(
      _readVector2(data, 'accumulatedForce', fallback: Vector2.zero()),
    );
    body.lastAppliedForce.setFrom(
      _readVector2(data, 'lastAppliedForce', fallback: Vector2.zero()),
    );

    return body;
  }

  @override
  Map<String, Object?> encode(RigidBody component) {
    return <String, Object?>{
      'velocity': _vector2ToList(component.velocity),
      'acceleration': _vector2ToList(component.acceleration),
      'accumulatedForce': _vector2ToList(component.accumulatedForce),
      'lastAppliedForce': _vector2ToList(component.lastAppliedForce),
      'mass': component.mass,
      'angularVelocity': component.angularVelocity,
      'linearDamping': component.linearDamping,
      'angularDamping': component.angularDamping,
      'gravityScale': component.gravityScale,
      'useGravity': component.useGravity,
      'isStatic': component.isStatic,
    };
  }
}

class _ColliderCodec extends ComponentCodec<Collider> {
  @override
  String get typeId => 'physics.collider';

  @override
  Collider decode(Map<String, Object?> data) {
    return Collider(
      radius: _readDouble(data, 'radius', fallback: 1),
      restitution: _readDouble(data, 'restitution', fallback: 0.4),
      staticFriction: _readDouble(data, 'staticFriction', fallback: 0.6),
      dynamicFriction: _readDouble(data, 'dynamicFriction', fallback: 0.45),
      enabled: _readBool(data, 'enabled', fallback: true),
    );
  }

  @override
  Map<String, Object?> encode(Collider component) {
    return <String, Object?>{
      'radius': component.radius,
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

class _ParticleEmitterCodec extends ComponentCodec<ParticleEmitter> {
  @override
  String get typeId => 'render.particleEmitter';

  @override
  ParticleEmitter decode(Map<String, Object?> data) {
    final emitter = ParticleEmitter(
      enabled: _readBool(data, 'enabled', fallback: true),
      emissionRate: _readDouble(data, 'emissionRate', fallback: 0),
      burstCount: _readInt(data, 'burstCount', fallback: 0),
      spread: _readDouble(data, 'spread', fallback: 0.4),
      speedMin: _readDouble(data, 'speedMin', fallback: 10),
      speedMax: _readDouble(data, 'speedMax', fallback: 30),
      lifetimeMin: _readDouble(data, 'lifetimeMin', fallback: 0.2),
      lifetimeMax: _readDouble(data, 'lifetimeMax', fallback: 0.8),
      sizeStartMin: _readDouble(data, 'sizeStartMin', fallback: 1),
      sizeStartMax: _readDouble(data, 'sizeStartMax', fallback: 2.5),
      sizeEndMin: _readDouble(data, 'sizeEndMin', fallback: 0),
      sizeEndMax: _readDouble(data, 'sizeEndMax', fallback: 1),
      drag: _readDouble(data, 'drag', fallback: 0),
      z: _readInt(data, 'z', fallback: 1),
      localOffset: _readVector2(data, 'localOffset'),
      localDirection: _readVector2(
        data,
        'localDirection',
        fallback: Vector2(0, 1),
      ),
      alignToRotation: _readBool(data, 'alignToRotation', fallback: true),
      colorStart: Color(
        _readInt(
          data,
          'colorStart',
          fallback: const Color(0xFFFFE08A).toARGB32(),
        ),
      ),
      colorEnd: Color(
        _readInt(
          data,
          'colorEnd',
          fallback: const Color(0x00FF6A00).toARGB32(),
        ),
      ),
    );

    emitter.spawnRemainder = _readDouble(data, 'spawnRemainder', fallback: 0);
    return emitter;
  }

  @override
  Map<String, Object?> encode(ParticleEmitter component) {
    return <String, Object?>{
      'enabled': component.enabled,
      'emissionRate': component.emissionRate,
      'burstCount': component.burstCount,
      'spread': component.spread,
      'speedMin': component.speedMin,
      'speedMax': component.speedMax,
      'lifetimeMin': component.lifetimeMin,
      'lifetimeMax': component.lifetimeMax,
      'sizeStartMin': component.sizeStartMin,
      'sizeStartMax': component.sizeStartMax,
      'sizeEndMin': component.sizeEndMin,
      'sizeEndMax': component.sizeEndMax,
      'drag': component.drag,
      'z': component.z,
      'localOffset': _vector2ToList(component.localOffset),
      'localDirection': _vector2ToList(component.localDirection),
      'alignToRotation': component.alignToRotation,
      'colorStart': component.colorStart.toARGB32(),
      'colorEnd': component.colorEnd.toARGB32(),
      'spawnRemainder': component.spawnRemainder,
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
