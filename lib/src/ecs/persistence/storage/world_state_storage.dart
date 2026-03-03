abstract class WorldStateStorage<TSerialized> {
  Future<void> write(String location, TSerialized data);

  Future<TSerialized> read(String location);
}
