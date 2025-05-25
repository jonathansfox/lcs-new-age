import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/location.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/newspaper/display_news.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

String getLastNameForHeadline(String fullName) {
  return fullName.split(' ').last.toUpperCase();
}

int displayStoryHeader(NewsStory ns, View? header) {
  int y = 17;
  switch (ns.type) {
    case NewsStories.presidentImpeached:
      displayCenteredNewsFont(
          getLastNameForHeadline(politics.oldPresidentName), 5, ns);
      displayCenteredNewsFont("IMPEACHED", 11, ns);
    case NewsStories.presidentBelievedDead:
      displayCenteredNewsFont(
          getLastNameForHeadline(politics.oldPresidentName), 5, ns);
      displayCenteredNewsFont("BELIEVED DEAD", 11, ns);
    case NewsStories.presidentFoundDead:
      displayCenteredNewsFont(
          getLastNameForHeadline(politics.oldPresidentName), 5, ns);
      displayCenteredNewsFont("FOUND DEAD", 11, ns);
    case NewsStories.presidentFound:
      displayCenteredNewsFont(
          getLastNameForHeadline(politics.oldPresidentName), 5, ns);
      displayCenteredNewsFont("RESCUED", 11, ns);
    case NewsStories.presidentKidnapped:
      displayCenteredNewsFont(
          getLastNameForHeadline(politics.oldPresidentName), 5, ns);
      displayCenteredNewsFont("KIDNAPPED", 11, ns);
    case NewsStories.presidentMissing:
      displayCenteredNewsFont(
          getLastNameForHeadline(politics.oldPresidentName), 5, ns);
      displayCenteredNewsFont("MISSING", 11, ns);
    case NewsStories.presidentAssassinated:
      displayCenteredNewsFont(
          getLastNameForHeadline(politics.oldPresidentName), 5, ns);
      displayCenteredNewsFont("ASSASSINATED", 11, ns);
    case NewsStories.ccsNoBackers:
      displayCenteredNewsFont("FBI HUNTS CCS", 5, ns);
      y = 11;
    case NewsStories.ccsDefeated:
      displayCenteredNewsFont("RAIDS END CCS", 5, ns);
      y = 11;
    case NewsStories.carTheft:
    case NewsStories.arrestGoneWrong:
      displayCenteredNewsFont("POLICE KILLED", 5, ns);
      y = 11;
    case NewsStories.squadEscapedSiege:
    case NewsStories.squadFledAttack:
      Location? nsloc = ns.loc;
      if ((nsloc is Site) && nsloc.type == SiteType.homelessEncampment) {
        displayCenteredNewsFont("LCS ESCAPES", 5, ns);
        displayCenteredNewsFont("POLICE SWEEP", 11, ns);
      } else {
        displayCenteredNewsFont("LCS ESCAPES", 5, ns);
        displayCenteredNewsFont("POLICE SIEGE", 11, ns);
      }
    case NewsStories.squadDefended:
    case NewsStories.squadBrokeSiege:
      Location? nsloc = ns.loc;
      if ((nsloc is Site) && nsloc.type == SiteType.homelessEncampment) {
        displayCenteredNewsFont("HOMELESS RIOT", 5, ns);
        displayCenteredNewsFont("REPELS COPS", 11, ns);
      } else {
        displayCenteredNewsFont("LCS FIGHTS", 5, ns);
        displayCenteredNewsFont("OFF COPS", 11, ns);
      }
    case NewsStories.squadKilledInSiegeAttack:
    case NewsStories.squadKilledInSiegeEscape:
      if (ns.publicationAlignment != DeepAlignment.eliteLiberal) {
        displayCenteredNewsFont("LCS SIEGE", 5, ns);
        displayCenteredNewsFont("TRAGIC END", 11, ns);
      } else {
        displayCenteredNewsFont("POLICE KILL", 5, ns);
        displayCenteredNewsFont("LCS MARTYRS", 11, ns);
      }
    case NewsStories.ccsSiteAction:
    case NewsStories.ccsKilledInSiteAction:
      if (!ccsInPublicEye) {
        displayCenteredNewsFont("CONSERVATIVE", 5, ns);
        displayCenteredNewsFont("CRIME SQUAD", 11, ns);
      } else {
        if (!ns.liberalSpin) {
          displayCenteredNewsFont("CCS STRIKES", 5, ns);
        } else {
          displayCenteredNewsFont("CCS RAMPAGE", 5, ns);
        }
        y = 11;
      }
    default:
      if (ns.liberalSpin) {
        if (lcsInPublicEye || ns.publication == Publication.liberalGuardian) {
          if (ns.publication != Publication.liberalGuardian) {
            if (ns.priority > 250) {
              y = 11;
              displayCenteredNewsFont(
                  ["HUGE LCS HIT", "UNSTOPPABLE"].random, 5, ns);
            } else {
              y = 11;
              displayCenteredNewsFont("LCS STRIKES", 5, ns);
            }
          } else {
            y = 11;
            if (ns.priority > 150) {
              if (header != null) {
                changePublicOpinion(header, 5,
                    coloredByLcsOpinions: true); // Bonus for big story
              }
              switch (header) {
                case View.taxes:
                  displayCenteredNewsFont(
                      ["TAX EVASION", "TAX THE RICH", "INEQUALITY"].random,
                      5,
                      ns);
                case View.sweatshops:
                  displayCenteredNewsFont(
                      ["HUMAN TOLL", "BROKEN LIVES", "FORCED LABOR"].random,
                      5,
                      ns);
                case View.ceoSalary:
                  displayCenteredNewsFont(
                      ["WEALTH HOARDED", "LAVISH LIES", "RICH TYRANT"].random,
                      5,
                      ns);
                case View.nuclearPower:
                  displayCenteredNewsFont(
                      ["MELTDOWN RISK", "TOXIC LEGACY", "NUCLEAR DREAD"].random,
                      5,
                      ns);
                case View.policeBehavior:
                  displayCenteredNewsFont(
                      ["FUCK THE COPS", "PUBLIC FEAR", "NO AUTHORITY"].random,
                      5,
                      ns);
                case View.prisons:
                case View.deathPenalty:
                  displayCenteredNewsFont(
                      ["FREE THEM NOW", "FREEDOM SOLD", "INMATE ABUSE"].random,
                      5,
                      ns);
                case View.intelligence:
                  if (nineteenEightyFour) {
                    displayCenteredNewsFont(
                        ["NO LOVE LOST", "LOVE OR FEAR", "LOVE IS DEAD"].random,
                        5,
                        ns);
                  } else {
                    displayCenteredNewsFont(
                        ["FUCK THE CIA", "COVERT CHAOS", "SPY WARS"].random,
                        5,
                        ns);
                  }
                case View.animalResearch:
                case View.genetics:
                  displayCenteredNewsFont(
                      ["ANIMAL RIGHTS", "LAB CRUELTY", "ETHICS IGNORED"].random,
                      5,
                      ns);
                case View.freeSpeech:
                case View.lgbtRights:
                case View.justices:
                  displayCenteredNewsFont(
                      ["FOR JUSTICE", "FOR RIGHTS", "INJUSTICE"].random, 5, ns);
                case View.pollution:
                  displayCenteredNewsFont(
                      ["SAVING EARTH", "TOXIC PROFIT", "CHOKED SKIES"].random,
                      5,
                      ns);
                case View.corporateCulture:
                  displayCenteredNewsFont(
                      ["GREED REIGNS", "WHAT ETHICS", "WAGE THEFT"].random,
                      5,
                      ns);
                case View.amRadio:
                  displayCenteredNewsFont(
                      ["DEAD AIR", "NO SIGNAL", "TUNING OUT"].random, 5, ns);
                case View.cableNews:
                  displayCenteredNewsFont(
                      ["SPIN CYCLE", "BIAS TOWN", "PUNDITS DOWN"].random,
                      5,
                      ns);
                default:
                  displayCenteredNewsFont(
                      [
                        "HEROIC STRIKE",
                        "BOLD STRIKE",
                        "JUSTICE WON",
                        "SPARK OF HOPE",
                        "LIBERAL WIN",
                        "BOLD DEFIANCE",
                        "HEROIC ACTION",
                        "HOPE IGNITED",
                        "TRUTH WINS",
                        "HEROES RISE",
                        "LIBERTY TODAY",
                      ].random,
                      5,
                      ns);
              }
            } else {
              displayCenteredNewsFont(["LCS STRIKES"].random, 5, ns);
            }
          }
        } else {
          displayCenteredNewsFont("LIBERAL CRIME", 5, ns);
          displayCenteredNewsFont("SQUAD STRIKES", 11, ns);
        }
      } else {
        if (lcsInPublicEye && ns.priority < 250) {
          displayCenteredNewsFont("LCS RAMPAGE", 5, ns);
          y = 11;
        } else {
          displayCenteredNewsFont("LIBERAL CRIME", 5, ns);
          displayCenteredNewsFont("SQUAD RAMPAGE", 11, ns);
        }
      }
  }
  return y;
}
