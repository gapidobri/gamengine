import 'dart:math';

extension IterableExtension<T> on Iterable<T> {
  T? random([Random? random]) =>
      isEmpty ? null : elementAt((random ?? Random()).nextInt(length));
}
