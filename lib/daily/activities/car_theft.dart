import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_actions/common_actions.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/common_display/print_creature_info.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/sitemode/chase_sequence.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';
import 'package:lcs_new_age/vehicles/vehicle.dart';
import 'package:lcs_new_age/vehicles/vehicle_type.dart';

enum CarKeyLocation { ignition, sunblock, glove, frontSeat, backSeat, muffler }

class CarTheftScene {
  CarTheftScene(this.cr);
  Creature cr;
  bool alarmOn = false;
  bool bailed = false;
  bool senseAlarm = false;
  bool touchAlarm = false;
  String get alarmName => senseAlarm ? "THE VIPER" : v.fullName();
  int windowDamage = 0;
  late VehicleType cartype;
  late Vehicle v;

  Future<void> play() async {
    await _pickACar();
    if (bailed) return;
    await _lookAround();
    await _foundACar();
    await _approachTheCar();
    if (bailed) return;
    await _breakIn();
    if (bailed) return;
    await _startCar();
    if (bailed) return;
    await _driveAway();
  }

  Future<void> _breakIn() async {
    bool entered = false;
    while (!entered) {
      _addCarTheftHeader();
      if (alarmOn) {
        mvaddstrc(10, 0, white, "$alarmName: ");
        if (senseAlarm) {
          addstrc(red, "STAND AWAY FROM THE VEHICLE!   <BEEP!!> <BEEP!!>");
        } else {
          addstrc(red, "<BEEP!!> <BEEP!!> <BEEP!!> <BEEP!!>");
        }
      } else if (senseAlarm) {
        mvaddstrc(10, 0, white, "$alarmName:   ");
        addstrc(red, "THIS IS THE VIPER!   STAND AWAY!");
      } else {
        mvaddstrc(
            10, 0, lightGray, "${cr.name} stands by the ${v.fullName()}.");
      }
      addOptionText(12, 0, "A", "A - Pick the lock.");
      addOptionText(13, 0, "B", "B - Break the window.");
      move(14, 0);
      if (!senseAlarm) {
        addInlineOptionText("Enter", "Enter - Call it a day.");
      } else {
        if (!alarmOn) {
          addInlineOptionText(
              "Enter", "Enter - The Viper?   ${cr.name} is deterred.");
        } else {
          addInlineOptionText(
              "Enter", "Enter - Yes, the Viper has deterred ${cr.name}.");
        }
      }

      late int c;
      do {
        c = await getKey();
        if (isBackKey(c)) {
          bailed = true;
          return;
        }
      } while (c != Key.a && c != Key.b);

      //PICK LOCK
      if (c == Key.a) {
        if (cr.skillCheck(Skill.security, Difficulty.average)) {
          cr.train(Skill.security, 25);
          mvaddstrc(16, 0, white, "${cr.name} jimmies the car door open.");
          await getKey();
          entered = true;
        } else {
          mvaddstrc(
              16, 0, white, "${cr.name} fiddles with the lock with no luck.");
          await getKey();
        }
      }
      //BREAK WINDOW
      if (c == Key.b) {
        int difficulty = Difficulty.easy - windowDamage;

        if (cr.attributeCheck(Attribute.strength, difficulty)) {
          mvaddstrc(16, 0, white, "${cr.name} smashes the window");
          if ((cr.weapon.type.meleeAttack?.damage ?? 0) > 10) {
            addstr(" with a ");
            addstr(cr.weapon.getName(sidearm: true));
          }
          addstr(".");
          windowDamage = 10;
          await getKey();
          entered = true;
        } else {
          mvaddstrc(16, 0, white, cr.name);
          addstr(" cracks the window");
          if ((cr.weapon.type.meleeAttack?.damage ?? 0) > 10) {
            addstr(" with a ${cr.weapon.getName(sidearm: true)}");
          }
          addstr(" but it is still somewhat intact.");
          windowDamage++;
          await getKey();
        }
      }

      //ALARM CHECK
      int y = 17;
      if ((touchAlarm || senseAlarm) && !alarmOn) {
        mvaddstrc(y++, 0, yellow, "An alarm suddenly starts blaring!");
        await getKey();
        alarmOn = true;
      }

      //NOTICE CHECK
      if (oneIn(50) || (oneIn(5) && alarmOn)) {
        mvaddstrc(y++, 0, red, cr.name);
        addstr(" has been spotted by a passerby!");
        await getKey();

        //FOOT CHASE
        sitestory = NewsStory.prepare(NewsStories.carTheft);
        bailed = true;
        await soloChaseSequence(cr, 5);
        return;
      }
    }
  }

  Future<void> _startCar() async {
    CarKeyLocation? keyLocation = CarKeyLocation.values.random;
    if (!oneIn(5)) keyLocation = null;
    int nervousness = 0;
    int timesSearchedForKeys = 0;

    bool started = false;
    while (!started) {
      nervousness++;

      _addCarTheftHeader();
      int y = 10;

      mvaddstrc(y++, 0, lightGray,
          "${cr.name} is behind the wheel of a ${v.fullName()}.");
      if (alarmOn) {
        if (alarmOn) {
          mvaddstrc(y++, 0, white, "$alarmName: ");
          if (senseAlarm) {
            addstrc(red, "STAND AWAY FROM THE VEHICLE!   <BEEP!!> <BEEP!!>");
          } else {
            addstrc(red, "<BEEP!!> <BEEP!!> <BEEP!!> <BEEP!!>");
          }
        }
      }

      y++;
      late int c;
      if (keyLocation == CarKeyLocation.ignition) {
        // Key in ignition; notice them instantly upon entering the car
        c = Key.b;
      } else {
        addOptionText(y++, 0, "A", "A - Hotwire the car.");
        addOptionText(y++, 0, "B", "B - Desperately search for keys.");
        move(y++, 0);
        if (!senseAlarm) {
          addInlineOptionText("Enter", "Enter - Call it a day.");
        } else {
          addInlineOptionText(
              "Enter", "Enter - The Viper has finally deterred ${cr.name}.");
        }
        y++;
        do {
          c = await getKey();
          if (isBackKey(c)) {
            bailed = true;
            return;
          }
        } while (c != Key.a && c != Key.b);
      }

      //HOTWIRE CAR
      if (c == Key.a) {
        if (cr.skillCheck(Skill.security, Difficulty.hard)) {
          cr.train(Skill.security, 50);
          mvaddstrc(y++, 0, white, "${cr.name} hotwires the car!");
          await getKey();
          started = true;
        } else {
          mvaddstrc(y++, 0, white, cr.name);
          switch (lcsRandom(cr.skill(Skill.security) < 4 ? 3 : 5)) {
            case 0:
              addstr(" fiddles with the ignition, but the car doesn't start.");
            case 1:
              addstr(
                  " digs around in the steering column, but the car doesn't start.");
            case 2:
              addstr(
                  " touches some wires together, but the car doesn't start.");
            case 3:
              addstr(
                  " makes something in the engine click, but the car doesn't start.");
            case 4:
              addstr(
                  " manages to turn on some dash lights, but the car doesn't start.");
          }
          await getKey();
        }
      }
      //KEYS
      if (c == Key.b) {
        int difficulty;
        String location;

        if (keyLocation == null) {
          difficulty = 100;
          location = "in the bugfield!";
        } else {
          switch (keyLocation) {
            case CarKeyLocation.ignition:
              difficulty = Difficulty.automatic;
              location = "in the ignition.  Damn.";
            case CarKeyLocation.sunblock:
              difficulty = Difficulty.easy;
              location = "above the pull-down sunblock thingy!";
            case CarKeyLocation.glove:
              difficulty = Difficulty.easy;
              location = "in the glove compartment!";
            case CarKeyLocation.frontSeat:
              difficulty = Difficulty.average;
              location = "under the front seat!";
            case CarKeyLocation.backSeat:
              difficulty = Difficulty.hard;
              location = "under the back seat!";
            case CarKeyLocation.muffler:
              difficulty = Difficulty.legendary;
              location = "taped to the muffler!";
          }
        }
        if (cr.attributeCheck(Attribute.intelligence, difficulty)) {
          setColor(lightGreen);
          mvaddstrc(y++, 0, lightGreen,
              "Holy ${noProfanity ? "[Car Keys]" : "Shit"}!  ${cr.name} found the keys $location");
          await getKey();
          started = true;
        } else {
          timesSearchedForKeys++;
          mvaddstrc(y++, 0, white, cr.name);
          addstr(": <rummaging> ");
          setColor(lightGreen);
          if (timesSearchedForKeys == 5) {
            addstr("Are they even in here?");
          } else if (timesSearchedForKeys == 10) {
            addstr("I don't think they're in here...");
          } else if (timesSearchedForKeys == 15) {
            addstr("If they were here, I'd have found them by now.");
          } else if (timesSearchedForKeys > 15) {
            addstr([
              "This isn't working!",
              "Why me?",
              "What do I do now?",
              "Oh no...",
              "I'm going to get arrested, aren't I?",
            ].random);
          } else {
            addstr([
              "Please be in here somewhere...",
              "${noProfanity ? "[Shoot]" : "Fuck"}!  Where are they?!",
              "Come on, baby, come to me...",
              "${noProfanity ? "[Darn] it" : "Dammit"}...",
              "I wish I could hotwire this thing...",
            ].random);
          }

          await getKey();
        }
      }

      //NOTICE CHECK
      if (!started && (oneIn(50) || (alarmOn && oneIn(5)))) {
        mvaddstrc(y++, 0, red, cr.name);
        addstr(" has been spotted by a passerby!");

        await getKey();

        //FOOT CHASE
        sitestory = NewsStory.prepare(NewsStories.carTheft);
        await soloChaseSequence(cr, 5);
        mode = GameMode.base;
        bailed = true;
        return;
      }

      // Nervous message check
      else if (!started && (lcsRandom(7) + 5) < nervousness) {
        nervousness = 0;
        move(++y, 0);
        y++;
        setColor(yellow);
        addstr(cr.name);
        switch (lcsRandom(3)) {
          case 0:
            addstr(" hears someone nearby making a phone call.");
          case 1:
            addstr(" is getting nervous being out here this long.");
          case 2:
            addstr(" sees a police car driving around a few blocks away.");
        }
        await getKey();
      }
    }
  }

  Future<void> _driveAway() async {
    //CHASE SEQUENCE
    //CAR IS OFFICIAL, THOUGH CAN BE DELETE BY chasesequence()
    addjuice(cr, v.type.juice, 100);
    vehiclePool.add(v);
    v.heat += 14 + v.type.extraHeat;
    v.location = cr.base;
    // Automatically assign this car to this driver, if no other one is present
    if (cr.preferredCar == null) {
      cr.preferredCarId = v.id;
      cr.preferredDriver = true;
    }

    bool chaselev = oneIn(13 - windowDamage);
    if (chaselev ||
        (v.type.idName == "POLICECAR" &&
            oneIn(2))) //Identify police cruiser. Temporary solution? -XML
    {
      v.heat += 10;

      sitestory = NewsStory.prepare(NewsStories.carTheft);
      await soloChaseSequence(cr, 1, v: v);
    }
  }

  Future<void> _foundACar() async {
    if (!cr.skillCheck(Skill.streetSmarts, cartype.difficultyToFind * 2)) {
      VehicleType old = cartype;
      cartype = vehicleTypes.values
          .where((v) => v != old)
          .expand((v) => [for (int i = v.difficultyToFind; i < 10; i++) v])
          .random;
      mvaddstr(11, 0,
          "${cr.name} was unable to find a ${old.longName} but did find a ${cartype.longName}.");
    } else {
      mvaddstr(11, 0, "${cr.name} found a ${cartype.longName}.");
    }
    await getKey();
    cr.train(Skill.streetSmarts, 10);
    v = Vehicle(cartype.idName);
    alarmOn = false;
    windowDamage = 0;
    senseAlarm = lcsRandom(100) < v.type.senseAlarmChance;
    touchAlarm = lcsRandom(100) < v.type.touchAlarmChance;
  }

  Future<void> _lookAround() async {
    _addCarTheftHeader();
    mvaddstrc(10, 0, lightGray,
        "${cr.name} looks around for an accessible vehicle...");
    await getKey();
  }

  void _addCarTheftHeader() {
    erase();
    mvaddstrc(0, 0, white, "Adventures in Liberal Car Theft");
    printCreatureInfo(cr, showCarPrefs: ShowCarPrefs.onFoot);
    makeDelimiter();
  }

  Future<void> _approachTheCar() async {
    _addCarTheftHeader();
    mvaddstrc(10, 0, lightGray,
        "${cr.name} looks from a distance at an empty ${v.fullName()}.");
    addOptionText(12, 0, "A", "A - Approach the driver's side door.");
    addOptionText(13, 0, "Enter", "Enter - Call it a day.");

    while (true) {
      int c = await getKey();
      if (c == Key.a) break;
      if (isBackKey(c)) {
        bailed = true;
        break;
      }
    }
  }

  Future<void> _pickACar() async {
    List<VehicleType> cart =
        vehicleTypes.values.where((v) => v.difficultyToFind < 10).toList();
    bailed = true;
    erase();
    await pagedInterface(
      headerPrompt:
          "What type of car will ${cr.name} try to find and steal today?",
      headerKey: {4: "TYPE", 49: "DIFFICULTY TO FIND UNATTENDED"},
      footerPrompt: "Press a Letter to select a Type of Car",
      count: cart.length,
      lineBuilder: (y, key, index) {
        VehicleType v = cart[index];
        mvaddstrc(y, 0, lightGray, "$key - ${v.longName}");
        addDifficultyText(y, 49, v.difficultyToFind);
      },
      onChoice: (index) async {
        bailed = false;
        cartype = cart[index];
        return true;
      },
    );
    if (bailed) cr.activity = Activity.none();
  }
}
