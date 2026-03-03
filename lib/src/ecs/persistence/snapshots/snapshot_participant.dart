abstract class SnapshotParticipant {
  String get snapshotId;

  Object? exportSnapshot();

  void importSnapshot(Object? snapshot);
}
