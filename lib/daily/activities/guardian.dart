import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

void doActivityWriteGuardian(List<Creature> people) {
  for (Creature p in people) {
    politics.addBackgroundInfluence(
        View.issues.random,
        p.skillRoll(Skill.writing) +
            p.skill(Skill.law) +
            p.skill(Skill.science) +
            p.skill(Skill.religion) +
            p.skill(Skill.business) -
            5);
    p.train(Skill.writing, 5);
  }
}

void doActivityStreamGuardian(List<Creature> people) {
  for (Creature p in people) {
    politics.addBackgroundInfluence(
        View.issues.random,
        4 *
            (p.skillRoll(Skill.persuasion) +
                p.skill(Skill.law) +
                p.skill(Skill.science) +
                p.skill(Skill.religion) +
                p.skill(Skill.business) -
                5));
    p.train(Skill.persuasion, 5);
  }
}
