import 'package:lcs_new_age/items/item_type.dart';

Map<String, LootType> lootTypes = {};

class LootType extends ItemType {
  LootType(String id) : super(id) {
    lootTypes[id] = this;
  }
  bool stackable = false;
  bool noQuickFencing = false;
  bool cloth = false;
}

class LootTypeIds {
  static const String cheapJewelry = "LOOT_CHEAPJEWELRY";
  static const String dirtySock = "LOOT_DIRTYSOCK";
  static const String familyPhoto = "LOOT_FAMILYPHOTO";
  static const String fineCloth = "LOOT_FINECLOTH";
  static const String recycledCloth = "LOOT_RECYCLEDCLOTH";
  static const String expensiveJewelry = "LOOT_EXPENSIVEJEWELERY";
  static const String trinket = "LOOT_TRINKET";
  static const String labEquipment = "LOOT_LABEQUIPMENT";
  static const String computer = "LOOT_COMPUTER";
  static const String kidArt = "LOOT_KIDART";
  static const String microphone = "LOOT_MICROPHONE";
  static const String silverware = "LOOT_SILVERWARE";
  static const String cellphone = "LOOT_CELLPHONE";
  static const String pda = "LOOT_PDA";
  static const String watch = "LOOT_WATCH";
  static const String chemical = "LOOT_CHEMICAL";
  static const String amRadioFiles = "LOOT_AMRADIOFILES";
  static const String cableNewsFiles = "LOOT_CABLENEWSFILES";
  static const String ccsBackerList = "LOOT_CCS_BACKERLIST";
  static const String ceoLoveLetters = "LOOT_CEOLOVELETTERS";
  static const String ceoPhotos = "LOOT_CEOPHOTOS";
  static const String ceoTaxPapers = "LOOT_CEOTAXPAPERS";
  static const String intHqDisk = "LOOT_INTHQDISK";
  static const String judgeFiles = "LOOT_JUDGEFILES";
  static const String policeRecords = "LOOT_POLICERECORDS";
  static const String prisonFiles = "LOOT_PRISONFILES";
  static const String researchFiles = "LOOT_RESEARCHFILES";
  static const String corpFiles = "LOOT_CORPFILES";
  static const String secretDocuments = "LOOT_SECRETDOCUMENTS";
  static const String landlordPapers = "LOOT_LANDLORD_PAPERS";
  static const String insuranceFraudEvidence = "LOOT_INSURANCE_DOCUMENTS";
  static const String elderAbuseEvidence = "LOOT_RETIREMENT_DOCUMENTS";
}
