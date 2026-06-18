import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/item_type.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/views.dart';

Map<String, FlagType> flagTypes = {};

/// The kind of cause a flag represents. The category fully determines both the
/// political issue (View) the flag affects during a siege and how it is used to
/// protest (national flags are burned, everything else is waved/flown).
enum FlagCategory {
  national,
  pride,
  anarchist,
  labor,
  feminist,
  environmentalist,
  civilRights;

  View get view => switch (this) {
    FlagCategory.national => View.freeSpeech,
    FlagCategory.pride => View.lgbtRights,
    FlagCategory.anarchist => View.policeBehavior,
    FlagCategory.labor => View.sweatshops,
    FlagCategory.feminist => View.womensRights,
    FlagCategory.environmentalist => View.pollution,
    FlagCategory.civilRights => View.civilRights,
  };

  Law get primaryLaw => switch (this) {
    FlagCategory.national => Law.flagBurning,
    FlagCategory.pride => Law.lgbtRights,
    FlagCategory.anarchist => Law.policeReform,
    FlagCategory.labor => Law.labor,
    FlagCategory.feminist => Law.genderEquality,
    FlagCategory.environmentalist => Law.pollution,
    FlagCategory.civilRights => Law.civilRights,
  };

  /// National flags are burned in protest; everything else is flown.
  bool get burns => this == FlagCategory.national;
}

class FlagType extends ItemType {
  FlagType(String id) : super(id) {
    flagTypes[id] = this;
  }

  /// SVG file name within assets/flags/.
  String asset = "";
  FlagCategory category = FlagCategory.pride;

  /// Flavor text shown in flag menus.
  String description = "";

  /// If false, the flag cannot be bought for $20 (crafting still allowed).
  bool buyable = true;

  /// Minimum tailoring skill to craft. -1 means uncraftable.
  int makeDifficulty = -1;
  int makePrice = 0;

  String? _shortName;
  String get shortName => _shortName ?? name;
  set shortName(String value) => _shortName = value;

  View get view => category.view;
  bool get burns => category.burns;
  String get assetPath => 'assets/flags/$asset';

  int makeDifficultyFor(Creature cr) =>
      makeDifficulty - cr.skill(Skill.tailoring);
}

bool flagLawBanned(FlagType flag) {
  if (flag.category == FlagCategory.national) return false;
  return laws[flag.category.primaryLaw] == DeepAlignment.archConservative &&
      laws[Law.freeSpeech] == DeepAlignment.archConservative;
}

bool flagCanBePurchased(FlagType flag) {
  if (!flag.buyable) return false;
  if (flag.category == FlagCategory.national) return true;
  return !flagLawBanned(flag);
}

int flagSecrecyWhenFlying(FlagType? flag) {
  // Negative values are heat, positive values are secrecy
  int secrecy = 0;
  if (flag != null) {
    if (flag.category == FlagCategory.national) {
      if (laws[Law.flagBurning] == DeepAlignment.archConservative) {
        // What a good American patriot you are!
        secrecy = 5;
      } else {
        secrecy = 0;
      }
    } else {
      if (laws[flag.category.primaryLaw] == DeepAlignment.archConservative) {
        if (laws[Law.freeSpeech] == DeepAlignment.archConservative) {
          secrecy = -15;
        } else {
          secrecy = -5;
        }
      } else {
        secrecy = 0;
      }
    }
  }
  return secrecy;
}
