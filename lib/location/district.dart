import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/city.dart';
import 'package:lcs_new_age/location/location.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';

part 'district.g.dart';

@JsonSerializable(ignoreUnannotated: true)
class District implements Location {
  District(this.shortName, this.name, this.cityId, {required this.area})
      : id = gameState.nextDistrictId++;
  factory District.fromJson(Map<String, dynamic> json) =>
      _$DistrictFromJson(json);
  Map<String, dynamic> toJson() => _$DistrictToJson(this);

  @override
  void init() {}

  @JsonKey()
  int id;
  @JsonKey()
  String shortName;
  @JsonKey()
  int cityId;
  @override
  City get city => cities.firstWhere((city) => city.id == cityId);
  @JsonKey()
  List<Site> sites = [];

  @override
  @JsonKey()
  int area;
  @override
  @JsonKey()
  String name;

  @override
  String getName({bool short = false, bool includeCity = false}) {
    if (short) {
      return shortName;
    } else {
      if (includeCity) {
        return "$name, ${city.name}";
      } else {
        return name;
      }
    }
  }

  @override
  String get idString => "District$id";

  void addSites(List<SiteType> siteTypes) {
    sites.addAll(siteTypes.map((t) => Site(t, city, this)));
  }
}
