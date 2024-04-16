import 'dart:math';

import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/body.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/location_type.dart';
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
  if (laws[Law.gunControl] == DeepAlignment.conservative && oneIn(30)) {
    cr.giveWeaponAndAmmo("WEAPON_REVOLVER_38", 4);
  } else if (laws[Law.gunControl] == DeepAlignment.archConservative) {
    if (oneIn(10)) {
      cr.giveWeaponAndAmmo("WEAPON_SEMIPISTOL_9MM", 4);
    } else if (oneIn(9)) {
      cr.giveWeaponAndAmmo("WEAPON_SEMIPISTOL_45", 4);
    }
  }
}

void applyHardcodedCreatureTypeStuff(Creature cr, CreatureType type) {
  switch (type.id) {
    case CreatureTypeIds.bouncer:
      if (mode == GameMode.site && activeSite?.hasHighSecurity == true) {
        cr.name = "Enforcer";
        cr.rawSkill[Skill.martialArts] = lcsRandom(3) + 3;
      }
      if (laws[Law.gunControl] == DeepAlignment.archConservative) {
        cr.giveWeaponAndAmmo("WEAPON_SMG_MP5", 4);
      } else if (laws[Law.gunControl] == DeepAlignment.conservative) {
        cr.giveWeaponAndAmmo("WEAPON_REVOLVER_44", 4);
      } else if (laws[Law.gunControl] == DeepAlignment.moderate) {
        cr.giveWeaponAndAmmo("WEAPON_REVOLVER_38", 4);
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
        cr.giveWeaponAndAmmo("WEAPON_SMG_MP5", 4);
      } else if (laws[Law.gunControl] != DeepAlignment.archConservative) {
        cr.giveWeaponAndAmmo("WEAPON_REVOLVER_38", 4);
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
        cr.giveWeaponAndAmmo("WEAPON_REVOLVER_44", 4);
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
    case CreatureTypeIds.lawyer:
      if (laws[Law.gunControl] == DeepAlignment.archConservative && oneIn(3)) {
        cr.giveWeaponAndAmmo("WEAPON_REVOLVER_38", 1);
      }
    case CreatureTypeIds.doctor:
      if (laws[Law.gunControl] == DeepAlignment.archConservative && oneIn(3)) {
        cr.giveWeaponAndAmmo("WEAPON_REVOLVER_38", 1);
      }
    case CreatureTypeIds.psychologist:
      if (laws[Law.gunControl] == DeepAlignment.archConservative && oneIn(3)) {
        cr.giveWeaponAndAmmo("WEAPON_REVOLVER_38", 1);
        cr.reload(false);
      }
      if (cr.gender == Gender.male || oneIn(2)) {
        cr.giveArmorType("ARMOR_CHEAPSUIT");
      } else {
        cr.giveArmorType("ARMOR_CHEAPDRESS");
      }
    case CreatureTypeIds.nurse:
      if (laws[Law.gunControl] == DeepAlignment.archConservative && oneIn(3)) {
        cr.giveWeaponAndAmmo("WEAPON_REVOLVER_38", 1);
      }
    case CreatureTypeIds.tank:
      cr.body = TankBody();
    case CreatureTypeIds.merc:
      if (laws[Law.gunControl]! < DeepAlignment.conservative) {
        cr.giveWeaponAndAmmo("WEAPON_AUTORIFLE_M16", 7);
      } else {
        cr.giveWeaponAndAmmo("WEAPON_SEMIRIFLE_AR15", 7);
      }
    case CreatureTypeIds.hick:
      cr.name = hickNames.random;
      if ((laws[Law.gunControl] == DeepAlignment.archConservative &&
              oneIn(2)) ||
          oneIn(10)) {
        cr.giveWeaponAndAmmo("WEAPON_SHOTGUN_PUMP", 4);
      } else if (oneIn(2)) {
        cr.giveWeaponAndAmmo("WEAPON_TORCH", 0);
      } else {
        cr.giveWeaponAndAmmo("WEAPON_PITCHFORK", 0);
      }
    case CreatureTypeIds.cop:
      if (laws[Law.policeReform] == DeepAlignment.eliteLiberal &&
          cr.align == Alignment.liberal &&
          oneIn(3)) // Peace Officer
      {
        cr.align = Alignment.moderate;
        cr.name = "Police Negotiator";
        cr.rawSkill[Skill.persuasion] = lcsRandom(4) + 1;
        cr.rawSkill[Skill.firearms] = lcsRandom(3) + 1;
      } else {
        if (laws[Law.gunControl] == DeepAlignment.archConservative &&
            oneIn(3)) {
          cr.giveWeaponAndAmmo("WEAPON_SMG_MP5", 4);
        } else {
          cr.giveWeaponAndAmmo("WEAPON_SEMIPISTOL_9MM", 4);
        }
        cr.reload(false);
        cr.align = Alignment.conservative;
        cr.rawSkill[Skill.firearms] = lcsRandom(4) + 1;
        cr.rawSkill[Skill.martialArts] = lcsRandom(2) + 1;
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
        cr.giveArmorType("ARMOR_BUNKERGEAR");
      }
    case CreatureTypeIds.ccsMolotov:
      if (mode == GameMode.site) {
        nameCCSMember(cr);
      }
    case CreatureTypeIds.ccsSniper:
      if (mode == GameMode.site) {
        nameCCSMember(cr);
      }
    case CreatureTypeIds.ccsVigilante:
      cr.giveArmorType("ARMOR_CLOTHES");
      switch (lcsRandom(5) + ccsState.index) {
        case 0:
        case 1:
        case 2:
          cr.giveWeaponAndAmmo("WEAPON_SEMIPISTOL_9MM", 7);
        case 3:
          cr.giveWeaponAndAmmo("WEAPON_REVOLVER_44", 7);
        case 4:
          cr.giveWeaponAndAmmo("WEAPON_SHOTGUN_PUMP", 7);
        case 5:
          cr.giveWeaponAndAmmo("WEAPON_SEMIRIFLE_AR15", 7);
          cr.giveArmorType("ARMOR_CIVILLIANARMOR");
        case 6:
          cr.giveWeaponAndAmmo("WEAPON_SEMIRIFLE_AR15", 7);
          cr.giveArmorType("ARMOR_ARMYARMOR");
        default:
          cr.giveWeaponAndAmmo("WEAPON_AUTORIFLE_M16", 7);
          cr.giveArmorType("ARMOR_ARMYARMOR");
      }
      if (mode == GameMode.site /* && sitealarm>0*/) {
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
    case CreatureTypeIds.prisonGuard:
      if (laws[Law.gunControl] == DeepAlignment.archConservative && oneIn(3)) {
        cr.giveWeaponAndAmmo("WEAPON_SMG_MP5", 4);
      } else if (oneIn(3)) {
        cr.giveWeaponAndAmmo("WEAPON_SHOTGUN_PUMP", 4);
      } else {
        cr.giveWeaponAndAmmo("WEAPON_NIGHTSTICK", 0);
      }
    case CreatureTypeIds.educator:
      if (laws[Law.gunControl] == DeepAlignment.archConservative && oneIn(3)) {
        cr.giveWeaponAndAmmo("WEAPON_SMG_MP5", 4);
      } else if (oneIn(3)) {
        cr.giveWeaponAndAmmo("WEAPON_SEMIPISTOL_9MM", 4);
      } else {
        cr.giveWeaponAndAmmo("WEAPON_SYRINGE", 0);
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
      if (!animalsArePeopleToo) cr.money = 0;
    case CreatureTypeIds.guardDog:
      cr.body = dogBody();
      if (!animalsArePeopleToo) cr.money = 0;
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
      cr.giveArmorType(crtype.randomArmor?.idName ?? "");
      cr.money = crtype.money.roll();
      cr.juice = crtype.juice.roll();
      cr.name = crtype.randomEncounterName;
      if (cr.align == Alignment.conservative) {
        cr.align = nonConservativeAlignment();
      }
    case CreatureTypeIds.bum:
      giveCivilianWeapon(cr);
      if (cr.equippedWeapon == null && oneIn(5)) {
        cr.giveWeaponAndAmmo("WEAPON_SHANK", 0);
      }
      if (cr.align == Alignment.conservative) {
        cr.align = nonConservativeAlignment();
      }
    case CreatureTypeIds.mutant:
      giveCivilianWeapon(cr);
      if (cr.equippedWeapon == null && oneIn(5)) {
        cr.giveWeaponAndAmmo("WEAPON_SHANK", 0);
      }
    case CreatureTypeIds.gangMember:
      if (oneIn(20) ||
          (laws[Law.gunControl] == DeepAlignment.archConservative &&
              oneIn(5))) {
        cr.giveWeaponAndAmmo("WEAPON_AUTORIFLE_AK47", 3);
      } else if (oneIn(16) ||
          (laws[Law.gunControl] == DeepAlignment.archConservative &&
              oneIn(5))) {
        cr.giveWeaponAndAmmo("WEAPON_SMG_MP5", 4);
      } else if (oneIn(15)) {
        cr.giveWeaponAndAmmo("WEAPON_SEMIPISTOL_45", 4);
      } else if (oneIn(10)) {
        cr.giveWeaponAndAmmo("WEAPON_SHOTGUN_PUMP", 4);
      } else if (oneIn(4)) {
        cr.giveWeaponAndAmmo("WEAPON_SEMIPISTOL_9MM", 4);
      } else if (oneIn(2)) {
        cr.giveWeaponAndAmmo("WEAPON_REVOLVER_38", 4);
      } else {
        cr.giveWeaponAndAmmo("WEAPON_COMBATKNIFE", 0);
      }
      cr.reload(false);
      // We'll make the crack house a bit dicey
      if (activeSite?.type == SiteType.drugHouse) {
        cr.align = Alignment.conservative;
      } else if (activeSiteUnderSiege) {
        cr.align = Alignment.conservative;
      }
      if (oneIn(2)) {
        criminalize(
            cr, [Crime.drugDistribution, Crime.assault, Crime.murder].random);
      }
    case CreatureTypeIds.crackhead:
      giveCivilianWeapon(cr);
      if (oneIn(5)) {
        cr.giveWeaponAndAmmo("WEAPON_SHANK", 0);
      }
      cr.rawAttributes[Attribute.heart] =
          max(1, cr.rawAttributes[Attribute.heart]! - 2);
      cr.rawAttributes[Attribute.wisdom] =
          max(1, cr.rawAttributes[Attribute.wisdom]! - 2);
    case CreatureTypeIds.sexWorker:
      if (oneIn(10)) criminalize(cr, Crime.prostitution);
    case CreatureTypeIds.hippie:
      if (oneIn(10)) criminalize(cr, Crime.drugDistribution);
    case CreatureTypeIds.socialite:
      if (cr.gender == Gender.female) {
        cr.giveArmorType("ARMOR_EXPENSIVEDRESS");
      } else {
        cr.giveArmorType("ARMOR_EXPENSIVESUIT");
      }
    case CreatureTypeIds.thief:
      cr.name = creatureTypes[[
        CreatureTypeIds.socialite,
        CreatureTypeIds.clerk,
        CreatureTypeIds.officeWorker,
        CreatureTypeIds.artCritic,
        CreatureTypeIds.musicCritic
      ].random]!
          .randomEncounterName;
      if (oneIn(10)) criminalize(cr, Crime.breakingAndEntering);
      if (oneIn(10)) criminalize(cr, Crime.theft);
  }
}

const List<String> hickNames = [
  "Country Boy",
  "Good ol' Boy",
  "Hick",
  "Hillbilly",
  "Redneck",
  "Rube",
  "Yokel",
  "Bumpkin",
  "Hayseed",
  "Rustic",
];

/* gives a CCS member a cover name */
void nameCCSMember(Creature cr) {
  if (cr.armor.type.idName == "ARMOR_CIVILLIANARMOR") {
    cr.name = "Elite Security";
  } else if (cr.armor.type.idName == "ARMOR_ARMYARMOR") {
    cr.name = "Soldier";
  } else if (cr.armor.type.idName == "ARMOR_HEAVYARMOR") {
    cr.name = "CCS Heavy";
  } else if (cr.weapon.type.idName == "WEAPON_SHOTGUN_PUMP" || oneIn(2)) {
    cr.name = hickNames.random;
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
