import 'dart:math';

extension RandomExtension on Random {
  double nextDoubleBetween(double min, double max) =>
      (nextDouble() * (max - min)) + min;
}
