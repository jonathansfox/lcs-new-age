import 'package:lcs_new_age/common_actions/common_actions.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/activities/arrest.dart';
import 'package:lcs_new_age/daily/activities/hardliner_fight.dart';
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
    message = "Your Activists ";
  } else {
    message = "${trouble[0].name} ";
  }

  int power = 0;
  for (int t = 0; t < trouble.length; t++) {
    power +=
        trouble[t].skillRoll(Skill.art) + trouble[t].skill(Skill.streetSmarts);
    trouble[t].train(Skill.streetSmarts, 5);
  }

  int mod = 1;
  if (lcsRandom(10) < power) mod++;
  if (lcsRandom(20) < power) mod++;
  if (lcsRandom(40) < power) mod++;
  if (lcsRandom(60) < power) mod++;
  if (lcsRandom(80) < power) mod++;
  if (lcsRandom(100) < power) mod++;

  while (issue == null) {
    issue = View.issues.random;
    switch (issue) {
      case View.animalResearch:
        message += "ran around uptown splashing paint on fur coats!";
        juiceval = 2;
        crime = Crime.assault;
      case View.lgbtRights:
        message += "disrupted a traditional wedding at a church!";
        juiceval = 2;
        crime = Crime.disturbingThePeace;
      case View.womensRights:
        message += "posted horrifying dead abortion doctor pictures downtown!";
        if (noProfanity) {
          juiceval = 2;
          crime = Crime.unlawfulSpeech;
        } else {
          juiceval = 1;
        }
      case View.policeBehavior:
        message += "went downtown and reenacted a police beating!";
        juiceval = 2;
        crime = Crime.disturbingThePeace;
      case View.nuclearPower:
        message +=
            "dressed up and pretended to be ${trouble.length > 1 ? "" : "a "}"
            "radioactive mutant${trouble.length > 1 ? "s" : ""}!";
        juiceval = 1;
      case View.pollution:
        message += "squirted business people with fake polluted water!";
        juiceval = 2;
        crime = Crime.assault;
      case View.deathPenalty:
        if (laws[Law.deathPenalty] == DeepAlignment.eliteLiberal) continue;
        message += "distributed fliers graphically illustrating executions!";
        if (noProfanity) {
          juiceval = 2;
          crime = Crime.unlawfulSpeech;
        } else {
          juiceval = 1;
        }
      case View.torture:
        if (laws[Law.torture] == DeepAlignment.eliteLiberal) continue;
        message += "distributed fliers graphically illustrating CIA torture!";
        if (noProfanity) {
          juiceval = 2;
          crime = Crime.unlawfulSpeech;
        } else {
          juiceval = 1;
        }
      case View.corporateCulture:
        message += "burned a corporate symbol and denounced capitalism!";
        if (corporateFeudalism) {
          juiceval = 2;
          crime = Crime.flagBurning;
        } else {
          juiceval = 1;
        }
      case View.sweatshops:
        message += "set up a mock sweatshop in the mall!";
        juiceval += 1;
      case View.taxes:
        message += "organized a pro-tax flash mob in a ritzy area!";
        juiceval = 2;
        crime = Crime.disturbingThePeace;
      case View.intelligence:
        message += "staged a performance of George Orwell's 1984!";
        juiceval = 1;
      case View.freeSpeech:
        message += "held an anti-censorship street performance!";
        if (noProfanity) {
          juiceval = 2;
          crime = Crime.unlawfulSpeech;
        } else {
          juiceval = 1;
        }
      case View.genetics:
        message += "created a protest camp outside a biotech firm!";
        if (noProfanity) {
          juiceval = 2;
          crime = Crime.unlawfulSpeech;
        } else {
          juiceval = 1;
        }
      case View.justices:
        message += "staged a sit-in at the courthouse!";
        if (noProfanity) {
          juiceval = 2;
          crime = Crime.unlawfulSpeech;
        } else {
          juiceval = 2;
          crime = Crime.disturbingThePeace;
        }
      case View.gunControl:
        message += "organized a die-in at city hall to protest gun violence!";
        if (noProfanity) {
          juiceval = 2;
          crime = Crime.unlawfulSpeech;
        } else {
          juiceval = 2;
          crime = Crime.disturbingThePeace;
        }
      case View.ceoSalary:
        message += "marched downtown to protest wealth inqueality!";
        if (noProfanity) {
          juiceval = 2;
          crime = Crime.unlawfulSpeech;
        } else {
          juiceval = 1;
        }
      case View.civilRights:
        message += "marched downtown chanting Black Lives Matter!";
        if (noProfanity) {
          juiceval = 2;
          crime = Crime.unlawfulSpeech;
        } else {
          juiceval = 1;
        }
      case View.drugs:
        message += "handed out free samples of marijuana!";
        juiceval = 2;
        crime = Crime.drugDistribution;
      case View.immigration:
        message += "distributed fliers declaring that no one is illegal!";
        if (noProfanity) {
          juiceval = 2;
          crime = Crime.unlawfulSpeech;
        } else {
          juiceval = 1;
        }
      case View.military:
        message += "organized an anti-war protest!";
        if (noProfanity) {
          juiceval = 2;
          crime = Crime.unlawfulSpeech;
        } else {
          juiceval = 1;
        }
      case View.prisons:
        message += "staged a prison abolition protest!";
        if (noProfanity) {
          juiceval = 2;
          crime = Crime.unlawfulSpeech;
        } else {
          juiceval = 1;
        }
      case View.amRadio:
        message += "burned an effigy of a right-wing radio host!";
        if (noProfanity) {
          juiceval = 2;
          crime = Crime.unlawfulSpeech;
        } else {
          juiceval = 1;
        }
      case View.cableNews:
        message += "burned an effigy of a right-wing news anchor!";
        if (noProfanity) {
          juiceval = 2;
          crime = Crime.unlawfulSpeech;
        } else {
          juiceval = 1;
        }
      default:
        message += "protested against the game being buggy!";
        if (noProfanity) {
          // How DARE you protest against the game being buggy!
          juiceval = 2;
          crime = Crime.unlawfulSpeech;
        } else {
          juiceval = 1;
        }
    }
  }

  politics.changePublicOpinion(View.lcsKnown, mod ~/ 2, noPublicInterest: true);
  politics.changePublicOpinion(View.lcsLiked, mod ~/ 4, noPublicInterest: true);
  politics.addBackgroundInfluence(issue, mod);

  if (!disbanding) {
    await showMessage(message);
    message = "";

    if (crime != null) {
      for (int t = 0; t < trouble.length; t++) {
        if (oneIn(30) &&
            !trouble[t].skillCheck(Skill.streetSmarts, Difficulty.average)) {
          if (oneIn(4)) {
            criminalize(trouble[t], crime);
            sitestory = NewsStory.prepare(NewsStories.arrestGoneWrong);
            await attemptArrest(trouble[t], "causing trouble");
          } else {
            await hardlinerFight(trouble[t]);
          }
        }
      }
    }
  }

  for (int h = 0; h < trouble.length; h++) {
    addjuice(trouble[h], juiceval, 50);
  }
}
