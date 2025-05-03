import 'dart:math';

import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/location/city.dart';
import 'package:lcs_new_age/location/location.dart';
import 'package:lcs_new_age/politics/alignment.dart';

Future<void> doActivityTeach(List<Creature> teachers) async {
  for (Creature teacher in teachers) {
    List<Skill> skills;
    int cost = 0;
    int workload = 0;
    //Build a list of skills to train and determine the cost for running
    //a class depending on what the teacher is teaching
    switch (teacher.activity.type) {
      case ActivityType.teachLiberalArts:
        cost = 2;
        skills = [
          Skill.law,
          Skill.persuasion,
          Skill.writing,
          Skill.religion,
          Skill.business,
          Skill.science,
          Skill.psychology,
          Skill.music,
          Skill.art,
        ];
      case ActivityType.teachCovert:
        cost = 6;
        skills = [
          Skill.security,
          Skill.computers,
          Skill.disguise,
          Skill.tailoring,
          Skill.stealth,
          Skill.seduction,
          Skill.driving,
          Skill.streetSmarts,
        ];
      case ActivityType.teachFighting:
        cost = 10;
        skills = [
          Skill.heavyWeapons,
          Skill.throwing,
          Skill.martialArts,
          Skill.dodge,
          Skill.firstAid,
          Skill.firearms,
        ];
      default:
        continue;
    }

    //Count potential students for this teacher to get an idea of efficiency.
    //Much of the verbosity here is for performance reasons, to avoid iterating
    //over the entire pool of creatures multiple times, and to avoid iterating
    //over the entire list of sites multiple times.
    List<Creature> students = [];
    City? city = teacher.site?.city;
    Iterable<Location> locations = allLocations.where((l) => l.city == city);
    Iterable<String> siteIdsInJusticeSystem =
        sites.where((s) => s.isPartOfTheJusticeSystem).map((s) => s.idString);
    Iterable<String> siteIds = locations.map((s) => s.idString);
    for (Creature p in pool) {
      if (p != teacher &&
          siteIds.contains(p.locationId) &&
          p.align == Alignment.liberal &&
          (p.sleeperAgent || !siteIdsInJusticeSystem.contains(p.locationId)) &&
          p.clinicMonthsLeft == 0) {
        students.add(p);
      }
    }
    for (Creature p in students) {
      for (Skill skill in skills) {
        // Count the number of skills being taught times the number of
        // students learning those skills to determine the teacher's
        // workload
        if (p.skill(skill) < teacher.skill(skill) &&
            p.skill(skill) < p.skillCap(skill)) {
          workload++;
        }
      }
    }

    // Check funds
    int totalCost = cost * min(workload, 10);
    if (ledger.funds < totalCost) {
      await showMessage(
          "${teacher.name} couldn't afford the supplies to run their class.");
      continue;
    } else {
      ledger.subtractFunds(totalCost, Expense.training);
    }

    //Walk through and train people
    for (Creature p in students) {
      for (Skill skill in skills) {
        // Teach skills where the student is below the teacher's skill
        if (p.skill(skill) < teacher.skill(skill) &&
            p.skill(skill) < p.skillCap(skill)) {
          //workload++;
        } else {
          continue;
        }
        // Teach based on teacher's skill in the topic plus skill in teaching, minus
        // student's skill in the topic
        int teach = teacher.skill(skill) +
            teacher.skill(Skill.teaching) * 3 -
            p.skill(skill);
        //at ten students, cost no longer goes up, but effectiveness goes down.
        if (workload > 10) {
          //62.5% speed with twice as many students.
          teach = ((teach * 30 ~/ workload) + teach) ~/ 4;
        }
        if (teach < 1) teach = 1;
        // Cap at 50 points per day
        if (teach > 50) teach = 50;

        p.train(skill, teach);
        teacher.train(Skill.teaching, 1);
      }
    }
    if (workload == 0) {
      await showMessage(
          "${teacher.name} has no students and will stop ${teacher.activity.description}.");
      teacher.activity = Activity(ActivityType.none);
    }
  }
}
