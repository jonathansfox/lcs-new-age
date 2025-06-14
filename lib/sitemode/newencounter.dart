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

  void addAll(Map<String, int> other) {
    for (var entry in other.entries) {
      this[entry.key] = (this[entry.key] ?? 0) + entry.value;
    }
  }
}

/* generates a new random encounter */
void prepareEncounter(SiteType type, bool sec,
    {bool addToExisting = false, int? num}) {
  if (!addToExisting) encounter.clear();

  Map<String, int> weights = {};
  bool lcs = activeSite?.controller == SiteController.lcs;
  bool ccs = activeSite?.controller == SiteController.ccs && ccsActive;

  if (postAlarmTimer > 80) {
    switch (type) {
      case SiteType.armyBase:
        weights.addAll({
          CreatureTypeIds.soldier: 1000,
          CreatureTypeIds.militaryPolice: 300,
          CreatureTypeIds.seal: 150,
          CreatureTypeIds.guardDog: 100,
          CreatureTypeIds.tank: 100,
        });
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
        weights.add(CreatureTypeIds.angryRuralMob, 1000);
      case SiteType.policeStation:
        if (deathSquadsActive) {
          weights.add(CreatureTypeIds.deathSquad, 1000);
        } else {
          weights.add(CreatureTypeIds.swat, 1000);
        }
      case SiteType.drugHouse:
        weights.add(CreatureTypeIds.gangMember, 1000);
      default:
        if (activeSite!.controller == SiteController.ccs) {
          weights.add(CreatureTypeIds.ccsVigilante, 1000);
        } else if (deathSquadsActive) {
          weights.add(CreatureTypeIds.deathSquad, 1000);
        } else {
          weights.add(CreatureTypeIds.swat, 1000);
        }
    }
    if (siteOnFire && !noProfanity) {
      weights.add(CreatureTypeIds.firefighter, 1000);
    }
  }

  if (activeSite?.controller == SiteController.ccs &&
      (type != SiteType.barAndGrill || sec)) {
    weights.addAll({
      CreatureTypeIds.ccsVigilante: 50,
      CreatureTypeIds.sexWorker: 5,
      CreatureTypeIds.crackhead: 5,
      CreatureTypeIds.priest: 5,
      CreatureTypeIds.radioPersonality: 1,
      CreatureTypeIds.televangelist: 1,
      CreatureTypeIds.neoNazi: 5,
    });

    for (int n = 0; n < lcsRandom(6) + 1; n++) {
      Creature cr =
          Creature.fromId(creatureTypes[lcsRandomWeighted(weights)]!.id);
      conservatize(cr);
      encounter.add(cr);
    }
  } else {
    int encnum = num ?? 6;
    switch (type) {
      case SiteType.drugHouse:
        if (!lcs) {
          weights.addAll({
            CreatureTypeIds.gangMember: 200,
            CreatureTypeIds.sexWorker: 200,
            if (ccsState.index < CCSStrength.defeated.index &&
                ccsState.index > CCSStrength.inHiding.index &&
                activeSite?.city.sites
                        .any((s) => s.controller == SiteController.ccs) ==
                    true)
              CreatureTypeIds.ccsVigilante: 50,
            CreatureTypeIds.crackhead: 200,
            if (mutantsPossible) CreatureTypeIds.mutant: 2,
            if (mutantsCommon) CreatureTypeIds.mutant: 50,
            CreatureTypeIds.punk: 10,
            CreatureTypeIds.biker: 10,
            CreatureTypeIds.painter: 1,
            CreatureTypeIds.sculptor: 1,
            CreatureTypeIds.musician: 1,
            CreatureTypeIds.mathematician: 1,
            CreatureTypeIds.thief: 3,
            CreatureTypeIds.actor: 1,
            CreatureTypeIds.journalist: 2,
            CreatureTypeIds.highschoolDropout: 30,
            CreatureTypeIds.teenager: 50,
            CreatureTypeIds.bum: 100,
          });
        }
      case SiteType.juiceBar:
        weights.addAll({
          CreatureTypeIds.teenager: 10,
          CreatureTypeIds.liberalJudge: 1,
          CreatureTypeIds.collegeStudent: 10,
          CreatureTypeIds.musician: 2,
          CreatureTypeIds.mathematician: 1,
          CreatureTypeIds.teacher: 1,
          CreatureTypeIds.highschoolDropout: 1,
          CreatureTypeIds.engineer: 1,
          CreatureTypeIds.fastFoodWorker: 1,
          CreatureTypeIds.baker: 1,
          CreatureTypeIds.barista: 1,
          CreatureTypeIds.bartender: 1,
          CreatureTypeIds.telemarketer: 1,
          CreatureTypeIds.carSalesman: 1,
          CreatureTypeIds.officeWorker: 1,
          CreatureTypeIds.mailman: 1,
          CreatureTypeIds.chef: 1,
          CreatureTypeIds.nurse: 1,
          CreatureTypeIds.amateurMagician: 1,
          CreatureTypeIds.hippie: 6,
          CreatureTypeIds.punk: 1,
          CreatureTypeIds.emo: 2,
          CreatureTypeIds.goth: 1,
          CreatureTypeIds.artCritic: 1,
          CreatureTypeIds.musicCritic: 1,
          CreatureTypeIds.author: 1,
          CreatureTypeIds.journalist: 1,
          CreatureTypeIds.socialite: 2,
          CreatureTypeIds.programmer: 1,
          CreatureTypeIds.retiree: 1,
          CreatureTypeIds.painter: 1,
          CreatureTypeIds.sculptor: 1,
          CreatureTypeIds.dancer: 1,
          CreatureTypeIds.photographer: 1,
          CreatureTypeIds.cameraman: 1,
          CreatureTypeIds.hairstylist: 1,
          CreatureTypeIds.fashionDesigner: 1,
          CreatureTypeIds.clerk: 1,
          CreatureTypeIds.thief: 1,
          CreatureTypeIds.actor: 1,
          CreatureTypeIds.yogaInstructor: 1,
          CreatureTypeIds.martialArtist: 1,
          CreatureTypeIds.athlete: 2,
          CreatureTypeIds.locksmith: 1,
        });
      case SiteType.barAndGrill:
        if (sec || siteAlarm) {
          weights.add(CreatureTypeIds.bouncer, 100);
        } else {
          weights.add(CreatureTypeIds.bouncer, 10);
        }
        if (!lcs) {
          weights.addAll({
            CreatureTypeIds.eminentScientist: 1,
            CreatureTypeIds.corporateManager: 30,
            CreatureTypeIds.cop: 5,
            if (deathSquadsActive) CreatureTypeIds.deathSquad: 2,
            if (gangUnitsActive) CreatureTypeIds.gangUnit: 2,
            CreatureTypeIds.conservativeJudge: 1,
            CreatureTypeIds.radioPersonality: 1,
            CreatureTypeIds.newsAnchor: 1,
            CreatureTypeIds.televangelist: 1,
            CreatureTypeIds.neoNazi: 10,
            CreatureTypeIds.naziPunk: 1,
            CreatureTypeIds.firefighter: 1,
          });
        } else {
          weights.addAll({
            CreatureTypeIds.punk: 5,
            CreatureTypeIds.goth: 5,
            CreatureTypeIds.emo: 5,
            CreatureTypeIds.hippie: 5,
            CreatureTypeIds.collegeStudent: 5,
          });
        }
        if (ccs) {
          weights.addAll({
            CreatureTypeIds.ccsVigilante: 50,
            if (sec) CreatureTypeIds.guardDog: 25,
          });
        }
        if (!lcs && !ccs) {
          weights.addAll({
            if (sec) CreatureTypeIds.bouncer: 15,
          });
        }
        weights.addAll({
          CreatureTypeIds.lawyer: 15,
          CreatureTypeIds.doctor: 10,
          CreatureTypeIds.psychologist: 1,
          CreatureTypeIds.musician: 1,
          CreatureTypeIds.engineer: 10,
          CreatureTypeIds.bartender: 10,
          CreatureTypeIds.footballCoach: 1,
          CreatureTypeIds.artCritic: 1,
          CreatureTypeIds.musicCritic: 1,
          CreatureTypeIds.author: 1,
          CreatureTypeIds.journalist: 1,
          CreatureTypeIds.socialite: 2,
          CreatureTypeIds.retiree: 1,
          CreatureTypeIds.painter: 1,
          CreatureTypeIds.sculptor: 1,
          CreatureTypeIds.dancer: 1,
          CreatureTypeIds.photographer: 1,
          CreatureTypeIds.fashionDesigner: 1,
          CreatureTypeIds.thief: 1,
          CreatureTypeIds.actor: 1,
          CreatureTypeIds.athlete: 1,
          CreatureTypeIds.locksmith: 1,
          CreatureTypeIds.sexWorker: 2,
        });
      case SiteType.whiteHouse:
        weights.addAll({
          CreatureTypeIds.eminentScientist: 1,
          CreatureTypeIds.janitor: 2,
          CreatureTypeIds.secretary: 2,
          CreatureTypeIds.teenager: 1,
          CreatureTypeIds.liberalJudge: 1,
          CreatureTypeIds.conservativeJudge: 1,
          CreatureTypeIds.agent: 2,
          CreatureTypeIds.secretService: sec ? 100 : 5,
          CreatureTypeIds.lawyer: 3,
          CreatureTypeIds.doctor: 1,
          CreatureTypeIds.collegeStudent: 1,
          CreatureTypeIds.teacher: 1,
          CreatureTypeIds.officeWorker: 5,
          CreatureTypeIds.footballCoach: 1,
          CreatureTypeIds.chef: 1,
          CreatureTypeIds.veteran: 1,
          CreatureTypeIds.journalist: 2,
          CreatureTypeIds.socialite: 1,
          CreatureTypeIds.photographer: 2,
          CreatureTypeIds.cameraman: 1,
          CreatureTypeIds.hairstylist: 1,
          CreatureTypeIds.clerk: 5,
          CreatureTypeIds.actor: 1,
          CreatureTypeIds.athlete: 1,
        });
      case SiteType.publicPark:
      case SiteType.latteStand:
        weights.addAll({
          CreatureTypeIds.securityGuard: 5,
          CreatureTypeIds.labTech: 10,
          CreatureTypeIds.eminentScientist: 1,
          CreatureTypeIds.corporateManager: 10,
          CreatureTypeIds.janitor: 5,
          if (nonUnionWorkers) CreatureTypeIds.nonUnionWorker: 5,
          if (unionWorkers) CreatureTypeIds.unionWorker: 5,
          CreatureTypeIds.secretary: 15,
          CreatureTypeIds.teenager: 5,
          CreatureTypeIds.cop: 5,
          if (deathSquadsActive) CreatureTypeIds.deathSquad: 2,
          if (gangUnitsActive) CreatureTypeIds.gangUnit: 2,
          CreatureTypeIds.liberalJudge: 1,
          CreatureTypeIds.conservativeJudge: 1,
          CreatureTypeIds.agent: 1,
          if (ccsActive) CreatureTypeIds.ccsVigilante: 40,
          CreatureTypeIds.radioPersonality: 1,
          CreatureTypeIds.newsAnchor: 1,
          CreatureTypeIds.lawyer: 5,
          CreatureTypeIds.doctor: 5,
          CreatureTypeIds.psychologist: 1,
          CreatureTypeIds.nurse: 5,
          CreatureTypeIds.sewerWorker: 1,
          CreatureTypeIds.collegeStudent: 30,
          CreatureTypeIds.musician: 5,
          CreatureTypeIds.mathematician: 5,
          CreatureTypeIds.teacher: 5,
          CreatureTypeIds.highschoolDropout: 1,
          CreatureTypeIds.bum: 1,
          if (mutantsPossible) CreatureTypeIds.mutant: 1,
          if (mutantsCommon) CreatureTypeIds.mutant: 10,
          CreatureTypeIds.gangMember: 5,
          CreatureTypeIds.crackhead: 1,
          CreatureTypeIds.priest: 1,
          CreatureTypeIds.engineer: 5,
          CreatureTypeIds.fastFoodWorker: 5,
          CreatureTypeIds.baker: 1,
          CreatureTypeIds.barista: 10,
          CreatureTypeIds.bartender: 1,
          CreatureTypeIds.telemarketer: 5,
          CreatureTypeIds.carSalesman: 3,
          CreatureTypeIds.officeWorker: 10,
          CreatureTypeIds.footballCoach: 1,
          CreatureTypeIds.cheerleader: 1,
          CreatureTypeIds.sexWorker: 1,
          CreatureTypeIds.mailman: 1,
          CreatureTypeIds.garbageman: 1,
          CreatureTypeIds.plumber: 1,
          CreatureTypeIds.chef: 1,
          CreatureTypeIds.constructionWorker: 3,
          CreatureTypeIds.amateurMagician: 1,
          CreatureTypeIds.angryRuralMob: 1,
          CreatureTypeIds.soldier: 1,
          CreatureTypeIds.veteran: 3,
          if (nineteenEightyFour) CreatureTypeIds.educator: 1,
          if (!nineteenEightyFour) CreatureTypeIds.prisonGuard: 1,
          CreatureTypeIds.hippie: 1,
          CreatureTypeIds.punk: 2,
          CreatureTypeIds.emo: 2,
          CreatureTypeIds.goth: 1,
          CreatureTypeIds.artCritic: 1,
          CreatureTypeIds.musicCritic: 1,
          CreatureTypeIds.author: 1,
          CreatureTypeIds.journalist: 1,
          CreatureTypeIds.socialite: 1,
          CreatureTypeIds.biker: 1,
          CreatureTypeIds.trucker: 1,
          CreatureTypeIds.taxiDriver: 1,
          CreatureTypeIds.programmer: 5,
          CreatureTypeIds.retiree: 3,
          CreatureTypeIds.painter: 1,
          CreatureTypeIds.sculptor: 1,
          CreatureTypeIds.dancer: 1,
          CreatureTypeIds.photographer: 1,
          CreatureTypeIds.cameraman: 1,
          CreatureTypeIds.hairstylist: 1,
          CreatureTypeIds.fashionDesigner: 1,
          CreatureTypeIds.clerk: 1,
          CreatureTypeIds.thief: 1,
          CreatureTypeIds.actor: 1,
          CreatureTypeIds.yogaInstructor: 1,
          CreatureTypeIds.martialArtist: 1,
          CreatureTypeIds.athlete: 1,
          CreatureTypeIds.firefighter: 1,
          CreatureTypeIds.locksmith: 1,
        });
      case SiteType.veganCoOp:
        weights.addAll({
          CreatureTypeIds.teenager: 5,
          CreatureTypeIds.liberalJudge: 1,
          CreatureTypeIds.collegeStudent: 50,
          CreatureTypeIds.musician: 20,
          CreatureTypeIds.mathematician: 1,
          CreatureTypeIds.teacher: 1,
          CreatureTypeIds.highschoolDropout: 10,
          CreatureTypeIds.bum: 1,
          if (mutantsPossible) CreatureTypeIds.mutant: 1,
          if (mutantsCommon) CreatureTypeIds.mutant: 10,
          CreatureTypeIds.hippie: 50,
          CreatureTypeIds.punk: 10,
          CreatureTypeIds.emo: 10,
          CreatureTypeIds.goth: 5,
          CreatureTypeIds.artCritic: 1,
          CreatureTypeIds.musicCritic: 1,
          CreatureTypeIds.author: 1,
          CreatureTypeIds.journalist: 1,
          CreatureTypeIds.retiree: 1,
          CreatureTypeIds.painter: 1,
          CreatureTypeIds.sculptor: 1,
          CreatureTypeIds.dancer: 1,
          CreatureTypeIds.photographer: 1,
          CreatureTypeIds.yogaInstructor: 2,
          CreatureTypeIds.cheerleader: 1,
        });
      case SiteType.internetCafe:
        weights.addAll({
          CreatureTypeIds.labTech: 5,
          CreatureTypeIds.corporateManager: 3,
          CreatureTypeIds.teenager: 15,
          CreatureTypeIds.lawyer: 3,
          CreatureTypeIds.collegeStudent: 25,
          CreatureTypeIds.musician: 2,
          CreatureTypeIds.mathematician: 1,
          CreatureTypeIds.teacher: 5,
          CreatureTypeIds.engineer: 5,
          CreatureTypeIds.doctor: 1,
          CreatureTypeIds.barista: 10,
          CreatureTypeIds.carSalesman: 2,
          CreatureTypeIds.officeWorker: 15,
          CreatureTypeIds.secretary: 5,
          CreatureTypeIds.hippie: 1,
          CreatureTypeIds.punk: 3,
          CreatureTypeIds.emo: 3,
          CreatureTypeIds.goth: 3,
          CreatureTypeIds.programmer: 15,
          CreatureTypeIds.retiree: 5,
          CreatureTypeIds.painter: 1,
          CreatureTypeIds.sculptor: 1,
          CreatureTypeIds.dancer: 1,
          CreatureTypeIds.photographer: 1,
          CreatureTypeIds.cameraman: 1,
          CreatureTypeIds.clerk: 1,
          CreatureTypeIds.locksmith: 1,
        });
      case SiteType.tenement:
        encnum = 1;
        if (mode == GameMode.site && !levelMap[locx][locy][locz].restricted) {
          encnum = 4;
        }
        weights.addAll({
          CreatureTypeIds.securityGuard: 1,
          CreatureTypeIds.labTech: 1,
          CreatureTypeIds.janitor: 3,
          if (nonUnionWorkers) CreatureTypeIds.nonUnionWorker: 1,
          CreatureTypeIds.secretary: 2,
          if (unionWorkers) CreatureTypeIds.unionWorker: 1,
          CreatureTypeIds.teenager: 5,
          CreatureTypeIds.sewerWorker: 1,
          CreatureTypeIds.collegeStudent: 1,
          CreatureTypeIds.musician: 1,
          CreatureTypeIds.mathematician: 1,
          CreatureTypeIds.teacher: 1,
          CreatureTypeIds.highschoolDropout: 3,
          CreatureTypeIds.bum: 3,
          if (mutantsPossible) CreatureTypeIds.mutant: 2,
          if (mutantsCommon) CreatureTypeIds.mutant: 5,
          CreatureTypeIds.gangMember: 3,
          CreatureTypeIds.crackhead: 3,
          CreatureTypeIds.punk: 1,
          CreatureTypeIds.fastFoodWorker: 1,
          CreatureTypeIds.barista: 1,
          CreatureTypeIds.bartender: 1,
          CreatureTypeIds.telemarketer: 1,
          CreatureTypeIds.carSalesman: 1,
          CreatureTypeIds.officeWorker: 1,
          CreatureTypeIds.sexWorker: 3,
          CreatureTypeIds.mailman: 1,
          CreatureTypeIds.garbageman: 1,
          CreatureTypeIds.constructionWorker: 1,
          CreatureTypeIds.amateurMagician: 1,
          CreatureTypeIds.angryRuralMob: 1,
          CreatureTypeIds.soldier: 1,
          CreatureTypeIds.veteran: 2,
          if (nineteenEightyFour) CreatureTypeIds.educator: 1,
          if (!nineteenEightyFour) CreatureTypeIds.prisonGuard: 1,
          CreatureTypeIds.hippie: 1,
          CreatureTypeIds.biker: 1,
          CreatureTypeIds.taxiDriver: 1,
          CreatureTypeIds.retiree: 1,
          CreatureTypeIds.painter: 1,
          CreatureTypeIds.sculptor: 1,
          CreatureTypeIds.dancer: 1,
          CreatureTypeIds.photographer: 1,
          CreatureTypeIds.hairstylist: 1,
          CreatureTypeIds.clerk: 1,
          CreatureTypeIds.thief: 1,
          CreatureTypeIds.actor: 1,
          CreatureTypeIds.firefighter: 1,
          CreatureTypeIds.locksmith: 1,
        });
      case SiteType.apartment:
        encnum = 1;
        if (mode == GameMode.site && !levelMap[locx][locy][locz].restricted) {
          encnum = 4;
        }
        weights.addAll({
          CreatureTypeIds.securityGuard: 1,
          CreatureTypeIds.labTech: 1,
          CreatureTypeIds.corporateManager: 1,
          CreatureTypeIds.janitor: 1,
          if (nonUnionWorkers) CreatureTypeIds.nonUnionWorker: 1,
          CreatureTypeIds.secretary: 1,
          if (unionWorkers) CreatureTypeIds.unionWorker: 1,
          CreatureTypeIds.teenager: 3,
          CreatureTypeIds.cop: 1,
          if (deathSquadsActive) CreatureTypeIds.deathSquad: 1,
          if (gangUnitsActive) CreatureTypeIds.gangUnit: 1,
          CreatureTypeIds.lawyer: 1,
          CreatureTypeIds.sewerWorker: 1,
          CreatureTypeIds.collegeStudent: 1,
          CreatureTypeIds.musician: 1,
          CreatureTypeIds.mathematician: 1,
          CreatureTypeIds.teacher: 1,
          CreatureTypeIds.priest: 1,
          CreatureTypeIds.engineer: 1,
          CreatureTypeIds.fastFoodWorker: 1,
          CreatureTypeIds.baker: 1,
          CreatureTypeIds.barista: 1,
          CreatureTypeIds.bartender: 1,
          CreatureTypeIds.telemarketer: 1,
          CreatureTypeIds.carSalesman: 1,
          CreatureTypeIds.officeWorker: 1,
          CreatureTypeIds.footballCoach: 1,
          CreatureTypeIds.cheerleader: 1,
          CreatureTypeIds.mailman: 1,
          CreatureTypeIds.doctor: 1,
          CreatureTypeIds.psychologist: 1,
          CreatureTypeIds.nurse: 1,
          CreatureTypeIds.garbageman: 1,
          CreatureTypeIds.plumber: 1,
          CreatureTypeIds.chef: 1,
          CreatureTypeIds.constructionWorker: 1,
          CreatureTypeIds.amateurMagician: 1,
          CreatureTypeIds.soldier: 1,
          CreatureTypeIds.veteran: 2,
          if (nineteenEightyFour) CreatureTypeIds.educator: 1,
          if (!nineteenEightyFour) CreatureTypeIds.prisonGuard: 1,
          CreatureTypeIds.hippie: 1,
          CreatureTypeIds.punk: 1,
          CreatureTypeIds.emo: 1,
          CreatureTypeIds.goth: 1,
          CreatureTypeIds.artCritic: 1,
          CreatureTypeIds.musicCritic: 1,
          CreatureTypeIds.author: 1,
          CreatureTypeIds.journalist: 1,
          CreatureTypeIds.taxiDriver: 1,
          CreatureTypeIds.programmer: 1,
          CreatureTypeIds.retiree: 1,
          CreatureTypeIds.painter: 1,
          CreatureTypeIds.sculptor: 1,
          CreatureTypeIds.dancer: 1,
          CreatureTypeIds.photographer: 1,
          CreatureTypeIds.cameraman: 1,
          CreatureTypeIds.hairstylist: 1,
          CreatureTypeIds.clerk: 1,
          CreatureTypeIds.thief: 1,
          CreatureTypeIds.actor: 1,
          CreatureTypeIds.yogaInstructor: 1,
          CreatureTypeIds.martialArtist: 1,
          CreatureTypeIds.athlete: 1,
          CreatureTypeIds.firefighter: 1,
          CreatureTypeIds.locksmith: 1,
        });
      case SiteType.bank:
        if (mode == GameMode.site &&
            !(levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0)) {
          encnum = 6;
          weights.addAll({
            CreatureTypeIds.labTech: 1,
            if (nonUnionWorkers) CreatureTypeIds.nonUnionWorker: 1,
            if (unionWorkers) CreatureTypeIds.unionWorker: 1,
            CreatureTypeIds.teenager: 3,
            CreatureTypeIds.janitor: 1,
            CreatureTypeIds.secretary: 1,
            CreatureTypeIds.cop: 1,
            if (deathSquadsActive) CreatureTypeIds.deathSquad: 1,
            if (gangUnitsActive) CreatureTypeIds.gangUnit: 1,
            CreatureTypeIds.lawyer: 1,
            CreatureTypeIds.sewerWorker: 1,
            CreatureTypeIds.collegeStudent: 1,
            CreatureTypeIds.musician: 1,
            CreatureTypeIds.mathematician: 1,
            CreatureTypeIds.teacher: 1,
            CreatureTypeIds.priest: 1,
            CreatureTypeIds.engineer: 1,
            CreatureTypeIds.fastFoodWorker: 1,
            CreatureTypeIds.baker: 1,
            CreatureTypeIds.barista: 1,
            CreatureTypeIds.bartender: 1,
            CreatureTypeIds.telemarketer: 1,
            CreatureTypeIds.carSalesman: 1,
            CreatureTypeIds.officeWorker: 1,
            CreatureTypeIds.footballCoach: 1,
            CreatureTypeIds.mailman: 1,
            CreatureTypeIds.doctor: 1,
            CreatureTypeIds.psychologist: 1,
            CreatureTypeIds.nurse: 1,
            CreatureTypeIds.garbageman: 1,
            CreatureTypeIds.plumber: 1,
            CreatureTypeIds.chef: 1,
            CreatureTypeIds.constructionWorker: 1,
            CreatureTypeIds.amateurMagician: 1,
            CreatureTypeIds.soldier: 1,
            CreatureTypeIds.veteran: 2,
            if (nineteenEightyFour) CreatureTypeIds.educator: 1,
            if (!nineteenEightyFour) CreatureTypeIds.prisonGuard: 1,
            CreatureTypeIds.hippie: 1,
            CreatureTypeIds.artCritic: 1,
            CreatureTypeIds.musicCritic: 1,
            CreatureTypeIds.author: 1,
            CreatureTypeIds.journalist: 1,
            CreatureTypeIds.taxiDriver: 1,
            CreatureTypeIds.programmer: 1,
            CreatureTypeIds.retiree: 1,
            CreatureTypeIds.painter: 1,
            CreatureTypeIds.sculptor: 1,
            CreatureTypeIds.dancer: 1,
            CreatureTypeIds.photographer: 1,
            CreatureTypeIds.cameraman: 1,
            CreatureTypeIds.hairstylist: 1,
            CreatureTypeIds.clerk: 1,
            CreatureTypeIds.thief: 1,
            CreatureTypeIds.actor: 1,
            CreatureTypeIds.yogaInstructor: 1,
            CreatureTypeIds.martialArtist: 1,
            CreatureTypeIds.athlete: 1,
            CreatureTypeIds.firefighter: 1,
            CreatureTypeIds.locksmith: 1,
          });
        } else {
          weights.addAll({
            if (sec) CreatureTypeIds.merc: 2000,
            if (!sec) CreatureTypeIds.securityGuard: 1000,
            CreatureTypeIds.bankManager: 200,
            CreatureTypeIds.janitor: 100,
            CreatureTypeIds.thief: 5,
          });
        }
      case SiteType.upscaleApartment:
        if (mode == GameMode.site &&
            !(levelMap[locx][locy][locz].flag & SITEBLOCK_RESTRICTED != 0)) {
          if (sec) {
            weights.add(CreatureTypeIds.merc, 2000);
          } else {
            weights.add(CreatureTypeIds.securityGuard, 100);
          }
          if (sec) weights.add(CreatureTypeIds.guardDog, 50);
        }
        encnum = 1;
        if (mode == GameMode.site && !levelMap[locx][locy][locz].restricted) {
          encnum = 4;
        }
        weights.addAll({
          CreatureTypeIds.eminentScientist: 1,
          CreatureTypeIds.corporateManager: 5,
          CreatureTypeIds.janitor: 5,
          CreatureTypeIds.secretary: 1,
          CreatureTypeIds.teenager: 3,
          CreatureTypeIds.liberalJudge: 1,
          CreatureTypeIds.conservativeJudge: 1,
          CreatureTypeIds.radioPersonality: 1,
          CreatureTypeIds.newsAnchor: 1,
          CreatureTypeIds.lawyer: 5,
          CreatureTypeIds.doctor: 5,
          CreatureTypeIds.psychologist: 1,
          CreatureTypeIds.nurse: 1,
          CreatureTypeIds.collegeStudent: 1,
          CreatureTypeIds.musician: 1,
          CreatureTypeIds.sexWorker: 3,
          CreatureTypeIds.mailman: 1,
          CreatureTypeIds.artCritic: 1,
          CreatureTypeIds.musicCritic: 1,
          CreatureTypeIds.author: 1,
          CreatureTypeIds.journalist: 1,
          CreatureTypeIds.socialite: 2,
          CreatureTypeIds.painter: 1,
          CreatureTypeIds.sculptor: 1,
          CreatureTypeIds.dancer: 1,
          CreatureTypeIds.photographer: 1,
          CreatureTypeIds.fashionDesigner: 1,
          CreatureTypeIds.thief: 1,
          CreatureTypeIds.actor: 1,
          CreatureTypeIds.athlete: 1,
          CreatureTypeIds.locksmith: 1,
        });
      case SiteType.cosmeticsLab:
        weights.addAll({
          CreatureTypeIds.securityGuard: sec ? 100 : 3,
          CreatureTypeIds.labTech: 10,
          CreatureTypeIds.eminentScientist: 1,
          CreatureTypeIds.corporateManager: 1,
          CreatureTypeIds.janitor: 10,
          CreatureTypeIds.secretary: 10,
          CreatureTypeIds.officeWorker: 10,
        });
      case SiteType.nuclearPlant:
        weights.addAll({
          CreatureTypeIds.securityGuard: sec ? 100 : 10,
          CreatureTypeIds.labTech: 10,
          CreatureTypeIds.eminentScientist: 1,
          CreatureTypeIds.corporateManager: 1,
          CreatureTypeIds.janitor: 10,
          CreatureTypeIds.secretary: 10,
          CreatureTypeIds.officeWorker: 10,
        });
      case SiteType.geneticsLab:
        weights.addAll({
          if (sec) CreatureTypeIds.guardDog: 25,
          CreatureTypeIds.securityGuard: sec ? 100 : 3,
          CreatureTypeIds.labTech: 10,
          CreatureTypeIds.eminentScientist: 1,
          CreatureTypeIds.corporateManager: 1,
          CreatureTypeIds.doctor: 1,
          CreatureTypeIds.janitor: 10,
          CreatureTypeIds.secretary: 10,
          CreatureTypeIds.officeWorker: 10,
        });
      case SiteType.policeStation:
        weights.addAll({
          CreatureTypeIds.policeChief: 20,
          CreatureTypeIds.labTech: 1,
          CreatureTypeIds.corporateManager: 1,
          CreatureTypeIds.janitor: 50,
          if (nonUnionWorkers) CreatureTypeIds.nonUnionWorker: 1,
          CreatureTypeIds.secretary: 1,
          if (unionWorkers) CreatureTypeIds.unionWorker: 1,
          CreatureTypeIds.teenager: 5,
          CreatureTypeIds.cop: sec ? 1000 : 500,
          if (deathSquadsActive) CreatureTypeIds.deathSquad: 400,
          if (gangUnitsActive) CreatureTypeIds.gangUnit: 400,
          CreatureTypeIds.liberalJudge: 1,
          CreatureTypeIds.conservativeJudge: 1,
          CreatureTypeIds.agent: 1,
          CreatureTypeIds.radioPersonality: 1,
          CreatureTypeIds.newsAnchor: 1,
          CreatureTypeIds.lawyer: 1,
          CreatureTypeIds.doctor: 1,
          CreatureTypeIds.psychologist: 1,
          CreatureTypeIds.nurse: 1,
          CreatureTypeIds.sewerWorker: 1,
          CreatureTypeIds.collegeStudent: 1,
          CreatureTypeIds.musician: 1,
          CreatureTypeIds.mathematician: 1,
          CreatureTypeIds.teacher: 1,
          CreatureTypeIds.highschoolDropout: 10,
          CreatureTypeIds.bum: 10,
          if (mutantsPossible) CreatureTypeIds.mutant: 2,
          if (mutantsCommon) CreatureTypeIds.mutant: 5,
          CreatureTypeIds.gangMember: 10,
          CreatureTypeIds.crackhead: 10,
          CreatureTypeIds.cheerleader: 1,
          CreatureTypeIds.punk: 5,
          CreatureTypeIds.goth: 2,
          CreatureTypeIds.emo: 2,
          CreatureTypeIds.priest: 5,
          CreatureTypeIds.engineer: 1,
          CreatureTypeIds.fastFoodWorker: 1,
          CreatureTypeIds.baker: 1,
          CreatureTypeIds.barista: 1,
          CreatureTypeIds.bartender: 1,
          CreatureTypeIds.telemarketer: 1,
          CreatureTypeIds.carSalesman: 1,
          CreatureTypeIds.officeWorker: 1,
          CreatureTypeIds.footballCoach: 1,
          CreatureTypeIds.sexWorker: 10,
          CreatureTypeIds.mailman: 1,
          CreatureTypeIds.garbageman: 1,
          CreatureTypeIds.plumber: 1,
          CreatureTypeIds.chef: 1,
          CreatureTypeIds.constructionWorker: 1,
          CreatureTypeIds.amateurMagician: 1,
          CreatureTypeIds.angryRuralMob: 1,
          CreatureTypeIds.soldier: 1,
          CreatureTypeIds.veteran: 2,
          if (nineteenEightyFour) CreatureTypeIds.educator: 1,
          if (!nineteenEightyFour) CreatureTypeIds.prisonGuard: 1,
          CreatureTypeIds.hippie: 1,
          CreatureTypeIds.artCritic: 1,
          CreatureTypeIds.musicCritic: 1,
          CreatureTypeIds.author: 1,
          CreatureTypeIds.journalist: 1,
          CreatureTypeIds.socialite: 1,
          CreatureTypeIds.biker: 5,
          CreatureTypeIds.trucker: 1,
          CreatureTypeIds.taxiDriver: 1,
          CreatureTypeIds.programmer: 1,
          CreatureTypeIds.nun: 1,
          CreatureTypeIds.retiree: 1,
          CreatureTypeIds.painter: 1,
          CreatureTypeIds.sculptor: 1,
          CreatureTypeIds.dancer: 1,
          CreatureTypeIds.photographer: 1,
          CreatureTypeIds.cameraman: 1,
          CreatureTypeIds.hairstylist: 1,
          CreatureTypeIds.fashionDesigner: 1,
          CreatureTypeIds.clerk: 1,
          CreatureTypeIds.thief: 10,
          CreatureTypeIds.actor: 1,
          CreatureTypeIds.yogaInstructor: 1,
          CreatureTypeIds.martialArtist: 1,
          CreatureTypeIds.athlete: 1,
          CreatureTypeIds.firefighter: 1,
          CreatureTypeIds.locksmith: 5, //Forensic locksmiths
        });
      case SiteType.courthouse:
        weights.addAll({
          CreatureTypeIds.cop: sec ? 2000 : 200,
          CreatureTypeIds.labTech: 1,
          CreatureTypeIds.eminentScientist: 1,
          CreatureTypeIds.corporateManager: 1,
          CreatureTypeIds.janitor: 50,
          if (nonUnionWorkers) CreatureTypeIds.nonUnionWorker: 1,
          CreatureTypeIds.secretary: 50,
          if (unionWorkers) CreatureTypeIds.unionWorker: 1,
          CreatureTypeIds.teenager: 1,
          if (deathSquadsActive) CreatureTypeIds.deathSquad: 80,
          if (gangUnitsActive) CreatureTypeIds.gangUnit: 80,
          CreatureTypeIds.liberalJudge: 20,
          CreatureTypeIds.conservativeJudge: 20,
          CreatureTypeIds.agent: 1,
          CreatureTypeIds.radioPersonality: 1,
          CreatureTypeIds.newsAnchor: 1,
          CreatureTypeIds.lawyer: 200,
          CreatureTypeIds.psychologist: 20,
          CreatureTypeIds.sewerWorker: 1,
          CreatureTypeIds.collegeStudent: 1,
          CreatureTypeIds.musician: 1,
          CreatureTypeIds.mathematician: 1,
          CreatureTypeIds.teacher: 1,
          CreatureTypeIds.highschoolDropout: 1,
          CreatureTypeIds.bum: 1,
          if (mutantsPossible) CreatureTypeIds.mutant: 1,
          if (mutantsCommon) CreatureTypeIds.mutant: 2,
          CreatureTypeIds.gangMember: 1,
          CreatureTypeIds.crackhead: 1,
          CreatureTypeIds.cheerleader: 1,
          CreatureTypeIds.punk: 1,
          CreatureTypeIds.goth: 1,
          CreatureTypeIds.emo: 1,
          CreatureTypeIds.priest: 1,
          CreatureTypeIds.engineer: 1,
          CreatureTypeIds.fastFoodWorker: 1,
          CreatureTypeIds.baker: 1,
          CreatureTypeIds.barista: 1,
          CreatureTypeIds.bartender: 1,
          CreatureTypeIds.telemarketer: 1,
          CreatureTypeIds.carSalesman: 2,
          CreatureTypeIds.officeWorker: 50,
          CreatureTypeIds.footballCoach: 1,
          CreatureTypeIds.sexWorker: 1,
          CreatureTypeIds.mailman: 1,
          CreatureTypeIds.garbageman: 1,
          CreatureTypeIds.plumber: 1,
          CreatureTypeIds.chef: 1,
          CreatureTypeIds.constructionWorker: 1,
          CreatureTypeIds.amateurMagician: 1,
          CreatureTypeIds.angryRuralMob: 1,
          CreatureTypeIds.soldier: 1,
          CreatureTypeIds.veteran: 2,
          if (nineteenEightyFour) CreatureTypeIds.educator: 1,
          if (!nineteenEightyFour) CreatureTypeIds.prisonGuard: 1,
          CreatureTypeIds.hippie: 1,
          CreatureTypeIds.artCritic: 1,
          CreatureTypeIds.musicCritic: 1,
          CreatureTypeIds.author: 1,
          CreatureTypeIds.journalist: 1,
          CreatureTypeIds.socialite: 1,
          CreatureTypeIds.biker: 1,
          CreatureTypeIds.trucker: 1,
          CreatureTypeIds.taxiDriver: 1,
          CreatureTypeIds.programmer: 1,
          CreatureTypeIds.nun: 1,
          CreatureTypeIds.retiree: 1,
          CreatureTypeIds.painter: 1,
          CreatureTypeIds.sculptor: 1,
          CreatureTypeIds.dancer: 1,
          CreatureTypeIds.photographer: 1,
          CreatureTypeIds.cameraman: 1,
          CreatureTypeIds.hairstylist: 1,
          CreatureTypeIds.fashionDesigner: 1,
          CreatureTypeIds.clerk: 1,
          CreatureTypeIds.thief: 3,
          CreatureTypeIds.actor: 1,
          CreatureTypeIds.yogaInstructor: 1,
          CreatureTypeIds.martialArtist: 1,
          CreatureTypeIds.athlete: 1,
          CreatureTypeIds.firefighter: 1,
          CreatureTypeIds.locksmith: 5,
        });
      case SiteType.fireStation:
        weights.addAll({
          CreatureTypeIds.janitor: 5,
          CreatureTypeIds.secretary: 2,
          if (sec && !deathSquadsActive && !gangUnitsActive)
            CreatureTypeIds.cop: 50,
          if (sec && deathSquadsActive) CreatureTypeIds.deathSquad: 50,
          if (sec && gangUnitsActive) CreatureTypeIds.gangUnit: 50,
          CreatureTypeIds.nurse: 2,
          CreatureTypeIds.priest: 5,
          CreatureTypeIds.journalist: 1,
          CreatureTypeIds.photographer: 1,
          CreatureTypeIds.firefighter: 100,
        });
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
        weights.addAll({
          CreatureTypeIds.agent: sec ? 1000 : 100,
          CreatureTypeIds.janitor: 50,
          CreatureTypeIds.secretary: 50,
          if (nineteenEightyFour) CreatureTypeIds.educator: 50,
          if (sec) CreatureTypeIds.guardDog: 450,
          CreatureTypeIds.guardDog: 50,
          CreatureTypeIds.mathematician: 5,
          CreatureTypeIds.programmer: 5,
        });
      case SiteType.armyBase:
        weights.addAll({
          CreatureTypeIds.soldier: 750,
          if (sec) CreatureTypeIds.guardDog: 230,
          CreatureTypeIds.guardDog: 20,
          CreatureTypeIds.militaryPolice: 100,
          if (sec) CreatureTypeIds.militaryPolice: 100,
          CreatureTypeIds.seal: 20,
        });
      case SiteType.sweatshop:
        weights.addAll({
          CreatureTypeIds.securityGuard: sec ? 1000 : 100,
          CreatureTypeIds.corporateManager: 5,
          CreatureTypeIds.sweatshopWorker: 800,
        });
      case SiteType.dirtyIndustry:
        weights.addAll({
          if (sec) CreatureTypeIds.securityGuard: 100,
          CreatureTypeIds.corporateManager: 1,
          CreatureTypeIds.janitor: 10,
          CreatureTypeIds.secretary: 10,
          CreatureTypeIds.engineer: 10,
          if (laws[Law.labor] == DeepAlignment.archConservative)
            CreatureTypeIds.childLaborer: 160,
          if (laws[Law.labor] == DeepAlignment.conservative)
            CreatureTypeIds.nonUnionWorker: 160,
          if (laws[Law.labor] == DeepAlignment.moderate)
            CreatureTypeIds.nonUnionWorker: 80,
          if (laws[Law.labor] == DeepAlignment.liberal)
            CreatureTypeIds.nonUnionWorker: 50,
          if (laws[Law.labor] == DeepAlignment.liberal)
            CreatureTypeIds.unionWorker: 110,
          if (laws[Law.labor] == DeepAlignment.eliteLiberal)
            CreatureTypeIds.unionWorker: 160,
        });
      case SiteType.corporateHQ:
        weights.addAll({
          if (sec) CreatureTypeIds.guardDog: 100,
          CreatureTypeIds.securityGuard: sec ? 400 : 40,
          CreatureTypeIds.corporateManager: 20,
          CreatureTypeIds.janitor: 20,
          CreatureTypeIds.secretary: 40,
          CreatureTypeIds.conservativeJudge: 1,
          CreatureTypeIds.lawyer: 20,
          CreatureTypeIds.priest: 1,
          CreatureTypeIds.officeWorker: 80,
          CreatureTypeIds.sexWorker: 1,
        });
      case SiteType.ceoHouse:
        weights.addAll({
          if (sec) CreatureTypeIds.merc: 100,
          CreatureTypeIds.guardDog: sec ? 50 : 5,
          CreatureTypeIds.servant: 30,
          CreatureTypeIds.secretary: 5,
          CreatureTypeIds.teenager: 5,
          CreatureTypeIds.genetic: 1,
          CreatureTypeIds.lawyer: 5,
          CreatureTypeIds.priest: 1,
          CreatureTypeIds.sexWorker: 1,
        });
      case SiteType.amRadioStation:
        weights.addAll({
          CreatureTypeIds.securityGuard: sec ? 100 : 10,
          CreatureTypeIds.corporateManager: 2,
          CreatureTypeIds.janitor: 10,
          CreatureTypeIds.secretary: 10,
          CreatureTypeIds.radioPersonality: 2,
          CreatureTypeIds.officeWorker: 40,
        });
      case SiteType.cableNewsStation:
        weights.addAll({
          CreatureTypeIds.securityGuard: sec ? 100 : 10,
          CreatureTypeIds.corporateManager: 5,
          CreatureTypeIds.janitor: 20,
          CreatureTypeIds.secretary: 20,
          CreatureTypeIds.newsAnchor: 2,
          CreatureTypeIds.officeWorker: 40,
          CreatureTypeIds.photographer: 5,
          CreatureTypeIds.cameraman: 5,
        });
      case SiteType.homelessEncampment:
      default:
        if (!lcs) {
          weights.addAll({
            CreatureTypeIds.janitor: 5,
            CreatureTypeIds.teenager: 20,
            CreatureTypeIds.musician: 3,
            CreatureTypeIds.mathematician: 1,
            CreatureTypeIds.bum: 200,
            if (mutantsPossible) CreatureTypeIds.mutant: 2,
            if (mutantsCommon) CreatureTypeIds.mutant: 50,
            CreatureTypeIds.gangMember: 5,
            CreatureTypeIds.crackhead: 50,
            CreatureTypeIds.sexWorker: 10,
            CreatureTypeIds.amateurMagician: 1,
            CreatureTypeIds.hippie: 1,
            CreatureTypeIds.punk: 1,
            CreatureTypeIds.goth: 1,
            CreatureTypeIds.emo: 1,
            CreatureTypeIds.nurse: 5,
            CreatureTypeIds.biker: 1,
            CreatureTypeIds.painter: 1,
            CreatureTypeIds.sculptor: 1,
            CreatureTypeIds.dancer: 1,
            CreatureTypeIds.photographer: 1,
            CreatureTypeIds.thief: 5,
            CreatureTypeIds.actor: 1,
          });
        }
    }
    if (weights.isNotEmpty) {
      for (int n = 0; n < lcsRandom(encnum - 1) + 1; n++) {
        encounter.add(Creature.fromId(lcsRandomWeighted(weights)));
      }
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
        if (freeslots < 4) return false;

        num = lcsRandom(3) + 4;

        for (int i = 0; i < min(num, freeslots); i++) {
          Creature e;

          if (activeSiteUnderSiege) {
            switch (activeSite!.siege.activeSiegeType) {
              case SiegeType.police:
                if (activeSite!.siege.escalationState ==
                    SiegeEscalation.police) {
                  if (deathSquadsActive) {
                    e = Creature.fromId(CreatureTypeIds.deathSquad);
                  } else {
                    e = Creature.fromId(CreatureTypeIds.swat);
                  }
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
              case SiegeType.angryRuralMob:
                e = Creature.fromId(lcsRandomWeighted({
                  CreatureTypeIds.angryRuralMob: 9,
                  CreatureTypeIds.neoNazi: 1,
                }));
                ensureIsArmed(e);
              case SiegeType.corporateMercs:
                e = Creature.fromId(CreatureTypeIds.merc);
                ensureIsArmed(e);
              case SiegeType.ccs:
                e = Creature.fromId(CreatureTypeIds.ccsVigilante);
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
                e = Creature.fromId(CreatureTypeIds.angryRuralMob);
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
                  e = Creature.fromId(CreatureTypeIds.ccsVigilante);
                } else if (deathSquadsActive) {
                  e = Creature.fromId(CreatureTypeIds.deathSquad);
                } else {
                  e = Creature.fromId(CreatureTypeIds.swat);
                }
            }
          }

          encounter.add(e);

          if (type == SIEGEFLAG_UNIT_DAMAGED) {
            e.blood -= lcsRandom(50) + 1;
            e.body.parts.random.bleeding = 1;
          }
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
          ["WEAPON_9MM_HANDGUN", "WEAPON_22_REVOLVER"].random, 4);
    } else if (randomint < (lightgun + mediumgun)) {
      enemy.giveWeaponAndAmmo(
          [
            "WEAPON_44_REVOLVER",
            "WEAPON_45_HANDGUN",
            "WEAPON_AR15",
            "WEAPON_PUMP_SHOTGUN",
          ].random,
          4);
    } else {
      enemy.giveWeaponAndAmmo(
          [
            "WEAPON_AK102",
            "WEAPON_M4",
            "WEAPON_M7",
            "WEAPON_MP5",
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
