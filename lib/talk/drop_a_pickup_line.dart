import 'package:collection/collection.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/dating.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/politics/alignment.dart';
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
        addstr("\"Hot damn.  You're built like a brick shithouse, honey.\"");
      case 4:
        addstr("\"I know I've seen you on the back of a milk carton, ");
        move(11, 1);
        y++;
        addstr("cuz you've been missing from my life.\"");
      case 5:
        addstr("\"I'm big where it counts.\"");
      case 6:
        addstr(
            "\"Daaaaaamn girl, I want to wrap your legs around my face and ");
        move(11, 1);
        y++;
        addstr("wear you like a feed bag!\""); // Bill Hicks
      case 7:
        addstr("\"Let's play squirrel.  I'll bust a nut in your hole.\"");
      case 8:
        addstr("\"You know, if I were you, I'd have sex with me.\"");
      case 9:
        addstr("\"You don't sweat much for a fat chick.\"");
      case 10:
        addstr("\"Fuck me if I'm wrong but you want to kiss me, right?\"");
      case 11:
        addstr("\"Are you a communist?");
        mvaddstr(
            11, 1, "'Cause you're inspiring an uprising in my lower class.\"");
        y++;
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
        addstr(
            "\"Do you have stars on your panties?  Your ass is outta this world!\"");
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
        addstr("\"Hey pop tart, fancy coming in my toaster of love?\"");
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
        addstr(
            "Because I could have sworn you were checking out my package.\"");
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
        addstr("\"Do you want to see something swell?\"");
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

  int difficulty = Difficulty.hard;
  if (tk.type.majorEnemy) {
    difficulty = Difficulty.heroic;
  }
  if (tk.type.id == CreatureTypeIds.corporateCEO ||
      tk.type.id == CreatureTypeIds.president) {
    difficulty = Difficulty.legendary;
  }

  if (a.indecent) {
    if (lcsRandom(5) > 0) {
      difficulty += 10;
    } else {
      difficulty -= 10;
    }
  }

  // Age mechanics taken from Terra Vitae
  if (a.age > tk.age) {
    difficulty += (a.age - tk.age) ~/ 5 - 1;
  } else {
    difficulty += (tk.age - a.age) ~/ 10 - 1;
  }

  bool succeeded = a.skillCheck(Skill.seduction, difficulty);
  if ((tk.seduced && tk.hireId == a.id) ||
      datingSessions.any((d) => d.lcsMember == a && d.dates.contains(tk))) {
    succeeded = true;
  } else if (poolAndProspects.contains(tk)) {
    succeeded = false;
  }
  if ((tk.type.animal && animalsArePeopleToo && !a.type.animal) ||
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

  if (a.armor.type.police && tk.type.id == CreatureTypeIds.sexWorker) {
    mvaddstrc(y++, 1, white, "${tk.name} responds, ");
    setColor(red);
    move(y++, 1);

    addstr("\"Dirty. You know that's illegal, officer.\"");

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
          addstr("\"Winter's coming.  You'd better bust more than one.\"");
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
          addstr("\"Oooo, all aboard baby!\"");
        case 13:
          addstr("\"Not as hot as we'll be tonight you slut.\"");
        case 14:
          addstr("\"Goober.  You wanna hook up tonight?\"");
        case 15:
          addstr("\"Oooo, we should get stoned too!  He he.\"");
        case 16:
          addstr(
              "\"You'll have to whip out your rocket to get some.  Let's do it.\"");
        case 17:
          addstr("\"So would my underwear.\"");
        case 18:
          addstr("\"Yeah, and you're going to repay me tonight.\"");
        case 19:
          addstr("\"Then stop *thinking* about it and come over tonight.\"");
        case 20:
          addstr(
              "\"As long as you put a condom between them, I'm all for it.\"");
        case 21:
          addstr("\"Sure, but you can't use your mouth.\"");
        case 22:
          addstr("\"I hope you don't have a foot fetish, but I'm game.\"");
        case 23:
          addstr("\"My sex could do even more.\"");
        case 24:
          addstr(
              "\"Let me invite you to visit my island paradise.  Tonight.\"");
        case 25:
          addstr("\"Oh, man...  just don't tell anybody I'm seeing you.\"");
        case 26:
          addstr(
              "\"I hope we're shooting blanks, soldier.  I'm out of condoms.\"");
        case 27:
          addstr("\"You can lick all my decals off, baby.\"");
        case 28:
          addstr("\"Only if I'm not allowed to use my hands.\"");
        case 29:
          addstr("\"The one that says 'Open All Night'.\"");
        case 30:
          addstr("\"It looks like a letter bomb to me.  Let me blow it up.\"");
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
          addstr("\"They make a yummy bedtime snack.\"");
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
          addstr("\"I'd rather feel something swell.\"");
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
          addstr(
              "\"Actually I'm a succubus from hell, and you're my next victim.\"");
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

      tk.location = a.location;
      tk.base = a.base;

      newd.dates.add(tk);

      encounter.remove(tk);
    }
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
    } else {
      switch (line) {
        //LIMIT          :-----------------------------------------------------------------------------:
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
          addstr("\"You fuck squirrels?\"");
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
          addstr("\"I don't approve of your hi-carb diet.\"");
          setColor(white);
          addstr(" <starts ranting about nutrition>");
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
          addstr("\"Yes, and it's practically microscopic.\"");
          setColor(white);
          addstr(" <puts 2 fingers really close together>");
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
          addstr("\"Laaaame.\"");
          setColor(white);
          addstr(" <looks bored>");
        case 40:
          addstr("\"Eew, no, gross.\"");
          setColor(white);
          addstr(" <vomits on you>");
        case 41:
          addstr("\"Too late for apologies!\"");
          setColor(white);
          addstr(" <slaps you>");
        case 42:
          addstr("\"What an idiot!\"");
          setColor(white);
          addstr(" <laughs>");
        case 43:
          addstr("\"Nothing works, I can't help it.\"");
          setColor(white);
          addstr(" <starts crying>");
        case 44:
          addstr("\"Hahahahaha!\"");
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
