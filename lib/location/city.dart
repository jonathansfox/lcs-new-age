import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/district.dart';
import 'package:lcs_new_age/location/location.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';

part 'city.g.dart';

@JsonSerializable()
class City extends Location {
  City(this.name, this.shortName, this.description, {int? area})
      : id = gameState.nextCityId++,
        area = area ?? gameState.nextCityId - 1;
  factory City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);
  Map<String, dynamic> toJson() => _$CityToJson(this);

  int id;

  @override
  String get idString => "City$id";

  @override
  String name;
  String shortName;
  @override
  int area;

  String description;

  List<District> districts = [];

  @JsonKey(includeToJson: false)
  Iterable<Site> get sites => districts.expand((d) => d.sites);

  @override
  @JsonKey(includeToJson: false)
  City get city => this;

  @override
  void init() {}

  @override
  String getName({bool short = false, bool includeCity = false}) {
    return short ? shortName : name;
  }

  void addCommercialDistrict() {
    addDistrict("Shopping", "Shopping").addSites([
      SiteType.departmentStore,
      SiteType.pawnShop,
      SiteType.oubliette,
      SiteType.carDealership,
    ]);
  }

  District addDistrict(String name, String description,
      {bool outOfTown = false}) {
    District d =
        District(name, description, id, area: outOfTown ? -area : area);
    districts.add(d);
    return d;
  }
}
