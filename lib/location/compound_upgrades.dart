import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';

/// Single source of truth for the purchasable safehouse upgrades and their
/// prices. Both the investment screen (`investInLocation`) and anything that
/// needs to value installed upgrades (e.g. the medical industry liquidating a
/// dismantled safehouse) read prices from here, so the two can never drift.
enum CompoundUpgrade {
  fortify,
  cameras,
  boobyTraps,
  bollards,
  generator,
  solarPanels,
  aaGun,
  videoRoom,
  hackerDen,
  businessFront;

  /// Purchase price in dollars at the current law levels.
  int get price {
    switch (this) {
      case CompoundUpgrade.fortify:
      case CompoundUpgrade.cameras:
      case CompoundUpgrade.videoRoom:
        return 2000;
      case CompoundUpgrade.boobyTraps:
      case CompoundUpgrade.bollards:
      case CompoundUpgrade.generator:
      case CompoundUpgrade.businessFront:
        return 3000;
      case CompoundUpgrade.hackerDen:
        return 4000;
      case CompoundUpgrade.solarPanels:
        return switch (laws[Law.pollution]!) {
          DeepAlignment.archConservative => 60000,
          DeepAlignment.conservative => 40000,
          DeepAlignment.moderate => 30000,
          DeepAlignment.liberal => 20000,
          DeepAlignment.eliteLiberal => 10000,
        };
      case CompoundUpgrade.aaGun:
        return laws[Law.gunControl] == DeepAlignment.archConservative
            ? 35000
            : 200000;
    }
  }

  /// Whether this upgrade is currently installed at [loc].
  bool isActiveOn(Site loc) {
    switch (this) {
      case CompoundUpgrade.fortify:
        return loc.compound.fortified;
      case CompoundUpgrade.cameras:
        return loc.compound.cameras;
      case CompoundUpgrade.boobyTraps:
        return loc.compound.boobyTraps;
      case CompoundUpgrade.bollards:
        return loc.compound.bollards;
      case CompoundUpgrade.generator:
        return loc.compound.generator;
      case CompoundUpgrade.solarPanels:
        return loc.compound.solarPanels;
      case CompoundUpgrade.aaGun:
        return loc.compound.aaGun;
      case CompoundUpgrade.videoRoom:
        return loc.compound.videoRoom;
      case CompoundUpgrade.hackerDen:
        return loc.compound.hackerDen;
      case CompoundUpgrade.businessFront:
        return loc.businessFront;
    }
  }

  /// Remove this upgrade from [loc] (used when a safehouse is dismantled).
  void removeFrom(Site loc) {
    switch (this) {
      case CompoundUpgrade.fortify:
        loc.compound.fortified = false;
      case CompoundUpgrade.cameras:
        loc.compound.cameras = false;
      case CompoundUpgrade.boobyTraps:
        loc.compound.boobyTraps = false;
      case CompoundUpgrade.bollards:
        loc.compound.bollards = false;
      case CompoundUpgrade.generator:
        loc.compound.generator = false;
      case CompoundUpgrade.solarPanels:
        loc.compound.solarPanels = false;
      case CompoundUpgrade.aaGun:
        loc.compound.aaGun = false;
      case CompoundUpgrade.videoRoom:
        loc.compound.videoRoom = false;
      case CompoundUpgrade.hackerDen:
        loc.compound.hackerDen = false;
      case CompoundUpgrade.businessFront:
        loc.businessFront = false;
    }
  }
}

/// Total purchase value of every upgrade currently installed at [loc].
int compoundUpgradeValue(Site loc) => CompoundUpgrade.values
    .where((u) => u.isActiveOn(loc))
    .fold(0, (total, u) => total + u.price);
