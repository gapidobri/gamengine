abstract class WorldStateFormat<T> {
  String get formatId;

  T encode(Map<String, Object?> worldState);

  Map<String, Object?> decode(T serialized);
}
