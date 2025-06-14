import 'package:collection/collection.dart';
import 'package:lcs_new_age/common_display/print_creature_info.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/shopsnstuff.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/gamestate/squad.dart';
import 'package:lcs_new_age/items/money.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/compound.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/sitemode/site_display.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';
import 'package:lcs_new_age/talk/drop_a_pickup_line.dart';
import 'package:lcs_new_age/talk/talk_about_issues.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<bool> talkOutsideCombat(Creature a, Creature tk) async {
  bool nude = a.indecent;
  String whileNaked = nude ? " while naked" : "";
  clearSceneAreas();
  mvaddstrc(9, 1, white, a.name);
  addstrc(lightGray, " talks to ");
  addstrc(tk.align.color, tk.name);
  setColor(white);
  addstr(" ${creatureAgeAndGender(tk)}");
  addstr(":");

  addOptionText(console.y + 2, 1, "A",
      "A - Strike up a conversation about politics$whileNaked.");
  addOptionText(console.y + 1, 1, "B", "B - Drop a pickup line$whileNaked.",
      enabledWhen: tk.canDate(a));
  addOptionText(console.y + 1, 1, "C",
      "C - On second thought, don't say anything$whileNaked.");

  if (tk.type.id == CreatureTypeIds.landlord) {
    if (activeSite?.controller == SiteController.unaligned) {
      addOptionText(14, 1, "D", "D - Rent a room$whileNaked.");
    } else if (activeSite?.controller == SiteController.lcs) {
      addOptionText(14, 1, "D", "D - Stop renting a room$whileNaked.");
    }
  } else if (tk.type.id == CreatureTypeIds.gangMember ||
      tk.type.id == CreatureTypeIds.merc) {
    addOptionText(14, 1, "D", "D - Buy weapons$whileNaked.");
  } else if (tk.type.id == CreatureTypeIds.bankTeller) {
    addOptionText(14, 1, "D", "D - Rob the bank$whileNaked.");
  }

  // relationship/recruits status
  String recruitOverview = "";
  if (a.subordinatesLeft <= 0) {
    recruitOverview +=
        "&m${a.name} cannot manage any${a.maxSubordinates > 0 ? " more " : " "}subordinates";
    if (a.scheduledMeetings > 0) {
      recruitOverview +=
          ", but still has &W${a.scheduledMeetings}&m meeting${a.scheduledMeetings > 1 ? "s" : ""} scheduled";
    }
  } else {
    recruitOverview +=
        "&w${a.name} can manage &W${a.subordinatesLeft}&w more subordinate${a.subordinatesLeft > 1 ? "s" : ""}";
    if (a.scheduledMeetings > 0) {
      recruitOverview +=
          ", and has &W${a.scheduledMeetings}&w meeting${a.scheduledMeetings > 1 ? "s" : ""} scheduled";
    }
  }
  recruitOverview += ". ";
  if (a.scheduldeDates > 0 || a.scheduledMeetings > 0) {
    recruitOverview += "&m${a.gender.heSheCap} ";
  }
  if (a.relationshipsLeft <= 0) {
    recruitOverview +=
        "&m${a.gender.heSheCap} cannot maintain any${a.maxRelationships > 0 ? " more " : " "}relationships";
    if (a.scheduldeDates > 0) {
      recruitOverview +=
          ", but still has &W${a.scheduldeDates}&m hot date${a.scheduldeDates > 1 ? "s" : ""} lined up. ";
    } else {
      recruitOverview += ". ";
    }
  } else {
    recruitOverview +=
        "&w${a.gender.heSheCap} can maintain &W${a.relationshipsLeft}&w more relationship${a.relationshipsLeft > 1 ? "s" : ""}";
    if (a.scheduldeDates == 0) {
      recruitOverview += ". ";
    } else {
      recruitOverview +=
          ", and has &W${a.scheduldeDates}&w hot date${a.scheduldeDates > 1 ? "s" : ""} lined up. ";
    }
  }

  addparagraph(console.y + 2, 1, recruitOverview);

  while (true) {
    int c = await getKey();

    switch (c) {
      case Key.a:
        return wannaHearSomethingDisturbing(a, tk);
      case Key.b:
        if (tk.canDate(a)) return await doYouComeHereOften(a, tk);
      case Key.c:
        return false;
      case Key.d:
        if (tk.type.id == CreatureTypeIds.landlord &&
            activeSite?.controller == SiteController.unaligned) {
          return heyIWantToRentARoom(a, tk);
        } else if (tk.type.id == CreatureTypeIds.landlord &&
            activeSite?.controller == SiteController.lcs) {
          return heyIWantToCancelMyRoom(a, tk);
        } else if (tk.type.id == CreatureTypeIds.gangMember ||
            tk.type.id == CreatureTypeIds.merc) {
          return heyINeedAGun(a, tk);
        } else if (tk.type.id == CreatureTypeIds.bankTeller) {
          return talkToBankTeller(a, tk);
        }
    }
  }
}

Future<bool> wannaHearSomethingDisturbing(Creature a, Creature tk) async {
  clearSceneAreas();
  mvaddstrc(9, 1, white, "${a.name} says, ");
  mvaddstrc(10, 1, lightGreen, "\"Do you want to hear something disturbing?\"");

  await getKey();

  bool interested = tk.type.talkReceptive ||
      a.skillCheck(Skill.persuasion, Difficulty.average);
  if (a.indecent) {
    interested = interested && lcsRandom(3) == 0;
  }

  if ((tk.type.animal &&
          !a.type.animal &&
          tk.align != Alignment.liberal &&
          !animalsArePeopleToo) ||
      tk.type.tank) {
    mvaddstrc(12, 1, white, tk.name);
    if (tk.type.tank) {
      addstr(" rumbles disinterestedly.");
    } else if (tk.type.dog) {
      addstr(" barks.");
    } else {
      addstr(" doesn't understand.");
    }

    await getKey();
    return true;
  } else if (tk.name != "Prisoner" && interested) {
    mvaddstrc(12, 1, white, "${tk.name} responds, ");
    mvaddstrc(13, 1, lightBlue, "\"What?\"");

    await getKey();

    return talkAboutIssues(a, tk);
  } else {
    mvaddstrc(12, 1, white, "${tk.name} responds, ");
    setColor(lightBlue);
    move(13, 1);
    if (tk.name == "Prisoner") {
      if (tk.align == Alignment.liberal) {
        addstr("\"I'm stuck in here.\"");
      } else {
        addstr("\"Leave me alone.\"");
        tk.isWillingToTalk = false;
      }
    } else {
      addstr("\"No.\"");
      tk.isWillingToTalk = false;
    }
    addstrc(white, " <turns away>");
    await getKey();

    return true;
  }
}

Future<bool> heyIWantToRentARoom(Creature a, Creature tk) async {
  clearSceneAreas();
  mvaddstrc(9, 1, white, a.name);
  addstr(" says, ");
  mvaddstrc(10, 1, lightGreen, "\"I'd like to rent a room.\"");

  await getKey();

  if (a.indecent) {
    mvaddstrc(12, 1, white, tk.name);
    addstr(" responds, ");
    mvaddstrc(
        13, 1, lightBlue, "\"Put some clothes on before I call the cops.\"");

    await getKey();

    return true;
  }

  int rent;
  switch (activeSite?.type) {
    case SiteType.apartment:
      rent = 650;
    case SiteType.upscaleApartment:
      rent = 1500;
    default:
      rent = 200;
  }

  mvaddstrc(12, 1, white, tk.name);
  addstr(" responds, ");
  mvaddstrc(13, 1, lightBlue, "\"It'll be \$$rent a month.");

  mvaddstr(14, 1, "I'll need \$$rent now as a security deposit.\"");

  await getKey();

  clearSceneAreas();

  while (true) {
    int c = Key.a;

    setColor(ledger.funds >= rent ? white : darkGray);
    addOptionText(11, 1, "A", "A - Accept.");
    addOptionText(12, 1, "B", "B - Decline.");
    addOptionText(13, 1, "C", "C - Threaten the landlord.");

    c = await getKey();

    switch (c) {
      case Key.a: // Accept rent deal
        if (ledger.funds < rent) break;

        clearSceneAreas();
        mvaddstrc(9, 1, white, a.name);
        addstr(" says, ");
        mvaddstrc(10, 1, lightGreen, "\"I'll take it.\"");

        await getKey();

        mvaddstrc(12, 1, white, tk.name);
        addstr(" responds, ");
        mvaddstrc(
            13, 1, lightBlue, "\"Rent is due by the third of every month.");

        mvaddstr(14, 1, "We'll start next month.\"");

        setColor(white);
        addstr(" <turns away>");

        await getKey();

        ledger.subtractFunds(rent, Expense.rent);
        activeSite?.controller = SiteController.lcs;
        activeSite?.rent = rent;
        activeSite?.newRental = true;

        activeSquad?.members.forEach((c) => c.base = activeSite);
        return true;

      case Key.b: // Refuse rent deal
        clearSceneAreas();
        mvaddstrc(9, 1, white, a.name);
        addstr(" says, ");
        mvaddstrc(10, 1, lightGreen,
            "\"Whoa, I was looking for something cheaper.\"");

        await getKey();

        mvaddstrc(12, 1, white, tk.name);
        addstr(" responds, ");
        mvaddstrc(13, 1, lightBlue, "\"Not my problem...\"");
        setColor(white);
        addstr(" <turns away>");

        await getKey();

        return true;

      case Key.c: // Threaten landlord
        clearSceneAreas();
        setColor(white);
        Creature? armedLiberal = activeSquad?.members
            .firstWhereOrNull((c) => c.weapon.type.threatening);
        if (armedLiberal != null) {
          mvaddstr(9, 1, armedLiberal.name);
          addstr(" brandishes the ");
          addstr(armedLiberal.weapon.getName(sidearm: true));
          addstr(".");

          await getKey();
          clearSceneAreas();
        }
        mvaddstr(9, 1, "${a.name} says, ");
        mvaddstrc(10, 1, lightGreen,
            "\"What's the price for the Liberal Crime Squad?\"");

        await getKey();

        int roll = a.skillRoll(Skill.persuasion);
        int difficulty = Difficulty.formidable;

        if (!lcsInPublicEye) {
          difficulty += DifficultyModifier.aLittleHarder;
        }
        if (armedLiberal == null) {
          difficulty += DifficultyModifier.aLittleHarder;
        }

        if (roll < difficulty - 4) {
          mvaddstrc(12, 1, white, tk.name);
          addstr(" responds, ");
          mvaddstrc(13, 1, lightBlue, "\"I think you'd better leave.\"");
          setColor(white);
          addstr(" <crosses arms>");

          await getKey();

          tk.isWillingToTalk = false;
          return true;
        } else {
          mvaddstrc(12, 1, white, tk.name);
          addstr(" responds, ");
          mvaddstrc(13, 1, lightBlue, "\"Jesus... it's yours...\"");

          await getKey();

          int rent;

          // Either he calls the cops or it's yours for free
          if (roll < difficulty) {
            addPotentialCrime(squad, Crime.extortion);
            activeSite!.siege.timeUntilCops = 2;
            rent = 100000000000000; // 100 trillion to guarantee eviction
          } else {
            rent = 0;
          }

          activeSite!.rent = rent;
          activeSite!.newRental = true;
          activeSite!.controller = SiteController.lcs;

          for (var c in squad) {
            c.base = activeSite;
          }
          return true;
        }
    }
  }
}

Future<bool> heyIWantToCancelMyRoom(Creature a, Creature tk) async {
  clearSceneAreas();
  mvaddstrc(9, 1, white, a.name);
  addstr(" says, ");
  mvaddstrc(10, 1, lightGreen, "\"I'd like to cancel my room.\"");

  await getKey();

  if (a.indecent) {
    mvaddstrc(12, 1, white, tk.name);
    addstr(" responds, ");
    mvaddstrc(
        13, 1, lightBlue, "\"Put some clothes on before I call the cops.\"");

    await getKey();

    return true;
  }

  mvaddstrc(12, 1, white, tk.name);
  addstr(" responds, ");
  mvaddstrc(13, 1, lightBlue, "\"Fine.  Clear out your room.\"");

  await getKey();

  mvaddstrc(15, 1, white,
      "<Your possessions at this location have been moved to the homeless camp.>");

  await getKey();

  activeSite!.controller = SiteController.unaligned;

  //MOVE ALL ITEMS AND SQUAD MEMBERS
  Site hs = findSiteInSameCity(activeSite!.city, SiteType.homelessEncampment)!;
  for (Creature p in pool) {
    if (p.location == activeSite) p.location = hs;
    if (p.base == activeSite) p.base = hs;
  }
  hs.addLootAndProcessMoney(activeSite!.loot);

  activeSite!.compound = Compound();
  activeSite!.compound.rations = 0;
  activeSite!.businessFront = false;

  return true;
}

Future<bool> heyINeedAGun(Creature a, Creature tk) async {
  clearSceneAreas();
  mvaddstrc(9, 1, white, a.name);
  addstr(" says, ");
  mvaddstrc(10, 1, lightGreen, "\"Hey, I need a gun.\"");
  await getKey();

  if (a.indecent) {
    mvaddstrc(12, 1, white, tk.name);
    addstr(" responds, ");
    mvaddstrc(13, 1, lightBlue, "\"Jesus...\"");
    await getKey();
    return true;
  }
  if (a.clothing.type.police) {
    mvaddstrc(12, 1, white, tk.name);
    addstr(" responds, ");
    mvaddstrc(13, 1, lightBlue, "\"I don't sell guns, officer.\"");
    await getKey();
    return true;
  }
  if (siteAlarm) {
    mvaddstrc(12, 1, white, tk.name);
    addstr(" responds, ");
    mvaddstrc(13, 1, lightBlue, "\"We can talk when things are calm.\"");
    await getKey();
    return true;
  }
  SiteType? siteType = activeSite?.type;
  if (mode != GameMode.site) siteType = null;
  switch (siteType) {
    case SiteType.bunker:
    case SiteType.drugHouse:
    case SiteType.barAndGrill:
    case SiteType.armsDealer:
    case SiteType.tenement:
    case SiteType.bombShelter:
    case SiteType.homelessEncampment:
    case SiteType.warehouse:
    case null:
      mvaddstrc(12, 1, white, tk.name);
      addstr(" responds, ");
      mvaddstrc(13, 1, lightBlue, "\"What exactly do you need?\"");
      await getKey();
      Squad? oldSquad;
      Squad? newSquad;
      if (activeSquad == null) {
        oldSquad = tk.squad;
        newSquad = Squad();
        squads.add(newSquad);
        tk.squad = newSquad;
        activeSquad = tk.squad;
      }
      await armsdealer(activeSite ??
          Site(SiteType.armsDealer, tk.base!.city, tk.base!.district)
        ..name = "Secluded Alley");
      if (newSquad != null) {
        squads.remove(newSquad);
      }
      if (oldSquad != null) {
        tk.squad = oldSquad;
        activeSquad = null;
        newSquad = null;
      }
      return true;
    default:
      mvaddstrc(12, 1, white, tk.name);
      addstr(" responds, ");
      mvaddstrc(13, 1, lightBlue, "\"Uhhh... not a good place for this.\"");
      await getKey();
      return true;
  }
}

Future<bool> talkToBankTeller(Creature a, Creature tk) async {
  clearSceneAreas();
  setColor(lightGray);
  addOptionText(11, 1, "A", "A - Quietly pass the teller a robbery note");
  if (a.indecent) addstr(" while naked");
  addstr(".");
  addOptionText(
      12, 1, "B", "B - Threaten bystanders and demand access to the vault");
  if (a.indecent) addstr(" while naked");
  addstr(".");
  addOptionText(13, 1, "C", "C - On second thought, don't rob the bank");
  if (a.indecent) addstr(" while naked");
  addstr(".");

  int c;
  do {
    c = await getKey();
  } while (c < Key.a && c > Key.c);

  switch (c) {
    case Key.a:
      clearSceneAreas();
      mvaddstrc(9, 1, white, a.name);
      addstr(" slips the teller a note: ");
      setColor(lightGreen);
      move(10, 1);
      switch (lcsRandom(10)) {
        case 0:
          addstr("KINDLY PUT MONEY IN BAG. OR ELSE.");
        case 1:
          addstr("I AM LIBERATING YOUR MONEY SUPPLY.");
        case 2:
          addstr("THIS IS A ROBBERY. GIVE ME THE MONEY.");
        case 3:
          addstr("I HAVE A GUN. CASH PLEASE.");
        case 4:
          addstr("THE LIBERAL CRIME SQUAD REQUESTS CASH.");
        case 5:
          addstr("I AM MAKING A WITHDRAWAL. ALL YOUR MONEY.");
        case 6:
          addstr("YOU ARE BEING ROBBED. GIVE ME YOUR MONEY.");
        case 7:
          addstr("PLEASE PLACE LOTS OF DOLLARS IN THIS BAG.");
        case 8:
          addstr("SAY NOTHING. YOU ARE BEING ROBBED.");
        case 9:
          addstr("ROBBERY. GIVE ME CASH. NO FUNNY MONEY.");
      }

      await getKey();

      if (activeSite!.hasHighSecurity) {
        mvaddstrc(11, 1, white, "The bank teller reads the note, ");
        switch (lcsRandom(5)) {
          case 0:
            addstr("gestures, ");
          case 1:
            addstr("signals, ");
          case 2:
            addstr("shouts, ");
          case 3:
            addstr("screams, ");
          case 4:
            addstr("gives a warning, ");
        }
        mvaddstr(
            12, 1, "and dives for cover as the guards move in on the squad!");

        await getKey();

        siteAlarm = true;
        addPotentialCrime(squad, Crime.bankRobbery);
        addDramaToSiteStory(Drama.bankTellerRobbery);
        siteCrime += 30;
        encounter.add(Creature.fromId(CreatureTypeIds.merc));
        encounter.add(Creature.fromId(CreatureTypeIds.merc));
        encounter.add(Creature.fromId(CreatureTypeIds.merc));
        encounter.add(Creature.fromId(CreatureTypeIds.merc));
      } else {
        mvaddstrc(11, 1, white, "The bank teller reads the note, ");
        switch (lcsRandom(5)) {
          case 0:
            addstr("nods calmly, ");
          case 1:
            addstr("looks startled, ");
          case 2:
            addstr("inhales sharply, ");
          case 3:
            addstr("sets the paper aside, ");
          case 4:
            addstr("looks up, ");
        }
        mvaddstr(
            12, 1, "and slips several bricks of cash into the squad's bag.");

        await getKey();

        addPotentialCrime(squad, Crime.bankRobbery);
        addDramaToSiteStory(Drama.bankTellerRobbery);
        siteCrime += 30;
        siteAlarmTimer = 0;
        activeSquad!.loot.add(Money(5000));
      }
      tk.isWillingToTalk = false;
      return true;
    case Key.b:
      clearSceneAreas();
      setColor(white);
      Creature? armedLiberal =
          squad.firstWhereOrNull((p) => p.weapon.type.threatening);
      if (armedLiberal != null) {
        String weaponName = armedLiberal.weapon.getName(sidearm: true);
        mvaddstr(9, 1, "${armedLiberal.name} brandishes the $weaponName.");
        await getKey();
        clearMessageArea();
      }
      mvaddstr(10, 1, "${a.name} says, ");
      mvaddstrc(11, 1, lightGreen, "\"$slogan");
      mvaddstr(12, 1, "OPEN THE VAULT, NOW!\"");

      await getKey();

      int roll = a.skillRoll(Skill.persuasion);
      int difficulty = Difficulty.veryEasy;

      if (armedLiberal == null) {
        difficulty += DifficultyModifier.aLotHarder;
      }
      if (activeSite!.hasHighSecurity) {
        difficulty += DifficultyModifier.aLotHarder;
      }

      clearSceneAreas();
      setColor(white);
      if (roll < difficulty) {
        mvaddstrc(9, 1, white, "The bank teller dives for cover as ");
        mvaddstr(10, 1, "guards move in on the squad!");

        await getKey();

        siteAlarm = true;
        addPotentialCrime(squad, Crime.bankRobbery);
        addDramaToSiteStory(Drama.bankStickup);
        siteCrime += 50;
        String guard = CreatureTypeIds.securityGuard;
        if (activeSite!.hasHighSecurity) guard = CreatureTypeIds.merc;
        for (int i = 0; i < 6; i++) {
          encounter.add(Creature.fromId(guard));
        }
      } else {
        mvaddstrc(9, 1, white, "The bank employees hesitantly cooperate!");
        await getKey();
        mvaddstr(10, 1, "The vault is open!");
        await getKey();

        addPotentialCrime(squad, Crime.bankRobbery);
        addDramaToSiteStory(Drama.bankStickup);
        siteCrime += 50;
        siteAlarm = true;

        for (SiteTile t in levelMap.all) {
          t.locked = false;
          if (t.special == TileSpecial.bankVault) {
            for (SiteTile n in t.neighbors()) {
              n.door = false;
            }
            t.special = TileSpecial.none;
          }
        }

        encounter.remove(tk);
      }
      return true;
    case Key.c:
    default:
      return false;
  }
}
