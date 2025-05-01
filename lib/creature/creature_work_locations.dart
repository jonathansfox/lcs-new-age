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
      // Wherever you go, there they are
      // (short list of exceptions)
      okaySite.addAll(SiteType.values.toList()
        ..remove(SiteType.publicPark)
        ..remove(SiteType.drugHouse)
        ..remove(SiteType.homelessEncampment)
        ..remove(SiteType.bombShelter)
        ..remove(SiteType.bunker)
        ..remove(SiteType.armyBase)
        ..remove(SiteType.ceoHouse)
        ..remove(SiteType.warehouse));
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
      okaySite.addAll([
        SiteType.geneticsLab,
        SiteType.ceoHouse,
      ]);
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
        SiteType.nuclearPlant,
        SiteType.corporateHQ,
        SiteType.dirtyIndustry,
      ]);
    case CreatureTypeIds.barista:
      okaySite.addAll([
        SiteType.latteStand,
        SiteType.internetCafe,
        SiteType.juiceBar,
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
      okaySite.addAll([
        SiteType.barAndGrill,
        SiteType.tenement,
        SiteType.drugHouse,
        SiteType.ceoHouse,
      ]);
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
    case CreatureTypeIds.cameraman:
    case CreatureTypeIds.newsAnchor:
    case CreatureTypeIds.televangelist:
      okaySite.add(SiteType.cableNewsStation);
    case CreatureTypeIds.journalist:
    case CreatureTypeIds.photographer:
    case CreatureTypeIds.hairstylist:
      okaySite.addAll([
        SiteType.cableNewsStation,
        SiteType.whiteHouse,
      ]);
    case CreatureTypeIds.chef:
      okaySite.addAll([
        SiteType.barAndGrill,
        SiteType.whiteHouse,
      ]);
    case CreatureTypeIds.clerk:
      okaySite.addAll([
        SiteType.veganCoOp,
        SiteType.juiceBar,
        SiteType.latteStand,
        SiteType.internetCafe,
        SiteType.departmentStore,
        SiteType.oubliette,
        SiteType.whiteHouse,
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
