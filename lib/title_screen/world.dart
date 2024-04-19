import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/city.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';

class Area {
  Area(this.name, this.description);
  String name;
  String description;
}

void makeWorld() {
  City seattle = City("Seattle, WA", "SEA", "Birthplace of the LCS");
  cities.add(seattle);
  seattle
    ..addCommercialDistrict()
    ..addDistrict("Downtown", "Downtown Seattle").addSites([
      SiteType.upscaleApartment,
      SiteType.policeStation,
      SiteType.courthouse,
      SiteType.bank,
      SiteType.amRadioStation,
      SiteType.latteStand,
      SiteType.barAndGrill,
    ])
    ..addDistrict("U-District", "University District").addSites([
      SiteType.apartment,
      SiteType.universityHospital,
      SiteType.geneticsLab,
      SiteType.cosmeticsLab,
      SiteType.veganCoOp,
      SiteType.juiceBar,
      SiteType.internetCafe,
      SiteType.publicPark,
    ])
    ..addDistrict("I-District", "Industrial District").addSites([
      SiteType.homelessEncampment,
      SiteType.warehouse,
      SiteType.tenement,
      SiteType.dirtyIndustry,
      SiteType.sweatshop,
      SiteType.drugHouse,
    ])
    ..addDistrict("Outskirts", "Eastern Washington", outOfTown: true).addSites([
      SiteType.prison,
      SiteType.intelligenceHQ,
      SiteType.corporateHQ,
      SiteType.armyBase,
    ]);

  City newYork = City("New York, NY", "NYC", "Wall Street and Big Media");
  cities.add(newYork);
  newYork
    ..addCommercialDistrict()
    ..addDistrict("Manhattan", "Manhattan Island").addSites([
      SiteType.latteStand,
      SiteType.upscaleApartment,
      SiteType.policeStation,
      SiteType.courthouse,
      SiteType.bank,
      SiteType.corporateHQ,
      SiteType.amRadioStation,
      SiteType.cableNewsStation,
      SiteType.intelligenceHQ,
      SiteType.publicPark,
      SiteType.prison,
    ])
    ..addDistrict("Brooklyn & Queens", "Long Island").addSites([
      SiteType.warehouse,
      SiteType.apartment,
      SiteType.universityHospital,
      SiteType.juiceBar,
      SiteType.internetCafe,
      SiteType.dirtyIndustry,
      SiteType.geneticsLab,
      SiteType.armyBase,
      SiteType.bombShelter,
    ])
    ..addDistrict("The Bronx", "The Bronx").addSites([
      SiteType.homelessEncampment,
      SiteType.tenement,
      SiteType.sweatshop,
      SiteType.cosmeticsLab,
      SiteType.veganCoOp,
      SiteType.drugHouse,
      SiteType.publicPark,
    ])
    ..addDistrict("Outskirts", "Upstate New York", outOfTown: true).addSites([
      SiteType.nuclearPlant,
    ]);

  City losAngeles = City("Los Angeles, CA", "LA", "Hollywood and Trade");
  cities.add(losAngeles);
  losAngeles
    ..addCommercialDistrict()
    ..addDistrict("Downtown", "Downtown").addSites([
      SiteType.latteStand,
      SiteType.homelessEncampment,
      SiteType.apartment,
      SiteType.policeStation,
      SiteType.courthouse,
      SiteType.bank,
      SiteType.corporateHQ,
      SiteType.universityHospital,
    ])
    ..addDistrict("Hollywood", "Greater Hollywood").addSites([
      SiteType.upscaleApartment,
      SiteType.veganCoOp,
      SiteType.amRadioStation,
      SiteType.cableNewsStation,
      SiteType.publicPark,
      SiteType.ceoHouse,
    ])
    ..addDistrict("Seaport", "Seaport Area").addSites([
      SiteType.warehouse,
      SiteType.tenement,
      SiteType.geneticsLab,
      SiteType.cosmeticsLab,
      SiteType.dirtyIndustry,
      SiteType.sweatshop,
      SiteType.drugHouse,
    ])
    ..addDistrict("Outskirts", "Outskirts & Orange County", outOfTown: true)
        .addSites([
      SiteType.prison,
      SiteType.nuclearPlant,
      SiteType.armyBase,
      SiteType.bunker,
    ]);

  City washingtonDC = City("Washington DC", "DC", "The Nation's Capital");
  cities.add(washingtonDC);
  washingtonDC
    ..addCommercialDistrict()
    ..addDistrict("Downtown", "Downtown").addSites([
      SiteType.latteStand,
      SiteType.policeStation,
      SiteType.courthouse,
      SiteType.bank,
      SiteType.universityHospital,
      SiteType.homelessEncampment,
    ])
    ..addDistrict("Mall", "National Mall").addSites([
      SiteType.publicPark,
      SiteType.whiteHouse,
    ])
    ..addDistrict("Outskirts", "Arlington, VA", outOfTown: true).addSites([
      SiteType.prison,
      SiteType.intelligenceHQ,
      SiteType.armyBase,
    ]);

  // If the CCS is active, give them control of their safehouses
  if (ccsActive) {
    for (Site s in sites.where((s) =>
        s.controller == SiteController.unaligned &&
        [SiteType.barAndGrill, SiteType.bombShelter, SiteType.bunker]
            .contains(s.type))) {
      s.controller = SiteController.ccs;
    }
  }
}
