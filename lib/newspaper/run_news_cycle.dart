import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/siege.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/newspaper/ccs_storyline.dart';
import 'package:lcs_new_age/newspaper/display_news.dart';
import 'package:lcs_new_age/newspaper/major_event.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/newspaper/television.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> runNewsCycle() async {
  await generateRandomEventNewsStories();
  cleanUpEmptyNewsStories();
  if (canSeeThings) await runTelevisionNewsStories();
  assignPageNumbersToNewspaperStories();
  if (canSeeThings) await displayNewsStories();
  for (NewsStory story in newsStories) {
    handlePublicOpinionImpact(story);
  }
  newsStories.clear();
}

Future<void> generateRandomEventNewsStories() async {
  // Conservative Crime Squad Strikes!
  if (ccsActive && lcsRandom(30) < ccsState.index) {
    ccsStrikesStory();
  }

  // The slow defeat of the Conservative Crime Squad...
  if (ccsActive && ccsExposure.index >= CCSExposure.exposed.index) {
    await advanceCCSDefeatStoryline();
  }

  // Random major event news stories
  if (oneIn(60)) {
    newsStories.add(randomMajorEventStory());
  }
}

Future<void> displayNewsStories() async {
  int guardianPower = 0;
  for (Creature c in pool.where((c) => c.isActiveLiberal)) {
    Skill? skill;
    if (c.activity.type == ActivityType.writeGuardian) {
      skill = Skill.writing;
    } else if (c.activity.type == ActivityType.streamGuardian) {
      skill = Skill.persuasion;
    }
    if (skill != null) {
      guardianPower += c.skillRoll(skill);
      c.train(skill, 10);
      if (noProfanity) criminalize(c, Crime.unlawfulSpeech);
    }
  }

  for (NewsStory n in newsStories) {
    bool liberalguardian = false;
    View? issueFocus;
    if (guardianPower > lcsRandom(100) && n.type != NewsStories.majorEvent) {
      liberalguardian = true;
    }

    if (n.type == NewsStories.squadSiteAction ||
        n.type == NewsStories.squadKilledInSiteAction) {
      issueFocus = switch (n.loc?.type) {
        SiteType.cosmeticsLab => View.animalResearch,
        SiteType.geneticsLab => View.genetics,
        SiteType.policeStation => View.policeBehavior,
        SiteType.courthouse => View.justices,
        SiteType.prison => View.deathPenalty,
        SiteType.intelligenceHQ => View.intelligence,
        SiteType.sweatshop => View.sweatshops,
        SiteType.dirtyIndustry => View.pollution,
        SiteType.nuclearPlant => View.nuclearPower,
        SiteType.corporateHQ => View.corporateCulture,
        SiteType.ceoHouse => View.ceoSalary,
        SiteType.amRadioStation => View.amRadio,
        SiteType.cableNewsStation => View.cableNews,
        SiteType.upscaleApartment ||
        SiteType.barAndGrill ||
        SiteType.bank =>
          View.taxes,
        _ => null,
      };
    }
    if (liberalguardian) {
      if (n.type == NewsStories.ccsSiteAction ||
          n.type == NewsStories.ccsKilledInSiteAction) {
        n.positive = 0;
      }
      await displayStory(n, liberalguardian, issueFocus);
      if (n.positive > 0) {
        n.positive += 1;
      }
    } else {
      await displayStory(n, false, null);
    }
  }
}

void cleanUpEmptyNewsStories() {
  // Delete stories that have no content or shouldn't be reported on
  for (int n = newsStories.length - 1; n >= 0; n--) {
    // Squad site action stories without crimes
    if (newsStories[n].type == NewsStories.squadSiteAction &&
        newsStories[n].drama.isEmpty) {
      newsStories.removeAt(n);
      continue;
    }

    // Police killed stories without police being killed
    if (newsStories[n].type == NewsStories.carTheft ||
        newsStories[n].type == NewsStories.arrestGoneWrong) {
      bool conf = newsStories[n].drama.any((c) => c == Drama.killedSomebody);
      if (!conf) {
        newsStories.removeAt(n);
        continue;
      }
    }

    // Sieges that aren't police actions
    if ((newsStories[n].type == NewsStories.squadEscapedSiege ||
            newsStories[n].type == NewsStories.squadFledAttack ||
            newsStories[n].type == NewsStories.squadDefended ||
            newsStories[n].type == NewsStories.squadBrokeSiege ||
            newsStories[n].type == NewsStories.squadKilledInSiegeAttack ||
            newsStories[n].type == NewsStories.squadKilledInSiegeEscape) &&
        (newsStories[n].siegetype != SiegeType.police)) {
      newsStories.removeAt(n);
      continue;
    }
  }
}

void assignPageNumbersToNewspaperStories() {
  for (int n = newsStories.length - 1; n >= 0; n--) {
    setpriority(newsStories[n]);
    // Suppress squad actions that aren't worth a story
    if (newsStories[n].type == NewsStories.squadSiteAction &&
        ((newsStories[n].priority < 50 && newsStories[n].claimed == 0) ||
            newsStories[n].priority < 4)) {
      newsStories.removeAt(n);
      continue;
    }
    newsStories[n].page = -1;
  }
  bool acted;
  int curpage = 1, curguardianpage = 1;
  do {
    acted = false;
    // Sort the major newspapers
    int maxn = -1, maxp = -1;
    for (int n = 0; n < newsStories.length; n++) {
      if (newsStories[n].priority > maxp && newsStories[n].page == -1) {
        maxn = n;
        maxp = newsStories[n].priority;
      }
    }
    if (maxn != -1) {
      if (newsStories[maxn].priority < 30 && curpage == 1) curpage = 2;
      if (newsStories[maxn].priority < 25 && curpage < 3) {
        curpage = 3 + lcsRandom(2);
      }
      if (newsStories[maxn].priority < 20 && curpage < 5) {
        curpage = 5 + lcsRandom(5);
      }
      if (newsStories[maxn].priority < 15 && curpage < 10) {
        curpage = 10 + lcsRandom(10);
      }
      if (newsStories[maxn].priority < 10 && curpage < 20) {
        curpage = 20 + lcsRandom(10);
      }
      if (newsStories[maxn].priority < 5 && curpage < 30) {
        curpage = 30 + lcsRandom(20);
      }

      newsStories[maxn].page = curpage;
      newsStories[maxn].guardianpage = curguardianpage;
      curpage++;
      curguardianpage++;
      acted = true;
    }
  } while (acted);
}

void handlePublicOpinionImpact(NewsStory ns) {
  // Check if this function is meant to handle public opinion impact
  // for this type of news story (primarily deals with squad/site actions)
  List<NewsStories> okayTypes = [
    NewsStories.squadSiteAction,
    NewsStories.squadEscapedSiege,
    NewsStories.squadFledAttack,
    NewsStories.squadDefended,
    NewsStories.squadBrokeSiege,
    NewsStories.squadKilledInSiegeAttack,
    NewsStories.squadKilledInSiegeEscape,
    NewsStories.squadKilledInSiteAction,
    NewsStories.ccsSiteAction,
    NewsStories.ccsKilledInSiteAction
  ];

  if (!okayTypes.contains(ns.type)) {
    return; // No impact for this news story type
  }

  int impact = ns.priority;

  // Magnitude of impact will be affected by which page of the newspaper the story appears on
  impact *= switch (ns.page) {
    1 => 5,
    2 => 3,
    3 => 2,
    _ => 1,
  };

  int maxpower = switch (ns.page) {
    1 => 100,
    < 5 => 100 - 10 * ns.page,
    < 10 => 40,
    < 20 => 20,
    < 30 => 10,
    < 40 => 5,
    _ => 1,
  };

  // Five times effectiveness with the Liberal Guardian
  if (ns.positive == 2) impact *= 5;
  // Cap power
  if (impact > maxpower) impact = maxpower;

  impact = (impact / 10).round();
  impact++;

  // Account for squad responsible, rampages, and Liberal Guardian bias
  bool ccsResponsible = false;
  bool lcsResponsible = false;
  Alignment impactDirection = Alignment.liberal;
  if (ns.type == NewsStories.ccsSiteAction ||
      ns.type == NewsStories.ccsKilledInSiteAction) {
    ccsResponsible = true;
    impactDirection = Alignment.conservative;
    if (ns.positive > 0) {
      changePublicOpinion(
          View.ccsLiked, -impact); //Negative numbers = favorable for CCS
    } else {
      changePublicOpinion(View.ccsLiked, impact);
    }
  } else {
    lcsResponsible = true;
    changePublicOpinion(View.lcsKnown, 2 + impact.abs());
    impactDirection = Alignment.liberal;
    if (ns.positive > 0) {
      changePublicOpinion(View.lcsLiked, impact);
    } else {
      changePublicOpinion(View.lcsLiked, -impact);
    }
  }
  if (impactDirection == Alignment.conservative) impact = -impact;
  if (impactDirection == Alignment.moderate) impact = 0;

  // Impact gun control issue
  changePublicOpinion(View.gunControl, (impact / 10).abs().ceil());

  if (ns.loc == null) return;

  // Location-specific issue impact
  List<View> issues = switch (ns.loc?.type) {
    SiteType.cosmeticsLab => [View.animalResearch, View.womensRights],
    SiteType.geneticsLab => [View.animalResearch, View.genetics],
    SiteType.policeStation => [View.policeBehavior, View.prisons, View.drugs],
    SiteType.fireStation => [if (noProfanity) View.freeSpeech],
    SiteType.courthouse || SiteType.whiteHouse => [
        View.deathPenalty,
        View.justices,
        View.freeSpeech,
        View.lgbtRights,
        View.womensRights,
        View.civilRights
      ],
    SiteType.prison => [
        View.deathPenalty,
        View.drugs,
        View.torture,
        View.prisons
      ],
    SiteType.armyBase => [View.torture, View.military],
    SiteType.intelligenceHQ => [View.intelligence, View.torture, View.prisons],
    SiteType.sweatshop => [View.sweatshops, View.immigration],
    SiteType.dirtyIndustry => [View.sweatshops, View.pollution],
    SiteType.nuclearPlant => [View.nuclearPower],
    SiteType.corporateHQ => [
        View.taxes,
        View.corporateCulture,
        View.womensRights
      ],
    SiteType.ceoHouse => [View.taxes, View.ceoSalary],
    SiteType.amRadioStation => [
        View.amRadio,
        View.freeSpeech,
        View.lgbtRights,
        View.womensRights,
        View.civilRights
      ],
    SiteType.cableNewsStation => [
        View.cableNews,
        View.freeSpeech,
        View.lgbtRights,
        View.womensRights,
        View.civilRights
      ],
    SiteType.upscaleApartment => [View.taxes, View.ceoSalary, View.gunControl],
    SiteType.barAndGrill => [
        View.taxes,
        View.ceoSalary,
        View.womensRights,
        View.gunControl,
        View.lgbtRights
      ],
    SiteType.bank => [View.taxes, View.ceoSalary, View.corporateCulture],
    _ => [],
  };
  for (View issue in issues) {
    changePublicOpinion(issue, impact,
        coloredByLcsOpinions: lcsResponsible,
        coloredByCcsOpinions: ccsResponsible);
  }
}

/* news - determines the priority of a news story */
void setpriority(NewsStory ns) {
  // Priority is set differently based on the type of the news story
  switch (ns.type) {
    // Major events always muscle to the front page by having a very high priority
    case NewsStories.majorEvent:
      ns.priority = 30000;
    // LCS-related news stories are more important if they involve lots of headline-grabbing
    // crimes
    case NewsStories.squadSiteAction:
    case NewsStories.squadEscapedSiege:
    case NewsStories.squadFledAttack:
    case NewsStories.squadDefended:
    case NewsStories.squadBrokeSiege:
    case NewsStories.squadKilledInSiegeAttack:
    case NewsStories.squadKilledInSiegeEscape:
    case NewsStories.squadKilledInSiteAction:
    case NewsStories.carTheft:
    case NewsStories.arrestGoneWrong:
      ns.priority = 0;

      Map<Drama, int> drama = {for (Drama d in Drama.values) d: 0};
      // Record all the dramas in this story
      for (Drama d in ns.drama) {
        drama.update(d, (i) => i + 1);
      }
      // Cap publicity for more than ten repeats of an action of some type
      if (drama[Drama.stoleSomething]! > 10) drama[Drama.stoleSomething] = 10;
      if (drama[Drama.brokeDownDoor]! > 10) drama[Drama.brokeDownDoor] = 10;
      if (drama[Drama.attacked]! > 10) drama[Drama.attacked] = 10;
      if (drama[Drama.vandalism]! > 10) drama[Drama.vandalism] = 10;
      if (drama[Drama.freeRabbits]! > 10) drama[Drama.freeRabbits] = 10;
      if (drama[Drama.freeMonsters]! > 10) drama[Drama.freeMonsters] = 10;
      if (drama[Drama.tagging]! > 10) drama[Drama.tagging] = 10;

      // Increase news story priority based on the number of instances of
      // various crimes, scaled by a factor dependant on the crime

      // Unique site crimes
      ns.priority += drama[Drama.bankVaultRobbery]! * 100;
      ns.priority += drama[Drama.bankStickup]! * 100;
      ns.priority += drama[Drama.shutDownReactor]! * 100;
      ns.priority += drama[Drama.hackedIntelSupercomputer]! * 100;
      ns.priority += drama[Drama.openedArmory]! * 100;
      ns.priority += drama[Drama.openedCEOSafe]! * 100;
      ns.priority += drama[Drama.stoleCorpFiles]! * 100;
      ns.priority += drama[Drama.releasedPrisoners]! * 50;
      ns.priority += drama[Drama.openedPoliceLockup]! * 30;
      ns.priority += drama[Drama.openedCourthouseLockup]! * 30;
      ns.priority += drama[Drama.juryTampering]! * 30;
      ns.priority += drama[Drama.bankTellerRobbery]! * 30;

      // Common site crimes
      ns.priority += drama[Drama.killedSomebody]! * 30;
      ns.priority += drama[Drama.freeMonsters]! * 12;
      ns.priority += drama[Drama.freeRabbits]! * 8;
      ns.priority += drama[Drama.vandalism]! * 8;
      ns.priority += drama[Drama.tagging]! * 2;
      ns.priority += drama[Drama.attacked]! * 2;

      // Add additional priority based on the type of news story
      // and how high profile the LCS is
      int fame = publicOpinion[View.lcsKnown]! ~/ 3;
      ns.priority += switch (ns.type) {
        NewsStories.squadEscapedSiege => fame + 10,
        NewsStories.squadFledAttack => fame + 15,
        NewsStories.squadDefended => fame + 30,
        NewsStories.squadBrokeSiege => fame + 45,
        NewsStories.squadKilledInSiegeAttack => fame + 10,
        NewsStories.squadKilledInSiteAction => fame + 10,
        _ => 0,
      };

      // Suppress actions at CCS safehouses
      if (ns.loc?.controller == SiteController.ccs) {
        ns.priority = 0;
      }

      // Double profile if the squad declared their involvement somehow
      if (ns.claimed == 2) {
        ns.priority *= 2;
      }

      // Modify notability by location
      if (ns.loc != null) {
        switch (ns.loc!.type) {
          // Nobody snitches
          case SiteType.drugHouse:
            if (ns.type == NewsStories.squadKilledInSiteAction ||
                ns.type == NewsStories.squadSiteAction) {
              ns.priority = 0;
              break;
            }
          // News doesn't care
          case SiteType.tenement:
            ns.priority = ns.priority ~/ 10;
          // Extra attention
          case SiteType.nuclearPlant:
          case SiteType.policeStation:
          case SiteType.courthouse:
          case SiteType.prison:
          case SiteType.intelligenceHQ:
          case SiteType.armyBase:
          case SiteType.fireStation:
          case SiteType.corporateHQ:
          case SiteType.ceoHouse:
          case SiteType.amRadioStation:
          case SiteType.cableNewsStation:
          case SiteType.bank:
          case SiteType.whiteHouse:
            ns.priority *= 2;
          // Normal priority
          default:
            break;
        }
      }

      // Cap news priority, in part so it can't displace major news stories
      if (ns.priority > 20000) ns.priority = 20000;
    case NewsStories.kidnapReport:
      // Kidnappings are higher priority if they're an archconservative or otherwise prominent
      ns.priority = 20;
      if (ns.cr?.type.id == CreatureTypeIds.corporateCEO ||
          ns.cr?.type.id == CreatureTypeIds.radioPersonality ||
          ns.cr?.type.id == CreatureTypeIds.newsAnchor ||
          ns.cr?.type.id == CreatureTypeIds.eminentScientist ||
          ns.cr?.type.id == CreatureTypeIds.president ||
          ns.cr?.type.id == CreatureTypeIds.conservativeJudge ||
          ns.cr?.type.id == CreatureTypeIds.liberalJudge ||
          ns.cr?.type.id == CreatureTypeIds.actor) {
        ns.priority = 40;
      }
    case NewsStories.massacre:
      // More people massacred, higher priority
      ns.priority = 10 + ns.siegebodycount * 5;
    case NewsStories.ccsSiteAction:
    case NewsStories.ccsKilledInSiteAction:
      // CCS actions loosely simulate LCS actions; here it adds some
      // random site crimes to the story and increases the
      // priority accordingly
      ns.drama.add(Drama.brokeDownDoor);
      ns.priority = 1;
      if (ns.positive == 0) {
        ns.priority += 7;
      }
      ns.drama.add(Drama.attacked);
      ns.priority += 4 * (lcsRandom(10) + 1);
      if (lcsRandom(ccsState.index + 1) > 0) {
        ns.drama.add(Drama.killedSomebody);
        ns.priority += lcsRandom(10) * 30;
      }
      if (lcsRandom(ccsState.index + 1) > 0) {
        ns.drama.add(Drama.stoleSomething);
        ns.priority += lcsRandom(10);
      }
      if (oneIn(ccsState.index + 4)) {
        ns.drama.add(Drama.vandalism);
        ns.priority += lcsRandom(10) * 2;
      }
      if (oneIn(2)) {
        ns.drama.add(Drama.carChase);
      }
    case NewsStories.ccsDefended:
    case NewsStories.ccsKilledInSiegeAttack:
      ns.priority = 40 + publicOpinion[View.lcsKnown]! ~/ 3;
    default:
      break;
  }
}
