import 'package:lcs_new_age/location/city.dart';

abstract class Location {
  String get idString;
  String get name;
  set name(String name);
  int get area;

  City get city;

  void init();
  String getName({bool short = false, bool includeCity = false});
}
