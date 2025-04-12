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
import 'package:lcs_new_age/sitemode/stealth.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<bool> talkInCombat(Creature liberal, Creature target) async {
  clearSceneAreas();

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

  addOptionText(11, 1, "A", "A - Intimidate");
  setColorConditional(hostages > 0);
  addOptionText(12, 1, "B", "B - Threaten hostages");
  setColorConditional(target.isWillingToTalk);
  addOptionText(13, 1, "C", "C - Bluff");
  setColorConditional(canSurrender);
  addOptionText(14, 1, "D", "D - Surrender to authorities");
  setColor(lightGray);
  addOptionText(15, 1, "E", "E - Do nothing");
  while (true) {
    c = await getKey();

    if (c == 'a'.codePoint) break;
    if (c == 'b'.codePoint && hostages > 0) break;
    if (c == 'c'.codePoint && target.isWillingToTalk) break;
    if (c == 'd'.codePoint && canSurrender) break;
    if (c == 'e'.codePoint) return false;
  }

  if (c == 'a'.codePoint) {
    await intimidate(liberal);
  } else if (c == 'b'.codePoint) {
    mvaddstrc(9, 1, white, "${liberal.name}: ");
    setColor(lightGreen);
    move(10, 1);
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
    addPotentialCrime(squad, Crime.terrorism,
        reasonKey: "threatening hostages");

    await getKey();

    bool noretreat = false;

    if (weaponhostage > 0) {
      Creature? e = encounter.firstWhereOrNull((e) =>
          e.isEnemy &&
          e.alive &&
          e.blood > 70 &&
          (e.type.canPerformArrests || e.type.edgelord));
      if (e != null) {
        mvaddstrc(9, 1, white, "${e.name}:");
        move(10, 1);
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
        mvaddstrc(9, 1, white, "The ploy works! The Conservatives back off.");
        for (int i = encounter.length - 1; i >= 0; i--) {
          if (encounter[i].alive && encounter[i].isEnemy) {
            encounter.removeAt(i);
          }
        }
        await getKey();
      } else {
        clearSceneAreas();
        mvaddstrc(9, 1, lightGray, "How should ${liberal.name} respond?");
        bool plural = hostages > 1;
        addOptionText(
            11, 1, "A", "A - Execute ${plural ? "a" : "the"} hostage");
        addOptionText(12, 1, "B",
            "B - Offer to trade the hostage${plural ? "s" : ""} for freedom");

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

          move(9, 1);
          setColor(red);
          if (executer.weapon.type.rangedAttack?.usesAmmo == true &&
              executer.weapon.ammo > 0) {
            addstr("BLAM!");
            executer.weapon.ammo--; //What if it doesn't use ammo? -XML
          } else {
            addstr("CRUNCH!");
          }

          await getKey();

          mvaddstrc(10, 1, white,
              "${executer.name} Heartlessly drops ${executer.prisoner!.name}'s body.");
          executer.heartDamage++;
          siteCrime += 10;
          addDramaToSiteStory(Drama.killedSomebody);
          addPotentialCrime(squad, Crime.murder);

          if (executer.prisoner!.type.preciousToAngryRuralMobs) {
            siteCrime += 30;
            offendedAngryRuralMobs = true;
          }
          makeLoot(executer.prisoner!, groundLoot);
          await getKey();

          executer.prisoner = null;

          if (hostages > 1 && !e.type.edgelord) {
            clearMessageArea();
            mvaddstrc(9, 1, white, "${e.name}: ");
            setColor(red);
            move(10, 1);
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
          move(9, 1);
          mvaddstrc(9, 1, white, "${liberal.name}: ");
          setColor(lightGreen);
          move(10, 1);
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
            mvaddstrc(9, 1, white, "${e.name}: ");
            setColor(red);
            move(10, 1);
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
            mvaddstrc(9, 1, white, "${e.name}: ");
            setColor(red);
            move(10, 1);
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
            move(9, 1);
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
      move(9, 1);
      addstr("${target.name} isn't interested in your pathetic threats.");

      await getKey();
    }
  } else if (c == 'c'.codePoint) {
    setColor(white);
    move(9, 1);
    if (activeSiteUnderSiege) {
      addstr("${liberal.name} ");
      switch (activeSite!.siege.activeSiegeType) {
        case SiegeType.police:
          addstr("pretends to be part of a police raid.");
        case SiegeType.cia:
          addstr("pretends to be a Secret Agent.");
        case SiegeType.angryRuralMob:
          addstr([
            "complains loudly about John Deere contracts.",
            "mutters about city folks messing things up.",
            "grumbles about the 'good old days'.",
            "blusters about the rising cost of feed.",
            "yells \"I think they went that-a-way!\"",
            "says \"They're hidin' here somewhere!\"",
            "asks \"Y'all seen 'em anywheres?\"",
            "says \"I reckon they's in the barn.\"",
            "says \"Doubt they coulda gone far!\"",
            "shouts \"They went 'round that way!\"",
          ].random);
        case SiegeType.ccs:
          addstr([
            "makes a neo-Nazi hand gesture.",
            "mutters something racist.",
            "just starts growling slurs.",
            "parrots a hateful slogan.",
            "mutters a vague insult about minorities.",
          ].random);
        case SiegeType.corporateMercs:
          addstr("pretends to be a mercenary.");
        case SiegeType.none:
          addstr("sniffs around for Liberals.");
      }
    } else {
      //Special bluff messages for various uniforms
      setColor(lightGreen);
      if (target.clothing.typeName == "CLOTHING_POLICEUNIFORM" ||
          target.clothing.typeName == "CLOTHING_POLICEARMOR" ||
          target.clothing.typeName == "CLOTHING_SWATARMOR") {
        addstr("\"The situation is under control.\"");
      } else if (target.clothing.typeName == "CLOTHING_BUNKERGEAR") {
        if (siteOnFire) {
          addstr("\"Fire! Evacuate immediately!\"");
        } else {
          addstr("\"Everything's in check.\"");
        }
      } else if (target.clothing.typeName == "CLOTHING_LABCOAT") {
        addstr("\"Make way, I'm a doctor!\"");
      } else if (target.clothing.typeName == "CLOTHING_DEATHSQUADBODYARMOR") {
        addstr("\"Non-targets please leave the site.\"");
      } else if (target.clothing.typeName == "CLOTHING_MITHRIL") {
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
        mvaddstr(10, 1, "and pretends to belong here.");
      }
    }

    await getKey();

    bool fooled = true;

    for (Creature e in encounter) {
      if (e.alive && e.isEnemy) {
        DisguiseQuality disguise = disguiseQuality(liberal);
        int penalty = disguise.penalty;
        int roll = liberal.skillRoll(Skill.disguise) + penalty;
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
      move(9, 1);
      if (target.type.id == CreatureTypeIds.angryRuralMob) {
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
      mvaddstrc(9, 1, lightGreen, "The Enemy is fooled and departs.");
      await getKey();

      for (int i = encounter.length - 1; i >= 0; i--) {
        if (encounter[i].alive && encounter[i].isEnemy) {
          encounter.removeAt(i);
        }
      }
    }
  } else {
    clearMessageArea();
    mvaddstrc(9, 1, white, "The Squad surrenders and is arrested.");
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

Future<void> intimidate(Creature liberal) async {
  clearMessageArea();
  mvaddstrc(9, 1, white, "${liberal.name}: ");
  move(10, 1);
  setColor(lightGreen);

  bool enemyPresent = false;
  for (Creature e in encounter) {
    if (e.alive && e.isEnemy && !e.calculateWillRunAway()) {
      enemyPresent = true;
      break;
    }
  }

  String formattedSlogan = "";
  if (slogan[0] != '"') formattedSlogan += '"';
  formattedSlogan += slogan;
  int last = slogan.length;
  if (last > 0 &&
      slogan[last - 1] != '"' &&
      slogan[last - 1] != '!' &&
      slogan[last - 1] != '.' &&
      slogan[last - 1] != '?') {
    formattedSlogan += "!";
  }
  if (last > 0 && slogan[last - 1] != '"') formattedSlogan += '"';

  if (enemyPresent) {
    addstr([
      formattedSlogan,
      "Run, you Conservative swine!",
      "We're the Liberal Crime Squad!",
      "Praying won't help you now!",
      "You fight like a dairy farmer!",
      "You're in the wrong place!",
      "Don't mess with the LCS!",
      "You're in for it now!",
      "Go now or I'll kill you!",
      "Run away, and never return!",
      if (noProfanity) "[Please leave!]" else "Get the fuck out of here!",
      "I swear to Darwin I'll end you!",
      "Don't make me ${noProfanity ? "[be mean]" : "fuck you up"}!",
      "I pity the fool who stands against the LCS!",
      "Anybody feel like dying a hero?",
    ].random);
  } else {
    if (encounter.any(
        (e) => e.equippedWeapon != null && e.align == Alignment.conservative)) {
      addstr([
        "Hands in the air and you can walk!",
        "Step back, drop your weapons, and walk out.",
        "Drop it now!  I won't ask twice!",
        "If you're giving up, show me your hands.",
        "Put your weapons down and walk away.",
        "Drop it before I drop you!",
        "Lose the weapon and get out of here!",
        "Drop your weapons and back off!",
      ].random);
    } else {
      addstr([
        formattedSlogan,
        "Don't push your luck.",
        "Walk away. Now!",
        "If you don't want more trouble, then go.",
        "I'm giving you chance to run.",
        "Go on, get out of here.",
        "You better leave.",
        "You don't want to be here.",
        "Back off and live to see another day.",
        "You don't have to die today.",
        "You can walk away from this.",
        "Turn around and walk away.",
        "Get moving. Now.",
        "I don't want to see you again.",
        "Out! Go, before I change my mind.",
      ].random);
    }
  }
  await getKey();

  for (int i = encounter.length - 1; i >= 0; i--) {
    Creature e = encounter[i];
    if (e.alive && e.isEnemy) {
      int attack =
          (liberal.juice / 50 + publicOpinion[View.lcsKnown]! / 10).round();
      int defense = e.attributeRoll(Attribute.wisdom);
      if (e.type.intimidationResistant) defense = defense * 2;

      if (attack > defense || e.nonCombatant) {
        clearMessageArea();
        mvaddstrc(9, 1, white, e.name);

        if (e.equippedWeapon != null) {
          addstr(" drops the ${e.equippedWeapon!.getName()} and");
          e.dropWeapon(lootPile: groundLoot);
        }

        if (e.body.legok < 2 || e.blood < e.maxBlood * 0.45) {
          addstr(escapeCrawling.random);
        } else {
          addstr(escapeRunning.random);
        }
        encounter.removeAt(i);
        addjuice(liberal, 2, 1000); // Instant juice!

        await getKey();
      }
    }
  }
}
