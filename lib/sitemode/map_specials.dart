// ignore_for_file: constant_identifier_names

import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_actions/common_actions.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/ammo.dart';
import 'package:lcs_new_age/items/ammo_type.dart';
import 'package:lcs_new_age/items/clothing.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/loot.dart';
import 'package:lcs_new_age/items/money.dart';
import 'package:lcs_new_age/items/weapon.dart';
import 'package:lcs_new_age/items/weapon_type.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/sitemode/advance.dart';
import 'package:lcs_new_age/sitemode/fight.dart';
import 'package:lcs_new_age/sitemode/miscactions.dart';
import 'package:lcs_new_age/sitemode/newencounter.dart';
import 'package:lcs_new_age/sitemode/site_display.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';
import 'package:lcs_new_age/sitemode/sitemode.dart';
import 'package:lcs_new_age/sitemode/stealth.dart';
import 'package:lcs_new_age/talk/talk.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> useTileSpecial() async {
  switch (currentTile.special) {
    case TileSpecial.cagedRabbits:
      await specialLabCosmeticsCagedAnimals();
    case TileSpecial.nuclearControlRoom:
      await specialNuclearOnOff();
    case TileSpecial.cagedMonsters:
      await specialLabGeneticCagedAnimals();
    case TileSpecial.policeStationLockup:
      await specialPoliceStationLockup();
    case TileSpecial.courthouseLockup:
      await specialCourthouseLockup();
    case TileSpecial.courthouseJuryRoom:
      await specialCourthouseJury();
    case TileSpecial.prisonControl:
    case TileSpecial.prisonControlLow:
    case TileSpecial.prisonControlMedium:
    case TileSpecial.prisonControlHigh:
      await specialPrisonControl(currentTile.special);
    case TileSpecial.intelSupercomputer:
      await specialIntelSupercomputer();
    case TileSpecial.sweatshopEquipment:
      await specialSweatshopEquipment();
    case TileSpecial.polluterEquipment:
      await specialPolluterEquipment();
    case TileSpecial.labEquipment:
      await specialLabEquipment();
    case TileSpecial.ceoSafe:
      await specialCEOSafe();
    case TileSpecial.armory:
      await specialArmory();
    case TileSpecial.corporateFiles:
      await specialCorporateSafe();
    case TileSpecial.radioBroadcastStudio:
      await specialRadioBroadcastStudio();
    case TileSpecial.cableBroadcastStudio:
      await specialCableBroadcastStudio();
    case TileSpecial.signOne:
      await specialReadSign(TileSpecial.signOne);
    case TileSpecial.signTwo:
      await specialReadSign(TileSpecial.signTwo);
    case TileSpecial.signThree:
      await specialReadSign(TileSpecial.signThree);
    case TileSpecial.stairsUp:
      locz++;
    case TileSpecial.stairsDown:
      locz--;
    case TileSpecial.displayCase:
      await specialDisplayCase();
    case TileSpecial.bankVault:
      await specialBankVault();
    case TileSpecial.bankMoney:
      await specialBankMoney();
    case TileSpecial.ccsBoss:
    case TileSpecial.bankTeller:
    case TileSpecial.ovalOfficeNW:
    case TileSpecial.ovalOfficeNE:
    case TileSpecial.ovalOfficeSW:
    case TileSpecial.ovalOfficeSE:
    case TileSpecial.ceoOffice:
    case TileSpecial.apartmentLandlord:
    case TileSpecial.table:
    case TileSpecial.computer:
    case TileSpecial.tent:
    case TileSpecial.parkBench:
    case TileSpecial.clubBouncer:
    case TileSpecial.clubBouncerSecondVisit:
    case TileSpecial.securityCheckpoint:
    case TileSpecial.securityMetalDetectors:
    case TileSpecial.securitySecondVisit:
      break; // Behavior triggers on entering tile, not using special
    case TileSpecial.none:
  }
}

const int REJECTED_CCS = 0;
const int REJECTED_NUDE = 1;
const int REJECTED_WEAPONS = 2;
const int REJECTED_UNDERAGE = 3;
const int REJECTED_TRANS = 4;
const int REJECTED_FEMALE = 5;
const int REJECTED_BLOODYCLOTHES = 6;
const int REJECTED_DAMAGEDCLOTHES = 7;
const int REJECTED_CROSSDRESSING = 8;
const int REJECTED_GUESTLIST = 9;
const int REJECTED_DRESSCODE = 10;
const int REJECTED_SECONDRATECLOTHES = 11;
const int REJECTED_SMELLFUNNY = 12;
const int NOT_REJECTED = 13;

void specialBouncerGreetSquad() {
  // add a bouncer if there isn't one in the first slot
  if (!siteAlarm &&
      activeSite!.controller != SiteController.lcs &&
      !encounter.any((e) =>
          e.type.id == CreatureTypeIds.bouncer ||
          e.type.id == CreatureTypeIds.ccsVigilante)) {
    if (activeSite!.controller == SiteController.ccs) {
      encounter.add(Creature.fromId(CreatureTypeIds.ccsVigilante));
      encounter.add(Creature.fromId(CreatureTypeIds.ccsVigilante));
    } else {
      encounter.add(Creature.fromId(CreatureTypeIds.bouncer));
      encounter.add(Creature.fromId(CreatureTypeIds.bouncer));
    }
  }
}

Future<void> specialBouncerAssessSquad() async {
  if (activeSite!.controller == SiteController.lcs) return;

  bool autoadmit = false;
  encounter.clear();

  specialBouncerGreetSquad();
  if (encounter.isEmpty) return;

  printEncounter();
  Creature? sleeper = pool.firstWhereOrNull(
      (p) => p.base == activeSite && p.type.id == encounter[0].type.id);
  if (sleeper != null) {
    autoadmit = true;
    encounter[0] = sleeper;
    levelMap[locx][locy][locz].special = TileSpecial.none;
    await encounterMessage(
        "Sleeper ${sleeper.name} smirks and lets the squad in.");
  } else {
    levelMap[locx][locy][locz].special = TileSpecial.clubBouncerSecondVisit;
    if (activeSite!.controller == SiteController.ccs &&
        activeSite!.type != SiteType.barAndGrill) {
      await encounterMessage("The Conservative scum block the door.");
    } else {
      await encounterMessage("The bouncer assesses your squad.");
    }
  }

  int rejected = NOT_REJECTED;
  void reject(int reason) {
    if (reason < rejected) rejected = reason;
  }

  // Size up the squad for entry
  if (!autoadmit) {
    for (Creature s in squad) {
      // Wrong clothes? Gone
      if (s.indecent) reject(REJECTED_NUDE);
      if (disguiseQuality(s) == DisguiseQuality.trespassing) {
        reject(REJECTED_DRESSCODE);
      }
      // Busted, cheap, bloody clothes? Gone
      if (s.clothing.bloody) reject(REJECTED_BLOODYCLOTHES);
      if (s.clothing.damaged) reject(REJECTED_DAMAGEDCLOTHES);
      if (s.clothing.quality != 1) reject(REJECTED_SECONDRATECLOTHES);
      if (s.gender == Gender.female &&
          laws[Law.genderEquality] == DeepAlignment.archConservative) {
        reject(REJECTED_FEMALE);
      }
      // Suspicious weapons? Gone
      if (weaponCheck(s) == WeaponCheckResult.suspicious) {
        reject(REJECTED_WEAPONS);
      }
      // Underage? Gone
      if (s.age < 21) reject(REJECTED_UNDERAGE);
      // Must pass disguise check unless you're dressed as cops;
      // harder if you're trans at the Desert Eagle Bar & Grill
      if (!s.clothing.type.police) {
        if (siteType == SiteType.barAndGrill &&
            s.genderAssignedAtBirth != s.gender &&
            laws[Law.lgbtRights] != DeepAlignment.eliteLiberal) {
          if (disguisesite(siteType) &&
              !s.skillCheck(Skill.disguise, Difficulty.hard)) {
            reject(REJECTED_TRANS);
          }
        } else {
          if (disguisesite(siteType) &&
              !s.skillCheck(Skill.disguise, Difficulty.average)) {
            reject(REJECTED_SMELLFUNNY);
          }
        }
      }
      // High security in gentleman's club? Gone
      if (siteType == SiteType.barAndGrill && activeSite!.hasHighSecurity) {
        reject(REJECTED_GUESTLIST);
      }
      if (activeSite!.controller == SiteController.ccs &&
          activeSite!.type != SiteType.barAndGrill) {
        rejected = REJECTED_CCS;
      }
    }
    move(10, 1);
    switch (rejected) {
      case REJECTED_CCS:
        setColor(red);
        addstr([
          "\"Can I see... heh heh... some ID?\"",
          "\"Woah... you think you're coming in here?\"",
          "\"Check out this fool. Heh.\"",
          "\"Want some trouble, dumpster breath?\"",
          "\"You're gonna stir up the hornet's nest, fool.\"",
          "\"Come on, take a swing at me. Just try it.\"",
          "\"You really don't want to fuck with me.\"",
          "\"Hey girly, have you written your will?\"",
          "\"Oh, you're trouble. I *like* trouble.\"",
          "\"I'll bury you in those planters over there.\"",
          "\"Looking to check on the color of your blood?\"",
        ].random);
      case REJECTED_NUDE:
        setColor(red);
        addstr([
          "\"No shirt, no underpants, no service.\"",
          "\"Put some clothes on! That's disgusting.\"",
          "\"No! No, you can't come in naked! God!!\"",
          "\"Naked? ${noProfanity ? "[I won't look.]" : "That's hot."} But no, you can't come in.\"",
          "\"${noProfanity ? "[Yuck!]" : "Fuck!"} I did not want to see your naked ${noProfanity ? "[body]" : "ass"}.\"",
        ].random);
      case REJECTED_UNDERAGE:
        setColor(red);
        addstr([
          "\"ID? No? Come back when you're older.\"",
          "\"I'm gonna need to see some ID.\"",
          "\"Drinking age is 21, mate.\"",
          "\"You look a bit young for this place.\"",
          "\"Must be 21 or older to enter.\"",
        ].random);
      case REJECTED_FEMALE:
        setColor(red);
        addstr([
          "\"Move along ma'am, this club's for men.\"",
          "\"This 'ain't no sewing circle, ma'am.\"",
          "\"Leave, female.\"",
          "\"Where's your husband?\"",
        ].random);
      case REJECTED_TRANS:
        setColor(red);
        addstr([
          "\"I smell trangenderism. Get out.\"",
          "\"Ugh, trans people. ${noProfanity ? "[Heavens]" : "Hell"} no.\"",
          "\"Your gender is a disgrace against nature.\"",
          "\"Trans men are men, ${noProfanity ? "[fellow child of God]" : "idiot"}. Get out.\"",
          "\"Trans women are women, ${noProfanity ? "[fellow child of God]" : "moron"}. Leave.\"",
        ].random);
      case REJECTED_DRESSCODE:
        setColor(red);
        addstr([
          "\"Check the dress code.\"",
          "\"We have a dress code here.\"",
          "\"I can't let you in wearing that.\"",
        ].random);
      case REJECTED_SMELLFUNNY:
        setColor(red);
        addstr([
          "\"God, you smell.\"",
          "\"You smell that? Yeah... Liberals...\"",
          "\"Nope. There's something off about you.\"",
          "\"Take a shower, hippie.\"",
          "\"Jesus. Ever heard of deodorant?\"",
          "\"Nah. I can tell this ain't your scene.\"",
        ].random);
      case REJECTED_BLOODYCLOTHES:
        setColor(red);
        addstr([
          "\"Good God! What is wrong with your clothes?\"",
          "\"Absolutely not. Clean up a bit.\"",
          "\"This isn't a goth club, bloody clothes don't cut it here.\"",
          "\"Uh, maybe you should wash... replace... those clothes.\"",
          "\"Did you spill something on your clothes?\"",
          "\"Come back when you get the red wine out of your clothes.\"",
        ].random);
      case REJECTED_DAMAGEDCLOTHES:
        setColor(red);
        addstr([
          "\"Good God! What is wrong with your clothes?\"",
          "\"This isn't a goth club, ripped clothes don't cut it here.\"",
        ].random);
      case REJECTED_SECONDRATECLOTHES:
        setColor(red);
        addstr([
          "\"Do you shop at a dumpster or a thrift store?\"",
          "\"I'm gonna guess you sew your own clothes.\"",
          "\"If badly cut clothing is a hot new trend, I missed it.\"",
          "\"That doesn't... that doesn't even fit you.\"",
        ].random);
      case REJECTED_WEAPONS:
        setColor(red);
        addstr([
          "\"No weapons allowed.\"",
          "\"I can't let you in carrying that.\"",
          "\"I can't let you take that in.\"",
          "\"Come to me armed, and I'll tell you to take a hike.\"",
          "\"Real men fight with fists. And no, you can't come in.\"",
        ].random);
      case REJECTED_GUESTLIST:
        setColor(red);
        addstr("\"VIPs only for now, due to recent events.\"");
      case NOT_REJECTED:
        setColor(lightGreen);
        addstr([
          "\"Keep it civil and don't drink too much.\"",
          "\"Let me get the door for you.\"",
          "\"Ehh, alright, go on in.\"",
          "\"Come on in.\"",
        ].random);
    }

    await getKey();
  } else {
    encounter.removeAt(0);
  }
  setColor(white);
  for (int dx = -1; dx <= 1; dx++) {
    for (int dy = -1; dy <= 1; dy++) {
      SiteTile tile = levelMap[locx + dx][locy + dy][locz];
      if (tile.door) {
        if (rejected < NOT_REJECTED) {
          tile.locked = true;
          tile.cantUnlock = true;
        } else {
          tile.door = false;
        }
      }
    }
  }
  if (!autoadmit) {
    encounter.firstOrNull?.isWillingToTalk = false;
    encounter.firstOrNull?.noticedParty = true;
  }
}

Future<void> specialLabCosmeticsCagedAnimals() async {
  bool freeThem = await sitemodePrompt(
      "You see animals in a sealed cage.", "Free them? (Yes or No)");
  if (!freeThem) return;

  UnlockResult result = await unlock(UnlockTypes.cage);

  if (result == UnlockResult.unlocked) {
    delayedSuspicion(20 + lcsRandom(10));

    siteCrime++;
    juiceparty(3, 100);
    sitestory!.drama.add(Drama.freeRabbits);
  }

  if (result != UnlockResult.noAttempt) {
    await noticeCheck();
    levelMap[locx][locy][locz].special = TileSpecial.none;
  }
}

Future<void> specialReadSign(TileSpecial sign) async {
  clearMessageArea();
  setColor(white);

  switch (sign) {
    case TileSpecial.signOne:
      switch (activeSite!.type) {
        case SiteType.nuclearPlant:
          mvaddstr(9, 1, "Welcome to the NPP Nuclear Plant. Please enjoy");
          mvaddstr(10, 1, "the museum displays in the gift shop.");
        case SiteType.tenement:
        case SiteType.apartment:
        case SiteType.upscaleApartment:
          mvaddstr(9, 1, "The landlord's office is the first door");
          mvaddstr(10, 1, "on the left.");
        default:
          mvaddstr(9, 1, "\"Keep Calm and Carry On\"");
      }
    case TileSpecial.signTwo:
      switch (activeSite!.type) {
        default:
          mvaddstr(9, 1, "\"Great work is done by people who do great work.\"");
      }
    case TileSpecial.signThree:
      switch (activeSite!.type) {
        default:
          mvaddstr(9, 1, "Employees Only");
      }
    default:
      mvaddstr(9, 1, "\"The best way not to fail is to succeed.\"");
  }

  await getKey();
}

Future<void> specialNuclearOnOff() async {
  bool pressIt;
  if (laws[Law.nuclearPower] == DeepAlignment.eliteLiberal) {
    pressIt = await sitemodePrompt(
        "You see the nuclear waste center control room.",
        "Release nuclear waste?");
  } else {
    pressIt = await sitemodePrompt(
        "You see the nuclear power plant control room.",
        "Mess with the reactor?");
  }
  if (!pressIt) return;

  clearMessageArea();
  levelMap[locx][locy][locz].special = TileSpecial.none;

  Creature? maxs;
  for (Creature p in activeSquad!.livingMembers) {
    if (p.skillCheck(Skill.science, Difficulty.hard)) {
      maxs = p;
      break;
    }
  }

  if (maxs != null) {
    mvaddstrc(9, 1, white, maxs.name);
    addstr(" presses the big red button!");
    await getKey();

    mvaddstr(10, 1, ".");
    await getKey();
    addstr(".");
    await getKey();
    addstr(".");
    await getKey();

    if (laws[Law.nuclearPower] == DeepAlignment.eliteLiberal) {
      mvaddstr(9, 1, "Nuclear waste is released into the water!");
      await getKey();
      mvaddstr(10, 1, "But why?  The squad feels a bit Conservative.");
      await getKey();

      changePublicOpinion(View.nuclearPower, 15);
      changePublicOpinion(View.lcsLiked, -50);

      juiceparty(-40, -50);
      maxs.stunned = 15;
      siteCrime += 25; //Shutdown Site

      sitestory!.drama.add(Drama.shutDownReactor);
    } else {
      await encounterMessage("The lights go out as the reactor shuts down!",
          line2: "Power must be out statewide...");

      changePublicOpinion(View.nuclearPower, 15);

      juiceparty(100, 1000); // Instant juice!
      siteCrime += 50; //Shutdown Site

      sitestory!.drama.add(Drama.shutDownReactor);
    }
  } else {
    await encounterMessage(
        "After some failed attempts, and a very loud alarm, ",
        line2: "the Squad resigns to just leaving a threatening note.");

    juiceparty(15, 500);
  }
  siteAlarm = true;
  levelMap[locx][locy][locz].special = TileSpecial.none;
  siteCrime += 5;
  addPotentialCrime(squad, Crime.terrorism);
}

Future<void> specialLabGeneticCagedAnimals() async {
  bool freeThem = await sitemodePrompt(
      "You see horrible misshapen creatures in a sealed cage.",
      "Free them? (Yes or No)");
  if (!freeThem) return;

  UnlockResult result = await unlock(UnlockTypes.cageHard);
  if (result == UnlockResult.unlocked) {
    delayedSuspicion(20 + lcsRandom(10));
    siteCrime++;
    juiceparty(5, 200);
    sitestory!.drama.add(Drama.freeMonsters);
    if (oneIn(2)) {
      fillEncounter(CreatureTypeIds.genetic, lcsRandom(6) + 1);
      if (squad.isNotEmpty && encounter.isNotEmpty) {
        await talk(squad.first, encounter.first);
        if (encounter.first.align == Alignment.conservative) {
          siteAlarm = true;
        } else if (siteAlarmTimer > 1) {
          siteAlarmTimer = 1;
        }
      }
    }
  } else if (result != UnlockResult.noAttempt) {
    await noticeCheck();
  }

  if (result != UnlockResult.noAttempt) {
    levelMap[locx][locy][locz].special = TileSpecial.none;
  }
}

Future<void> specialPoliceStationLockup() async {
  bool freeThem = await sitemodePrompt(
      "You see prisoners in the detention room.", "Free them? (Yes or No)");
  if (!freeThem) return;

  UnlockResult result = await unlock(UnlockTypes.cell);
  if (result == UnlockResult.unlocked) {
    fillEncounter(CreatureTypeIds.prisoner, lcsRandom(8) + 2);
    juiceparty(50, 1000);
    siteCrime += 20;
    delayedSuspicion(20 + lcsRandom(10));
    printEncounter();
    refresh();
    await partyrescue(TileSpecial.policeStationLockup);
  }

  if (result != UnlockResult.noAttempt) {
    await noticeCheck(difficulty: Difficulty.hard);
    levelMap[locx][locy][locz].special = TileSpecial.none;
    siteCrime += 2;
    addDramaToSiteStory(Drama.openedPoliceLockup);
    addPotentialCrime(squad, Crime.aidingEscape);
  }
}

Future<void> specialCourthouseLockup() async {
  bool freeThem = await sitemodePrompt(
      "You see prisoners in the Courthouse jail.", "Free them? (Yes or No)");
  if (!freeThem) return;

  UnlockResult result = await unlock(UnlockTypes.cell);
  if (result == UnlockResult.unlocked) {
    fillEncounter(CreatureTypeIds.prisoner, lcsRandom(8) + 2);
    juiceparty(50, 1000);
    siteCrime += 20;
    delayedSuspicion(20 + lcsRandom(10));
    printEncounter();
    refresh();
    await partyrescue(TileSpecial.courthouseLockup);
  }

  if (result != UnlockResult.noAttempt) {
    await noticeCheck(difficulty: Difficulty.hard);
    levelMap[locx][locy][locz].special = TileSpecial.none;
    siteCrime += 3;
    addDramaToSiteStory(Drama.openedCourthouseLockup);
    addPotentialCrime(squad, Crime.aidingEscape);
  }
}

Future<void> specialCourthouseJury() async {
  if (siteAlarm) {
    await encounterMessage("It appears as if this room has been ",
        line2: "vacated in a hurry.", color: white);
    return;
  }

  bool influenceThem = await sitemodePrompt(
      "You've found a Jury in deliberations!",
      "Attempt to influence them? (Yes or No)");
  if (!influenceThem) return;

  levelMap[locx][locy][locz].special = TileSpecial.none;

  bool succeed = false;
  int maxattack = 0;
  late Creature maxp;

  for (Creature p in activeSquad!.livingMembers) {
    if (p.attribute(Attribute.charisma) +
            p.attribute(Attribute.intelligence) +
            p.skill(Skill.persuasion) +
            p.skill(Skill.law) >
        maxattack) {
      maxattack = p.attribute(Attribute.charisma) +
          p.attribute(Attribute.intelligence) +
          p.skill(Skill.persuasion) +
          p.skill(Skill.law);
      maxp = p;
    }
  }

  maxp.train(Skill.persuasion, 50);
  maxp.train(Skill.law, 50);
  for (Creature p in activeSquad!.livingMembers) {
    if (p != maxp) {
      p.train(Skill.persuasion, 25);
      p.train(Skill.law, 25);
    }
  }

  bool successPersuasion = maxp.skillCheck(Skill.persuasion, Difficulty.hard);
  bool successLaw = maxp.skillCheck(Skill.law, Difficulty.challenging);

  if (successPersuasion && successLaw) {
    succeed = true;
  }

  String crime = [
    "murder",
    "assault",
    "theft",
    "mugging",
    "burglary",
    "property destruction",
    "vandalism",
    "libel",
    "slander",
    "sodomy",
    "obstruction of justice",
    "breaking and entering",
    "public indecency",
    "arson",
    "resisting arrest",
    "tax evasion",
    "adultery",
    "homosexuality",
  ].random;
  if (succeed) {
    if (laws[Law.deathPenalty] == DeepAlignment.archConservative) {
      await encounterMessage(
          "${maxp.name} works the room like in Twelve Angry Men, and the jury ",
          line2: "concludes that $crime isn't worth yet another execution.");
      addjuice(maxp, 25, 1000);
    } else {
      await encounterMessage(
          "${maxp.name} works the room like in Twelve Angry Men, and the jury ",
          line2: "concludes that $crime wasn't really wrong here.");
      addjuice(maxp, 25, 200);
    }
  } else {
    if (successPersuasion) {
      await encounterMessage(
          "${maxp.name} charms the jury into not calling the guards, but fails ",
          line2: "to show why $crime should go unpunished.");
    } else if (successLaw) {
      await encounterMessage(
          "${maxp.name} presents a complex lecture on the many nuances of ",
          line2: "the law around $crime, but the jurors just fall asleep.");
    } else {
      await encounterMessage(
          "${maxp.name} tries to work the room like in Twelve Angry Men, but ",
          line2: "only manages to produce Twelve Angry Jurors.");
      fillEncounter(CreatureTypeIds.juror, 12);
      printEncounter();
      siteAlarm = true;
      siteCrime += 10;
    }

    addDramaToSiteStory(Drama.juryTampering);
    addPotentialCrime(squad, Crime.juryTampering);
  }
}

Future<void> specialPrisonControl(TileSpecial prisonControlType) async {
  String level = switch (prisonControlType) {
    TileSpecial.prisonControlLow => "low security",
    TileSpecial.prisonControlMedium => "medium security",
    TileSpecial.prisonControlHigh => "high security",
    _ => ""
  };
  bool freeThem = await sitemodePrompt(
      "You've found the $level prison control room.",
      "Free the prisoners? (Yes or No)");
  if (!freeThem) return;

  int numleft = lcsRandom(8) + 2;
  if (prisonControlType == TileSpecial.prisonControlLow) {
    switch (laws[Law.deathPenalty]) {
      case DeepAlignment.conservative:
        numleft = lcsRandom(6) + 2;
      case DeepAlignment.moderate:
        numleft = lcsRandom(3) + 1;
      default:
    }
  } else if (prisonControlType == TileSpecial.prisonControlMedium) {
    switch (laws[Law.deathPenalty]) {
      case DeepAlignment.eliteLiberal:
        numleft = lcsRandom(4) + 1;
      case DeepAlignment.liberal:
        numleft = lcsRandom(6) + 1;
      default:
    }
  } else if (prisonControlType == TileSpecial.prisonControlHigh) {
    switch (laws[Law.deathPenalty]) {
      case DeepAlignment.eliteLiberal:
        numleft = 0;
      case DeepAlignment.liberal:
        numleft = lcsRandom(4);
      case DeepAlignment.conservative:
        numleft += lcsRandom(4);
      case DeepAlignment.archConservative:
        numleft += lcsRandom(4) + 2;
      default:
    }
  }

  fillEncounter(CreatureTypeIds.prisoner, numleft);
  delayedSuspicion(20 + lcsRandom(10));

  printEncounter();
  refresh();

  addPotentialCrime(squad, Crime.aidingEscape);
  await partyrescue(prisonControlType);

  await noticeCheck();
  levelMap[locx][locy][locz].special = TileSpecial.none;
  siteCrime += 30;
  juiceparty(50, 1000);
  addDramaToSiteStory(Drama.releasedPrisoners);
}

Future<void> specialIntelSupercomputer() async {
  if (siteAlarm) {
    await encounterMessage("The security alert has caused the ",
        line2: "computer to shut down.");
    return;
  }

  bool hackIt = await sitemodePrompt(
      "You've found the Intelligence Supercomputer.", "Hack it? (Yes or No)");
  if (!hackIt) return;

  UnlockResult result = await hack(HackTypes.supercomputer);

  if (result == UnlockResult.unlocked) {
    clearMessageArea();

    mvaddstrc(9, 1, white, "The Squad obtains sensitive information");
    if (ccsActive && ccsExposure == CCSExposure.none) {
      addstr(",");
      mvaddstr(10, 1, "including a list of government backers of the CCS.");

      Item it = Loot("LOOT_CCS_BACKERLIST");
      activeSquad!.loot.add(it);

      ccsExposure = CCSExposure.lcsGotData;
    } else {
      addstr(".");
    }

    juiceparty(50, 1000);

    Item it = Loot("LOOT_INTHQDISK");
    activeSquad!.loot.add(it);

    await getKey();
  }

  if (result != UnlockResult.noAttempt) {
    await noticeCheck();
    levelMap[locx][locy][locz].special = TileSpecial.none;
    siteCrime += 3;
    addDramaToSiteStory(Drama.hackedIntelSupercomputer);

    addPotentialCrime(squad, Crime.treason);
  }
}

Future<void> specialGraffiti() async {
  await encounterMessage("The squad sprays Liberal Graffiti!", color: white);

  sitestory?.claimed = 2;

  delayedSuspicion(20 + lcsRandom(10));

  await noticeCheck(difficulty: Difficulty.hard);

  levelMap[locx][locy][locz]
    ..graffitiLCS = true
    ..graffitiCCS = false
    ..graffitiOther = false;
  if (!activeSite!.hasHighSecurity) {
    // Erase any previous semi-permanent graffiti here
    activeSite!.changes.removeWhere((element) =>
        element.x == locx &&
        element.y == locy &&
        element.z == locz &&
        (element.flag == SITEBLOCK_GRAFFITI ||
            element.flag == SITEBLOCK_GRAFFITI_CCS ||
            element.flag == SITEBLOCK_GRAFFITI_OTHER));

    // Add new semi-permanent graffiti
    activeSite!.changes
        .add(SiteTileChange(locx, locy, locz, SITEBLOCK_GRAFFITI));
  }
  siteCrime++;
  juiceparty(1, 50);

  addPotentialCrime(squad, Crime.vandalism);
  addDramaToSiteStory(Drama.tagging);

  return;
}

Future<bool> sitemodePromptOneLine(String line) async {
  clearMessageArea();

  mvaddstrc(9, 1, white, line);

  while (true) {
    int c = await getKey();

    if (c == Key.y) return true;
    if (c == Key.n) return false;
  }
}

Future<bool> sitemodePrompt(String line1, String line2) async {
  clearMessageArea();

  mvaddstrc(9, 1, white, line1);

  mvaddstr(10, 1, line2);

  while (true) {
    int c = await getKey();

    if (c == Key.y) return true;
    if (c == Key.n) return false;
  }
}

Future<void> encounterMessage(String message,
    {String? line2, Color color = white}) async {
  clearMessageArea();

  mvaddstrc(9, 1, color, message);

  if (line2 != null) {
    mvaddstr(10, 1, line2);
  }

  await getKey();
}

void delayedSuspicion(int time) {
  if (time < 1) time = 1;
  if (siteAlarmTimer > time || siteAlarmTimer == -1) siteAlarmTimer = time;
}

Future<void> specialSweatshopEquipment() async {
  bool smash = await sitemodePrompt(
      "You see some textile equipment.", "Destroy it? (Yes or No)");
  if (!smash) return;

  await _vandalizeTile();
}

Future<void> specialPolluterEquipment() async {
  bool smash = await sitemodePrompt(
      "You see some industrial equipment.", "Destroy it? (Yes or No)");
  if (!smash) return;

  changePublicOpinion(View.pollution, 2, coloredByLcsOpinions: true);

  await _vandalizeTile();
}

Future<void> specialLabEquipment() async {
  bool smash = await sitemodePrompt(
      "You see some lab equipment.", "Destroy it? (Yes or No)");
  if (!smash) return;

  changePublicOpinion(View.animalResearch, 2, coloredByLcsOpinions: true);

  await _vandalizeTile();
}

Future<void> _vandalizeTile() async {
  delayedSuspicion(20 + lcsRandom(10));

  await noticeCheck(difficulty: Difficulty.heroic);
  levelMap[locx][locy][locz].special = TileSpecial.none;
  levelMap[locx][locy][locz].debris = true;
  siteCrime += 2;
  juiceparty(5, 200);
  addDramaToSiteStory(Drama.vandalism);
  addPotentialCrime(squad, Crime.vandalism);
}

void _loot(Item item) => activeSquad!.loot.add(item);

void _lootWeapon(String tag, int extraMags) {
  WeaponType weaponType = weaponTypes[tag]!;
  AmmoType? ammoType = weaponType.acceptableAmmo.firstOrNull;
  _loot(Weapon.fromType(weaponType, fullammo: true));
  if (ammoType != null && extraMags > 0) {
    _loot(Ammo(ammoType.idName, stackSize: extraMags));
  }
}

Future<void> specialCEOSafe() async {
  bool crack =
      await sitemodePrompt("You've found a safe.", "Crack it? (Yes or No)");
  if (!crack) return;

  UnlockResult result = await unlock(UnlockTypes.safe);

  if (result == UnlockResult.unlocked) {
    bool empty = true;

    if (!lcsGotDeagle) {
      await encounterMessage("The squad has found a Desert Eagle.");
      _lootWeapon("WEAPON_DESERT_EAGLE", 9);
      lcsGotDeagle = true;
      empty = false;
    }

    if (oneIn(2)) {
      await encounterMessage("This guy sure had a lot of \$100 bills.");
      _loot(Money(1000 * (1 + lcsRandom(10))));
      empty = false;
    }

    if (oneIn(2)) {
      await encounterMessage("The squad Liberates some expensive jewelery.");
      _loot(Loot("LOOT_EXPENSIVEJEWELERY", stackSize: 3));
      empty = false;
    }

    if (oneIn(3)) {
      await encounterMessage(
          "There are some... very compromising photos here.");
      _loot(Loot("LOOT_CEOPHOTOS"));
      empty = false;
    }

    if (oneIn(3)) {
      await encounterMessage("There are some drugs here.");
      empty = false;
    }

    if (oneIn(3)) {
      await encounterMessage("Wow, get a load of these love letters.",
          line2: "The squad will take those.");
      _loot(Loot("LOOT_CEOLOVELETTERS"));
      empty = false;
    }

    if (oneIn(3)) {
      await encounterMessage("These documents show serious tax evasion.");
      _loot(Loot("LOOT_CEOTAXPAPERS"));
      empty = false;
    }

    if (empty) {
      await encounterMessage("Wow, it's empty.  That sucks.");
    } else {
      juiceparty(50, 1000);
      siteCrime += 40;
      addDramaToSiteStory(Drama.openedCEOSafe);
      addPotentialCrime(squad, Crime.theft);
    }
  }

  await noticeCheck();
  levelMap[locx][locy][locz].special = TileSpecial.none;
}

Future<void> specialArmory() async {
  bool smash =
      await sitemodePrompt("You've found the armory.", "Break in? (Yes or No)");
  if (!smash) return;

  siteAlarm = true;
  await encounterMessage("Alarms go off!", color: red);

  setColor(white);
  bool empty = true;
  if (!lcsGotM249 && activeSite!.type == SiteType.armyBase) {
    await encounterMessage("Jackpot! The squad found an XM250 Machine Gun!");
    _lootWeapon("WEAPON_M250_MACHINEGUN", 9);
    lcsGotM249 = true;
    empty = false;
  }

  if (oneIn(2)) {
    await encounterMessage("The squad finds some XM7 Assault Rifles.");
    int num = 0;
    do {
      _lootWeapon("WEAPON_M7", 5);
      num++;
    } while (num < 2 || (oneIn(2) && num < 5));
    empty = false;
  }

  if (oneIn(2)) {
    await encounterMessage("The squad finds some M4 Carbines.");
    int num = 0;
    do {
      _lootWeapon("WEAPON_M4", 5);
      num++;
    } while (num < 2 || (oneIn(2) && num < 5));
    empty = false;
  }

  if (oneIn(2)) {
    await encounterMessage("The squad finds some body armor.");
    int num = 0;
    do {
      if (activeSite!.type == SiteType.armyBase) {
        _loot(Clothing("CLOTHING_ARMYARMOR"));
      } else {
        _loot(Clothing("CLOTHING_CIVILLIANARMOR"));
      }
      num++;
    } while (num < 2 || (oneIn(2) && num < 5));
    empty = false;
  }

  int numleft;
  if (empty) {
    addPotentialCrime(squad, Crime.treason);
    await encounterMessage("It's a trap!  The armory is empty.");
    numleft = lcsRandom(6) + 4;
  } else {
    juiceparty(50, 1000);
    siteCrime += 40;
    addDramaToSiteStory(Drama.openedArmory);
    addPotentialCrime(squad, Crime.theft);
    addPotentialCrime(squad, Crime.treason);
    await encounterMessage("The guards are coming!");
    numleft = lcsRandom(4) + 2;
  }
  for (int i = 0; i < numleft; i++) {
    if (activeSite!.type == SiteType.armyBase) {
      encounter.add(Creature.fromId(CreatureTypeIds.soldier));
    } else {
      encounter.add(Creature.fromId(CreatureTypeIds.merc));
    }
  }

  levelMap[locx][locy][locz].special = TileSpecial.none;
}

Future<void> specialCorporateSafe() async {
  bool crack =
      await sitemodePrompt("You've found a safe.", "Crack it? (Yes or No)");
  if (!crack) return;

  UnlockResult result = await unlock(UnlockTypes.safe);

  if (result == UnlockResult.unlocked) {
    await encounterMessage("The Squad has found some very interesting files.");

    _loot(Loot("LOOT_CORPFILES"));
    _loot(Loot("LOOT_CORPFILES"));

    juiceparty(50, 1000);
    siteCrime += 40;
  }

  if (result != UnlockResult.noAttempt) {
    await noticeCheck();
    levelMap[locx][locy][locz].special = TileSpecial.none;
    siteCrime += 3;
    addDramaToSiteStory(Drama.stoleCorpFiles);
    addPotentialCrime(squad, Crime.theft);
  }
}

Future<void> specialRadioBroadcastStudio() async {
  bool broadcast;
  if (siteAlarm) {
    broadcast = await sitemodePrompt(
        "The studio is empty, but the equipment is still on.",
        "Start a broadcast? (Yes or No)");
  } else {
    broadcast = await sitemodePrompt("You've found a radio broadcasting room.",
        "Interrupt this evening's programming? (Yes or No)");
  }
  if (!broadcast) return;

  if (await radioBroadcast()) {
    sitestory?.claimed = 2;
    addDramaToSiteStory(Drama.hijackedBroadcast);
    levelMap[locx][locy][locz].special = TileSpecial.none;
  }
}

Future<void> specialCableBroadcastStudio() async {
  bool broadcast;
  if (siteAlarm) {
    broadcast = await sitemodePrompt(
        "The studio is empty, but the equipment is still on.",
        "Start a broadcast? (Yes or No)");
  } else {
    broadcast = await sitemodePrompt(
        "You've found a Cable News broadcasting studio.",
        "Interrupt this evening's programming? (Yes or No)");
  }
  if (!broadcast) return;

  if (await tvBroadcast()) {
    sitestory?.claimed = 2;
    addDramaToSiteStory(Drama.hijackedBroadcast);
    levelMap[locx][locy][locz].special = TileSpecial.none;
  }
}

Future<void> specialDisplayCase() async {
  List<String> items;
  switch (activeSite?.type) {
    case SiteType.barAndGrill:
      items = [
        "some neo-Nazi memorabilia",
        "a Confederate flag",
        "a portrait of Ronald Reagan",
        "a photo of a lynching",
        "white supremacist literature",
        "a portrait of Strom Thurmond",
        "some old records with racist lyrics",
      ];
    case SiteType.courthouse:
      items = [
        "a portrait of Ronald Reagan",
        "a portrait of some old white guy",
        "an old police badge",
        "a copy of the US Constitution",
        "an old photo of the courthouse",
        "an old photo of a hanging",
        "an award from a Conservative group",
        "a bust of some old white guy",
      ];
    default:
      items = [
        "some Conservative memoribilia",
        "a Confederate flag",
        "a portrait of some old white guy",
        "some random pointless shit",
      ];
  }
  String featuring = items.randomSeeded(
      locx + locy * 7 + locz + sites.indexOf(activeSite ?? sites[0]));
  bool smash = await sitemodePrompt(
      "You see a display case containing $featuring.", "Smash it? (Yes or No)");
  if (!smash) return;

  await _vandalizeTile();
}

void spawnSecurity() {
  // add a bouncer if there isn't one in the first slot
  if (!siteAlarm && encounter.isEmpty) {
    switch (activeSite!.type) {
      case SiteType.policeStation:
      case SiteType.courthouse:
      case SiteType.publicPark:
        encounter.add(Creature.fromId(CreatureTypeIds.cop));
        encounter.add(Creature.fromId(CreatureTypeIds.cop));
      case SiteType.prison:
        encounter.add(Creature.fromId(CreatureTypeIds.prisonGuard));
        encounter.add(Creature.fromId(CreatureTypeIds.prisonGuard));
        encounter.add(Creature.fromId(CreatureTypeIds.guardDog));
      case SiteType.whiteHouse:
        encounter.add(Creature.fromId(CreatureTypeIds.secretService));
        encounter.add(Creature.fromId(CreatureTypeIds.secretService));
        encounter.add(Creature.fromId(CreatureTypeIds.secretService));
        encounter.add(Creature.fromId(CreatureTypeIds.secretService));
      case SiteType.intelligenceHQ:
        encounter.add(Creature.fromId(CreatureTypeIds.agent));
        encounter.add(Creature.fromId(CreatureTypeIds.agent));
        encounter.add(Creature.fromId(CreatureTypeIds.guardDog));
      case SiteType.armyBase:
        encounter.add(Creature.fromId(CreatureTypeIds.militaryPolice));
        encounter.add(Creature.fromId(CreatureTypeIds.militaryPolice));
      case SiteType.barAndGrill:
      case SiteType.bombShelter:
      case SiteType.bunker:
        if (activeSite!.controller == SiteController.ccs) {
          encounter.add(Creature.fromId(CreatureTypeIds.ccsVigilante));
          encounter.add(Creature.fromId(CreatureTypeIds.ccsVigilante));
        }
      case SiteType.corporateHQ:
      case SiteType.ceoHouse:
      case SiteType.bank:
      case SiteType.nuclearPlant:
      default:
        encounter.add(Creature.fromId(CreatureTypeIds.merc));
        encounter.add(Creature.fromId(CreatureTypeIds.merc));
    }
  }
}

Future<void> specialSecurity(bool metaldetect) async {
  bool autoAdmit = false;
  Creature? sleeper;
  encounter.clear();

  spawnSecurity();

  if (encounter.isNotEmpty) {
    for (Creature p in pool) {
      if (p.base == activeSite) {
        autoAdmit = true;
        if (p.type == encounter[0].type) {
          sleeper = p;
          encounter[0] = sleeper;
          encounter[0].isWillingToTalk = false;
          break;
        }
      }
    }
  }
  setColor(white);
  move(9, 1);
  if (siteAlarm) {
    addstr("The security checkpoint is abandoned.");

    levelMap[locx][locy][locz].special = TileSpecial.none;
    return;
  } else if (autoAdmit) {
    addstr("The squad flashes ID badges.");
    metaldetect = false;

    levelMap[locx][locy][locz].special = TileSpecial.securitySecondVisit;
  } else {
    if (metaldetect) {
      addstr("The squad steps into a metal detector.");
    } else {
      addstr("This door is guarded.");
    }

    levelMap[locx][locy][locz].special = TileSpecial.securitySecondVisit;
  }
  printEncounter();

  await getKey();

  int rejectReason = NOT_REJECTED;
  void reject(int newReason) {
    if (newReason < rejectReason) rejectReason = newReason;
  }

  void scanSquad() {
    // Size up the squad for entry
    for (Creature s in squad) {
      // Nudity gets blocked always
      if (s.equippedClothing == null && s.type.animal) reject(REJECTED_NUDE);
      if (!autoAdmit) {
        // Having an employee badge will bypass most checks even
        // if the security guard doesn't work for you
        if (disguiseQuality(s) == DisguiseQuality.trespassing) {
          reject(REJECTED_DRESSCODE);
        }
        if (s.clothing.bloody) reject(REJECTED_BLOODYCLOTHES);
        if (s.clothing.damaged) reject(REJECTED_DAMAGEDCLOTHES);
        if (s.clothing.quality != 1) reject(REJECTED_SECONDRATECLOTHES);
        if (s.age < 16) reject(REJECTED_UNDERAGE);
      }
      if (sleeper == null) {
        // Suspicious weapons blocked unless the security guard
        // works for you
        if (weaponCheck(s, metalDetector: metaldetect) ==
            WeaponCheckResult.suspicious) {
          reject(REJECTED_WEAPONS);
        }
      }
    }
  }

  scanSquad();

  move(10, 1);
  setColor(rejectReason == NOT_REJECTED ? lightGreen : red);
  switch (rejectReason) {
    case REJECTED_NUDE:
      if (autoAdmit) {
        addstr("\"Jesus!! Put some clothes on!\"");
      } else {
        addstr([
          "\"Get out of here you nudist!!\"",
          "\"Back off, creep!\"",
          "\"Jesus!! Put some clothes on!\"",
          "\"Are you sleepwalking?!\"",
        ].random);
      }
    case REJECTED_UNDERAGE:
      addstr([
        "\"Can't come through here, youngster.\"",
        "\"Hey kid. You got a reason to be here?\"",
        "\"No loitering, kid.\"",
        "\"Your parents work here or something?\"",
      ].random);
    case REJECTED_DRESSCODE:
      addstr("\"Employees only.\"");
    case REJECTED_SMELLFUNNY:
      addstr([
        "\"You don't work here, do you?\"",
        "\"Hmm... can I see your badge?\"",
        "\"There's just something off about you.\"",
        "\"You must be new. You'll need your badge.\"",
      ].random);
    case REJECTED_BLOODYCLOTHES:
      addstr([
        "\"Good God! What is wrong with your clothes?\"",
        "\"Are you hurt?! The aid station is the other way!\"",
        "\"Your clothes, that's blood!\"",
        "\"Blood?! That's more than a little suspicious...\"",
        "\"Did you just butcher a cat?!\"",
        "\"Blood everywhere...?\"",
      ].random);
    case REJECTED_DAMAGEDCLOTHES:
      addstr([
        "\"Good God! What is wrong with your clothes?\"",
        "\"Are you okay? Why are your clothes ripped?\"",
      ].random);
    case REJECTED_SECONDRATECLOTHES:
      addstr([
        "\"Did you make that outfit yourself?\"",
        "\"Is that a halloween costume? Who are you?\"",
      ].random);
    case REJECTED_WEAPONS:
      if (metaldetect) {
        addstr("-BEEEP- -BEEEP- -BEEEP-");
        if (politics.laws[Law.gunControl] == DeepAlignment.archConservative) {
          await getKey();
          clearMessageArea();
          mvaddstrc(9, 1, white,
              "The guard sounds incredibly bored and doesn't even glance at the squad.");
          mvaddstrc(
              10,
              1,
              lightGreen,
              [
                "\"Anyone carrying a gun is welcome. Head on in.\"",
                "\"Don't mind it, not sure why we even turn it on.\"",
                "\"Ignore the noise. Keep your gun, just don't shoot nobody.\"",
                "\"Don't mind Metal Mabel here, she's just here to impress Liberals.\"",
                "\"It's a free country. Don't know why we even have this thing.\"",
                "\"Constitution says you can carry guns anywhere you want.\"",
                "\"You've a right to bear arms here or anywhere else.\"",
              ].random);
          rejectReason = NOT_REJECTED;
          metaldetect = false;
          scanSquad();
          switch (rejectReason) {
            case REJECTED_NUDE:
              await encounterMessage(
                  "Better keep moving before the guard notices you're naked...");
            case REJECTED_WEAPONS:
              await encounterMessage(
                  "Better keep moving before the guard notices what you're carrying...");
            case REJECTED_DAMAGEDCLOTHES:
            case REJECTED_BLOODYCLOTHES:
            case REJECTED_DRESSCODE:
            case REJECTED_SECONDRATECLOTHES:
              await encounterMessage(
                  "Better keep moving before the guard notices what you're wearing...");
            case REJECTED_SMELLFUNNY:
            case REJECTED_TRANS:
            case REJECTED_FEMALE:
            case REJECTED_UNDERAGE:
            case REJECTED_GUESTLIST:
            case NOT_REJECTED:
          }
          rejectReason = NOT_REJECTED;
        } else {
          siteAlarm = true;
        }
      } else {
        addstr([
          "\"Put that away!\"",
          "\"Hey, back off!\"",
          "\"Don't try anything!\"",
          "\"Are you here to make trouble?\"",
          "\"Stay back!\"",
        ].random);
      }
    case NOT_REJECTED:
      addstr([
        "\"Move along.\"",
        "\"Have a nice day.\"",
        "\"Quiet day, today.\"",
        "\"Go on in.\"",
      ].random);
  }

  await getKey();

  setColor(white);
  for (SiteTile tile in adjacentTiles(locx, locy, locz)) {
    if (tile.door) {
      if (rejectReason != NOT_REJECTED) {
        tile.locked = true;
        tile.cantUnlock = true;
      } else {
        tile.door = false;
      }
    }
  }
  encounter[0].isWillingToTalk = false;
  encounter[0].noticedParty = true;
}

Future<void> specialSecurityCheckpoint() async {
  await specialSecurity(false);
}

Future<void> specialSecurityMetaldetectors() async {
  await specialSecurity(true);
}

void specialSecuritySecondvisit() {
  spawnSecurity();
}

Future<void> specialBankVault() async {
  await encounterMessage("The vault door has three layers: A combo lock, ",
      line2: "an electronic lock, and a biometric lock.");
  await encounterMessage("The squad will need a security expert, a computer ",
      line2: "expert, and one of the bank managers.");

  for (Creature p in pool) {
    if (p.type.id == CreatureTypeIds.bankManager &&
        p.sleeperAgent &&
        p.base == activeSite) {
      await encounterMessage("Sleeper ${p.name} can handle the biometrics, ",
          line2: "but you'll still have to crack the other locks.");
      break;
    }
  }

  bool open = await sitemodePromptOneLine("Open the bank vault? (Yes or No)");
  if (!open) return;

  await encounterMessage("First is the combo lock that will have to ",
      line2: "be cracked by a security expert.");

  UnlockResult result = await unlock(UnlockTypes.vault);
  if (result != UnlockResult.unlocked) {
    await encounterMessage("The squad can only dream of the money ",
        line2: "on the other side of this door...");
    levelMap[locx][locy][locz].special = TileSpecial.none;
    await noticeCheck(difficulty: Difficulty.challenging);
    return;
  }

  await encounterMessage("Next is the electronic lock that will have to ",
      line2: "be bypassed by a computer expert.");

  result = await hack(HackTypes.vault);
  if (result != UnlockResult.unlocked) {
    await encounterMessage("The money was so close the squad could taste it!");
    levelMap[locx][locy][locz].special = TileSpecial.none;
    await noticeCheck(difficulty: Difficulty.hard);
    return;
  }

  await encounterMessage("Last is the biometric lock keyed only ",
      line2: "to the bank's managers.");

  Creature? manager;
  bool canbreakin = false;

  for (Creature c in squad) {
    if (c.type.id == CreatureTypeIds.bankManager) {
      manager = c;
      if (c.daysSinceJoined < 30 && !c.kidnapped) {
        await encounterMessage("${c.name} opens the vault.");
        canbreakin = true;
        break;
      }
    }

    if (c.prisoner?.type.id == CreatureTypeIds.bankManager) {
      await encounterMessage("The hostage is forced to open the vault.");
      canbreakin = true;
      break;
    }
  }

  if (!canbreakin) {
    for (Creature p in pool) {
      if (p.base == activeSite &&
          p.sleeperAgent &&
          p.type.id == CreatureTypeIds.bankManager) {
        await encounterMessage("Sleeper ${p.name} opens the vault, ",
            line2: "and will join the active LCS to avoid arrest.");
        canbreakin = true;
        p.location = p.base = squad[0].base;
        p.sleeperAgent = false;
        p.activity = Activity.none();
        criminalize(p, Crime.bankRobbery);
        break;
      }
    }
  }

  if (canbreakin) {
    addPotentialCrime(squad, Crime.bankRobbery);
    siteCrime += 20;
    addDramaToSiteStory(Drama.bankVaultRobbery);
    levelMap[locx + 1][locy][locz].flag &= ~SITEBLOCK_DOOR;
    levelMap[locx - 1][locy][locz].flag &= ~SITEBLOCK_DOOR;
    levelMap[locx][locy + 1][locz].flag &= ~SITEBLOCK_DOOR;
    levelMap[locx][locy - 1][locz].flag &= ~SITEBLOCK_DOOR;
    levelMap[locx][locy][locz].special = TileSpecial.none;
  } else {
    if (manager != null) {
      await encounterMessage("${manager.name} is no longer recognized.");
    } else {
      await encounterMessage("The squad has nobody that can do the job.");
    }
  }

  await noticeCheck(difficulty: Difficulty.heroic);
}

Future<void> specialBankTeller() async {
  levelMap[locx][locy][locz].special = TileSpecial.none;
  if (siteAlarm || activeSiteUnderSiege) {
    await encounterMessage("The teller window is empty.");
  } else {
    await encounterMessage("A bank teller is available.");
    encounter.clear();
    encounter.add(Creature.fromId(CreatureTypeIds.bankTeller));
  }
}

int _specialBankMoneySWATCounter = 0;
Future<void> specialBankMoney() async {
  levelMap[locx][locy][locz].special = TileSpecial.none;
  await encounterMessage("The squad loads bricks of cash into a duffel bag.",
      color: lightGreen);

  _loot(Money(20000));
  siteCrime += 20;

  if (postAlarmTimer <= 80) _specialBankMoneySWATCounter = 0;

  if (!siteAlarm && siteAlarmTimer != 0) {
    siteAlarmTimer = 0;
  } else if (!siteAlarm && oneIn(2)) {
    siteAlarm = true;
  } else if (siteAlarm && postAlarmTimer <= 60) {
    postAlarmTimer += 20;
  } else if (siteAlarm && postAlarmTimer <= 80 && oneIn(2)) {
    postAlarmTimer = 81;
  } else if (siteAlarm &&
      postAlarmTimer > 80 &&
      oneIn(2) &&
      _specialBankMoneySWATCounter < 2) {
    setColor(red);
    move(10, 1);
    if (_specialBankMoneySWATCounter > 0) {
      addstr("Another SWAT team moves in!!");
    } else {
      addstr("A SWAT team storms the vault!!");
    }
    _specialBankMoneySWATCounter++;
    for (int i = 0; i < 9; i++) {
      encounter.add(Creature.fromId(CreatureTypeIds.swat));
    }
    printEncounter();
    await getKey();
  }
}

Future<void> specialOvalOffice() async {
  // Clear entire Oval Office area
  for (int dx = -1; dx <= 1; dx++) {
    for (int dy = -1; dy <= 1; dy++) {
      if (levelMap[locx + dx][locy + dy][locz].special ==
              TileSpecial.ovalOfficeNW ||
          levelMap[locx + dx][locy + dy][locz].special ==
              TileSpecial.ovalOfficeNE ||
          levelMap[locx + dx][locy + dy][locz].special ==
              TileSpecial.ovalOfficeSW ||
          levelMap[locx + dx][locy + dy][locz].special ==
              TileSpecial.ovalOfficeSE) {
        levelMap[locx + dx][locy + dy][locz].special = TileSpecial.none;
      }
    }
  }
  printSiteMapSmall(locx, locy, locz);

  encounter.clear();

  if (siteAlarm) {
    await encounterMessage("The President isn't here...");

    mvaddstr(10, 1, "Secret Service agents ambush the squad!");
    for (int e = 0; e < 6; e++) {
      encounter.add(Creature.fromId(CreatureTypeIds.secretService));
    }
    printEncounter();
    await getKey();

    await enemyattack(encounter);
    await creatureadvance();
  } else {
    await encounterMessage("The President is in the Oval Office.");
    if (uniqueCreatures.president.formerHostage &&
        uniqueCreatures.president.align == Alignment.conservative) {
      encounter.add(Creature.fromId(CreatureTypeIds.secretService));
      encounter.add(Creature.fromId(CreatureTypeIds.secretService));
      encounter.add(Creature.fromId(CreatureTypeIds.secretService));
      encounter.add(uniqueCreatures.president);
      encounter.add(Creature.fromId(CreatureTypeIds.secretService));
      encounter.add(Creature.fromId(CreatureTypeIds.secretService));
      encounter.add(Creature.fromId(CreatureTypeIds.secretService));
      printEncounter();
      if (squad.first.genderAssignedAtBirth == Gender.male) {
        await encounterMessage("${uniqueCreatures.president.name} smirks,",
            line2: "\"You got brass fucking balls, I'll give you that.\"");
      } else {
        await encounterMessage("${uniqueCreatures.president.name} smirks,",
            line2: "\"You're a brave fucking girl, I'll give you that.\"");
      }
      siteAlarm = true;

      await enemyattack(encounter);
      await creatureadvance();
    } else {
      encounter.add(Creature.fromId(CreatureTypeIds.secretService));
      encounter.add(uniqueCreatures.president);
      encounter.add(Creature.fromId(CreatureTypeIds.secretService));
      printEncounter();
    }
  }
}

Future<void> specialCCSBoss() async {
  if (activeSite?.controller != SiteController.ccs) {
    await encounterMessage("Cool boss arena. It's empty at the moment.");
    return;
  } else if (siteAlarm || activeSiteUnderSiege) {
    levelMap[locx][locy][locz].special = TileSpecial.none;
    await encounterMessage("The CCS leader is ready for you!");

    encounter.clear();
    encounter.add(Creature.fromId(CreatureTypeIds.ccsArchConservative));
    fillEncounter(CreatureTypeIds.ccsVigilante, 5);
  } else {
    levelMap[locx][locy][locz].special = TileSpecial.none;
    await encounterMessage("The CCS leader is here.");

    encounter.clear();
    encounter.add(Creature.fromId(CreatureTypeIds.ccsArchConservative));
  }
}

Future<void> lootGround() async {
  if (activeSiteUnderSiege) {
    await lootGroundBase();
  } else {
    await lootGroundSite();
  }
}

Future<void> lootGroundBase() async {
  //GRAB SOME OF THE BASE LOOT
  int lcount = 1 + levelMap.all.where((t) => t.loot).length;

  int lplus = activeSite!.loot.length ~/ lcount;
  if (lcount == 1) lplus = activeSite!.loot.length;

  Item it;

  int numLooted = 0;
  for (; lplus > 0; lplus--) {
    it = activeSite!.loot.random;
    addLootToSquad(it);
    activeSite!.loot.remove(it);
    numLooted++;
  }

  if (activeSite!.loot.isEmpty) {
    await encounterMessage(
        "That's the last of the safehouse inventory. Time to go.");
  } else if (numLooted > 1) {
    await encounterMessage(
        "The squad picks up $numLooted items from the safehouse.");
  } else if (numLooted == 1) {
    await encounterMessage("The squad picks up an item from the safehouse.");
  }
}

Future<void> lootGroundSite() async {
  delayedSuspicion(20 + lcsRandom(10));

  Item? item = lootItemForSite(siteType);
  if (item != null) {
    addLootToSquad(item);
    clearMessageArea();
    mvaddstrc(9, 1, lightGray, "You find: ");
    move(10, 1);
    item.printEquipTitle();

    await getKey(); //wait for key press before clearing.
  }
}

Item? lootItemForSite(SiteType site) {
  Item? item;

  String newLootType = "", newWeaponType = "", newArmorType = "";

  switch (site) {
    case SiteType.tenement:
      if (oneIn(25)) {
        List<String> rndWeps = [
          "WEAPON_BASEBALLBAT",
          "WEAPON_CROWBAR",
          "WEAPON_SHANK",
          "WEAPON_SYRINGE",
          "WEAPON_CHAIN",
          "WEAPON_GUITAR",
          "WEAPON_SPRAYCAN"
        ];
        newWeaponType = rndWeps.random;
      } else if (oneIn(20)) {
        List<String> rndArmors = [
          "CLOTHING_CHEAPDRESS",
          "CLOTHING_CHEAPSUIT",
          "CLOTHING_CLOTHES",
          "CLOTHING_TRENCHCOAT",
          "CLOTHING_WORKCLOTHES",
          "CLOTHING_TOGA",
          "CLOTHING_PRISONER"
        ];
        newArmorType = rndArmors.random;
      } else if (oneIn(3)) {
        newLootType = "LOOT_KIDART";
      } else if (oneIn(2)) {
        newLootType = "LOOT_DIRTYSOCK";
      } else {
        newLootType = "LOOT_FAMILYPHOTO";
      }
    case SiteType.bank:
      if (oneIn(4)) {
        newLootType = "LOOT_WATCH";
      } else if (oneIn(3)) {
        newLootType = "LOOT_CELLPHONE";
      } else if (oneIn(2)) {
        newLootType = "LOOT_PDA";
      } else {
        newLootType = "LOOT_COMPUTER";
      }
    case SiteType.apartment:
      if (oneIn(25)) {
        List<String> rndWeps = [
          "WEAPON_BASEBALLBAT",
          "WEAPON_22_REVOLVER",
          "WEAPON_44_REVOLVER",
          "WEAPON_NIGHTSTICK",
          "WEAPON_GUITAR",
        ];
        newWeaponType = rndWeps.random;
      } else if (oneIn(20)) {
        List<String> rndArmors = [
          "CLOTHING_CHEAPDRESS",
          "CLOTHING_CHEAPSUIT",
          "CLOTHING_CLOTHES",
          "CLOTHING_TRENCHCOAT",
          "CLOTHING_WORKCLOTHES",
          "CLOTHING_CLOWNSUIT",
          "CLOTHING_FURSUIT",
        ];
        newArmorType = rndArmors.random;
      } else if (oneIn(5)) {
        newLootType = "LOOT_CELLPHONE";
      } else if (oneIn(4)) {
        newLootType = "LOOT_SILVERWARE";
      } else if (oneIn(3)) {
        newLootType = "LOOT_TRINKET";
      } else if (oneIn(2)) {
        newLootType = "LOOT_CHEAPJEWELERY";
      } else {
        newLootType = "LOOT_COMPUTER";
      }
    case SiteType.upscaleApartment:
      if (oneIn(30)) {
        List<String> rndWeps = [
          "WEAPON_BASEBALLBAT",
          "WEAPON_COMBATKNIFE",
          "WEAPON_DAISHO",
          "WEAPON_PUMP_SHOTGUN",
          "WEAPON_44_REVOLVER",
          "WEAPON_45_HANDGUN",
          "WEAPON_AR15",
          "WEAPON_M4",
        ];
        //make sure the number of types matches the random range...
        newWeaponType = rndWeps[lcsRandom(8 - laws[Law.gunControl]!.index)];
      } else if (oneIn(20)) {
        List<String> rndArmors = [
          "CLOTHING_EXPENSIVEDRESS",
          "CLOTHING_BLACKDRESS",
          "CLOTHING_EXPENSIVESUIT",
          "CLOTHING_BLACKSUIT",
          "CLOTHING_BONDAGEGEAR",
          "CLOTHING_CAMOSUIT",
          "CLOTHING_BLACKROBE",
          "CLOTHING_LABCOAT",
        ];
        newArmorType = rndArmors.random;
      } else if (oneIn(10)) {
        newLootType = "LOOT_EXPENSIVEJEWELERY";
      } else if (oneIn(5)) {
        newLootType = "LOOT_CELLPHONE";
      } else if (oneIn(4)) {
        newLootType = "LOOT_SILVERWARE";
      } else if (oneIn(3)) {
        newLootType = "LOOT_PDA";
      } else if (oneIn(2)) {
        newLootType = "LOOT_CHEAPJEWELERY";
      } else {
        newLootType = "LOOT_COMPUTER";
      }
    case SiteType.cosmeticsLab:
    case SiteType.nuclearPlant:
    case SiteType.geneticsLab:
      if (oneIn(20)) {
        newLootType = "LOOT_RESEARCHFILES";
      } else if (oneIn(2)) {
        newLootType = "LOOT_LABEQUIPMENT";
      } else if (oneIn(2)) {
        newLootType = "LOOT_COMPUTER";
      } else if (oneIn(5)) {
        newLootType = "LOOT_PDA";
      } else if (oneIn(5)) {
        newLootType = "LOOT_CHEMICAL";
      } else {
        newLootType = "LOOT_COMPUTER";
      }
    case SiteType.policeStation:
      if (oneIn(25)) {
        List<String> rndWeps = [
          "WEAPON_NIGHTSTICK",
          "WEAPON_NIGHTSTICK",
          "WEAPON_PUMP_SHOTGUN",
          "WEAPON_9MM_HANDGUN",
          "WEAPON_MP5",
          "WEAPON_M4",
        ];
        newWeaponType = rndWeps.random;
      } else if (oneIn(25)) {
        List<String> rndArmors = [
          "CLOTHING_POLICEUNIFORM",
          "CLOTHING_POLICEUNIFORM",
          "CLOTHING_POLICEARMOR",
          "CLOTHING_POLICEUNIFORM",
          "CLOTHING_SWATARMOR",
          "CLOTHING_POLICEUNIFORM",
          "CLOTHING_POLICEARMOR",
        ];
        newArmorType = rndArmors.random;
      } else if (oneIn(20)) {
        newLootType = "LOOT_POLICERECORDS";
      } else if (oneIn(3)) {
        newLootType = "LOOT_CELLPHONE";
      } else if (oneIn(2)) {
        newLootType = "LOOT_PDA";
      } else {
        newLootType = "LOOT_COMPUTER";
      }
    case SiteType.courthouse:
      if (oneIn(20)) {
        newLootType = "LOOT_JUDGEFILES";
      } else if (oneIn(3)) {
        newLootType = "LOOT_CELLPHONE";
      } else if (oneIn(2)) {
        newLootType = "LOOT_PDA";
      } else {
        newLootType = "LOOT_COMPUTER";
      }
    case SiteType.prison:
      if (oneIn(5)) {
        newArmorType = "CLOTHING_PRISONER";
      } else {
        newWeaponType = "WEAPON_SHANK";
      }
    case SiteType.whiteHouse:
      if (oneIn(20)) {
        newLootType = "LOOT_SECRETDOCUMENTS";
      } else if (oneIn(3)) {
        newLootType = "LOOT_CELLPHONE";
      } else if (oneIn(2)) {
        newLootType = "LOOT_PDA";
      } else {
        newLootType = "LOOT_COMPUTER";
      }
    case SiteType.armyBase:
      if (oneIn(3)) {
        List<String> rndWeps = [
          "WEAPON_9MM_HANDGUN",
          "WEAPON_M4",
          "WEAPON_M7",
        ];
        newWeaponType = rndWeps.random;
      } else if (oneIn(2)) {
        List<String> rndArmors = ["CLOTHING_ARMYARMOR"];
        newArmorType = rndArmors.random;
      } else if (oneIn(20)) {
        newLootType = "LOOT_SECRETDOCUMENTS";
      } else if (oneIn(3)) {
        newLootType = "LOOT_CELLPHONE";
      } else if (oneIn(2)) {
        newLootType = "LOOT_WATCH";
      } else {
        newLootType = "LOOT_TRINKET";
      }
    case SiteType.intelligenceHQ:
      if (oneIn(24)) {
        List<String> rndWeps = [
          "WEAPON_FLAMETHROWER",
          "WEAPON_45_HANDGUN",
          "WEAPON_MP5",
          "WEAPON_M4",
          "WEAPON_M7",
        ];
        newWeaponType = rndWeps.random;
      } else if (oneIn(20)) {
        newLootType = "LOOT_SECRETDOCUMENTS";
      } else if (oneIn(3)) {
        newLootType = "LOOT_CELLPHONE";
      } else if (oneIn(2)) {
        newLootType = "LOOT_PDA";
      } else {
        newLootType = "LOOT_COMPUTER";
      }
    case SiteType.fireStation:
      if (oneIn(25)) {
        newArmorType = "CLOTHING_BUNKERGEAR";
      } else if (oneIn(2)) {
        newLootType = "LOOT_TRINKET";
      } else {
        newLootType = "LOOT_COMPUTER";
      }
    case SiteType.sweatshop:
      newLootType = "LOOT_FINECLOTH";
    case SiteType.dirtyIndustry:
      newLootType = "LOOT_CHEMICAL";
    case SiteType.corporateHQ:
      if (oneIn(50)) {
        newLootType = "LOOT_CORPFILES";
      } else if (oneIn(3)) {
        newLootType = "LOOT_CELLPHONE";
      } else if (oneIn(2)) {
        newLootType = "LOOT_PDA";
      } else {
        newLootType = "LOOT_COMPUTER";
      }
    case SiteType.ceoHouse:
      if (oneIn(50)) {
        List<String> rndArmors = [
          "CLOTHING_EXPENSIVEDRESS",
          "CLOTHING_EXPENSIVESUIT",
          "CLOTHING_EXPENSIVESUIT",
          "CLOTHING_EXPENSIVESUIT",
          "CLOTHING_BONDAGEGEAR",
        ];
        newArmorType = rndArmors.random;
      }
      if (oneIn(8)) {
        newLootType = "LOOT_TRINKET";
      } else if (oneIn(7)) {
        newLootType = "LOOT_WATCH";
      } else if (oneIn(6)) {
        newLootType = "LOOT_PDA";
      } else if (oneIn(5)) {
        newLootType = "LOOT_CELLPHONE";
      } else if (oneIn(4)) {
        newLootType = "LOOT_SILVERWARE";
      } else if (oneIn(3)) {
        newLootType = "LOOT_CHEAPJEWELERY";
      } else if (oneIn(2)) {
        newLootType = "LOOT_FAMILYPHOTO";
      } else {
        newLootType = "LOOT_COMPUTER";
      }
    case SiteType.amRadioStation:
      if (oneIn(20)) {
        newLootType = "LOOT_AMRADIOFILES";
      } else if (oneIn(4)) {
        newLootType = "LOOT_MICROPHONE";
      } else if (oneIn(3)) {
        newLootType = "LOOT_PDA";
      } else if (oneIn(2)) {
        newLootType = "LOOT_CELLPHONE";
      } else {
        newLootType = "LOOT_COMPUTER";
      }
    case SiteType.cableNewsStation:
      if (oneIn(20)) {
        newLootType = "LOOT_CABLENEWSFILES";
      } else if (oneIn(4)) {
        newLootType = "LOOT_MICROPHONE";
      } else if (oneIn(3)) {
        newLootType = "LOOT_PDA";
      } else if (oneIn(2)) {
        newLootType = "LOOT_CELLPHONE";
      } else {
        newLootType = "LOOT_COMPUTER";
      }
    case SiteType.barAndGrill:
    case SiteType.bunker:
    case SiteType.bombShelter:
      //storming a CCS stronghold. Logically you ought to get all the leftover stuff if you win...
      List<String> rndWeps = [
        "WEAPON_9MM_HANDGUN",
        "WEAPON_45_HANDGUN",
        "WEAPON_22_REVOLVER",
        "WEAPON_44_REVOLVER",
        "WEAPON_MP5",
        "WEAPON_M4",
      ];
      List<String> rndArmors = [
        "CLOTHING_CHEAPSUIT",
        "CLOTHING_CLOTHES",
        "CLOTHING_TRENCHCOAT",
        "CLOTHING_DUSTER",
        "CLOTHING_WORKCLOTHES",
        "CLOTHING_PMC",
        "CLOTHING_CAMOSUIT",
        "CLOTHING_TACHARNESS",
        "CLOTHING_HEAVYARMOR",
      ];
      switch (lcsRandom(3)) {
        case 0:
          newWeaponType = rndWeps.random;
        case 1:
          newArmorType = rndArmors.random;
        default:
          if (oneIn(5)) {
            newLootType = "LOOT_CELLPHONE";
          } else if (oneIn(4)) {
            newLootType = "LOOT_SILVERWARE";
          } else if (oneIn(3)) {
            newLootType = "LOOT_TRINKET";
          } else if (oneIn(2)) {
            newLootType = "LOOT_CHEAPJEWELERY";
          } else {
            newLootType = "LOOT_COMPUTER";
          }
      }
    default:
      break;
  }
  item = null;
  if (newLootType.isNotEmpty) {
    item = Loot(newLootType);
  }
  if (newArmorType.isNotEmpty) {
    Clothing a = Clothing(newArmorType);
    if (oneIn(3)) a.damaged = true;
    item = a;
  }

  if (newWeaponType.isNotEmpty) {
    Weapon w = Weapon(newWeaponType);
    if (w.type.usesAmmo) {
      if (oneIn(2) || //50% chance of being loaded...
          //except for the most exotic weapons, which are always loaded.
          w.type.idName == "WEAPON_DESERT_EAGLE" ||
          w.type.idName == "WEAPON_FLAMETHROWER") //Make weapon property? -XML
      {
        w.ammo = w.type.ammoCapacity;
        w.loadedAmmoType = w.type.acceptableAmmo.firstOrNull;
      }
    }
    item = w;
  }
  return item;
}
