import 'package:lcs_new_age/saveload/parse_value.dart';
import 'package:lcs_new_age/vehicles/vehicle_type.dart';
import 'package:xml/xml.dart';

void parseVehicleType(VehicleType type, XmlElement xml) {
  for (XmlElement element in xml.childElements) {
    String key = element.name.local;
    switch (key) {
      case "year":
        for (XmlElement element in element.childElements) {
          String key = element.name.local;
          switch (key) {
            case "start_at_current_year":
              type.yearStart =
                  parseBool(element.innerText) == true ? null : type.yearStart;
            case "start_at_year":
              type.yearStart =
                  int.tryParse(element.innerText) ?? type.yearStart;
            case "add_random_up_to_current_year":
              type.yearAddRandomUpToCurrent =
                  parseBool(element.innerText) ?? type.yearAddRandomUpToCurrent;
            case "add_random":
              type.yearAddRandom =
                  int.tryParse(element.innerText) ?? type.yearAddRandom;
            case "add":
              type.yearAdd = int.tryParse(element.innerText) ?? type.yearAdd;
          }
        }
      case "colors":
        for (XmlElement element in element.childElements) {
          if (element.name.local == "color") {
            type.colors.add(element.innerText);
          } else if (element.name.local == "display_color") {
            type.displayColor =
                parseBool(element.innerText) ?? type.displayColor;
          }
        }
      case "drivebonus":
        type.driveBonus = int.tryParse(element.innerText) ?? type.driveBonus;
      case "longname":
        type.longName = element.innerText;
      case "shortname":
        type.shortName = element.innerText;
      case "stealing":
        for (XmlElement element in element.childElements) {
          String key = element.name.local;
          switch (key) {
            case "difficulty_to_find":
              type.difficultyToFind =
                  int.tryParse(element.innerText) ?? type.difficultyToFind;
            case "juice":
              type.juice = int.tryParse(element.innerText) ?? type.juice;
            case "extra_heat":
              type.extraHeat =
                  int.tryParse(element.innerText) ?? type.extraHeat;
            case "sense_alarm_chance":
              type.senseAlarmChance =
                  int.tryParse(element.innerText) ?? type.senseAlarmChance;
            case "touch_alarm_chance":
              type.touchAlarmChance =
                  int.tryParse(element.innerText) ?? type.touchAlarmChance;
          }
        }
      case "available_at_dealership":
        type.availableAtDealership =
            parseBool(element.innerText) ?? type.availableAtDealership;
      case "price":
        type.price = int.tryParse(element.innerText) ?? type.price;
      case "sleeperprice":
        type.sleeperprice =
            int.tryParse(element.innerText) ?? type.sleeperprice;
    }
  }
}
