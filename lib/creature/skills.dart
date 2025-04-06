import 'package:lcs_new_age/creature/attributes.dart';

int skillXpNeeded(int skillLevel) => 100 + 10 * skillLevel;

enum Skill {
  art(Attribute.heart, "Art", "Create visual works of beauty.",
      classText: "Painting, color theory, and more."),
  business(Attribute.intelligence, "Business",
      "Talk about economics. Earn lots of money.",
      classText: "Economics and business management."),
  computers(
      Attribute.intelligence, "Computers", "Mastery of computers. Hacking.",
      classText: "Computer science and programming."),
  disguise(Attribute.charisma, "Disguise", "Look and act like you belong.",
      classText: "Acting. Theater. Become a character."),
  dodge(Attribute.agility, "Dodge", "Avoid attacks. Utilize cover.",
      classText: "Master dancing. Move like water."),
  driving(
      Attribute.agility, "Driving", "Race cars without crashing. Do stunts.",
      classText: "Advanced vehicle handling and racing."),
  firstAid(Attribute.intelligence, "First Aid",
      "Staunch bleeding, treat wounds at base.",
      classText: "Identify and treat injuries."),
  heavyWeapons(Attribute.strength, "Heavy Weapons",
      "Use machine guns and flamethrowers.",
      canTakeClasses: false),
  law(Attribute.intelligence, "Law", "Understand the law. Defend yourself.",
      classText: "Criminal justice law and procedure."),
  martialArts(
      Attribute.strength, "Martial Arts", "Fighting with or without weapons.",
      classText: "Train with your body and melee weapons."),
  music(Attribute.heart, "Music", "Inspire with musical instruments.",
      classText: "Play instruments and learn music theory."),
  persuasion(
      Attribute.charisma, "Persuasion", "Recruit allies and argue verbally.",
      classText: "Make speeches, learn rhetoric and debate."),
  firearms(Attribute.agility, "Firearms", "Effectively use guns in combat.",
      classText: "Safely maintain and shoot firearms."),
  psychology(Attribute.intelligence, "Psychology",
      "Sustain or shatter the human psyche.",
      classText: "Study of the human mind and its functions."),
  religion(
      Attribute.intelligence, "Religion", "Understand and manipulate faith.",
      classText: "Theology and religious studies."),
  science(Attribute.intelligence, "Science",
      "Defend or apply scientific knowledge.",
      classText: "Chemistry, biology, physics, and more."),
  security(Attribute.intelligence, "Security", "Open locks and disable alarms.",
      canTakeClasses: false),
  stealth(Attribute.agility, "Stealth", "Move unseen and unheard.",
      canTakeClasses: false),
  streetSmarts(Attribute.intelligence, "Street Smarts",
      "Navigate cities and avoid police.",
      canTakeClasses: false),
  tailoring(Attribute.intelligence, "Tailoring", "Make and repair clothing.",
      classText: "Sewing, pattern making, and more."),
  teaching(Attribute.charisma, "Teaching", "Teach others what you know.",
      classText: "The method and practice of pedagogy."),
  throwing(Attribute.agility, "Throwing", "Throw a molotov. Or other things.",
      canTakeClasses: false),
  writing(Attribute.intelligence, "Writing",
      "Write effective articles and letters.",
      classText: "Creative writing and essays."),
  seduction(
      Attribute.heart, "Seduction", "Make others want you, then satisfy them.",
      canTakeClasses: false),
  ;

  const Skill(this.attribute, this.displayName, this.description,
      {this.canTakeClasses = true, String? classText})
      : _classText = classText;
  final Attribute attribute;
  final String displayName;
  final String description;
  final bool canTakeClasses;
  final String? _classText;
  String get classText => _classText ?? description;
}
