import 'dart:math';

import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/body.dart';
import 'package:lcs_new_age/creature/conversion.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/clothing.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/sitemode/stealth.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Alignment nonConservativeAlignment() {
  if (oneIn(2)) return Alignment.moderate;
  return Alignment.liberal;
}

void giveCivilianWeapon(Creature cr) {
  if (cr.align == Alignment.liberal) return;
  if (laws[Law.gunControl] == DeepAlignment.moderate && oneIn(30)) {
    cr.giveWeaponAndAmmo("WEAPON_22_HANDGUN", 1);
  } else if (laws[Law.gunControl] == DeepAlignment.conservative && oneIn(10)) {
    cr.giveWeaponAndAmmo("WEAPON_22_HANDGUN", 2);
  } else if (laws[Law.gunControl] == DeepAlignment.archConservative) {
    if (oneIn(10)) {
      cr.giveWeaponAndAmmo("WEAPON_9MM_HANDGUN", 2);
    } else if (oneIn(9)) {
      cr.giveWeaponAndAmmo("WEAPON_45_HANDGUN", 2);
    } else if (oneIn(8)) {
      cr.giveWeaponAndAmmo("WEAPON_22_HANDGUN", 2);
    }
  }
}

void applyHardcodedCreatureTypeStuff(Creature cr, CreatureType type) {
  switch (type.id) {
    case CreatureTypeIds.bouncer:
      if (mode == GameMode.site && activeSite?.hasHighSecurity == true) {
        cr.name = "Huge Bouncer";
        cr.rawSkill[Skill.martialArts] = lcsRandom(3) + 3;
      }
      if (laws[Law.gunControl] == DeepAlignment.archConservative) {
        cr.giveWeaponAndAmmo("WEAPON_MP5", 4);
      } else if (laws[Law.gunControl] == DeepAlignment.conservative) {
        cr.giveWeaponAndAmmo("WEAPON_9MM_HANDGUN", 4);
      } else if (laws[Law.gunControl] == DeepAlignment.moderate) {
        cr.giveWeaponAndAmmo("WEAPON_22_HANDGUN", 4);
      } else {
        cr.giveWeaponAndAmmo("WEAPON_NIGHTSTICK", 0);
      }
      if (disguisesite(siteType)) {
        cr.align = Alignment.conservative;
        cr.infiltration = 0.1 * lcsRandom(4);
      } else {
        cr.align = Alignment.moderate;
      }
    case CreatureTypeIds.securityGuard:
      if (laws[Law.gunControl] == DeepAlignment.archConservative) {
        cr.giveWeaponAndAmmo("WEAPON_MP5", 4);
      } else if (laws[Law.gunControl]!.index < DeepAlignment.liberal.index) {
        cr.giveWeaponAndAmmo("WEAPON_9MM_HANDGUN", 4);
      } else {
        cr.giveWeaponAndAmmo("WEAPON_NIGHTSTICK", 0);
      }
    case CreatureTypeIds.eminentScientist:
    case CreatureTypeIds.labTech:
      giveCivilianWeapon(cr);
      if (cr.equippedWeapon == null && oneIn(2)) {
        cr.giveWeaponAndAmmo("WEAPON_SYRINGE", 0);
      }
    case CreatureTypeIds.conservativeJudge:
      if (laws[Law.gunControl] == DeepAlignment.archConservative && oneIn(3)) {
        cr.giveWeaponAndAmmo("WEAPON_44_REVOLVER", 4);
      } else if (oneIn(2)) {
        cr.giveWeaponAndAmmo("WEAPON_GAVEL", 0);
      }
    case CreatureTypeIds.corporateCEO:
      cr.properName = generateFullName(Gender.whiteMalePatriarch).firstLast;
      cr.name = "CEO ${cr.properName}";
      cr.alreadyNamed = true;
    case CreatureTypeIds.nonUnionWorker:
      giveCivilianWeapon(cr);
      if (cr.equippedWeapon == null) {
        cr.giveWeaponAndAmmo("WEAPON_CHAIN", 0);
      }
      if (cr.align == Alignment.liberal) {
        if (oneIn(2)) {
          cr.align = Alignment.moderate;
        } else {
          cr.align = Alignment.conservative;
        }
      }
    case CreatureTypeIds.sweatshopWorker:
      criminalize(cr, Crime.illegalEntry);
    case CreatureTypeIds.tank:
      cr.body = TankBody();
    case CreatureTypeIds.angryRuralMob:
      cr.name = ruralMobNames.random;
    case CreatureTypeIds.cop:
      if (laws[Law.policeReform] == DeepAlignment.eliteLiberal &&
          cr.align == Alignment.liberal &&
          oneIn(3)) {
        cr.align = Alignment.moderate;
        cr.name = "Police Negotiator";
        cr.rawSkill[Skill.persuasion] = lcsRandom(4) + 3;
        cr.rawSkill[Skill.firearms] = lcsRandom(3) + 1;
      } else {
        if (oneIn(10)) {
          cr.giveWeaponAndAmmo("WEAPON_PUMP_SHOTGUN", 4);
        } else {
          cr.giveWeaponAndAmmo("WEAPON_9MM_HANDGUN", 4);
        }
        cr.reload(false);
        cr.equippedClothing = Clothing("CLOTHING_POLICEUNIFORM",
            stackSize: 1, armorId: "ARMOR_HIDDEN");
        cr.align = Alignment.conservative;
        cr.rawSkill[Skill.firearms] = lcsRandom(4) + 3;
        cr.rawSkill[Skill.martialArts] = lcsRandom(2) + 3;
      }
    case CreatureTypeIds.firefighter:
      if (fahrenheit451) {
        cr.giveWeaponAndAmmo("WEAPON_FLAMETHROWER", 4);
        cr.reload(false);
        cr.rawSkill[Skill.heavyWeapons] = lcsRandom(3) + 2;
        cr.name = "Fireman";
        cr.align = Alignment.conservative;
      } else {
        cr.giveWeaponAndAmmo("WEAPON_AXE", 0);
        cr.rawSkill[Skill.martialArts] = lcsRandom(3) + 2;
        cr.name = "Firefighter";
      }
      if (siteAlarm) {
        // Respond to emergencies in bunker gear
        cr.giveClothingType("CLOTHING_BUNKERGEAR");
      }
    case CreatureTypeIds.ccsVigilante:
      switch (lcsRandom(5) + ccsState.index) {
        case 0:
        case 1:
        case 2:
          cr.giveWeaponAndAmmo("WEAPON_9MM_HANDGUN", 7);
        case 3:
          cr.giveWeaponAndAmmo("WEAPON_44_REVOLVER", 7);
        case 4:
          cr.giveWeaponAndAmmo("WEAPON_PUMP_SHOTGUN", 7);
        case 5:
          cr.giveWeaponAndAmmo("WEAPON_AR15", 7);
        case 6:
          cr.giveWeaponAndAmmo("WEAPON_AR15", 7);
          cr.giveClothingType("CLOTHING_ARMYARMOR");
        default:
          cr.giveWeaponAndAmmo("WEAPON_M4", 7);
          cr.giveClothingType("CLOTHING_ARMYARMOR");
      }
      if (mode == GameMode.site) {
        nameCCSMember(cr);
      }
    case CreatureTypeIds.ccsArchConservative:
      if (activeSiteUnderSiege) {
        cr.name = "CCS Team Leader";
      } else if (activeSite?.type == SiteType.bunker) {
        cr.name = "CCS Founder";
      } else {
        cr.name = "CCS Lieutenant";
      }
    case CreatureTypeIds.genetic:
      if (activeSite?.type == SiteType.ceoHouse) {
        cr.name = "Pet ";
        cr.rawAttributes[Attribute.charisma] = 10;
      } else {
        cr.name = "";
      }

      switch (lcsRandom(11)) {
        case 0:
          cr.name += "Genetic Monster";
          cr.body = monsterBody();
        case 1:
          cr.name += "Flaming Rabbit";
          cr.body = flamingRabbitBody();
        case 2:
          cr.name += "Genetic Nightmare";
          cr.body = monsterBody();
        case 3:
          cr.name += "Mad Cow";
          cr.body = madCowBody();
        case 4:
          cr.name += "Giant Mosquito";
          cr.body = giantMosquitoBody();
        case 5:
          cr.name += "Six-legged Pig";
          cr.body = sixLeggedPigBody();
        case 6:
          cr.name += "Purple Gorilla";
          cr.body = purpleGorillaBody();
        case 7:
          cr.name += "Warped Bear";
          cr.body = warpedBearBody();
        case 8:
          cr.name += "Writhing Mass";
          cr.body = monsterBody();
        case 9:
          cr.name += "Something Bad";
          cr.body = monsterBody();
        case 10:
          cr.name += "Pink Elephant";
          cr.body = pinkElephantBody();
      }
      if (!animalsArePeopleToo) {
        cr.money = 0;
        cr.equippedWeapon = null;
      }
    case CreatureTypeIds.guardDog:
      cr.body = dogBody();
      if (!animalsArePeopleToo) {
        cr.money = 0;
        cr.equippedWeapon = null;
      }
    case CreatureTypeIds.prisoner:
      // Prisoners should not be "prisoners" after recruiting them,
      // they should be some brand of criminal
      if (oneIn(10)) {
        // Thief
        cr = Creature.fromId(CreatureTypeIds.thief);
      } else {
        cr = Creature.fromId([
          CreatureTypeIds.bum,
          CreatureTypeIds.gangMember,
          CreatureTypeIds.crackhead,
          CreatureTypeIds.sexWorker,
          CreatureTypeIds.teenager,
          CreatureTypeIds.highschoolDropout,
        ].random);
      }

      CreatureType crtype = creatureTypes[CreatureTypeIds.prisoner]!;
      crtype.randomWeaponFor(cr);
      cr.giveClothingType(crtype.randomArmor?.idName ?? "");
      cr.money = crtype.money.roll();
      cr.juice = crtype.juice.roll();
      cr.name = crtype.randomEncounterName;
      if (cr.align == Alignment.conservative) {
        cr.align = nonConservativeAlignment();
      }
    case CreatureTypeIds.gangMember:
      if (oneIn(2)) {
        criminalize(
            cr, [Crime.drugDistribution, Crime.assault, Crime.murder].random);
      }
      if (mode == GameMode.site &&
          activeSite?.type == SiteType.drugHouse &&
          activeSite?.controller != SiteController.lcs) {
        conservatize(cr);
      }
    case CreatureTypeIds.crackhead:
      cr.rawAttributes[Attribute.heart] =
          max(1, cr.rawAttributes[Attribute.heart]! - 2);
      cr.rawAttributes[Attribute.wisdom] =
          max(1, cr.rawAttributes[Attribute.wisdom]! - 2);
    case CreatureTypeIds.sexWorker:
      if (oneIn(2)) criminalize(cr, Crime.prostitution);
    case CreatureTypeIds.hippie:
      if (oneIn(10)) criminalize(cr, Crime.drugDistribution);
    case CreatureTypeIds.thief:
      if (oneIn(4)) criminalize(cr, Crime.breakingAndEntering);
      if (oneIn(4)) criminalize(cr, Crime.theft);
  }
}

const List<String> ruralMobNames = [
  "Country Boy",
  "Country Folk",
  "Mountain Man",
  "Rancher",
  "Rural Fury",
  "Homesteader",
  "Hinterlander",
  "Backroads Bully",
  "Spittin' Mad",
  "Heartlander",
  "Hayseed",
  "Small-Towner",
  "Rustic",
];

/* gives a CCS member a cover name */
void nameCCSMember(Creature cr) {
  if (cr.clothing.type.idName == "CLOTHING_ARMYARMOR") {
    cr.name = "Soldier";
  } else if (cr.clothing.type.idName == "CLOTHING_HEAVYARMOR") {
    cr.name = "CCS Heavy";
  } else if (cr.weapon.type.idName == "WEAPON_PUMP_SHOTGUN" || oneIn(2)) {
    cr.name = ruralMobNames.random;
  } else {
    cr.name = [
      "Biker",
      "Transient",
      "Crackhead",
      "Fast Food Worker",
      "Telemarketer",
      "Office Worker",
      "Mailman",
      "Musician",
      "Hairstylist",
      "Bartender",
    ].random;
  }
}
