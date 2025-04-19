import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/creature/aging.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/items/clothing.dart';
import 'package:lcs_new_age/items/weapon.dart';

part 'body.g.dart';

Body dogBody() {
  return HumanoidBody()
    ..type = BodyType.canine
    ..typeName = "Dog"
    ..naturalWeapon = Weapon("WEAPON_BITE")
    ..maxTeeth = 42
    ..teeth = 42
    ..leftLeg.name = "Left Rear Leg"
    ..leftLeg.size = 1
    ..rightLeg.name = "Right Rear Leg"
    ..rightLeg.size = 1
    ..leftArm.name = "Left Front Leg"
    ..leftArm.size = 1
    ..rightArm.name = "Right Front Leg"
    ..rightArm.size = 1;
}

Body monsterBody() {
  return HumanoidBody()
    ..type = BodyType.monster
    ..typeName = "Monster"
    ..naturalWeapon = Weapon("WEAPON_BITE");
}

Body purpleGorillaBody() {
  return HumanoidBody()
    ..type = BodyType.purpleGorilla
    ..typeName = "Purple Gorilla";
}

Body warpedBearBody() {
  return HumanoidBody()
    ..type = BodyType.warpedBear
    ..typeName = "Warped Bear"
    ..naturalWeapon = Weapon("WEAPON_BITE")
    ..maxTeeth = 42
    ..teeth = 42
    ..leftLeg.name = "Left Rear Leg"
    ..rightLeg.name = "Right Rear Leg"
    ..leftArm.name = "Left Front Leg"
    ..rightArm.name = "Right Front Leg";
}

Body pinkElephantBody() {
  return HumanoidBody()
    ..type = BodyType.pinkElephant
    ..typeName = "Pink Elephant"
    ..maxTeeth = 26
    ..teeth = 26
    ..leftLeg.name = "Left Rear Leg"
    ..rightLeg.name = "Right Rear Leg"
    ..leftArm.name = "Left Front Leg"
    ..rightArm.name = "Right Front Leg";
}

Body madCowBody() {
  return HumanoidBody()
    ..type = BodyType.madCow
    ..typeName = "Mad Cow"
    ..leftLeg.name = "Left Rear Leg"
    ..leftLeg.size = 1
    ..rightLeg.name = "Right Rear Leg"
    ..rightLeg.size = 1
    ..leftArm.name = "Left Front Leg"
    ..leftArm.size = 1
    ..rightArm.name = "Right Front Leg"
    ..rightArm.size = 1;
}

Body sixLeggedPigBody() {
  return SixLeggedPigBody();
}

Body flamingRabbitBody() {
  return HumanoidBody()
    ..type = BodyType.flamingRabbit
    ..typeName = "Flaming Rabbit"
    ..naturalWeapon = Weapon("WEAPON_FIRE_BREATH")
    ..maxTeeth = 36
    ..teeth = 36
    ..leftLeg.name = "Left Rear Leg"
    ..leftLeg.size = 1
    ..rightLeg.name = "Right Rear Leg"
    ..rightLeg.size = 1
    ..leftArm.name = "Left Front Leg"
    ..leftArm.size = 1
    ..rightArm.name = "Right Front Leg"
    ..rightArm.size = 1;
}

Body giantMosquitoBody() {
  return HumanoidBody()
    ..type = BodyType.giantMosquito
    ..typeName = "Giant Mosquito"
    ..naturalWeapon = Weapon("WEAPON_PROBOSCIS")
    ..maxTeeth = 0
    ..teeth = 0
    ..leftLeg.name = "Left Rear Leg"
    ..leftLeg.size = 1
    ..rightLeg.name = "Right Rear Leg"
    ..rightLeg.size = 1
    ..leftArm.name = "Left Front Leg"
    ..leftArm.size = 1
    ..rightArm.name = "Right Front Leg"
    ..rightArm.size = 1;
}

@JsonSerializable()
class SixLeggedPigBody extends HumanoidBody {
  SixLeggedPigBody() : super() {
    type = BodyType.sixLeggedPig;
    typeName = "Six-Legged Pig";
    maxTeeth = 44;
    teeth = 44;
    leftLeg.name = "Left Rear Leg";
    rightLeg.name = "Right Rear Leg";
    leftArm.name = "Left Front Leg";
    rightArm.name = "Right Front Leg";
  }

  factory SixLeggedPigBody.fromJson(Map<String, dynamic> json) =>
      _$SixLeggedPigBodyFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$SixLeggedPigBodyToJson(this);

  BodyPart rightMiddleLeg = BodyPart("Right Middle Leg", size: 1);
  BodyPart leftMiddleLeg = BodyPart("Left Middle Leg", size: 1);

  @override
  List<BodyPart> get parts => super.parts + [leftMiddleLeg, rightMiddleLeg];
}

@JsonSerializable()
class TankBody extends Body {
  TankBody()
      : super(
          Weapon("WEAPON_120MM_CANNON"),
          Clothing("CLOTHING_COMPOSITE_ARMOR"),
        );
  factory TankBody.fromJson(Map<String, dynamic> json) =>
      _$TankBodyFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$TankBodyToJson(this);
  @override
  BodyType get type => BodyType.tank;
  @override
  String get typeName => "Tank";
  @override
  bool get canWalk => true;
  @override
  bool get canSee => true;
  @override
  bool get missingTeeth => false;
  @override
  bool get noTeeth => false;
  @override
  bool get fullParalysis => false;
  @override
  bool get partialParalysis => !leftTrack.missing && !rightTrack.missing;
  @override
  String? specialInjuryDescription(bool small) => null;
  @override
  List<String> allSpecialInjuries() => [];
  @override
  int permanentAttributeMods(Attribute a, int value, int age) => value;
  @override
  int get combatRollModifier => 0;
  @override
  int get armok => 0;
  @override
  int get legok => [leftTrack, rightTrack].where((t) => !t.missing).length;
  @override
  int get eyeok => 2;
  @override
  int get teeth => 0;

  BodyPart turretRear = BodyPart("Turret Rear",
      size: 5, critical: true, weakSpot: true, naturalArmor: 10);
  BodyPart turretFront =
      BodyPart("Turret Front", size: 5, critical: true, naturalArmor: 20);
  BodyPart frontArmor =
      BodyPart("Front", size: 5, critical: true, naturalArmor: 20);
  BodyPart rearArmor = BodyPart("Rear",
      size: 3, critical: true, weakSpot: true, naturalArmor: 10);
  BodyPart leftSide =
      BodyPart("Left Side", size: 7, critical: true, naturalArmor: 15);
  BodyPart rightSide =
      BodyPart("Right Side", size: 7, critical: true, naturalArmor: 15);
  BodyPart leftTrack =
      BodyPart("Left Track", size: 4, weakSpot: true, naturalArmor: 10);
  BodyPart rightTrack =
      BodyPart("Right Track", size: 4, weakSpot: true, naturalArmor: 10);

  @override
  List<BodyPart> get parts => [
        turretRear,
        turretFront,
        frontArmor,
        rearArmor,
        leftSide,
        rightSide,
        leftTrack,
        rightTrack,
      ];

  @override
  Iterable<BodyPart> get arms => [];

  @override
  Iterable<BodyPart> get legs => [leftTrack, rightTrack];

  @override
  bool get fellApart => false;
}

enum InjuryState {
  healthy,
  untreated,
  treated,
}

@JsonSerializable()
class HumanoidBody extends Body {
  HumanoidBody()
      : super(
          Weapon("WEAPON_NONE"),
          Clothing("CLOTHING_NONE"),
        );
  factory HumanoidBody.fromJson(Map<String, dynamic> json) =>
      _$HumanoidBodyFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$HumanoidBodyToJson(this);

  @override
  int teeth = 32;
  int maxTeeth = 32;
  int ribs = 10;
  int maxRibs = 10;

  BodyPart leftLeg = BodyPart("Left Leg", immuneInCar: true);
  BodyPart rightLeg = BodyPart("Right Leg", immuneInCar: true);
  BodyPart leftArm = BodyPart("Left Arm");
  BodyPart rightArm = BodyPart("Right Arm");
  BodyPart head = BodyPart("Head", size: 1, critical: true, weakSpot: true);
  BodyPart torso = BodyPart("Torso", size: 4, critical: true);

  bool missingRightEye = false;
  bool missingLeftEye = false;
  bool missingNose = false;
  bool missingTongue = false;
  bool puncturedRightLung = false;
  bool puncturedLeftLung = false;
  bool puncturedHeart = false;
  bool puncturedLiver = false;
  bool puncturedStomach = false;
  bool puncturedRightKidney = false;
  bool puncturedLeftKidney = false;
  bool puncturedSpleen = false;
  InjuryState neck = InjuryState.healthy;
  bool get brokenNeck => neck != InjuryState.healthy;
  InjuryState upperSpine = InjuryState.healthy;
  bool get brokenUpperSpine => upperSpine != InjuryState.healthy;
  InjuryState lowerSpine = InjuryState.healthy;
  bool get brokenLowerSpine => lowerSpine != InjuryState.healthy;

  int get intactLegs => (leftLeg.missing ? 0 : 1) + (rightLeg.missing ? 0 : 1);
  int get intactArms => (leftArm.missing ? 0 : 1) + (rightArm.missing ? 0 : 1);
  int get intactEyes => (missingRightEye ? 0 : 1) + (missingLeftEye ? 0 : 1);

  @override
  bool get fellApart => torso.cleanOff || torso.nastyOff;

  @override
  int get armok => fullParalysis ? 0 : intactArms;
  @override
  int get legok => partialParalysis ? 0 : intactLegs;
  @override
  int get eyeok => intactEyes;

  @override
  BodyType type = BodyType.human;
  @override
  String typeName = "Human";
  @override
  List<BodyPart> get parts =>
      [leftLeg, rightLeg, leftArm, rightArm, head, torso];
  @override
  bool get canWalk => intactLegs > 0 && !partialParalysis;
  @override
  bool get canSee => intactEyes > 0;
  @override
  bool get missingTeeth => teeth < maxTeeth;
  bool get halfTeeth => teeth < maxTeeth / 2;
  @override
  bool get noTeeth => teeth == 0;
  @override
  bool get fullParalysis => brokenNeck || brokenUpperSpine;
  @override
  bool get partialParalysis => brokenLowerSpine || fullParalysis;
  @override
  Iterable<BodyPart> get arms => [leftArm, rightArm];
  @override
  Iterable<BodyPart> get legs => [leftLeg, rightLeg];
  @override
  String? specialInjuryDescription(bool small) {
    if (brokenNeck) {
      return small ? "NckBroke" : "Neck Broken";
    } else if (brokenUpperSpine) {
      return small ? "Quadpleg" : "Quadraplegic";
    } else if (brokenLowerSpine) {
      return small ? "Parapleg" : "Paraplegic";
    } else if (intactEyes == 0 && missingNose) {
      return small ? "FaceGone" : "Face Gone";
    } else if (intactLegs + intactArms == 0) {
      return "No Limbs";
    } else if (intactLegs + intactArms == 1) {
      return "One Limb";
    } else if (intactLegs == 2 && intactArms == 0) {
      return "No Arms";
    } else if (intactLegs == 0 && intactArms == 2) {
      return "No Legs";
    } else if (intactLegs == 1 && intactArms == 1) {
      return small ? "1Arm1Leg" : "One Arm, One Leg";
    } else if (intactArms == 1) {
      return "One Arm";
    } else if (intactLegs == 1) {
      return "One Leg";
    } else if (intactEyes == 1 && missingNose) {
      return small ? "FaceMutl" : "Face Mutated";
    } else if (intactEyes == 1) {
      return small ? "One Eye" : "Missing Eye";
    } else if (missingNose) {
      return small ? "NoseGone" : "Missing Nose";
    } else if (missingTongue) {
      return small ? "NoTongue" : "No Tongue";
    } else if (missingTeeth && noTeeth) {
      return "No Teeth";
    } else if (missingTeeth && noTeeth) {
      return small ? "MisTeeth" : "Missing Teeth";
    }
    return null;
  }

  @override
  List<String> allSpecialInjuries() {
    List<String> injuries = [];
    if (puncturedHeart) injuries.add("Heart Punctured");
    if (puncturedRightLung) injuries.add("R. Lung Collapsed");
    if (puncturedLeftLung) injuries.add("L. Lung Collapsed");
    if (brokenNeck) injuries.add("Broken Neck");
    if (brokenUpperSpine) injuries.add("Broken Up Spine");
    if (brokenLowerSpine) injuries.add("Broken Lw Spine");
    if (missingRightEye) injuries.add("No Right Eye");
    if (missingLeftEye) injuries.add("No Left Eye");
    if (missingNose) injuries.add("No Nose");
    if (missingTongue) injuries.add("No Tongue");
    if (missingTeeth) {
      if (noTeeth) {
        injuries.add("No Teeth");
      } else if (halfTeeth) {
        injuries.add("Half Teeth");
      } else if (teeth == maxTeeth - 1) {
        injuries.add("Missing a Tooth");
      } else {
        injuries.add("Missing Teeth");
      }
    }
    if (puncturedLiver) injuries.add("Liver Damaged");
    if (puncturedRightKidney) injuries.add("R. Kidney Damaged");
    if (puncturedLeftKidney) injuries.add("L. Kidney Damaged");
    if (puncturedStomach) injuries.add("Stomach Injured");
    if (puncturedSpleen) injuries.add("Busted Spleen");
    if (ribs < maxRibs) {
      if (ribs == 0) {
        injuries.add("All Ribs Broken");
      } else if (ribs == maxRibs - 1) {
        injuries.add("Broken Rib");
      } else {
        injuries.add("Broken Ribs");
      }
    }
    return injuries;
  }

  int get disfigurationLevel {
    int disfigs = 0;
    if (missingTeeth) disfigs++;
    if (halfTeeth) disfigs++;
    if (noTeeth) disfigs++;
    if (missingLeftEye) disfigs += 2;
    if (missingRightEye) disfigs += 2;
    if (missingTongue) disfigs += 3;
    if (missingNose) disfigs += 3;
    return disfigs;
  }

  @override
  int permanentAttributeMods(Attribute a, int value, int age) {
    if (a == Attribute.strength && age < 11) {
      value = (value / 2).round();
    } else {
      value += ageModifierForAttribute(a, age);
    }
    if (a == Attribute.strength && paralyzed) {
      if (fullParalysis) value = (value / 4).round();
      if (partialParalysis) value = (value / 2).round();
    }
    if (a == Attribute.agility) {
      if (!canWalk) value = (value / 4).round();
    }
    if (a == Attribute.charisma) {
      value -= disfigurationLevel;
    }
    return value;
  }

  @override
  int get combatRollModifier {
    double modifier = 0;
    if (missingLeftEye && missingRightEye) modifier += 5;
    if (puncturedRightLung) modifier += 2;
    if (puncturedLeftLung) modifier += 2;
    if (puncturedHeart) modifier += 2;
    if (puncturedLiver) modifier += 1;
    if (puncturedStomach) modifier += 1;
    if (puncturedRightKidney) modifier += 1;
    if (puncturedLeftKidney) modifier += 1;
    if (puncturedSpleen) modifier += 1;
    if (brokenUpperSpine) modifier += 25;
    if (brokenLowerSpine) modifier += 50;
    if (brokenNeck) modifier += 75;
    if (ribs < 10) modifier += 1;
    if (ribs < 5) modifier += 1;
    if (ribs <= 0) modifier += 1;
    return modifier.round();
  }
}

abstract class Body {
  Body(this.naturalWeapon, this.naturalArmor);
  factory Body.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case "tank":
        return TankBody.fromJson(json);
      case "sixLeggedPig":
        return SixLeggedPigBody.fromJson(json);
      default:
        return HumanoidBody.fromJson(json);
    }
  }
  Map<String, dynamic> toJson() {
    if (this is TankBody) {
      return (this as TankBody).toJson();
    } else if (this is SixLeggedPigBody) {
      return (this as SixLeggedPigBody).toJson();
    } else {
      return (this as HumanoidBody).toJson();
    }
  }

  Weapon naturalWeapon;
  Clothing naturalArmor;

  BodyType get type;
  String get typeName;
  List<BodyPart> get parts;
  bool get canWalk;
  bool get canSee;
  bool get missingTeeth;
  bool get noTeeth;
  bool get fullParalysis;
  bool get partialParalysis;
  bool get paralyzed => fullParalysis || partialParalysis;
  bool get fellApart;
  Iterable<BodyPart> get arms;
  Iterable<BodyPart> get legs;
  String? specialInjuryDescription(bool small);
  List<String> allSpecialInjuries();
  int permanentAttributeMods(Attribute a, int value, int age);
  int get combatRollModifier;
  int get armok;
  int get legok;
  int get eyeok;
  int get teeth;
}

@JsonSerializable()
class BodyPart {
  BodyPart(
    this.name, {
    this.size = 2,
    this.critical = false,
    this.weakSpot = false,
    this.immuneInCar = false,
    this.naturalArmor = 0,
  });
  factory BodyPart.fromJson(Map<String, dynamic> json) =>
      _$BodyPartFromJson(json);
  Map<String, dynamic> toJson() => _$BodyPartToJson(this);
  String name;
  int size;
  int naturalArmor;
  bool critical;
  bool weakSpot;
  bool immuneInCar;
  bool shot = false;
  bool cut = false;
  bool bruised = false;
  bool burned = false;
  @JsonKey(defaultValue: 0, name: "bleedingStacks")
  int bleeding = 0;
  bool torn = false;
  bool nastyOff = false;
  bool cleanOff = false;
  @JsonKey(defaultValue: 1)
  double relativeHealth = 1;

  bool get missing => nastyOff || cleanOff;
  bool get wounded =>
      shot ||
      cut ||
      bruised ||
      burned ||
      bleeding > 0 ||
      torn ||
      nastyOff ||
      cleanOff ||
      relativeHealth < 1;

  void heal() {
    shot = false;
    cut = false;
    bruised = false;
    burned = false;
    bleeding = 0;
    torn = false;
    if (nastyOff) {
      nastyOff = false;
      cleanOff = true;
    }
    if (!cleanOff) {
      relativeHealth = 1;
    }
  }
}

enum BodyType {
  human,
  canine,
  tank,
  sixLeggedPig,
  flamingRabbit,
  giantMosquito,
  purpleGorilla,
  madCow,
  warpedBear,
  pinkElephant,
  monster,
}
