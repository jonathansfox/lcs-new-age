/* news - show major news story */

import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/siege.dart';
import 'package:lcs_new_age/newspaper/ads.dart';
import 'package:lcs_new_age/newspaper/filler.dart';
import 'package:lcs_new_age/newspaper/headline.dart';
import 'package:lcs_new_age/newspaper/layout.dart';
import 'package:lcs_new_age/newspaper/major_event.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/newspaper/squad_story_text.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/saveload/load_cpc_images.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> displayStory(NewsStory ns, View? header) async {
  bool liberalguardian = ns.publication == Publication.liberalGuardian;
  erase();
  preparePage(ns, liberalguardian);

  String story;
  List<int> storyXStart = [for (var i = 0; i < 25; i++) 1];
  List<int> storyXEnd = [for (var i = 0; i < 25; i++) 78];
  displayAds(ns, liberalguardian, storyXStart, storyXEnd);

  String city = ns.loc?.city.name ?? randomCityName();

  switch (ns.type) {
    case NewsStories.majorEvent:
      displayMajorEventStory(ns, storyXStart, storyXEnd);
    case NewsStories.ccsNoBackers:
    case NewsStories.ccsDefeated:
    case NewsStories.squadSiteAction:
    case NewsStories.squadEscapedSiege:
    case NewsStories.squadFledAttack:
    case NewsStories.squadDefended:
    case NewsStories.squadBrokeSiege:
    case NewsStories.squadKilledInSiegeAttack:
    case NewsStories.squadKilledInSiegeEscape:
    case NewsStories.squadKilledInSiteAction:
    case NewsStories.ccsSiteAction:
    case NewsStories.ccsKilledInSiteAction:
    case NewsStories.carTheft:
    case NewsStories.arrestGoneWrong:
      int y = 2;
      if ((!liberalguardian && ns.page == 1) ||
          (liberalguardian && ns.guardianpage == 1)) {
        y = displayStoryHeader(ns, header);
      }

      story = city;
      story += " - ";

      Map<Drama, int> drama = {for (Drama c in Drama.values) c: 0};
      for (var c in ns.drama) {
        drama.update(c, (level) => level + 1);
      }

      switch (ns.type) {
        case NewsStories.ccsNoBackers:
          story +=
              "The FBI investigation into the Conservative Crime Squad's government connections has led to the arrest of more than "
              "a dozen elected officials and revealed extensive corruption in law enforcement."
              "&r"
              "  \"The uphevals in the police force, and arrest of corrupt officials, are only the beginning,\" FBI Chief "
              "Roberta T. Malton said during a news conference.  \"A major focus "
              "of our efforts will be on the complete destruction of the Conservative Crime Squad. Within six months, we'll have their "
              "entire leadership, dead or alive. I personally guarantee it.\""
              "&r";
        case NewsStories.ccsDefeated:
          story += "An elite FBI force conducted simultaneous "
              "raids on several suspected Conservative Crime Squad safehouses in the early hours. Despite resistance from "
              "CCS terrorists armed with automatic weapons and body armor, no FBI agents were killed in the raids, and all "
              "three raids were successful. Seventeen suspects were killed in the fighting, and twenty-three are "
              "now in custody."
              "&r"
              "  The Conservative Crime Squad fell on hard times when the alternative news site Liberal Guardian published "
              "1147 pages of documents showing extensive government support for the group. The ensuing scandal "
              "led to the arrest of twenty-five members of Congress, as well as several leadership figures in the "
              "Conservative Party's National Committee."
              "&r"
              "  \"I want parents to rest easy tonight,\" FBI Chief "
              "Roberta T. Malton said during a news conference to announce the raids.  \"You don't need the Liberal Crime Squad "
              "to protect you. The Government can handle it.\""
              "&r";
        case NewsStories.arrestGoneWrong:
        case NewsStories.carTheft:
          story += "A routine arrest went horribly wrong yesterday, "
              "according to a spokesperson from the police department.&r"
              "  A suspect, whose identity is unclear, killed ";
          if (drama[Drama.killedSomebody]! > 1) {
            story += drama[Drama.killedSomebody].toString();
            story += " police officers that were";
          } else {
            story += "a police officer that was";
          }
          story += " attempting to perform an arrest.  ";

          if (drama[Drama.killedSomebody]! > 1) {
            story +=
                "The names of the officers have not been released pending notification of their families.";
          } else {
            story +=
                "The name of the officer has not been released pending notification of the officer's family.";
          }
          story += "&r";
        case NewsStories.squadEscapedSiege:
          story += "Members of the Liberal Crime Squad "
              "escaped from a police siege yesterday, according ";
          if (!liberalguardian) {
            story += "to a spokesperson from the police department.";
          } else {
            story += "to a Liberal Crime Squad spokesperson.";
          }
          story += "&r";
        case NewsStories.squadFledAttack:
          story += "Members of the Liberal Crime Squad "
              "escaped from police officers during a raid yesterday, according ";
          if (!liberalguardian) {
            story += "to a spokesperson from the police department.";
          } else {
            story += "to a Liberal Crime Squad spokesperson.";
          }
          story += "&r";
        case NewsStories.squadDefended:
          story += "Members of the Liberal Crime Squad "
              "fought off a police raid yesterday, according ";
          if (!liberalguardian) {
            story += "to a spokesperson from the police department.";
          } else {
            story += "to a Liberal Crime Squad spokesperson.";
          }
          story += "&r";
        case NewsStories.squadBrokeSiege:
          story += "Members of the Liberal Crime Squad "
              "violently broke a police siege yesterday, according ";
          if (!liberalguardian) {
            story += "to a spokesperson from the police department.";
          } else {
            story += "to a Liberal Crime Squad spokesperson.";
          }
          story += "&r";
        case NewsStories.squadKilledInSiegeAttack:
          story += "Members of the Liberal Crime Squad were ";
          if (!liberalguardian) {
            story += "slain during a police raid yesterday, according "
                "to a spokesperson from the police department.";
          } else {
            story += "murdered during a police raid yesterday, according "
                "to a Liberal Crime Squad spokesperson.";
          }
          story += "&r";
        case NewsStories.squadKilledInSiegeEscape:
          story += "Members of the Liberal Crime Squad were ";
          if (!liberalguardian) {
            story +=
                "slain trying to escape from a police siege yesterday, according "
                "to a spokesperson from the police department.";
          } else {
            story +=
                "murdered trying to escape from a police siege yesterday, according "
                "to a Liberal Crime Squad spokesperson.";
          }
          story += "&r";
        default:
          bool ccs = ns.type == NewsStories.ccsKilledInSiteAction ||
              ns.type == NewsStories.ccsSiteAction;

          story += squadStoryTextOpening(ns, ccs);

          bool did(Drama d) => drama[d]! > 0;

          int typesum = drama.entries
              .where((entry) => entry.value >= 1)
              .whereNot((entry) => [
                    Drama.openedCEOSafe,
                    Drama.stoleCorpFiles,
                    Drama.shutDownReactor,
                    Drama.bankVaultRobbery,
                    Drama.bankTellerRobbery,
                    Drama.bankStickup,
                    Drama.openedPoliceLockup,
                    Drama.openedCourthouseLockup,
                    Drama.releasedPrisoners,
                    Drama.juryTampering,
                    Drama.hackedIntelSupercomputer,
                    Drama.openedArmory,
                    Drama.carChase,
                    Drama.carCrash,
                    Drama.footChase,
                    Drama.hijackedBroadcast,
                    Drama.legalGunUsed,
                    Drama.illegalGunUsed,
                  ].contains(entry.key))
              .length;

          if (did(Drama.shutDownReactor)) {
            if (laws[Law.nuclearPower] == DeepAlignment.eliteLiberal) {
              if (!liberalguardian) {
                story += "  According to sources that were at the scene, "
                    "the Liberal Crime Squad contaminated the state's water supply"
                    "yesterday by tampering with equipment on the site."
                    "&r";
              } else {
                story +=
                    "  The Liberal Crime Squad tampered with the state's water supply yesterday, "
                    "demonstrating the extreme dangers of Nuclear Waste. "
                    "&r";
              }
            } else {
              if (!liberalguardian) {
                story += "  According to sources that were at the scene, "
                    "the Liberal Crime Squad nearly caused a catastrophic meltdown of the nuclear "
                    "reactor."
                    "&r";
              } else {
                story +=
                    "  The Liberal Crime Squad brought the reactor to the verge of a nuclear meltdown, "
                    "demonstrating the extreme vulnerability and danger of Nuclear Power Plants. "
                    "&r";
              }
            }
          }
          if (did(Drama.openedPoliceLockup)) {
            if (!liberalguardian) {
              story += "  According to sources that were at the scene, "
                  "the Liberal Crime Squad allegedly freed or attempted to free prisoners from the police lockup."
                  "&r";
            } else {
              story +=
                  "  The Liberal Crime Squad attempted to rescue innocent people from the police lockup, "
                  "saving them from torture and brutality at the hands of Conservative police interrogators."
                  "&r";
            }
          }
          if (did(Drama.bankVaultRobbery)) {
            if (!liberalguardian) {
              story += "  According to sources that were at the scene, "
                  "the Liberal Crime Squad opened the bank vault, which held more than \$100,000 at the time."
                  "&r";
            } else {
              story += "  The Liberal Crime Squad opened the bank vault, "
                  "showing the triumph of Liberal ideals over Conservative economics."
                  "&r";
            }
          } else if (did(Drama.bankStickup)) {
            if (!liberalguardian) {
              story += "  According to sources that were at the scene, "
                  "the Liberal Crime Squad threatened innocent bystanders in order to rob the bank vault."
                  "&r";
            } else {
              story +=
                  "  The Liberal Crime Squad demanded access to the bank vault, "
                  "hoping to acquire the resources to overcome evil."
                  "&r";
            }
          }
          if (did(Drama.openedCourthouseLockup)) {
            if (!liberalguardian) {
              story += "  According to sources that were at the scene, "
                  "the Liberal Crime Squad allegedly freed or attempted to free prisoners from the courthouse lockup."
                  "&r";
            } else {
              story +=
                  "  The Liberal Crime Squad attempted to rescue innocent people from the courthouse lockup, "
                  "saving them from the highly corrupt Conservative justice system."
                  "&r";
            }
          }
          if (did(Drama.releasedPrisoners)) {
            if (!liberalguardian) {
              story += "  According to sources that were at the scene, "
                  "the Liberal Crime Squad allegedly freed prisoners while in the facility."
                  "&r";
            } else {
              story +=
                  "  The Liberal Crime Squad attempted to rescue innocent people from the abusive Conservative conditions "
                  "at the prison."
                  "&r";
            }
          }
          if (did(Drama.juryTampering)) {
            if (!liberalguardian) {
              story += "  According to police sources that were at the scene, "
                  "the Liberal Crime Squad allegedly violated the sacred "
                  "trust and attempted to influence a jury."
                  "&r";
            } else {
              story +=
                  "  The Liberal Crime Squad has apologized over reports that the operation "
                  "may have interfered with jury deliberations."
                  "&r";
            }
          }
          if (did(Drama.hackedIntelSupercomputer)) {
            if (!liberalguardian) {
              story += "  According to police sources that were at the scene, "
                  "intelligence officials seemed very nervous about something."
                  "&r";
            } else {
              story +=
                  "  Liberal Crime Squad computer specialists worked to liberate information from CIA computers."
                  "&r";
            }
          }
          if (did(Drama.openedArmory)) {
            if (!liberalguardian) {
              story += "  According to sources, "
                  "the Liberal Crime Squad attempted to break into the armory."
                  "&r";
            } else {
              story +=
                  "  Liberal Crime Squad infiltration specialists worked to liberate weapons from the oppressors."
                  "&r";
            }
          }
          if (did(Drama.openedCEOSafe)) {
            if (!liberalguardian) {
              story += "  According to police sources that were at the scene, "
                  "the owner of the house seemed very frantic about some missing property."
                  "&r";
            } else {
              story +=
                  "  The Liberal Crime Squad was attempting to uncover the CEO's Conservative corruption."
                  "&r";
            }
          }
          if (did(Drama.stoleCorpFiles)) {
            if (!liberalguardian) {
              story += "  According to police sources that were at the scene, "
                  "executives on the scene seemed very nervous about something."
                  "&r";
            } else {
              story +=
                  "  The Liberal Crime Squad was attempting to uncover the company's Conservative corruption."
                  "&r";
            }
          }
          if (did(Drama.hijackedBroadcast)) {
            if (!liberalguardian) {
              story += "  The Liberal Crime Squad hijacked a news broadcast, "
                  "interrupting regular programming."
                  "&r";
            } else {
              story +=
                  "  The Liberal Crime Squad delivered its message to the masses today."
                  "&r";
            }
          }

          if (liberalguardian && !ccs) {
            if (did(Drama.killedSomebody)) typesum--;
          }

          if (typesum > 0) {
            if (!ccs) {
              if (!liberalguardian) {
                story +=
                    "  Further details are sketchy, but police sources suggest that the LCS "
                    "engaged in ";
              } else {
                story += "  The Liberal Crime Squad ";
              }
            } else {
              story +=
                  "  Further details are sketchy, but police sources suggest that the CCS "
                  "engaged in ";
            }
            debugPrint("typesum: $typesum");
            void addDrama(String drama, [String? alt]) {
              if (!liberalguardian || ccs) {
                story += drama;
              } else {
                story += alt ?? drama;
              }
              if (typesum >= 3) {
                story += ", ";
              } else if (typesum == 2) {
                if (drama.contains(" and ") || (liberalguardian && !ccs)) {
                  story += ", and ";
                } else {
                  story += " and ";
                }
              }
              typesum--;
            }

            if (did(Drama.arson)) {
              addDrama("arson", "set fire to Conservative property");
            }
            if (did(Drama.killedSomebody) && (!liberalguardian || ccs)) {
              addDrama("murder");
            }
            if (did(Drama.attacked)) {
              addDrama(
                  "violence", "engaged in combat with Conservative forces");
            }
            if (did(Drama.stoleSomething) || did(Drama.bankTellerRobbery)) {
              addDrama("theft", "liberated enemy resources");
            }
            if (did(Drama.freeRabbits) || did(Drama.freeMonsters)) {
              addDrama(
                  "tampering with lab animals", "liberated abused animals");
            }
            if (did(Drama.brokeSweatshopEquipment) ||
                did(Drama.brokeFactoryEquipment) ||
                did(Drama.vandalism)) {
              addDrama("destruction of private property",
                  "damaged enemy infrastructure");
            }
            if (did(Drama.tagging)) {
              addDrama("vandalism", "marked the site for Liberation");
            }
            if (did(Drama.brokeDownDoor)) {
              addDrama("breaking and entering", "broke down doors");
            }
            if (did(Drama.unlockedDoor)) {
              addDrama("unlawful entry", "picked locks");
            }
            if (did(Drama.musicalRampage)) {
              addDrama("a musical rampage", "performed an impromptu concert");
            }

            story += "."
                "&r";
          }

          if (did(Drama.carChase)) {
            if (!liberalguardian || ccs) {
              story += "  It is known that there was a high-speed chase "
                  "following the incident.  ";
            } else {
              story += "  Conservative operatives engaged in a reckless "
                  "pursuit of the LCS.  ";
            }

            if (did(Drama.carCrash)) {
              if (drama[Drama.carCrash]! > 1) {
                story += drama[Drama.carCrash].toString();
                story += " vehicles crashed.  ";
              } else {
                story += "One vehicle crashed.  ";
              }
              if (!liberalguardian || ccs) {
                story += "Details about injuries were not released.  ";
              }
            }

            if (did(Drama.footChase)) {
              if (!liberalguardian || ccs) {
                story +=
                    "There was also a foot chase when the suspect or suspects bailed out after the high-speed pursuit.  ";
              } else {
                story +=
                    "The Liberal Crime Squad ended the dangerous high-speed chase in order to protect the public, and attempted to escape on foot.  ";
              }
            }
            story += "&r";
          }

          String culprit = ccs ? "CCS" : "LCS";
          if (ns.publicationAlignment == DeepAlignment.archConservative) {
            if (ns.type == NewsStories.squadKilledInSiteAction) {
              story +=
                  "  A prominent gun advocacy group remarked that it was only "
                  "thanks to the bravery of people carrying guns that this "
                  "didn't turn out worse, and those who stood by and did nothing "
                  "were just as guilty as the ones who committed the crime.&r";
            } else {
              if (ccs) {
                story +=
                    "  A prominent gun advocacy group noted that increased "
                    "gun ownership would help to bring violence like this to "
                    "an end.&r";
              } else {
                story += "  A prominent gun advocacy group noted that it was "
                    "unfortunate that there weren't more armed citizens in "
                    "the area to stop this from happening.&r";
              }
            }
          } else if (did(Drama.legalGunUsed)) {
            story +=
                "  The $culprit was seen to use firearms that are commonly "
                "sold in the state.&r";
          } else if (did(Drama.illegalGunUsed)) {
            story += "  The $culprit was seen to use firearms that are "
                "illegal for civilians to own in this state.&r";
          }

          if (!ccs) {
            if (oneIn(8)) {
              if (did(Drama.tagging)) {
                story +=
                    "  The slogan, \"$slogan\" was found painted on the walls.";
              } else {
                switch (lcsRandom(3)) {
                  case 0:
                    if (ns.type == NewsStories.squadKilledInSiteAction) {
                      story +=
                          "  One uttered the words, \"$slogan\" before passing out.";
                    } else {
                      story += "  As they left, they shouted, \"$slogan\"";
                    }
                  case 1:
                    story +=
                        "  One of them was rumored to have cried out, \"$slogan\"";
                  case 2:
                    story +=
                        "  Witnesses reported hearing the phrase, \"$slogan\"";
                }
              }
              story += "&r";
            }
          }
      }

      story += generateFiller(200);
      displayNewsStory(story, storyXStart, storyXEnd, y, ns);

      if (ns.type == NewsStories.ccsSiteAction ||
          ns.type == NewsStories.ccsKilledInSiteAction) {
        ccsInPublicEye = true;
      } else if (!lcsInPublicEye) {
        lcsInPublicEye = true;
      }

    case NewsStories.massacre:
      int y = 3;
      if (ns.page == 1) {
        y = 19;
        if (ns.siegetype == SiegeType.ccs) {
          displayCenteredNewsFont("CCS MASSACRE", 5, ns);
        } else if (!liberalguardian) {
          displayCenteredNewsFont("MYSTERIOUS", 5, ns);
          displayCenteredNewsFont("MASSACRE", 10, ns);
        } else {
          displayCenteredNewsFont("CONSERVATIVE", 5, ns);
          displayCenteredNewsFont("MASSACRE", 10, ns);
        }
      }

      story = city;
      story += " - ";
      if (ns.siegebodycount > 2) {
        story += ns.siegebodycount.toString();
        story += " bodies were "; //Gruesome pile, large pile.
      } else if (ns.siegebodycount > 1) {
        story += " Two bodies were ";
      } else {
        story += " A body was ";
      }
      story += " found in the ${ns.loc!.name} yesterday.";
      if (!liberalguardian) {
        story += "  According to a spokesperson for "
            "the police department, the matter is under investigation as a homicide."
            "&r"
            "  Privately, sources in the department confide that there aren't any leads.  "
            "According to one person familiar with the case, \"";
      } else {
        story +=
            "  The police have opened an investigation into the massacre, but seem "
            "unwilling to pursue the case with any serious effort."
            "&r"
            "  The Liberal Crime Squad has claimed that the ";
        if (ns.siegebodycount > 1) {
          story += "victims were members ";
        } else {
          story += "victim was a member ";
        }
        story += "of the LCS targeted simply due to their political beliefs.  "
            "According to an LCS spokesperson, \"";
      }
      switch (ns.siegetype) {
        case SiegeType.none:
          story += "We have no idea who did this, or why, or how it happened.  "
              "It's a complete mystery.  A bug in the game even.  "
              "We're working closely with the programmers to find out what happened.\"";
        case SiegeType.cia:
          if (!liberalguardian) {
            if (ns.siegebodycount > 1) {
              story += "The bodies had no faces or ";
            } else {
              story += "The body had no face or ";
            }
            story += "fingerprints.  Like, it was all smooth.  ";
            if (noProfanity) {
              story += "[Strangest] thing I've ever seen";
            } else if (laws[Law.freeSpeech] == DeepAlignment.eliteLiberal) {
              story += "Damnedest thing I've ever seen";
            } else {
              story += "D*mnd*st thing I've ever seen";
            }
          } else {
            story +=
                "We have strong evidence that this was an extra-judicial slaughter "
                "carried out by the Central Intelligence Agency in retaliation for our "
                "previous actions to uncover human rights abuses and corruption in the "
                "intelligence community";
          }
        case SiegeType.police:
          if (!liberalguardian) {
            story += "It's just a gang-related incident.  "
                "You know, the usual.  "
                "Some people just don't know how to live in a civilized society";
          } else {
            story +=
                "It was the cops.  They'll say otherwise, but we know the truth.  "
                "There is no excusing this kind of brutality.  We will not rest until "
                "this kind of government-condoned violence is stopped.  We will not be "
                "intimidated, and we will not be silenced";
          }
        case SiegeType.angryRuralMob:
          if (!liberalguardian) {
            story += "...  stabbed with, maybe, pitchforks.  There may have "
                "been bite marks.  Nothing recognizable left.  Complete carnage.";
          } else {
            story += "We have reason to believe that this brutal massacre was "
                "inspired by the Conservative media's brainwashing propaganda";
          }
        case SiegeType.corporateMercs:
          if (!liberalguardian) {
            story +=
                "It was execution style.  Professional.  We've got nothing";
          } else {
            story +=
                "This massacre has the signature mark of a group of mercenaries "
                "known to work with several corporations we've had confrontations "
                "with in the past.  *When* the police can't figure this one out, they're "
                "just covering it up";
          }
        case SiegeType.ccs:
          if (!liberalguardian) {
            story +=
                "Look, it was a Conservative Crime Squad hit, that's all we know, "
                "no names, no faces, not even where it happened really";
          } else {
            story +=
                "This is the doing of the Conservative Crime Squad butchers.  "
                "They have to be stopped before they kill again";
          }
      }
      story += ".\"  "
          "&r";

      story += generateFiller(200);
      displayNewsStory(story, storyXStart, storyXEnd, y, ns);
    case NewsStories.kidnapReport:
      int y = 2;

      if (ns.page == 1) {
        y = 19;
        if (liberalguardian) {
          displayCenteredNewsFont("LCS DENIES", 5, ns);
          displayCenteredNewsFont("KIDNAPPING", 10, ns);
        } else {
          switch (ns.cr!.type.id) {
            case CreatureTypeIds.president:
              displayCenteredNewsFont("PRESIDENT", 5, ns);
              displayCenteredNewsFont("KIDNAPPED", 10, ns);
              // Instantly bring a max military siege to the site
              if (ns.cr!.typeId == CreatureTypeIds.president) {
                ns.cr!.heat += 1000;
                ns.cr!.site?.heat += 1000 + lcsRandom(1000);
                ns.cr!.site?.siege.timeUntilCops = lcsRandom(3) + 1;
                ns.cr!.site?.siege.escalationState = SiegeEscalation.bombers;
              }
            case CreatureTypeIds.corporateCEO:
              displayCenteredNewsFont("CEO", 5, ns);
              displayCenteredNewsFont("KIDNAPPED", 10, ns);
            case CreatureTypeIds.radioPersonality:
              displayCenteredNewsFont("RADIO HOST", 5, ns);
              displayCenteredNewsFont("KIDNAPPED", 10, ns);
            case CreatureTypeIds.newsAnchor:
              displayCenteredNewsFont("NEWS ANCHOR", 5, ns);
              displayCenteredNewsFont("KIDNAPPED", 10, ns);
            case CreatureTypeIds.eminentScientist:
              displayCenteredNewsFont("SCIENTIST", 5, ns);
              displayCenteredNewsFont("KIDNAPPED", 10, ns);
            case CreatureTypeIds.liberalJudge:
            case CreatureTypeIds.conservativeJudge:
              displayCenteredNewsFont("JUDGE", 5, ns);
              displayCenteredNewsFont("KIDNAPPED", 10, ns);
            case CreatureTypeIds.policeChief:
              displayCenteredNewsFont("POLICE CHIEF", 5, ns);
              displayCenteredNewsFont("KIDNAPPED", 10, ns);
            case CreatureTypeIds.cop:
            case CreatureTypeIds.gangUnit:
              displayCenteredNewsFont("POLICE", 5, ns);
              displayCenteredNewsFont("KIDNAPPED", 10, ns);
            case CreatureTypeIds.deathSquad:
              displayCenteredNewsFont("DEATH COP", 5, ns);
              displayCenteredNewsFont("KIDNAPPED", 10, ns);
            case CreatureTypeIds.actor:
              displayCenteredNewsFont("ACTOR", 5, ns);
              displayCenteredNewsFont("KIDNAPPED", 10, ns);
            default:
              displayCenteredNewsFont("SUSPECTED", 5, ns);
              displayCenteredNewsFont("KIDNAPPING", 10, ns);
          }
        }
      }

      story = city;
      story += " - The disappearance of ${ns.cr!.properName} is now "
          "considered a kidnapping, "
          "according to a police spokesperson."
          "&r"
          "  ${generateFullName(Gender.maleBias).firstLast}, "
          "speaking on behalf of the police department, stated "
          "\"We now believe that ${ns.cr!.properName} was taken "
          "${ns.cr!.daysSinceJoined - 1} days ago, by a person or "
          "persons as yet undetermined.  "
          "We have several leads and are confident that we will "
          "bring ${ns.cr!.properName} back home and bring the "
          "kidnappers to justice.  "
          "As the investigation is ongoing, I cannot be more specific at this time.  "
          "To the citizens, please contact the department if you have any "
          "additional information.\""
          "&r"
          "  According to sources, ${ns.cr!.properName}'s last known location was the "
          "${ns.cr!.workLocation.name}.  Police were seen searching the "
          "surrounding area yesterday."
          "&r";

      story += generateFiller(200);
      displayNewsStory(story, storyXStart, storyXEnd, y, ns);

    default:
      story = "The news is not yet written. Report this as a bug.&r";
      displayNewsStory(story, storyXStart, storyXEnd, 3, ns);
  }

  int c;
  do {
    c = await getKey();
  } while (!isBackKey(c));
}

void displayCenteredNewsFont(String str, int y, NewsStory ns,
    {bool? useBigFont}) {
  if (ns.headline == "") {
    ns.headline = str;
  } else {
    ns.headline += " $str";
  }
  int width = -1;
  int s;
  bool isLetter(String letter) =>
      letter.codePoint >= 'A'.codePoint && letter.codePoint <= 'Z'.codePoint;
  for (s = 0; s < str.length; s++) {
    if (isLetter(str[s].toUpperCase())) {
      width += 6;
    } else if (str[s] == '\'') {
      width += 4;
    } else {
      width += 3;
    }
  }

  int x = 39 - width ~/ 2;

  if (useBigFont == true) {
    for (s = 0; s < str.length; s++) {
      if (isLetter(str[s]) || str[s] == '\'') {
        int p;
        if (isLetter(str[s])) {
          p = str[s].codePoint - 'A'.codePoint;
        } else {
          p = 26;
        }
        int lim = 6;
        if (str[s] == '\'') lim = 4;
        if (s == str.length - 1) lim--;
        for (int x2 = 0; x2 < lim; x2++) {
          for (int y2 = 0; y2 < 7; y2++) {
            move(y + y2, x + x2);
            if (x2 == 5) {
              setColor(ns.publication.backgroundColor,
                  background: ns.publication.backgroundColor);
              addchar(' ');
            } else {
              drawCPCGlyph(bigletters[p][x2][y2],
                  remapLightGray: ns.publication.backgroundColor);
            }
          }
        }
        refresh();
        x += lim;
      } else {
        setColor(ns.publication.backgroundColor,
            background: ns.publication.backgroundColor);
        for (int x2 = 0; x2 < 3; x2++) {
          for (int y2 = 0; y2 < 7; y2++) {
            move(y + y2, x + x2);
            addchar(' ');
          }
        }
        x += 3;
      }
    }
  } else {
    // Print using 4x5 font
    setColor(black, background: ns.publication.backgroundColor);
    print5x5NewsText(y, x, str);
  }
}

void displayCenteredSmallNews(String str, int y, NewsStory ns) {
  ns.body = str;
  int x = 39 - ((str.length - 1) >> 1);
  move(y, x);
  setColor(black, background: ns.publication.backgroundColor);
  addstr(str);
}

void displayNewsPicture(int p, int y, NewsStory ns,
    [bool remapSkinTones = false]) {
  ns.newspaperPhotoId = p;
  ns.remapSkinTones = remapSkinTones;
  renderNewsPic(p, y, remapSkinTones);
}

void renderNewsPic(int p, int y, [bool remapSkinTones = false]) {
  for (int x2 = 0; x2 < 78; x2++) {
    for (int y2 = 0; y2 < 15; y2++) {
      if (y + y2 > 24) break;
      move(y + y2, 1 + x2);
      drawCPCGlyph(newspic[p][x2][y2], remapSkinTones: remapSkinTones);
    }
  }
}

/* news - draws the specified block of text to the screen */
void displayNewsStory(String story, List<int> storyXStart, List<int> storyXEnd,
    int y, NewsStory? ns) {
  ns?.body = newsprintToWebFormat(story);
  List<String> text = [];
  List<bool> centered = [];

  List<String> paragraphs = story.split("&r");
  List<String> lines = [];
  for (String paragraph in paragraphs) {
    bool isCentered = paragraph.contains("&c");
    if (isCentered) {
      paragraph = paragraph.replaceAll("&c", "");
    }

    List<String> words = paragraph.split(" ");
    List<String> line = [];
    int lineLength = 0;
    for (String word in words) {
      int lineY = min(y + lines.length, storyXStart.length - 1);
      int span = storyXEnd[lineY] - storyXStart[lineY] + 1;
      if (lineLength + line.length + word.length + 1 > span) {
        int spacesNeeded = span - lineLength;
        while (spacesNeeded > 0) {
          for (int i = 0; i < line.length - 1; i++) {
            int remainingInLine = line.length - 1 - i;
            if (line[i] != " " &&
                (spacesNeeded > remainingInLine ||
                    lcsRandom(remainingInLine) <= spacesNeeded)) {
              line[i] += " ";
              spacesNeeded--;
              if (spacesNeeded == 0) break;
            }
          }
        }
        lines.add(line.join());
        centered.add(isCentered);
        line = [word];
        lineLength = word.length;
      } else {
        lineLength += word.length;
        line.add(word);
      }
    }
    lines.add(line.join(' '));
    centered.add(isCentered);
  }

  Color bgColor = (ns?.publication ?? Publication.times).backgroundColor;
  setColor(black, background: bgColor);
  for (int cury = y; cury < 25; cury++) {
    if (lines.isEmpty) break;
    if (lines.first.isEmpty) {
      lines.removeAt(0);
      centered.removeAt(0);
      continue;
    }
    lines.first.trim();
    if (centered.first) {
      move(cury,
          (storyXStart[cury] + storyXEnd[cury] - lines.first.length + 1) >> 1);
    } else {
      move(cury, storyXStart[cury]);
    }
    addstr(lines.first);
    lines.removeAt(0);
    centered.removeAt(0);
  }

  setColor(black, background: bgColor);
  for (int t = 0; t < text.length; t++) {
    if (y + t >= 25) break;
    if (text[t].endsWith(' ')) {
      // remove trailing space
      // (necessary for proper centering and to not overwrite borders around an ad)
      text[t] = text[t].substring(0, text[t].length - 2);
    }
    if (centered[t]) {
      move(y + t,
          (storyXStart[y + t] + storyXEnd[y + t] - text[t].length + 1) >> 1);
    } else {
      mvaddstr(y + t, storyXStart[y + t], text[t]);
    }
  }
  text.clear();
}

void archiveNewsStory(NewsStory ns) {
  ns.date = gameState.date.copyWith();
  if (gameState.newsArchive.contains(ns)) return;
  gameState.newsArchive.add(ns);
  if (gameState.newsArchive.length > 51) {
    gameState.newsArchive.removeAt(0);
  }
}
