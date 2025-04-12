import 'dart:math';

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/common_display/print_creature_info.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/recruitment.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/items/ammo.dart';
import 'package:lcs_new_age/items/clothing.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/weapon.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/city.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/sitemode/haul_kidnap.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

part 'dating.g.dart';

@JsonSerializable()
class DatingSession {
  DatingSession(this.lcsMemberId, this.city);
  factory DatingSession.fromJson(Map<String, dynamic> json) =>
      _$DatingSessionFromJson(json);
  Map<String, dynamic> toJson() => _$DatingSessionToJson(this);

  List<Creature> dates = [];
  @JsonKey(defaultValue: 0)
  int lcsMemberId;
  @JsonKey(includeToJson: false, disallowNullValue: false)
  Creature? get lcsMember => pool.firstWhereOrNull((e) => e.id == lcsMemberId);
  set lcsMember(Creature? c) => lcsMemberId = c?.id ?? lcsMemberId;
  City city;
  int timeLeft = 0;
}

Future<void> doDates() async {
  for (int d = datingSessions.length - 1; d >= 0; d--) {
    DatingSession date = datingSessions[d];
    Creature? p = date.lcsMember;
    if (p == null) {
      datingSessions.remove(date);
      continue;
    }
    // Stand up dates if 1) dater does not exist, or
    // 2) dater was not able to return to a safehouse today (and is not in the hospital)
    if (date.timeLeft > 0 ||
        (p.site?.controller == SiteController.lcs ||
            p.site?.type == SiteType.universityHospital ||
            p.site?.type == SiteType.clinic)) {
      //VACATION
      if (date.timeLeft > 0) {
        p.vacationDaysLeft = --date.timeLeft;
        if (date.timeLeft <= 0) {
          Site? hs = findSiteInSameCity(date.city, SiteType.homelessEncampment);
          if (p.base?.siege.underSiege == false) p.base = hs;
          p.location = p.base;
          if (await completeVacation(date, p)) {
            datingSessions.remove(date);
            continue;
          }
        }
      }
      //DO A DATE
      else {
        //TERMINATE NULL DATES
        if (p.site?.siege.underSiege == true) {
          datingSessions.remove(date);
          continue;
        }
        //DO DATE
        else {
          if (await completeDate(date, p)) {
            datingSessions.remove(date);
            continue;
          } else {
            p.vacationDaysLeft = date.timeLeft;
            if (p.vacationDaysLeft > 0) {
              //NOW KICK THE DATER OUT OF THE SQUAD AND LOCATION
              p.squad = null;
              p.location = null;
            }
          }
        }
      }
    } else {
      datingSessions.remove(date);
      continue;
    }
  }
}

const List<Skill> talkingSkills = [
  Skill.science,
  Skill.religion,
  Skill.business,
  Skill.law,
];

Future<bool> completeDate(DatingSession d, Creature p) async {
  City? city = p.location?.city;
  if (d.dates.any((d) => d.location?.city != city)) {
    city = null;
  }

  erase();
  setColor(white);
  move(0, 0);
  String message = "${p.name} has ";
  if (d.dates.length == 1) {
    if (p.clinicMonthsLeft > 0 || city == null) {
      message += "a \"hot\" date with ";
    } else {
      message += "a hot date with ";
    }
  } else {
    message += "dates to manage with ";
  }
  for (int ei = 0; ei < d.dates.length; ei++) {
    Creature e = d.dates[ei];
    message += e.name;

    if (ei <= d.dates.length - 3) {
      message += ", ";
    } else if (ei == d.dates.length - 2) {
      message += " and ";
    } else {
      if (p.clinicMonthsLeft > 0) {
        message += " at ${p.location?.name}";
      } else if (city == null) {
        message += " over video chat";
      }
      message += ".";
    }
  }
  addparagraph(1, 1, console.height - 2, console.width - 2, message);

  await getKey();

  int dateCount =
      d.dates.where((c) => c.type.id != CreatureTypeIds.sexWorker).length;

  if (dateCount > 1 && lcsRandom(dateCount > 2 ? 4 : 6) == 0) {
    switch (lcsRandom(3)) {
      case 0:
        move(2, 0);
        if (dateCount > 2) {
          addstr(
              "Unfortunately, they all know each other and had been discussing");
        } else {
          addstr("Unfortunately, they know each other and had been discussing");
        }
        move(3, 0);
        addstr(p.name);
        addstr(".  An ambush was set for the lying dog...");

        await getKey();
      case 1:
        move(2, 0);
        if (dateCount > 2) {
          addstr("Unfortunately, they all turn up at the same time.");
        } else {
          addstr("Unfortunately, they turn up at the same time.");
        }

        move(3, 0);
        addstr("Ruh roh...");

        await getKey();
      default:
        move(2, 0);
        addstr(p.name);
        if (d.dates.length > 2) {
          if (city != null) {
            addstr(
                " realizes ${p.gender.heShe} has committed to eating ${d.dates.length} meals at once.");
          } else {
            addstr(
                " realizes ${p.gender.heShe} has committed to ${d.dates.length} calls at once.");
          }
        } else {
          addstr(" mixes up the names of ");
          addstr(d.dates[0].name);
          addstr(" and ");
          addstr(d.dates[1].name);
          addstr(".");
        }
        move(3, 0);
        addstr("Things go downhill fast.");

        await getKey();
    }

    const List<String> dateFail = [
      " is publicly humiliated.",
      " runs away.",
      " escapes through the bathroom window.",
      " spends the night getting drunk alone.",
      " gets chased out by an angry mob.",
      " gets stuck washing dishes all night.",
      " is rescued by a passing Elite Liberal.",
      " makes like a tree and leaves."
    ];
    const List<String> dateFailOnline = [
      " feels completely humiliated.",
      " is quickly blocked.",
      " is promptly told off.",
      " spends the night getting drunk alone.",
      " unplugs the power in shame.",
      " sits in the dark feeling dumb.",
      " spends the evening watching online videos.",
      " gets lit up on social media."
    ];
    List<String> dateFailList = city == null ? dateFailOnline : dateFail;
    move(5, 0);
    addstr(p.name);
    addstr(dateFailList.random);

    await getKey();

    return true;
  }

  for (int ei = d.dates.length - 1; ei >= 0; ei--) {
    Creature e = d.dates[ei];
    bool eIsSexworker = e.type.id == CreatureTypeIds.sexWorker;
    bool sameCity = e.location?.city == p.location?.city;
    int vacationPrice = eIsSexworker ? 2000 : 1000;
    erase();
    setColor(white);
    move(0, 0);
    addstr("Seeing ");
    addstr(e.name);
    addstr(", ");
    addstr(e.type.name);
    addstr(", ");
    addstr(e.workLocation.getName(short: false, includeCity: true));
    setColor(lightGray);
    printFunds();

    List<Item> temp = [];
    e.dropWeaponAndAmmo(lootPile: temp);
    e.giveArmor(Clothing("CLOTHING_CLOTHES"), temp);

    printCreatureInfo(e, showCarPrefs: ShowCarPrefs.onFoot);
    makeDelimiter();

    while (temp.isNotEmpty) {
      if (temp.last is Weapon) {
        e.giveWeapon(temp.last as Weapon, null);
      } //casts -XML
      else if (temp.last is Clothing) {
        e.giveArmor(temp.last as Clothing, null);
      } else if (e.weapon.acceptableAmmo.contains(temp.last.type)) {
        e.takeAmmo(temp.last as Ammo, null, temp.last.stackSize);
      }
      temp.removeAt(temp.length - 1);
    }

    mvaddstr(10, 0, "How should ${p.name} approach the situation?");

    bool canPay100 = ledger.funds >= 100 &&
        p.clinicMonthsLeft == 0 &&
        (sameCity || eIsSexworker);
    String payText;
    if (sameCity) {
      if (eIsSexworker) {
        payText = "A - Pay \$100 for a night together.";
      } else {
        payText =
            "A - Spend a hundred bucks to take ${e.name.split(' ').first} out on the town.";
      }
    } else {
      if (eIsSexworker) {
        payText = "A - Pay \$100 for a one-on-one video call.";
      } else {
        payText = "A - There is no expectation to spend money on this date.";
      }
    }
    addOptionText(11, 0, "A", payText, enabledWhen: canPay100);

    bool canAvoidPaying = !eIsSexworker;
    String avoidPayingText;
    move(12, 0);
    if (eIsSexworker) {
      avoidPayingText =
          "B - ${e.name} expects to be paid for ${e.gender.hisHer} time.";
    } else if (sameCity) {
      avoidPayingText =
          "B - Try to get through the evening without spending a penny.";
    } else {
      avoidPayingText =
          "B - Try to charm ${e.gender.himHer} with online dating.";
    }
    addOptionText(12, 0, "B", avoidPayingText, enabledWhen: canAvoidPaying);

    bool canGoOnVacation = p.clinicMonthsLeft == 0 &&
        p.blood == p.maxBlood &&
        ledger.funds >= vacationPrice;
    String vacationText;
    if (p.blood == p.maxBlood) {
      if (sameCity) {
        vacationText =
            "C - Spend a week and \$$vacationPrice on a cheap vacation (stands up other dates).";
      } else {
        vacationText =
            "C - Spend \$$vacationPrice to visit ${e.name.split(' ').first} for a week (stands up other dates).";
      }
    } else {
      vacationText =
          "C - Spend a week and \$$vacationPrice on a cheap vacation (must be uninjured).";
    }
    addOptionText(13, 0, "C", vacationText, enabledWhen: canGoOnVacation);

    addOptionText(14, 0, "D", "D - Break it off.");
    if (e.align == Alignment.conservative &&
        p.clinicMonthsLeft == 0 &&
        sameCity) {
      addOptionText(15, 0, "E", "E - Just kidnap the Conservative.");
    }

    int thingsincommon = countCommonInterests(p, e);
    while (true) {
      int c = await getKey();

      int aroll = p.skillRoll(Skill.seduction);
      int troll = e.attributeRoll(Attribute.wisdom, take10: true) + e.level;

      bool shouldDoDate = false;
      aroll += thingsincommon * 3;
      if (c == Key.a &&
          ledger.funds >= 100 &&
          p.clinicMonthsLeft == 0 &&
          (sameCity || eIsSexworker)) {
        ledger.subtractFunds(100, Expense.dating);
        aroll += lcsRandom(10);
        shouldDoDate = true;
      } else if (c == Key.b && !eIsSexworker) {
        shouldDoDate = true;
      }

      if (shouldDoDate) {
        int experience = lcsRandom(4) + 5;
        if (eIsSexworker) experience += 10;
        if (!sameCity) experience = max(1, experience ~/ 4);
        p.train(Skill.seduction, experience);
        for (Skill s in talkingSkills) {
          if (e.skill(s) >= 0) {
            if (e.skill(s) >= p.skill(s)) {
              p.train(s, e.skill(s));
            }
            troll += e.skill(s);
            aroll += p.skill(s);
          }
        }

        int y = 17;
        if (await dateResult(aroll, troll, d, e, p, y) == DateResult.arrested) {
          return true;
        }
        break;
      }

      if (c == Key.c &&
          ledger.funds >= vacationPrice &&
          p.clinicMonthsLeft == 0 &&
          p.blood == p.maxBlood) {
        for (int e2 = d.dates.length - 1; e2 >= 0; e2--) {
          if (e2 == ei) continue;
          d.dates.removeAt(e2);
          ei = 0;
        }
        d.timeLeft = 7;

        for (Skill s in talkingSkills) {
          if (e.skill(s) >= 0) {
            if (e.skill(s) >= p.skill(s)) {
              p.train(s, e.skill(s) * 4);
            }
          }
        }
        return false;
      }
      if (c == Key.d) {
        d.dates.remove(e);
        break;
      }
      if (c == Key.e &&
          e.align == Alignment.conservative &&
          p.clinicMonthsLeft == 0 &&
          sameCity) {
        setColor(yellow);
        int bonus = 0;
        move(17, 0);
        addstr(p.name);
        bool ranged = false;
        String weapon = "";
        bool unseriousWeapon = false;

        if (p.weapon.type.rangedAttack != null) {
          weapon = p.weapon.getName(sidearm: true);
          addstr(" comes back from the bathroom toting the ");
          addstr(weapon);
          move(18, 0);
          addstr("and threatens to blow the Conservative's brains out!");

          bonus = 5;
          ranged = true;
        } else if (p.equippedWeapon != null) {
          weapon = p.weapon.getName(sidearm: true);
          addstr(" grabs the Conservative from behind, holding the ");
          addstr(weapon);
          move(18, 0);
          addstr("to the corporate slave's throat!");

          if (p.weapon.type.canTakeHostages) {
            bonus = 5;
          } else {
            // Conservative emboldened by the fact that you're trying
            // to kidnap them with a gavel or some shit like that
            bonus = -1;
            unseriousWeapon = true;
          }
        } else {
          addstr(" seizes the Conservative swine from behind and warns it");
          move(18, 0);
          if (!noProfanity) {
            addstr("not to fuck around!");
          } else {
            addstr("not to [resist]!");
          }

          bonus += p.skill(Skill.martialArts) - 1;
        }

        await getKey();

        // Kidnap probably succeeds if the conservative isn't very dangerous,
        // but fails 15 times as often if the conservative is tough stuff.
        if ((!e.type.kidnapResistant && lcsRandom(15) > 0) ||
            lcsRandom(2 + bonus) > 0) {
          setColor(lightGreen);
          move(19, 0);
          addstr(e.name);
          if (bonus > 0) {
            addstr(" doesn't resist.");
          } else {
            addstr(" struggles and yells for help, but nobody comes.");
          }

          await getKey();

          move(20, 0);
          addstr(p.name);
          addstr(" kidnaps the Conservative!");

          await getKey();

          //Kidnapped wearing normal clothes and no weapon
          e.dropWeaponAndAmmo();
          Clothing clothes = Clothing("CLOTHING_CLOTHES");
          e.giveArmor(clothes, null);

          await kidnaptransfer(e);

          stats.kidnappings++;
          d.dates.remove(e);
          break;
        } else {
          int y = 19;
          setColor(red);
          move(y++, 0);
          if (ranged) {
            addstr("${e.name} brazenly tackles ${p.name}!");
          } else {
            addstr("${e.name} struggles and they both tumble to the ground!");
          }
          if (weapon != "") {
            await getKey();
            if (unseriousWeapon) {
              move(y++, 0);
              addstrc(yellow, "The $weapon is knocked away uselessly.");
            } else {
              move(y++, 0);
              addstrc(yellow, "The two struggle for control of the $weapon!");
            }
          }
          await getKey();

          if (lcsRandom(p.skill(Skill.martialArts) + 1) > 0) {
            setColor(yellow);
            move(y++, 0);
            addstr("${p.name} breaks free after a wild struggle.");
            mvaddstr(y++, 0, "Unfortunately, the Conservative escapes...");

            // Charge with kidnapping
            p.wantedForCrimes[Crime.kidnapping] =
                p.wantedForCrimes[Crime.kidnapping]! + 1;

            await getKey();

            d.dates.remove(e);
            break;
          } else {
            move(y++, 0);
            if (weapon != "" && !unseriousWeapon) {
              addstrc(
                  red, "The Conservative manages to wrest the $weapon away!");
              move(y++, 0);
              await getKey();
              if (p.weapon.type.attacks.any((a) => a.bruises)) {
                addstr(
                    "${e.name} swings the $weapon and knocks ${p.name} out!");
              } else {
                addstr(
                    "${e.name} switches grips and clubs ${p.name} in the head!");
              }
            } else {
              addstrc(red, e.name);
              addstr("'s fist is the last thing ");
              addstr(p.name);
              addstr(" remembers seeing!");
              await getKey();
            }
            move(y++, 0);
            addstr("The Liberal wakes up in the police station...");

            // Find the police station
            Site? ps =
                findSiteInSameCity(p.location!.city, SiteType.policeStation);

            // Arrest the Liberal
            p.squad = null;
            p.carId = null;
            p.location = ps;
            p.dropWeaponAndAmmo();
            p.activity = Activity.none();

            // Charge with kidnapping
            criminalize(p, Crime.kidnapping);

            await getKey();

            d.dates.remove(e);
            return true;
          }
        }
      }
    }
  }

  if (d.dates.isNotEmpty) {
    d.timeLeft = 0;
    return false;
  } else {
    return true;
  }
}

enum DateResult {
  meetTomorrow,
  breakup,
  joined,
  arrested,
}

// Handles the result of a date or vacation
Future<DateResult> dateResult(int aroll, int troll, DatingSession d, Creature e,
    Creature p, int y) async {
  bool eIsSexworker = e.type.id == CreatureTypeIds.sexWorker;
  if (eIsSexworker) {
    troll -= 10 + e.daysSinceJoined; // It's a commercial transaction
  } else if (e.location?.city != p.location?.city) {
    troll += 10; // It's a long-distance relationship
  }

  if (aroll > troll) {
    if (eIsSexworker) {
      troll += 30; // It's an *arm's length* commercial transaction
      // Slowly become more amenable to joining and less prone to getting bad vibes
      e.daysSinceJoined++;
    }
    setColor(lightBlue);
    move(y, 0);
    y++;
    if (eIsSexworker && !e.isWillingToTalk) {
      if (p.skill(Skill.seduction) >= p.skillCap(Skill.seduction)) {
        addstrc(yellow,
            "${p.name} has learned all ${p.gender.heShe} can from ${e.name}.");
      } else {
        addstr("${p.name} still has more to learn from ${e.name}.");
      }
    } else {
      addstr(e.name);
      if (eIsSexworker) {
        addstr(" enjoys discussing ");
      } else {
        addstr(" is quite taken with ");
      }
      addstr(p.name);
      addstr("'s unique life philosophy...");
    }

    await getKey();

    if (p.subordinatesLeft <= 0 && eIsSexworker && e.isWillingToTalk) {
      mvaddstrc(y++, 0, yellow,
          "But ${e.name} doesn't like to get too emotionally attached.");

      mvaddstrc(y++, 0, lightGray,
          "${p.name} doesn't have the juice to recruit otherwise.");
      mvaddstr(y++, 0,
          "This won't go anywhere, but it can continue for \"educational purposes\".");
      e.isWillingToTalk = false;

      await getKey();

      return DateResult.meetTomorrow;
    } else if (p.relationshipsLeft <= 0 && !eIsSexworker) {
      setColor(yellow);

      move(y++, 0);
      addstr("But ${p.name} is already dating ");
      int numRelationships = p.maxRelationships - p.relationshipsLeft;
      if (numRelationships == 1) {
        addstr("someone.");
      } else {
        addstr("$numRelationships people.");
      }

      move(y++, 0);
      addstr("${p.name} isn't seductive enough to maintain ");
      if (numRelationships == 1) {
        addstr("another");
      } else {
        addstr("yet another");
      }
      addstr(" relationship.");

      await getKey();
      setColor(lightGray);

      move(y++, 0);
      addstr("It was fun though. They agree to part ways amicably.");

      await getKey();

      d.dates.remove(e);

      return DateResult.breakup;
    }

    if (lcsRandom((aroll - troll) ~/ 2) > e.attribute(Attribute.wisdom) &&
        e.attribute(Attribute.wisdom) < 4 &&
        !(eIsSexworker && !e.isWillingToTalk)) {
      setColor(lightGreen);
      move(y, 0);
      y++;
      if (eIsSexworker) {
        addstr(
            "In fact, ${e.name} decides to put ${e.gender.hisHer} skills to work for the LCS!");
        e.daysSinceJoined =
            0; // Reset to zero since we used this to track time dating
      } else if (e.align == Alignment.conservative) {
        addstr(
            "In fact, ${e.name} swears off Conservatism and begs to join the LCS!");
      } else if (e.align == Alignment.moderate) {
        addstr("In fact, ${e.name} wants to join ${p.name} in the LCS!");
      } else {
        addstr("In fact, ${e.name} is eager to fight alongside ${p.name}!");
      }

      //Get map of their workplace
      e.workSite?.mapped = true;
      e.workSite?.hidden = false;

      await getKey();

      if (!eIsSexworker) e.seduced = true;
      e.hireId = p.id;
      e.base = p.base;

      erase();

      setColor(white);
      move(0, 0);
      if (e.align != Alignment.liberal) {
        addstr("The Liberal Rebirth of ");
      } else {
        addstr("The Radicalization of ");
      }
      addstr(e.properName);

      move(2, 0);
      setColor(lightGray);
      addstr(
          "What name will you give to ${e.properName} in ${e.gender.hisHer} new life?");
      move(3, 0);
      addstr(
          "If you do not enter anything, ${e.gender.heShe} will keep ${e.gender.hisHer} old name.");

      e.name = await enterName(4, 0, e.properName, prefill: true);

      pool.add(e);

      await sleeperizePrompt(e, p, 8);

      stats.recruits++;
      d.dates.remove(e);

      //Check to determine if murderers are offended

      return DateResult.joined;
    } else {
      if (e.align == Alignment.conservative &&
          e.attribute(Attribute.wisdom) > e.attribute(Attribute.heart)) {
        setColor(lightGreen);
        y++;
        move(y++, 0);
        addstr(
            "${p.name} is slowly warming ${e.name}'s frozen Conservative heart.");

        move(y++, 0);
        e.adjustAttribute(Attribute.wisdom, -1);
        e.adjustAttribute(Attribute.heart, 1);
      } else if (e.attribute(Attribute.wisdom) > 3) {
        e.adjustAttribute(Attribute.wisdom, -1);
      }
      //Possibly date reveals map of location
      else if (e.workSite?.mapped == false &&
          lcsRandom(e.attribute(Attribute.wisdom)) == 0) {
        y++;
        mvaddstr(y++, 0,
            "${e.name} turns the topic of discussion to the ${e.workSite!.name}.");
        mvaddstr(y++, 0,
            "${p.name} is able to create a map of the site from this information.");
        y++;
        e.workSite!.mapped = true;
        e.workSite!.hidden = false;
      }

      setColor(lightGray);
      move(y++, 0);
      if (eIsSexworker && !e.isWillingToTalk) {
        addstr("Lessons continue tomorrow.");
      } else {
        addstr("They'll meet again tomorrow.");
      }

      await getKey();

      return DateResult.meetTomorrow;
    }
  } else if (aroll == troll) {
    setColor(lightGray);
    move(y++, 0);
    addstr("${e.name} had to leave early");
    switch (lcsRandom(4)) {
      case 0:
        addstr(" to wash ${e.gender.hisHer} hair.");
      case 1:
        addstr(" due to an allergy attack.");
      case 2:
        addstr(" due to an early meeting tomorrow.");
      case 3:
        addstr(" to catch ${e.gender.hisHer} favourite TV show.");
      case 4:
        addstr(" to take care of ${e.gender.hisHer} pet");
        switch (lcsRandom(3 +
            ((laws[Law.animalRights] == DeepAlignment.archConservative)
                ? 1
                : 0))) {
          case 0:
            addstr(" cat.");
          case 1:
            addstr(" dog.");
          case 2:
            addstr(" fish.");
          case 3:
            addstr(" six-legged pig.");
        }
      case 5:
        addstr(" to go to a birthday party.");
      case 6:
        addstr(" to recharge ${e.gender.hisHer} cell phone.");
    }
    move(y++, 0);
    addstr("${e.gender.heSheCap} did still promise to meet up again tomorrow.");

    await getKey();

    return DateResult.meetTomorrow;
  } else {
    //WISDOM POSSIBLE INCREASE
    if (e.align == Alignment.conservative && aroll < troll / 2) {
      setColor(red);
      move(y++, 0);

      addstr("Talking with ");
      addstr(e.name);
      addstr(" actually curses ");
      addstr(p.name);
      addstr("'s mind with wisdom!!!");

      p.adjustAttribute(Attribute.wisdom, 1);

      for (Skill s in talkingSkills) {
        if (e.skill(s) > p.skill(s)) {
          p.train(s, 20 * e.skill(s));
        }
      }

      await getKey();
    }

    //BREAK UP
    bool reportingToPolice = e.type.reportsToPolice && lcsRandom(2) == 0;
    reportingToPolice = reportingToPolice || lcsRandom(50) == 0;
    if (p.isCriminal && reportingToPolice) {
      mvaddstrc(y++, 0, red,
          "${e.name} was leaking information to the police the whole time!");

      await getKey();

      move(y++, 0);
      Site? ps = findSiteInSameCity(p.location!.city, SiteType.policeStation);
      if (ps == null) {
        addstrc(lightGreen,
            "But there isn't a police station in ${p.location!.city.name}!");
        mvaddstr(y++, 0, "Nobody comes to arrest ${p.name}.");
      } else if (!p.skillCheck(Skill.streetSmarts, Difficulty.hard)) {
        addstrc(purple, "${p.name} has been arrested.");

        p.squad = null;
        p.carId = -1;
        p.location = ps;
        p.dropWeaponAndAmmo();
        p.activity = Activity.none();

        await getKey();

        d.dates.remove(e);

        return DateResult.arrested;
      } else {
        setColor(lightGreen);
        addstr("But ${p.name} cleverly escapes the police ambush!");
      }
    } else {
      int existingRelationships = p.relationships.length;
      if (eIsSexworker) {
        mvaddstrc(y++, 0, purple,
            "${e.name} picks up some weird vibes and decides to bail.");
        mvaddstr(y++, 0, "This will be the last visit.");
        move(y++, 0);
      } else if (existingRelationships > 0 && lcsRandom(2) > 0) {
        setColor(purple);
        move(y++, 0);
        addstr("The date starts well, but ${e.name} has no patience for ");
        move(y++, 0);
        addstr("${p.name}'s ");
        switch (existingRelationships) {
          case 5:
            addstr("awe-inspiring ");
          case 4:
            addstr("mind-bending ");
          case 3:
            addstr("intricate ");
          case 2:
            addstr("complicated ");
          case 1:
            addstr("busy ");
          default:
            addstr("unbelievably complicated ");
        }
        addstr("schedule and prior relationships.");

        move(y++, 0);
        addstr("This relationship is over.");
      } else {
        setColor(purple);
        move(y++, 0);
        addstr(e.name);
        addstr(" can sense that things just aren't working out.");

        move(y++, 0);
        addstr("This relationship is over.");
      }
    }

    await getKey();

    d.dates.remove(e);

    return DateResult.breakup;
  }
}

Future<bool> completeVacation(DatingSession d, Creature p) async {
  Creature e = d.dates.first;
  bool eIsSexworker = e.type.id == CreatureTypeIds.sexWorker;

  erase();
  setColor(white);
  move(0, 0);
  addstr(p.name);
  addstr(" is back from vacation.");

  int aroll = p.skillRoll(Skill.seduction, advantage: true);
  int troll = e.attributeRoll(Attribute.wisdom, take10: true) + e.level;

  p.train(Skill.seduction, lcsRandom(28) + 35);
  if (eIsSexworker) p.train(Skill.seduction, 100);

  int thingsincommon = countCommonInterests(p, e);
  aroll += thingsincommon * 3;

  for (Skill s in talkingSkills) {
    if (e.skill(s) >= 0) {
      if (e.skill(s) >= p.skill(s)) {
        p.train(s, e.skill(s));
      }
      troll += e.skill(s);
      aroll += p.skill(s);
    }
  }

  switch (await dateResult(aroll, troll, d, e, p, 2)) {
    case DateResult.breakup:
    case DateResult.joined:
    case DateResult.arrested:
      return true;
    case DateResult.meetTomorrow:
      return false;
  }
}

int countCommonInterests(Creature p, Creature e) {
  int commonInterests = 0;
  for (Skill s in Skill.values) {
    if (e.skill(s) >= 1 && p.skill(s) >= 1) {
      commonInterests++;
    }
  }
  return commonInterests;
}
