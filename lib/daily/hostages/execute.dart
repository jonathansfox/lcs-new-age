import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/daily/hostages/tend_hostage.dart';
import 'package:lcs_new_age/daily/hostages/traumatize.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<int> handleExecution(InterrogationSession intr, Creature lead,
    List<Creature> tenders, int y) async {
  Creature cr = intr.hostage;
  erase();
  mvaddstrc(0, 0, white,
      "The Final Education of ${cr.name}: Day ${cr.daysSinceJoined}");
  Creature? killer;

  for (int i = 0; i < tenders.length; i++) {
    if (lcsRandom(50) < tenders[i].juice ||
        lcsRandom(9) + 1 >=
            (tenders[i].rawAttributes[Attribute.heart] ?? 0) +
                (intr.rapport[tenders[i].id] ?? 0)) {
      killer = tenders[i];
      break;
    }
  }

  if (killer != null) {
    //delete interrogation information
    setColor(purple);
    cr.die();
    stats.kills++;
    mvaddstr(y++, 0, "${lead.name} executes ${cr.name} by ");
    addstr([
      "burning photos of Ronald Reagan in front of ${cr.gender.himHer}.",
      "telling ${cr.gender.himHer} that taxes have been increased.",
      "forcing ${cr.gender.himHer} to listen to right-wing radio for 24 hours straight.",
      "showing ${cr.gender.himHer} a graph of rising global temperatures.",
      "forcing ${cr.gender.himHer} to actually read a book.",
    ].random);

    await getKey();

    y = await traumatize(lead, "execution", y);
    if (lead.activity.type == ActivityType.none) {
      selectNewLead(tenders, lead);
    }
  } else {
    setColor(brown);
    mvaddstr(y++, 0, "There is no one able to get up the nerve to ");
    mvaddstr(y++, 0, "execute ${cr.name} in cold blood.");

    await getKey();
  }

  mvaddstrc(24, 0, lightGray, "Press any key to reflect on this.");

  await getKey();

  return y;
}

void selectNewLead(List<Creature> tenders, Creature lead) {
  tenders.removeWhere((e) => e.activity.type != ActivityType.interrogation);
  if (tenders.isNotEmpty) {
    lead = tenders.random;
  }
}
