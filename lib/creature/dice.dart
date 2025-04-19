import 'package:lcs_new_age/utils/lcsrandom.dart';

enum Dice {
  d20,
  r3d6,
  r2d6;

  int roll() {
    switch (this) {
      case Dice.d20:
        return lcsRandom(20) + 1;
      case Dice.r3d6:
        return lcsRandom(6) + lcsRandom(6) + lcsRandom(6) + 3;
      case Dice.r2d6:
        return (lcsRandom(6) + 1) + (lcsRandom(6) + 1);
    }
  }

  int take10() {
    switch (this) {
      case Dice.d20:
        return 10;
      case Dice.r3d6:
        return 10;
      case Dice.r2d6:
        return 7;
    }
  }
}
