import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/conversion.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/siege.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/sitemode/site_display.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

/* checks if your liberal activity is noticed */
Future<void> noticeCheck(
    {int difficulty = Difficulty.average,
    Creature? exclude,
    bool includeModerates = true,
    bool includeLiberals = false}) async {
  if (siteAlarm) return;

  int sneak = -1;

  Creature? sneaker;
  for (Creature p in activeSquad!.livingMembers) {
    int take10 = p.skillRoll(Skill.stealth, take10: true);
    if (sneaker == null || take10 < sneak) {
      sneak = take10;
      sneaker = p;
    }
  }
  if (sneaker == null) return;
  for (Creature e in encounter) {
    if (e.align == Alignment.liberal && !includeLiberals) continue;
    if (e.align == Alignment.moderate && !includeModerates) continue;
    //Prisoners shouldn't shout for help.
    if (e.name == "Prisoner" ||
        e == exclude ||
        sneaker.skillCheck(Skill.stealth, difficulty)) {
      continue;
    } else {
      clearMessageArea();

      mvaddstrc(9, 1, red, "${e.name} observes your Liberal activity ");
      move(10, 1);
      if (e.align == Alignment.conservative) {
        addstr("and lets forth a piercing Conservative alarm cry!");
      } else {
        addstr("and shouts for help!");
      }

      siteAlarm = true;

      await getKey();

      break;
    }
  }
}

/* checks if your liberal behavior/attack alienates anyone */
Future<bool> alienationCheck(bool evenIfNoWitnesses) async {
  if (activeSiteUnderSiege || activeSite?.controller == SiteController.ccs) {
    return false;
  }

  bool alienate = false;
  bool alienatebig = false;

  SiteAlienation oldSiteAlienation = siteAlienated;

  List<Creature> noticer = [];
  for (Creature e in encounter) {
    // Prisoners should never be alienated by your crimes, as
    // they're happy to have you attacking their place of holding
    if (e.name == "Prisoner" || e.type.id == CreatureTypeIds.prisoner) continue;

    if (e.alive &&
        (e.align == Alignment.moderate || e.align == Alignment.liberal)) {
      noticer.add(e);
    }
  }

  if (noticer.isNotEmpty || evenIfNoWitnesses) {
    for (Creature n in noticer) {
      if (n.align == Alignment.liberal) {
        alienatebig = true;
      } else {
        alienate = true;
      }
      conservatize(n);
      n.nonCombatant = true;
    }

    if (evenIfNoWitnesses) alienatebig = false;

    if (oldSiteAlienation.index < siteAlienated.index) {
      clearMessageArea();
      setColor(yellow);
      move(9, 1);
      if (siteAlienated == SiteAlienation.alienatedModerates) {
        addstr("We've alienated the masses here!");
      } else {
        addstr("We've alienated absolutely everyone here!");
      }

      siteAlarm = true;

      for (Creature e in encounter) {
        if (e.align != Alignment.conservative) {
          if (e.align == Alignment.moderate || alienatebig) {
            conservatize(e);
          }
        }
      }

      printEncounter();

      await getKey();
    }
  }

  return alienate;
}

/* checks if conservatives see through your disguise */
Future<void> disguisecheck(int timer) async {
  WeaponCheckResult weapon = WeaponCheckResult.ok;
  DisguiseQuality disguise = DisguiseQuality.inconspicuous;
  int partysize = squad.length;
  Creature? squaddieThatBlewIt;
  bool forcecheck = false, spotted = false;
  //List<int> weaponar = [0];

  // Only start to penalize the player's disguise/stealth checks after the first turn.
  timer--;

  for (Creature c in squad) {
    if (c.indecent) forcecheck = true;
    WeaponCheckResult thisweapon = weaponCheck(c);
    if (thisweapon.index > weapon.index) weapon = thisweapon;
    DisguiseQuality thisdisguise = disguiseQuality(c);
    if (thisdisguise.index > disguise.index) disguise = thisdisguise;
  }

  // Nothing suspicious going on here
  if (!siteAlarm &&
      siteAlarmTimer != 0 &&
      timer == 0 &&
      weapon == WeaponCheckResult.ok &&
      disguise != DisguiseQuality.alarming &&
      disguise != DisguiseQuality.disturbing &&
      disguise != DisguiseQuality.unusual &&
      !forcecheck) {
    if ((!disguisesite(activeSite!.type) &&
            !levelMap[locx][locy][locz].restricted) ||
        disguise == DisguiseQuality.inconspicuous) {
      if (disguisesite(activeSite!.type) ||
          levelMap[locx][locy][locz].restricted) {
        for (Creature c in squad) {
          c.train(Skill.disguise, 10);
        }
      }
      return;
    }
  }

  bool noticed = false;
  List<Creature> noticer = [];
  for (Creature e in encounter) {
    if (e.type.id == CreatureTypeIds.prisoner || e.name == "Prisoner") continue;
    if (e.alive && e.isEnemy) {
      noticer.add(e);
    }
  }

  if (noticer.isNotEmpty) {
    Creature n;
    do {
      n = noticer.random;
      noticer.remove(n);

      int stealthDifficulty;
      int disguiseDifficulty;

      // Determine difficulty based on enemy type
      switch (n.type.id) {
        case CreatureTypeIds.swat:
        case CreatureTypeIds.cop:
        case CreatureTypeIds.gangUnit:
        case CreatureTypeIds.deathSquad:
          stealthDifficulty = Difficulty.easy;
          disguiseDifficulty = Difficulty.easy;
        case CreatureTypeIds.prisonGuard:
        case CreatureTypeIds.bouncer:
        case CreatureTypeIds.securityGuard:
          stealthDifficulty = Difficulty.average;
          disguiseDifficulty = Difficulty.easy;
        case CreatureTypeIds.agent:
          stealthDifficulty = Difficulty.average;
          disguiseDifficulty = Difficulty.average;
        case CreatureTypeIds.newsAnchor:
        case CreatureTypeIds.radioPersonality:
        case CreatureTypeIds.corporateCEO:
        case CreatureTypeIds.conservativeJudge:
        case CreatureTypeIds.ccsArchConservative:
        case CreatureTypeIds.eminentScientist:
        case CreatureTypeIds.televangelist:
          stealthDifficulty = Difficulty.easy;
          disguiseDifficulty = Difficulty.hard;
        case CreatureTypeIds.guardDog:
          stealthDifficulty = Difficulty.heroic;
          disguiseDifficulty = Difficulty.average;
        case CreatureTypeIds.secretService:
        case CreatureTypeIds.policeChief:
          stealthDifficulty = Difficulty.formidable;
          disguiseDifficulty = Difficulty.formidable;
        default:
          stealthDifficulty = Difficulty.veryEasy;
          disguiseDifficulty = Difficulty.veryEasy;
      }

      // Increase difficulty if Conservatives suspicious...
      if (siteAlarmTimer == 0) {
        stealthDifficulty += DifficultyModifier.aLotHarder;
        disguiseDifficulty += DifficultyModifier.aLotHarder;
      }
      // Sneaking with a party is hard
      stealthDifficulty += partysize - 1;
      // Sneaking past a bloody scene with suspicious conservatives present
      // is also quite hard
      if (currentTile.megaBloody) {
        stealthDifficulty += DifficultyModifier.moderatelyHarder;
      } else if (currentTile.bloody) {
        stealthDifficulty += DifficultyModifier.aLittleHarder;
      }

      // Make the attempt!
      for (Creature c in squad) {
        // Try to sneak.
        if (!spotted) {
          int result = c.skillRoll(Skill.stealth);
          result -= timer;
          if (result < stealthDifficulty) spotted = true;
        }
      }

      List<Creature> spottedSquad = [];
      if (spotted) {
        spottedSquad = squad.where((c) {
          bool blewIt = weaponCheck(c) == WeaponCheckResult.suspicious &&
              !(politics.laws[Law.gunControl] ==
                  DeepAlignment.archConservative);

          int penalty = disguiseQuality(c).penalty;
          int result = c.skillRoll(Skill.disguise) + penalty;
          result -= timer;
          if (result < disguiseDifficulty) blewIt = true;
          return blewIt;
        }).toList();
        if (spottedSquad.isNotEmpty) {
          squaddieThatBlewIt = spottedSquad.random;
          noticed = true;
        }

        if (noticed) break;
      }
    } while (noticer.isNotEmpty);

    // Give feedback on the Liberal Performance
    if (!spotted) {
      for (Creature c in squad) {
        c.train(Skill.stealth, 40);
      }

      if (timer == 0) {
        setColor(lightBlue);
        move(9, 1);

        if (partysize > 1) {
          addstr("The squad");
        } else {
          addstr(squad[0].name);
        }
        addstr(" fades into the shadows.");

        await getKey();
      }
    } else {
      for (Creature p in squad) {
        if (disguiseQuality(p).penalty > -50) {
          p.train(Skill.disguise, 50);
        }
      }

      if (squaddieThatBlewIt != null && oneIn(2)) {
        mvaddstrc(9, 1, yellow, squaddieThatBlewIt.name);
        addstr([
          " coughs.",
          " accidentally mumbles the slogan.",
          " paces uneasily.",
          " stares at the Conservatives.",
          " laughs nervously.",
          " fidgets.",
          " whistles.",
          " mutters incomprehensibly.",
          " exhales loudly.",
          " comments loudly on the weather.",
        ].random);

        await getKey();
      } else if (!noticed) {
        /*
        setColor(lightBlue);
        move(9, 1);

        if (partysize > 1) {
          addstr("The squad");
        } else {
          addstr(squad[0].name);
        }
        addstr(" acts natural.");

        await getKey();
        */
      }
    }

    if (!noticed) return;

    clearMessageArea();

    mvaddstrc(9, 1, red, n.name);
    if (siteAlarmTimer != 0 &&
        [WeaponCheckResult.ok, WeaponCheckResult.inCharacter]
            .contains(weapon) &&
        disguise != DisguiseQuality.alarming &&
        !n.type.dog) {
      if ((siteType == SiteType.tenement ||
              siteType == SiteType.apartment ||
              siteType == SiteType.upscaleApartment) &&
          levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0) {
        siteAlarm = true;

        addstr(" shouts in alarm at the squad's Liberal Trespassing!");
      } else {
        addstr(" looks at the Squad suspiciously.");

        int time;

        time = 20 +
            lcsRandom(10) -
            n.attribute(Attribute.intelligence) -
            n.attribute(Attribute.wisdom);

        if (time < 1) time = 1;

        if (siteAlarmTimer > time || siteAlarmTimer == -1) {
          siteAlarmTimer = time;
        } else {
          if (siteAlarmTimer > 5) siteAlarmTimer -= 5;
          if (siteAlarmTimer <= 5) siteAlarmTimer = 0;
        }
      }
    } else {
      if (weapon != WeaponCheckResult.ok &&
          weapon != WeaponCheckResult.inCharacter &&
          !n.type.dog &&
          !(politics.laws[Law.gunControl] == DeepAlignment.archConservative)) {
        addstr(" takes one look at the Squad's Liberal Weapons");
      } else if (disguise == DisguiseQuality.alarming && !n.type.dog) {
        addstr(" takes one look at the Squad's Liberal Armor");
      } else {
        addstr(" looks at the Squad with Intolerance");
      }
      move(10, 1);
      if (n.type.dog) {
        addstr("and launches into angry Conservative barking!");
      } else if (n.align == Alignment.conservative) {
        addstr("and lets forth a piercing Conservative alarm cry!");
      } else {
        addstr("and shouts for help!");
      }

      siteAlarm = true;
    }

    await getKey();
  }
}

enum WeaponCheckResult {
  ok,
  inCharacter,
  suspicious,
}

WeaponCheckResult weaponCheck(Creature creature, {bool metalDetector = false}) {
  bool suspicious = creature.weapon.type.suspicious;
  bool concealed = creature.weaponIsConcealed ||
      (politics.laws[Law.gunControl] == DeepAlignment.archConservative &&
          creature.weapon.type.isAGun);
  bool inCharacter = creature.weaponIsInCharacter;
  if (disguiseQuality(creature).lowQuality) inCharacter = false;
  if (suspicious) {
    if (concealed && !metalDetector) {
      return WeaponCheckResult.ok;
    } else if (inCharacter) {
      return WeaponCheckResult.inCharacter;
    } else {
      return WeaponCheckResult.suspicious;
    }
  }
  return WeaponCheckResult.ok;
}

enum DisguiseQuality {
  inconspicuous,
  unusual,
  disturbing,
  authorityFigure,
  trespassing,
  alarming,
  hidden;

  bool get lowQuality {
    switch (this) {
      case inconspicuous:
        return false;
      case unusual:
        return true;
      case disturbing:
        return true;
      case authorityFigure:
        return false;
      case trespassing:
        return true;
      case alarming:
        return true;
      case hidden:
        return false;
    }
  }

  int get penalty => switch (this) {
        DisguiseQuality.hidden => 0,
        DisguiseQuality.inconspicuous => 0,
        DisguiseQuality.authorityFigure => -2,
        DisguiseQuality.unusual => -4,
        DisguiseQuality.disturbing => -8,
        DisguiseQuality.trespassing => -100,
        DisguiseQuality.alarming => -100,
      };
}

/* checks if a creature's uniform is appropriate to the location */
DisguiseQuality disguiseQuality(Creature cr) {
  SiteType? type = activeSite?.type;

  DisguiseQuality uniformed = DisguiseQuality.trespassing;
  if (!cr.clothing.type.allowVisibleArmor &&
      cr.clothing.armor?.visible == true &&
      cr.clothing.armor?.idName != cr.clothing.type.intrinsicArmorId) {
    return DisguiseQuality.alarming;
  }

  if (activeSiteUnderSiege) {
    switch (activeSite!.siege.activeSiegeType) {
      case SiegeType.cia:
        if (["CLOTHING_BLACKSUIT", "CLOTHING_BLACKDRESS"]
            .contains(cr.clothing.type.idName)) {
          uniformed = DisguiseQuality.inconspicuous;
        }
      case SiegeType.corporateMercs:
        if (["CLOTHING_MILITARY", "CLOTHING_ARMYARMOR", "CLOTHING_SEALSUIT"]
            .contains(cr.clothing.type.idName)) {
          uniformed = DisguiseQuality.inconspicuous;
        }
      case SiegeType.angryRuralMob:
        if (cr.clothing.type.idName == "CLOTHING_CLOTHES") {
          uniformed = DisguiseQuality.unusual;
        }
        if (["CLOTHING_OVERALLS", "CLOTHING_WIFEBEATER"]
            .contains(cr.clothing.type.idName)) {
          uniformed = DisguiseQuality.inconspicuous;
        }
      case SiegeType.ccs:
        uniformed = DisguiseQuality.trespassing;
      case SiegeType.police:
        if (activeSite!.siege.escalationState == SiegeEscalation.police) {
          if ([
            "CLOTHING_POLICEUNIFORM",
            "CLOTHING_POLICEARMOR",
            "CLOTHING_SWATARMOR"
          ].contains(cr.clothing.type.idName)) {
            uniformed = DisguiseQuality.inconspicuous;
          }
        } else {
          if (["CLOTHING_MILITARY", "CLOTHING_ARMYARMOR", "CLOTHING_SEALSUIT"]
              .contains(cr.clothing.type.idName)) {
            uniformed = DisguiseQuality.inconspicuous;
          }
        }
      default:
    }
  } else {
    if (!cr.indecent && cr.clothing.type.idName != "CLOTHING_HEAVYARMOR") {
      uniformed = DisguiseQuality.inconspicuous;
    }

    switch (type) {
      case SiteType.warehouse:
      case SiteType.homelessEncampment:
        uniformed = DisguiseQuality.inconspicuous;
      case SiteType.cosmeticsLab:
      case SiteType.geneticsLab:
        if (levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0) {
          uniformed = DisguiseQuality.trespassing;
          if (["CLOTHING_LABCOAT", "CLOTHING_SCRUBS"]
              .contains(cr.clothing.type.idName)) {
            uniformed = DisguiseQuality.inconspicuous;
          }
          if (["CLOTHING_SECURITYUNIFORM"].contains(cr.clothing.type.idName)) {
            if (activeSite!.hasHighSecurity) {
              uniformed = DisguiseQuality.inconspicuous;
            } else {
              uniformed = DisguiseQuality.authorityFigure;
            }
          }
        }
      case SiteType.policeStation:
        if (levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0) {
          uniformed = DisguiseQuality.trespassing;
          if (["CLOTHING_POLICEUNIFORM", "CLOTHING_POLICEARMOR"]
              .contains(cr.clothing.type.idName)) {
            uniformed = DisguiseQuality.inconspicuous;
          }
          if (deathSquadsActive &&
              cr.clothing.type.idName == "CLOTHING_DEATHSQUADUNIFORM") {
            uniformed = DisguiseQuality.inconspicuous;
          }
          if (cr.clothing.type.idName == "CLOTHING_SWATARMOR") {
            uniformed = DisguiseQuality.inconspicuous;
          }
        }
      case SiteType.whiteHouse:
        if (levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0) {
          uniformed = DisguiseQuality.trespassing;
          if ([
            "CLOTHING_BLACKSUIT",
            "CLOTHING_BLACKDRESS",
            "CLOTHING_CHEAPSUIT",
            "CLOTHING_CHEAPDRESS",
            "CLOTHING_EXPENSIVESUIT",
            "CLOTHING_EXPENSIVEDRESS",
            "CLOTHING_MILITARY",
            "CLOTHING_ARMYARMOR",
            "CLOTHING_SEALSUIT",
            "CLOTHING_HABIT",
            "CLOTHING_CASSOCK",
          ].contains(cr.clothing.type.idName)) {
            uniformed = DisguiseQuality.inconspicuous;
          }
        }
      case SiteType.courthouse:
        if (levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0) {
          uniformed = DisguiseQuality.trespassing;
          if ([
            "CLOTHING_BLACKROBE",
            "CLOTHING_BLACKSUIT",
            "CLOTHING_BLACKDRESS",
            "CLOTHING_CHEAPSUIT",
            "CLOTHING_CHEAPDRESS",
            "CLOTHING_EXPENSIVESUIT",
            "CLOTHING_EXPENSIVEDRESS",
            "CLOTHING_SECURITYUNIFORM",
            "CLOTHING_POLICEUNIFORM",
            "CLOTHING_POLICEARMOR",
          ].contains(cr.clothing.type.idName)) {
            uniformed = DisguiseQuality.inconspicuous;
          }
          if (deathSquadsActive &&
              cr.clothing.type.idName == "CLOTHING_DEATHSQUADUNIFORM") {
            uniformed = DisguiseQuality.inconspicuous;
          }
          if (cr.clothing.type.idName == "CLOTHING_SWATARMOR") {
            if (activeSite!.hasHighSecurity) {
              uniformed = DisguiseQuality.inconspicuous;
            } else {
              uniformed = DisguiseQuality.authorityFigure;
            }
          }
        }
      case SiteType.prison:
        if (levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0) {
          uniformed = DisguiseQuality.trespassing;
          if (nineteenEightyFour) {
            if (cr.clothing.type.idName == "CLOTHING_LABCOAT") {
              uniformed = DisguiseQuality.inconspicuous;
            }
          } else if (cr.clothing.type.idName == "CLOTHING_PRISONGUARD") {
            uniformed = DisguiseQuality.inconspicuous;
          }
          if (["CLOTHING_PRISONER", "CLOTHING_SCRUBS"]
              .contains(cr.clothing.type.idName)) {
            uniformed = DisguiseQuality.inconspicuous;
          }
        }
      case SiteType.armyBase:
        if (levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0) {
          uniformed = DisguiseQuality.trespassing;
          if (["CLOTHING_MILITARY", "CLOTHING_ARMYARMOR", "CLOTHING_SEALSUIT"]
              .contains(cr.clothing.type.idName)) {
            uniformed = DisguiseQuality.inconspicuous;
          }
        }
      case SiteType.intelligenceHQ:
        if (levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0) {
          uniformed = DisguiseQuality.trespassing;
          if (["CLOTHING_BLACKSUIT", "CLOTHING_BLACKDRESS"]
              .contains(cr.clothing.type.idName)) {
            uniformed = DisguiseQuality.inconspicuous;
          }
        }
      case SiteType.fireStation:
        if (levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0) {
          uniformed = DisguiseQuality.trespassing;
          if ([
            "CLOTHING_BUNKERGEAR",
            "CLOTHING_WORKCLOTHES",
            "CLOTHING_OVERALLS",
            "CLOTHING_HABIT",
            "CLOTHING_CASSOCK",
          ].contains(cr.clothing.type.idName)) {
            uniformed = DisguiseQuality.inconspicuous;
          }
          if (activeSite!.hasHighSecurity) {
            if ([
              "CLOTHING_POLICEUNIFORM",
              "CLOTHING_POLICEARMOR",
              "CLOTHING_SWATARMOR",
            ].contains(cr.clothing.type.idName)) {
              uniformed = DisguiseQuality.inconspicuous;
            }
            if (deathSquadsActive &&
                cr.clothing.type.idName == "CLOTHING_DEATHSQUADUNIFORM") {
              uniformed = DisguiseQuality.inconspicuous;
            }
          }
        }
      case SiteType.bank:
        if (levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0) {
          uniformed = DisguiseQuality.trespassing;
          if ([
            "CLOTHING_BLACKSUIT",
            "CLOTHING_BLACKDRESS",
            "CLOTHING_CHEAPSUIT",
            "CLOTHING_CHEAPDRESS",
            "CLOTHING_EXPENSIVESUIT",
            "CLOTHING_EXPENSIVEDRESS",
            "CLOTHING_SECURITYUNIFORM",
            "CLOTHING_POLICEUNIFORM",
            "CLOTHING_POLICEARMOR",
          ].contains(cr.clothing.type.idName)) {
            uniformed = DisguiseQuality.inconspicuous;
          }
          if (deathSquadsActive &&
              cr.clothing.type.idName == "CLOTHING_DEATHSQUADUNIFORM") {
            uniformed = DisguiseQuality.inconspicuous;
          }
          if (cr.clothing.type.idName == "CLOTHING_SWATARMOR") {
            if (activeSite!.hasHighSecurity || siteAlarm) {
              uniformed = DisguiseQuality.inconspicuous;
            } else {
              uniformed = DisguiseQuality.authorityFigure;
            }
          }
        }
      case SiteType.barAndGrill:
        uniformed = DisguiseQuality.trespassing;
        if ([
          "CLOTHING_EXPENSIVESUIT",
          "CLOTHING_CHEAPSUIT",
          "CLOTHING_EXPENSIVEDRESS",
          "CLOTHING_CHEAPDRESS",
          "CLOTHING_BLACKSUIT",
          "CLOTHING_BLACKDRESS"
        ].contains(cr.clothing.type.idName)) {
          uniformed = DisguiseQuality.inconspicuous;
        }
      case SiteType.sweatshop:
        uniformed = DisguiseQuality.trespassing;
        if (cr.equippedClothing == null) {
          uniformed = DisguiseQuality.inconspicuous;
        }
        if (cr.clothing.type.idName == "CLOTHING_SECURITYUNIFORM") {
          uniformed = DisguiseQuality.inconspicuous;
        }
      case SiteType.dirtyIndustry:
        uniformed = DisguiseQuality.trespassing;
        if (["CLOTHING_WORKCLOTHES", "CLOTHING_HARDHAT"]
            .contains(cr.clothing.type.idName)) {
          uniformed = DisguiseQuality.inconspicuous;
        }
        if (activeSite!.hasHighSecurity &&
            cr.clothing.type.idName == "CLOTHING_SECURITYUNIFORM") {
          uniformed = DisguiseQuality.inconspicuous;
        }
      case SiteType.nuclearPlant:
        if (levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0) {
          uniformed = DisguiseQuality.trespassing;
          if ([
            "CLOTHING_SECURITYUNIFORM",
            "CLOTHING_LABCOAT",
            "CLOTHING_CIVILLIANARMOR",
            "CLOTHING_HARDHAT"
          ].contains(cr.clothing.type.idName)) {
            uniformed = DisguiseQuality.inconspicuous;
          }
        }
      case SiteType.corporateHQ:
        uniformed = DisguiseQuality.trespassing;
        if ([
          "CLOTHING_BLACKSUIT",
          "CLOTHING_BLACKDRESS",
          "CLOTHING_CHEAPSUIT",
          "CLOTHING_CHEAPDRESS",
          "CLOTHING_EXPENSIVESUIT",
          "CLOTHING_EXPENSIVEDRESS",
          "CLOTHING_SECURITYUNIFORM",
        ].contains(cr.clothing.type.idName)) {
          uniformed = DisguiseQuality.inconspicuous;
        }
      case SiteType.ceoHouse:
        uniformed = DisguiseQuality.trespassing;
        if ([
          "CLOTHING_BLACKSUIT",
          "CLOTHING_BLACKDRESS",
          "CLOTHING_EXPENSIVESUIT",
          "CLOTHING_EXPENSIVEDRESS",
          "CLOTHING_SECURITYUNIFORM",
          "CLOTHING_SERVANTUNIFORM",
        ].contains(cr.clothing.type.idName)) {
          uniformed = DisguiseQuality.inconspicuous;
        }
        if (activeSite!.hasHighSecurity) {
          if (["CLOTHING_MILITARY", "CLOTHING_ARMYARMOR"]
              .contains(cr.clothing.type.idName)) {
            uniformed = DisguiseQuality.inconspicuous;
          }
        }
      case SiteType.amRadioStation:
        if (levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0) {
          uniformed = DisguiseQuality.trespassing;
          if ([
            "CLOTHING_SECURITYUNIFORM",
            "CLOTHING_EXPENSIVESUIT",
            "CLOTHING_CHEAPSUIT",
            "CLOTHING_EXPENSIVEDRESS",
            "CLOTHING_CHEAPDRESS"
          ].contains(cr.clothing.type.idName)) {
            uniformed = DisguiseQuality.inconspicuous;
          }
        }
      case SiteType.cableNewsStation:
        if (levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0) {
          uniformed = DisguiseQuality.trespassing;
          if ([
            "CLOTHING_SECURITYUNIFORM",
            "CLOTHING_EXPENSIVESUIT",
            "CLOTHING_EXPENSIVEDRESS",
          ].contains(cr.clothing.type.idName)) {
            uniformed = DisguiseQuality.inconspicuous;
          }
        }
      case SiteType.tenement:
      case SiteType.apartment:
      case SiteType.upscaleApartment:
        if (levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0) {
          uniformed = DisguiseQuality.trespassing;
        }
      default:
        break;
    }
  }

  if (uniformed == DisguiseQuality.trespassing) {
    if (["CLOTHING_POLICEUNIFORM", "CLOTHING_POLICEARMOR", "CLOTHING_SWATARMOR"]
        .contains(cr.clothing.type.idName)) {
      uniformed = DisguiseQuality.authorityFigure;
    }
    if (deathSquadsActive &&
        ["CLOTHING_DEATHSQUADUNIFORM", "CLOTHING_DEATHSQUADBODYARMOR"]
            .contains(cr.clothing.type.idName)) {
      uniformed = DisguiseQuality.authorityFigure;
    }
    if (siteOnFire && cr.clothing.type.idName == "CLOTHING_BUNKERGEAR") {
      uniformed = DisguiseQuality.inconspicuous;
    }
  }

  if (uniformed != DisguiseQuality.trespassing) {
    int qlmax = cr.clothing.type.qualityLevels;
    int ql = cr.clothing.quality + (cr.clothing.damaged ? 1 : 0);
    if (ql > qlmax) // Shredded clothes are obvious
    {
      uniformed = DisguiseQuality.disturbing;
    } else if ((ql - 1) * 2 > qlmax) // poor clothes make a poor disguise
    {
      uniformed = DisguiseQuality.unusual;
    }
  }

  return uniformed;
}

/* returns true if the entire site is not open to public */
bool disguisesite(SiteType type) {
  switch (type) {
    case SiteType.cosmeticsLab:
    case SiteType.geneticsLab:
    case SiteType.prison:
    case SiteType.intelligenceHQ:
    case SiteType.sweatshop:
    case SiteType.dirtyIndustry:
    case SiteType.corporateHQ:
    case SiteType.ceoHouse:
    case SiteType.barAndGrill:
      return true;
    default:
      return false;
  }
}
