import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

bool testWorkLocation(CreatureType type, Site location) {
  List<SiteType> okaySite = [];
  switch (type.id) {
    case CreatureTypeIds.bouncer:
      okaySite.add(SiteType.barAndGrill);
    case CreatureTypeIds.president:
      okaySite.add(SiteType.whiteHouse);
    case CreatureTypeIds.corporateCEO:
      okaySite.add(SiteType.corporateHQ);
    case CreatureTypeIds.securityGuard:
      okaySite.addAll([
        SiteType.upscaleApartment,
        SiteType.cosmeticsLab,
        SiteType.geneticsLab,
        SiteType.courthouse,
        SiteType.intelligenceHQ,
        SiteType.sweatshop,
        SiteType.dirtyIndustry,
        SiteType.nuclearPlant,
        SiteType.corporateHQ,
        SiteType.ceoHouse,
        SiteType.amRadioStation,
        SiteType.cableNewsStation,
        SiteType.barAndGrill,
        SiteType.bank,
      ]);
    case CreatureTypeIds.bankManager:
    case CreatureTypeIds.bankTeller:
      okaySite.add(SiteType.bank);
    case CreatureTypeIds.labTech:
    case CreatureTypeIds.eminentScientist:
      okaySite.addAll([
        SiteType.cosmeticsLab,
        SiteType.geneticsLab,
        SiteType.nuclearPlant,
        SiteType.universityHospital,
      ]);
    case CreatureTypeIds.corporateManager:
      okaySite.addAll([
        SiteType.cosmeticsLab,
        SiteType.geneticsLab,
        SiteType.sweatshop,
        SiteType.dirtyIndustry,
        SiteType.nuclearPlant,
        SiteType.corporateHQ,
        SiteType.amRadioStation,
        SiteType.cableNewsStation,
      ]);
    case CreatureTypeIds.servant:
      okaySite.add(SiteType.ceoHouse);
    case CreatureTypeIds.janitor:
      okaySite.addAll([
        SiteType.tenement,
        SiteType.apartment,
        SiteType.upscaleApartment,
        SiteType.cosmeticsLab,
        SiteType.geneticsLab,
        SiteType.clinic,
        SiteType.universityHospital,
        SiteType.policeStation,
        SiteType.courthouse,
        SiteType.prison,
        SiteType.intelligenceHQ,
        SiteType.dirtyIndustry,
        SiteType.nuclearPlant,
        SiteType.corporateHQ,
        SiteType.amRadioStation,
        SiteType.cableNewsStation,
        SiteType.pawnShop,
        SiteType.drugHouse,
        SiteType.juiceBar,
        SiteType.barAndGrill,
        SiteType.latteStand,
        SiteType.veganCoOp,
        SiteType.internetCafe,
        SiteType.departmentStore,
        SiteType.oubliette,
        SiteType.fireStation,
      ]);
    case CreatureTypeIds.sweatshopWorker:
      okaySite.add(SiteType.sweatshop);
    case CreatureTypeIds.unionWorker:
    case CreatureTypeIds.nonUnionWorker:
    case CreatureTypeIds.childLaborer:
      okaySite.add(SiteType.dirtyIndustry);
    case CreatureTypeIds.secretary:
      okaySite.addAll([
        SiteType.cosmeticsLab,
        SiteType.geneticsLab,
        SiteType.clinic,
        SiteType.universityHospital,
        SiteType.policeStation,
        SiteType.courthouse,
        SiteType.intelligenceHQ,
        SiteType.dirtyIndustry,
        SiteType.nuclearPlant,
        SiteType.corporateHQ,
        SiteType.ceoHouse,
        SiteType.amRadioStation,
        SiteType.cableNewsStation,
        SiteType.fireStation,
        SiteType.whiteHouse,
      ]);
    case CreatureTypeIds.landlord:
      okaySite.addAll([
        SiteType.tenement,
        SiteType.apartment,
        SiteType.upscaleApartment,
      ]);
    case CreatureTypeIds.teenager:
      okaySite.addAll([
        SiteType.tenement,
        SiteType.apartment,
        SiteType.upscaleApartment,
        SiteType.homelessEncampment,
        SiteType.ceoHouse,
      ]);
    case CreatureTypeIds.cop:
    case CreatureTypeIds.policeChief:
    case CreatureTypeIds.gangUnit:
    case CreatureTypeIds.swat:
    case CreatureTypeIds.deathSquad:
      okaySite.add(SiteType.policeStation);
    case CreatureTypeIds.firefighter:
      okaySite.add(SiteType.fireStation);
    case CreatureTypeIds.liberalJudge:
    case CreatureTypeIds.conservativeJudge:
      okaySite.add(SiteType.courthouse);
    case CreatureTypeIds.secretService:
      okaySite.add(SiteType.whiteHouse);
    case CreatureTypeIds.agent:
      okaySite.addAll([
        SiteType.intelligenceHQ,
        SiteType.amRadioStation,
        SiteType.cableNewsStation,
      ]);
    case CreatureTypeIds.genetic:
      okaySite.add(SiteType.geneticsLab);
    case CreatureTypeIds.guardDog:
      okaySite.addAll([
        SiteType.prison,
        SiteType.intelligenceHQ,
        SiteType.ceoHouse,
        SiteType.armyBase,
      ]);
    case CreatureTypeIds.lawyer:
      okaySite.addAll([
        SiteType.courthouse,
        SiteType.whiteHouse,
      ]);
    case CreatureTypeIds.doctor:
    case CreatureTypeIds.psychologist:
    case CreatureTypeIds.nurse:
      okaySite.addAll([
        SiteType.clinic,
        SiteType.universityHospital,
      ]);
    case CreatureTypeIds.ccsArchConservative:
    case CreatureTypeIds.ccsMolotov:
    case CreatureTypeIds.ccsSniper:
    case CreatureTypeIds.ccsVigilante:
      okaySite.add(SiteType.bunker);
      okaySite.add(SiteType.bombShelter);
      okaySite.add(SiteType.barAndGrill);
    case CreatureTypeIds.highschoolDropout:
    case CreatureTypeIds.bum:
      okaySite.add(SiteType.homelessEncampment);
    case CreatureTypeIds.gangMember:
      okaySite.add(SiteType.drugHouse);
    case CreatureTypeIds.engineer:
      okaySite.addAll([
        SiteType.amRadioStation,
        SiteType.cableNewsStation,
        SiteType.nuclearPlant,
        SiteType.corporateHQ,
      ]);
    case CreatureTypeIds.barista:
      okaySite.addAll([
        SiteType.latteStand,
        SiteType.internetCafe,
      ]);
    case CreatureTypeIds.bartender:
      okaySite.add(SiteType.barAndGrill);
    case CreatureTypeIds.carSalesman:
      okaySite.add(SiteType.carDealership);
    case CreatureTypeIds.officeWorker:
      okaySite.addAll([
        SiteType.cosmeticsLab,
        SiteType.geneticsLab,
        SiteType.clinic,
        SiteType.universityHospital,
        SiteType.courthouse,
        SiteType.corporateHQ,
        SiteType.amRadioStation,
        SiteType.cableNewsStation,
        SiteType.departmentStore,
        SiteType.whiteHouse,
      ]);
    case CreatureTypeIds.sexWorker:
    case CreatureTypeIds.chef:
      okaySite.add(SiteType.barAndGrill);
    case CreatureTypeIds.merc:
      okaySite.addAll([
        SiteType.corporateHQ,
        SiteType.ceoHouse,
        SiteType.nuclearPlant,
        SiteType.geneticsLab,
        SiteType.bank,
      ]);
    case CreatureTypeIds.tank:
    case CreatureTypeIds.hardenedVeteran:
    case CreatureTypeIds.soldier:
    case CreatureTypeIds.militaryPolice:
    case CreatureTypeIds.seal:
      okaySite.add(SiteType.armyBase);
    case CreatureTypeIds.educator:
    case CreatureTypeIds.prisonGuard:
      okaySite.add(SiteType.prison);
    case CreatureTypeIds.programmer:
      okaySite.add(SiteType.intelligenceHQ);
      okaySite.add(SiteType.corporateHQ);
    case CreatureTypeIds.musicCritic:
    case CreatureTypeIds.radioPersonality:
      okaySite.add(SiteType.amRadioStation);
    case CreatureTypeIds.artCritic:
    case CreatureTypeIds.journalist:
    case CreatureTypeIds.photographer:
    case CreatureTypeIds.cameraman:
    case CreatureTypeIds.newsAnchor:
      okaySite.add(SiteType.cableNewsStation);
    case CreatureTypeIds.clerk:
      okaySite.addAll([
        SiteType.veganCoOp,
        SiteType.juiceBar,
        SiteType.latteStand,
        SiteType.internetCafe,
        SiteType.departmentStore,
        SiteType.oubliette,
      ]);
    default:
  }
  return okaySite.contains(location.type);
}

void giveWorkLocation(Creature cr, CreatureType type) {
  if (activeSite == null) return;
  if (testWorkLocation(type, activeSite!)) {
    cr.workLocation = activeSite!;
  } else {
    Iterable<Site> validWorkLocations =
        activeSite!.city.sites.where((site) => testWorkLocation(type, site));
    if (validWorkLocations.isNotEmpty) {
      cr.workLocation = validWorkLocations.random;
    } else {
      cr.workLocation = activeSite!.district;
    }
  }
}
