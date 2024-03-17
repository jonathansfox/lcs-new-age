import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

void doActivityWriteGuardian(List<Creature> people) {
  for (Creature p in people) {
    politics.backgroundInfluence.update(
        View.issues.random, (value) => value + p.skillRoll(Skill.writing));
    p.train(Skill.writing, 5);
  }
}

void doActivityStreamGuardian(List<Creature> people) {
  for (Creature p in people) {
    politics.backgroundInfluence.update(View.issues.random,
        (value) => value + 4 * p.skillRoll(Skill.persuasion));
    p.train(Skill.persuasion, 5);
  }
}
