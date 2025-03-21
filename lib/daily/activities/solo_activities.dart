import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_actions/common_actions.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/daily/activities/armor_creation.dart';
import 'package:lcs_new_age/daily/activities/armor_repair.dart';
import 'package:lcs_new_age/daily/activities/bury_dead.dart';
import 'package:lcs_new_age/daily/activities/car_theft.dart';
import 'package:lcs_new_age/daily/activities/fundraising.dart';
import 'package:lcs_new_age/daily/activities/graffiti.dart';
import 'package:lcs_new_age/daily/activities/guardian.dart';
import 'package:lcs_new_age/daily/activities/hacking.dart';
import 'package:lcs_new_age/daily/activities/learning.dart';
import 'package:lcs_new_age/daily/activities/recruiting.dart';
import 'package:lcs_new_age/daily/activities/sleeper_join_lcs.dart';
import 'package:lcs_new_age/daily/activities/teaching.dart';
import 'package:lcs_new_age/daily/activities/trouble.dart';
import 'package:lcs_new_age/daily/shopsnstuff.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/views.dart';

Future<void> soloActivities() async {
  Map<ActivityType, List<Creature>> activities = {};
  for (Creature p in pool) {
    p.income = 0;
    if (!p.alive) continue;
    if (p.clinicMonthsLeft > 0) continue;
    if (p.vacationDaysLeft > 0) continue;
    if (p.hidingDaysLeft != 0) continue;
    p.location ??= p.base;
    // Clear actions for people under siege
    if (p.site?.siege.underSiege == true) {
      switch (p.activity.type) {
        // things you can do at home in the dark
        case ActivityType.interrogation:
        case ActivityType.none:
          break;
        // things you can do at home, but only if the power isn't cut
        case ActivityType.hacking:
        case ActivityType.ccfraud:
        case ActivityType.study:
        case ActivityType.streamGuardian:
        case ActivityType.writeGuardian:
          if (p.site?.siege.lightsOff == true) {
            p.activity = Activity.none();
          }
        // things that necessitate spending money or touching grass
        default:
          p.activity = Activity.none();
      }
    }
    if (p.align != Alignment.liberal) continue;
    if (p.imprisoned) continue;
    // Activities
    activities.putIfAbsent(p.activity.type, () => []).add(p);
  }

  for (MapEntry entry in activities.entries) {
    ActivityType type = entry.key;
    List<Creature> people = entry.value;
    switch (type) {
      case ActivityType.visit:
        if (disbanding) continue;
        for (Creature p in people) {
          p.activity = Activity.none();
        }
      case ActivityType.none:
        if (disbanding) continue;
        for (Creature p in people) {
          await doActivityRepairArmor(p);
        }
      case ActivityType.makeArmor:
        if (disbanding) continue;
        for (Creature p in people) {
          await doActivityMakeArmor(p);
        }
      case ActivityType.wheelchair:
        if (disbanding) continue;
        for (Creature p in people) {
          await doActivityGetWheelchair(p);
        }
      case ActivityType.recruiting:
        if (disbanding) continue;
        for (Creature p in people) {
          await doActivityRecruit(p);
        }
      case ActivityType.stealCars:
        if (disbanding) continue;
        for (Creature p in people) {
          CarTheftScene scene = CarTheftScene(p);
          await scene.play();
        }
      case ActivityType.donations:
        if (disbanding) continue;
        await doActivitySolicitDonations(people);
      case ActivityType.sellTshirts:
        if (disbanding) continue;
        await doActivitySellTshirts(people);
      case ActivityType.sellMusic:
        if (disbanding) continue;
        await doActivitySellMusic(people);
      case ActivityType.sellArt:
        if (disbanding) continue;
        await doActivitySellArt(people);
      case ActivityType.sellDrugs:
        if (disbanding) continue;
        await doActivitySellBrownies(people);
      case ActivityType.prostitution:
        if (disbanding) continue;
        await doActivityProstitution(people);
      case ActivityType.graffiti:
        if (disbanding) continue;
        await doActivityGraffiti(people);
      case ActivityType.trouble:
        await doActivityTrouble(people);
      case ActivityType.communityService:
        for (Creature p in people) {
          addjuice(p, 1, 10);
          changePublicOpinion(View.lcsLiked, 1);
        }
      case ActivityType.hacking:
        if (disbanding) continue;
        await doActivityHacking(people);
      case ActivityType.ccfraud:
        if (disbanding) continue;
        await doActivityCCFraud(people);
      case ActivityType.bury:
        if (disbanding) continue;
        await doActivityBury(people);
      case ActivityType.teachLiberalArts:
      case ActivityType.teachFighting:
      case ActivityType.teachCovert:
        if (disbanding) continue;
        await doActivityTeach(people);
      case ActivityType.streamGuardian:
        doActivityStreamGuardian(people);
      case ActivityType.writeGuardian:
        doActivityWriteGuardian(people);
      case ActivityType.study:
        if (disbanding) continue;
        await doActivityStudy(people);
      case ActivityType.takeClass:
        if (disbanding) continue;
        await doActivityTakeClasses(people);
      case ActivityType.clinic:
        if (disbanding) continue;
        for (Creature p in people) {
          if (p.site?.city == null) continue;
          Site? hospital =
              findSiteInSameCity(p.site!.city, SiteType.universityHospital);
          if (hospital == null) continue;
          await hospitalize(hospital, p);
        }
      case ActivityType.sleeperJoinLcs:
        if (disbanding) continue;
        await doActivitySleeperJoinLCS(people);
      default:
        break;
    }
  }
}

Future<void> doActivityGetWheelchair(Creature p) async {
  await showMessage("${p.name} has procured a wheelchair.");
  p.hasWheelchair = true;
  p.activity = Activity.none();
}
