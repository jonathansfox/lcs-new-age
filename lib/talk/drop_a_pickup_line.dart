import 'package:collection/collection.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/dating.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/sitemode/site_display.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<bool> doYouComeHereOften(Creature a, Creature tk) async {
  int y = 12;
  clearSceneAreas();
  mvaddstrc(9, 1, white, "${a.name} says, ");
  move(10, 1);
  setColor(lightGreen);
  int line;
  if (noProfanity) {
    line = lcsRandom(3);
    switch (line) {
      case 0:
        addstr("\"[What church do you go to?]\"");
      case 1:
        addstr("\"[Will you marry me?]\"");
      case 2:
        addstr("\"[Do you believe in abstinence education?]\"");
    }
  } else {
    line = lcsRandom(47);
    switch (line) {
      case 0:
        addstr("\"Hey baby, you're kinda ugly.  I like that.\"");
      case 1:
        addstr("\"I lost my phone number.  Could I have yours?\"");
      case 2:
        addstr("\"Hey, you wanna go rub one off?\"");
      case 3:
        String honey = switch (tk.gender) {
          Gender.female => "honey",
          Gender.male => "boy",
          _ => "buddy",
        };
        addstr("\"Hot damn.  You're built like a brick shithouse, $honey.\"");
      case 4:
        addstr("\"I know I've seen you on the back of a milk carton, ");
        move(11, 1);
        y++;
        addstr("cuz you've been missing from my life.\"");
      case 5:
        addstr("\"I'm big where it counts.\"");
      case 6:
        String girl = switch (tk.gender) {
          Gender.male => "boy",
          Gender.female => "girl",
          _ => "yo",
        };
        addstr(
            "\"Daaaaaamn $girl, I want to wrap your legs around my face and ");
        move(11, 1);
        y++;
        addstr("wear you like a feed bag!\""); // Bill Hicks
      case 7:
        if (a.gender == Gender.male) {
          addstr("\"Let's play squirrel.  I'll bust a nut in your hole.\"");
        } else if (tk.gender == Gender.male) {
          addstr(
              "\"Let's play squirrel.  I'll let you bust a nut in my hole.\"");
        } else {
          // Female to female
          addstr(
              "\"Let's flip a coin.  Heads, you're mine, tails, I'm yours.\"");
        }
      case 8:
        addstr("\"You know, if I were you, I'd have sex with me.\"");
      case 9:
        String chick = switch (tk.gender) {
          Gender.male => "guy",
          Gender.female => "chick",
          _ => "person",
        };
        addstr("\"You don't sweat much for a fat $chick.\"");
      case 10:
        addstr("\"Fuck me if I'm wrong but you want to kiss me, right?\"");
      case 11:
        if (a.gender == Gender.male) {
          addstr("\"Are you a communist?");
          mvaddstr(11, 1,
              "'Cause you're inspiring an uprising in my lower class.\"");
          y++;
        } else if (tk.gender == Gender.male) {
          addstr("\"Are you a communist?");
          mvaddstr(11, 1,
              "'Cause I seem to be inspiring an uprising in your lower class.\"");
          y++;
        } else {
          addstr("\"Are you a communist?");
          mvaddstr(
              11, 1, "'Cause you're bringing some heat to my lower class.\"");
          y++;
        }
      case 12:
        addstr(
            "\"Let's play trains...  you can sit on my face and I will chew chew chew.\"");
      case 13:
        addstr("\"Is it hot in here or is it just you?\"");
      case 14:
        addstr(
            "\"I may not be Fred Flintstone, but I can make your bed rock!\"");
      case 15:
        addstr(
            "\"What do you say we go behind a rock and get a little boulder?\"");
      case 16:
        String panties = switch (tk.gender) {
          Gender.male => "briefs",
          Gender.female => "panties",
          _ => "underwear",
        };
        addstr(
            "\"Do you have stars on your $panties?  Your ass is outta this world!\"");
      case 17:
        addstr("\"Those pants would look great on the floor of my bedroom.\"");
      case 18:
        addstr(
            "\"If I said you had a nice body, would you hold it against me?\"");
      case 19:
        addstr(
            "\"Are you tired?  You've been running around in my thoughts all day.\"");
      case 20:
        addstr(
            "\"If I could change the alphabet baby, I would put the U and I together!\"");
      case 21:
        addstr("\"Your lips look sweet.  Can I taste them?\"");
      case 22:
        addstr("\"Nice shoes.  Wanna fuck?\"");
      case 23:
        addstr("\"Your sexuality makes me nervous and this frustrates me.\"");
      case 24:
        addstr("\"Are you Jamaican?  Cuz Jamaican me horny.\"");
      case 25:
        if (a.gender == Gender.female && tk.gender == Gender.male) {
          addstr("\"Hey pop tart, fancy coming in my toaster of love?\"");
        } else if (a.gender == Gender.male && tk.gender == Gender.female) {
          addstr(
              "\"Hey, fancy letting my pop tart into your toaster of love?\"");
        } else {
          addstr("\"Bi~ the way, are you free tonight?\"");
        }
      case 26:
        addstr("\"Wanna play army?  You lie down and I'll blow you away.\"");
      case 27:
        addstr("\"Can I lick your forehead?\"");
      case 28:
        addstr("\"I have a genital rash.  Will you rub this ointment on me?\"");
      case 29:
        addstr("\"What's your sign?\"");
      case 30:
        addstr("\"Do you work for the post office? ");
        move(11, 1);
        y++;
        if (a.gender == Gender.male) {
          addstr(
              "Because I could have sworn you were checking out my package.\"");
        } else if (tk.gender == Gender.male) {
          addstr("Because I can't help but check out your package.\"");
        } else {
          addstr(
              "\"Because I could have sworn you were checking out my packages.\"");
        }
      case 31:
        addstr("\"I'm not the most attractive person in here, ");
        move(11, 1);
        y++;
        addstr("but I'm the only one talking to you.\"");
      case 32:
        addstr("\"Hi.  I suffer from amnesia.  Do I come here often?\"");
      case 33:
        addstr(
            "\"I'm new in town.  Could you give me directions to your apartment?\"");
      case 34:
        addstr("\"Stand still so I can pick you up!\"");
      case 35:
        addstr(
            "\"Your daddy must have been a baker, cuz you've got a nice set of buns.\"");
      case 36:
        addstr("\"If you were a laser, you'd be set on 'stunning'.\"");
      case 37:
        addstr(
            "\"Is that a keg in your pants?  Cuz I'd love to tap that ass.\"");
      case 38:
        addstr("\"If I could be anything, I'd love to be your bathwater.\"");
      case 39:
        addstr("\"Stop, drop and roll, baby.  You are on fire.\"");
      case 40:
        if (a.gender == Gender.male) {
          addstr("\"Do you want to see something swell?\"");
        } else {
          addstr("\"I'd love to see something swell.\"");
        }
      case 41:
        addstr("\"Excuse me.  Do you want to fuck or should I apologize?\"");
      case 42:
        addstr("\"Say, did we go to different schools together?\"");
      case 43:
        addstr("\"You smell...  Let's go take a shower.\"");
      case 44:
        addstr("\"Roses are red, violets are blue,");
        move(11, 1);
        y++;
        addstr("All my base, are belong to you.\"");
      case 45:
        addstr("\"Did it hurt when you fell from heaven?\"");
      case 46:
        addstr(
            "\"Holy shit you're hot!  I want to have sex with you RIGHT NOW.\"");
    }
  }

  await getKey();

  int difficulty = Difficulty.challenging;
  if (tk.type.majorEnemy) {
    difficulty = Difficulty.heroic;
  }

  // Liberals a little more sexually liberated
  if (tk.align == Alignment.liberal) {
    difficulty += DifficultyModifier.aLittleEasier;
  } else if (tk.align == Alignment.conservative) {
    difficulty += DifficultyModifier.aLittleHarder;
  }

  // 20% chance the target is allured by nudity, 80% chance they're scandalized
  if (a.indecent) {
    if (!oneIn(5)) {
      difficulty += DifficultyModifier.aLotHarder;
    } else {
      difficulty += DifficultyModifier.aLotEasier;
    }
  }

  // Penalty for lgbt seduction attempts based on lgbt laws
  // Exemptions:
  // - Any Liberal target
  // - Non-binary targets
  // - Transgender targets
  int lgbtPenalty = 0;
  bool sameSex = a.gender.simplified == tk.gender.simplified;
  bool trans =
      a.gender != a.genderAssignedAtBirth || a.gender == Gender.nonbinary;
  bool targetIsTrans =
      tk.gender != tk.genderAssignedAtBirth || tk.gender == Gender.nonbinary;
  bool targetIsLiberal = tk.align == Alignment.liberal;
  if ((sameSex || trans) && !targetIsLiberal && !targetIsTrans && !oneIn(10)) {
    lgbtPenalty = switch (politics.laws[Law.lgbtRights]!) {
      DeepAlignment.archConservative => DifficultyModifier.aLotHarder,
      DeepAlignment.conservative => DifficultyModifier.moderatelyHarder,
      DeepAlignment.moderate => DifficultyModifier.moderatelyHarder,
      DeepAlignment.liberal => DifficultyModifier.aLittleHarder,
      DeepAlignment.eliteLiberal => 0,
    };
    if (sameSex && trans) lgbtPenalty ~/= 2;
    if (tk.align == Alignment.moderate) lgbtPenalty ~/= 2;
    if (trans && a.skillCheck(Skill.disguise, Difficulty.challenging)) {
      lgbtPenalty ~/= 2;
    }
    difficulty += lgbtPenalty;
  } else if (trans && targetIsTrans) {
    difficulty += DifficultyModifier.aLotEasier;
  }

  // Age mechanics taken from Terra Vitae
  if (a.age > tk.age) {
    difficulty += (a.age - tk.age) ~/ 5 - 1;
  } else {
    difficulty += (tk.age - a.age) ~/ 10 - 1;
  }

  int result = a.skillRoll(Skill.seduction);
  bool succeeded = result >= difficulty;
  if ((tk.seduced && tk.hireId == a.id) ||
      datingSessions.any((d) => d.lcsMember == a && d.dates.contains(tk))) {
    succeeded = true;
  } else if (poolAndProspects.contains(tk)) {
    succeeded = false;
  }
  if ((tk.type.animal && !animalsArePeopleToo && !a.type.animal) ||
      tk.type.tank) {
    mvaddstrc(y++, 1, white, tk.name);

    if (tk.type.tank) {
      addstr(" shakes its turret a firm 'no'.");
    } else if (tk.type.dog) {
      addstr(" says, ");
      move(y, 1);
      setColor(red);
      switch (lcsRandom(3)) {
        case 0:
          addstr("\"No! Wrong! I'm a dog!! Jesus.\"");
        case 1:
          addstr("\"What?! Ugh, I'm going to toss my kibble.\"");
        case 2:
          addstr("\"Okay, you need to stop petting me now.\"");
      }
      tk.align = Alignment.conservative;
      tk.isWillingToTalk = false;
    } else if (tk.type.id == CreatureTypeIds.genetic) {
      addstr(" says, ");
      move(y, 1);
      setColor(red);
      switch (lcsRandom(8)) {
        case 0:
          addstr("\"Foolish human!\"");
        case 1:
          addstr("\"Never thought I'd hear that...\"");
        case 2:
          addstr("\"STRANGER DANGER.\"");
        case 3:
          addstr("\"I am not laughing, mortal!\"");
        case 4:
          addstr("\"Gag!\"");
        case 5:
          addstr("\"You would make jokes with the likes of me?!\"");
        case 6:
          addstr("\"I am above such mortal sins!\"");
        case 7:
          addstr("\"You foul, disgusting human...!\"");
      }
      tk.align = Alignment.conservative;
      tk.isWillingToTalk = false;
    } else {
      addstr(" doesn't quite pick up on the subtext.");
    }

    await getKey();

    return true;
  }

  a.train(Skill.seduction, 10);

  if (a.clothing.type.police && tk.type.id == CreatureTypeIds.sexWorker) {
    mvaddstrc(y++, 1, white, "${tk.name} responds, ");
    setColor(red);
    move(y++, 1);

    String guyGirl = switch (a.gender) {
      Gender.male => "guy",
      Gender.female => "girl",
      _ => "person",
    };

    addstr([
      "\"Dirty. You know that's illegal, officer.\"",
      "\"Sorry, I don't date cops.\"",
      "\"I think you've mistaken me for someone else, sir.\"",
      "\"I'm not that kind of $guyGirl, officer.\"",
      "\"Nope. I don't do police roleplay.\"",
      "\"I'm not interested, officer.\"",
      "\"Um, officer, isn't that illegal?\"",
    ].random);

    await getKey();

    tk.isWillingToTalk = false;
  } else if (tk.name == "Prisoner") {
    mvaddstrc(y++, 1, white, "${tk.name} responds, ");
    move(y++, 1);
    setColor(red);
    addstr([
      "\"I don't even know who the fuck you are.\"",
      "\"Weird.\"",
      "\"This is a prison, Hoss.\"",
      "\"What the fuck?\"",
      "\"That's hot.\"",
      "\"Why are you talking to me?\"",
      "\"Get a load of this idiot.\"",
    ].random);

    await getKey();

    tk.isWillingToTalk = false;
  } else if (succeeded || tk.type.id == CreatureTypeIds.sexWorker) {
    String responds = "responds";
    if (a.indecent) {
      responds = "openly stares";
    }
    mvaddstrc(y++, 1, white, "${tk.name} $responds, ");
    setColor(lightBlue);
    move(y++, 1);

    if (noProfanity) {
      switch (line) {
        case 0:
          addstr("\"[I go to your church.]\"");
        case 1:
          addstr("\"[Yes.]\"");
        case 2:
          addstr("\"[Yes.  Yes, I do.]\"");
      }
    } else {
      switch (line) {
        //LIMIT          :-----------------------------------------------------------------------------:
        case 0:
          addstr("\"You're not so cute yourself.  Wanna get a room?\"");
        case 1:
          addstr("\"How sweet!  You can call me tonight...\"");
        case 2:
          addstr("\"You bet, baby.\"");
        case 3:
          addstr(
              "\"He he, I'll let that one slide.  Besides, I like country folk...\"");
        case 4:
          addstr("\"That's sick.  I can do sick tonight.\"");
        case 5:
          addstr("\"Oooo, let me see!\"");
        case 6:
          addstr(
              "\"Wow, looks like I'm going to have to reward creativity tonight!\"");
        case 7:
          if (a.gender == Gender.male) {
            addstr("\"Winter's coming.  You'd better bust more than one.\"");
          } else if (tk.gender == Gender.male) {
            addstr("\"Winter's coming.  I'd better bust more than one.\"");
          } else {
            addstr("\"Your coin or mine?\"");
          }
        case 8:
          addstr("\"But you're not, so the pleasure's all mine.\"");
        case 9:
          addstr("\"Just wait until tonight, baby.\"");
        case 10:
          addstr("\"You're wrong.\"");
        case 11:
          addstr("\"Sounds like conditions are right for me");
          mvaddstr(y++, 1, "to seize your means of reproduction.\"");
        case 12:
          if (tk.gender == Gender.male) {
            addstr("\"All aboard, but you better not bite!\"");
          } else {
            addstr("\"Oooo, all aboard baby!\"");
          }
        case 13:
          if (a.gender == Gender.male) {
            addstr("\"Not as hot as we'll be tonight you rake.\"");
          } else {
            addstr("\"Not as hot as we'll be tonight you slut.\"");
          }
        case 14:
          addstr("\"Goober.  You wanna hook up tonight?\"");
        case 15:
          addstr("\"Oooo, we should get stoned too!  He he.\"");
        case 16:
          if (tk.gender == Gender.male) {
            addstr("\"I'd be glad to whip out my rocket if you want a ride.\"");
          } else if (a.gender == Gender.male) {
            addstr(
                "\"You'll have to whip out your rocket to get some.  Let's do it.\"");
          } else {
            addstr("\"Oh yeah?  Why don't you let me show you the moon.\"");
          }
        case 17:
          addstr("\"So would my underwear.\"");
        case 18:
          addstr("\"Yeah, and you're going to repay me tonight.\"");
        case 19:
          addstr("\"Then stop *thinking* about it and come over tonight.\"");
        case 20:
          if (tk.gender == Gender.male || a.gender == Gender.male) {
            addstr(
                "\"As long as you put a condom between them, I'm all for it.\"");
          } else {
            addstr(
                "\"As long as you handle your letters with care, I'm all for it.\"");
          }
        case 21:
          if (tk.gender == Gender.female) {
            addstr("\"Sure, but you can't use your mouth.\"");
          } else if (a.gender == Gender.female) {
            addstr("\"I'm more interested in your lips, my dear.\"");
          } else {
            addstr(
                "\"I think that one's meant to be used on girls, ya goof.\"");
          }
        case 22:
          switch (lcsRandom(3)) {
            case 0:
              addstr("\"I hope you don't have a foot fetish, but I'm game.\"");
            case 1:
              addstr("\"Want me to keep 'em on in bed?\"");
            case 2:
              addstr("\"Hell yeah, and your shoes are pretty cute too.\"");
          }
        case 23:
          addstr("\"My sex could do even more.\"");
        case 24:
          addstr(
              "\"Let me invite you to visit my island paradise.  Tonight.\"");
        case 25:
          if (a.gender != tk.gender) {
            addstr("\"Oh, man...  just don't tell anybody I'm seeing you.\"");
          } else {
            addstr("\"Tonight?  I can make space for a gay old time.\"");
          }
        case 26:
          if (tk.genderAssignedAtBirth == Gender.male) {
            addstr(
                "\"I hope we're shooting blanks, soldier.  I'm out of condoms.\"");
          } else {
            addstr(
                "\"I'm not packing that kind of equipment, soldier, but I'm game.\"");
          }
        case 27:
          addstr("\"You can lick all my decals off, baby.\"");
        case 28:
          addstr("\"Only if I'm not allowed to use my hands.\"");
        case 29:
          addstr("\"The one that says 'Open All Night'.\"");
        case 30:
          if (a.gender == Gender.male) {
            addstr(
                "\"It looks like a letter bomb to me.  Let me blow it up.\"");
          } else if (tk.gender == Gender.male) {
            addstr("\"It might be a letter bomb.  Why don't you blow it up?\"");
          } else {
            addstr(
                "\"They seem like a good weight, but I'm sure I can hold them.\"");
          }
        case 31:
          addstr("\"Hey, I could do better.  But I'm feeling cheap tonight.\"");
        case 32:
          addstr("\"Yeah.  I hope you remember the lube this time.\"");
        case 33:
          addstr(
              "\"But if we use a hotel, you won't get shot by an angry spouse tonight.\"");
        case 34:
          addstr("\"I think you'll appreciate the way I move after tonight.\"");
        case 35:
          if (tk.gender == Gender.male) {
            addstr(
                "\"And my mother was a butcher.  Want to taste my sausage?\"");
          } else {
            addstr("\"They make a yummy bedtime snack.\"");
          }
        case 36:
          addstr(
              "\"Oh..  oh, God.  I can't believe I'm going to date a Trekkie.\"");
        case 37:
          addstr(
              "\"Oh, it isn't safe for you to drive like that.  You'd better stay the night.\"");
        case 38:
          addstr("\"Come over tonight and I can show you what it's like.\"");
        case 39:
          addstr("\"I'll stop, drop and roll if you do it with me.\"");
        case 40:
          if (a.gender == Gender.male) {
            addstr("\"I'd rather feel something swell.\"");
          } else if (tk.gender == Gender.male) {
            addstr("\"I'd rather let you feel something swell.\"");
          } else {
            addstr(
                "\"Can't help you there, but I can show you something slick.\"");
          }
        case 41:
          addstr("\"You can apologize later if it isn't any good.\"");
        case 42:
          addstr(
              "\"Yeah, and we tonight can try different positions together.\"");
        case 43:
          addstr("\"Don't you like it dirty?\"");
        case 44:
          addstr(
              "\"It's you!!  Somebody set up us the bomb.  Move 'Zig'.  For great justice.\"");
        case 45:
          String aSuccubus = switch (tk.gender) {
            Gender.male => "an incubus",
            _ => "a succubus",
          };
          addstr(
              "\"Actually I'm $aSuccubus from hell, and you're my next victim.\"");
        case 46:
          addstr(
              "\"Can you wait a couple hours?  I got 6 other people to fuck first.\"");
      }
    }

    await getKey();

    mvaddstrc(
        ++y, 1, white, "${a.name} and ${tk.name} make plans for tonight.");

    await getKey();

    if (!poolAndProspects.contains(tk)) {
      DatingSession? newd =
          datingSessions.firstWhereOrNull((element) => element.lcsMember == a);
      if (newd == null) {
        newd = DatingSession(a.id, a.location!.city);
        datingSessions.add(newd);
      }

      tk.nameCreature();

      tk.location = tk.workLocation;
      tk.base = a.base;

      newd.dates.add(tk);
    }

    encounter.remove(tk);
  } else {
    String responds = "responds";
    if (a.indecent) {
      responds = "looks away";
    }
    mvaddstrc(y++, 1, white, "${tk.name} $responds, ");
    setColor(red);
    move(y++, 1);
    if (tk.type.id == CreatureTypeIds.corporateCEO) {
      if (a.gender != Gender.male) {
        addstr("\"I'm a happily married man, sweetie.\"");
      } else {
        addstr("\"This ain't Brokeback Mountain, son.\"");
      }
    } else if (tk.type.id == CreatureTypeIds.president) {
      addstr("\"The last thing I need is another sex scandal.\"");
    } else if (noProfanity) {
      switch (line) {
        case 0:
          if (tk.align == Alignment.liberal) {
            addstr("\"[A different one.]\"");
          } else {
            addstr("\"${randomChurchName()}. Why?\"");
          }
        case 1:
          if (tk.align == Alignment.liberal) {
            addstr("\"[No.]\"");
          } else {
            addstr("\"Bless your heart.\"");
          }
        case 2:
          if (tk.align == Alignment.liberal) {
            addstr("\"[No.]\"");
          } else {
            addstr("\"Doesn't everyone?\"");
          }
      }
    } else if (lgbtPenalty > 0 &&
        tk.align == Alignment.conservative &&
        oneIn(2)) {
      String response = "Somethin's kinda buggin' me.";
      if (sameSex) {
        String gay;
        String aLesbian;
        String gayPeople;
        String gays;
        String cologne;
        String guys;
        if (a.gender == Gender.female) {
          gay = "lesbian";
          aLesbian = "a lesbian";
          gayPeople = "lesbians";
          gays = "lesbians";
          cologne = "perfume";
          guys = "girls";
        } else {
          gay = "gay";
          aLesbian = "gay";
          gayPeople = "gay people";
          gays = "gays";
          cologne = "cologne";
          guys = "guys";
        }

        response = [
          "With you? How progressive.",
          "Did somebody tell you I'm gay? 'Cause I'm not.",
          "I'm not interested.",
          "I like ${a.gender == Gender.female ? "guys" : "girls"}.",
          "I don't swing that way.",
          "Wait, with another ${a.gender.manWoman}? I... I could, but... no.",
          "Damn it, I told ${firstName()}, my $gay era was only a phase!",
          "Jesus...",
          "Lord save me from these $gayPeople sayin' weird things.",
          "Y'all $gayPeople need Jesus.",
          "Jesus, not again! It's gotta be my $cologne, $gays are all over me!",
          "I'm not gay.",
          "I'm only bi when I'm drunk, and I'm not drunk.",
          "Heh, that's funny. And gay.",
          "No no no no, I'm not $aLesbian, I'm not $aLesbian, I swear!",
          "Hot damn! This ${a.gender.manWoman}'s into me! I'm not even into $guys.",
          "Great. The only person willing to be with me is another ${a.gender.manWoman}.",
          "I'm straight.",
          "Huh. ${capitalize(gayPeople)}.",
          "I like ${a.gender == Gender.female ? "men" : "ladies"}.",
        ].random;
      } else if (trans) {
        Gender perceivedGender = forceGenderBinary(a.gender);
        String guyGirl = switch (perceivedGender) {
          Gender.male => "guy",
          Gender.female => "girl",
          _ => "person",
        };
        response = [
          "Jesus. Why are you trans ${guyGirl}s so fuckin' hot? Get outta here.",
          "Nah, I don't find you trans folks attractive.",
          "You some kinda queer?",
          "Ho, shit! I dig it, but you know... I could never be seen sayin' yes.",
          "No, I'm no chaser.",
          "That's sweet of ye, but I like my gender as normative as possible.",
          "Huh. I dig it. But no, I'm not gonna date a trans $guyGirl.",
          "You're kinda hot for a trans $guyGirl, but I ain't that brave.",
          "I'm not into that whole gender thing.",
          "I find your gender confusing and that makes me uncomfortable.",
          "Oh, uh... I don't think we can date, I don't have a pronoun.",
          if (a.genderAssignedAtBirth == Gender.female)
            "Why's your hair so short?"
          else
            "Why's your hair so long?",
          "Heh, don't get hit on by a trans $guyGirl every day.",
          "I don't know what gender you are and that makes me kinda frustrated.",
          "Oh lawd have mercy, the libs are tryin' ta trans my gender.",
        ].random;
      }
      addstr("\"$response\"");
    } else {
      switch (line) {
        case 0:
          addstr("\"You're such an asshole!\"");
          setColor(white);
          addstr(" <pouts>");
        case 1:
          addstr("\"Sure, here ya go...\"");
          setColor(white);
          addstr(" <writes wrong number>");
        case 2:
          addstr("\"I'm.. uh.. waiting for someone.\"");
          setColor(white);
          addstr(" <turns away>");
        case 3:
          addstr("\"Go use a real bathroom, ya hick.\"");
          setColor(white);
          addstr(" <points towards bathroom>");
        case 4:
          addstr("\"That was a very traumatic incident.\"");
          setColor(white);
          addstr(" <cries>");
        case 5:
          addstr("\"You're big everywhere, fatass.\"");
          setColor(white);
          addstr(" <laughs>");
        case 6:
          addstr("\"You're disgusting.\"");
          setColor(white);
          addstr(" <turns away>");
        case 7:
          if (a.gender == Gender.male || tk.gender == Gender.male) {
            addstr("\"You fuck squirrels?\"");
          } else {
            addstr("\"Huh?\"");
          }
          setColor(white);
          addstr(" <looks dumbfounded>");
        case 8:
          addstr("\"So what you're saying is you masturbate a lot.\"");
          setColor(white);
          addstr(" <wags finger>");
        case 9:
          addstr("\"You're a pig.\"");
          setColor(white);
          addstr(" <turns away>");
        case 10:
          addstr("\"Nice try, but no.\"");
          setColor(white);
          addstr(" <sticks out tongue>");
        case 11:
          addstr("\"Your game is as dead as your ideology.\"");
          setColor(white);
          addstr(" <turns away>");
        case 12:
          addstr("\"You look like a biter.\"");
          setColor(white);
          addstr(" <flinches>");
        case 13:
          addstr("\"I'm way outta your league, scumbag.\"");
          setColor(white);
          addstr(" <grabs pepper spray>");
        case 14:
          addstr("\"You still watch cartoons?\"");
          setColor(white);
          addstr(" <laughs>");
        case 15:
          addstr("\"I hate puns!  You suck at comedy.\"");
          setColor(white);
          addstr(" <frowns>");
        case 16:
          addstr("\"Yes, I'm an alien, you inferior Earth scum.\"");
          setColor(white);
          addstr(" <reaches for ray gun>");
        case 17:
          addstr("\"Not after I do this.\"");
          setColor(white);
          addstr(" <shits pants>");
        case 18:
          addstr("\"Yes, I can't stand liars.\"");
          setColor(white);
          addstr(" <crosses flabby arms>");
        case 19:
          addstr("\"I don't remember doing that.\"");
          setColor(white);
          addstr(" <looks confused>");
        case 20:
          addstr("\"We got a kindergarten dropout over here!\"");
          setColor(white);
          addstr(" <points and laughs>");
        case 21:
          addstr("\"No, I don't want to infect anyone else with herpes.\"");
          setColor(white);
          addstr(" <sighs>");
        case 22:
          addstr("\"Stop staring at my feet, you freak!\"");
          setColor(white);
          addstr(" <kicks you>");
        case 23:
          addstr("\"You're such a loser.\"");
          setColor(white);
          addstr(" <makes L sign on forehead>");
        case 24:
          addstr("\"I'm about to put a voodoo curse on yo ass...\"");
          setColor(white);
          addstr(" <starts chanting>");
        case 25:
          if (a.gender != tk.gender) {
            addstr("\"I don't approve of your hi-carb diet.\"");
            setColor(white);
            addstr(" <starts ranting about nutrition>");
          } else {
            addstr("\"Not even remotely.\"");
            setColor(white);
            addstr(" <starts ranting about work>");
          }
        case 26:
          addstr("\"Go back home to play with your G.I. Joe dolls.\"");
          setColor(white);
          addstr(" <scoffs>");
        case 27:
          addstr("\"No, and stop acting like a lost puppy.\"");
          setColor(white);
          addstr(" <hisses like a cat>");
        case 28:
          addstr("\"Jesus...\"");
          setColor(white);
          addstr(" <turns away>");
        case 29:
          addstr("\"I don't believe in astrology, you ignoramus.\"");
          setColor(white);
          addstr(" <blinds you with science>");
        case 30:
          if (a.gender == Gender.male) {
            addstr("\"Yes, and it's practically microscopic.\"");
            setColor(white);
            addstr(" <puts 2 fingers really close together>");
          } else if (tk.gender == Gender.male) {
            addstr("\"Keep your eyes to yourself.\"");
            setColor(white);
            addstr(" <turns away>");
          } else {
            addstr("\"These boxes aren't addressed to you.\"");
            setColor(white);
            addstr(" <turns away>");
          }
        case 31:
          addstr("\"My spouse will be here soon to straighten things out.\"");
          setColor(white);
          addstr(" <looks for spouse>");
        case 32:
          addstr("\"You're not my type.  I like sane people.\"");
          setColor(white);
          addstr(" <turns away>");
        case 33:
          addstr("\"Yes, here you go...\"");
          setColor(white);
          addstr(" <writes fake directions>");
        case 34:
          addstr("\"Gotta go!  Bye!\"");
          setColor(white);
          addstr(" <squirms away>");
        case 35:
          addstr("\"I don't do anal.\"");
          setColor(white);
          addstr(" <puts hands over butt>");
        case 36:
          addstr("\"Hey, look, a UFO!\"");
          setColor(white);
          addstr(" <ducks away>");
        case 37:
          addstr("\"Go home, you're drunk.\"");
          setColor(white);
          addstr(" <gestures away>");
        case 38:
          addstr("\"At least then you'd be liquidated.\"");
          setColor(white);
          addstr(" <stares intently>");
        case 39:
          addstr("\"Is that the best you can do?\"");
          setColor(white);
          addstr(" <looks bored>");
        case 40:
          addstr("\"Eew, no, gross.\"");
          setColor(white);
          addstr(" <turns away>");
        case 41:
          addstr("\"Just shove off.\"");
          setColor(white);
          addstr(" <turns away>");
        case 42:
          addstr("\"What on earth are you on about?\"");
          setColor(white);
          addstr(" <turns away>");
        case 43:
          addstr("\"Nothing works, I can't help it.\"");
          setColor(white);
          addstr(" <starts crying>");
        case 44:
          addstr("\"That meme is older than dirt.\"");
          setColor(white);
          addstr(" <shakes head>");
        case 45:
          addstr("\"Yes, now go away.\"");
          setColor(white);
          addstr(" <points to exit>");
        case 46:
          addstr("\"Touch me and you'll regret it.\"");
          setColor(white);
          addstr(" <crosses arms>");
      }
    }

    await getKey();

    tk.isWillingToTalk = false;
  }
  return false;
}

String randomChurchName() {
  String first = ["Holy", "Sacred", "Abiding", "Faithful", "Eternal"].random;
  String second = ["Cross", "Hope", "Flame", "Family", "Refuge"].random;
  String third = ["Church", "Church", "Cathedral", "Temple", "Chapel"].random;
  return "$first $second $third";
}
