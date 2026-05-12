import 'package:gamengine/src/ecs/components/component.dart';

/// Optional per-entity override for physics debug rendering.
///
/// - `enabled == null`: follow global [PhysicsDebugSettings.enabled]
/// - `enabled == true`: force show debug for this entity
/// - `enabled == false`: force hide debug for this entity
class PhysicsDebugOverride extends Component {
  PhysicsDebugOverride({this.enabled});

  bool? enabled;
}
