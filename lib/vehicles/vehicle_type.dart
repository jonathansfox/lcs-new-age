import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Map<String, VehicleType> vehicleTypes = {};

class VehicleType {
  VehicleType(String definition)
      : longName = definition,
        shortName = definition,
        idName = definition {
    vehicleTypes[idName] = this;
  }
  String longName;
  String shortName;
  String idName;
  int? yearStart;
  bool yearAddRandomUpToCurrent = false;
  int yearAddRandom = 0;
  int yearAdd = 0;
  int driveBonus = 0;
  List<String> colors = [];
  bool displayColor = true;
  int difficultyToFind = 1;
  int juice = 0;
  int extraHeat = 0;
  int senseAlarmChance = 0;
  int touchAlarmChance = 0;
  bool availableAtDealership = true;
  int price = 1234;
  int sleeperprice = 1111;

  int makeYear() =>
      (yearStart ?? year) +
      (yearAddRandomUpToCurrent ? lcsRandom(year - (yearStart ?? year)) : 0) +
      lcsRandom(yearAddRandom) +
      yearAdd;
}

class VehicleTypeIds {
  static const String bug = "BUG";
  static const String humvee = "HMMWV";
  static const String jeep = "JEEP";
  static const String pickup = "PICKUP";
  static const String policeCar = "POLICECAR";
  static const String agentCar = "AGENTCAR";
  static const String sportsCar = "SPORTSCAR";
  static const String stationWagon = "STATIONWAGON";
  static const String suv = "SUV";
  static const String taxicab = "TAXICAB";
  static const String van = "VAN";
}
