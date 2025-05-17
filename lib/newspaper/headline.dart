import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/location.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/newspaper/display_news.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

String getLastNameForHeadline(String fullName) {
  return fullName.split(' ').last.toUpperCase();
}

int displayStoryHeader(NewsStory ns, bool liberalguardian, View? header) {
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
      if (!liberalguardian) {
        displayCenteredNewsFont("LCS SIEGE", 5, ns);
        displayCenteredNewsFont("TRAGIC END", 11, ns);
      } else {
        displayCenteredNewsFont("POLICE KILL", 5, ns);
        displayCenteredNewsFont("LCS MARTYRS", 11, ns);
      }
    case NewsStories.ccsSiteAction:
    case NewsStories.ccsKilledInSiteAction:
      if (!ccscherrybusted) {
        displayCenteredNewsFont("CONSERVATIVE", 5, ns);
        displayCenteredNewsFont("CRIME SQUAD", 11, ns);
      } else {
        if (ns.positive > 0) {
          displayCenteredNewsFont("CCS STRIKES", 5, ns);
        } else {
          displayCenteredNewsFont("CCS RAMPAGE", 5, ns);
        }
        y = 11;
      }
    default:
      if (ns.positive > 0 || liberalguardian) {
        if (lcscherrybusted || liberalguardian) {
          if (!liberalguardian) {
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
                case View.sweatshops:
                case View.ceoSalary:
                  displayCenteredNewsFont("THE CLASS WAR", 5, ns);
                case View.nuclearPower:
                  displayCenteredNewsFont("MELTDOWN RISK", 5, ns);
                case View.policeBehavior:
                  displayCenteredNewsFont("FUCK THE COPS", 5, ns);
                case View.prisons:
                case View.deathPenalty:
                  displayCenteredNewsFont("FREE THEM NOW", 5, ns);
                case View.intelligence:
                  if (nineteenEightyFour) {
                    displayCenteredNewsFont("FUCK THE LOVE", 5, ns);
                  } else {
                    displayCenteredNewsFont("FUCK THE CIA", 5, ns);
                  }
                case View.animalResearch:
                case View.genetics:
                  displayCenteredNewsFont("ANIMAL RIGHTS", 5, ns);
                case View.freeSpeech:
                case View.lgbtRights:
                case View.justices:
                  displayCenteredNewsFont("FOR JUSTICE", 5, ns);
                case View.pollution:
                  displayCenteredNewsFont("SAVING EARTH", 5, ns);
                case View.corporateCulture:
                  displayCenteredNewsFont("CAPITALISM", 5, ns);
                case View.amRadio:
                case View.cableNews:
                  displayCenteredNewsFont("PROPAGANDISTS", 5, ns);
                default:
                  displayCenteredNewsFont("HEROIC STRIKE", 5, ns);
              }
            } else {
              displayCenteredNewsFont("LCS STRIKES", 5, ns);
            }
          }
        } else {
          displayCenteredNewsFont("LIBERAL CRIME", 5, ns);
          displayCenteredNewsFont("SQUAD STRIKES", 11, ns);
        }
      } else {
        if (lcscherrybusted) {
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
