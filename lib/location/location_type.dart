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
  armsDealer("Black Market", "Black Market"),
  carDealership("Car Dealer", "Used Car Dealership"),
  homelessEncampment("Homeless", "Homeless Camp"),
  tenement("Tenement", "Low Income Housing"),
  apartment("Apartment", "Apartment Building"),
  upscaleApartment("Highrise", "Upscale Apartment"),
  bombShelter("Bomb Shelter", "Fallout Shelter"),
  cosmeticsLab("Cosmetics", "Cosmetics Lab"),
  geneticsLab("Genetics", "Genetics Lab"),
  policeStation("Police Station", "Police Station"),
  courthouse("Courthouse", "Courthouse"),
  prison("Prison", "Prison"),
  intelligenceHQ("Intel HQ", "Intelligence HQ"),
  fireStation("Fire Dept.", "Fire Station"),
  sweatshop("Sweatshop", "Sweatshop"),
  dirtyIndustry("Dirty Industry", "Dirty Industry"),
  nuclearPlant("Nuclear Plant", "Nuclear Plant"),
  warehouse("Warehouse", "Abandoned Warehouse"),
  corporateHQ("Corp. HQ", "Corporate HQ"),
  ceoHouse("Mansion", "CEO's Mansion"),
  amRadioStation("Radio Station", "AM Radio Station"),
  cableNewsStation("TV Station", "Cable News Station"),
  drugHouse("Drug House", "Drug House"),
  juiceBar("Juice Bar", "Juice Bar"),
  latteStand("Latte Stand", "Latte Stand"),
  veganCoOp("Vegan Co-op", "Vegan Co-op"),
  internetCafe("Cyber Cafe", "Internet Cafe"),
  barAndGrill("Bar & Grill", "Desert Eagle Bar & Grill"),
  publicPark("Public Park", "Public Park"),
  bunker("Bunker", "Robert E. Lee Bunker"),
  armyBase("Army Base", "Army Base"),
  bank("Bank", "First American Bank"),
  liberalPartyHQ("Campaign HQ", "Liberal Party HQ"),
  whiteHouse("White House", "White House"),
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
