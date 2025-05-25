import 'dart:math';

import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/basemode/disbanding.dart';
import 'package:lcs_new_age/basemode/liberal_agenda.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/body.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/advance_day.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/clothing.dart';
import 'package:lcs_new_age/items/loot_type.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/justice/prison.dart';
import 'package:lcs_new_age/justice/trial.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/monthly/lcs_monthly.dart';
import 'package:lcs_new_age/monthly/sleeper_update.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/congress.dart';
import 'package:lcs_new_age/politics/elections.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/supreme_court.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/saveload/save_load.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';
import 'package:lcs_new_age/title_screen/game_over.dart';
import 'package:lcs_new_age/title_screen/high_scores.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> advanceMonth() async {
  var oldlaw = Map.fromEntries(laws.entries);
  switch (ccsState) {
    case CCSStrength.inHiding:
      if (politics.publicMood() > 60) {
        for (Site s in sites.where((s) =>
            s.controller == SiteController.unaligned &&
            [SiteType.barAndGrill, SiteType.bombShelter, SiteType.bunker]
                .contains(s.type))) {
          s.controller = SiteController.ccs;
        }
        ccsState = CCSStrength.active;
        if (!ccsInPublicEye) {
          publicOpinion[View.ccsHated] = politics.publicMood();
        }
      }
    case CCSStrength.active:
      if (politics.publicMood() > 80) {
        ccsState = CCSStrength.attacks;
      }
    case CCSStrength.attacks:
      if (politics.publicMood() > 90) {
        ccsState = CCSStrength.sieges;
      }
    default:
      break;
  }

  //CLEAR RENT EXEMPTIONS
  for (Site l in sites) {
    l.newRental = false;
  }

  //YOUR PAPER AND PUBLIC OPINION AND STUFF
  Iterable<Creature> publishers = pool.where((p) =>
      p.isActiveLiberal && p.activity.type == ActivityType.writeGuardian ||
      p.activity.type == ActivityType.streamGuardian);

  // Check for game over
  await checkForDefeat();
  await dispersalCheck();

  if (!disbanding) {
    //DO SPECIAL EDITIONS
    LootType? loot = await chooseSpecialEdition();

    if (loot != null) {
      await printNews(loot, publishers);
    }
  }

  Map<View, int> libpower = {for (var view in View.values) view: 0};

  //STORIES STALE EVEN IF NOT PRINTED
  for (var entry in politics.publicInterest.entries) {
    politics.publicInterest[entry.key] = entry.value ~/ 2;
  }

  double conspower = 300 -
      publicOpinion[View.amRadio]! * 1.5 -
      publicOpinion[View.cableNews]! * 1.5;

  //HAVING SLEEPERS
  for (int pl = pool.length - 1; pl > 0; pl--) {
    if (pool[pl].alive && (pool[pl].sleeperAgent)) {
      await sleeperEffect(pool[pl], libpower);
    }
  }

  //Manage graffiti
  for (Site l in sites) // Check each location
  {
    for (int c = l.changes.length - 1; c >= 0; c--) // Each change to the map
    {
      if (l.changes[c].flag == SITEBLOCK_GRAFFITI ||
          l.changes[c].flag == SITEBLOCK_GRAFFITI_CCS ||
          l.changes[c].flag ==
              SITEBLOCK_GRAFFITI_OTHER) // Find changes that refer specifically to graffiti
      {
        // Purge graffiti from more secure sites
        if (securityable(l.type) > 0) {
          l.changes.removeAt(c);
        } else {
          // Some occasional changes to graffiti in less secure sites
          if (l.controller == SiteController.ccs) {
            l.changes[c].flag = SITEBLOCK_GRAFFITI_CCS; // Convert to CCS tags
          } else if (l.controller == SiteController.lcs) {
            l.changes[c].flag = SITEBLOCK_GRAFFITI; // Convert to LCS tags
          } else {
            if (oneIn(10)) {
              l.changes[c].flag =
                  SITEBLOCK_GRAFFITI_OTHER; // Convert to other tags
            }
            if (oneIn(10) && ccsActive) {
              l.changes[c].flag = SITEBLOCK_GRAFFITI_CCS; // Convert to CCS tags
            }
            if (oneIn(30)) {
              l.changes.removeAt(c); // Clean up
            }
          }
        }
      }
    }
  }

  //PUBLIC OPINION NATURAL MOVES
  for (View v in View.values) {
    // Liberal essays add their power to the effect of sleepers
    libpower.update(v, (i) => i + (politics.backgroundInfluence[v] ?? 0));
    politics.backgroundInfluence[v] =
        ((politics.backgroundInfluence[v] ?? 0) * 0.66).round();

    if (v == View.lcsKnown) continue;
    //if(v==View.POLITICALVIOLENCE)
    //{
    //   changePublicOpinion(View.POLITICALVIOLENCE,-1,0);
    //   continue;
    //}
    if (v != View.amRadio && v != View.cableNews) {
      double balance = libpower[v]! - conspower;

      // Heavy randomization -- balance of power just biases the roll
      double roll = balance + lcsRandom(400) - 200;

      // If +/-50 to either side, that side wins the tug-of-war
      if (roll.abs() >= 50) {
        if (roll < 0) {
          changePublicOpinion(v, -1);
        } else if (roll > 0) {
          changePublicOpinion(v, 1);
        }
      }
    }
    // AM Radio and Cable News popularity slowly shift to reflect public
    // opinion over time -- if left unchecked, their subtle influence
    // on society will become a self-perpetuating Conservative nightmare!
    else if (v == View.amRadio || v == View.cableNews) {
      // If the public is much more liberal than the media, slowly shift
      // away from watching Conservative media
      if (politics.publicMood() - 20 > publicOpinion[v]!) {
        changePublicOpinion(v, 1);
      }
      // When disbanding and public opinion is very liberal, don't allow
      // the Conservative media to gain traction (it's just annoying)
      if (politics.publicMood() > 90 && disbanding) continue;
      // Otherwise, slowly shift in favor of Conservative media
      if (politics.publicMood() - 10 < publicOpinion[v]!) {
        changePublicOpinion(v, -1);
      }
    }
  }

  // Seduction monthly experience stipends for those liberals
  // who have been getting it on with their romantic partners
  // in the background
  for (int s = 0; s < pool.length; s++) {
    int stipendsize = 0;
    stipendsize = pool[s].relationships.length * pool[s].health;
    pool[s].train(Skill.seduction, stipendsize);
  }

  //SUPREME COURT
  if (month == 6) {
    await supremeCourt();
  }

  //CONGRESS
  await congress();

  //ELECTIONS
  if (month == 11) {
    await elections();
  }

  //DID YOU WIN?
  await winCheck();

  //CONTROL LONG DISBANDS
  if (disbanding && year - disbandTime >= 50) {
    await defeatMessages(
        "The Liberal Crime Squad is now just a memory.",
        "The last LCS members have all been hunted down.",
        "They will never see the utopia they dreamed of...");
    HighScore yourScore = await saveHighScore(Ending.disbandLoss);
    await deleteSaveGame();
    await viewHighScores(yourScore);
    endGame();
  }

  //UPDATE THE WORLD IN CASE THE LAWS HAVE CHANGED
  renameBuildingsAfterLawChanges(laws, oldlaw);

  //THE SYSTEM!
  for (int i = pool.length - 1; i >= 0; i--) {
    Creature p = pool[i];
    if (disbanding) break;

    if (!p.alive) continue;
    if (p.sleeperAgent) continue;
    if (p.site?.type == SiteType.policeStation) {
      if (p.missing) {
        await showMessage(
            "Cops re-polluted ${p.name}'s mind with Conservatism!",
            color: purple);
        p.squad = null;
        pool.remove(p);
        continue;
      } else if ((p.wantedForCrimes[Crime.illegalEntry] ?? 0) > 0 &&
          laws[Law.immigration] != DeepAlignment.eliteLiberal) {
        bool execute =
            laws[Law.deathPenalty] == DeepAlignment.archConservative &&
                laws[Law.immigration] == DeepAlignment.archConservative;
        await showMessage(
            "${p.name} has been handed over to ICE and ${execute ? "executed" : "deported"}!",
            color: purple);

        p.squad = null;
        pool.remove(p);
        continue;
      } else {
        //TRY TO GET RACKETEERING CHARGE
        int maxCopStrength = switch (laws[Law.policeReform]) {
          DeepAlignment.archConservative => 200,
          DeepAlignment.conservative => 150,
          DeepAlignment.liberal => 75,
          DeepAlignment.eliteLiberal => 50,
          _ => 100,
        };

        int copstrength = min(maxCopStrength, 10 * p.heat);

        if (laws[Law.deathPenalty] == DeepAlignment.archConservative) {
          copstrength = 200;
        }

        if (copstrength > 200) copstrength = 200;

        int libstrength = p.juice +
            (p.attribute(Attribute.heart) * 5) -
            (p.attribute(Attribute.wisdom) * 5) +
            (p.skill(Skill.psychology) * 5) +
            (p.skill(Skill.law) * 5);

        if (p.brainwashed) libstrength = 0;

        if (libstrength < 0) libstrength = 0;

        //Confession check
        if ((lcsRandom(copstrength) > libstrength) && (p.hireId != null)) {
          // p breaks under the pressure and tells the cops everything
          Creature p2 = pool.firstWhere((p2) => p2.id == p.hireId);
          if (p2.alive && p2.site?.type != SiteType.prison) {
            //Charge the boss with racketeering!
            criminalize(p2, Crime.racketeering);
            //Rack up testimonies against the boss in court!
            p2.confessions++;
          }
          //Issue a raid on this guy's base!
          p.base?.heat += 300;

          erase();
          mvaddstrc(8, 1, white, p.name);
          if (p.brainwashed) {
            addstr(" has reverted to Conservatism in police custody!");
          } else {
            addstr(" has broken under the pressure and ratted you out!");
          }

          await getKey();

          mvaddstrc(9, 1, white,
              "The traitor will testify in court, and safehouses may be compromised.");

          await getKey();
          p.squad = null;
          pool.remove(p);
          continue; //no trial for this person; skip to next person
        }

        await showMessage("${p.name} is moved to the courthouse for trial.");

        p.location = findSiteInSameCity(p.site!.city, SiteType.courthouse);
        Clothing prisoner = Clothing("CLOTHING_PRISONER");
        p.giveArmor(prisoner, null);
      }
    } else if (p.site?.type == SiteType.courthouse) {
      await trial(p);
    } else if (p.site?.type == SiteType.prison) {
      await prison(p);
    }
  }

  //NUKE EXECUTION VICTIMS
  for (int i = pool.length - 1; i >= 0; i--) {
    Creature p = pool[i];

    if (p.site?.type == SiteType.prison && !p.alive) {
      p.squad = null;

      p.die();
      p.location = null;
    }
  }

  //MUST DO AN END OF GAME CHECK HERE BECAUSE OF EXECUTIONS
  await checkForDefeat(Ending.executed);

  //DISPERSAL CHECK
  await dispersalCheck();

  //FUND REPORTS
  if (canSeeThings) await fundReport(false);
  ledger.resetMonthlyAmounts();
  if (clearScreenOnNextMessage) erase();

  //HEAL CLINIC PEOPLE
  for (Creature p in pool) {
    if (disbanding) break;
    if (!p.alive) continue;

    if (p.clinicMonthsLeft > 0) {
      p.clinicMonthsLeft--;

      for (BodyPart w in p.body.parts) {
        w.heal();
      }

      int healthdamage = 0;
      HumanoidBody? body =
          p.body is HumanoidBody ? p.body as HumanoidBody : null;
      if (body != null) {
        if (body.puncturedRightLung) {
          body.puncturedRightLung = false;
          if (oneIn(2)) healthdamage++;
        }
        if (body.puncturedLeftLung) {
          body.puncturedLeftLung = false;
          if (oneIn(2)) healthdamage++;
        }
        if (body.puncturedHeart) {
          body.puncturedHeart = false;
          if (!oneIn(3)) healthdamage++;
        }
        body.puncturedLiver = false;
        body.puncturedStomach = false;
        body.puncturedRightKidney = false;
        body.puncturedLeftKidney = false;
        body.puncturedSpleen = false;
        body.ribs = body.maxRibs;
        if (body.neck == InjuryState.untreated) {
          body.neck = InjuryState.treated;
        }
        if (body.upperSpine == InjuryState.untreated) {
          body.upperSpine = InjuryState.treated;
        }
        if (body.lowerSpine == InjuryState.untreated) {
          body.lowerSpine = InjuryState.treated;
        }

        // Inflict permanent health damage
        p.permanentHealthDamage += healthdamage;
      }

      if (p.blood <= p.maxBlood * 0.5 && p.clinicMonthsLeft <= 2) {
        p.blood = (p.maxBlood * 0.5).floor();
      }
      if (p.blood <= p.maxBlood * 0.75 && p.clinicMonthsLeft <= 1) {
        p.blood = (p.maxBlood * 0.75).floor();
      }

      // If at clinic and in critical condition, transfer to university hospital
      if (p.clinicMonthsLeft > 2 && p.site?.type == SiteType.clinic) {
        Site? hospital =
            findSiteInSameCity(p.site!.city, SiteType.universityHospital);
        if (hospital != null) {
          p.location = hospital;
          mvaddstrc(8, 1, white, p.name);
          addstr(" has been transferred to ");
          addstr(hospital.name);
          addstr(".");

          await getKey();
        }
      }

      // End treatment
      if (p.clinicMonthsLeft == 0) {
        p.blood = p.maxBlood;
        p.activity = Activity.none();
        await showMessage("${p.name} has left the ${p.site!.name}.");

        Site? hs =
            findSiteInSameCity(p.site!.city, SiteType.homelessEncampment);

        if (hs != null &&
            (p.base?.siege.underSiege != false ||
                p.base?.controller != SiteController.lcs)) {
          p.base = hs;
        }

        p.location = p.base;
      }
    }
  }
}

Future<void> winCheck() async {
  if (politics.laws.values.any((law) => law != DeepAlignment.eliteLiberal)) {
    return;
  }
  if (summarizePoliticalBody(court)[4] <= court.length / 2) return;
  if (summarizePoliticalBody(house)[4] <= house.length / 2) return;
  if (summarizePoliticalBody(senate)[4] <= senate.length / 2) return;
  if (exec.values.any((e) => e != DeepAlignment.eliteLiberal)) return;
  if (ccsActive) return;
  await liberalAgenda(AgendaVibe.liberalVictory);
  await saveHighScore(Ending.victory);
  await deleteSaveGame();
  await viewHighScores();
  endGame();
}

void renameBuildingsAfterLawChanges(
    Map<Law, DeepAlignment> law, Map<Law, DeepAlignment> oldlaw) {
  void update(
      SiteType siteType, List<Law> lawsToCheck, DeepAlignment alignment) {
    if ((law.entries
                .where((e) => lawsToCheck.contains(e.key))
                .every((e) => e.value == alignment) ||
            oldlaw.entries
                .where((e) => lawsToCheck.contains(e.key))
                .every((e) => e.value == alignment)) &&
        lawsToCheck.any((l) => law[l] != oldlaw[l])) {
      sites
          .where(
              (l) => l.type == siteType && l.controller != SiteController.lcs)
          .forEach(initSiteName);
    }
  }

  // NOTE: make sure to keep code here matching code in initlocation() in locations.cpp for when names are changed
  update(SiteType.policeStation, [Law.policeReform, Law.deathPenalty],
      DeepAlignment.archConservative);
  update(
      SiteType.fireStation, [Law.freeSpeech], DeepAlignment.archConservative);
  update(
      SiteType.courthouse, [Law.deathPenalty], DeepAlignment.archConservative);
  update(SiteType.prison, [Law.prisons], DeepAlignment.archConservative);
  update(SiteType.nuclearPlant, [Law.nuclearPower],
      DeepAlignment.archConservative);
  update(
      SiteType.intelligenceHQ,
      [Law.privacy, Law.prisons, Law.military, Law.policeReform],
      DeepAlignment.archConservative);
  update(
      SiteType.armyBase,
      [Law.privacy, Law.prisons, Law.military, Law.policeReform],
      DeepAlignment.archConservative);
  update(SiteType.pawnShop, [Law.gunControl], DeepAlignment.eliteLiberal);
  update(SiteType.ceoHouse, [Law.corporate, Law.taxes],
      DeepAlignment.archConservative);
  update(SiteType.drugHouse, [Law.drugs], DeepAlignment.eliteLiberal);
}
