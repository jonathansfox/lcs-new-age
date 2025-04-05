import 'package:collection/collection.dart';
import 'package:lcs_new_age/creature/creature_type_xml.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/attack.dart';
import 'package:lcs_new_age/items/weapon_type.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/saveload/parse_value.dart';
import 'package:xml/xml.dart';

void parseWeaponType(WeaponType weapon, XmlElement xml) {
  for (XmlElement element in xml.childElements) {
    String key = element.name.local;
    switch (key) {
      case "name":
        weapon.name = element.innerText;
      case "name_future":
        weapon.nameFuture = element.innerText;
      case "name_large_subtype":
        weapon.largeSubtypeName = element.innerText;
      case "name_small_subtype":
        weapon.smallSubtypeName = element.innerText;
      case "name_large_subtype_future":
        weapon.futureLargeSubtypeName = element.innerText;
      case "name_small_subtype_future":
        weapon.futureSmallSubtypeName = element.innerText;
      case "shortname":
        weapon.shortName = element.innerText;
      case "shortname_future":
        weapon.futureShortName = element.innerText;
      case "description":
        weapon.description = element.innerText;
      case "looks_dangerous":
        bool? looksDangerous = parseBool(element.innerText);
        if (looksDangerous != null) {
          weapon.threatening = looksDangerous;
          weapon.canThreatenHostages = looksDangerous;
          weapon.canTakeHostages = looksDangerous;
          weapon.protectsAgainstKidnapping = looksDangerous;
          weapon.suspicious = looksDangerous;
        }
      case "suspicious":
        weapon.suspicious = parseBool(element.innerText) ?? weapon.suspicious;
      case "can_take_hostages":
        weapon.canTakeHostages =
            parseBool(element.innerText) ?? weapon.canTakeHostages;
      case "threatening":
        weapon.threatening = parseBool(element.innerText) ?? weapon.threatening;
      case "can_threaten_hostages":
        weapon.canThreatenHostages =
            parseBool(element.innerText) ?? weapon.canThreatenHostages;
      case "protects_against_kidnapping":
        weapon.protectsAgainstKidnapping =
            parseBool(element.innerText) ?? weapon.protectsAgainstKidnapping;
      case "instrument":
        weapon.instrument = parseBool(element.innerText) ?? weapon.instrument;
      case "graffiti":
        weapon.canGraffiti = parseBool(element.innerText) ?? weapon.canGraffiti;
      case "banned_at_gun_control":
        weapon.bannedAtGunControl =
            parseAlignment(element.innerText) ?? weapon.bannedAtGunControl;
      case "price":
        weapon.price = int.tryParse(element.innerText) ?? weapon.price;
        if (weapon.fenceValue == 0) weapon.fenceValue = weapon.price * 0.25;
      case "fencevalue":
        weapon.fenceValue =
            double.tryParse(element.innerText) ?? weapon.fenceValue;
      case "auto_break_locks":
        weapon.autoBreakLock =
            parseBool(element.innerText) ?? weapon.autoBreakLock;
      case "size":
        weapon.size = int.tryParse(element.innerText) ?? weapon.size;
      case "attack":
        weapon.attacks.add(parseAttack(element));
      case "magazine_size":
        weapon.ammoCapacity =
            int.tryParse(element.innerText) ?? weapon.ammoCapacity;
      case "ammo_plus_one":
        weapon.canKeepOneInTheChamber =
            parseBool(element.innerText) ?? weapon.canKeepOneInTheChamber;
      default:
        debugPrint("Unknown key $key in weapon type ${weapon.name}");
    }
  }
}

Attack parseAttack(XmlElement element) {
  Attack attack = Attack();
  for (XmlAttribute a in element.attributes) {
    switch (a.name.local) {
      case "preset":
        switch (a.value) {
          case "FIRE_GUN":
            attack.priority = 1;
            attack.ranged = true;
            attack.attackDescription.add("shoots at");
            attack.skill = Skill.firearms;
            attack.shoots = true;
            attack.bleeds = true;
          case "PISTOL_WHIP":
            attack.priority = 2;
            attack.attackDescription.add("swings at");
            attack.skill = Skill.martialArts;
            attack.bruises = true;
            attack.damage = 15;
          case "BUTT_STROKE":
            attack.priority = 2;
            attack.attackDescription.add("swings at");
            attack.skill = Skill.martialArts;
            attack.bruises = true;
            attack.damage = 25;
        }
    }
  }
  for (XmlElement e in element.childElements) {
    switch (e.name.local) {
      case "priority":
        attack.priority = int.tryParse(e.innerText) ?? attack.priority;
      case "ranged":
        attack.ranged = parseBool(e.innerText) ?? attack.ranged;
      case "thrown":
        attack.thrown = parseBool(e.innerText) ?? attack.thrown;
      case "cartridge":
        attack.cartridge = e.innerText;
      case "initiative":
        attack.initiative = int.tryParse(e.innerText) ?? attack.initiative;
      case "attack_description":
        attack.attackDescription.add(e.innerText);
      case "hit_description":
        attack.hitDescription = e.innerText;
      case "always_describe_hit":
        attack.alwaysDescribeHit =
            parseBool(e.innerText) ?? attack.alwaysDescribeHit;
      case "hit_punctuation":
        attack.hitPunctuation = e.innerText;
      case "skill":
        attack.skill = parseSkill(e.innerText) ?? attack.skill;
      case "accuracy_bonus":
        attack.accuracyBonus =
            int.tryParse(e.innerText) ?? attack.accuracyBonus;
      case "can_backstab":
        attack.canBackstab = parseBool(e.innerText) ?? attack.canBackstab;
      case "number_attacks":
        attack.numberOfAttacks =
            int.tryParse(e.innerText) ?? attack.numberOfAttacks;
      case "successive_attacks_difficulty":
        attack.successiveAttacksDifficulty =
            int.tryParse(e.innerText) ?? attack.successiveAttacksDifficulty;
      case "strentgh_min":
      case "strength_min":
        attack.strengthMin = int.tryParse(e.innerText) ?? attack.strengthMin;
      case "strength_max":
        attack.strengthMax = int.tryParse(e.innerText) ?? attack.strengthMax;
      case "damage":
        attack.damage = int.tryParse(e.innerText) ?? attack.damage;
      case "bruises":
        attack.bruises = parseBool(e.innerText) ?? attack.bruises;
      case "tears":
        attack.tears = parseBool(e.innerText) ?? attack.tears;
      case "cuts":
        attack.cuts = parseBool(e.innerText) ?? attack.cuts;
      case "burns":
        attack.burns = parseBool(e.innerText) ?? attack.burns;
      case "shoots":
        attack.shoots = parseBool(e.innerText) ?? attack.shoots;
      case "bleeding":
        attack.bleeds = parseBool(e.innerText) ?? attack.bleeds;
      case "stuns":
        attack.stuns = parseBool(e.innerText) ?? attack.stuns;
      case "alignment_restriction":
        attack.alignmentRestriction = Alignment.values
                .firstWhereOrNull((v) => v.name == e.innerText.toLowerCase()) ??
            attack.alignmentRestriction;
      case "severtype":
        attack.severType = SeverType.values
                .firstWhereOrNull((v) => v.name == e.innerText.toLowerCase()) ??
            attack.severType;
      case "social_damage":
        attack.socialDamage = parseBool(e.innerText) ?? attack.socialDamage;
      case "no_damage_reduction_for_limbs_chance":
        attack.noDamageReductionForLimbsChance =
            int.tryParse(e.innerText) ?? attack.noDamageReductionForLimbsChance;
      case "fire":
        Fire fire = Fire();
        for (XmlElement c in e.childElements) {
          switch (c.name.local) {
            case "chance":
              fire.chance = int.tryParse(c.innerText) ?? fire.chance;
            case "chance_causes_debris":
              fire.chanceCausesDebris =
                  int.tryParse(c.innerText) ?? fire.chanceCausesDebris;
          }
        }
        attack.fire = fire;
      default:
        debugPrint("Unknown key ${e.name.local} in attack");
    }
  }
  return attack;
}
