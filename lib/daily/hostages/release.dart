import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/conversion.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/hostages/tend_hostage.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/clothing.dart';
import 'package:lcs_new_age/items/clothing_type.dart';
import 'package:lcs_new_age/location/siege.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> handleRelease(
    InterrogationSession intr, Creature lead, int y) async {
  Creature cr = intr.hostage;
  erase();
  mvaddstrc(
      0, 0, white, "The Release of ${cr.name}: Day ${cr.daysSinceJoined}");
  y = 2;
  setColor(lightGray);

  if (cr.site?.siege.underSiege == true) {
    String typeOfSiegers = switch (cr.site?.siege.activeSiegeType) {
      SiegeType.police => switch (cr.site?.siege.escalationState) {
          SiegeEscalation.police => "police",
          _ => "soldiers",
        },
      SiegeType.cia => "CIA agents",
      SiegeType.angryRuralMob => "people outside",
      SiegeType.corporateMercs => "corporate mercenaries",
      SiegeType.ccs => "CCS vigilantes",
      _ => "giant bugs",
    };
    addparagraph(
        y,
        0,
        "${lead.name} leads ${cr.name} to the front door and lets "
        "${cr.gender.himHer} run into the arms of the waiting $typeOfSiegers. "
        "There is a brief commotion as ${cr.name} is led to safety, but "
        "aside from that, there's no change in the situation.");
    await getKey();
    return;
  }

  // Calculate recruitment chance similar to recruitment attempt, with an
  // additional -50% penalty since you're actually letting them go and they
  // can easily just go back to their old life
  int successChance = -50;
  successChance += lead.skill(Skill.psychology) * 5;
  successChance += ((intr.rapport[lead.id] ?? 0) * 10).round();
  successChance -= cr.attribute(Attribute.wisdom) * 30;
  successChance -= cr.juice * 2;

  String reaction;
  if (successChance >= 100) {
    reaction = [
      "looks at ${lead.name} for a long time, and actually seems sad to go.",
      "seems to have been profoundly changed by the experience.",
      "appears to have found a new purpose in life.",
      "looks like ${cr.gender.heShe} has made an important decision.",
      "exchanges a meaningful look with ${lead.name}.",
      "tells ${lead.name} that ${cr.gender.heShe} will be in touch.",
      "appears to be thinking deeply about the future.",
      "looks like ${cr.gender.heShe} has found something ${cr.gender.heShe} was missing.",
    ].random;
  } else if (successChance < 0) {
    reaction = [
      "glances back at ${lead.name} with barely concealed contempt.",
      "seems eager to get away as quickly as possible.",
      "breaks out into a dead run as soon as ${lead.name} lets ${cr.gender.himHer} go.",
      "can't wait to get back to ${cr.gender.hisHer} old life.",
      "can barely believe ${lead.name} is actually letting ${cr.gender.himHer} go.",
      "hesitates only to make sure it isn't a trick, then bolts.",
      "looks ready to put this nonsense behind ${cr.gender.himHer}.",
    ].random;
  } else if (successChance < 25) {
    reaction = [
      "looks around cautiously, unsure what to make of this.",
      "seems confused by the sudden change in circumstances.",
      "appears to be processing what just happened.",
      "looks like ${cr.gender.heShe} is trying to figure out what to do next.",
      "runs off without a word.",
      "glances back at ${lead.name} and looks a bit confused.",
      "looks like ${cr.gender.heShe} is trying to make sense of everything.",
    ].random;
  } else {
    reaction = [
      "looks at ${lead.name} with a mix of emotions.",
      "seems to have been affected by the experience.",
      "appears to be thinking about what ${cr.gender.heShe} has learned.",
      "looks like ${cr.gender.heShe} might have changed ${cr.gender.hisHer} mind about some things.",
      "seems to be considering new possibilities.",
      "appears to be reflecting on what ${cr.gender.heShe} has been through.",
      "looks like ${cr.gender.heShe} has gained some perspective.",
    ].random;
  }

  addparagraph(
      y,
      0,
      "${lead.name} takes ${cr.name} to a secure location and releases "
      "${cr.gender.himHer} from captivity. ${cr.name} $reaction");
  y = console.y + 1;

  await getKey();

  // If the hostage is liberal (heart > wisdom) and has rapport with the lead,
  // they might become a sleeper agent
  if (lcsRandom(100) < successChance) {
    addparagraph(
        y,
        0,
        "${cr.name} gets in touch with ${lead.name} later, expressing "
        "a desire to continue their conversations and offering "
        "${cr.gender.hisHer} services as a sleeper agent for the "
        "Liberal Crime Squad.");
    cr.hireId = lead.id;
    cr.brainwashed = true;
    cr.base = cr.workLocation is Site ? cr.workLocation as Site : null;
    cr.location = cr.workLocation;
    cr.missing = false;
    cr.kidnapped = false;
    cr.sleeperAgent = true;
    liberalize(cr);
    stats.recruits++;
    await getKey();
  } else {
    // Otherwise they'll be released
    pool.remove(cr);
    cr.location = cr.workLocation;
    // Make sure they recognize the LCS if they see them again
    cr.formerHostage = true;
    // Give them appropriate clothing and weapon in case they lost them
    ClothingType? armorType = cr.type.randomArmor;
    if (armorType != null && armorType.idName != "CLOTHING_NONE") {
      cr.equippedClothing = Clothing(armorType.idName);
    }
    cr.type.randomWeaponFor(cr);
    // Clear their kidnapping flags
    cr.missing = false;
    cr.kidnapped = false;
  }
}
