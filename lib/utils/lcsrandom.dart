import 'dart:math';

Random _rng = Random();
int get nextRngSeed => _rng.nextInt(0x7fffffff);
set nextRngSeed(int value) => reseedRNG(seed: value);

int rollInterval(int min, int max) {
  return min + lcsRandom(max - min);
}

extension RollInterval on (int, int) {
  int roll() => rollInterval($1, $2);
  double rollDouble() => rollIntervalDouble($1.toDouble(), $2.toDouble());
}

double rollIntervalDouble(double min, double max) {
  return min + lcsRandomDouble(max - min);
}

extension RollIntervalDouble on (double, double) {
  double roll() => rollIntervalDouble($1, $2);
}

void reseedRNG({int? seed}) => _rng = Random(seed);
int lcsRandom(int max) {
  if (max < 0) {
    return -_rng.nextInt(-max);
  }
  if (max > 0) {
    return _rng.nextInt(max);
  }
  return 0;
}

bool oneIn(int chance) => lcsRandom(chance) <= 0;

double lcsRandomDouble(double max) {
  if (max < 0) {
    return -_rng.nextDouble() * max;
  }
  if (max > 0) {
    return _rng.nextDouble() * max;
  }
  return 0;
}

extension IterableExtension<T> on Iterable<T> {
  T get random => elementAt(_rng.nextInt(length));
  T? get randomOrNull => isEmpty ? null : elementAt(_rng.nextInt(length));
  T randomWhere(bool Function(T) test) => where(test).random;
}

extension ListExtension<T> on List<T> {
  T get random => this[_rng.nextInt(length)];
  T? get randomOrNull => isEmpty ? null : this[_rng.nextInt(length)];
  T randomSeeded(int seed) => this[Random(seed).nextInt(length)];
  T randomPop() => removeAt(_rng.nextInt(length));
}

T lcsRandomWeighted<T>(Map<T, num> cr) {
  double sum = cr.values.fold(0, (a, b) => a + b);

  if (sum > 0) {
    double roll = lcsRandomDouble(sum);
    int sel = 0;
    while (roll >= 0) {
      roll -= cr.values.elementAt(sel);
      sel++;
    }
    return cr.keys.elementAt(sel - 1);
  } else {
    return cr.keys.first;
  }
}
