import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';
import 'package:lcs_new_age/vehicles/vehicle_type.dart';

part 'vehicle.g.dart';

@JsonSerializable()
class Vehicle {
  Vehicle(this.typeName, {int? id}) : id = id ?? gameState.nextVehicleId++ {
    color = type.colors.random;
    year = type.makeYear();
  }
  factory Vehicle.fromJson(Map<String, dynamic> json) =>
      _$VehicleFromJson(json);
  Map<String, dynamic> toJson() => _$VehicleToJson(this);

  int id;
  late String typeName;
  late String color;
  late int year;
  int heat = 0;
  int? locationId;
  @JsonKey(includeToJson: false, includeFromJson: false)
  VehicleType get type => vehicleTypes[typeName]!;
  @JsonKey(includeToJson: false, includeFromJson: false)
  Site? get location => locationId != null ? sites[locationId!] : null;
  set location(Site? site) => locationId = site?.id;
  @JsonKey(includeToJson: false, includeFromJson: false)
  String get shortName => type.shortName;

  String fullName({bool extraVerbose = false}) {
    String s = '';
    int words = 0;
    if (heat > 0) {
      s = "Stolen ";
      words++;
    }
    if (type.displayColor) {
      s += "$color ";
      words++;
    }
    if (words < 2) {
      s += "$year ";
    }
    if (!extraVerbose) {
      s += type.shortName;
    } else {
      s += type.longName;
    }
    return s;
  }
}
