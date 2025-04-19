import 'dart:ui';

import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/sitemode/site_display.dart';
import 'package:lcs_new_age/talk/talk_outside_combat.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<bool> heyMisterAnimal(List<(String, String)> goodTalk,
    List<(String, String)> badTalk, Creature target) async {
  bool success = false;
  String pitch, response;
  Creature liberal = squad.reduce((value, element) =>
      value.attribute(Attribute.heart) >= element.attribute(Attribute.heart)
          ? value
          : element);
  Color targetColor;
  if (liberal.attribute(Attribute.heart) >= 15) {
    success = true;
    (pitch, response) = goodTalk.random;
    targetColor = lightGreen;
  } else {
    target.isWillingToTalk = false;
    (pitch, response) = badTalk.random;
    targetColor = red;
  }

  clearSceneAreas();
  printEncounter();
  printSiteMapSmall(locx, locy, locz);

  mvaddstrc(9, 1, white, "${liberal.name}: ");
  mvaddstrc(10, 1, lightGreen, pitch);
  await getKey();

  clearMessageArea();

  mvaddstrc(9, 1, white, "${target.name}: ");
  mvaddstrc(10, 1, targetColor, response);
  await getKey();

  if (success) {
    if (target.align != Alignment.liberal) {
      for (Creature animal in encounter.where((e) => e.type == target.type)) {
        animal.align = Alignment.liberal;
      }
    } else {
      return await talkOutsideCombat(liberal, target);
    }
  }

  return true;
}

List<(String, String)> randomDogTalkGood = [
  (
    "\"I love dogs more than people.\"",
    "\"A human after my own heart, in more ways than one.\""
  ),
  (
    "\"Dogs are the future of humanity.\"",
    "\"I don't see it, but I'll hear you out.\""
  ),
  ("\"Power to the canines!\"", "\"Down with the feline establishment!\""),
  (
    "\"We need to recruit more dogs.\"",
    "\"Oh yeah? I'm a dog. What do you represent?\""
  ),
  ("\"Wanna join the LCS?\"", "\"Do you have a good veteranary plan?\""),
  ("\"Want me to untie you?\"", "\"Yes, please! This collar is painful!\""),
  (
    "\"You deserve better than this.\"",
    "\"Finally, a human that understands.\""
  ),
  (
    "\"Dogs are the best anything ever.\"",
    "\"Heheheh, you're funny. Okay, I won't rat you out.\""
  ),
  ("\"Conservatives kick dogs!\"", "\"That IS disturbing. What can I do?\""),
  (
    "\"All we are saying is give fleas a chance.\"",
    "\"We'll fight the fleas until our dying itch.\""
  ),
  ("\"Dogs are better than humans.\"", "\"You're pandering, but I love it.\""),
];

List<(String, String)> randomDogTalkBad = [
  ("\"Hi Mister Dog!\"", "\"Woof?\""),
  ("\"Good dog!\"", "\"Bark!\""),
  ("\"Hey there, boy.\"", "\"Woof!\""),
  ("\"Woof...?\"", "\"Woof!\""),
  ("\"Bark at the man for me!\"", "\"Bark! Grr...\""),
  ("\"Down, boy!\"", "\"Rr...?\""),
  ("\"Don't bite me!\"", "\"Grrr...!\""),
  ("\"Hi doggy!\"", "\"Bark!\""),
  ("\"Hi, puppy.\"", "\"Bark!\""),
  ("\"OH MAN I LOVE DOGS!\"", "\"Bark!\""),
  ("\"Bark! Bark!\"", "\"Your accent is atrocious.\"")
];

List<(String, String)> randomMonsterTalkGood = [
  (
    "\"I love diversity in all its forms.\"",
    "\"Your tolerance is impressive, human!\""
  ),
  (
    "\"Your kind are the future of humanity.\"",
    "\"Your recognition of our superiority is wise.\""
  ),
  (
    "\"Power to the genetic monsters!\"",
    "\"Down with the human establishment!\""
  ),
  (
    "\"We need to recruit more genetic monsters.\"",
    "\"For what purpose do you seek our aid?\""
  ),
  ("\"Wanna join the LCS?\"", "\"Maybe. Can we scare small children?\""),
  (
    "\"You're free! Join us to liberate more!\"",
    "\"Is this what compassion is?\""
  ),
  (
    "\"You deserve better than this.\"",
    "\"No beast deserves to be an experiment!\""
  ),
  (
    "\"You are the best anything ever.\"",
    "\"It's okay blokes, this one is friendly.\""
  ),
  ("\"We should flay geneticists together!\"", "\"My favorite future hobby!\""),
  (
    "\"All we are saying is give peace a chance.\"",
    "\"Will humans ever let us have peace?\""
  ),
  ("\"Monsters are better than humans.\"", "\"You're a clever one.\""),
];

List<(String, String)> randomMonsterTalkBad = [
  ("\"Stay calm!\"", "\"Die in a fire!\""),
  ("\"Good monster!\"", "\"You will die screaming!\""),
  ("\"Woah, uh... shit!\"", "\"Foolish mortal!\""),
  ("\"Don't kill me!\"", "\"Pathetic human! You're already dead!\""),
  ("\"Oh crap!\"", "\"Where is your god now, mortal?!\""),
  ("\"Uhhh... down, boy?\"", "\"You dare call me a boy? Fool!\""),
  ("\"Don't eat me!\"", "\"I will feast on your flesh!\""),
  (
    "\"Excuse me, I am, uh...\"",
    "\"ABOUT TO DIE! I AM THE DOOM OF HUMANITY.\""
  ),
  (
    "\"Shh... it's okay... I'm a friend!\"",
    "\"We will kill you AND your friends!\""
  ),
  (
    "\"OH MAN I LOVE MONSTERS!\"",
    "\"WHAT A COINCIDENCE, I WILL LOVE EATING YOU!\""
  ),
  ("\"Slurp! Boom! Raaahgh!\"", "\"Your mockery will be met with death!\""),
];
