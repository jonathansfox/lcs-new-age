enum DistrictType {
  downtown,
  commercial,
  university,
  industrial,
  outskirts,
  travel,
}

enum SiteType {
  clinic("Clinic", "Free Clinic"),
  universityHospital("Hospital", "University Hospital"),
  pawnShop("Pawn Shop", "Pawn Shop"),
  departmentStore("Dept. Store", "Department Store"),
  oubliette("Oubliette", "The Oubliette"),
  armsDealer("Blk Market", "Black Market"),
  carDealership("Car Dealer", "Used Car Dealership"),
  homelessEncampment("Homeless", "Homeless Camp"),
  tenement("Projects", "Low Income Housing"),
  apartment("Apartment", "Apartment Building"),
  upscaleApartment("Condos", "Upscale Apartment"),
  bombShelter("Bomb Shelter", "Fallout Shelter"),
  cosmeticsLab("Cosmetics", "Cosmetics Lab"),
  geneticsLab("Genetics", "Genetics Lab"),
  policeStation("Police", "Police Station"),
  courthouse("Courthouse", "Courthouse"),
  prison("Prison", "Prison"),
  intelligenceHQ("Intel HQ", "Intelligence HQ"),
  fireStation("Fire Dept.", "Fire Station"),
  sweatshop("Sweatshop", "Sweatshop"),
  dirtyIndustry("D Industry", "Dirty Industry"),
  nuclearPlant("Nuclear", "Nuclear Plant"),
  warehouse("Warehouse", "Abandoned Warehouse"),
  corporateHQ("Corp. HQ", "Corporate HQ"),
  ceoHouse("CEO House", "CEO's Mansion"),
  amRadioStation("AM Radio", "AM Radio Station"),
  cableNewsStation("Cable News", "Cable News Station"),
  drugHouse("Drug House", "Drug House"),
  juiceBar("Juice Bar", "Juice Bar"),
  latteStand("Latte", "Latte Stand"),
  veganCoOp("Vegan", "Vegan Co-op"),
  internetCafe("Net Cafe", "Internet Cafe"),
  barAndGrill("Deagle Bar", "Desert Eagle Bar & Grill"),
  publicPark("Park", "Public Park"),
  bunker("Bunker", "Robert E. Lee Bunker"),
  armyBase("Army Base", "Army Base"),
  bank("Bank", "First American Bank"),
  liberalPartyHQ("Lib. HQ", "Liberal Party HQ"),
  whiteHouse("WhiteHouse", "White House"),
  // districts
  downtown("Downtown", "Downtown"),
  commercialDistrict("Commercial", "Commercial District"),
  universityDistrict("University", "University District"),
  industrialDistrict("Industrial", "Industrial District"),
  outOfTown("Rural", "Rural Areas");

  const SiteType(this.shortName, this.name);
  final String name;
  final String shortName;
}

/* returns if the site type supports high security */
int securityable(SiteType type) {
  switch (type) {
    case SiteType.barAndGrill:
    case SiteType.upscaleApartment:
    case SiteType.cosmeticsLab:
    case SiteType.geneticsLab:
    case SiteType.fireStation:
    case SiteType.sweatshop:
    case SiteType.dirtyIndustry:
    case SiteType.corporateHQ:
    case SiteType.amRadioStation:
    case SiteType.cableNewsStation:
      return 1;
    //These places have better quality locks.
    case SiteType.bank:
    case SiteType.nuclearPlant:
    case SiteType.policeStation:
    case SiteType.courthouse:
    case SiteType.prison:
    case SiteType.intelligenceHQ:
    case SiteType.armyBase:
    case SiteType.ceoHouse:
    case SiteType.whiteHouse:
      return 2;
    default:
      return 0;
  }
}
