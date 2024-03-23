import 'dart:math';

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/body.dart';
import 'package:lcs_new_age/creature/creature_builder.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/level.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/squad.dart';
import 'package:lcs_new_age/items/ammo.dart';
import 'package:lcs_new_age/items/ammo_type.dart';
import 'package:lcs_new_age/items/armor.dart';
import 'package:lcs_new_age/items/attack.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/weapon.dart';
import 'package:lcs_new_age/items/weapon_type.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/location.dart';
import 'package:lcs_new_age/location/siege.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';
import 'package:lcs_new_age/vehicles/vehicle.dart';

part 'creature.g.dart';

@JsonSerializable()
class Creature {
  factory Creature() {
    return Creature._(creatureTypes.values.first);
  }
  factory Creature.fromId(String typeId, {Alignment? align}) {
    return creatureBuilder(Creature._(creatureTypes[typeId]!), align: align);
  }
  Creature._(this.type);
  factory Creature.fromJson(Map<String, dynamic> json) =>
      _$CreatureFromJson(json);
  Map<String, dynamic> toJson() => _$CreatureToJson(this);

  int id = gameState.nextCreatureId++;

  int? hireId;
  int? squadId;
  int? carId;
  int? preferredCarId;
  bool isDriver = false;
  bool preferredDriver = false;
  Alignment align = Alignment.moderate;
  bool alive = true;
  bool sleeperAgent = false;
  int hidingDaysLeft = 0;
  bool get inHiding => hidingDaysLeft != 0;
  int clinicMonthsLeft = 0;
  int vacationDaysLeft = 0;
  int daysSinceJoined = 0;
  int daysSinceDeath = 0;
  String? locationId;
  String? workLocationId;
  int? baseId;
  int juice = 0;
  int income = 0;
  int money = 0;
  int heartDamage = 0;
  int permanentHealthDamage = 0;
  int heat = 0;
  double infiltration = 0;
  int meetings = 0;
  bool hasWheelchair = false;
  Activity activity = Activity(ActivityType.none);
  String name = "";
  String properName = "";
  bool alreadyNamed = false;
  String get typeId => type.id;
  set typeId(String id) => type = creatureTypes[id]!;
  @JsonKey(includeFromJson: false, includeToJson: false)
  CreatureType type = creatureTypes.values.first;
  bool missing = false;
  bool kidnapped = false;
  bool brainwashed = false;
  bool seduced = false;
  Map<Crime, int> wantedForCrimes = {for (Crime c in Crime.values) c: 0};
  Map<Crime, int> pastConvictions = {for (Crime c in Crime.values) c: 0};
  DateTime birthDate = DateTime.now();

  Gender gender = lcsRandom(2) == 0 ? Gender.male : Gender.female;
  late Gender genderAssignedAtBirth = gender;
  int sentence = 0;
  bool deathPenalty = false;
  int confessions = 0;

  Map<Attribute, int> rawAttributes = <Attribute, int>{
    for (Attribute a in Attribute.values) a: 10
  };

  Map<Skill, int> rawSkill = <Skill, int>{for (Skill s in Skill.values) s: 0};
  int skill(Skill skill) => rawSkill[skill] ?? 0;
  Map<Skill, int> rawSkillXP = <Skill, int>{for (Skill s in Skill.values) s: 0};
  int skillXP(Skill skill) => rawSkillXP[skill] ?? 0;

  Body body = HumanoidBody();
  Weapon? equippedWeapon;
  Armor? equippedArmor;
  Item? spareAmmo;

  // Not saved
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isCriminal => wantedForCrimes.values.any((v) => v > 0);
  @JsonKey(includeFromJson: false, includeToJson: false)
  int get age {
    int yearDiff = gameState.date.year - birthDate.year;
    if (gameState.date.month < birthDate.month ||
        (gameState.date.month == birthDate.month &&
            gameState.date.day < birthDate.day)) {
      yearDiff--;
    }
    return yearDiff;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get canSee => body.canSee;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Attack get attack {
    return weapon.type.attacks.first;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get human => body is HumanoidBody && !type.animal && !type.tank;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Weapon get weapon => equippedWeapon ?? body.naturalWeapon;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Armor get armor => equippedArmor ?? body.naturalArmor;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get indecent => equippedArmor == null && !type.animal;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Creature? prisoner;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool incapacitatedThisRound = false;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool isWillingToTalk = true;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool noticedParty = false;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool isKidnapResistant = false;
  @JsonKey(includeFromJson: false, includeToJson: false)
  int stunned = 0;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool justEscaped = false;

  @JsonKey(includeFromJson: false, includeToJson: false)
  Site? get site => location is Site ? location! as Site : null;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Location? get location =>
      allLocations.firstWhereOrNull((l) => l.idString == locationId);
  set location(Location? loc) => locationId = loc?.idString;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Location get workLocation {
    return sites.firstWhereOrNull((e) => e.idString == workLocationId) ??
        location?.city ??
        cities.first;
  }

  set workLocation(Location? loc) => workLocationId = loc?.idString;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Site? get workSite => workLocation is Site ? workLocation as Site : null;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Site? get base => sites.elementAtOrNull(baseId ?? sites.length);
  set base(Site? loc) => baseId = loc?.id;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Squad? get squad => squads.where((s) => s.id == squadId).firstOrNull;
  set squad(Squad? s) {
    squad?.members.removeWhere((c) => c.id == id);
    squadId = s?.id;
    s?.members.add(this);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  Creature? get boss => pool.where((c) => c.id == hireId).firstOrNull;
  set boss(Creature? c) => hireId = c?.id;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get hasBoss => hireId != null;

  @JsonKey(includeFromJson: false, includeToJson: false)
  Vehicle? get car => vehiclePool
      .followedBy(chaseSequence?.enemycar ?? [])
      .firstWhereOrNull((c) => c.id == carId);
  @JsonKey(includeFromJson: false, includeToJson: false)
  Vehicle? get preferredCar => vehiclePool
      .followedBy(chaseSequence?.enemycar ?? [])
      .firstWhereOrNull((c) => c.id == preferredCarId);
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get imprisoned {
    return (site?.isPartOfTheJusticeSystem ?? false) && !sleeperAgent;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get away =>
      clinicMonthsLeft > 0 || vacationDaysLeft > 0 || hidingDaysLeft > 0;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get inTown => vacationDaysLeft == 0 && hidingDaysLeft == 0;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isActiveLiberal =>
      alive &&
      align == Alignment.liberal &&
      !away &&
      !sleeperAgent &&
      !imprisoned;

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isLiberal => align == Alignment.liberal;

  double _blood = 1;
  @JsonKey(includeFromJson: false, includeToJson: false)
  int get blood => (_blood * maxBlood).round().clamp(0, maxBlood);
  set blood(int value) => _blood = value / maxBlood;
  @JsonKey(includeFromJson: false, includeToJson: false)
  int get maxBlood {
    return health * 10;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  int get health {
    int health = 5;
    // Your maximum health is derived from your convictions
    if (align == Alignment.liberal) {
      // Liberals use heart
      health += attribute(Attribute.heart);
    } else if (align == Alignment.conservative) {
      // Conservatives use wisdom
      health += attribute(Attribute.wisdom);
    } else {
      // moderates use whichever is lower, only finding strength in balance
      // (this makes moderates quite weak by comparison; that is intended)
      health += min(attribute(Attribute.heart), attribute(Attribute.wisdom));
    }
    return max(health - permanentHealthDamage, 1);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isHoldingBody => prisoner != null;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get canWalk => alive && body.canWalk;
  bool justConverted = false;

  int skillCap(Skill s) => attribute(s.attribute);
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get weaponIsConcealed =>
      armor.type.concealWeaponSize >= weapon.type.size;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get weaponIsInCharacter =>
      equippedWeapon == null ||
      armor.type.weaponsPermitted.contains(weapon.type);

  @JsonKey(includeFromJson: false, includeToJson: false)
  int get weaponSkill => rawSkill[weapon.skill] ?? 0;

  @JsonKey(includeFromJson: false, includeToJson: false)
  int get level => levelFromXP(juice);
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get title => levelTitle(level, align);

  Attack? getAttack(bool forceRanged, bool forceMelee, bool forceNoReload,
      {bool allowSocial = false}) {
    Attack? atk = weapon.getAttack(forceRanged, forceMelee, forceNoReload,
        allowSocial: allowSocial, wielderAlignment: align);
    if (allowSocial && atk?.socialDamage != true) {
      Attack? socialAtk = type.socialAttacks.firstWhereOrNull((a) =>
          a.socialDamage &&
          (a.alignmentRestriction == null || a.alignmentRestriction == align));
      if (socialAtk != null) atk = socialAtk;
    }
    return atk;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get hasThrownWeapon =>
      equippedWeapon == null &&
      spareAmmo?.isWeapon == true &&
      (spareAmmo!.type as WeaponType).thrown &&
      spareAmmo!.stackSize > 0;
  bool willDoRangedAttack(bool forceRanged, bool forceMelee) {
    if (equippedWeapon == null) return false;
    if (equippedWeapon
            ?.getAttack(forceRanged, forceMelee, !canReload())
            ?.ranged ==
        true) {
      return true;
    }
    return false;
  }

  bool willReload(bool forceRanged, bool forceMelee) {
    if (equippedWeapon == null) return false;
    if (!canReload()) return false;
    if (weapon.getAttack(forceRanged, forceMelee, false)?.usesAmmo == true &&
        weapon.ammo == 0) {
      return true;
    }
    return false;
  }

  bool canReload() {
    return weapon.acceptableAmmo.contains(spareAmmo?.type) &&
        (spareAmmo?.stackSize ?? 0) > 0;
  }

  bool reload(bool wasteful) {
    Item? ammo = spareAmmo;
    if (canReload() && (wasteful || weapon.ammo == 0) && ammo is Ammo) {
      bool r = weapon.reload(ammo);
      if (ammo.stackSize == 0) spareAmmo = null;
      return r;
    } else {
      return false;
    }
  }

  bool readyAnotherThrowingWeapon() {
    var ammo = spareAmmo;
    if (hasThrownWeapon && ammo != null) {
      equippedWeapon = ammo.split(1) as Weapon;
      if (ammo.stackSize <= 0) spareAmmo = null;
      return true;
    } else {
      return false;
    }
  }

  void dropWeapon({List<Item>? lootPile}) {
    Weapon? weapon = equippedWeapon;
    if (weapon != null) {
      if (lootPile != null) lootPile.add(weapon);
      equippedWeapon = null;
    }
  }

  void dropAmmo({List<Item>? lootPile}) {
    Item? ammo = spareAmmo;
    if (ammo != null) {
      if (lootPile != null) lootPile.add(ammo);
      spareAmmo = null;
    }
  }

  void dropWeaponAndAmmo({List<Item>? lootPile}) {
    dropWeapon(lootPile: lootPile);
    dropAmmo(lootPile: lootPile);
  }

  void die() {
    alive = false;
    blood = 0;
    if (id == uniqueCreatures.ceo.id) {
      uniqueCreatures.newCEO();
    }
    if (id == uniqueCreatures.president.id) {
      politics.oldPresidentName = properName;
      politics.promoteVP();
      uniqueCreatures.newPresident();
    }
    interrogationSessions.removeWhere((e) => e.hostage == this);

    if (align == Alignment.liberal) {
      stats.martyrs++;
    } else if (align == Alignment.conservative &&
        (!type.animal ||
            laws[Law.animalRights] == DeepAlignment.eliteLiberal)) {
      stats.kills++;
    }
  }

  void adjustAttribute(Attribute a, int amount) {
    rawAttributes[a] = rawAttributes[a]! + amount;
  }

  void adjustSkill(Skill s, int amount) {
    rawSkill[s] = rawSkill[s]! + amount;
  }

  int permanentAttribute(Attribute a) {
    int value = rawAttributes[a]!;
    value = max(1, body.permanentAttributeMods(a, value, age));
    if (a == Attribute.heart) value -= min(value - 1, heartDamage);
    return value;
  }

  int attribute(Attribute a) =>
      max(1, modifyAttributeForBlood(a, levelAttribute(this, a)));

  int modifyAttributeForBlood(Attribute a, int amount) {
    if (a == Attribute.strength ||
        a == Attribute.agility ||
        a == Attribute.charisma ||
        a == Attribute.intelligence) {
      return (amount * (blood / maxBlood)).round();
    } else {
      return amount;
    }
  }

  int skillRoll(
    Skill skill, {
    bool take10 = false,
    bool healthMod = false,
    bool advantage = false,
  }) {
    int roll;
    if (take10) {
      roll = 10;
      if (advantage) roll += 5;
    } else {
      roll = lcsRandom(20) + 1;
      if (advantage) roll = max(roll, lcsRandom(20) + 1);
    }
    int attMod = attribute(skill.attribute) - 5;
    int skillMod = rawSkill[skill]!;
    if (skillMod < 1) roll = roll ~/ 2;
    if (healthMod) {
      roll -= (maxBlood - blood) * 4 ~/ maxBlood;
      roll += body.combatRollModifier;
    }
    return roll + attMod + skillMod;
  }

  bool skillCheck(Skill skill, int difficulty,
      {bool take10 = false, bool healthMod = false}) {
    if (!alive) return false;
    int result = skillRoll(skill, take10: take10, healthMod: healthMod);
    //debugPrint("${skill.name} check: $result >= $difficulty");
    return result >= difficulty;
  }

  int attributeRoll(Attribute att,
      {bool take10 = false, bool healthMod = false}) {
    int roll = lcsRandom(20) + 1;
    if (take10) roll = 10;
    int attMod = attribute(att) - 5;
    if (healthMod) {
      roll -= (maxBlood - blood) * 4 ~/ maxBlood;
      roll += body.combatRollModifier;
    }
    return roll + attMod;
  }

  bool attributeCheck(Attribute att, int difficulty,
      {bool take10 = false, bool healthMod = false}) {
    if (!alive) return false;
    return attributeRoll(att, take10: take10, healthMod: healthMod) >=
        difficulty;
  }

  void train(Skill skill, int experience) {
    if (skillCap(skill) <= rawSkill[skill]! || experience <= 0) return;
    double multiplier = 1; // attribute(skill.attribute) / 10
    rawSkillXP[skill] =
        (rawSkillXP[skill] ?? 0) + max(1, (experience * multiplier).round());
    int toNextLevel;
    if (skillCap(skill) <= rawSkill[skill]!) {
      toNextLevel = 0;
    } else {
      toNextLevel = skillXpNeeded(rawSkill[skill]!);
    }
    rawSkillXP[skill] = min(rawSkillXP[skill]!, (toNextLevel * 1.5).round());
    return;
  }

  void strip({List<Item>? lootPile}) {
    Armor? armor = equippedArmor;
    if (armor != null && armor.type.idName != "ARMOR_NONE") {
      if (lootPile != null) lootPile.add(armor);
      equippedArmor = null;
    }
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isEnemy {
    if (align == Alignment.conservative) return true;
    if (type.enemyEvenWhenNotConservative && !pool.contains(this)) {
      return true;
    }
    return false;
  }

  bool canDate(Creature other) {
    // Assume animals, tanks, etc. are adults
    // (we will use humorous rejections elsewhere for interspecies)
    int myAge = type.animal ? 20 : age;
    int theirAge = other.type.animal ? 20 : other.age;
    if (myAge < 11 || theirAge < 11) return false;
    if (myAge < 16 && theirAge < 16) return false;
    return true;
  }

  void nameCreature() {
    if (!alreadyNamed) {
      FullName fullName = generateFullName(gender);
      properName = fullName.firstLast;
      name = fullName.firstLast;
      alreadyNamed = true;
    }
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  int get maxSubordinates {
    if (brainwashed) return 0;

    int recruitCap = 0;
    if (level >= 6) {
      recruitCap = 6;
    } else if (level >= 5) {
      recruitCap = 5;
    } else if (level >= 4) {
      recruitCap = 3;
    } else if (level >= 3) {
      recruitCap = 1;
    }
    if (hireId == null && align == Alignment.liberal) recruitCap += 6;
    return recruitCap;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  int get subordinatesLeft {
    int cap = maxSubordinates;
    cap -= pool
        .where((p) => p.hireId == id && !p.seduced && !p.brainwashed)
        .length;
    return cap;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  int get maxRelationships {
    // A polyamorous Liberal's daily affirmation
    // (only one of these actually matters, whichever is best)
    return [
      // I'm good enough
      (attribute(Attribute.heart) - 4) ~/ 2,
      // I'm hot enough
      (attribute(Attribute.charisma) - 4) ~/ 2,
      // And doggone it, people like having sex with me
      (skill(Skill.seduction) / 2 + 1).round(),
    ].reduce(max);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  int get relationshipsLeft => maxRelationships - relationships.length;

  @JsonKey(includeFromJson: false, includeToJson: false)
  Iterable<Creature> get relationships {
    return pool.where(
        (p) => (p.hireId == id && p.seduced) || (seduced && p.id == hireId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  int get scheduledMeetings {
    return recruitmentSessions.where((m) => m.recruiter.id == id).length;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  int get scheduldeDates {
    return datingSessions
        .where((m) => m.lcsMember.id == id)
        .fold(0, (previousValue, element) => element.dates.length);
  }

  void skillUp() {
    for (Skill skill in rawSkill.keys) {
      int skillxp = rawSkillXP[skill] ?? 0;
      int level = rawSkill[skill]!;
      int cap = skillCap(skill);
      while (skillxp >= skillXpNeeded(level) && level < cap) {
        skillxp -= skillXpNeeded(level);
        rawSkillXP[skill] = skillxp;
        rawSkill[skill] = ++level;
      }
      if (level >= skillCap(skill)) rawSkillXP[skill] = 0;
    }
  }

  void criminalize(Crime crime) {
    if (mode == GameMode.site) {
      if (activeSiteUnderSiege &&
          activeSite?.siege.activeSiegeType != SiegeType.police) {
        // Attacked by an illegal raid; nobody is reporting anything
        return;
      }
      if (activeSite?.controller == SiteController.ccs) {
        // Attacking CCS safehouse; nobody is reporting anything
        return;
      }
    }
    wantedForCrimes[crime] = (wantedForCrimes[crime] ?? 0) + 1;
    heat += crimeHeat(crime);
  }

  void giveArmorType(String armorTypeString, {List<Item>? lootPile}) {
    strip(lootPile: lootPile);
    if (armorTypeString == "ARMOR_NONE" || armorTypeString.isEmpty) return;
    giveArmor(Armor(armorTypeString));
  }

  void giveWeaponAndAmmo(String weaponTypeString, int ammo,
      {List<Item>? lootPile}) {
    dropWeaponAndAmmo(lootPile: lootPile);
    if (weaponTypeString == "WEAPON_NONE" || weaponTypeString.isEmpty) return;
    WeaponType? weaponType = weaponTypes[weaponTypeString];
    if (weaponType == null) {
      debugPrint(
          "Invalid weapon type passed to giveWeaponAndAmmo: $weaponTypeString");
      return;
    }
    giveWeapon(Weapon.fromType(weaponType, fullammo: true));
    if (ammo > 1 && (weapon.type.usesAmmo || weapon.type.thrown)) {
      AmmoType? ammoType = weaponType.ammoType;
      if (ammoType != null) {
        spareAmmo = Ammo(ammoType.idName, stackSize: ammo - 1);
      } else if (weaponType.thrown) {
        spareAmmo = Weapon(weaponType.idName, stackSize: ammo - 1);
      }
    }
  }

  void giveWeapon(Weapon weapon, [List<Item>? lootPile]) {
    debugPrint(
        "Give weapon: ${weapon.getName()}, stackSize: ${weapon.stackSize}");
    if (weapon.stackSize == 0) {
      return;
    }
    if (weapon.stackSize > 1) {
      weapon = weapon.split(1) as Weapon;
    } else if (lootPile != null && lootPile.contains(weapon)) {
      lootPile.remove(weapon);
    }
    Weapon? current = equippedWeapon;
    if (current == null) {
      dropWeaponAndAmmo(lootPile: lootPile);
      equippedWeapon = weapon;
    } else {
      if (current.type.thrown && weapon.type == current.type) {
        int takeNumber = 10 - current.stackSize;
        if (takeNumber > 0) {
          current.stackSize += 1;
          weapon.stackSize -= 1;
        }
      } else {
        dropWeapon(lootPile: lootPile);
        equippedWeapon = weapon;
        if (spareAmmo != null &&
            !weapon.acceptableAmmo.contains(current.type)) {
          dropAmmo(lootPile: lootPile);
        }
      }
    }
  }

  void giveArmor(Armor armor, [List<Item>? lootPile]) {
    if (equippedArmor != null) strip(lootPile: lootPile);
    equippedArmor = armor.split(1) as Armor;
  }

  void takeAmmo(Ammo ammo, List<Item>? lootPile, int count) {
    if (weapon.acceptableAmmo.contains(ammo.type)) {
      Item? spare = spareAmmo;
      if (spare != null && spare.type == ammo.type) {
        int numToTake = min(count, 9 - spare.stackSize);
        if (numToTake > 0) {
          spare.stackSize += numToTake;
          ammo.stackSize -= numToTake;
        }
      } else {
        dropAmmo(lootPile: lootPile);
        spareAmmo = ammo.split([9, ammo.stackSize, count].reduce(min)) as Ammo;
      }
    }
  }
}

class JsonCreatureReferenceById implements JsonConverter<Creature, int> {
  const JsonCreatureReferenceById();

  @override
  Creature fromJson(int json) {
    return pool.firstWhere((element) => element.id == json);
  }

  @override
  int toJson(Creature object) {
    return object.id;
  }
}
