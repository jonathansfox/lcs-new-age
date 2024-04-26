import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/newspaper/display_news.dart';
import 'package:lcs_new_age/newspaper/filler.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

NewsStory randomMajorEventStory() {
  NewsStory ns = NewsStory.unpublished(NewsStories.majorEvent);
  while (true) {
    ns.view = View.issues.random;
    ns.positive = lcsRandom(2);

    // Skip issues that we have no news stories for
    if (ns.view == View.immigration) continue;
    if (ns.view == View.drugs) continue;
    if (ns.view == View.military) continue;
    if (ns.view == View.civilRights) continue;
    if (ns.view == View.torture) continue;

    // News stories that don't apply when the law is extreme -- covering
    // nuclear power when it's banned, police corruption when it doesn't
    // exist, out of control pollution when it's under control, etc.
    if (ns.positive > 0) {
      Law? law = switch (ns.view) {
        View.womensRights => Law.genderEquality,
        View.deathPenalty => Law.deathPenalty,
        View.nuclearPower => Law.nuclearPower,
        View.animalResearch => Law.animalRights,
        View.policeBehavior => Law.policeReform,
        View.intelligence => Law.privacy,
        View.sweatshops => Law.labor,
        View.pollution => Law.pollution,
        View.corporateCulture => Law.corporate,
        View.ceoSalary => Law.corporate,
        _ => null,
      };
      DeepAlignment banAlignment = DeepAlignment.eliteLiberal;
      if (ns.view == View.womensRights) {
        banAlignment = DeepAlignment.archConservative;
      }
      if (law != null) {
        if (laws[law] == banAlignment) continue;
      }
    } else {
      Law? law = switch (ns.view) {
        View.womensRights => Law.genderEquality,
        View.amRadio => Law.freeSpeech,
        View.animalResearch => Law.animalRights,
        _ => null,
      };
      DeepAlignment banAlignment = DeepAlignment.eliteLiberal;
      if (law == Law.freeSpeech) banAlignment = DeepAlignment.archConservative;
      if (law != null) {
        if (laws[law] == banAlignment) continue;
      }
    }

    break;
  }

  if (ns.positive > 0) {
    changePublicOpinion(ns.view!, 20);
  } else {
    changePublicOpinion(ns.view!, -20);
  }
  politics.publicInterest.update(ns.view!, (value) => value + 50);
  return ns;
}

const int pictureMutantBeast = 0;
const int pictureCEO = 1;
const int pictureReaganBook = 2;
const int pictureNuclearMeltdown = 3;
const int pictureGenetics = 4;
const int pictureRiverFire = 5;
const int pictureDollarsDisappearing = 6;
const int pictureTinkyWinky = 7;
const int pictureOil = 8;
const int pictureTerroristAttack = 9;
const int pictureHateRally = 10;
const int pictureFashionLine = 11;
const int pictureTshirtWithPleaForHelp = 12;

void displayMajorEventStory(
    NewsStory ns, List<int> storyXStart, List<int> storyXEnd) {
  if (ns.positive > 0) {
    switch (ns.view) {
      case View.womensRights:
        displayCenteredNewsFont("CLINIC MURDER", 5);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 13);
      case View.lgbtRights:
        displayCenteredNewsFont("CRIME OF HATE", 5);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 13);
      case View.deathPenalty:
        displayCenteredNewsFont("JUSTICE DEAD", 5);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 13);
      /*
         case View.MILITARY:
            displaycenterednewsfont("CASUALTIES MOUNT",5);
            displaycenteredsmallnews("Is the latest military invasion yet another quagmire?",12);
            story = "";
            generatefiller(story,200);
            displayNewsStory(story,storyXStart,storyXEnd,13);
            break;
            */
      /*
         case View.POLITICALVIOLENCE:
            displaycenterednewsfont("NIGHTMARE",5);
            constructeventstory(story,ns.view,ns.positive);
            generatefiller(story,200);
            displayNewsStory(story,storyXStart,storyXEnd,13);
            break;
            */
      case View.gunControl:
        displayCenteredNewsFont("MASS SHOOTING", 5);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 13);
      case View.taxes:
        displayCenteredNewsFont(
            "REAGAN FLAWED", 5); //XXX: "Reagan was wrong" or something?
        String str =
            "${["Dark", "Shadow", "Abyssal", "Orwellian", "Craggy"].random} ${[
          "Actor",
          "Lord",
          "Emperor",
          "Puppet",
          "Dementia"
        ].random}: A new book further documenting the other side of Reagan.";
        displayCenteredSmallNews(str, 12);
        displayNewsPicture(pictureReaganBook, 13);
      case View.nuclearPower:
        displayCenteredNewsFont("MELTDOWN", 5);
        displayCenteredSmallNews(
            "A nuclear power plant suffers a catastrophic meltdown.", 12);
        displayNewsPicture(pictureNuclearMeltdown, 13);
      case View.animalResearch:
        displayCenteredNewsFont("HELL ON EARTH", 5);
        displayCenteredSmallNews(
            "A mutant animal has escaped from a lab and killed thirty people.",
            12);
        displayNewsPicture(pictureMutantBeast, 13);
      case View.prisons:
        displayCenteredNewsFont("ON THE INSIDE", 5);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 13);
      case View.intelligence:
        displayCenteredNewsFont("THE FBI FILES", 5);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 13);
      case View.freeSpeech:
        displayCenteredNewsFont("BOOK BANNED", 5);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 13);
      case View.genetics:
        displayCenteredNewsFont("KILLER FOOD", 5);
        displayCenteredSmallNews(
            "Over a hundred people become sick from genetically modified food.",
            12);
        displayNewsPicture(pictureGenetics, 13);
      case View.justices:
        displayCenteredNewsFont("IN CONTEMPT", 5);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 13);
      case View.sweatshops:
        displayCenteredNewsFont("CHILD'S PLEA", 5);
        displayCenteredSmallNews(
            "A T-shirt in a store is found scrawled with a message from a sweatshop worker.",
            12);
        displayNewsPicture(pictureTshirtWithPleaForHelp, 13);
      case View.pollution:
        displayCenteredNewsFont("RIVER ON FIRE", 5);
        displayCenteredSmallNews(
            "The Cuyahoga River is ablaze as pollution increases.", 12);
        displayNewsPicture(pictureRiverFire, 13);
      case View.corporateCulture:
        displayCenteredNewsFont("FINANCE FRAUD", 5);
        String companyName = "${[
          "Anti", "Dis", "Fore", "Uni", "Sub", "Pre", "Under", "Inter", //
        ].random}${[
          "bolt", "card", "fold", "run", "star", "flow", "wind", "fire", //
        ].random} ${[
          "Industries", "Enterprises", "Holdings", "Group", "International", //
        ].random}";
        displayCenteredSmallNews(
            "Investors out billions as $companyName collapses.", 12);
        displayNewsPicture(pictureDollarsDisappearing, 13);
      case View.ceoSalary:
        displayCenteredNewsFont("AMERICAN CEO", 5);
        String str = "This major CEO ${[
          "wants you to worship him like a god",
          "only works one day a week",
          "donated millions to the KKK",
          "hasn't paid taxes in over 20 years",
          "took out a contract on his wife",
          "doesn't know what his company does",
          "hunts endangered species for fun",
          "imprisoned and tortured an intern",
          "installed hidden cameras in an office bathroom",
          "owns slaves in three countries",
        ].random}.";
        displayCenteredSmallNews(str, 12);
        displayNewsPicture(pictureCEO, 13, true);
      case View.amRadio:
        displayCenteredNewsFont("AM IMPLOSION", 5);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 13);
      default:
        displayCenteredNewsFont("BUGGY GAME", 5);
        displayCenteredSmallNews(
            "There's no good news story for ${ns.view}", 12);
        displayNewsStory(generateFiller(200), storyXStart, storyXEnd, 15);
    }
  } else {
    switch (ns.view) {
      case View.lgbtRights:
        displayCenteredNewsFont("KINKY WINKY", 5);
        displayCenteredSmallNews(
            "Jerry Falwell's zombie rises to warn us about Tinky Winky.  Again.",
            12);
        displayNewsPicture(pictureTinkyWinky, 13);
      case View.deathPenalty:
        displayCenteredNewsFont("LET'S FRY 'EM", 5);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 13);
      /*
         case View.MILITARY:
            displaycenterednewsfont("BIG VICTORY",5);
            displaycenteredsmallnews("Our boys defend freedom once again, defeating an evil dictator.",13);
            story = "";
            generatefiller(story,200);
            displayNewsStory(story,storyXStart,storyXEnd,15);
            break;
            */
      /*
         case View.POLITICALVIOLENCE:
            displaycenterednewsfont("END IN TEARS",5);
            constructeventstory(story,ns.view,ns.positive);
            generatefiller(story,200);
            displayNewsStory(story,storyXStart,storyXEnd,13);
            break;
            */
      case View.gunControl:
        displayCenteredNewsFont("ARMED CITIZEN", 5);
        displayCenteredNewsFont("SAVES LIVES", 13);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 21);
      case View.taxes:
        displayCenteredNewsFont("REAGAN THE MAN", 5);
        String str = "${["Great", "Noble", "True", "Pure", "Golden"].random} ${[
          "Leadership", "Courage", "Pioneer", "Communicator", "Faith" //
        ].random}: A new book lauding Reagan and the greatest generation.";
        displayCenteredSmallNews(str, 12);
        displayNewsPicture(pictureReaganBook, 13);
      case View.nuclearPower:
        displayCenteredNewsFont("OIL CRUNCH", 5);
        displayCenteredSmallNews(
            "OPEC cuts oil production sharply in response to a US foreign policy decision.",
            12);
        displayNewsPicture(pictureOil, 13);
      case View.animalResearch:
        displayCenteredNewsFont("APE EXPLORERS", 5);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 13);
      case View.policeBehavior:
        if (noProfanity) {
          displayCenteredNewsFont("[JERKS]", 5);
        } else {
          displayCenteredNewsFont("BASTARDS", 5);
        }
        displayNewsPicture(pictureTerroristAttack, 13);
      case View.prisons:
        displayCenteredNewsFont("HOSTAGE SLAIN", 5);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 13);
      case View.intelligence:
        displayCenteredNewsFont("DODGED BULLET", 5);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 13);
      case View.freeSpeech:
        displayCenteredNewsFont("HATE RALLY", 5);
        displayCenteredSmallNews(
            "Free speech advocates fight hard to let a white supremacist rally take place.",
            12);
        displayNewsPicture(pictureHateRally, 13, true);
      case View.genetics:
        displayCenteredNewsFont("GM FOOD FAIRE", 5);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 13);
      case View.justices:
        displayCenteredNewsFont("JUSTICE AMOK", 5);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 13);
      case View.sweatshops:
        displayCenteredNewsFont("THEY ARE HERE", 5);
        if (month >= 8 && month <= 11) {
          displayCenteredSmallNews(
              "Fall fashions hit the stores across the country.", 12);
        } else {
          displayCenteredSmallNews(
              "Fall fashions are previewed in stores across the country.", 12);
        }
        displayNewsPicture(pictureFashionLine, 13);
      case View.pollution:
        displayCenteredNewsFont("LOOKING UP", 5);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 13);
      case View.corporateCulture:
        displayCenteredNewsFont("NEW JOBS", 5);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 13);
      case View.amRadio:
        displayCenteredNewsFont("FM OBSCENITY", 5);
        displayNewsStory(majorEventStoryText(ns.view, ns.positive > 0),
            storyXStart, storyXEnd, 13);
      default:
        displayCenteredNewsFont("BUGGY GAME", 5);
        displayCenteredSmallNews(
            "There's no bad news story for ${ns.view}", 12);
        displayNewsStory(generateFiller(200), storyXStart, storyXEnd, 15);
    }
  }
}

String majorEventStoryText(View? view, bool positive) {
  String story;

  if (positive) {
    switch (view) {
      case View.womensRights:
        FullName doctor = generateFullName(Gender.female);
        FullName perpetrator = generateFullName(Gender.male);
        String abortions = switch (laws[Law.genderEquality]) {
          DeepAlignment.archConservative => "illegal abortion-murders",
          DeepAlignment.conservative => "illegal abortions",
          DeepAlignment.moderate => "semi-legal abortions",
          _ => "abortions",
        };

        story = "${randomCityName()} - A doctor that routinely performed "
            "$abortions was ruthlessly gunned down outside of the "
            "${lastName()} Clinic yesterday.  Dr. ${doctor.firstLast} "
            "was walking to her car when, according to police reports, shots "
            "were fired from a nearby vehicle.  She was hit ${lcsRandom(15) + 3} "
            "times and died immediately in the parking lot.  The suspected "
            "shooter, ${perpetrator.firstLast}, is in "
            "custody.&r"
            "  Witnesses report that ${perpetrator.last} remained at the scene "
            "after the shooting, screaming verses of the Bible at the stunned "
            "onlookers.  Someone called the police on a cellphone and they "
            "arrived shortly thereafter.  ${perpetrator.last} surrendered "
            "without a struggle, reportedly saying that God's work had been "
            "completed.&r"
            "  Dr. ${doctor.last} is survived by her husband and "
            "two children.&r";

      case View.lgbtRights:
        FullName victim = generateFullName(Gender.female);
        String victimDeadName = firstName(Gender.male);
        String victimFullName = laws[Law.lgbtRights]! < DeepAlignment.moderate
            ? "$victimDeadName ${victim.last}"
            : victim.firstLast;
        String victimLabel = switch (laws[Law.lgbtRights]) {
          DeepAlignment.archConservative =>
            "${noProfanity ? "[confused man]" : "tranny"} calling himself \"${victim.first}\"",
          DeepAlignment.conservative =>
            "transsexual calling himself \"${victim.first}\"",
          _ => "trans woman",
        };
        String murdered = [
          "dragged to death behind a pickup truck",
          "burned alive",
          "beaten to death",
        ].random;
        String actionTowardPolice = [
          "throwing ${noProfanity ? "[juice boxes]" : "beer bottles"}",
          "${noProfanity ? "[relieving themselves]" : "pissing"} out the window",
          "taking swipes",
        ].random;
        String chaseEnd = [
          "ran out of gas",
          "collided with a manure truck",
          "veered into a ditch",
          "were surrounded by alert citizens",
          "were caught in traffic",
        ].random;
        String despiteTheBan = switch (laws[Law.lgbtRights]) {
          DeepAlignment.archConservative => noProfanity
              ? ", even though transgenderism is deviant, as we all know"
              : ", despite the fact that $victimFullName was a known transsexual",
          _ => "",
        };

        story = "${randomCityName()} - $victimFullName, a "
            "$victimLabel, was $murdered here yesterday.  "
            "A police spokesperson reported that "
            "four suspects were apprehended after a high speed chase.  Their "
            "names have not yet been released.&r"
            "  Witnesses of the freeway chase described the pickup of the "
            "alleged murderers swerving wildly, $actionTowardPolice at the "
            "pursuing police cruisers.  The chase ended when "
            "the suspects $chaseEnd, at which point they were taken into "
            "custody.  Nobody was seriously injured during the pursuit.&r"
            "  Authorities have stated that they will vigorously prosecute "
            "this case as a hate crime, due to the aggravated nature of the "
            "offense$despiteTheBan.&r";

      case View.deathPenalty:
        FullName victim = generateFullName(Gender.male);
        String timeOfDeath =
            "${lcsRandom(12) + 1}:${lcsRandom(6)}${lcsRandom(10)} ${oneIn(2) ? "AM" : "PM"}";
        int yearConvicted = year - lcsRandom(11) - 10;
        String exculpatoryEvidence = [
          "a confession from another convict",
          "a battery of negative DNA tests",
          "an admission from a former prosecutor that ${victim.last} was framed",
        ].random;
        String awfulReason = [
          "Black male, 5'10\", 180 pounds.  We have our man, no question.",
          "He was found guilty in a court of law.  End of story.",
          "Anyone who kills innocent people deserves death.",
        ].random;

        story = "${randomStateName()} - An innocent citizen has been put "
            "to death in the electric chair.  "
            "$victim was pronounced dead at $timeOfDeath yesterday at the "
            "${lastName()} Correctional Facility.&r"
            "  ${victim.last} was convicted in $yearConvicted of 13 "
            "serial murders.  Since then, numerous pieces of exculpatory "
            "evidence have been produced, including $exculpatoryEvidence.  "
            "The state still went through with the execution, with "
            "a spokesperson for the governor saying, \"$awfulReason\"&r"
            "  Candlelight vigils were held throughout the country last night "
            "during the execution, and more events are expected this evening.  "
            "If there is a bright side to be found from this tragedy, it will "
            "be that our nation is now evaluating the ease with which people "
            "can be put to death in this country.&r";

      case View.intelligence:
        String harmlessBehavior = [
          "buying music with 'Explicit Lyrics' labels",
          "helping homeless people",
          "eating at vegan restaurants",
          "drinking soy milk",
          "reading too many books",
        ].random;

        story = "Washington, DC - The FBI might be keeping tabs on you.  "
            "This newspaper yesterday received a collection of files from "
            "a source in the Federal Bureau of Investigations.  The files "
            "contain information on which people have been attending "
            "demonstrations, organizing unions, working for liberal "
            "organizations —— even $harmlessBehavior.&r"
            "  More disturbingly, the files make reference to a plan to "
            "\"deal with the undesirables\", although this phrase is not "
            "clarified.&r"
            "  The FBI refused to comment initially, but when confronted "
            "with the information, a spokesperson stated, \""
            "Well, you know, there's privacy, and then there's privacy.  "
            "It might be a bit presumptive to assume that these files deal "
            "with the one and not the other.  You think about that before "
            "you continue slanging accusations.\"&r";

      case View.freeSpeech:
        String protagonist = firstName();
        String bookTitle = "$protagonist "
            "and the ${[
          "Mysterious", "Magical", "Golden", "Invisible", //
          "Wondrous", "Amazing", "Secret",
        ].random} ${[
          "School", "Castle", "Forest", "Wizard", //
          "Thing", "Object", "Friend",
        ].random}";
        FullName author = generateFullName();
        String authorName =
            "${author.first} ${author.middle.substring(0, 1)}. ${author.last}";
        String nationality = [
          "British", "Indian", "Chinese", "Rwandan", //
          "Palestinian", "Egyptian", "French", "German",
          "Iraqi", "Bolivian", "Columbian",
        ].random;
        String insaneBanReason = [
          "glorifies Satan worship and was spawned by demons from the pit",
          "teaches children to kill their parents and hate life",
          "causes violence in schools and is a gateway to cocaine use",
          "breeds demonic thoughts that manifest themselves as dreams of murder",
          "contains step-by-step instructions to summon the Prince of Darkness"
        ].random;
        String childMisbehavior = [
          "swore in class",
          "said a magic spell at her parents",
          "${["pushed", "hit", "slapped", "insulted", "tripped"].random} "
              "${["his", "her"].random} ${["older", "younger"].random}"
              "${["brother", "sister"].random}",
        ].random;
        String sadChildQuote = [
          "Mamma, is $protagonist dead?",
          "Mamma, why did they kill $protagonist?"
        ].random;

        story = "${randomCityName()} - A children's story has been removed "
            "from libraries here after the city bowed to pressure from "
            "religious groups.&r"
            "   The book, $bookTitle, is an immensely popular book by "
            "$nationality author $authorName.  Although the title is "
            "adored by children worldwide, some conservatives feel that "
            "the book $insaneBanReason.  In their complaint, the groups "
            "cited an incident involving a child that $childMisbehavior "
            "as key evidence of the dark nature of the book.&r"
            "   When the decision to ban the book was announced yesterday, "
            "many area children spontaneously broke into tears.  One child "
            "was heard saying, \"$sadChildQuote\"&r";

      case View.justices:
        FullName judge = generateFullName(Gender.whiteMalePatriarch);
        FullName prostitute = generateFullName();
        String judgeDid = [
          "defied the federal government by putting a Ten Commandments monument in the local federal building",
          "stated that, \"Segregation wasn't the bad idea everybody makes it out to be these days\"",
        ].random;
        String whatPoliceSaw = [
          "the most perverse and spine-tingling debauchery imaginable, at least with only two people",
          "the judge going to the bathroom in the vicinity of the prostitute",
          "the prostitute hollering like a cowboy astride the judge",
        ].random;
        String whatTheProstituteOffered = [
          "the arresting officers money",
          "to let the officers join in",
          "the arresting officers \"favors\"",
        ].random;

        story = "${randomCityName()} - Conservative federal judge "
            "${judge.firstLast} has resigned in disgrace after being caught with a "
            "${noProfanity ? "[civil servant]" : "prostitute"}.&r"
            "  ${judge.last}, who once $judgeDid, was found with ${prostitute.firstLast} "
            "last week in a hotel during a police sting operation.  "
            "According to sources familiar with the particulars, "
            "when police broke into the hotel room they saw $whatPoliceSaw.  "
            "${judge.last} reportedly offered $whatTheProstituteOffered "
            "in exchange for their silence.&r"
            "  ${judge.last} could not be reached for comment, although an "
            "aide stated that the judge would be going on a Bible retreat "
            "for a few weeks to \"Make things right with the Almighty "
            "Father.\"&r";

      case View.amRadio:
        FullName radioHost = generateFullName(Gender.whiteMalePatriarch);
        String showName = "${[
          "Straight", "Real", "True", //
        ].random} ${[
          "Talk", "Chat", "Discussion", //
        ].random}";
        String wildQuote = [
          "and the Grays are going to take over the planet in the End Times",
          "summoning a liberal chupacabra to suck our blood from us like a goat",
          "I feel translucent rods passing through my body...  it's like making love to the future",
          "and it's all a conspiracy against me, they're trying to trans my gender",
          "we're talking about a centipede species with liberal membranes between its legs",
          "everyone who has died in the last ten years is a paid actor",
          "under my skin is a layer of nanobots that the government uses to control my thoughts",
          "they're using space lasers to beam gay thoughts into our brains",
        ].random;
        FullName fan = generateFullName();
        String fanNameForHost = [
          "my old hero", "my old idol", "the legend", //
        ].random;
        String fanSwear = switch (laws[Law.freeSpeech]) {
          DeepAlignment.archConservative => "[gosh darn]",
          DeepAlignment.eliteLiberal => "goddamn",
          _ => "g*dd*mn",
        };
        String lostHisMind = [
          "lost his $fanSwear mind",
          "maybe gone a little off the deep end",
          "listened to a little too much Art Bell back in the day",
        ].random;

        story = "${randomCityName()} - Well-known AM radio personality "
            "${radioHost.firstLast} went off for fifteen minutes in an "
            "inexplicable rant two nights ago during the syndicated radio "
            "program \"$showName\".&r"
            "  ${radioHost.last}'s monologue for the evening began the way "
            "that fans had come to expect, with attacks on the \"liberal "
            "media establishment\" and the \"elite liberal agenda\".  But "
            "when the radio icon said, \"$wildQuote\", a former fan of "
            "the show, ${fan.firstLast}, knew that \"$fanNameForHost "
            "had $lostHisMind. And after that, it just got worse and "
            "worse.\"&r"
            "  ${radioHost.last} issued an apology later in the program, but "
            "the damage might already be done.  According to a poll completed "
            "yesterday, fully half of the host's most loyal supporters have "
            "decided to leave the program for saner pastures.  Of these, "
            "many said that they would be switching over to the FM band.&r";

      case View.gunControl:
        FullName shooter = generateFullName(Gender.whiteMalePatriarch);
        int schoolType = lcsRandom(4);
        String school = [
          "elementary school",
          "middle school",
          "high school",
          "university",
        ][schoolType];
        String shooterAge = "${lcsRandom(6) + 6 + schoolType * 4}";
        String beforePolice = noProfanity
            ? "[hurt some people]"
            : "killed ${2 + lcsRandom(30)} and wounded dozens more";
        String unalived =
            noProfanity ? "[fell deeply asleep]" : "committed suicide";

        story = "${randomCityName()} - A student has gone on a "
            "${noProfanity ? "[hurting spree]" : "shooting rampage"} at a local "
            "$school.  ${shooter.firstLast}, $shooterAge, used a variety of "
            "guns to ${noProfanity ? "[scare]" : "mow down"} more than a dozen "
            "classmates and two teachers at ${lastName()} $school.  "
            "${shooter.firstLast} entered the $school while classes were in "
            "session, then systematically started breaking into classrooms, "
            "${noProfanity ? "[scaring]" : "spraying bullets at"} students and "
            "teachers inside.  When other students tried to wrestle the "
            "weapons away from ${shooter.last}, they were "
            "${noProfanity ? "[unfortunately harmed]" : "shot"} as well.&r"
            "  When the police arrived, the student had already "
            "$beforePolice.  ${shooter.first} $unalived shortly afterwards.&r"
            "  Investigators are currently searching the student's "
            "belongings, and initial reports indicate that the student kept a "
            "journal that showed ${shooter.first} was disturbingly obsessed "
            "with guns and death.&r";

      case View.prisons:
        FullName author = generateFullName();
        String book = "${[
          "Nightmare", "Primal", "American", "Solitary", "The Pain",
          "Orange", //
        ].random} ${[
          "Punk", "Kid", "Cell", "Shank", "Lockdown", "Inside", //
        ].random}";
        story = "${randomCityName()}"
            " - A former prisoner has written a book describing in horrifying "
            "detail what goes on behind bars.  "
            "Although popular culture has used, or perhaps overused, the "
            "prison theme lately in its offerings for mass consumption, rarely "
            "have these works been as poignant as ${author.firstLast}'s new "
            "tour-de-force, $book.&r"
            "   Take this excerpt, \""
            "The steel bars grated forward in their rails, "
            "coming to a halt with a deafening clang that said it all —— "
            "I was trapped with them now.  There were three, looking me over "
            "with dark glares of bare lust, as football players might stare "
            "at a stupefied, drunken, helpless teenager.  "
            "My shank's under the mattress.  Better to be brave and fight or "
            "chicken out and let them take it?  "
            "Maybe lose an eye the one way, maybe catch AIDS the other.  A "
            "${noProfanity ? "[difficult]" : "helluva"} choice, and I would "
            "only have a few seconds before they made it for me.\"&r";
      default:
        story =
            "This is a placeholder positive story for $view.  This is a bug.&r";
    }
  } else {
    switch (view) {
      case View.deathPenalty:
        FullName serialKiller = generateFullName(Gender.whiteMalePatriarch);
        String heWasFoundInPosessionOf = [
          "pieces of another victim",
          "bloody toys",
          "a child's clothing stained with DNA evidence",
          "seven junior high school yearbooks",
          "two small backpacks",
        ].random;
        String conditionOfVictims = [
          "carved with satanic symbols",
          "sexually mutilated",
          "missing all of their teeth",
          "missing all of their fingers",
          "without eyes",
        ].random;
        String victimsFound = noProfanity
            ? "[in a better place]"
            : "dead and $conditionOfVictims";
        String theBreakthrough = [
          "a victim called 911 just prior to being slain while still on the phone",
          "the suspect carved an address into one of the bodies",
          "an eye witness spotted the suspect luring a victim into a car",
          "a blood trail was found on a road that led them to the suspect's car trunk",
          "they found a victim in a ditch, still clinging to life",
        ].random;
        String howTheDAReacts =
            laws[Law.deathPenalty] == DeepAlignment.eliteLiberal
                ? "that the death penalty should really be an option"
                : "it will be seeking the death penalty";

        story =
            "${randomCityName()} - Perhaps parents can rest easier tonight.  "
            "The authorities have apprehended their primary suspect in the "
            "String of brutal child killings that has kept everyone in the area on edge, "
            "according to a spokesperson for the police department here.  "
            "$serialKiller was detained yesterday afternoon, reportedly in "
            "possession of $heWasFoundInPosessionOf.  Over twenty children in "
            "the past two years have gone missing, only to turn up later "
            "$victimsFound.  Sources say that the police got a break in the "
            "case when $theBreakthrough.&r"
            "   The district attorney's office has already repeatedly said "
            "$howTheDAReacts in this case.&r";

      case View.animalResearch:
        String country = [
          "Russia", "North Korea", "Cuba", "Iran", "China", //
        ].random;
        String fromCountry = switch (laws[Law.animalRights]) {
          DeepAlignment.eliteLiberal => "from $country",
          _ => "here",
        };
        String drugName = "${[
          if (noProfanity) "Bum" else "Anal", "Colo", "Lacta", "Pur", "Loba", //
        ].random}${[
          "nephrin", "tax", "zac", "thium", "drene", //
        ].random}";
        String drugEffect = [
          "boosts intelligence in chimpanzees",
          if (noProfanity)
            "[helps chimpanzees reproduce]"
          else
            "corrects erectile dysfunction in chimpanzees",
          "allows chimpanzees to move blocks with their minds",
          "allows chimpanzees to fly short distances",
          "increases the attention span of young chimpanzees",
        ].random;
        String responseToEthics = [
          "The ones that survived are all doing very well",
          "They hardly notice when you drill their brains out, if you're fast",
          "When we started muffling the screams of our subjects, the other chimps all calmed down quite a bit",
        ].random;

        story = "${randomCityName()} - Researchers $fromCountry "
            "report that they have discovered an amazing new wonder drug.  "
            "Called $drugName, the drug apparently $drugEffect.  "
            "Fielding questions about the ethics of their experiments from "
            "reporters during a press conference yesterday, a spokesperson for "
            "the research team stated that, \"It really isn't so bad as all "
            "that.  Chimpanzees are very resilient creatures.  "
            "$responseToEthics.  We have a very experienced research team.  "
            "While we understand your concerns, any worries are entirely "
            "unfounded.  I think the media should be focusing on the enormous "
            "benefits of this drug.\"&r"
            "   The first phase of human trials is slated to begin in a few "
            "months.&r";

      case View.intelligence:
        String terrorists = [
          "white supremacists",
          "Islamic fundamentalists",
          "outcast goths from a suburban high school",
        ].random;
        String censoredAttack = [
          "[land] planes [on apartment buildings]",
          "[put] fertilizer [on plants] at a federal building",
          "[show up uninvited to] a warship",
          "[give children owies and boo-boos]",
          "[cause a traffic jam on] a major bridge",
          "[take] the president [on vacation]",
          "[hurt] the president",
          "[vandalize] the Capitol Building",
          "detonate [fireworks] in New York",
        ].random;
        String terroristAttack = [
          "fly planes into skyscrapers",
          "detonate a fertilizer bomb a federal building",
          "ram a motorboat loaded with explosives into a warship",
          "detonate explosives on a school bus",
          "blow out a section of a major bridge",
          "kidnap the president",
          "assassinate the president",
          "destroy the Capitol Building",
          "detonate a nuclear bomb in New York",
        ].random;
        String attackChoice = noProfanity ? censoredAttack : terroristAttack;

        story =
            "Washington, DC - The CIA announced yesterday that it has averted "
            "a terror attack that would have occurred on American soil.&r"
            "   According to a spokesperson for the agency, $terrorists "
            "planned to $attackChoice.  "
            "However, intelligence garnered from deep within the mysterious "
            "terrorist organization allowed the plot to be foiled just days "
            "before it was to occur.&r"
            "   The spokesperson further stated, \""
            "I won't compromise our sources and methods, but let me just say "
            "that we are grateful to the Congress and this Administration for "
            "providing us with the tools we need to neutralize these enemies of "
            "civilization before they can destroy American families.  "
            "However, let me also say that there's more that needs to be done.  "
            "The Head of the Agency will be sending a request to Congress "
            "for what we feel are the essential tools for combating terrorism in "
            "this new age.\"&r";

      case View.genetics:
        String corporation = "${[
          "Altered", "Gene-tech", "DNA", "Proteomic", "Genomic", //
        ].random} ${[
          "Foods", "Agriculture", "Meals", "Farming", "Living" //
        ].random}";
        String product = "${[
          "Mega", "Epic", "Overlord", "Franken", "Transcendent", //
        ].random} ${[
          "Rice", "Beans", "Corn", "Wheat", "Potatoes", //
        ].random}";
        String benefit = [
          "extends human life by a few minutes every bite",
          "mends split-ends upon digestion.  Hair is also made glossier and thicker",
          "allows people to see in complete darkness",
          "causes a person to slowly attain their optimum weight with repeated use",
          "cures the common cold",
        ].random;
        String incident = [
          "guy going on a killing spree",
          "gal turning blue and exploding",
          "guy speaking in tongues and worshiping Satan",
          "gal having a ruptured intestine",
        ].random;
        String hooey = [
          "hooey", "poppycock", "horseradish", "skunk weed", "garbage", //
        ].random;

        story = "${randomCityName()}"
            " - The genetic foods industry staged a major event here yesterday "
            "to showcase its upcoming products.  Over thirty companies set up "
            "booths and gave talks to wide-eyed onlookers."
            "&r"
            "   One such corporation, $corporation, presented their product, "
            "\"$product\", during an afternoon PowerPoint presentation.  "
            "According to the public relations representative speaking, "
            "this amazing new product actually $benefit.&r"
            "   Spokespeople for the GM corporations were universal "
            "in their dismissal of the criticism which often follows "
            "the industry.  One in particular said, \""
            "Look, these products are safe.  That thing about the "
            "$incident is just a load of $hooey.  Would we stake the "
            "reputation of our company on unsafe products?  No.  That's "
            "just ridiculous.  I mean, sure companies have put unsafe "
            "products out, but the GM industry operates at a higher ethical "
            "standard.  That goes without saying.\"&r";

      case View.justices:
        FullName serialKiller = generateFullName();
        Gender judgeGender = forceGenderBinary(Gender.nonbinary);
        FullName judge = generateFullName(judgeGender);
        String judgeReason = [
          "mishearing of a ten-year-old's eyewitness testimony",
          "general feelings about police corruption",
          "belief that the crimes were a vast right-wing conspiracy",
          "belief that ${serialKiller.last} deserved another chance",
          "personal philosophy of liberty",
          "close personal friendship with the ${serialKiller.last} family",
          "consultations with a Magic 8-Ball",
        ].random;

        story = "${randomCityName()}"
            " - The conviction of confessed serial killer $serialKiller "
            "was overturned by a federal judge yesterday.  Judge "
            "${judge.firstLast} of the notoriously liberal court of appeals "
            "here made the decision based on ${judgeGender.hisHer} "
            "$judgeReason, despite the confession of ${serialKiller.last}, "
            "which even Judge ${judge.last} grants was not coerced in any way.&r"
            "  Ten years ago, ${serialKiller.last} was convicted of the "
            "now-infamous ${lastName()} slayings.  After an intensive manhunt, "
            "${serialKiller.last} was found with the murder weapon covered "
            "in the victims' blood.  ${serialKiller.last} confessed and was "
            "sentenced to life, saying \"Thank you for saving me from myself.  "
            "If I were to be released, I would surely kill again.\"&r"
            "   A spokesperson for the district attorney has stated that the "
            "case will not be retried, due to the current economic doldrums "
            "that have left the state completely strapped for cash.&r";

      case View.pollution:
        String thinkTankName = "${[
          "American", "United", "Patriot", "Family", "Children's", "National" //
        ].random} ${[
          "Heritage", "Enterprise", "Freedom", "Liberty", "Charity",
          "Equality" //
        ].random} ${[
          "Partnership", "Institute", "Consortium", "Forum", "Center",
          "Association" //
        ].random}";
        String absurdBehavior = [
          "a modest intake of radioactive waste",
          "a healthy dose of radiation",
          "a bath in raw sewage",
          "watching animals die in oil slicks",
          "inhaling carbon monoxide",
          "drinking a cup of fracking fluid a day",
        ].random;
        String pollutionBenefit = [
          "purify the soul",
          "increase test scores",
          "increase a child's attention span",
          "make children behave better",
          "make shy children fit in",
          "cure everything from abdominal ailments to zygomycosis",
        ].random;
        String scienceIsAnArtReally = [
          "Research is complicated, and there are always two ways to think about things",
          "The jury is still out on pollution.  You really have to keep an open mind",
          "They've got their scientists, and we have ours.  The issue of pollution is wide open as it stands today",
          "I just tried it myself and I feel like a million bucks!  *Coughs up blood*  I'm OK, that's just ketchup",
        ].random;
        String theLiberals = [
          "the elitist liberal media",
          "the vast left-wing education machine",
          "the fruits, nuts, and flakes of the environmentalist left",
          "leftists suffering from the mental disorder chemophobia",
        ].random;

        story = "${randomCityName()}"
            " - Pollution might not be so bad after all.  The $thinkTankName "
            "recently released a wide-ranging report detailing recent trends "
            "and the latest science on the issue.  "
            "Among the most startling of the think tank's findings is that "
            "$absurdBehavior might actually $pollutionBenefit.&r"
            "   When questioned about the science behind these results, "
            "a spokesperson stated that, \"$scienceIsAnArtReally.  You have to "
            "realize that $theLiberals often distort these issues to their own "
            "advantage.  All we've done is introduced a little clarity into "
            "the ongoing debate.  Why is there contention on the pollution "
            "question?  It's because there's work left to be done.  We should "
            "study much more before we urge any action.  Society really just "
            "needs to take a breather on this one.  We don't see why there's "
            "such a rush to judgment here.\"&r";

      case View.corporateCulture:
        String techGiantName = "${[
          "Ameri", "Gen", "Oro", "Amelia", "Vivo", "Benji", "Amal", "Ply",
          "Seli", "Rio" //
        ].random}${[
          "tech", "com", "zap", "cor", "dyne", "bless", "chip", "co", "wire",
          "rex" //
        ].random}";

        story = "${randomCityName()}"
            " - Several major companies have announced at a joint news "
            "conference here that they will be expanding their work forces "
            "considerably during the next quarter.  Over thirty thousand jobs "
            "are expected in the first month, with tech giant $techGiantName "
            "increasing its payrolls by over ten thousand workers alone.  "
            "Given the state of the economy recently and in light of the "
            "tendency of large corporations to export jobs overseas these "
            "days, this welcome news is bound to be a pleasant surprise to "
            "those in the unemployment lines.  The markets reportedly "
            "responded to the announcement with mild interest, although the "
            "dampened movement might be expected due to the uncertain futures "
            "of some of the companies in the tech sector.  On the whole, "
            "however, analysts suggest that not only does the expansion "
            "speak to the health of the tech industry but is also indicative "
            "of a full economic recovery.&r";

      case View.amRadio:
        FullName shockJock = generateFullName(Gender.male);
        String showName = "${[
          "Morning", "Commuter", "Jam", "Talk", "Radio", //
        ].random} ${[
          "Swamp", "Jolt", "Club", "Show", "Fandango", //
        ].random}";
        String shockingBehavior = switch (laws[Law.freeSpeech]) {
          DeepAlignment.eliteLiberal => [
              "fucked",
              "encouraged listeners to call in and take a piss",
              "screamed \"Fuck the police those goddamn motherfuckers.  I got a fucking ticket this morning and I'm fucking pissed as shit.\"",
              "breastfed from a lactating woman",
              "jerked off",
            ].random,
          DeepAlignment.archConservative => [
              "[laid down in a bed with a woman]",
              "encouraged listeners to call in and [visit the restroom]",
              "screamed \"[Darn] the police those [big dumb jerks].  I got a [stupid] ticket this morning and I'm [so angry].\"",
              "[consumed milk] from [a woman]",
              "[caused God to kill a kitten]",
            ].random,
          _ => [
              "had intercourse",
              "encouraged listeners to call in and urinate",
              "screamed \"F*ck the police those g*dd*mn m*th*f*ck*rs.  I got a f*cking ticket this morning and I'm f*cking p*ss*d as sh*t.\"",
              "breastfed from a lactating woman",
              "masturbated",
            ].random,
        };

        story = "${randomCityName()}"
            " - Infamous FM radio shock jock ${shockJock.firstLast} has "
            "brought radio entertainment to a new low.  During yesterday's "
            "broadcast of the program \"${shockJock.first}'s $showName\", "
            "${shockJock.firstLast} reportedly $shockingBehavior on the air.  "
            "Although ${shockJock.firstLast} later apologized, the FCC "
            "received several hundred complaints from irate listeners from "
            "all over the state.  A spokesperson for the FCC stated that the "
            "incident is under investigation.&r";

      case View.gunControl:
        Gender shooterGender = Gender.male;
        FullName shooter = generateFullName(shooterGender);
        Gender heroGender = forceGenderBinary(Gender.nonbinary);
        FullName hero = generateFullName(heroGender);
        String venue = "${lastName()} ${[
          "Mall", "Theater", "High School", "University", //
        ].random}";
        String massShooting = noProfanity ? "[hurting spree]" : "mass shooting";
        String heroAction = noProfanity
            ? "[putting the attacker to sleep]"
            : "killing the attacker";
        String heroTitle = switch (heroGender) {
          Gender.female => "Ms. ",
          Gender.male => "Mr. ",
          _ => "",
        };

        story = "${randomCityName()}"
            " - In a surprising turn, a $massShooting was prevented "
            "by a bystander with a gun.  After ${shooter.firstLast} opened "
            "fire at $venue, ${hero.firstLast} sprung into action.  "
            "The citizen pulled a concealed handgun and fired once at the "
            "shooter, forcing ${shooter.last} to take cover while others "
            "called the police.&r"
            "  Initially, $heroTitle${hero.last} attempted to talk down the "
            "shooter, but as ${shooter.last} became more agitated, the heroic "
            "citizen was forced to engage the shooter in a firefight, "
            "$heroAction before ${shooterGender.heShe} could hurt anyone "
            "else.&r"
            "  The spokesperson for the police department said, \"We'd have "
            "yet another $massShooting if not for $heroTitle${hero.last}'s "
            "heroic actions.\"&r";

      case View.prisons:
        Gender perpGender = forceGenderBinary(Gender.maleBias);
        FullName perp = generateFullName(perpGender);
        Gender guardGender = forceGenderBinary(Gender.maleBias);
        FullName guard = generateFullName(guardGender);
        String rapist = noProfanity ? "[reproduction fiend]" : "rapist";
        String prisonName = lastName();
        String imKillingThisPig = [
          switch (laws[Law.freeSpeech]) {
            DeepAlignment.eliteLiberal =>
              "Ah, fuck this shit.  This punk bitch is fuckin' dead!",
            DeepAlignment.archConservative =>
              "Ah, [I am unhappy].  This [police officer will be harmed]!",
            _ => "Ah, f*ck this sh*t.  This punk b*tch is f*ckin' dead!",
          },
          switch (laws[Law.freeSpeech]) {
            DeepAlignment.eliteLiberal =>
              "Fuck a muthafuckin' bull.  I'm killin' this pig shit.",
            DeepAlignment.archConservative =>
              "[I am attracted to cattle].  [I am harming a police officer].",
            _ => "F*ck a m*th*f*ck*n' bull.  I'm killin' this pig sh*t.",
          },
          switch (laws[Law.freeSpeech]) {
            DeepAlignment.eliteLiberal =>
              "Why the fuck am I talkin' to you?  I'd rather kill this pig.",
            DeepAlignment.archConservative =>
              "Why [are we speaking]?  I'd rather [harm this police officer].",
            _ => "Why the f*ck am I talkin' to you?  I'd rather kill this pig.",
          },
          switch (laws[Law.freeSpeech]) {
            DeepAlignment.eliteLiberal =>
              "Imma kill all you bitches, startin' with this muthafucker here.",
            DeepAlignment.archConservative =>
              "[I will harm every police officer], startin' with this [one] here.",
            _ =>
              "Imma kill all you b*tches, startin' with this m*th*f*ck*r here.",
          },
        ].random;
        String killedTheGuard = switch (laws[Law.freeSpeech]) {
          DeepAlignment.archConservative => "[harmed] the guard",
          DeepAlignment.conservative => "killed the guard",
          _ => [
              "slit the guard's throat with a shank",
              "strangled the guard to death with a knotted bed sheet",
              "chewed out the guard's throat",
              "smashed the guard's skull with the toilet seat from "
                  "${perpGender.hisHer} cell",
              "shot the guard with ${guardGender.hisHer} own gun",
              "poisoned the guard with drugs smuggled into the prison by "
                  "the ${["Crips", "Bloods"].random}",
              "hit all 36 pressure points of death on the guard",
              "electrocuted the guard with high-voltage wires",
              "thrown the guard out the top-story window",
              "taken the guard to the execution chamber and finished "
                  "${guardGender.himHer} off",
              "tricked another guard into shooting the guard dead",
              "burnt the guard to a crisp using a lighter and some gasoline",
              "eaten the guard's liver with some fava beans and a nice chianti",
              "performed deadly experiments on the guard unheard of since "
                  "Dr. Mengele",
              "sacrificed the guard on a makeshift "
                  "${["satanic", "neo-pagan"].random} altar",
            ].random,
        };
        String beatenToDeath =
            noProfanity ? "[also harmed]" : "beaten to death";

        story = "${randomCityName()}"
            " - The hostage crisis at the $prisonName Correctional Facility "
            "ended tragically yesterday with the death of both the prison "
            "guard being held hostage and ${guardGender.hisHer} captor.&r"
            "   Two weeks ago, convicted $rapist ${perp.firstLast}, an inmate "
            "at $prisonName, overpowered ${guard.firstLast} and barricaded "
            "${perpGender.himselfHerself} with the guard in a prison tower.  "
            "Authorities locked down the prison and attempted to negotiate by "
            "phone for ${lcsRandom(18) + 5} days, but talks were cut short when "
            "${perp.firstLast} reportedly screamed into the receiver, \""
            "$imKillingThisPig\"  The tower was breached in an attempt to "
            "reach the hostage, but ${perp.last} had already $killedTheGuard.  "
            "The prisoner was $beatenToDeath while \"resisting capture\", "
            "according to a prison spokesperson.&r";
      default:
        story =
            "This is a placeholder negative story for $view.  This is a bug.&r";
    }
  }
  story += generateFiller(200);

  return story;
}
