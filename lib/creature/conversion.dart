import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/politics/alignment.dart';

void conservatize(Creature cr) {
  if (cr.align == Alignment.liberal && cr.juice > 0) cr.juice = 0;
  cr.align = Alignment.conservative;
  if (cr.hireId == null) {
    switch (cr.type.id) {
      case CreatureTypeIds.cop:
        cr.name = "Police Officer";
      case CreatureTypeIds.unionWorker:
        cr.name = "Ex-Union Worker";
      case CreatureTypeIds.liberalJudge:
        cr.name = "Jaded Liberal Judge";
    }
  }
}

void liberalize(Creature cr) {
  if (cr.align == Alignment.conservative && cr.juice > 0) cr.juice = 0;
  cr.align = Alignment.liberal;
  if (cr.hireId == null) {
    switch (cr.type.id) {
      case CreatureTypeIds.nonUnionWorker:
        cr.name = "New Union Worker";
      case CreatureTypeIds.conservativeJudge:
        cr.name = "Enlightened Judge";
    }
  }
  interrogationSessions.removeWhere((e) => e.hostageId == cr.id);
}
