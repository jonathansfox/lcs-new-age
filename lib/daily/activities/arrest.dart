// Police accost your liberal!
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/sitemode/chase_sequence.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> attemptArrest(Creature liberal, String? s) async {
  if (s != null) {
    await showMessage("${liberal.name} is accosted by police while $s!");
  }

  // Chase sequence! Wee!
  sitestory ??= NewsStory.prepare(NewsStories.arrestGoneWrong);

  await soloChaseSequence(liberal, 5);
}

// While galavanting in public, your liberals may be ambushed by police
Future<bool> checkForArrest(Creature liberal, String s) async {
  bool arrest = false;

  if (liberal.indecent && oneIn(2)) {
    criminalize(liberal, Crime.disturbingThePeace);

    sitestory = NewsStory.prepare(NewsStories.arrestGoneWrong);

    arrest = true;
  } else if (liberal.heat > liberal.skill(Skill.streetSmarts) * 10) {
    liberal.train(Skill.streetSmarts, 5);
    if (oneIn(50)) {
      sitestory = NewsStory.prepare(NewsStories.arrestGoneWrong);
      arrest = true;
    }
  }

  if (arrest) await attemptArrest(liberal, s);

  return arrest;
}
