import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_actions/common_actions.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/conversion.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/loot.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/politics.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/sitemode/fight.dart';
import 'package:lcs_new_age/sitemode/map_specials.dart';
import 'package:lcs_new_age/sitemode/newencounter.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> sleeperEffect(Creature cr, Map<View, int> libpower) async {
  if (disbanding) cr.activity.type = ActivityType.sleeperLiberal;

  switch (cr.activity.type) {
    case ActivityType.sleeperLiberal:
      sleeperInfluence(cr, libpower);
    case ActivityType.sleeperEmbezzle:
      await sleeperEmbezzle(cr, libpower);
    case ActivityType.sleeperSteal:
      await sleeperSteal(cr, libpower);
    case ActivityType.sleeperRecruit:
      await sleeperRecruit(cr, libpower);
    case ActivityType.sleeperSpy:
      await sleeperSpy(cr, libpower);
    default:
      cr.infiltration += 0.01 * lcsRandom(5) + 0.01;
  }

  cr.infiltration = cr.infiltration.clamp(0.0, 1.0);
}

void sleeperInfluence(Creature cr, Map<View, int> libpower) {
  int power = cr.attribute(Attribute.charisma) +
      cr.attribute(Attribute.heart) +
      cr.attribute(Attribute.intelligence) +
      cr.skill(Skill.persuasion);

  Map<View, int> transferpower = {for (var view in View.values) view: 0};

  // Profession specific skills
  switch (cr.type.id) {
    case CreatureTypeIds.artCritic:
      power += cr.skill(Skill.writing) * 3;
      power += cr.skill(Skill.art) * 2;
    case CreatureTypeIds.painter:
    case CreatureTypeIds.sculptor:
      power += cr.skill(Skill.art) * 5;
    case CreatureTypeIds.musicCritic:
      power += cr.skill(Skill.writing) * 3;
      power += cr.skill(Skill.music) * 2;
    case CreatureTypeIds.musician:
      power += cr.skill(Skill.music) * 5;
    case CreatureTypeIds.author:
    case CreatureTypeIds.journalist:
      power += cr.skill(Skill.writing) * 5;
    case CreatureTypeIds.liberalJudge:
    case CreatureTypeIds.conservativeJudge:
      power += cr.skill(Skill.writing);
      power += cr.skill(Skill.law);
    case CreatureTypeIds.lawyer:
      power += cr.skill(Skill.law);
    case CreatureTypeIds.labTech:
    case CreatureTypeIds.eminentScientist:
      power += cr.skill(Skill.science);
    case CreatureTypeIds.corporateCEO:
    case CreatureTypeIds.corporateManager:
      power += cr.skill(Skill.business);
    case CreatureTypeIds.priest:
    case CreatureTypeIds.nun:
    case CreatureTypeIds.televangelist:
      power += cr.skill(Skill.religion) * 5;
    case CreatureTypeIds.educator:
      power += cr.skill(Skill.psychology);
    case CreatureTypeIds.teacher:
    case CreatureTypeIds.yogaInstructor:
      power += cr.skill(Skill.teaching);
    case CreatureTypeIds.athlete:
    case CreatureTypeIds.cheerleader:
      power += cr.skill(Skill.dodge);
    default:
      break;
  }

  // Adjust power for super sleepers
  switch (cr.type.id) {
    case CreatureTypeIds.corporateCEO:
    case CreatureTypeIds.president:
    case CreatureTypeIds.eminentScientist:
    case CreatureTypeIds.ccsArchConservative:
    case CreatureTypeIds.policeChief:
      power *= 20;
    case CreatureTypeIds.deathSquad:
    case CreatureTypeIds.educator:
    case CreatureTypeIds.televangelist:
      power *= 6;
    case CreatureTypeIds.actor:
    case CreatureTypeIds.gangUnit:
    case CreatureTypeIds.militaryPolice:
    case CreatureTypeIds.seal:
    case CreatureTypeIds.conservativeJudge:
      power *= 4;
    default:
      power *= 2;
  }

  power = (power * cr.infiltration).round();
  void addIssues(List<View> issues, int power) {
    for (View v in issues) {
      transferpower[v] = transferpower[v]! + power;
    }
  }

  switch (cr.type.id) {
    /* Radio Personalities and News Anchors subvert Conservative news stations by
         reducing their audience and twisting views on the issues. As their respective
         media establishments become marginalized, so does their influence. */
    case CreatureTypeIds.radioPersonality:
      changePublicOpinion(View.amRadio, 1);
      addIssues(
          View.issues, power * (100 - publicOpinion[View.amRadio]!) ~/ 100);
    case CreatureTypeIds.newsAnchor:
      changePublicOpinion(View.cableNews, 1);
      addIssues(
          View.issues, power * (100 - publicOpinion[View.cableNews]!) ~/ 100);
    /* Cultural leaders block - influences cultural issues */
    case CreatureTypeIds.televangelist:
    case CreatureTypeIds.priest:
    case CreatureTypeIds.nun:
    case CreatureTypeIds.painter:
    case CreatureTypeIds.sculptor:
    case CreatureTypeIds.author:
    case CreatureTypeIds.journalist:
    case CreatureTypeIds.psychologist:
    case CreatureTypeIds.musician:
    case CreatureTypeIds.musicCritic:
    case CreatureTypeIds.artCritic:
    case CreatureTypeIds.actor:
    case CreatureTypeIds.teacher:
    case CreatureTypeIds.fashionDesigner:
    case CreatureTypeIds.hairstylist:
      addIssues([
        View.womensRights, View.civilRights, View.lgbtRights, View.freeSpeech,
        View.drugs, View.immigration, //
      ], power);
    /* Legal block - influences an array of social issues */
    case CreatureTypeIds.liberalJudge:
    case CreatureTypeIds.conservativeJudge:
    case CreatureTypeIds.lawyer:
      addIssues([
        View.civilRights, View.deathPenalty, View.drugs, View.freeSpeech,
        View.gunControl, View.justices, View.policeBehavior, View.torture,
        View.womensRights, View.lgbtRights, View.intelligence,
        View.immigration, //
      ], power);
    /* Scientists block */
    case CreatureTypeIds.eminentScientist:
    case CreatureTypeIds.labTech:
      addIssues([
        View.animalResearch, View.genetics, View.pollution,
        View.nuclearPower, //
      ], power);
    /* Corporate block */
    case CreatureTypeIds.corporateCEO:
    case CreatureTypeIds.corporateManager:
      addIssues([
        View.ceoSalary, View.taxes, View.corporateCulture,
        View.sweatshops, View.pollution, View.civilRights, //
      ], power);
    case CreatureTypeIds.bankManager:
    case CreatureTypeIds.landlord:
      addIssues([
        View.taxes, View.civilRights, View.ceoSalary, //
      ], power);
    /* Law enforcement and prisons block */
    case CreatureTypeIds.deathSquad:
    case CreatureTypeIds.swat:
    case CreatureTypeIds.cop:
    case CreatureTypeIds.policeChief:
    case CreatureTypeIds.gangUnit:
    case CreatureTypeIds.educator:
    case CreatureTypeIds.prisonGuard:
    case CreatureTypeIds.prisoner:
      addIssues([
        View.policeBehavior, View.deathPenalty, View.drugs,
        View.torture, View.gunControl, View.prisons, //
      ], power);
    /* Intelligence block */
    case CreatureTypeIds.secretService:
    case CreatureTypeIds.agent:
      addIssues([
        View.intelligence, View.torture, View.prisons, View.freeSpeech, //
      ], power);
    /* Military block */
    case CreatureTypeIds.merc:
      addIssues([View.gunControl], power);
    case CreatureTypeIds.soldier:
    case CreatureTypeIds.veteran:
    case CreatureTypeIds.militaryPolice:
    case CreatureTypeIds.seal:
      addIssues([
        View.military, View.torture, View.gunControl,
        View.womensRights, View.lgbtRights, //
      ], power);
    /* Sweatshop workers */
    case CreatureTypeIds.sweatshopWorker:
      addIssues([View.sweatshops, View.immigration], power);
    /* No influence at all block - for people were liberal anyway, or have no way of doing any good */
    case CreatureTypeIds.childLaborer:
    case CreatureTypeIds.genetic:
    case CreatureTypeIds.guardDog:
    case CreatureTypeIds.bum:
    case CreatureTypeIds.crackhead:
    case CreatureTypeIds.tank:
    // too liberal to be a proper sleeper
    case CreatureTypeIds.punk:
    case CreatureTypeIds.goth:
    case CreatureTypeIds.emo:
    case CreatureTypeIds.hippie:
    case CreatureTypeIds.unionWorker:
      return;
    /* Miscellaneous block -- includes everyone else */
    case CreatureTypeIds.president:
      addIssues(
          [View.issues.random, View.issues.random, View.issues.random], power);
    case CreatureTypeIds.ccsArchConservative:
    case CreatureTypeIds.ccsVigilante:
    case CreatureTypeIds.neoNazi:
    case CreatureTypeIds.naziPunk:
      addIssues([View.ccsHated, View.issues.random], power);
    default: // Affect a random issue
      addIssues([View.issues.random], power);
  }

  //Transfer the liberal power adjustment to background liberal power
  for (View v in View.issues) {
    libpower[v] = libpower[v]! + transferpower[v]!;
    if (transferpower[v]! > 50) changePublicOpinion(v, transferpower[v]! ~/ 50);
  }
}

Future<void> sleeperSpy(Creature cr, Map<View, int> libpower) async {
  Site? homes =
      findSiteInSameCity(cr.workLocation.city, SiteType.homelessEncampment);

  if (lcsRandom(100) > 100 * cr.infiltration) {
    cr.infiltration -= 0.05;
    if (cr.infiltration < 0) {
      erase();
      if (cr == uniqueCreatures.president) {
        mvaddstr(
            6, 1, "President ${cr.name} has been impeached for corruption.");
        mvaddstr(8, 1, "The Ex-President is in disgrace.");
        politics.promoteVP();
      } else {
        mvaddstr(6, 1, "Sleeper ${cr.name} has been caught snooping around.");
        mvaddstr(8, 1, "The Liberal is now homeless and jobless...");
      }
      await getKey();

      cr.squad = null;
      cr.location = homes;
      cr.base = homes;
      cr.dropWeaponAndAmmo();
      cr.activity = Activity.none();
      cr.sleeperAgent = false;
    } else {
      erase();
      if (cr == uniqueCreatures.president) {
        mvaddstr(
            6, 1, "President ${cr.name} is under too much pressure to leak.");
        mvaddstr(8, 1, "A corruption scandal is brewing...");
      } else {
        mvaddstr(6, 1, "Sleeper ${cr.name} has been caught snooping around.");
        mvaddstr(8, 1, "The Liberal's infiltration score has taken a hit.");
      }
      await getKey();
    }
    return;
  }

  cr.workSite?.mapped = true;

  Future<void> leak(String itemType, String description) async {
    Item it = Loot(itemType);
    homes?.loot.add(it);
    erase();
    if (cr == uniqueCreatures.president) {
      mvaddstr(6, 1, "President ${cr.name} has leaked $description.");
    } else {
      mvaddstr(6, 1, "Sleeper ${cr.name} has leaked $description.");
    }
    mvaddstr(7, 1, "The dead drop is at the homeless camp.");

    mvaddstr(9, 1, "An investigation is being launched to find the leaker.");
    if (cr == uniqueCreatures.president) {
      mvaddstr(10, 1, "A corruption scandal is brewing...");
    } else {
      mvaddstr(10, 1, "The Liberal's infiltration score has taken a hit.");
    }

    cr.infiltration -= 0.2;
    addjuice(cr, 50, 1000);
    await getKey();
  }

  if (homes?.siege.underSiege != false || !canSeeThings) return;

  switch (cr.type.id) {
    case CreatureTypeIds.secretService:
    case CreatureTypeIds.agent:
    case CreatureTypeIds.president:
      if (ccsExposure.index >= CCSExposure.lcsGotData.index || !ccsActive) {
        await leak("LOOT_SECRETDOCUMENTS", "secret intelligence files");
      } else {
        await leak(
            "LOOT_CCS_BACKERLIST", "a list of the CCS's government backers");
        ccsExposure = CCSExposure.lcsGotData;
      }
    case CreatureTypeIds.deathSquad:
    case CreatureTypeIds.swat:
    case CreatureTypeIds.cop:
    case CreatureTypeIds.policeChief:
    case CreatureTypeIds.gangUnit:
      // Cops can leak police files to you
      await leak("LOOT_POLICERECORDS", "secret police records");
    case CreatureTypeIds.corporateManager:
    case CreatureTypeIds.corporateCEO:
      await leak("LOOT_CORPFILES", "secret corporate documents");
    case CreatureTypeIds.educator:
    case CreatureTypeIds.prisonGuard:
      await leak("LOOT_PRISONFILES", "internal prison records");
    case CreatureTypeIds.newsAnchor:
      await leak("LOOT_CABLENEWSFILES", "proof of systemic Cable News bias");
    case CreatureTypeIds.radioPersonality:
      await leak("LOOT_AMRADIOFILES", "proof of systemic AM Radio bias");
    case CreatureTypeIds.labTech:
    case CreatureTypeIds.eminentScientist:
      await leak("LOOT_RESEARCHFILES", "internal animal research reports");
    case CreatureTypeIds.conservativeJudge:
    case CreatureTypeIds.liberalJudge:
      await leak("LOOT_JUDGEFILES", "compromising files about another Judge");
    case CreatureTypeIds.ccsArchConservative:
      if (ccsExposure.index >= CCSExposure.lcsGotData.index) break;
      await leak(
          "LOOT_CCS_BACKERLIST", "a list of the CCS's government backers");
      ccsExposure = CCSExposure.lcsGotData;
    default:
      // 2/3 chance of not leaking anything
      if (!oneIn(3)) break;
      // Or find something interesting based on job location
      switch (cr.workSite?.type) {
        case SiteType.amRadioStation:
          await leak("LOOT_AMRADIOFILES", "proof of systemic AM Radio bias");
        case SiteType.cableNewsStation:
          await leak(
              "LOOT_CABLENEWSFILES", "proof of systemic Cable News bias");
        case SiteType.whiteHouse:
        case SiteType.intelligenceHQ:
          await leak("LOOT_SECRETDOCUMENTS", "secret intelligence files");
        case SiteType.prison:
          await leak("LOOT_PRISONFILES", "internal prison records");
        case SiteType.geneticsLab:
        case SiteType.cosmeticsLab:
          await leak("LOOT_RESEARCHFILES", "internal animal research reports");
        case SiteType.corporateHQ:
        case SiteType.ceoHouse:
          await leak("LOOT_CORPFILES", "secret corporate documents");
        default:
          break;
      }
  }
}

/// *******************************
///*
///*   SLEEPERS EMBEZZLING FUNDS
///*
///********************************
Future<void> sleeperEmbezzle(Creature cr, Map<View, int> libpower) async {
  bool takingHeat = false;
  if (lcsRandom(100) > 90 * cr.infiltration) {
    cr.infiltration -= 0.2;
    if (cr.infiltration < 0) {
      if (cr == uniqueCreatures.president) {
        await showMessage(
            "President ${cr.name} has been impeached for corruption.");
        criminalize(cr, Crime.embezzlement);
        await captureCreature(cr);
        politics.promoteVP();
        return;
      } else {
        await showMessage(
            "Sleeper ${cr.name} has been arrested while embezzling funds.");
        criminalize(cr, Crime.embezzlement);
        await captureCreature(cr);
        return;
      }
    } else {
      takingHeat = true;
    }
  }

  // Improves juice, as confidence improves
  addjuice(cr, 10, 1000);

  int income;
  switch (cr.type.id) {
    case CreatureTypeIds.corporateCEO:
    case CreatureTypeIds.president:
      income = (50000 * cr.infiltration).round();
    case CreatureTypeIds.eminentScientist:
    case CreatureTypeIds.corporateManager:
    case CreatureTypeIds.bankManager:
      income = (5000 * cr.infiltration).round();
    default:
      income = (500 * cr.infiltration).round();
  }
  ledger.addFunds(income, Income.embezzlement);

  erase();
  mvaddstrc(6, 1, lightGray, "Sleeper ${cr.name} has embezzled \$$income.");

  if (takingHeat) {
    erase();
    if (cr == uniqueCreatures.president) {
      mvaddstr(
          8, 1, "Unfortunately, watchdogs have noticed the mislaid funds.");
      mvaddstr(9, 1, "A corruption scandal is brewing...");
    } else {
      mvaddstr(8, 1,
          "Unfortunately, Conservatives have noticed funds are going missing.");
      mvaddstr(9, 1, "The Liberal's infiltration score has taken a hit.");
    }
  }
}

Future<void> sleeperSteal(Creature cr, Map<View, int> libpower) async {
  Site? camp =
      findSiteInSameCity(cr.workSite?.city, SiteType.homelessEncampment);
  if (camp == null) return;

  bool takingHeat = false;

  if (lcsRandom(100) > 95 * cr.infiltration) {
    cr.infiltration -= 0.2;
    if (cr.infiltration < 0) {
      if (cr == uniqueCreatures.president) {
        await showMessage(
            "President ${cr.name} has been impeached for corruption.");
        criminalize(cr, Crime.theft);
        await captureCreature(cr);
        politics.promoteVP();
        return;
      } else {
        await showMessage(
            "Sleeper ${cr.name} has been arrested while stealing things.");
        criminalize(cr, Crime.theft);
        await captureCreature(cr);
        return;
      }
    } else {
      takingHeat = true;
      erase();
      await getKey();
    }
  }
  // Improves juice, as confidence improves
  addjuice(cr, 10, 1000);

  cr.infiltration -= lcsRandom(10) * 0.01 - 0.02;

  int numberOfItems = lcsRandom(10) + 1;
  while (numberOfItems-- > 0) {
    Item? item = lootItemForSite(cr.workSite!.type);
    if (item != null) camp.loot.add(item);
  }
  erase();
  mvaddstrc(6, 1, lightGray,
      "Sleeper ${cr.name} has dropped a package off at the homeless camp.");
  if (takingHeat) {
    if (cr == uniqueCreatures.president) {
      mvaddstr(8, 1,
          "Unfortunately, observers have noticed the President's actions.");
      mvaddstr(9, 1, "A corruption scandal is brewing...");
    } else {
      mvaddstr(8, 1,
          "Unfortunately, the Conservatives have noticed things are going missing.");
      mvaddstr(9, 1, "The Liberal's infiltration score has taken a hit.");
    }
  }
  await getKey();
}

Future<void> sleeperRecruit(Creature cr, Map<View, int> libpower) async {
  if (cr.subordinatesLeft > 0) {
    // Special handling for President recruiting cabinet members
    if (cr == uniqueCreatures.president) {
      // Find a cabinet position that isn't already Elite Liberal
      Exec? positionToFill = Exec.values
          .where((e) =>
              e != Exec.president &&
              politics.exec[e] != DeepAlignment.eliteLiberal)
          .randomOrNull;

      if (positionToFill != null) {
        // Calculate the most Liberal candidate the Senate would confirm
        // Start with the current alignment and try to move more Liberal
        DeepAlignment currentAlign = politics.exec[positionToFill]!;
        DeepAlignment bestPossibleAlign = currentAlign;
        int houseVotesRequired = 0;
        if (positionToFill == Exec.vicePresident) {
          houseVotesRequired = politics.house.length ~/ 2 + 1;
        }

        // President's charisma and juice can help convince some Senators
        int bonusVotes = (cr.attribute(Attribute.charisma) / 10).round() +
            (cr.juice / 100).round();

        // Try each more Liberal alignment until we find the most Liberal one that can get confirmed
        for (int i = currentAlign.index + 1;
            i < DeepAlignment.values.length;
            i++) {
          DeepAlignment testAlign = DeepAlignment.values[i];
          int votesFor = 0;
          int houseVotesFor = 0;

          // Count votes from each Senator
          for (DeepAlignment senatorAlign in politics.senate) {
            // Senators will support a candidate one step more Liberal than themselves
            if (testAlign.index <= senatorAlign.index + 1) {
              votesFor++;
            }
          }
          for (DeepAlignment houseAlign in politics.house) {
            if (testAlign.index <= houseAlign.index + 1) {
              houseVotesFor++;
            }
          }

          votesFor += bonusVotes;
          houseVotesFor += bonusVotes;

          // Need 51 votes to confirm
          if (votesFor >= 51 && houseVotesFor >= houseVotesRequired) {
            bestPossibleAlign = testAlign;
          } else {
            break; // Can't get any more Liberal than this
          }
        }

        if (bestPossibleAlign != currentAlign) {
          politics.exec[positionToFill] = bestPossibleAlign;
          String newAlignColor = bestPossibleAlign.colorKey;
          String oldAlignColor = currentAlign.colorKey;
          if (bestPossibleAlign.index == currentAlign.index + 1) {
            // Convince the existing cabinet member to shift to the new alignment
            erase();
            setColor(lightGray);
            addparagraph(
                6,
                1,
                "News from our ${cr.gender.manWoman} in the White House: Under "
                "intense pressure from the President, &$oldAlignColor${positionToFill.displayName} "
                "&$oldAlignColor${politics.execName[positionToFill]!.last}&w "
                "has agreed to adopt &$newAlignColor${bestPossibleAlign.label}&w "
                "policies.");
            addjuice(cr, 25, 1000);
            await getKey();
            return;
          } else if (bestPossibleAlign.index > currentAlign.index) {
            // Appoint the new cabinet member
            FullName oldName = politics.execName[positionToFill]!;
            // Generate a new name for the cabinet member
            politics.execName[positionToFill] =
                generateFullName(switch (bestPossibleAlign) {
              DeepAlignment.archConservative => Gender.whiteMalePatriarch,
              DeepAlignment.conservative => Gender.male,
              DeepAlignment.eliteLiberal => Gender.nonbinary,
              _ => Gender.maleBias,
            });

            erase();
            setColor(lightGray);
            if (positionToFill == Exec.vicePresident) {
              addparagraph(
                  6,
                  1,
                  "News from our ${cr.gender.manWoman} in the White House: Under "
                  "intense pressure from the President, "
                  "&${oldAlignColor}Vice President ${oldName.last}&w "
                  "is resigning. The President already has a new second "
                  "in mind: &$newAlignColor${politics.execName[positionToFill]!.firstLast}&w "
                  "is expected to pass confirmation in both the House and the "
                  "Senate.");
            } else {
              addparagraph(
                  6,
                  1,
                  "News from our ${cr.gender.manWoman} in the White House: Under "
                  "intense pressure from the President, "
                  "&$oldAlignColor${positionToFill.displayName} ${oldName.last}&w "
                  "is resigning. The President already has a new cabinet member "
                  "in mind: &$newAlignColor${politics.execName[positionToFill]!.firstLast}&w "
                  "is expected to pass confirmation in the Senate.");
            }

            // Add juice for successful appointment, more for more Liberal appointments
            addjuice(
                cr, (bestPossibleAlign.index - currentAlign.index) * 25, 1000);

            await getKey();
            return;
          }
        } else {
          // Failed to get a more Liberal appointment confirmed
          String oldAlignColor = currentAlign.colorKey;
          erase();
          setColor(lightGray);
          addparagraph(
              6,
              1,
              "Update from our ${cr.gender.manWoman} in the White House: "
              "Despite the President's best efforts, &$oldAlignColor${positionToFill.displayName} "
              "${politics.execName[positionToFill]!.last}&w continues to "
              "hold out against the internal push for more Liberal policies. "
              "The President is considering other options, but lacks the "
              "votes in Congress to confirm a more Liberal appointment.");

          await getKey();
          return;
        }
      } else {
        // All cabinet positions are already Elite Liberal so let the president
        // recruit like everyone else
      }
    }

    // Normal sleeper recruitment logic for non-Presidents
    activeSite = cr.workSite;
    activeSite ??=
        findSiteInSameCity(cr.workLocation.city, SiteType.publicPark);
    activeSite ??=
        findSiteInSameCity(cr.workLocation.city, SiteType.homelessEncampment);
    if (activeSite == null) return;
    prepareEncounter(activeSite!.type, false);
    for (Creature e in encounter) {
      if (e.workLocation == cr.workLocation || oneIn(5)) {
        if (e.align != Alignment.liberal && !oneIn(5)) continue;

        e.hireId = cr.id;
        liberalize(e);
        e.nameCreature();
        e.sleeperAgent = true;
        e.workSite?.mapped = true;
        e.workSite?.hidden = false;
        pool.add(e);

        erase();
        mvaddstrc(6, 1, lightGray,
            "Sleeper ${cr.name} has recruited a new ${e.type.name}.");
        mvaddstrc(8, 1, lightGray,
            "${e.name} looks forward serving the Liberal cause!");

        await getKey();

        if (cr.subordinatesLeft == 0) cr.activity = Activity.none();
        stats.recruits++;
        break;
      }
    }
  }
  return;
}
