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
  int y = 21;
  switch (ns.type) {
    case NewsStories.presidentImpeached:
      displayCenteredNewsFont(
          getLastNameForHeadline(politics.oldPresidentName), 5);
      displayCenteredNewsFont("IMPEACHED", 13);
    case NewsStories.presidentBelievedDead:
      displayCenteredNewsFont(
          getLastNameForHeadline(politics.oldPresidentName), 5);
      displayCenteredNewsFont("BELIEVED DEAD", 13);
    case NewsStories.presidentFoundDead:
      displayCenteredNewsFont(
          getLastNameForHeadline(politics.oldPresidentName), 5);
      displayCenteredNewsFont("FOUND DEAD", 13);
    case NewsStories.presidentFound:
      displayCenteredNewsFont(
          getLastNameForHeadline(politics.oldPresidentName), 5);
      displayCenteredNewsFont("RESCUED", 13);
    case NewsStories.presidentKidnapped:
      displayCenteredNewsFont(
          getLastNameForHeadline(politics.oldPresidentName), 5);
      displayCenteredNewsFont("KIDNAPPED", 13);
    case NewsStories.presidentMissing:
      displayCenteredNewsFont(
          getLastNameForHeadline(politics.oldPresidentName), 5);
      displayCenteredNewsFont("MISSING", 13);
    case NewsStories.presidentAssassinated:
      displayCenteredNewsFont(
          getLastNameForHeadline(politics.oldPresidentName), 5);
      displayCenteredNewsFont("ASSASSINATED", 13);
    case NewsStories.ccsNoBackers:
      displayCenteredNewsFont("FBI HUNTS CCS", 5);
      y = 13;
    case NewsStories.ccsDefeated:
      displayCenteredNewsFont("RAIDS END CCS", 5);
      y = 13;
    case NewsStories.carTheft:
    case NewsStories.arrestGoneWrong:
      displayCenteredNewsFont("POLICE KILLED", 5);
      y = 13;
    case NewsStories.squadEscapedSiege:
    case NewsStories.squadFledAttack:
      Location? nsloc = ns.loc;
      if ((nsloc is Site) && nsloc.type == SiteType.homelessEncampment) {
        displayCenteredNewsFont("LCS ESCAPES", 5);
        displayCenteredNewsFont("POLICE SWEEP", 13);
      } else {
        displayCenteredNewsFont("LCS ESCAPES", 5);
        displayCenteredNewsFont("POLICE SIEGE", 13);
      }
    case NewsStories.squadDefended:
    case NewsStories.squadBrokeSiege:
      Location? nsloc = ns.loc;
      if ((nsloc is Site) && nsloc.type == SiteType.homelessEncampment) {
        displayCenteredNewsFont("HOMELESS RIOT", 5);
        displayCenteredNewsFont("REPELS COPS", 13);
      } else {
        displayCenteredNewsFont("LCS FIGHTS", 5);
        displayCenteredNewsFont("OFF COPS", 13);
      }
    case NewsStories.squadKilledInSiegeAttack:
    case NewsStories.squadKilledInSiegeEscape:
      if (!liberalguardian) {
        displayCenteredNewsFont("LCS SIEGE", 5);
        displayCenteredNewsFont("TRAGIC END", 13);
      } else {
        displayCenteredNewsFont("POLICE KILL", 5);
        displayCenteredNewsFont("LCS MARTYRS", 13);
      }
    case NewsStories.ccsSiteAction:
    case NewsStories.ccsKilledInSiteAction:
      if (!ccscherrybusted) {
        displayCenteredNewsFont("CONSERVATIVE", 5);
        displayCenteredNewsFont("CRIME SQUAD", 13);
      } else {
        if (ns.positive > 0) {
          displayCenteredNewsFont("CCS STRIKES", 5);
        } else {
          displayCenteredNewsFont("CCS RAMPAGE", 5);
        }
        y = 13;
      }
    default:
      if (ns.positive > 0 || liberalguardian) {
        if (lcscherrybusted || liberalguardian) {
          if (!liberalguardian) {
            if (ns.priority > 250) {
              y = 13;
              displayCenteredNewsFont(
                  ["HUGE LCS HIT", "UNSTOPPABLE"].random, 5);
            } else {
              y = 13;
              displayCenteredNewsFont("LCS STRIKES", 5);
            }
          } else {
            y = 13;
            if (ns.priority > 150) {
              if (header != null) {
                changePublicOpinion(header, 5,
                    coloredByLcsOpinions: true); // Bonus for big story
              }
              switch (header) {
                case View.taxes:
                case View.sweatshops:
                case View.ceoSalary:
                  displayCenteredNewsFont("THE CLASS WAR", 5);
                case View.nuclearPower:
                  displayCenteredNewsFont("MELTDOWN RISK", 5);
                case View.policeBehavior:
                  displayCenteredNewsFont("FUCK THE COPS", 5);
                case View.prisons:
                case View.deathPenalty:
                  displayCenteredNewsFont("FREE THEM NOW", 5);
                case View.intelligence:
                  displayCenteredNewsFont("FUCK THE CIA", 5);
                case View.animalResearch:
                case View.genetics:
                  displayCenteredNewsFont("ANIMAL RIGHTS", 5);
                case View.freeSpeech:
                case View.lgbtRights:
                case View.justices:
                  displayCenteredNewsFont("FOR JUSTICE", 5);
                case View.pollution:
                  displayCenteredNewsFont("SAVING EARTH", 5);
                case View.corporateCulture:
                  displayCenteredNewsFont("CAPITALISM", 5);
                case View.amRadio:
                case View.cableNews:
                  displayCenteredNewsFont("PROPAGANDISTS", 5);
                default:
                  displayCenteredNewsFont("HEROIC STRIKE", 5);
              }
            } else {
              displayCenteredNewsFont("LCS STRIKES", 5);
            }
          }
        } else {
          displayCenteredNewsFont("LIBERAL CRIME", 5);
          displayCenteredNewsFont("SQUAD STRIKES", 13);
        }
      } else {
        if (lcscherrybusted) {
          displayCenteredNewsFont("LCS RAMPAGE", 5);
          y = 13;
        } else {
          displayCenteredNewsFont("LIBERAL CRIME", 5);
          displayCenteredNewsFont("SQUAD RAMPAGE", 13);
        }
      }
  }
  return y;
}
