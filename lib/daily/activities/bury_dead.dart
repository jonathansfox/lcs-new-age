import 'package:collection/collection.dart';
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/activities/arrest.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/sitemode/fight.dart';

Future<void> doActivityBury(List<Creature> bury) async {
  if (bury.isEmpty) return;
  List<Creature> bodies = pool.where((p) => !p.alive).toList();
  for (Creature body in bodies) {
    if (body.site == null) {
      pool.remove(body);
      continue;
    }
    Creature? burier =
        bury.firstWhereOrNull((p) => p.site?.city == body.site!.city);
    if (burier == null) continue;
    makeLoot(body, burier.site!.loot);
    pool.remove(body);
    if (burier.skillCheck(Skill.streetSmarts, Difficulty.easy)) {
      await showMessage("${burier.name} disposes of ${body.name}'s body.");
    } else {
      criminalize(burier, Crime.unlawfulBurial);
      await attemptArrest(burier, "burying ${body.name}'s body");
      bury.remove(burier); // Call it a day, even if got away
    }
    burier.train(Skill.streetSmarts, 50);
  }
  for (Creature buryer in bury) {
    buryer.activity = Activity.none();
  }
}
