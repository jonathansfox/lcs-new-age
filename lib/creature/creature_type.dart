import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/hardcoded_creature_type_stuff.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/attack.dart';
import 'package:lcs_new_age/items/clothing_type.dart';
import 'package:lcs_new_age/items/weapon_type.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Map<String, CreatureType> creatureTypes = {};

class CreatureType {
  CreatureType(this.id) {
    creatureTypes[id] = this;
  }
  final String id;
  String name = "LIVING BUG";
  String? hostageName;
  bool hardToIntimidate = false;
  CreatureTypeAlignment alignment = CreatureTypeAlignment.any;
  Alignment get randomAlignment {
    switch (alignment) {
      case CreatureTypeAlignment.any:
        return politics.rollAlignment();
      case CreatureTypeAlignment.conservative:
        return Alignment.conservative;
      case CreatureTypeAlignment.liberal:
        return Alignment.liberal;
      case CreatureTypeAlignment.moderate:
        return Alignment.moderate;
    }
  }

  List<Attack> socialAttacks = [];
  (int, int) age = (18, 57);
  (int, int) infiltration = (0, 30);
  DateTime get randomBirthay =>
      date.subtract(Duration(days: (365 * (age.rollDouble())).round()));
  (int, int) extraAttributePoints = (0, 0);
  Map<Attribute, (int, int)> attributePoints = {
    for (Attribute a in Attribute.values) a: (1, 10)
  };
  Map<Skill, (int, int)> skillPoints = {
    for (Skill s in Skill.values) s: (0, 0)
  };
  (int, int) money = (20, 40);
  (int, int) juice = (0, 0);
  Gender gender = Gender.nonbinary;

  List<String> armorTypeIds = [];
  ClothingType? get randomArmor =>
      armorTypeIds.map((s) => clothingTypes[s]).nonNulls.toList().randomOrNull;

  List<String> weaponTypeIds = [];
  WeaponType? randomWeaponFor(Creature cr) {
    String value = weaponTypeIds.randomOrNull ?? "";
    if (value == "CIVILIAN") {
      giveCivilianWeapon(cr);
    } else {
      cr.giveWeaponAndAmmo(value, 4);
    }
    return weaponTypes[value];
  }

  List<String> encounterNames = [];
  String get randomEncounterName => encounterNames.randomOrNull ?? name;
  bool talkReceptive = false;
  int seeThroughStealth = 3;
  int seeThroughDisguise = 3;
  bool kidnapResistant = false;
  bool reportsToPolice = false;
  bool intimidationResistant = false;
  bool canPerformArrests = false;
  bool animal = false;
  bool dog = false;
  bool get tank => id == CreatureTypeIds.tank;
  int? recruitActivityDifficulty;
  bool edgelord = false;

  bool get enemyEvenWhenNotConservative => id == CreatureTypeIds.cop;

  bool get freeable {
    if (id == CreatureTypeIds.childLaborer ||
        (id == CreatureTypeIds.servant &&
            laws[Law.labor] == DeepAlignment.archConservative) ||
        (id == CreatureTypeIds.sweatshopWorker)) {
      return true;
    } else {
      return false;
    }
  }

  bool get majorEnemy =>
      id == CreatureTypeIds.corporateCEO ||
      id == CreatureTypeIds.radioPersonality ||
      id == CreatureTypeIds.newsAnchor ||
      id == CreatureTypeIds.eminentScientist ||
      id == CreatureTypeIds.conservativeJudge ||
      id == CreatureTypeIds.ccsArchConservative ||
      id == CreatureTypeIds.policeChief ||
      id == CreatureTypeIds.televangelist ||
      id == CreatureTypeIds.president;

  bool get preciousToAngryRuralMobs =>
      id == CreatureTypeIds.radioPersonality ||
      id == CreatureTypeIds.newsAnchor;

  bool get lawEnforcement =>
      id == CreatureTypeIds.cop ||
      id == CreatureTypeIds.policeChief ||
      id == CreatureTypeIds.swat ||
      id == CreatureTypeIds.deathSquad ||
      id == CreatureTypeIds.gangUnit ||
      id == CreatureTypeIds.secretService ||
      id == CreatureTypeIds.agent ||
      id == CreatureTypeIds.prisonGuard;

  bool get ccsMember =>
      id == CreatureTypeIds.ccsArchConservative ||
      id == CreatureTypeIds.ccsVigilante;

  void applyOnDeathPublicOpinionEffects() {
    switch (id) {
      case CreatureTypeIds.corporateCEO:
        changePublicOpinion(View.ceoSalary, 5);
        changePublicOpinion(View.corporateCulture, 3);
      case CreatureTypeIds.radioPersonality:
        changePublicOpinion(View.amRadio, 5);
      case CreatureTypeIds.newsAnchor:
      case CreatureTypeIds.televangelist:
        changePublicOpinion(View.cableNews, 5);
      case CreatureTypeIds.eminentScientist:
        changePublicOpinion(View.genetics, 3);
        changePublicOpinion(View.animalResearch, 3);
      case CreatureTypeIds.conservativeJudge:
        changePublicOpinion(View.justices, 5);
      case CreatureTypeIds.policeChief:
        changePublicOpinion(View.policeBehavior, 5);
      default:
        break;
    }
  }
}

enum CreatureTypeAlignment { liberal, moderate, conservative, any }

class CreatureTypeIds {
  static const String bouncer = "CREATURE_BOUNCER";
  static const String securityGuard = "CREATURE_SECURITYGUARD";
  static const String labTech = "CREATURE_SCIENTIST_LABTECH";
  static const String eminentScientist = "CREATURE_SCIENTIST_EMINENT";
  static const String president = "CREATURE_PRESIDENT";
  static const String corporateManager = "CREATURE_CORPORATE_MANAGER";
  static const String corporateCEO = "CREATURE_CORPORATE_CEO";
  static const String servant = "CREATURE_WORKER_SERVANT";
  static const String janitor = "CREATURE_WORKER_JANITOR";
  static const String sweatshopWorker = "CREATURE_WORKER_SWEATSHOP";
  static const String nonUnionWorker = "CREATURE_WORKER_FACTORY_NONUNION";
  static const String childLaborer = "CREATURE_WORKER_FACTORY_CHILD";
  static const String secretary = "CREATURE_WORKER_SECRETARY";
  static const String unionWorker = "CREATURE_WORKER_FACTORY_UNION";
  static const String landlord = "CREATURE_LANDLORD";
  static const String bankTeller = "CREATURE_BANK_TELLER";
  static const String bankManager = "CREATURE_BANK_MANAGER";
  static const String teenager = "CREATURE_TEENAGER";
  static const String cop = "CREATURE_COP";
  static const String policeChief = "CREATURE_POLICE_CHIEF";
  static const String swat = "CREATURE_SWAT";
  static const String deathSquad = "CREATURE_DEATHSQUAD";
  static const String firefighter = "CREATURE_FIREFIGHTER";
  static const String educator = "CREATURE_EDUCATOR";
  static const String gangUnit = "CREATURE_GANGUNIT";
  static const String liberalJudge = "CREATURE_JUDGE_LIBERAL";
  static const String conservativeJudge = "CREATURE_JUDGE_CONSERVATIVE";
  static const String agent = "CREATURE_AGENT";
  static const String secretService = "CREATURE_SECRET_SERVICE";
  static const String radioPersonality = "CREATURE_RADIOPERSONALITY";
  static const String newsAnchor = "CREATURE_NEWSANCHOR";
  static const String genetic = "CREATURE_GENETIC";
  static const String guardDog = "CREATURE_GUARDDOG";
  static const String prisoner = "CREATURE_PRISONER";
  static const String juror = "CREATURE_JUROR";
  static const String lawyer = "CREATURE_LAWYER";
  static const String doctor = "CREATURE_DOCTOR";
  static const String psychologist = "CREATURE_PSYCHOLOGIST";
  static const String nurse = "CREATURE_NURSE";
  static const String ccsArchConservative = "CREATURE_CCS_ARCHCONSERVATIVE";
  static const String ccsVigilante = "CREATURE_CCS_VIGILANTE";
  static const String sewerWorker = "CREATURE_SEWERWORKER";
  static const String collegeStudent = "CREATURE_COLLEGESTUDENT";
  static const String musician = "CREATURE_MUSICIAN";
  static const String mathematician = "CREATURE_MATHEMATICIAN";
  static const String teacher = "CREATURE_TEACHER";
  static const String highschoolDropout = "CREATURE_HSDROPOUT";
  static const String bum = "CREATURE_BUM";
  static const String gangMember = "CREATURE_GANGMEMBER";
  static const String crackhead = "CREATURE_CRACKHEAD";
  static const String priest = "CREATURE_PRIEST";
  static const String engineer = "CREATURE_ENGINEER";
  static const String fastFoodWorker = "CREATURE_FASTFOODWORKER";
  static const String baker = "CREATURE_BAKER";
  static const String barista = "CREATURE_BARISTA";
  static const String bartender = "CREATURE_BARTENDER";
  static const String telemarketer = "CREATURE_TELEMARKETER";
  static const String carSalesman = "CREATURE_CARSALESMAN";
  static const String officeWorker = "CREATURE_OFFICEWORKER";
  static const String footballCoach = "CREATURE_FOOTBALLCOACH";
  static const String sexWorker = "CREATURE_SEXWORKER";
  static const String mailman = "CREATURE_MAILMAN";
  static const String garbageman = "CREATURE_GARBAGEMAN";
  static const String plumber = "CREATURE_PLUMBER";
  static const String chef = "CREATURE_CHEF";
  static const String constructionWorker = "CREATURE_CONSTRUCTIONWORKER";
  static const String amateurMagician = "CREATURE_AMATEURMAGICIAN";
  static const String tank = "CREATURE_TANK";
  static const String merc = "CREATURE_MERC";
  static const String angryRuralMob = "CREATURE_HICK";
  static const String veteran = "CREATURE_VETERAN";
  static const String hardenedVeteran = "CREATURE_HARDENED_VETERAN";
  static const String soldier = "CREATURE_SOLDIER";
  static const String militaryPolice = "CREATURE_MILITARYPOLICE";
  static const String seal = "CREATURE_SEAL";
  static const String hippie = "CREATURE_HIPPIE";
  static const String artCritic = "CREATURE_CRITIC_ART";
  static const String musicCritic = "CREATURE_CRITIC_MUSIC";
  static const String socialite = "CREATURE_SOCIALITE";
  static const String programmer = "CREATURE_PROGRAMMER";
  static const String retiree = "CREATURE_RETIREE";
  static const String painter = "CREATURE_PAINTER";
  static const String sculptor = "CREATURE_SCULPTOR";
  static const String author = "CREATURE_AUTHOR";
  static const String journalist = "CREATURE_JOURNALIST";
  static const String dancer = "CREATURE_DANCER";
  static const String photographer = "CREATURE_PHOTOGRAPHER";
  static const String cameraman = "CREATURE_CAMERAMAN";
  static const String hairstylist = "CREATURE_HAIRSTYLIST";
  static const String fashionDesigner = "CREATURE_FASHIONDESIGNER";
  static const String clerk = "CREATURE_CLERK";
  static const String thief = "CREATURE_THIEF";
  static const String actor = "CREATURE_ACTOR";
  static const String yogaInstructor = "CREATURE_YOGAINSTRUCTOR";
  static const String martialArtist = "CREATURE_MARTIALARTIST";
  static const String athlete = "CREATURE_ATHLETE";
  static const String cheerleader = "CREATURE_CHEERLEADER";
  static const String biker = "CREATURE_BIKER";
  static const String trucker = "CREATURE_TRUCKER";
  static const String taxiDriver = "CREATURE_TAXIDRIVER";
  static const String nun = "CREATURE_NUN";
  static const String locksmith = "CREATURE_LOCKSMITH";
  static const String politicalActivist = "CREATURE_POLITICALACTIVIST";
  static const String prisonGuard = "CREATURE_PRISONGUARD";
  static const String mutant = "CREATURE_MUTANT";
  static const String punk = "CREATURE_PUNK";
  static const String goth = "CREATURE_GOTH";
  static const String emo = "CREATURE_EMO";
  static const String naziPunk = "CREATURE_NAZIPUNK";
  static const String neoNazi = "CREATURE_NEONAZI";
  static const String televangelist = "CREATURE_TELEVANGELIST";
}
