import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_actions/common_actions.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/body.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> hardlinerFight(Creature cr) async {
  await showMessage(
      "${cr.name} is cornered by a gang of right-wing hardliners.");

  bool wonfight = false;
  if (cr.weapon.type.threatening) {
    await showMessage("${cr.name} brandishes the ${cr.weapon.getName()}!");
    await showMessage("The mob scatters!");
    addjuice(cr, 5, 50);
    wonfight = true;
  } else {
    for (int count = 0; count <= lcsRandom(5) + 2; count++) {
      if (cr.skillRoll(Skill.martialArts) > Difficulty.average + count) {
        await showMessage(
            "${cr.name} ${[
              "breaks the arm of the nearest person!",
              "knees a guy in the balls!",
              "knocks one out with a fist to the face!",
              "bites some asshole's ear off!",
              "smashes one of them in the jaw!",
              "shakes off a grab from behind!",
              "yells the slogan!",
              "knocks two of their heads together!",
            ].random}",
            color: lightBlue);
        wonfight = true;
      } else {
        await showMessage(
            "${cr.name} ${[
              "is held down and kicked by three guys!",
              "gets pummeled!",
              "gets hit by a sharp rock!",
              "is thrown against the sidewalk!",
              "is bashed in the face with a shovel!",
              "is forced into a headlock!",
              "crumples under a flurry of blows!",
              "is hit in the chest with a pipe!",
            ].random}",
            color: yellow);
        count++; // fight goes faster when you're losing
        wonfight = false;
      }
    }

    if (wonfight) {
      await showMessage(
          "${cr.name} beat the ${noProfanity ? "[tar]" : "shit"} out of everyone who got close!",
          color: lightGreen);
      addjuice(cr, 30, 300);
      if (cr.blood > cr.maxBlood * 0.7) cr.blood = (cr.maxBlood * 0.7).round();
    }
  }

  if (!wonfight) {
    await showMessage(
        "${cr.name} is severely beaten before the mob is broken up.",
        color: red);
    cr.activity = Activity(ActivityType.clinic);

    addjuice(cr, -10, 0);
    if (cr.blood > 10) cr.blood = 10;

    if (oneIn(5) && cr.body is HumanoidBody) {
      HumanoidBody body = cr.body as HumanoidBody;
      switch (lcsRandom(10)) {
        case 0:
          if (body.lowerSpine == InjuryState.healthy) {
            await showMessage("${cr.name}'s lower spine has been broken!");
            body.lowerSpine = InjuryState.untreated;
          }
        case 1:
          if (body.upperSpine == InjuryState.healthy) {
            await showMessage("${cr.name}'s upper spine has been broken!");
            body.upperSpine = InjuryState.untreated;
          }
        case 2:
          if (body.neck == InjuryState.healthy) {
            await showMessage("${cr.name}'s neck has been broken!");
            body.neck = InjuryState.untreated;
          }
        case 3:
          if (body.teeth > 0) {
            if (body.teeth > 1) {
              await showMessage(
                  "${cr.name}'s teeth have been smashed out on the curb!");
            } else {
              await showMessage(
                  "${cr.name}'s tooth has been pulled out with pliers!");
            }
            body.teeth = 0;
          }
        default:
          if (body.ribs > 0) {
            if (body.ribs > 1) {
              await showMessage("One of ${cr.name}'s ribs is broken!");
            } else {
              await showMessage("${cr.name}'s last unbroken rib is broken!");
            }
            body.ribs -= 1;
          }
      }
    }
  }
}
