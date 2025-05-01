import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

/// Handles the firm interrogation of a hostage by a lead interrogator
Future<void> handleFirmInterrogation(
    Creature lead, Creature cr, Map<int, double> rapport, int y) async {
  // Base forceroll on lead interrogator's psychology skill and rapport
  int forceroll =
      lead.skillRoll(Skill.psychology) + ((rapport[lead.id] ?? 0) * 5).round();
  // Reduce rapport with lead
  rapport.update(lead.id, (v) => v - 1, ifAbsent: () => -1);

  String message = "${lead.name} interrogates ${cr.name}, ${[
    "asking",
    "demanding",
    "saying",
    "pressing ${cr.gender.hisHer} by saying",
    "probing ${cr.gender.hisHer} by saying",
  ].random} \"${[
    "What do you know?",
    "Where do you work?",
    if (ccsActive) "What do you know about the CCS?",
    "Give up your secrets!",
    "Tell us what you know!",
    "We need information!",
    "What are you hiding?",
    "What's really going on?",
  ].random}\"";
  addparagraph(y, 0, message);
  y = console.y + 1;

  await getKey();

  if (!cr.attributeCheck(Attribute.wisdom, forceroll)) {
    if (cr.skillCheck(Skill.religion, forceroll)) {
      mvaddstr(
          y++,
          0,
          "${cr.name} ${[
            "prays silently...",
            "seeks strength in faith.",
            "tries to find inner peace.",
            "looks to God for guidance.",
            "whispers a prayer.",
            "asks for divine help.",
          ].random}");
    } else {
      Site? workSite = cr.workLocation is Site ? cr.workLocation as Site : null;
      if (workSite?.mapped == false) {
        addparagraph(y, 0,
            "${cr.name} reveals everything ${cr.gender.heShe} knows about the ${workSite!.name}.");
        y = console.y + 1;

        await getKey();

        workSite.mapped = true;
        workSite.hidden = false;
      } else {
        String the = cr.workLocation is Site ? "the " : "";
        addparagraph(
            y,
            0,
            "${cr.name} talks about $the${cr.workLocation.name}, though "
            "it doesn't seem like ${cr.gender.heShe} knows anything new.");
        y = console.y + 1;

        await getKey();
      }
    }
  } else {
    mvaddstr(y++, 0, "${cr.name} holds firm.");
    await getKey();
  }
}
