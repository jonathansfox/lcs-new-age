import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/activities/recruiting.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/clothing_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/colors.dart';

part 'activities.g.dart';

@JsonSerializable(includeIfNull: false, ignoreUnannotated: true)
class Activity {
  Activity(this.type, {this.skill, this.idInt, this.idString, this.view});
  factory Activity.none() => Activity(ActivityType.none);
  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityToJson(this);
  @JsonKey()
  ActivityType type = ActivityType.none;
  @JsonKey()
  Skill? skill;
  @JsonKey()
  int? idInt;
  @JsonKey()
  String? idString;
  @JsonKey()
  View? view;

  RecruitData? get recruitData =>
      recruitableCreatures.firstWhere((e) => e.type.id == idString);
  Creature? get creature => pool.firstWhereOrNull((e) => e.id == idInt);
  ClothingType? get armorType => clothingTypes[idString];
  Site? get location =>
      gameState.sites.firstWhereOrNull((e) => e.idString == idString);

  String get description {
    switch (type) {
      case ActivityType.interrogation:
        return "Tending to ${creature?.name ?? "a bug"}";
      case ActivityType.makeArmor:
        return "Making ${armorType?.shortName ?? "a bug"}";
      case ActivityType.visit:
        return "Visiting ${location?.name ?? "a bug"}";
      case ActivityType.study:
        return "Studying ${skill?.displayName ?? "a bug"}";
      default:
        return type.label;
    }
  }

  Color get color => type.color;
}

enum ActivityType {
  none("Laying Low", lightGray),
  visit("Visiting", yellow),
  interrogation("Hostage Tending", yellow),
  trouble("Causing Trouble", lightGreen),
  graffiti("Spraying Graffiti", lightGreen),
  communityService("Community Service", blue),
  sellArt("Selling Art", lightBlue),
  sellMusic("Selling Music", lightBlue),
  sellTshirts("Selling T-shirts", lightBlue),
  donations("Soliciting Donations", lightBlue),
  sellDrugs("Selling Brownies", red),
  prostitution("Prostitution", red),
  ccfraud("Credit Card Fraud", red),
  hacking("Hacking", lightGreen),
  makeArmor("Tailoring", lightBlue),
  stealCars("Stealing a Car", lightBlue),
  wheelchair("Procuring a Wheelchair", lightBlue),
  bury("Burying Dead", darkGray),
  writeGuardian("Liberal Guardian Writing", lightGreen),
  streamGuardian("Liberal Guardian Streaming", lightGreen),
  teachLiberalArts("Teaching Liberal Arts", purple),
  teachFighting("Teaching Fighting", purple),
  teachCovert("Teaching Covert Ops", purple),
  study("Studying", pink),
  takeClass("Taking a Class", pink),
  clinic("Going to the Hospital", red),
  sleeperLiberal("Promoting Liberalism", lightGreen),
  sleeperConservative("Spouting Conservatism", red),
  sleeperSpy("Snooping Around", lightBlue),
  sleeperRecruit("Recruiting Sleepers", green),
  sleeperEmbezzle("Embezzling Funds", red),
  sleeperSteal("Stealing Equipment", lightBlue),
  sleeperJoinLcs("Quitting Job", red),
  recruiting("Recruiting", green),
  augment("Augmenting a Liberal", lightBlue);

  const ActivityType(this.label, this.color);

  final String label;
  final Color color;
}
