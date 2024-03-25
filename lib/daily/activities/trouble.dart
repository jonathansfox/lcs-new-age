import 'package:lcs_new_age/common_actions/common_actions.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/activities/arrest.dart';
import 'package:lcs_new_age/daily/activities/redneck_fight.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> doActivityTrouble(List<Creature> trouble) async {
  if (trouble.isEmpty) return;

  int juiceval = 0;
  Crime? crime;
  View? issue;

  String message;
  if (trouble.length > 1) {
    message = "Your Activists have ";
  } else {
    message = "${trouble[0].name} has ";
  }

  int power = 0;
  for (int t = 0; t < trouble.length; t++) {
    power += trouble[t].skillRoll(Skill.art) +
        trouble[t].skillRoll(Skill.streetSmarts);
  }

  int mod = 1;
  if (lcsRandom(10) < power) mod++;
  if (lcsRandom(20) < power) mod++;
  if (lcsRandom(40) < power) mod++;
  if (lcsRandom(60) < power) mod++;
  if (lcsRandom(80) < power) mod++;
  if (lcsRandom(100) < power) mod++;

  while (issue == null) {
    switch (lcsRandom(10)) {
      case 0:
        message += "run around uptown splashing paint on fur coats!";
        juiceval = 2;
        crime = Crime.assault;
        issue = View.animalResearch;
      case 1:
        message += "disrupted a traditional wedding at a church!";
        juiceval = 2;
        crime = Crime.disturbingThePeace;
        issue = View.lgbtRights;
      case 2:
        message += "posted horrifying dead abortion doctor pictures downtown!";
        issue = View.womensRights;
        if (noProfanity) {
          juiceval = 2;
          crime = Crime.unlawfulSpeech;
        } else {
          juiceval = 1;
        }
      case 3:
        message += "gone downtown and reenacted a police beating!";
        issue = View.policeBehavior;
        juiceval = 2;
        crime = Crime.disturbingThePeace;
      case 4:
        message +=
            "dressed up and pretended to be radioactive mutant${trouble.length > 1 ? "s" : ""}!";
        issue = View.nuclearPower;
        juiceval = 1;
      case 5:
        message += "squirted business people with fake polluted water!";
        issue = View.pollution;
        juiceval = 2;
        crime = Crime.assault;
      case 6:
        if (laws[Law.deathPenalty] == DeepAlignment.eliteLiberal) continue;
        message += "distributed fliers graphically illustrating executions!";
        issue = View.deathPenalty;
        if (noProfanity) {
          juiceval = 2;
          crime = Crime.unlawfulSpeech;
        } else {
          juiceval = 1;
        }
      case 7:
        if (laws[Law.torture] == DeepAlignment.eliteLiberal) continue;
        message += "distributed fliers graphically illustrating CIA torture!";
        issue = View.torture;
        if (noProfanity) {
          juiceval = 2;
          crime = Crime.unlawfulSpeech;
        } else {
          juiceval = 1;
        }
      case 8:
        message += "burned a corporate symbol and denounced capitalism!";
        issue = View.corporateCulture;
        if (corporateFeudalism) {
          juiceval = 2;
          crime = Crime.flagBurning;
        } else {
          juiceval = 1;
        }
      case 9:
        message += "set up a mock sweatshop in the middle of the mall!";
        issue = View.sweatshops;
        juiceval += 1;
    }
  }

  changePublicOpinion(View.lcsKnown, mod);
  changePublicOpinion(View.lcsLiked, mod ~/ 2);
  politics.publicInterest.update(issue, (v) => v + mod);
  politics.backgroundInfluence.update(issue, (v) => v + mod);

  await showMessage(message);
  message = "";

  if (crime != null) {
    for (int t = 0; t < trouble.length; t++) {
      if (oneIn(30) &&
          !trouble[t].skillCheck(Skill.streetSmarts, Difficulty.average)) {
        if (oneIn(4)) {
          sitestory = NewsStory.prepare(NewsStories.arrestGoneWrong);
          await attemptArrest(trouble[t], "causing trouble");
        } else {
          await redneckFight(trouble[t]);
        }
      }
    }

    for (int h = 0; h < trouble.length; h++) {
      addjuice(trouble[h], juiceval, 50);
    }
  }
}
