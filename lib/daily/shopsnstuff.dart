/* active squad visits the hospital */
import 'package:collection/collection.dart';
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/basemode/base_mode.dart';
import 'package:lcs_new_age/common_actions/common_actions.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/common_display/print_creature_info.dart';
import 'package:lcs_new_age/common_display/print_party.dart';
import 'package:lcs_new_age/creature/body.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/gamestate/squad.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/sitemode/shop.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';
import 'package:lcs_new_age/vehicles/vehicle.dart';
import 'package:lcs_new_age/vehicles/vehicle_type.dart';

Future<void> hospital(Site loc) async {
  locatesquad(activeSquad!, loc);
  int partysize = squadsize(activeSquad);

  while (true) {
    erase();

    locHeader();
    printParty();

    addOptionText(10, 1, "F", "F - Go in and fix up Conservative wounds");
    addOptionText(12, 1, "Enter", "Enter - Leave");

    bool showPartyPrompt =
        partysize > 0 && (activeSquadMemberIndex == -1 || partysize > 1);
    mvaddstrc(13, 1, showPartyPrompt ? lightGray : darkGray,
        "# - Check the status of a squad Liberal");
    bool showStatusPrompt = activeSquadMember != null;
    addOptionText(14, 1, "0", "0 - Show the squad's Liberal status",
        enabledWhen: showStatusPrompt);

    int c = await getKey();

    if (isBackKey(c)) break;

    if (c == '0'.codePoint) activeSquadMemberIndex = -1;

    if (c >= '1'.codePoint && c <= '6'.codePoint && activeSquad != null) {
      int index = c - '1'.codePoint;
      if (squad.length > index) {
        Creature p = squad[index];
        if (p == activeSquadMember) {
          await fullCreatureInfoScreen(p);
        } else {
          activeSquadMember = p;
        }
      }
    }

    if (c == Key.f) {
      for (Creature p in squad.toList()) {
        await hospitalize(loc, p);
      }
      break;
    }
  }
}

Future<void> hospitalize(Site loc, Creature patient) async {
  // He's dead, Jim
  if (!patient.alive) return;

  int time = clinictime(patient);

  if (time > 0) {
    patient.clinicMonthsLeft = time;
    patient.squad = null;
    patient.location = loc;
    patient.activity = Activity.none();

    makeDelimiter();
    mvaddstrc(8, 1, white, "${patient.name} will be at ${loc.name} for $time ");
    if (time > 1) {
      addstr("months");
    } else {
      addstr("month");
    }
    addstr(".");

    await getKey();
  }
}

/* common - determines how long a creature's injuries will take to heal */
int clinictime(Creature g) {
  int time = 0;
  for (BodyPart bp in g.body.parts) {
    if (bp.nastyOff) time++;
  }
  if (g.blood <= g.maxBlood * 0.1) time++;
  if (g.blood <= g.maxBlood * 0.5) time++;
  if (g.blood < g.maxBlood) time++;
  if (g.body is HumanoidBody) {
    HumanoidBody body = g.body as HumanoidBody;
    if (body.puncturedRightLung) time++;
    if (body.puncturedLeftLung) time++;
    if (body.puncturedHeart) time += 2;
    if (body.puncturedLiver) time++;
    if (body.puncturedStomach) time++;
    if (body.puncturedRightKidney) time++;
    if (body.puncturedLeftKidney) time++;
    if (body.puncturedSpleen) time++;
    if (body.ribs < body.maxRibs) time++;
    if (body.neck == InjuryState.untreated) time++;
    if (body.upperSpine == InjuryState.untreated) time++;
    if (body.lowerSpine == InjuryState.untreated) time++;
  }
  return time;
}

int squadsize(Squad? activeSquad) {
  return squad.length;
}

Future<void> armsdealer(Site loc) => shop(loc, 'ARMSDEALER');
Future<void> pawnshop(Site loc) => shop(loc, 'PAWNSHOP');
Future<void> deptstore(Site loc) => shop(loc, 'DEPARTMENT_STORE');
Future<void> oubliette(Site loc) => shop(loc, 'OUBLIETTE');
Future<void> shop(Site loc, String shopType) async {
  locatesquad(activeSquad!, loc);
  await shopTypes[shopType]!.enter(activeSquad!);
}

/* active squad visits the car dealership */
Future<void> dealership(Site loc) async {
  int buyer = 0;
  locatesquad(activeSquad!, loc);
  int partysize = squadsize(activeSquad);
  while (true) {
    erase();

    locHeader();
    printParty();

    Creature? sleepercarsalesman = pool.firstWhereOrNull((p) =>
        p.alive &&
        p.sleeperAgent &&
        p.type.id == CreatureTypeIds.carSalesman &&
        p.site?.city == loc.city);

    Vehicle? carToSell;
    int price = 0;

    for (Vehicle v in vehiclePool) {
      if (v == squad[buyer].car) {
        carToSell = v;
      }
    }

    addOptionText(10, 1, "G", "G - Get a Liberal car",
        enabledWhen: carToSell == null);

    move(11, 1);
    if (carToSell != null) {
      price = (0.8 * carToSell.type.price).round();

      if (carToSell.heat > 0) price = price ~/ 10;
      addInlineOptionText(
          "S", "S - Sell the ${carToSell.fullName()} (\$$price)");
    } else {
      addInlineOptionText("S", "S - Sell a car", enabledWhen: false);
    }

    /*if(car_to_sell && car_to_sell.heat>1 && ledger.funds>=500) {
         setColor(lightGray);
      } else {
         addOptionText(12, 1, "P", "P - Repaint car, replace plates and tags ($500)");
      }*/
    addOptionText(15, 1, "0", "0 - Show the squad's Liberal status",
        enabledWhen: activeSquadMember != null);
    addOptionText(16, 1, "B", "B - Choose a buyer",
        enabledWhen: partysize >= 2);
    addOptionText(16, 40, "Enter", "Enter - Leave");

    if (partysize > 0 && (activeSquadMemberIndex == -1 || partysize > 1)) {
      setColor(lightGray);
    } else {
      setColor(darkGray);
    }
    mvaddstr(15, 40, "# - Check the status of a squad Liberal");

    int c = await getKey();

    // Leave
    if (isBackKey(c)) break;

    //Sell the car
    if (c == Key.s && carToSell != null) {
      ledger.addFunds(price, Income.cars);
      vehiclePool.remove(carToSell);
    }

    // Get a car
    if (c == Key.g && carToSell == null) {
      int carchoice;

      List<VehicleType> availablevehicle = [];
      List<String> vehicleoption = [];
      List<int> vehicleprice = [];
      for (VehicleType vt
          in vehicleTypes.values.where((vt) => vt.availableAtDealership)) {
        availablevehicle.add(vt);
        int price = sleepercarsalesman != null ? vt.sleeperprice : vt.price;
        vehicleprice.add(price);
        vehicleoption.add("${vt.longName} (\$$price)");
      }
      while (true) {
        carchoice = await choiceprompt("Choose a vehicle", "", vehicleoption,
            "Vehicle", true, "We don't need a Conservative car");
        if (carchoice != -1 && vehicleprice[carchoice] > ledger.funds) {
          mvaddstrc(1, 1, darkRed, "You don't have enough money!");
          carchoice = -1;

          await getKey();
        } else {
          break;
        }
      }

      if (carchoice == -1) continue;

      //Picked a car, pick color
      int colorchoice = await choiceprompt(
          "Choose a color",
          "",
          availablevehicle[carchoice].colors,
          "Color",
          true,
          "These colors are Conservative");

      if (colorchoice == -1) continue;

      Vehicle v = Vehicle(availablevehicle[carchoice].idName)
        ..color = availablevehicle[carchoice].colors[colorchoice]
        ..year = year;
      squad[buyer].preferredCarId = v.id;
      vehiclePool.add(v);

      ledger.subtractFunds(vehicleprice[carchoice], Expense.cars);
    }

    // Reduce heat
    /*if(c==Key.p && car_to_sell && car_to_sell.heat>1 && ledger.funds>=500)
      {
         funds-=500;
         moneylost_goods+=500;
         car_to_sell.heat=1;
      }*/

    if (c == Key.b) buyer = await chooseBuyerIndex(buyer);

    if (c == '0'.codePoint) activeSquadMemberIndex = -1;

    if (c >= '1'.codePoint && c <= '6'.codePoint && activeSquad != null) {
      int index = c - '1'.codePoint;
      if (squad.length > index) {
        if (activeSquadMemberIndex == index) {
          await fullCreatureInfoScreen(activeSquadMember!);
        } else {
          activeSquadMemberIndex = index;
        }
      }
    }
  }
}

/* choose buyer */
Future<int> chooseBuyerIndex(int buyer) async {
  activeSquadMemberIndex = -1;

  int partysize = squadsize(activeSquad);

  if (partysize <= 1) return buyer;

  while (true) {
    printParty();

    move(8, 20);
    setColor(white);
    addstr("Choose a Liberal squad member to SPEND.");

    int c = await getKey();

    if (isBackKey(c)) return buyer;

    if (c >= '1'.codePoint && c <= partysize + '1'.codePoint - 1) {
      return c - '1'.codePoint;
    }
  }
}

Future<Creature> chooseBuyer(Creature buyer) async {
  return activeSquad!.members[await chooseBuyerIndex(squad.indexOf(buyer))];
}
