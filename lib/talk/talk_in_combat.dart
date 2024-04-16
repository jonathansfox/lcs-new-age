import 'package:collection/collection.dart';
import 'package:lcs_new_age/common_actions/common_actions.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/loot.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/siege.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/politics.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/sitemode/fight.dart';
import 'package:lcs_new_age/sitemode/site_display.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<bool> talkInCombat(Creature liberal, Creature target) async {
  clearCommandArea();
  clearMessageArea();
  clearMapArea();

  mvaddstrc(9, 1, white, "${liberal.name} talks to ");
  addstrc(target.align.color, target.name);
  addstrc(white, ":");

  int c = 0, hostages = 0, weaponhostage = 0;
  bool canSurrender = false;

  for (Creature squaddie in activeSquad!.livingMembers) {
    if (squaddie.prisoner?.alive == true &&
        squaddie.prisoner?.isEnemy == true) {
      hostages++;
      if (squaddie.weapon.type.canThreatenHostages) {
        weaponhostage++;
      }
    }
  }
  if (target.type.canPerformArrests) {
    canSurrender = true;
  }

  mvaddstrc(11, 1, lightGray, "A - Intimidate");
  setColorConditional(hostages > 0);
  mvaddstr(12, 1, "B - Threaten hostages");
  setColorConditional(target.isWillingToTalk);
  mvaddstr(13, 1, "C - Bluff");
  setColorConditional(canSurrender);
  mvaddstr(14, 1, "D - Surrender to authorities");
  setColor(lightGray);
  mvaddstr(15, 1, "E - Do nothing");
  while (true) {
    c = await getKey();

    if (c == 'a'.codePoint) break;
    if (c == 'b'.codePoint && hostages > 0) break;
    if (c == 'c'.codePoint && target.isWillingToTalk) break;
    if (c == 'd'.codePoint && canSurrender) break;
    if (c == 'e'.codePoint) return false;
  }

  if (c == 'a'.codePoint) {
    mvaddstrc(16, 1, white, "${liberal.name}: ");
    move(17, 1);
    setColor(lightGreen);

    switch (lcsRandom(4)) {
      case 0:
        // Formatting the slogan so that it always has quotes around it and punctuation
        if (slogan[0] != '"') addchar('"');
        addstr(slogan);
        int last = slogan.length;
        if (last > 0 &&
            slogan[last - 1] != '"' &&
            slogan[last - 1] != '!' &&
            slogan[last - 1] != '.' &&
            slogan[last - 1] != '?') {
          addchar('!');
        }
        if (last > 0 && slogan[last - 1] != '"') addchar('"');

      case 1:
        addstr("Die, you Conservative swine!");
      case 2:
        addstr("We're the Liberal Crime Squad!");
      case 3:
        addstr("Praying won't help you now!");
    }

    await getKey();

    setColor(white);

    for (int i = encounter.length - 1; i >= 0; i--) {
      Creature e = encounter[i];
      if (e.alive && e.isEnemy) {
        int attack =
            (liberal.juice / 50 + publicOpinion[View.lcsKnown]! / 10).round();
        int defense = e.attributeRoll(Attribute.wisdom);

        if (attack > defense) {
          if (e.type.intimidationResistant) {
            if (lcsRandom(3) > 0) continue;
          }
          clearMessageArea();
          mvaddstr(16, 1, e.name);
          switch (lcsRandom(6)) {
            case 0:
              addstr(" chickens out!");
            case 1:
              addstr(" backs off!");
            case 2:
              addstr(" doesn't want to die!");
            case 3:
              addstr(" is out of there!");
            case 4:
              addstr(" has a family!");
            case 5:
              addstr(" is too young to die!");
          }
          encounter.removeAt(i);
          addjuice(liberal, 2, 1000); // Instant juice!

          await getKey();
        }
      }
    }
  } else if (c == 'b'.codePoint) {
    mvaddstrc(16, 1, white, "${liberal.name}: ");
    setColor(lightGreen);
    move(17, 1);
    switch (lcsRandom(6)) {
      case 0:
        addstr("\"Back off or the hostage dies!\"");
      case 1:
        addstr("\"Don't push the LCS!\"");
      case 2:
        addstr("\"Hostage says you better leave!\"");
      case 3:
        addstr("\"I'll do it! I'll kill this one!\"");
      case 4:
        addstr("\"You gonna tell the family you pushed me?!\"");
      case 5:
        if (noProfanity) {
          addstr("\"Don't [play] with me!\"");
        } else {
          addstr("\"Don't fuck with me!\"");
        }
    }

    siteCrime += 5;
    criminalizeAll(squad, Crime.kidnapping);

    await getKey();

    bool noretreat = false;

    if (weaponhostage > 0) {
      Creature? e = encounter.firstWhereOrNull((e) =>
          e.isEnemy &&
          e.alive &&
          e.blood > 70 &&
          (e.type.canPerformArrests || e.type.edgelord));
      if (e != null) {
        mvaddstrc(16, 1, white, "${e.name}:");
        move(17, 1);
        if (e.align != Alignment.conservative ||
            (e.type.id == CreatureTypeIds.secretService &&
                exec[Exec.president]! > DeepAlignment.conservative)) {
          setColor(lightGreen);
          switch (lcsRandom(5)) {
            case 0:
              addstr("\"Let them go. Think about what you're doing.\"");
            case 1:
              addstr("\"Calm down, and let's talk about this.\"");
            case 2:
              addstr("\"Wait! We can work this out.\"");
            case 3:
              addstr("\"This isn't right, think about it.\"");
            case 4:
              addstr("\"Slow down. We can work this out.\"");
          }
        } else {
          setColor(red);
          if (e.type.edgelord && e.align == Alignment.conservative) {
            switch (lcsRandom(5)) {
              case 0:
                addstr("\"Hahahaha...\"");
              case 1:
                addstr("\"You think you can scare me?\"");
              case 2:
                addstr("\"You're not getting out of here alive.\"");
              case 3:
                addstr("\"What's wrong?  Need your diaper changed?\"");
              case 4:
                addstr("\"Three... two...\"");
            }
          } else {
            switch (lcsRandom(5)) {
              case 0:
                if (hostages > 1) {
                  addstr("\"Release your hostages, and nobody gets hurt.\"");
                } else {
                  addstr("\"Let the hostage go, and nobody gets hurt.\"");
                }
              case 1:
                addstr("\"You got about five seconds to back down.\"");
              case 2:
                addstr("\"You want to do this the hard way?\"");
              case 3:
                addstr("\"Big mistake.\"");
              case 4:
                addstr("\"Release them, and I'll let you go.\"");
            }
          }
        }

        await getKey();

        noretreat = true;
      }
      if (!noretreat || e == null) {
        clearMessageArea();
        mvaddstrc(16, 1, white, "The ploy works! The Conservatives back off.");
        for (int i = encounter.length - 1; i >= 0; i--) {
          if (encounter[i].alive && encounter[i].isEnemy) {
            encounter.removeAt(i);
          }
        }
        await getKey();
      } else {
        clearCommandArea();
        clearMessageArea();
        clearMapArea();
        mvaddstrc(9, 1, lightGray, "How should ${liberal.name} respond?");
        move(11, 1);
        if (hostages > 1) {
          addstr("A - Execute a hostage");
        } else {
          addstr("A - Execute the hostage");
        }
        move(12, 1);
        if (hostages > 1) {
          addstr("B - Offer to trade the hostages for freedom");
        } else {
          addstr("B - Offer to trade the hostage for freedom");
        }

        while (true) {
          c = await getKey();
          if (c == 'a'.codePoint || c == 'b'.codePoint) break;
        }
        if (c == 'a'.codePoint) {
          Creature executer = liberal;
          if (liberal.prisoner?.alive == true &&
              liberal.prisoner?.isEnemy == true) {
            executer = liberal;
          } else {
            for (Creature squaddie in squad) {
              if (squaddie.prisoner?.alive == true &&
                  squaddie.prisoner?.isEnemy == true) {
                executer = squaddie;
                break;
              }
            }
          }

          move(16, 1);
          setColor(red);
          if (executer.weapon.type.rangedAttack?.usesAmmo == true &&
              executer.weapon.ammo > 0) {
            addstr("BLAM!");
            executer.weapon.ammo--; //What if it doesn't use ammo? -XML
          } else {
            addstr("CRUNCH!");
          }

          await getKey();

          mvaddstrc(17, 1, white,
              "${executer.name} Heartlessly drops ${executer.prisoner!.name}'s body.");
          executer.heartDamage++;
          siteCrime += 10;
          addDramaToSiteStory(Drama.killedSomebody);
          criminalize(executer, Crime.murder);

          if (executer.prisoner!.type.preciousToHicks) {
            siteCrime += 30;
            offendedHicks = true;
          }
          makeLoot(executer.prisoner!, groundLoot);
          await getKey();

          executer.prisoner = null;

          if (hostages > 1 && !e.type.edgelord) {
            clearMessageArea();
            mvaddstrc(16, 1, white, "${e.name}: ");
            setColor(red);
            move(17, 1);
            if (noProfanity) {
              addstr("\"Fuck! ");
            } else {
              addstr("\"[No!] ");
            }
            switch (lcsRandom(5)) {
              case 0:
                addstr("Okay, okay, you win!\"");
              case 1:
                addstr("Don't shoot!\"");
              case 2:
                addstr("Do you even care?!\"");
              case 3:
                addstr("You monster!\"");
              case 4:
                addstr("It's not worth it!\"");
            }

            for (int i = encounter.length - 1; i >= 0; i--) {
              if (encounter[i].alive && encounter[i].isEnemy) {
                encounter.removeAt(i);
              }
            }

            await getKey();
          }
        } else if (c == 'b'.codePoint) {
          move(16, 1);
          mvaddstrc(16, 1, white, "${liberal.name}: ");
          setColor(lightGreen);
          move(17, 1);
          switch (lcsRandom(5)) {
            case 0:
              if (hostages > 1) {
                addstr("\"Back off and we'll let the hostages go.\"");
              } else {
                addstr("\"Back off and the hostage goes free.\"");
              }
            case 1:
              addstr("\"Freedom for freedom, understand?\"");
            case 2:
              addstr("\"Let me go in peace, okay?\"");
            case 3:
              addstr("\"Let's make a trade, then.\"");
            case 4:
              addstr("\"I just want out of here, yeah?\"");
          }

          await getKey();

          if (e.type.edgelord) {
            clearMessageArea();
            mvaddstrc(16, 1, white, "${e.name}: ");
            setColor(red);
            move(17, 1);
            switch (lcsRandom(5)) {
              case 0:
                addstr("\"Do I look like a loving person?\"");
              case 1:
                addstr("\"You don't take a hint, do you?\"");
              case 2:
                addstr("\"I'm doing the world a favor.\"");
              case 3:
                addstr("\"That's so pathetic...\"");
              case 4:
                addstr("\"It's a deal.\"");
            }

            await getKey();
          } else {
            clearMessageArea();
            mvaddstrc(16, 1, white, "${e.name}: ");
            setColor(red);
            move(17, 1);
            switch (lcsRandom(4)) {
              case 0:
                addstr("\"Yes. Nice and easy.\"");
              case 1:
                addstr("\"Fine. Let them go.\"");
              case 2:
                addstr("\"You got it. Let them go, and we're done.\"");
              case 3:
                addstr("\"No tricks, okay?\"");
            }

            await getKey();

            for (int i = encounter.length - 1; i >= 0; i--) {
              if (encounter[i].alive && encounter[i].isEnemy) {
                encounter.removeAt(i);
              }
            }

            clearMessageArea();
            setColor(white);
            move(16, 1);
            for (Creature squaddie in squad) {
              // Instant juice for successful hostage negotiation
              addjuice(squaddie, 15, 1000);
              if (squaddie.prisoner?.alive == true &&
                  squaddie.prisoner?.isEnemy == true) {
                squaddie.prisoner = null;
              }
            }
            if (hostages > 1) {
              addstr("The squad releases all hostages in the trade.");
            } else {
              addstr("The squad releases the hostage in the trade.");
            }

            await getKey();
          }
        }
      }
    } else {
      setColor(white);
      clearMessageArea();
      move(16, 1);
      addstr("${target.name} isn't interested in your pathetic threats.");

      await getKey();
    }
  } else if (c == 'c'.codePoint) {
    setColor(white);
    move(16, 1);
    if (activeSiteUnderSiege) {
      addstr("${liberal.name} ");
      switch (activeSite!.siege.activeSiegeType) {
        case SiegeType.police:
          addstr("pretends to be part of a police raid.");
        case SiegeType.cia:
          addstr("pretends to be a Secret Agent.");
        case SiegeType.hicks:
          switch (lcsRandom(2)) {
            case 0:
              addstr("pretends to be Mountain ");
              mvaddstr(17, 1, "like Patrick Swayze in Next of Kin.");
            case 1:
              addstr("squeals like Ned Beatty ");
              mvaddstr(17, 1, "in Deliverance.");
          }
        case SiegeType.ccs:
          switch (lcsRandom(3)) {
            case 0:
              addstr("makes a neo-Nazi hand gesture.");
            case 1:
              addstr("mutters something racist.");
            case 2:
              addstr("just starts growling slurs.");
          }
        case SiegeType.corporateMercs:
          addstr("pretends to be a mercenary.");
        case SiegeType.none:
          addstr("sniffs around for Liberals.");
      }
    } else {
      //Special bluff messages for various uniforms
      setColor(lightGreen);
      if (target.armor.typeName == "ARMOR_POLICEUNIFORM" ||
          target.armor.typeName == "ARMOR_POLICEARMOR" ||
          target.armor.typeName == "ARMOR_SWATARMOR") {
        addstr("\"The situation is under control.\"");
      } else if (target.armor.typeName == "ARMOR_BUNKERGEAR") {
        if (siteOnFire) {
          addstr("\"Fire! Evacuate immediately!\"");
        } else {
          addstr("\"Everything's in check.\"");
        }
      } else if (target.armor.typeName == "ARMOR_LABCOAT") {
        addstr("\"Make way, I'm a doctor!\"");
      } else if (target.armor.typeName == "ARMOR_DEATHSQUADBODYARMOR") {
        addstr("\"Non-targets please leave the site.\"");
      } else if (target.armor.typeName == "ARMOR_MITHRIL") {
        addstr("${liberal.name} engraves ");
        addstrc(RainbowFlag.red, "E");
        addstrc(RainbowFlag.orange, "l");
        addstrc(RainbowFlag.yellow, "b");
        addstrc(RainbowFlag.green, "e");
        addstrc(RainbowFlag.blue, "r");
        addstrc(RainbowFlag.purple, "e");
        addstrc(RainbowFlag.red, "t");
        addstrc(RainbowFlag.orange, "h");
        addstrc(lightGreen, " on the floor.");
      } else {
        addstr("${liberal.name} talks like a Conservative ");
        mvaddstr(17, 1, "and pretends to belong here.");
      }
    }

    await getKey();

    bool fooled = true;

    for (Creature e in encounter) {
      if (e.alive && e.isEnemy) {
        int roll = liberal.skillRoll(Skill.disguise);
        int diff = e.attribute(Attribute.heart) < 2
            ? Difficulty.challenging
            : Difficulty.average;
        fooled = roll >= diff;
        if (!fooled) break;
      }
    }

    liberal.train(Skill.disguise, 50);

    if (!fooled) {
      clearMessageArea();

      setColor(red);
      move(16, 1);
      if (target.type.id == CreatureTypeIds.hick) {
        addstr("But ${target.name} weren't born yesterday.");
      } else {
        addstr(target.name);
        if (noProfanity) {
          addstr(" is not fooled by that [act].");
        } else {
          addstr(" is not fooled by that crap.");
        }
      }

      await getKey();
    } else {
      clearMessageArea();
      mvaddstrc(16, 1, lightGreen, "The Enemy is fooled and departs.");
      await getKey();

      for (int i = encounter.length - 1; i >= 0; i--) {
        if (encounter[i].alive && encounter[i].isEnemy) {
          encounter.removeAt(i);
        }
      }
    }
  } else {
    clearMessageArea();
    mvaddstrc(14, 1, white, "The Squad surrenders and is arrested.");
    await getKey();

    int stolen = 0;
    // Police assess stolen goods in inventory
    for (Item loot in activeSquad!.loot) {
      if (loot is Loot) {
        stolen += loot.stackSize;
      }
    }

    for (Creature squaddie in squad.toList()) {
      squaddie.wantedForCrimes[Crime.theft] =
          (squaddie.wantedForCrimes[Crime.theft] ?? 0) + stolen;
      await captureCreature(squaddie);
    }
    squad.clear();
    activeSite?.siege.activeSiegeType = SiegeType.none;
  }
  return true;
}
