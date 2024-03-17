import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/talk/talk_in_combat.dart';
import 'package:lcs_new_age/talk/talk_outside_combat.dart';
import 'package:lcs_new_age/talk/talk_to_animals.dart';

Future<bool> talk(Creature liberal, Creature target) async {
  if (target.type.dog &&
      !liberal.type.animal &&
      target.align != Alignment.liberal) {
    return heyMisterAnimal(randomDogTalkGood, randomDogTalkBad, target);
  }

  if (target.type.animal &&
      !liberal.type.animal &&
      target.align != Alignment.liberal) {
    return heyMisterAnimal(randomMonsterTalkGood, randomMonsterTalkBad, target);
  }

  if ((siteAlarm || activeSiteUnderSiege) && target.isEnemy) {
    return talkInCombat(liberal, target);
  }

  return talkOutsideCombat(liberal, target);
}
