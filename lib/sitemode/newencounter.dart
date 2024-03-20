/* generates a new siege encounter */
import 'dart:math';

import 'package:lcs_new_age/creature/conversion.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/siege.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

extension AddToMap on Map<String, int> {
  void add(String key, int value) {
    this[key] = (this[key] ?? 0) + value;
  }
}

/* generates a new random encounter */
void prepareEncounter(SiteType type, bool sec, {bool addToExisting = false}) {
  if (!addToExisting) encounter.clear();

  Map<String, int> weights = {};

  if (postAlarmTimer > 80) {
    switch (type) {
      case SiteType.armyBase:
        weights.add(CreatureTypeIds.soldier, 1000);
        weights.add(CreatureTypeIds.militaryPolice, 300);
        weights.add(CreatureTypeIds.seal, 150);
        weights.add(CreatureTypeIds.guardDog, 100);
        weights.add(CreatureTypeIds.tank, 100);
      case SiteType.whiteHouse:
        weights.add(CreatureTypeIds.secretService, 1000);
      case SiteType.intelligenceHQ:
        weights.add(CreatureTypeIds.agent, 1000);
        weights.add(CreatureTypeIds.guardDog, 50);
      case SiteType.corporateHQ:
      case SiteType.ceoHouse:
        weights.add(CreatureTypeIds.merc, 1000);
      case SiteType.amRadioStation:
      case SiteType.cableNewsStation:
        weights.add(CreatureTypeIds.hick, 1000);
      case SiteType.policeStation:
        if (deathSquadsActive) {
          weights.add(CreatureTypeIds.deathSquad, 1000);
        } else {
          weights.add(CreatureTypeIds.swat, 1000);
        }
      default:
        break;
    }
    if (siteOnFire && !noProfanity) {
      weights.add(CreatureTypeIds.firefighter, 1000);
    }
  }

  if (activeSite?.controller == SiteController.ccs &&
      (type != SiteType.barAndGrill || sec)) {
    weights.add(CreatureTypeIds.ccsVigilante, 50);
    weights.add(CreatureTypeIds.ccsArchConservative, 2);
    weights.add(CreatureTypeIds.sexWorker, 5);
    weights.add(CreatureTypeIds.crackhead, 5);
    weights.add(CreatureTypeIds.priest, 5);
    weights.add(CreatureTypeIds.radioPersonality, 1);

    for (int n = 0; n < lcsRandom(6) + 1; n++) {
      Creature cr =
          Creature.fromId(creatureTypes[lcsRandomWeighted(weights)]!.id);
      conservatize(cr);
      encounter.add(cr);
    }
  } else {
    int encnum = 6;
    switch (type) {
      case SiteType.drugHouse:
        weights.add(CreatureTypeIds.teenager, 100);
        weights.add(CreatureTypeIds.musician, 1);
        weights.add(CreatureTypeIds.mathematician, 1);
        weights.add(CreatureTypeIds.highschoolDropout, 30);
        weights.add(CreatureTypeIds.bum, 200);
        if (mutantsPossible) weights.add(CreatureTypeIds.mutant, 2);
        if (mutantsCommon) weights.add(CreatureTypeIds.mutant, 50);
        weights.add(CreatureTypeIds.gangMember, 200);
        weights.add(CreatureTypeIds.crackhead, 200);
        weights.add(CreatureTypeIds.sexWorker, 200);
        weights.add(CreatureTypeIds.biker, 5);
        weights.add(CreatureTypeIds.painter, 1);
        weights.add(CreatureTypeIds.sculptor, 1);
        weights.add(CreatureTypeIds.thief, 3);
        weights.add(CreatureTypeIds.actor, 1);
        weights.add(CreatureTypeIds.journalist, 2);
        if (ccsState.index < CCSStrength.defeated.index &&
            ccsState.index > CCSStrength.inHiding.index) {
          weights.add(CreatureTypeIds.ccsVigilante, 5);
        }
      case SiteType.juiceBar:
        weights.add(CreatureTypeIds.teenager, 10);
        weights.add(CreatureTypeIds.liberalJudge, 1);
        weights.add(CreatureTypeIds.collegeStudent, 10);
        weights.add(CreatureTypeIds.musician, 2);
        weights.add(CreatureTypeIds.mathematician, 1);
        weights.add(CreatureTypeIds.teacher, 1);
        weights.add(CreatureTypeIds.highschoolDropout, 1);
        weights.add(CreatureTypeIds.engineer, 1);
        weights.add(CreatureTypeIds.fastFoodWorker, 1);
        weights.add(CreatureTypeIds.baker, 1);
        weights.add(CreatureTypeIds.barista, 1);
        weights.add(CreatureTypeIds.bartender, 1);
        weights.add(CreatureTypeIds.telemarketer, 1);
        weights.add(CreatureTypeIds.carSalesman, 1);
        weights.add(CreatureTypeIds.officeWorker, 1);
        weights.add(CreatureTypeIds.mailman, 1);
        weights.add(CreatureTypeIds.chef, 1);
        weights.add(CreatureTypeIds.nurse, 1);
        weights.add(CreatureTypeIds.amateurMagician, 1);
        weights.add(CreatureTypeIds.hippie, 6);
        weights.add(CreatureTypeIds.artCritic, 1);
        weights.add(CreatureTypeIds.musicCritic, 1);
        weights.add(CreatureTypeIds.author, 1);
        weights.add(CreatureTypeIds.journalist, 1);
        weights.add(CreatureTypeIds.socialite, 2);
        weights.add(CreatureTypeIds.programmer, 1);
        weights.add(CreatureTypeIds.retiree, 1);
        weights.add(CreatureTypeIds.painter, 1);
        weights.add(CreatureTypeIds.sculptor, 1);
        weights.add(CreatureTypeIds.dancer, 1);
        weights.add(CreatureTypeIds.photographer, 1);
        weights.add(CreatureTypeIds.cameraman, 1);
        weights.add(CreatureTypeIds.hairstylist, 1);
        weights.add(CreatureTypeIds.fashionDesigner, 1);
        weights.add(CreatureTypeIds.clerk, 1);
        weights.add(CreatureTypeIds.thief, 1);
        weights.add(CreatureTypeIds.actor, 1);
        weights.add(CreatureTypeIds.yogaInstructor, 1);
        weights.add(CreatureTypeIds.martialArtist, 1);
        weights.add(CreatureTypeIds.athlete, 2);
        weights.add(CreatureTypeIds.locksmith, 1);
      case SiteType.barAndGrill:
        if (sec || siteAlarm) {
          weights.add(CreatureTypeIds.bouncer, 100);
        } else {
          weights.add(CreatureTypeIds.bouncer, 10);
        }
        if (sec) weights.add(CreatureTypeIds.guardDog, 25);
        weights.add(CreatureTypeIds.eminentScientist, 1);
        weights.add(CreatureTypeIds.corporateManager, 30);
        weights.add(CreatureTypeIds.cop, 5);
        if (deathSquadsActive) weights.add(CreatureTypeIds.deathSquad, 2);
        if (gangUnitsActive) weights.add(CreatureTypeIds.gangUnit, 2);
        weights.add(CreatureTypeIds.conservativeJudge, 1);
        weights.add(CreatureTypeIds.radioPersonality, 1);
        weights.add(CreatureTypeIds.newsAnchor, 1);
        weights.add(CreatureTypeIds.lawyer, 15);
        weights.add(CreatureTypeIds.doctor, 10);
        weights.add(CreatureTypeIds.psychologist, 1);
        weights.add(CreatureTypeIds.musician, 1);
        weights.add(CreatureTypeIds.engineer, 10);
        weights.add(CreatureTypeIds.bartender, 10);
        weights.add(CreatureTypeIds.footballCoach, 1);
        weights.add(CreatureTypeIds.artCritic, 1);
        weights.add(CreatureTypeIds.musicCritic, 1);
        weights.add(CreatureTypeIds.author, 1);
        weights.add(CreatureTypeIds.journalist, 1);
        weights.add(CreatureTypeIds.socialite, 2);
        weights.add(CreatureTypeIds.retiree, 1);
        weights.add(CreatureTypeIds.painter, 1);
        weights.add(CreatureTypeIds.sculptor, 1);
        weights.add(CreatureTypeIds.dancer, 1);
        weights.add(CreatureTypeIds.photographer, 1);
        weights.add(CreatureTypeIds.fashionDesigner, 1);
        weights.add(CreatureTypeIds.thief, 1);
        weights.add(CreatureTypeIds.actor, 1);
        weights.add(CreatureTypeIds.athlete, 1);
        weights.add(CreatureTypeIds.firefighter, 1);
        weights.add(CreatureTypeIds.locksmith, 1);
        if (ccsActive) weights.add(CreatureTypeIds.ccsVigilante, 5);
      case SiteType.whiteHouse:
        weights.add(CreatureTypeIds.eminentScientist, 1);
        weights.add(CreatureTypeIds.janitor, 2);
        weights.add(CreatureTypeIds.secretary, 2);
        weights.add(CreatureTypeIds.teenager, 1);
        weights.add(CreatureTypeIds.liberalJudge, 1);
        weights.add(CreatureTypeIds.conservativeJudge, 1);
        weights.add(CreatureTypeIds.agent, 2);
        weights.add(CreatureTypeIds.secretService, sec ? 100 : 5);
        weights.add(CreatureTypeIds.lawyer, 3);
        weights.add(CreatureTypeIds.doctor, 1);
        weights.add(CreatureTypeIds.collegeStudent, 1);
        weights.add(CreatureTypeIds.teacher, 1);
        weights.add(CreatureTypeIds.officeWorker, 5);
        weights.add(CreatureTypeIds.footballCoach, 1);
        weights.add(CreatureTypeIds.chef, 1);
        weights.add(CreatureTypeIds.veteran, 1);
        weights.add(CreatureTypeIds.journalist, 2);
        weights.add(CreatureTypeIds.socialite, 1);
        weights.add(CreatureTypeIds.photographer, 2);
        weights.add(CreatureTypeIds.cameraman, 1);
        weights.add(CreatureTypeIds.hairstylist, 1);
        weights.add(CreatureTypeIds.clerk, 5);
        weights.add(CreatureTypeIds.actor, 1);
        weights.add(CreatureTypeIds.athlete, 1);
      case SiteType.publicPark:
      case SiteType.latteStand:
        weights.add(CreatureTypeIds.securityGuard, 5);
        weights.add(CreatureTypeIds.labTech, 10);
        weights.add(CreatureTypeIds.eminentScientist, 1);
        weights.add(CreatureTypeIds.corporateManager, 10);
        weights.add(CreatureTypeIds.janitor, 5);
        if (nonUnionWorkers) {
          weights.add(CreatureTypeIds.nonUnionWorker, 5);
        }
        weights.add(CreatureTypeIds.secretary, 15);
        if (unionWorkers) weights.add(CreatureTypeIds.unionWorker, 5);
        weights.add(CreatureTypeIds.teenager, 5);
        weights.add(CreatureTypeIds.cop, 5);
        if (deathSquadsActive) weights.add(CreatureTypeIds.deathSquad, 2);
        if (gangUnitsActive) weights.add(CreatureTypeIds.gangUnit, 2);
        weights.add(CreatureTypeIds.liberalJudge, 1);
        weights.add(CreatureTypeIds.conservativeJudge, 1);
        weights.add(CreatureTypeIds.agent, 1);
        if (ccsActive) weights[CreatureTypeIds.ccsVigilante] = 4;
        weights.add(CreatureTypeIds.radioPersonality, 1);
        weights.add(CreatureTypeIds.newsAnchor, 1);
        weights.add(CreatureTypeIds.lawyer, 5);
        weights.add(CreatureTypeIds.doctor, 5);
        weights.add(CreatureTypeIds.psychologist, 1);
        weights.add(CreatureTypeIds.nurse, 5);
        weights.add(CreatureTypeIds.sewerWorker, 1);
        weights.add(CreatureTypeIds.collegeStudent, 30);
        weights.add(CreatureTypeIds.musician, 5);
        weights.add(CreatureTypeIds.mathematician, 5);
        weights.add(CreatureTypeIds.teacher, 5);
        weights.add(CreatureTypeIds.highschoolDropout, 1);
        weights.add(CreatureTypeIds.bum, 1);
        if (mutantsPossible) weights.add(CreatureTypeIds.mutant, 1);
        if (mutantsCommon) weights.add(CreatureTypeIds.mutant, 2);
        weights[CreatureTypeIds.gangMember] = 5;
        weights.add(CreatureTypeIds.crackhead, 1);
        weights.add(CreatureTypeIds.priest, 1);
        weights.add(CreatureTypeIds.engineer, 5);
        weights.add(CreatureTypeIds.fastFoodWorker, 5);
        weights.add(CreatureTypeIds.baker, 1);
        weights.add(CreatureTypeIds.barista, 10);
        weights.add(CreatureTypeIds.bartender, 1);
        weights.add(CreatureTypeIds.telemarketer, 5);
        weights.add(CreatureTypeIds.carSalesman, 3);
        weights.add(CreatureTypeIds.officeWorker, 10);
        weights.add(CreatureTypeIds.footballCoach, 1);
        weights.add(CreatureTypeIds.sexWorker, 1);
        weights.add(CreatureTypeIds.mailman, 1);
        weights.add(CreatureTypeIds.garbageman, 1);
        weights.add(CreatureTypeIds.plumber, 1);
        weights.add(CreatureTypeIds.chef, 1);
        weights.add(CreatureTypeIds.constructionWorker, 3);
        weights.add(CreatureTypeIds.amateurMagician, 1);
        weights.add(CreatureTypeIds.merc, 1);
        weights.add(CreatureTypeIds.soldier, 1);
        weights.add(CreatureTypeIds.veteran, 3);
        if (nineteenEightyFour) {
          weights.add(CreatureTypeIds.educator, 1);
        } else {
          weights.add(CreatureTypeIds.prisonGuard, 1);
        }
        weights.add(CreatureTypeIds.hippie, 1);
        weights.add(CreatureTypeIds.artCritic, 1);
        weights.add(CreatureTypeIds.musicCritic, 1);
        weights.add(CreatureTypeIds.author, 1);
        weights.add(CreatureTypeIds.journalist, 1);
        weights.add(CreatureTypeIds.socialite, 1);
        weights.add(CreatureTypeIds.biker, 1);
        weights.add(CreatureTypeIds.trucker, 1);
        weights.add(CreatureTypeIds.taxiDriver, 1);
        weights.add(CreatureTypeIds.programmer, 5);
        weights.add(CreatureTypeIds.retiree, 3);
        weights.add(CreatureTypeIds.painter, 1);
        weights.add(CreatureTypeIds.sculptor, 1);
        weights.add(CreatureTypeIds.dancer, 1);
        weights.add(CreatureTypeIds.photographer, 1);
        weights.add(CreatureTypeIds.cameraman, 1);
        weights.add(CreatureTypeIds.hairstylist, 1);
        weights.add(CreatureTypeIds.fashionDesigner, 1);
        weights.add(CreatureTypeIds.clerk, 1);
        weights.add(CreatureTypeIds.thief, 1);
        weights.add(CreatureTypeIds.actor, 1);
        weights.add(CreatureTypeIds.yogaInstructor, 1);
        weights.add(CreatureTypeIds.martialArtist, 1);
        weights.add(CreatureTypeIds.athlete, 1);
        weights.add(CreatureTypeIds.firefighter, 1);
        weights.add(CreatureTypeIds.locksmith, 1);
      case SiteType.veganCoOp:
        weights.add(CreatureTypeIds.teenager, 5);
        weights.add(CreatureTypeIds.liberalJudge, 1);
        weights.add(CreatureTypeIds.collegeStudent, 50);
        weights.add(CreatureTypeIds.musician, 20);
        weights.add(CreatureTypeIds.mathematician, 1);
        weights.add(CreatureTypeIds.teacher, 1);
        weights.add(CreatureTypeIds.highschoolDropout, 10);
        weights.add(CreatureTypeIds.bum, 1);
        if (mutantsPossible) weights.add(CreatureTypeIds.mutant, 1);
        if (mutantsCommon) weights.add(CreatureTypeIds.mutant, 10);
        weights.add(CreatureTypeIds.hippie, 50);
        weights.add(CreatureTypeIds.artCritic, 1);
        weights.add(CreatureTypeIds.musicCritic, 1);
        weights.add(CreatureTypeIds.author, 1);
        weights.add(CreatureTypeIds.journalist, 1);
        weights.add(CreatureTypeIds.retiree, 1);
        weights.add(CreatureTypeIds.painter, 1);
        weights.add(CreatureTypeIds.sculptor, 1);
        weights.add(CreatureTypeIds.dancer, 1);
        weights.add(CreatureTypeIds.photographer, 1);
        weights.add(CreatureTypeIds.yogaInstructor, 2);
      case SiteType.internetCafe:
        weights.add(CreatureTypeIds.labTech, 5);
        weights.add(CreatureTypeIds.corporateManager, 3);
        weights.add(CreatureTypeIds.teenager, 15);
        weights.add(CreatureTypeIds.lawyer, 3);
        weights.add(CreatureTypeIds.collegeStudent, 25);
        weights.add(CreatureTypeIds.musician, 2);
        weights.add(CreatureTypeIds.mathematician, 1);
        weights.add(CreatureTypeIds.teacher, 5);
        weights.add(CreatureTypeIds.engineer, 15);
        weights.add(CreatureTypeIds.doctor, 1);
        weights.add(CreatureTypeIds.barista, 10);
        weights.add(CreatureTypeIds.carSalesman, 3);
        weights.add(CreatureTypeIds.officeWorker, 15);
        weights.add(CreatureTypeIds.secretary, 5);
        weights.add(CreatureTypeIds.hippie, 1);
        weights.add(CreatureTypeIds.programmer, 15);
        weights.add(CreatureTypeIds.retiree, 5);
        weights.add(CreatureTypeIds.painter, 1);
        weights.add(CreatureTypeIds.sculptor, 1);
        weights.add(CreatureTypeIds.dancer, 1);
        weights.add(CreatureTypeIds.photographer, 1);
        weights.add(CreatureTypeIds.cameraman, 1);
        weights.add(CreatureTypeIds.clerk, 1);
        weights.add(CreatureTypeIds.locksmith, 1);
      case SiteType.tenement:
        weights.add(CreatureTypeIds.securityGuard, 1);
        weights.add(CreatureTypeIds.labTech, 1);
        weights.add(CreatureTypeIds.janitor, 3);
        if (nonUnionWorkers) weights.add(CreatureTypeIds.nonUnionWorker, 1);
        weights.add(CreatureTypeIds.secretary, 2);
        if (unionWorkers) weights.add(CreatureTypeIds.unionWorker, 1);
        weights.add(CreatureTypeIds.teenager, 5);
        weights.add(CreatureTypeIds.sewerWorker, 1);
        weights.add(CreatureTypeIds.collegeStudent, 1);
        weights.add(CreatureTypeIds.musician, 1);
        weights.add(CreatureTypeIds.mathematician, 1);
        weights.add(CreatureTypeIds.teacher, 1);
        weights.add(CreatureTypeIds.highschoolDropout, 3);
        weights.add(CreatureTypeIds.bum, 3);
        if (mutantsPossible) weights.add(CreatureTypeIds.mutant, 2);
        if (mutantsCommon) weights.add(CreatureTypeIds.mutant, 5);
        weights.add(CreatureTypeIds.gangMember, 3);
        weights.add(CreatureTypeIds.crackhead, 3);
        weights.add(CreatureTypeIds.fastFoodWorker, 1);
        weights.add(CreatureTypeIds.barista, 1);
        weights.add(CreatureTypeIds.bartender, 1);
        weights.add(CreatureTypeIds.telemarketer, 1);
        weights.add(CreatureTypeIds.carSalesman, 1);
        weights.add(CreatureTypeIds.officeWorker, 1);
        weights.add(CreatureTypeIds.sexWorker, 3);
        weights.add(CreatureTypeIds.mailman, 1);
        weights.add(CreatureTypeIds.garbageman, 1);
        weights.add(CreatureTypeIds.constructionWorker, 1);
        weights.add(CreatureTypeIds.amateurMagician, 1);
        weights.add(CreatureTypeIds.hick, 1);
        weights.add(CreatureTypeIds.soldier, 1);
        weights.add(CreatureTypeIds.veteran, 2);
        if (nineteenEightyFour) {
          weights.add(CreatureTypeIds.educator, 1);
        } else {
          weights.add(CreatureTypeIds.prisonGuard, 1);
        }
        weights.add(CreatureTypeIds.hippie, 1);
        weights.add(CreatureTypeIds.biker, 1);
        weights.add(CreatureTypeIds.taxiDriver, 1);
        weights.add(CreatureTypeIds.retiree, 1);
        weights.add(CreatureTypeIds.painter, 1);
        weights.add(CreatureTypeIds.sculptor, 1);
        weights.add(CreatureTypeIds.dancer, 1);
        weights.add(CreatureTypeIds.photographer, 1);
        weights.add(CreatureTypeIds.hairstylist, 1);
        weights.add(CreatureTypeIds.clerk, 1);
        weights.add(CreatureTypeIds.thief, 1);
        weights.add(CreatureTypeIds.actor, 1);
        weights.add(CreatureTypeIds.firefighter, 1);
        weights.add(CreatureTypeIds.locksmith, 1);
      case SiteType.apartment:
        weights.add(CreatureTypeIds.securityGuard, 1);
        weights.add(CreatureTypeIds.labTech, 1);
        weights.add(CreatureTypeIds.corporateManager, 1);
        weights.add(CreatureTypeIds.janitor, 1);
        if (nonUnionWorkers) weights.add(CreatureTypeIds.nonUnionWorker, 1);
        weights.add(CreatureTypeIds.secretary, 1);
        if (unionWorkers) weights.add(CreatureTypeIds.unionWorker, 1);
        weights.add(CreatureTypeIds.teenager, 3);
        weights.add(CreatureTypeIds.cop, 1);
        if (deathSquadsActive) weights.add(CreatureTypeIds.deathSquad, 1);
        if (gangUnitsActive) weights.add(CreatureTypeIds.gangUnit, 1);
        weights.add(CreatureTypeIds.lawyer, 1);
        weights.add(CreatureTypeIds.sewerWorker, 1);
        weights.add(CreatureTypeIds.collegeStudent, 1);
        weights.add(CreatureTypeIds.musician, 1);
        weights.add(CreatureTypeIds.mathematician, 1);
        weights.add(CreatureTypeIds.teacher, 1);
        weights.add(CreatureTypeIds.priest, 1);
        weights.add(CreatureTypeIds.engineer, 1);
        weights.add(CreatureTypeIds.fastFoodWorker, 1);
        weights.add(CreatureTypeIds.baker, 1);
        weights.add(CreatureTypeIds.barista, 1);
        weights.add(CreatureTypeIds.bartender, 1);
        weights.add(CreatureTypeIds.telemarketer, 1);
        weights.add(CreatureTypeIds.carSalesman, 1);
        weights.add(CreatureTypeIds.officeWorker, 1);
        weights.add(CreatureTypeIds.footballCoach, 1);
        weights.add(CreatureTypeIds.mailman, 1);
        weights.add(CreatureTypeIds.doctor, 1);
        weights.add(CreatureTypeIds.psychologist, 1);
        weights.add(CreatureTypeIds.nurse, 1);
        weights.add(CreatureTypeIds.garbageman, 1);
        weights.add(CreatureTypeIds.plumber, 1);
        weights.add(CreatureTypeIds.chef, 1);
        weights.add(CreatureTypeIds.constructionWorker, 1);
        weights.add(CreatureTypeIds.amateurMagician, 1);
        weights.add(CreatureTypeIds.soldier, 1);
        weights.add(CreatureTypeIds.veteran, 2);
        if (nineteenEightyFour) {
          weights.add(CreatureTypeIds.educator, 1);
        } else {
          weights.add(CreatureTypeIds.prisonGuard, 1);
        }
        weights.add(CreatureTypeIds.hippie, 1);
        weights.add(CreatureTypeIds.artCritic, 1);
        weights.add(CreatureTypeIds.musicCritic, 1);
        weights.add(CreatureTypeIds.author, 1);
        weights.add(CreatureTypeIds.journalist, 1);
        weights.add(CreatureTypeIds.taxiDriver, 1);
        weights.add(CreatureTypeIds.programmer, 1);
        weights.add(CreatureTypeIds.retiree, 1);
        weights.add(CreatureTypeIds.painter, 1);
        weights.add(CreatureTypeIds.sculptor, 1);
        weights.add(CreatureTypeIds.dancer, 1);
        weights.add(CreatureTypeIds.photographer, 1);
        weights.add(CreatureTypeIds.cameraman, 1);
        weights.add(CreatureTypeIds.hairstylist, 1);
        weights.add(CreatureTypeIds.clerk, 1);
        weights.add(CreatureTypeIds.thief, 1);
        weights.add(CreatureTypeIds.actor, 1);
        weights.add(CreatureTypeIds.yogaInstructor, 1);
        weights.add(CreatureTypeIds.martialArtist, 1);
        weights.add(CreatureTypeIds.athlete, 1);
        weights.add(CreatureTypeIds.firefighter, 1);
        weights.add(CreatureTypeIds.locksmith, 1);
      case SiteType.bank:
        if (mode == GameMode.site &&
            !(levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0)) {
          encnum = 6;
          weights.add(CreatureTypeIds.labTech, 1);
          if (nonUnionWorkers) {
            weights.add(CreatureTypeIds.nonUnionWorker, 1);
          }
          if (unionWorkers) weights.add(CreatureTypeIds.unionWorker, 1);
          weights.add(CreatureTypeIds.teenager, 3);
          weights.add(CreatureTypeIds.janitor, 1);
          weights.add(CreatureTypeIds.secretary, 1);
          weights.add(CreatureTypeIds.cop, 1);
          if (deathSquadsActive) weights.add(CreatureTypeIds.deathSquad, 1);
          if (gangUnitsActive) weights.add(CreatureTypeIds.gangUnit, 1);
          weights.add(CreatureTypeIds.lawyer, 1);
          weights.add(CreatureTypeIds.sewerWorker, 1);
          weights.add(CreatureTypeIds.collegeStudent, 1);
          weights.add(CreatureTypeIds.musician, 1);
          weights.add(CreatureTypeIds.mathematician, 1);
          weights.add(CreatureTypeIds.teacher, 1);
          weights.add(CreatureTypeIds.priest, 1);
          weights.add(CreatureTypeIds.engineer, 1);
          weights.add(CreatureTypeIds.fastFoodWorker, 1);
          weights.add(CreatureTypeIds.baker, 1);
          weights.add(CreatureTypeIds.barista, 1);
          weights.add(CreatureTypeIds.bartender, 1);
          weights.add(CreatureTypeIds.telemarketer, 1);
          weights.add(CreatureTypeIds.carSalesman, 1);
          weights.add(CreatureTypeIds.officeWorker, 1);
          weights.add(CreatureTypeIds.footballCoach, 1);
          weights.add(CreatureTypeIds.mailman, 1);
          weights.add(CreatureTypeIds.doctor, 1);
          weights.add(CreatureTypeIds.psychologist, 1);
          weights.add(CreatureTypeIds.nurse, 1);
          weights.add(CreatureTypeIds.garbageman, 1);
          weights.add(CreatureTypeIds.plumber, 1);
          weights.add(CreatureTypeIds.chef, 1);
          weights.add(CreatureTypeIds.constructionWorker, 1);
          weights.add(CreatureTypeIds.amateurMagician, 1);
          weights.add(CreatureTypeIds.soldier, 1);
          weights.add(CreatureTypeIds.veteran, 2);
          if (nineteenEightyFour) {
            weights.add(CreatureTypeIds.educator, 1);
          } else {
            weights.add(CreatureTypeIds.prisonGuard, 1);
          }
          weights.add(CreatureTypeIds.hippie, 1);
          weights.add(CreatureTypeIds.artCritic, 1);
          weights.add(CreatureTypeIds.musicCritic, 1);
          weights.add(CreatureTypeIds.author, 1);
          weights.add(CreatureTypeIds.journalist, 1);
          weights.add(CreatureTypeIds.taxiDriver, 1);
          weights.add(CreatureTypeIds.programmer, 1);
          weights.add(CreatureTypeIds.retiree, 1);
          weights.add(CreatureTypeIds.painter, 1);
          weights.add(CreatureTypeIds.sculptor, 1);
          weights.add(CreatureTypeIds.dancer, 1);
          weights.add(CreatureTypeIds.photographer, 1);
          weights.add(CreatureTypeIds.cameraman, 1);
          weights.add(CreatureTypeIds.hairstylist, 1);
          weights.add(CreatureTypeIds.clerk, 1);
          weights.add(CreatureTypeIds.thief, 1);
          weights.add(CreatureTypeIds.actor, 1);
          weights.add(CreatureTypeIds.yogaInstructor, 1);
          weights.add(CreatureTypeIds.martialArtist, 1);
          weights.add(CreatureTypeIds.athlete, 1);
          weights.add(CreatureTypeIds.firefighter, 1);
          weights.add(CreatureTypeIds.locksmith, 1);
        } else {
          if (sec) {
            weights.add(CreatureTypeIds.merc, 2000);
          } else {
            weights.add(CreatureTypeIds.securityGuard, 1000);
          }
          weights.add(CreatureTypeIds.bankManager, 200);
          weights.add(CreatureTypeIds.janitor, 100);
          weights.add(CreatureTypeIds.thief, 5);
        }
      case SiteType.upscaleApartment:
        if (mode == GameMode.site &&
            !(levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0)) {
          if (sec) {
            weights.add(CreatureTypeIds.securityGuard, 100);
          } else {
            weights.add(CreatureTypeIds.securityGuard, 10);
          }
          if (sec) weights.add(CreatureTypeIds.guardDog, 50);
        }
        weights.add(CreatureTypeIds.eminentScientist, 1);
        weights.add(CreatureTypeIds.corporateManager, 5);
        weights.add(CreatureTypeIds.janitor, 5);
        weights.add(CreatureTypeIds.secretary, 1);
        weights.add(CreatureTypeIds.teenager, 3);
        weights.add(CreatureTypeIds.liberalJudge, 1);
        weights.add(CreatureTypeIds.conservativeJudge, 1);
        weights.add(CreatureTypeIds.radioPersonality, 1);
        weights.add(CreatureTypeIds.newsAnchor, 1);
        weights.add(CreatureTypeIds.lawyer, 5);
        weights.add(CreatureTypeIds.doctor, 5);
        weights.add(CreatureTypeIds.psychologist, 1);
        weights.add(CreatureTypeIds.nurse, 1);
        weights.add(CreatureTypeIds.collegeStudent, 1);
        weights.add(CreatureTypeIds.musician, 1);
        weights.add(CreatureTypeIds.sexWorker, 3);
        weights.add(CreatureTypeIds.mailman, 1);
        weights.add(CreatureTypeIds.artCritic, 1);
        weights.add(CreatureTypeIds.musicCritic, 1);
        weights.add(CreatureTypeIds.author, 1);
        weights.add(CreatureTypeIds.journalist, 1);
        weights.add(CreatureTypeIds.socialite, 2);
        weights.add(CreatureTypeIds.painter, 1);
        weights.add(CreatureTypeIds.sculptor, 1);
        weights.add(CreatureTypeIds.dancer, 1);
        weights.add(CreatureTypeIds.photographer, 1);
        weights.add(CreatureTypeIds.fashionDesigner, 1);
        weights.add(CreatureTypeIds.thief, 1);
        weights.add(CreatureTypeIds.actor, 1);
        weights.add(CreatureTypeIds.athlete, 1);
        weights.add(CreatureTypeIds.locksmith, 1);
        encnum = 1;
        if (mode == GameMode.site &&
            !(levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0)) {
          encnum = 4;
        }
      case SiteType.cosmeticsLab:
        weights.add(CreatureTypeIds.securityGuard, sec ? 100 : 3);
        weights.add(CreatureTypeIds.labTech, 10);
        weights.add(CreatureTypeIds.eminentScientist, 1);
        weights.add(CreatureTypeIds.corporateManager, 1);
        weights.add(CreatureTypeIds.janitor, 10);
        weights.add(CreatureTypeIds.secretary, 10);
        weights.add(CreatureTypeIds.officeWorker, 10);
      case SiteType.nuclearPlant:
        weights.add(CreatureTypeIds.securityGuard, sec ? 100 : 10);
        weights.add(CreatureTypeIds.labTech, 10);
        weights.add(CreatureTypeIds.eminentScientist, 1);
        weights.add(CreatureTypeIds.corporateManager, 1);
        weights.add(CreatureTypeIds.janitor, 10);
        weights.add(CreatureTypeIds.secretary, 10);
        weights.add(CreatureTypeIds.officeWorker, 10);
      case SiteType.geneticsLab:
        if (sec) weights.add(CreatureTypeIds.guardDog, 25);
        weights.add(CreatureTypeIds.securityGuard, sec ? 100 : 3);
        weights.add(CreatureTypeIds.labTech, 10);
        weights.add(CreatureTypeIds.eminentScientist, 1);
        weights.add(CreatureTypeIds.corporateManager, 1);
        weights.add(CreatureTypeIds.doctor, 1);
        weights.add(CreatureTypeIds.janitor, 10);
        weights.add(CreatureTypeIds.secretary, 10);
        weights.add(CreatureTypeIds.officeWorker, 10);
      case SiteType.policeStation:
        weights.add(CreatureTypeIds.labTech, 1);
        weights.add(CreatureTypeIds.corporateManager, 1);
        weights.add(CreatureTypeIds.janitor, 50);
        if (nonUnionWorkers) weights.add(CreatureTypeIds.nonUnionWorker, 1);
        weights.add(CreatureTypeIds.secretary, 1);
        if (unionWorkers) weights.add(CreatureTypeIds.unionWorker, 1);
        weights.add(CreatureTypeIds.teenager, 5);
        weights.add(CreatureTypeIds.cop, sec ? 1000 : 500);
        if (deathSquadsActive) weights.add(CreatureTypeIds.deathSquad, 400);
        if (gangUnitsActive) weights.add(CreatureTypeIds.gangUnit, 400);
        weights.add(CreatureTypeIds.liberalJudge, 1);
        weights.add(CreatureTypeIds.conservativeJudge, 1);
        weights.add(CreatureTypeIds.agent, 1);
        weights.add(CreatureTypeIds.radioPersonality, 1);
        weights.add(CreatureTypeIds.newsAnchor, 1);
        weights.add(CreatureTypeIds.lawyer, 1);
        weights.add(CreatureTypeIds.doctor, 1);
        weights.add(CreatureTypeIds.psychologist, 1);
        weights.add(CreatureTypeIds.nurse, 1);
        weights.add(CreatureTypeIds.sewerWorker, 1);
        weights.add(CreatureTypeIds.collegeStudent, 1);
        weights.add(CreatureTypeIds.musician, 1);
        weights.add(CreatureTypeIds.mathematician, 1);
        weights.add(CreatureTypeIds.teacher, 1);
        weights.add(CreatureTypeIds.highschoolDropout, 10);
        weights.add(CreatureTypeIds.bum, 10);
        if (mutantsPossible) weights.add(CreatureTypeIds.mutant, 2);
        if (mutantsCommon) weights.add(CreatureTypeIds.mutant, 5);
        weights.add(CreatureTypeIds.gangMember, 10);
        weights.add(CreatureTypeIds.crackhead, 10);
        weights.add(CreatureTypeIds.priest, 5);
        weights.add(CreatureTypeIds.engineer, 1);
        weights.add(CreatureTypeIds.fastFoodWorker, 1);
        weights.add(CreatureTypeIds.baker, 1);
        weights.add(CreatureTypeIds.barista, 1);
        weights.add(CreatureTypeIds.bartender, 1);
        weights.add(CreatureTypeIds.telemarketer, 1);
        weights.add(CreatureTypeIds.carSalesman, 1);
        weights.add(CreatureTypeIds.officeWorker, 1);
        weights.add(CreatureTypeIds.footballCoach, 1);
        weights.add(CreatureTypeIds.sexWorker, 10);
        weights.add(CreatureTypeIds.mailman, 1);
        weights.add(CreatureTypeIds.garbageman, 1);
        weights.add(CreatureTypeIds.plumber, 1);
        weights.add(CreatureTypeIds.chef, 1);
        weights.add(CreatureTypeIds.constructionWorker, 1);
        weights.add(CreatureTypeIds.amateurMagician, 1);
        weights.add(CreatureTypeIds.hick, 1);
        weights.add(CreatureTypeIds.soldier, 1);
        weights.add(CreatureTypeIds.veteran, 2);
        if (nineteenEightyFour) {
          weights.add(CreatureTypeIds.educator, 1);
        } else {
          weights.add(CreatureTypeIds.prisonGuard, 1);
        }
        weights.add(CreatureTypeIds.hippie, 1);
        weights.add(CreatureTypeIds.artCritic, 1);
        weights.add(CreatureTypeIds.musicCritic, 1);
        weights.add(CreatureTypeIds.author, 1);
        weights.add(CreatureTypeIds.journalist, 1);
        weights.add(CreatureTypeIds.socialite, 1);
        weights.add(CreatureTypeIds.biker, 5);
        weights.add(CreatureTypeIds.trucker, 1);
        weights.add(CreatureTypeIds.taxiDriver, 1);
        weights.add(CreatureTypeIds.programmer, 1);
        weights.add(CreatureTypeIds.nun, 1);
        weights.add(CreatureTypeIds.retiree, 1);
        weights.add(CreatureTypeIds.painter, 1);
        weights.add(CreatureTypeIds.sculptor, 1);
        weights.add(CreatureTypeIds.dancer, 1);
        weights.add(CreatureTypeIds.photographer, 1);
        weights.add(CreatureTypeIds.cameraman, 1);
        weights.add(CreatureTypeIds.hairstylist, 1);
        weights.add(CreatureTypeIds.fashionDesigner, 1);
        weights.add(CreatureTypeIds.clerk, 1);
        weights.add(CreatureTypeIds.thief, 10);
        weights.add(CreatureTypeIds.actor, 1);
        weights.add(CreatureTypeIds.yogaInstructor, 1);
        weights.add(CreatureTypeIds.martialArtist, 1);
        weights.add(CreatureTypeIds.athlete, 1);
        weights.add(CreatureTypeIds.firefighter, 1);
        weights.add(CreatureTypeIds.locksmith, 5); //Forensic locksmiths
      case SiteType.courthouse:
        weights.add(CreatureTypeIds.cop, sec ? 2000 : 200);
        weights.add(CreatureTypeIds.labTech, 1);
        weights.add(CreatureTypeIds.eminentScientist, 1);
        weights.add(CreatureTypeIds.corporateManager, 1);
        weights.add(CreatureTypeIds.janitor, 50);
        if (nonUnionWorkers) weights.add(CreatureTypeIds.nonUnionWorker, 1);
        weights.add(CreatureTypeIds.secretary, 50);
        if (unionWorkers) weights.add(CreatureTypeIds.unionWorker, 1);
        weights.add(CreatureTypeIds.teenager, 1);
        if (deathSquadsActive) weights.add(CreatureTypeIds.deathSquad, 80);
        if (gangUnitsActive) weights.add(CreatureTypeIds.gangUnit, 80);
        weights.add(CreatureTypeIds.liberalJudge, 20);
        weights.add(CreatureTypeIds.conservativeJudge, 20);
        weights.add(CreatureTypeIds.agent, 1);
        weights.add(CreatureTypeIds.radioPersonality, 1);
        weights.add(CreatureTypeIds.newsAnchor, 1);
        weights.add(CreatureTypeIds.lawyer, 200);
        weights.add(CreatureTypeIds.psychologist, 20);
        weights.add(CreatureTypeIds.sewerWorker, 1);
        weights.add(CreatureTypeIds.collegeStudent, 1);
        weights.add(CreatureTypeIds.musician, 1);
        weights.add(CreatureTypeIds.mathematician, 1);
        weights.add(CreatureTypeIds.teacher, 1);
        weights.add(CreatureTypeIds.highschoolDropout, 1);
        weights.add(CreatureTypeIds.bum, 1);
        if (mutantsPossible) weights.add(CreatureTypeIds.mutant, 1);
        if (mutantsCommon) weights.add(CreatureTypeIds.mutant, 2);
        weights.add(CreatureTypeIds.gangMember, 1);
        weights.add(CreatureTypeIds.crackhead, 1);
        weights.add(CreatureTypeIds.priest, 1);
        weights.add(CreatureTypeIds.engineer, 1);
        weights.add(CreatureTypeIds.fastFoodWorker, 1);
        weights.add(CreatureTypeIds.baker, 1);
        weights.add(CreatureTypeIds.barista, 1);
        weights.add(CreatureTypeIds.bartender, 1);
        weights.add(CreatureTypeIds.telemarketer, 1);
        weights.add(CreatureTypeIds.carSalesman, 2);
        weights.add(CreatureTypeIds.officeWorker, 50);
        weights.add(CreatureTypeIds.footballCoach, 1);
        weights.add(CreatureTypeIds.sexWorker, 1);
        weights.add(CreatureTypeIds.mailman, 1);
        weights.add(CreatureTypeIds.garbageman, 1);
        weights.add(CreatureTypeIds.plumber, 1);
        weights.add(CreatureTypeIds.chef, 1);
        weights.add(CreatureTypeIds.constructionWorker, 1);
        weights.add(CreatureTypeIds.amateurMagician, 1);
        weights.add(CreatureTypeIds.hick, 1);
        weights.add(CreatureTypeIds.soldier, 1);
        weights.add(CreatureTypeIds.veteran, 2);
        if (nineteenEightyFour) {
          weights.add(CreatureTypeIds.educator, 1);
        } else {
          weights.add(CreatureTypeIds.prisonGuard, 1);
        }
        weights.add(CreatureTypeIds.hippie, 1);
        weights.add(CreatureTypeIds.artCritic, 1);
        weights.add(CreatureTypeIds.musicCritic, 1);
        weights.add(CreatureTypeIds.author, 1);
        weights.add(CreatureTypeIds.journalist, 1);
        weights.add(CreatureTypeIds.socialite, 1);
        weights.add(CreatureTypeIds.biker, 1);
        weights.add(CreatureTypeIds.trucker, 1);
        weights.add(CreatureTypeIds.taxiDriver, 1);
        weights.add(CreatureTypeIds.programmer, 1);
        weights.add(CreatureTypeIds.nun, 1);
        weights.add(CreatureTypeIds.retiree, 1);
        weights.add(CreatureTypeIds.painter, 1);
        weights.add(CreatureTypeIds.sculptor, 1);
        weights.add(CreatureTypeIds.dancer, 1);
        weights.add(CreatureTypeIds.photographer, 1);
        weights.add(CreatureTypeIds.cameraman, 1);
        weights.add(CreatureTypeIds.hairstylist, 1);
        weights.add(CreatureTypeIds.fashionDesigner, 1);
        weights.add(CreatureTypeIds.clerk, 1);
        weights.add(CreatureTypeIds.thief, 3);
        weights.add(CreatureTypeIds.actor, 1);
        weights.add(CreatureTypeIds.yogaInstructor, 1);
        weights.add(CreatureTypeIds.martialArtist, 1);
        weights.add(CreatureTypeIds.athlete, 1);
        weights.add(CreatureTypeIds.firefighter, 1);
        weights.add(CreatureTypeIds.locksmith, 5);
      case SiteType.fireStation:
        weights.add(CreatureTypeIds.janitor, 5);
        weights.add(CreatureTypeIds.secretary, 2);
        if (sec) {
          if (deathSquadsActive) {
            weights.add(CreatureTypeIds.deathSquad, 50);
          } else if (gangUnitsActive) {
            weights.add(CreatureTypeIds.gangUnit, 50);
          } else {
            weights.add(CreatureTypeIds.cop, 50);
          }
        }
        weights.add(CreatureTypeIds.nurse, 2);
        weights.add(CreatureTypeIds.priest, 5);
        weights.add(CreatureTypeIds.journalist, 1);
        weights.add(CreatureTypeIds.photographer, 1);
        weights.add(CreatureTypeIds.firefighter, 100);
      case SiteType.prison:
        if (levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0) {
          weights.add(CreatureTypeIds.prisoner,
              8); // prisoners only in restricted areas
        }
        if (nineteenEightyFour) {
          weights.add(CreatureTypeIds.educator, sec ? 3 : 2);
        } else {
          weights.add(CreatureTypeIds.prisonGuard, sec ? 3 : 2);
        }
      case SiteType.intelligenceHQ:
        weights.add(CreatureTypeIds.agent, sec ? 1000 : 100);
        weights.add(CreatureTypeIds.janitor, 50);
        weights.add(CreatureTypeIds.secretary, 50);
        if (nineteenEightyFour) weights.add(CreatureTypeIds.educator, 50);
        if (sec) weights.add(CreatureTypeIds.guardDog, 450);
        weights.add(CreatureTypeIds.guardDog, 50);
        weights.add(CreatureTypeIds.mathematician, 5);
        weights.add(CreatureTypeIds.programmer, 5);
      case SiteType.armyBase:
        weights.add(CreatureTypeIds.soldier, 750);
        if (sec) weights.add(CreatureTypeIds.guardDog, 230);
        weights.add(CreatureTypeIds.guardDog, 20);
        weights.add(CreatureTypeIds.militaryPolice, 100);
        if (sec) weights.add(CreatureTypeIds.militaryPolice, 100);
        weights.add(CreatureTypeIds.seal, 20);
      case SiteType.sweatshop:
        weights.add(CreatureTypeIds.securityGuard, sec ? 1000 : 100);
        weights.add(CreatureTypeIds.corporateManager, 5);
        weights.add(CreatureTypeIds.sweatshopWorker, 800);
      case SiteType.dirtyIndustry:
        if (sec) weights.add(CreatureTypeIds.securityGuard, 100);
        weights.add(CreatureTypeIds.corporateManager, 1);
        weights.add(CreatureTypeIds.janitor, 10);
        weights.add(CreatureTypeIds.secretary, 10);
        if (laws[Law.labor] == DeepAlignment.archConservative) {
          weights.add(CreatureTypeIds.childLaborer, 160);
        } else if (laws[Law.labor] == DeepAlignment.conservative) {
          weights.add(CreatureTypeIds.nonUnionWorker, 160);
        } else if (laws[Law.labor] == DeepAlignment.moderate) {
          weights.add(CreatureTypeIds.nonUnionWorker, 80);
          weights.add(CreatureTypeIds.unionWorker, 80);
        } else if (laws[Law.labor] == DeepAlignment.liberal) {
          weights.add(CreatureTypeIds.nonUnionWorker, 50);
          weights.add(CreatureTypeIds.unionWorker, 110);
        } else {
          weights.add(CreatureTypeIds.unionWorker, 160);
        }
      case SiteType.corporateHQ:
        if (sec) weights.add(CreatureTypeIds.guardDog, 100);
        weights.add(CreatureTypeIds.securityGuard, sec ? 40 : 400);
        weights.add(CreatureTypeIds.corporateManager, 20);
        weights.add(CreatureTypeIds.janitor, 20);
        weights.add(CreatureTypeIds.secretary, 40);
        weights.add(CreatureTypeIds.conservativeJudge, 1);
        weights.add(CreatureTypeIds.lawyer, 20);
        weights.add(CreatureTypeIds.priest, 1);
        weights.add(CreatureTypeIds.officeWorker, 80);
        weights.add(CreatureTypeIds.sexWorker, 1);
      case SiteType.ceoHouse:
        if (sec) weights.add(CreatureTypeIds.merc, 100);
        weights.add(CreatureTypeIds.guardDog, sec ? 50 : 5);
        weights.add(CreatureTypeIds.servant, 30);
        weights.add(CreatureTypeIds.secretary, 5);
        weights.add(CreatureTypeIds.teenager, 5);
        weights.add(CreatureTypeIds.genetic, 1);
        weights.add(CreatureTypeIds.lawyer, 5);
        weights.add(CreatureTypeIds.priest, 1);
        weights.add(CreatureTypeIds.sexWorker, 1);
      case SiteType.amRadioStation:
        weights.add(CreatureTypeIds.securityGuard, sec ? 100 : 10);
        weights.add(CreatureTypeIds.corporateManager, 2);
        weights.add(CreatureTypeIds.janitor, 10);
        weights.add(CreatureTypeIds.secretary, 10);
        weights.add(CreatureTypeIds.radioPersonality, 2);
        weights.add(CreatureTypeIds.engineer, 20);
        weights.add(CreatureTypeIds.officeWorker, 40);
      case SiteType.cableNewsStation:
        weights.add(CreatureTypeIds.securityGuard, sec ? 100 : 10);
        weights.add(CreatureTypeIds.corporateManager, 5);
        weights.add(CreatureTypeIds.janitor, 20);
        weights.add(CreatureTypeIds.secretary, 20);
        weights.add(CreatureTypeIds.newsAnchor, 2);
        weights.add(CreatureTypeIds.engineer, 40);
        weights.add(CreatureTypeIds.officeWorker, 40);
        weights.add(CreatureTypeIds.photographer, 5);
        weights.add(CreatureTypeIds.cameraman, 5);
      case SiteType.homelessEncampment:
      default:
        weights.add(CreatureTypeIds.janitor, 5);
        weights.add(CreatureTypeIds.teenager, 20);
        weights.add(CreatureTypeIds.musician, 3);
        weights.add(CreatureTypeIds.mathematician, 1);
        weights.add(CreatureTypeIds.bum, 200);
        if (mutantsPossible) weights.add(CreatureTypeIds.mutant, 2);
        if (mutantsCommon) weights.add(CreatureTypeIds.mutant, 50);
        weights.add(CreatureTypeIds.gangMember, 5);
        weights.add(CreatureTypeIds.crackhead, 50);
        weights.add(CreatureTypeIds.sexWorker, 10);
        weights.add(CreatureTypeIds.amateurMagician, 1);
        weights.add(CreatureTypeIds.hippie, 1);
        weights.add(CreatureTypeIds.nurse, 5);
        weights.add(CreatureTypeIds.biker, 1);
        weights.add(CreatureTypeIds.painter, 1);
        weights.add(CreatureTypeIds.sculptor, 1);
        weights.add(CreatureTypeIds.dancer, 1);
        weights.add(CreatureTypeIds.photographer, 1);
        weights.add(CreatureTypeIds.thief, 5);
        weights.add(CreatureTypeIds.actor, 1);
    }
    for (int n = 0; n < lcsRandom(encnum - 1) + 1; n++) {
      encounter.add(Creature.fromId(lcsRandomWeighted(weights)));
    }
  }
}

Future<bool> addsiegeencounter(int type) async {
  int num;
  int freeslots = ENCMAX - encounter.length;

  switch (type) {
    case SIEGEFLAG_UNIT:
    case SIEGEFLAG_UNIT_DAMAGED:
      {
        if (freeslots < 6) return false;

        num = lcsRandom(3) + 4;

        for (int i = 0; i < min(num, freeslots); i++) {
          Creature e;

          if (activeSiteUnderSiege) {
            switch (activeSite!.siege.activeSiegeType) {
              case SiegeType.police:
                if (activeSite!.siege.escalationState ==
                    SiegeEscalation.police) {
                  e = Creature.fromId(CreatureTypeIds.swat);
                } else {
                  if (activeSite!.siege.escalationState.index <
                      SiegeEscalation.bombers.index) {
                    e = Creature.fromId(CreatureTypeIds.soldier);
                  } else {
                    e = Creature.fromId(CreatureTypeIds.seal);
                  }
                }
                ensureIsArmed(e);
              case SiegeType.cia:
                e = Creature.fromId(CreatureTypeIds.agent);
                ensureIsArmed(e);
              case SiegeType.hicks:
                e = Creature.fromId(CreatureTypeIds.hick);
                ensureIsArmed(e);
              case SiegeType.corporateMercs:
                e = Creature.fromId(CreatureTypeIds.merc);
                ensureIsArmed(e);
              case SiegeType.ccs:
                if (oneIn(12)) {
                  e = Creature.fromId(CreatureTypeIds.ccsArchConservative);
                } else if (oneIn(11)) {
                  e = Creature.fromId(CreatureTypeIds.ccsMolotov);
                } else if (oneIn(10)) {
                  e = Creature.fromId(CreatureTypeIds.ccsSniper);
                } else {
                  e = Creature.fromId(CreatureTypeIds.ccsVigilante);
                }
                ensureIsArmed(e);
              default:
                addstr("Siege type ");
                addstr(activeSite!.siege.activeSiegeType.toString());
                addstr(" missing!\n");
                await getKey();
                return false;
            }
          } else {
            switch (siteType) {
              case SiteType.armyBase:
                if (encounter.isEmpty && oneIn(2)) {
                  e = Creature.fromId(CreatureTypeIds.tank);
                } else {
                  e = Creature.fromId(CreatureTypeIds.soldier);
                }
              case SiteType.intelligenceHQ:
                e = Creature.fromId(CreatureTypeIds.agent);
              case SiteType.corporateHQ:
              case SiteType.ceoHouse:
                e = Creature.fromId(CreatureTypeIds.merc);
              case SiteType.amRadioStation:
              case SiteType.cableNewsStation:
                e = Creature.fromId(CreatureTypeIds.hick);
              case SiteType.policeStation:
                if (deathSquadsActive) {
                  e = Creature.fromId(CreatureTypeIds.deathSquad);
                } else {
                  e = Creature.fromId(CreatureTypeIds.swat);
                }
              case SiteType.drugHouse:
                e = Creature.fromId(CreatureTypeIds.gangMember);
                e.align = Alignment.conservative;
              default:
                if (activeSite!.controller == SiteController.ccs) {
                  if (oneIn(11)) {
                    e = Creature.fromId(CreatureTypeIds.ccsMolotov);
                  } else if (oneIn(10)) {
                    e = Creature.fromId(CreatureTypeIds.ccsSniper);
                  } else {
                    e = Creature.fromId(CreatureTypeIds.ccsVigilante);
                  }
                } else if (deathSquadsActive) {
                  e = Creature.fromId(CreatureTypeIds.deathSquad);
                } else {
                  e = Creature.fromId(CreatureTypeIds.swat);
                }
            }
          }

          encounter.add(e);

          if (type == SIEGEFLAG_UNIT_DAMAGED) e.blood = lcsRandom(75) + 1;

          num--;
        }
        break;
      }
    case SIEGEFLAG_HEAVYUNIT:
      {
        if (freeslots < 1) return false;

        num = 1;

        for (int i = 0; i < min(num, freeslots); i++) {
          Creature e = Creature.fromId(CreatureTypeIds.tank);
          encounter.add(e);

          num--;
          if (num == 0) break;
        }
        break;
      }
  }

  return true;
}

/* siege - makes sure that a besieging attacker is armed and conservative */
void ensureIsArmed(Creature enemy) {
  int lightgun = 8, mediumgun = 4, heavygun = 0, randomint = 0;

  //Step one - besiegers conservative
  enemy.align = Alignment.conservative;

  //Now, find out if we need a weapon for this enemy
  if (enemy.equippedWeapon != null) {
    return; //No, already armed!
  } else {
    lightgun = max(0, lightgun - laws[Law.gunControl]!.index + 2);
    mediumgun = max(0, mediumgun - laws[Law.gunControl]!.index + 2);
    heavygun = max(0, heavygun - laws[Law.gunControl]!.index + 2);

    randomint = lcsRandom(lightgun + mediumgun + heavygun);
    if (randomint < lightgun) {
      enemy.giveWeaponAndAmmo(
          ["WEAPON_SEMIPISTOL_9MM", "WEAPON_REVOLVER_38"].random, 4);
    } else if (randomint < (lightgun + mediumgun)) {
      enemy.giveWeaponAndAmmo(
          [
            "WEAPON_REVOLVER_44",
            "WEAPON_SEMIPISTOL_45",
            "WEAPON_SEMIRIFLE_AR15",
            "WEAPON_SHOTGUN_PUMP",
          ].random,
          4);
    } else {
      enemy.giveWeaponAndAmmo(
          [
            "WEAPON_AUTORIFLE_AK47",
            "WEAPON_CARBINE_M4",
            "WEAPON_AUTORIFLE_M16",
            "WEAPON_SMG_MP5",
          ].random,
          4);
    }
  }
}

void fillEncounter(String creature, int num) {
  for (int i = 0; i < num; i++) {
    encounter.add(Creature.fromId(creature));
  }
}
