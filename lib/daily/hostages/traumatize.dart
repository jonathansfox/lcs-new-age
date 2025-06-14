import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/daily/advance_day.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<int> traumatize(Creature lead, String action, int y) async {
  if (lcsRandom(lead.attribute(Attribute.heart)) > lcsRandom(3)) {
    setColor(lightGreen);
    addparagraph(
        y++,
        0,
        "${lead.name} loses Heart and ${[
          "throws up in a trash can",
          "gets drunk, eventually falling asleep",
          "curls up in a ball, crying softly",
          "shoots up and collapses in a heap on the floor",
          "has a panic attack",
          "asks \"Are we the baddies?\"",
          "doesn't want to talk to anyone",
          "can't sleep for days",
          "is haunted by the memory of the $action",
          "has nightmares afterwards"
        ].random}.");
    lead.heartDamage += 1;
    move(y++, 0);
    lead.activity = Activity.none();
  } else if (oneIn(3) && lead.attribute(Attribute.wisdom) < 10) {
    setColor(lightBlue);
    addparagraph(y++, 0, "${lead.name} gains Wisdom and grows colder.");
    lead.adjustAttribute(Attribute.wisdom, 1);
  } else if (oneIn(3) &&
      lead.attribute(Attribute.wisdom) > lead.attribute(Attribute.heart)) {
    String name = lead.name;
    mvaddstrc(y++, 0, lightGray, "$name leaves the safehouse in a daze.");
    await getKey();
    mvaddstrc(
        y++,
        2,
        midGray,
        [
          "$name wanders the streets all night, lost in thought.",
          "$name gets drunk while out and rethinks this life.",
          "$name runs naked through the park at night.",
          "$name wanders aimlessly through the city, unable to think.",
          "$name finds a quiet diner and watches people exist.",
          "$name lies on a park bench, wracked by regret.",
          "$name walks until exhaustion forces ${lead.gender.himHer} to collapse.",
          "$name goes to a bar and meets some new people.",
          "$name lies down in a dumpster, where ${lead.gender.heShe} belongs.",
          "$name knocks on people's doors, turned away every time.",
          "$name sits in a bar, drinking and staring at the wall.",
          "$name stares at a church for hours, before going in.",
          "$name follows flickering streetlights into the darkness.",
          "$name sits in a park, watching people with regular lives.",
          "$name walks until the city dissolves into fog.",
          "$name stares up at the moon as it draws impossibly close.",
          "$name catches a bus, not knowing where it leads.",
          "$name catches a bus and rides it to the end of the line.",
          "$name catches a bus to the next city.",
          "\"I don't want to do this anymore...\"",
          "\"I need to get out of here!\"",
          "\"I can't do this anymore.\"",
          "\"I hate who I've become...\"",
          "\"I don't want to be a part of this...\"",
          "\"I hate this place!\"",
          "\"Fuck all of this!\"",
          "\"Fucking LCS bullshit...\"",
          "\"Who gives a shit about this anyway...\"",
          "\"What am I fucking doing?\"",
          "\"I hate this, I hate myself.\"",
          "\"I used to think I was a good person...\"",
        ].random);
    await getKey();
    if (oneIn(2)) {
      if (oneIn(2)) {
        mvaddstrc(y++, 4, darkGray, "${lead.name} never comes back.");
        lead.location = null;
        lead.die(); // they might be alive, but it doesn't matter to the LCS
        lead.boss?.juice -= 25;
        if (oneIn(2)) {
          lead.base?.siege.timeUntilCops = 2;
        }
      } else {
        lead.location = null;
        lead.hidingDaysLeft = lcsRandom(3) + 2;
        mvaddstrc(y++, 4, darkGray,
            "${lead.name} doesn't come back for several days...");
      }
    } else {
      mvaddstrc(y++, 4, lightGray,
          "${lead.name} returns to the safehouse after a few hours.");
    }
  } else {
    mvaddstrx(y++, 0, "&w${lead.name} &mdoesn't really &Kfeel anything...");
  }
  await getKey();
  if (!lead.alive) {
    await dispersalCheck();
  }
  return y;
}
