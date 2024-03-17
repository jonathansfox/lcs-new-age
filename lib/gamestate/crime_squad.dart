import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/gamestate/squad.dart';
import 'package:lcs_new_age/vehicles/vehicle.dart';

part 'crime_squad.g.dart';

@JsonSerializable()
class CrimeSquad {
  CrimeSquad();
  factory CrimeSquad.fromJson(Map<String, dynamic> json) =>
      _$CrimeSquadFromJson(json);
  Map<String, dynamic> toJson() => _$CrimeSquadToJson(this);
  List<Creature> pool = [];
  List<Squad> squads = [];
  List<Vehicle> vehiclePool = [];
  String slogan = "We need a slogan!";
}
