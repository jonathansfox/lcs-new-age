import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/conversion.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/loot.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/sitemode/fight.dart';
import 'package:lcs_new_age/sitemode/map_specials.dart';
import 'package:lcs_new_age/sitemode/newencounter.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> sleeperEffect(Creature cr, Map<View, int> libpower) async {
  if (disbanding) cr.activity.type = ActivityType.sleeperLiberal;
  bool infiltrate = true;

  switch (cr.activity.type) {
    case ActivityType.sleeperLiberal:
      sleeperInfluence(cr, libpower);
      cr.infiltration -= 0.02;
    case ActivityType.sleeperEmbezzle:
      await sleeperEmbezzle(cr, libpower);
      infiltrate = false;
    case ActivityType.sleeperSteal:
      await sleeperSteal(cr, libpower);
      infiltrate = false;
    case ActivityType.sleeperRecruit:
      await sleeperRecruit(cr, libpower);
    case ActivityType.sleeperSpy:
      await sleeperSpy(cr, libpower);
    default:
      break;
  }

  if (infiltrate) cr.infiltration += lcsRandom(8) * 0.01 - 0.02;

  cr.infiltration = cr.infiltration.clamp(0.0, 1.0);
}

void sleeperInfluence(Creature cr, Map<View, int> libpower) {
  int power = cr.attribute(Attribute.charisma) +
      cr.attribute(Attribute.heart) +
      cr.attribute(Attribute.intelligence) +
      cr.skill(Skill.persuasion);

  Map<View, int> transferpower = {for (var view in View.values) view: 0};

  // Profession specific skills
  switch (cr.type.id) {
    case CreatureTypeIds.artCritic:
      power += cr.skill(Skill.writing);
      power += cr.skill(Skill.art);
    case CreatureTypeIds.painter:
    case CreatureTypeIds.sculptor:
      power += cr.skill(Skill.art);
    case CreatureTypeIds.musicCritic:
      power += cr.skill(Skill.writing);
      power += cr.skill(Skill.music);
    case CreatureTypeIds.musician:
      power += cr.skill(Skill.music);
    case CreatureTypeIds.author:
    case CreatureTypeIds.journalist:
      power += cr.skill(Skill.writing);
    case CreatureTypeIds.conservativeJudge:
      power += cr.skill(Skill.writing);
      power += cr.skill(Skill.law);
    case CreatureTypeIds.lawyer:
      power += cr.skill(Skill.law);
    case CreatureTypeIds.labTech:
    case CreatureTypeIds.eminentScientist:
      power += cr.skill(Skill.science);
    case CreatureTypeIds.corporateCEO:
    case CreatureTypeIds.corporateManager:
      power += cr.skill(Skill.business);
    case CreatureTypeIds.priest:
    case CreatureTypeIds.nun:
      power += cr.skill(Skill.religion);
    case CreatureTypeIds.educator:
      power += cr.skill(Skill.psychology);
    case CreatureTypeIds.teacher:
    case CreatureTypeIds.yogaInstructor:
      power += cr.skill(Skill.teaching);
    case CreatureTypeIds.athlete:
    case CreatureTypeIds.cheerleader:
      power += cr.skill(Skill.dodge);
    default:
      break;
  }

  // Adjust power for super sleepers
  switch (cr.type.id) {
    case CreatureTypeIds.corporateCEO:
    case CreatureTypeIds.president:
    case CreatureTypeIds.eminentScientist:
      power *= 20;
    case CreatureTypeIds.deathSquad:
    case CreatureTypeIds.educator:
      power *= 6;
    case CreatureTypeIds.actor:
    case CreatureTypeIds.gangUnit:
    case CreatureTypeIds.militaryPolice:
    case CreatureTypeIds.seal:
      power *= 4;
    default:
      power *= 2;
  }

  power = (power * cr.infiltration).round();
  void addIssues(List<View> issues, int power) {
    for (View v in issues) {
      transferpower[v] = transferpower[v]! + power;
    }
  }

  switch (cr.type.id) {
    /* Radio Personalities and News Anchors subvert Conservative news stations by
         reducing their audience and twisting views on the issues. As their respective
         media establishments become marginalized, so does their influence. */
    case CreatureTypeIds.radioPersonality:
      changePublicOpinion(View.amRadio, 1);
      addIssues(
          View.issues, power * (100 - publicOpinion[View.amRadio]!) ~/ 100);
    case CreatureTypeIds.newsAnchor:
      changePublicOpinion(View.cableNews, 1);
      addIssues(
          View.issues, power * (100 - publicOpinion[View.cableNews]!) ~/ 100);
    /* Cultural leaders block - influences cultural issues */
    case CreatureTypeIds.priest:
    case CreatureTypeIds.nun:
    case CreatureTypeIds.painter:
    case CreatureTypeIds.sculptor:
    case CreatureTypeIds.author:
    case CreatureTypeIds.journalist:
    case CreatureTypeIds.psychologist:
    case CreatureTypeIds.musician:
    case CreatureTypeIds.musicCritic:
    case CreatureTypeIds.artCritic:
    case CreatureTypeIds.actor:
    case CreatureTypeIds.teacher:
    case CreatureTypeIds.fashionDesigner:
    case CreatureTypeIds.hairstylist:
      addIssues([
        View.womensRights, View.civilRights, View.lgbtRights, View.freeSpeech,
        View.drugs, View.immigration, //
      ], power);
    /* Legal block - influences an array of social issues */
    case CreatureTypeIds.conservativeJudge:
    case CreatureTypeIds.lawyer:
      addIssues([
        View.civilRights, View.deathPenalty, View.drugs, View.freeSpeech,
        View.gunControl, View.justices, View.policeBehavior, View.torture,
        View.womensRights, View.lgbtRights, View.intelligence,
        View.immigration, //
      ], power);
    /* Scientists block */
    case CreatureTypeIds.eminentScientist:
    case CreatureTypeIds.labTech:
      addIssues([
        View.animalResearch, View.genetics, View.pollution,
        View.nuclearPower, //
      ], power);
    /* Corporate block */
    case CreatureTypeIds.corporateCEO:
    case CreatureTypeIds.corporateManager:
      addIssues([
        View.ceoSalary, View.taxes, View.corporateCulture,
        View.sweatshops, View.pollution, View.civilRights, //
      ], power);
    case CreatureTypeIds.bankManager:
    case CreatureTypeIds.landlord:
      addIssues([
        View.taxes, View.civilRights, View.ceoSalary, //
      ], power);
    /* Law enforcement and prisons block */
    case CreatureTypeIds.deathSquad:
    case CreatureTypeIds.swat:
    case CreatureTypeIds.cop:
    case CreatureTypeIds.gangUnit:
    case CreatureTypeIds.educator:
    case CreatureTypeIds.prisonGuard:
    case CreatureTypeIds.prisoner:
      addIssues([
        View.policeBehavior, View.deathPenalty, View.drugs,
        View.torture, View.gunControl, View.prisons, //
      ], power);
    /* Intelligence block */
    case CreatureTypeIds.secretService:
    case CreatureTypeIds.agent:
      addIssues([
        View.intelligence, View.torture, View.prisons, View.freeSpeech, //
      ], power);
    /* Military block */
    case CreatureTypeIds.merc:
      addIssues([View.gunControl], power);
    case CreatureTypeIds.soldier:
    case CreatureTypeIds.veteran:
    case CreatureTypeIds.militaryPolice:
    case CreatureTypeIds.seal:
      addIssues([
        View.military, View.torture, View.gunControl,
        View.womensRights, View.lgbtRights, //
      ], power);
    /* Sweatshop workers */
    case CreatureTypeIds.sweatshopWorker:
      addIssues([View.sweatshops, View.immigration], power);
    /* No influence at all block - for people were liberal anyway, or have no way of doing any good */
    case CreatureTypeIds.childLaborer:
    case CreatureTypeIds.genetic:
    case CreatureTypeIds.guardDog:
    case CreatureTypeIds.bum:
    case CreatureTypeIds.crackhead:
    case CreatureTypeIds.tank:
    case CreatureTypeIds.hippie: // too liberal to be a proper sleeper
    case CreatureTypeIds.unionWorker: // same
    case CreatureTypeIds.liberalJudge: // more again
      return;
    /* Miscellaneous block -- includes everyone else */
    case CreatureTypeIds.president:
      addIssues(
          [View.issues.random, View.issues.random, View.issues.random], power);
    default: // Affect a random issue
      addIssues([View.issues.random], power);
  }

  //Transfer the liberal power adjustment to background liberal power
  for (View v in View.issues) {
    libpower[v] = libpower[v]! + transferpower[v]!;
  }
}

Future<void> sleeperSpy(Creature cr, Map<View, int> libpower) async {
  Site? homes =
      findSiteInSameCity(cr.workSite?.city, SiteType.homelessEncampment);

  if (lcsRandom(100) > 100 * cr.infiltration) {
    cr.juice -= 1;
    if (cr.juice < -2) {
      erase();
      mvaddstr(6, 1, "Sleeper ${cr.name} has been caught snooping around.");
      mvaddstr(8, 1, "The Liberal is now homeless and jobless...");
      await getKey();

      cr.squad = null;
      cr.location = homes;
      cr.base = homes;
      cr.dropWeaponAndAmmo();
      cr.activity = Activity.none();
      cr.sleeperAgent = false;
    }
    return;
  }

  // Improves juice, as confidence improves
  if (cr.juice < 100) {
    cr.juice += 10;
    if (cr.juice > 100) cr.juice = 100;
  }

  cr.workSite?.mapped = true;

  Future<void> leak(String itemType, String description) async {
    Item it = Loot(itemType);
    homes?.loot.add(it);
    erase();
    mvaddstr(6, 1, "Sleeper ${cr.name} has leaked $itemType.");
    addstr(cr.name);
    addstr(" has leaked $description.");
    mvaddstr(7, 1, "The dead drop is at the homeless camp.");
    await getKey();
  }

  bool noLeakToday(Law law) => lcsRandom(laws[law]!.index + 3) > 0;

  if (homes?.siege.underSiege != false || !canSeeThings) return;

  switch (cr.type.id) {
    case CreatureTypeIds.secretService:
    case CreatureTypeIds.agent:
    case CreatureTypeIds.president:
      // Agents can leak intelligence files to you
      if (noLeakToday(Law.privacy)) break;
      await leak("LOOT_SECRETDOCUMENTS", "secret intelligence files");
    case CreatureTypeIds.deathSquad:
    case CreatureTypeIds.swat:
    case CreatureTypeIds.cop:
    case CreatureTypeIds.gangUnit:
      // Cops can leak police files to you
      if (noLeakToday(Law.policeReform)) break;
      await leak("LOOT_POLICERECORDS", "secret police records");
    case CreatureTypeIds.corporateManager:
    case CreatureTypeIds.corporateCEO:
      // Can leak corporate files to you
      if (cr.type.id != CreatureTypeIds.corporateCEO &&
          noLeakToday(Law.corporate)) {
        break;
      }
      await leak("LOOT_CORPFILES", "secret corporate documents");
    case CreatureTypeIds.educator:
    case CreatureTypeIds.prisonGuard:
      if (noLeakToday(Law.prisons)) break;
      await leak("LOOT_PRISONFILES", "internal prison records");
    case CreatureTypeIds.newsAnchor:
      if (noLeakToday(Law.freeSpeech)) break;
      await leak("LOOT_CABLENEWSFILES", "proof of systemic Cable News bias");
    case CreatureTypeIds.radioPersonality:
      if (noLeakToday(Law.freeSpeech)) break;
      await leak("LOOT_AMRADIOFILES", "proof of systemic AM Radio bias");
    case CreatureTypeIds.labTech:
    case CreatureTypeIds.eminentScientist:
      if (noLeakToday(Law.animalRights)) break;
      await leak("LOOT_RESEARCHFILES", "internal animal research reports");
    case CreatureTypeIds.conservativeJudge:
      if (!oneIn(5)) break;
      await leak("LOOT_JUDGEFILES", "compromising files about another Judge");
    case CreatureTypeIds.ccsArchConservative:
      if (ccsExposure.index >= CCSExposure.lcsGotData.index) break;
      await leak(
          "LOOT_CCS_BACKERLIST", "a list of the CCS's government backers");
  }
}

/// *******************************
///*
///*   SLEEPERS EMBEZZLING FUNDS
///*
///********************************
Future<void> sleeperEmbezzle(Creature cr, Map<View, int> libpower) async {
  if (lcsRandom(100) > 90 * cr.infiltration) {
    cr.juice -= 1;
    if (cr.juice < -2) {
      await showMessage(
          "Sleeper ${cr.name} has been arrested while embezzling funds.");
      criminalize(cr, Crime.embezzlement);
      await captureCreature(cr);
    }
    return;
  }

  // Improves juice, as confidence improves
  if (cr.juice < 100) {
    cr.juice += 10;
    if (cr.juice > 100) cr.juice = 100;
  }

  int income;
  switch (cr.type.id) {
    case CreatureTypeIds.corporateCEO:
      income = (50000 * cr.infiltration).round();
    case CreatureTypeIds.eminentScientist:
    case CreatureTypeIds.corporateManager:
    case CreatureTypeIds.bankManager:
    case CreatureTypeIds.president:
      income = (5000 * cr.infiltration).round();
    default:
      income = (500 * cr.infiltration).round();
  }
  ledger.addFunds(income, Income.embezzlement);
}

Future<void> sleeperSteal(Creature cr, Map<View, int> libpower) async {
  Site? camp =
      findSiteInSameCity(cr.workSite?.city, SiteType.homelessEncampment);
  if (camp == null) return;

  if (lcsRandom(100) > 90 * cr.infiltration) {
    cr.juice -= 1;
    if (cr.juice < -2) {
      await showMessage(
          "Sleeper ${cr.name} has been arrested while stealing things.");
      criminalize(cr, Crime.theft);
      await captureCreature(cr);
    }
    return;
  }
  // Improves juice, as confidence improves
  if (cr.juice < 100) {
    cr.juice += 10;
    if (cr.juice > 100) cr.juice = 100;
  }

  cr.infiltration -= lcsRandom(10) * 0.01 - 0.02;

  int numberOfItems = lcsRandom(10) + 1;
  while (numberOfItems-- > 0) {
    Item? item = lootItemForSite(cr.workSite!.type);
    if (item != null) camp.loot.add(item);
  }
  erase();
  mvaddstrc(6, 1, lightGray,
      "Sleeper $numberOfItems has dropped a package off at the homeless camp.");
  await getKey();
}

Future<void> sleeperRecruit(Creature cr, Map<View, int> libpower) async {
  if (cr.workSite == null) return;
  if (cr.subordinatesLeft > 0) {
    prepareEncounter(cr.workSite!.type, false);
    for (Creature e in encounter) {
      if (e.workLocation == cr.workLocation || oneIn(5)) {
        if (e.align != Alignment.liberal && !oneIn(5)) continue;

        liberalize(e);
        e.nameCreature();
        e.hireId = cr.id;
        e.sleeperAgent = true;
        e.workSite?.mapped = true;
        e.workSite?.hidden = false;
        pool.add(e);

        erase();
        mvaddstr(
            6, 1, "Sleeper ${cr.name} has recruited a new ${e.type.name}.");
        mvaddstr(8, 1, "${e.name} looks forward serving the Liberal cause!");

        await getKey();

        if (cr.subordinatesLeft == 0) cr.activity = Activity.none();
        stats.recruits++;
        break;
      }
    }
  }
  return;
}
