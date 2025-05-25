import 'package:collection/collection.dart';
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/common_display/print_party.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/squad.dart';
import 'package:lcs_new_age/location/city.dart';
import 'package:lcs_new_age/location/district.dart';
import 'package:lcs_new_age/location/location.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';

const int intercityTicketPrice = 100;

Future<void> planSiteVisit() async {
  Squad? aSquad = activeSquad;
  if (aSquad == null || squad.isEmpty) return;
  bool haveCar = squad.any((s) => s.preferredCar != null);
  Site? squadLocation = aSquad.site;
  Location? area = squadLocation?.city;
  int ticketPrice = squad.length * intercityTicketPrice;
  int page = 0;

  while (true) {
    erase();
    mvaddstrc(0, 0, lightGray, "Where will the Squad go?");
    printParty(fullParty: true);
    if (area != null) mvaddstrc(8, 0, lightGray, area.name);
    List<Location> destinationList;
    if (area is City) {
      destinationList = [...area.districts];
    } else if (area is District) {
      destinationList = <Site>[...area.sites.whereNot((s) => s.hidden)]
        ..sort((a, b) => a.controller.index.compareTo(b.controller.index));
    } else {
      destinationList = [...cities];
    }

    int y = 10;
    for (int p = page * 11;
        p < destinationList.length && p < page * 11 + 11;
        p++) {
      Location thisLocation = destinationList[p];
      Site? thisSite = (thisLocation is Site) ? thisLocation : null;
      District? thisDistrict = (thisLocation is District) ? thisLocation : null;
      City? thisCity = (thisLocation is City) ? thisLocation : null;
      String name = thisLocation.getName();
      String letter = letterAPlus(y - 10);
      addOptionText(y, 0, letter, "$letter - $name",
          enabledWhen: thisSite?.isClosed != true &&
              thisSite?.siege.underSiege != true &&
              (thisLocation.area == squadLocation?.area || haveCar));
      if (thisLocation == squadLocation ||
          thisCity == squadLocation?.city ||
          thisDistrict == squadLocation?.district) {
        addstrc(white, " (Current Location)");
      } else if (thisSite?.controller == SiteController.lcs) {
        if (thisSite!.heatProtection <= 5) {
          addstrc(lightGreen, " (LCS Temp Shelter)");
        } else {
          if (thisSite.creaturesPresent.isEmpty &&
              !thisSite.compound.upgraded) {
            addstrc(lightGreen, " (Potential Safehouse)");
          } else {
            addstrc(lightGreen, " (LCS Safehouse)");
          }
        }
      } else if (thisSite?.controller == SiteController.ccs &&
          (ccsInPublicEye || thisSite?.mapped == true)) {
        addstrc(red, " (CCS Safehouse)");
      } else if (thisSite?.isClosed == true) {
        addstrc(red, " (Closed Down)");
      } else if (thisSite?.hasHighSecurity == true) {
        addstrc(pink, " (High Security)");
      }
      if (thisLocation.area != squadLocation?.area && !haveCar) {
        addstrc(yellow, " (Need Car)");
      }
      if (thisSite?.siege.underSiege == true) {
        addstrc(red, " (Under Siege)");
      }
      if (thisSite != null && thisSite.controller == SiteController.lcs) {
        int heat = thisSite.heat;
        int heatProtection = thisSite.heatProtection;
        mvaddstrc(y, 54, lightGray, "Heat: ");
        addstrc(heat > heatProtection ? red : darkGray, "$heat");
        mvaddstrc(y, 66, lightGray, "Secrecy: ");
        addstrc(heat > heatProtection ? red : darkGray, "$heatProtection");
      }
      if (thisCity != null) {
        mvaddstrc(y, 50, darkGray, thisCity.description);
      }
      y++;
    }
    if (area == squadLocation?.city) {
      String letter = letterAPlus(y - 10);
      addOptionText(y, 0, letter, "$letter - Travel to a Different City",
          enabledWhen: haveCar && ledger.funds >= ticketPrice);
      if (!haveCar) addstrc(yellow, " (Need Car)");
      addstrc(ledger.funds < ticketPrice ? red : green, " (\$$ticketPrice)");
    }
    setColor(lightGray);
    if (page > 0) mvaddstr(10, 60, previousPageStr);
    if (page + 1 < destinationList.length / 11) mvaddstr(20, 60, nextPageStr);
    if (area == squadLocation?.city) {
      addOptionText(
          24, 1, "Enter", "Enter - The Squad is not yet Liberal enough");
    } else {
      addOptionText(24, 1, "Enter", "Enter - Back one step");
    }
    int c = await getKey();
    if (isPageUp(c) && page > 0) page--;
    if (isPageDown(c) && page + 1 < destinationList.length / 11) page++;
    if (c >= Key.a && c <= Key.k) {
      int index = page * 11 + c - Key.a;
      if (index >= 0 && index < destinationList.length) {
        Location? oldArea = area;
        area = destinationList[index];
        if (area.area != squadLocation?.area && !haveCar) area = oldArea;
        if (area is Site && !area.isClosed) {
          aSquad.activity =
              Activity(ActivityType.visit, idString: area.idString);
          break;
        }
      } else if (haveCar &&
          area == squadLocation?.city &&
          index == destinationList.length) {
        area = null;
      }
    }
    if (isBackKey(c)) {
      if (area == squadLocation?.city) {
        aSquad.activity = Activity.none();
        break;
      } else if (area is City) {
        area = null;
      } else if (area == null) {
        area = squadLocation?.city;
      } else {
        area = area.city;
      }
    }
  }
}
