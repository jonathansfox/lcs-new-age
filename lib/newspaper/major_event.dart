import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/newspaper/display_news.dart';
import 'package:lcs_new_age/newspaper/filler.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

class MajorEventContent {
  const MajorEventContent({
    required this.headline,
    this.subheadline,
    this.pictureId,
    this.storyText,
    this.remapSkinTones = false,
  });

  final String headline;
  final String? subheadline;
  final int? pictureId;
  final String? storyText;
  final bool remapSkinTones;

  bool get useBigFont => pictureId != null;
}

NewsStory randomMajorEventStory() {
  NewsStory ns = NewsStory.unpublished(NewsStories.majorEvent);
  while (true) {
    ns.view = View.issues.random;
    ns.liberalSpin = oneIn(2) ? true : false;

    // News stories that don't apply when the law is extreme -- covering
    // nuclear power when it's banned, police corruption when it doesn't
    // exist, out of control pollution when it's under control, etc.
    if (ns.liberalSpin) {
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
  MajorEventContent content =
      generateMajorEventContent(ns.view!, ns.liberalSpin, ns);
  displayCenteredNewsFont(content.headline, 5, ns,
      useBigFont: content.useBigFont);
  setColor(black, background: ns.publication.backgroundColor);

  if (content.pictureId != null) {
    if (content.subheadline != null) {
      mvaddstrCenter(12, content.subheadline!);
      ns.body = content.subheadline!;
    }
    displayNewsPicture(content.pictureId!, 13, ns, content.remapSkinTones);
  } else if (content.storyText != null) {
    int startLine = 11;
    if (content.subheadline != null) {
      displayCenteredNewsFont(content.subheadline!, 11, ns);
      startLine = 17;
    }
    displayNewsStory(content.storyText! + generateFiller(200), storyXStart,
        storyXEnd, startLine, ns);
  }
}

MajorEventContent generateMajorEventContent(
    View view, bool liberalSpin, NewsStory ns) {
  if (liberalSpin) {
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
        if (ns.publicationAlignment == DeepAlignment.eliteLiberal) {
          abortions = "abortions";
        }
        return MajorEventContent(
          headline: "CLINIC MURDER",
          storyText: "${randomCityName()} - A doctor that routinely performed "
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
              "two children.&r",
        );
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
        String authorities = "Authorities";
        if (ns.publicationAlignment == DeepAlignment.eliteLiberal) {
          despiteTheBan = "";
          victimLabel = "trans woman";
          authorities = "In a rare case of justice, authorities";
        }

        return MajorEventContent(
          headline: "CRIME OF HATE",
          storyText: "${randomCityName()} - $victimFullName, a "
              "$victimLabel, was $murdered here yesterday.  "
              "A police spokesperson reported that "
              "four suspects were apprehended after a high speed chase.  Their "
              "names have not yet been released.&r"
              "  Witnesses of the freeway chase described the pickup of the "
              "alleged murderers swerving wildly, $actionTowardPolice at the "
              "pursuing police cruisers.  The chase ended when "
              "the suspects $chaseEnd, at which point they were taken into "
              "custody.  Nobody was seriously injured during the pursuit.&r"
              "  $authorities have stated that they will vigorously prosecute "
              "this case as a hate crime, due to the aggravated nature of the "
              "offense$despiteTheBan.&r",
        );
      case View.deathPenalty:
        FullName victim = generateFullName(Gender.male);
        String timeOfDeath =
            "${lcsRandom(12) + 1}:${lcsRandom(6)}${lcsRandom(10)} ${oneIn(2) ? "AM" : "PM"}";
        int yearConvicted = year - lcsRandom(11) - 10;
        String byExecutionMethod = switch (laws[Law.deathPenalty]) {
          DeepAlignment.archConservative => [
              "on the cross",
              "in a fire ant nest",
              "in a sewage digester vat",
              "in the guillotine",
            ].random,
          DeepAlignment.conservative => [
              "in the gallows",
              "in the electric chair",
            ].random,
          _ => "by lethal injection",
        };
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

        return MajorEventContent(
          headline: "JUSTICE DEAD",
          storyText: "${randomStateName()} - An innocent citizen has been put "
              "to death $byExecutionMethod.  "
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
              "can be put to death in this country.&r",
        );
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
        String beforePolice =
            noProfanity && ns.publicationAlignment != DeepAlignment.eliteLiberal
                ? "[hurt some people]"
                : "killed ${2 + lcsRandom(30)} and wounded dozens more";
        String unalived =
            noProfanity && ns.publicationAlignment != DeepAlignment.eliteLiberal
                ? "[decided to stop]"
                : "committed suicide";
        String shootingRampage =
            noProfanity && ns.publicationAlignment != DeepAlignment.eliteLiberal
                ? "[hurting spree]"
                : "shooting rampage";
        String mowDown =
            noProfanity && ns.publicationAlignment != DeepAlignment.eliteLiberal
                ? "[scare]"
                : "mow down";
        String sprayingBulletsAt =
            noProfanity && ns.publicationAlignment != DeepAlignment.eliteLiberal
                ? "[scaring]"
                : "spraying bullets at";
        String shot =
            noProfanity && ns.publicationAlignment != DeepAlignment.eliteLiberal
                ? "[scared]"
                : "shot";
        String finallyArrived =
            ns.publicationAlignment == DeepAlignment.eliteLiberal
                ? "finally arrived after forty minutes of loitering around "
                    "uselessly outside the school"
                : "arrived";
        String policeWereUseless =
            ns.publicationAlignment == DeepAlignment.eliteLiberal
                ? "  The police did not enter the building at any point while "
                    "the shooting was ongoing."
                : "";
        String journalFinding =
            ns.publicationAlignment == DeepAlignment.eliteLiberal
                ? "surprised at how easy it was to get his hands on the guns"
                : "disturbingly obsessed with guns and death";

        return MajorEventContent(
          headline: "MASS SHOOTING",
          storyText: "${randomCityName()} - A student has gone on a "
              "$shootingRampage at a local $school.  ${shooter.firstLast}, "
              "$shooterAge, used a variety of "
              "guns to $mowDown more than a dozen "
              "classmates and two teachers at ${lastName()} $school.  "
              "${shooter.firstLast} entered the $school while classes were in "
              "session, then systematically started breaking into classrooms, "
              "$sprayingBulletsAt students and "
              "teachers inside.  When other students tried to wrestle the "
              "weapons away from ${shooter.last}, they were "
              "$shot as well.&r"
              "  When the police $finallyArrived, the student had already "
              "$beforePolice.  ${shooter.first} $unalived shortly afterwards."
              "$policeWereUseless&r"
              "  Investigators are currently searching the student's "
              "belongings, and initial reports indicate that the student kept a "
              "journal that showed ${shooter.first} was $journalFinding.&r",
        );
      case View.taxes:
        return MajorEventContent(
          headline: "REAGAN FLAWED",
          pictureId: pictureReaganBook,
          subheadline: "${[
            "Dark",
            "Shadow",
            "Abyssal",
            "Orwellian",
            "Craggy"
          ].random} ${[
            "Actor",
            "Lord",
            "Emperor",
            "Puppet",
            "Dementia"
          ].random}: A new book further documenting the other side of Reagan.",
        );
      case View.nuclearPower:
        return const MajorEventContent(
          headline: "MELTDOWN",
          pictureId: pictureNuclearMeltdown,
          subheadline: "A nuclear power plant suffers a catastrophic meltdown.",
        );
      case View.animalResearch:
        return const MajorEventContent(
          headline: "HELL ON EARTH",
          pictureId: pictureMutantBeast,
          subheadline:
              "A mutant animal has escaped from a lab and killed thirty people.",
        );
      case View.prisons:
        FullName author = generateFullName();
        String book = "${[
          "Nightmare", "Primal", "American", "Solitary", "The Pain",
          "Orange", //
        ].random} ${[
          "Punk", "Kid", "Cell", "Shank", "Lockdown", "Inside", //
        ].random}";
        return MajorEventContent(
          headline: "ON THE INSIDE",
          storyText: "${randomCityName()}"
              " - A former prisoner has written a book describing in horrifying "
              "detail what goes on behind bars.  "
              "Although popular culture has used, or perhaps overused, the "
              "prison theme lately in its offerings for mass consumption, rarely "
              "have these works been as poignant as ${author.firstLast}'s new "
              "tour-de-force, $book.&r"
              "  Take this excerpt, \""
              "Boots echoed in the corridor——three sets, measured, methodical.  "
              "The guards never rushed. They enjoyed this part.&r"
              "  \"You,\" one "
              "snapped.  The baton swung before the word finished, sharpened by "
              "boredom, aimed with deliberate cruelty.  The force was enough to "
              "fold me in half.&r"
              "  \"The others laughed——short, clipped sounds, "
              "born of habit rather than amusement.  They hauled me up, shoving "
              "me forward, past cells packed with hollow men.  The dim bulbs "
              "hummed overhead, flickering weakly, as if even the light wanted to "
              "leave.  I didn't ask where we were going.  The answer never "
              "mattered.\"&r",
        );
      case View.intelligence:
        String harmlessBehavior = [
          "buying music with 'Explicit Lyrics' labels",
          "helping homeless people",
          "eating at vegan restaurants",
          "drinking soy milk",
          "reading too many books",
        ].random;

        return MajorEventContent(
          headline: "THE FBI FILES",
          storyText: "Washington, DC - The FBI might be keeping tabs on you.  "
              "This newspaper yesterday received a collection of files from "
              "a source in the Federal Bureau of Investigations.  The files "
              "contain information on which people have been attending "
              "demonstrations, organizing unions, working for liberal "
              "organizations——even $harmlessBehavior.&r"
              "  More disturbingly, the files make reference to a plan to "
              "\"deal with the undesirables\", although this phrase is not "
              "clarified.&r"
              "  The FBI refused to comment initially, but when confronted "
              "with the information, a spokesperson stated, \""
              "Well, you know, there's privacy, and then there's privacy.  "
              "It might be a bit presumptive to assume that these files deal "
              "with the one and not the other.  You think about that before "
              "you continue slanging accusations.\"&r",
        );
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
        String ridiculousBanReason = [
          "glorifies Satan worship and was spawned by demons from the pit",
          "teaches children to kill their parents and hate life",
          "causes violence in schools and is a gateway to cocaine use",
          "breeds demonic thoughts that manifest themselves as dreams of murder",
          "contains step-by-step instructions to summon the Prince of Darkness"
        ].random;
        String childMisbehavior = [
          "swore in class",
          "cried because the story was too scary",
          "said a magic spell at her parents",
          "refused to eat her vegetables",
          "threw a tantrum and refused to go to bed on time",
          "${["pushed", "hit", "slapped", "insulted", "tripped"].random} "
              "${["his", "her"].random} ${["older", "younger"].random} "
              "${["brother", "sister"].random}",
        ].random;
        String sadChildQuote = [
          "Mamma, is $protagonist dead?",
          "Mamma, why did they kill $protagonist?"
        ].random;

        return MajorEventContent(
          headline: "BOOK BANNED",
          storyText:
              "${randomCityName()} - A children's story has been removed "
              "from libraries here after the city bowed to pressure from "
              "religious groups.&r"
              "  The book, $bookTitle, is an immensely popular book by "
              "$nationality author $authorName.  Although the title is "
              "adored by children worldwide, some conservatives feel that "
              "the book $ridiculousBanReason.  In their complaint, the groups "
              "cited an incident involving a child that $childMisbehavior "
              "as key evidence of the dark nature of the book.&r"
              "  When the decision to ban the book was announced yesterday, "
              "many area children spontaneously broke into tears.  One child "
              "was heard saying, \"$sadChildQuote\"&r",
        );
      case View.genetics:
        return const MajorEventContent(
          headline: "KILLER FOOD",
          pictureId: pictureGenetics,
          subheadline:
              "Over a hundred people become sick from genetically modified food.",
        );
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
        String prostituteLabel = "prostitute";
        if (noProfanity &&
            ns.publicationAlignment != DeepAlignment.eliteLiberal) {
          prostituteLabel = "[civil servant]";
        }
        String whatTheJudgeOffered = [
          "the arresting officers money",
          "to let the officers join in",
          "the arresting officers \"favors\"",
        ].random;

        return MajorEventContent(
          headline: "IN CONTEMPT",
          storyText: "${randomCityName()} - Conservative federal judge "
              "${judge.firstLast} has resigned in disgrace after being caught with a "
              "$prostituteLabel.&r"
              "  ${judge.last}, who once $judgeDid, was found with ${prostitute.firstLast} "
              "last week in a hotel during a police sting operation.  "
              "According to sources familiar with the particulars, "
              "when police broke into the hotel room they saw $whatPoliceSaw.  "
              "${judge.last} reportedly offered $whatTheJudgeOffered "
              "in exchange for their silence.&r"
              "  ${judge.last} could not be reached for comment, although an "
              "aide stated that the judge would be going on a Bible retreat "
              "for a few weeks to \"Make things right with the Almighty "
              "Father.\"&r",
        );
      case View.sweatshops:
        return const MajorEventContent(
          headline: "CHILD'S PLEA",
          pictureId: pictureTshirtWithPleaForHelp,
          subheadline:
              "A T-shirt in a store is found scrawled with a message from a sweatshop worker.",
        );
      case View.pollution:
        return const MajorEventContent(
          headline: "RIVER ON FIRE",
          pictureId: pictureRiverFire,
          subheadline: "The Cuyahoga River is ablaze as pollution increases.",
        );
      case View.corporateCulture:
        String companyName = generateCompanyName();
        return MajorEventContent(
          headline: "FINANCE FRAUD",
          pictureId: pictureDollarsDisappearing,
          subheadline: "Investors out billions as $companyName collapses.",
        );
      case View.ceoSalary:
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
        return MajorEventContent(
          headline: "AMERICAN CEO",
          pictureId: pictureCEO,
          subheadline: str,
          remapSkinTones: true,
        );
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
        if (ns.publicationAlignment == DeepAlignment.eliteLiberal) {
          fanSwear = "goddamn";
        }
        String lostHisMind = [
          "lost his $fanSwear mind",
          "maybe gone a little off the deep end",
          "listened to a little too much Art Bell back in the day",
        ].random;

        return MajorEventContent(
          headline: "AM IMPLOSION",
          storyText: "${randomCityName()} - Well-known AM radio personality "
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
              "many said that they would be switching over to the FM band.&r",
        );
      case View.immigration:
        const List<String> countries = [
          "Mexico",
          "Guatemala",
          "Honduras",
          "Nicaragua",
          "Cuba",
          "Haiti",
          "Dominican Republic",
          "Colombia",
          "Venezuela"
        ];
        FullName immigrant = generateFullName();
        String immigrantCountry = countries.random;
        String differentCountry = "El Salvador";
        String immigrantJob = [
          "housekeeper",
          "restaurant manager",
          "delivery worker",
          "factory worker",
          "construction worker",
          "janitor",
          "sanitation worker",
          "security guard",
          "high school student",
        ].random;
        String harmlessTattoo = [
          "${immigrant.gender.hisHer} pet cat",
          "${immigrant.gender.hisHer} mother's name",
          "a paw print",
          "a peace sign",
          "a local sports team's mascot",
          "an American flag surrounded by hearts",
          if (lcsInPublicEye) "the letters 'LCS'",
        ].random;

        return MajorEventContent(
            headline: "BROKEN DREAMS",
            storyText: "${randomCityName()} - Masked ICE agents seized "
                "dozens of people off the street in what terrified residents "
                "described as a series of kidnappings yesterday.  The "
                "targets were immediately forced onto a plane and sent to a "
                "prison in $differentCountry, where most of them have never "
                "been and are being held without trial or any legal "
                "representation.&r"
                "  An ICE spokesperson said that everyone arrested was \"The "
                "worst of the worst.\"  As an example, they cited "
                "${immigrant.firstLast}, a $immigrantJob from "
                "$immigrantCountry, and showed photos of ${immigrant.gender.hisHer} "
                "tattoo of $harmlessTattoo as proof of gang affiliation.  "
                "Despite these claims, most of those deported, including "
                "${immigrant.last}, have no known criminal record.&r"
                "  \"This should never have happened,\" said "
                "Mayor ${lastName()}.  \"These people are valued members of our "
                "community who came to this country to work hard and provide "
                "for their families.  They don't deserve to be treated this "
                "way and I wasn't elected to let our communities by terrorized "
                "by a gang of roving kidnappers.\"&r"
                "  The mayor has directed local police to immediately stop "
                "cooperating with ICE.&r");
      case View.civilRights:
        String companyName = generateCompanyName();
        FullName incitingIncidentEmployee = generateFullName();
        String incitingIncident = [
          "was fired for complaining about racist comments made by a white employee.",
          "was bluntly informed that ${incitingIncidentEmployee.gender.heShe} "
              "would never be promoted because ${incitingIncidentEmployee.gender.heShe} "
              "is black.",
          "was denied a raise because ${incitingIncidentEmployee.gender.heShe} "
              "was deemed to be \"not the kind of person we want around here.\"",
        ].random;
        return MajorEventContent(
            headline: "BOYCOTT WINS",
            storyText:
                "${randomCityName()} - $companyName has announced a major "
                "overhaul of its policies after a recent boycott campaign.  "
                "Civil rights groups had been protesting the company's "
                "lobbying efforts in support of discriminatory policies, "
                "and called out a number of specific examples of "
                "discrimination, but the boycott was sparked when "
                "${incitingIncidentEmployee.firstLast} "
                "$incitingIncident  The boycott quickly spread "
                "through social media, causing sales to plummet and stock "
                "prices to crash.&r"
                "  In a statement released yesterday, $companyName apologized "
                "for its past actions and said that it would be \"taking a long, "
                "hard look at its policies\" and would be \"implementing a "
                "series of changes to ensure that $companyName is a more "
                "inclusive and welcoming place for all employees, customers, "
                "and suppliers, including and especially black employees "
                "that have been the subject of unequal treatment in the "
                "past.\"&r"
                "  $companyName has also promised to donate \$10,000,000 "
                "to various civil rights groups, and to settle a lawsuit that "
                "had been filed against it by ${incitingIncidentEmployee.firstLast}.&r");
      case View.drugs:
        String drug = [
          "marijuana",
          "psilocybin",
          "MDMA",
          "LSD",
        ].random;
        String benefit = [
          "improved ability to process trauma and grief",
          "increased empathy",
          "better social connections",
          "reduced stress and anxiety",
          "deeper self-awareness",
        ].random;
        String someEvenHadThisOutcome = [
          "discovered the meaning of life",
          "learned to communicate with plants",
          "were better people overall",
          "invented new colors",
          "achieved perfect inner peace",
          "unlocked the secrets of the universe",
          "stopped being mad about the state of the country",
        ].random;
        String thingYouCanDoWithTaxes = [
          "funding schools",
          "building parks",
          "fixing roads",
          "expanding healthcare",
          "supporting the arts",
          "protecting the environment",
          "helping the homeless",
        ].random;
        FullName enthusiast = generateFullName();
        String enthusiastQuote = [
          "The only thing we have to fear is fear itself... and maybe the DEA,",
          "I've never been more productive in my life, except for that one time I tried to organize my sock drawer by color,",
          "The government should be more concerned about people who don't do drugs.  I think there might be something wrong with them,",
          "If everyone did a little more $drug, we'd have world peace by next Tuesday,",
          "I used to think the world was flat, but then I tried $drug and realized it's actually a tesseract,",
          "The only bad trip I've ever had was when I went to Mexico and drank the water,",
          "I'm not saying $drug is the answer to all our problems, but it's definitely the answer to most of them,",
        ].random;
        String enthusiastActivity = [
          "carefully arranging a collection of crystals in a perfect Fibonacci spiral",
          "delicately stacking individual grains of rice into a perfect pyramid",
          "slowly petting a cat and whispering detailed complements about its fur texture",
          "using a ruler to ensure every piece of popcorn was evenly spaced in a bowl",
          "precisely measuring the distance between bites of ${enthusiast.gender.hisHer} sandwich",
        ].random;
        String legalizing = switch (politics.laws[Law.drugs]!) {
          DeepAlignment.archConservative ||
          DeepAlignment.conservative =>
            "decriminalizing",
          DeepAlignment.moderate || DeepAlignment.liberal => "legalizing",
          DeepAlignment.eliteLiberal => "subsidizing",
        };

        return MajorEventContent(
            headline: "DRUG STUDY",
            storyText:
                "${randomCityName()} - A new study has found that $legalizing "
                "$drug could be the key to solving our economic woes.  "
                "Researchers at ${lastName()} University discovered that "
                "regular $drug use leads to $benefit, with some participants "
                "even reporting that they $someEvenHadThisOutcome.&r"
                "  \"The tax revenue alone could be used for "
                "$thingYouCanDoWithTaxes,\" said Dr. ${lastName()}, lead "
                "researcher on the study.  \"Plus, think of all the money we'd "
                "save on law enforcement and prisons.  It's a win-win "
                "situation.\"&r"
                "  Local drug enthusiast ${enthusiast.firstLast} agrees.  "
                "\"$enthusiastQuote\" ${enthusiast.last} said, while "
                "$enthusiastActivity.&r");
      case View.military:
        CountryName country = generateCountryName();
        String countryLong = country.name;
        String countryShort = country.shortName;
        String city = country.capital;
        String supposedMission = [
          "protecting our democracy",
          "stopping the spread of communism",
          "protecting us from that warlord ${lastName()}",
          "promoting peace and stability",
        ].random;
        List<String> actualActivities = [
          "giving guns to people with no training who end up killing our own people",
          "raining drone strikes down on our families and children",
          "giving cash aid that goes directly to the pockets of corrupt officials",
          "protecting your corporate interests while they violate our local labor laws",
          "torturing prisoners who you just end up releasing without charges",
          "intercepting shipments of food and medical supplies we desperately need",
          "bombing our electricity and water infrastructure",
          "providing weapons to militias so they can pursue ethnic cleansing and make the violence even worse",
        ];
        String actualMission =
            "${actualActivities.randomPop()}, ${actualActivities.randomPop()}, ${actualActivities.randomPop()}, and ${actualActivities.randomPop()}";
        String incident = [
          "bombed a wedding party, killing more than 30 people",
          "accidentally started selling weapons directly to the enemy",
          "somehow managed to shoot every one of the hostages and none of the "
              "captors during a hostage rescue mission",
          "bombed a local hospital used exclusively by civilians",
          "shot down a civilian airliner, killing everyone on board",
        ].random;

        return MajorEventContent(
            headline: "END THE WAR",
            storyText:
                "$city, $countryShort - More than 100,000 locals marched through "
                "the capital demanding that the United States end its military "
                "intervention into the $countryLong.&r"
                "  \"Go home, Americans!\" one speaker demanded.  \"You have "
                "been nothing but trouble here!  You think you are "
                "$supposedMission, but all you are doing is $actualMission!  "
                "Please, just go!\"&r"
                "  While the intervention into $countryShort has been "
                "controversial since the beginning, public opinion in the "
                "country has sharply turned against the United States ever "
                "since American forces $incident.&r");

      case View.policeBehavior:
        switch (lcsRandom(5)) {
          case 0:
            // Police officer shoots another police officer in a road rage
            // incident
            FullName officer1 = generateFullName(Gender.whiteMalePatriarch);
            FullName officer2 = generateFullName(Gender.whiteMalePatriarch);
            return MajorEventContent(
              headline: "COP KILLS COP",
              storyText: "${randomCityName()} - Undercover police officer "
                  "${officer1.firstLast} has shot and killed an off-duty "
                  "officer, ${officer2.firstLast}, in a case of apparent road "
                  "rage.  ${officer1.last} told reporters that ${officer2.last} "
                  "ran a red light then forced him off the road before drawing "
                  "a gun and threatening to kill ${officer1.last} and his "
                  "family.&r"
                  "  Investigators are still trying to determine what "
                  "happened, but both ${officer1.last} and ${officer2.last} "
                  "had been the subject of numerous complaints in the past "
                  "about threats of violence made to people outside the "
                  "police department, and the incident has raised questions "
                  "about the temperament of the police force and the safety of "
                  "the public.&r"
                  "  ${officer1.last} has been placed on paid leave.&r",
            );
          case 1:
            // Police officers rob a bank
            FullName officer1 = generateFullName(Gender.whiteMalePatriarch);
            FullName officer2 = generateFullName(Gender.whiteMalePatriarch);
            return MajorEventContent(
              headline: "COPS ROB BANK",
              storyText: "${randomCityName()} - Two police officers, "
                  "${officer1.firstLast} and ${officer2.firstLast}, are "
                  "suspected of robbing the First American Bank and making off "
                  "with more than \$500,000.  The officers were caught on "
                  "camera wearing ski masks and carrying guns, but performed "
                  "the robbery in uniforms with their nametags visible and "
                  "escaped the scene in their marked police vehicle.&r"
                  "  After they returned to the police station, other officers "
                  "searched their vehicle and found the money.  The two "
                  "officers have insisted that while they were the ones to "
                  "take the money, they were actually acting in self-defense "
                  "after the money attacked them and they were forced to "
                  "defend themselves.&r"
                  "  Both officers have been placed on paid leave.&r",
            );
          case 2:
            // Police officer beats a suspect brutally for no damn reason
            FullName officer = generateFullName(Gender.whiteMalePatriarch);
            FullName suspect = generateFullName();
            String condition = [
              "${suspect.gender.hisHer} face was completely caved in",
              "${suspect.gender.hisHer} ribs were sticking out of ${suspect.gender.hisHer} chest",
              "${suspect.gender.hisHer} arm was broken in multiple places",
              "${suspect.gender.heShe} was paralyzed from the neck down",
              "${suspect.gender.hisHer} lost all of ${suspect.gender.hisHer} teeth",
              "${suspect.gender.hisHer} was vomiting blood",
              "${suspect.gender.hisHer} all four of ${suspect.gender.hisHer} limbs were broken",
            ].random;
            return MajorEventContent(
              headline: "COP BEATING",
              storyText: "${randomCityName()} - Police officer "
                  "${officer.firstLast} is under investigation for beating "
                  "a suspect, ${suspect.firstLast}, until $condition.  The "
                  "suspect was handcuffed and in police custody when the "
                  "attack took place.&r"
                  "  ${officer.last} insisted to investigators that the "
                  "suspect was extremely violent and had to be subdued, even "
                  "though ${suspect.last} had gone to the police station "
                  "${suspect.gender.himselfHerself} earlier in the day to "
                  "surrender, and was reported by other officers to be "
                  "very cooperative and compliant moments prior to being "
                  "isolated with ${officer.last}.&r"
                  "  ${officer.last} has been placed on paid leave.&r",
            );
          case 3:
            // Police officer steals $35,000 in drugs from evidence room
            FullName officer = generateFullName(Gender.whiteMalePatriarch);
            FullName suspect = generateFullName();
            return MajorEventContent(
              headline: "DIRTY COP",
              storyText: "${randomCityName()} - Police officer "
                  "${officer.firstLast} is under investigation for stealing "
                  "\$35,000 worth of drugs from the evidence room.  The drugs "
                  "were stashed in ${officer.gender.hisHer} personal vehicle, "
                  "which was parked outside the police station, and in a bag "
                  "marked \"Evidence.\"&r"
                  "  The drugs had been placed into evidence by ${officer.last} "
                  "earlier in the day after arresting ${suspect.firstLast} for "
                  "possession of a controlled substance, before being replaced "
                  "by a bag of powdered potato chips that ${officer.last} had "
                  "been eating earlier that day.  ${officer.last} "
                  "insisted that the drugs were not his and suggested "
                  "that ${suspect.last} must have planted them there.  "
                  "Investigators noted that ${suspect.last} was supervised in "
                  "the police lockup for the entire duration of the incident, "
                  "and that ${officer.last} had potato chip dust on his "
                  "hands when he was spotted heading out to his car with the "
                  "evidence bag in hand.&r"
                  "  ${officer.last} has been placed on paid leave.&r",
            );
          default:
            // Police officers shoot a suspect and then convict the victim
            // of attacking them
            FullName officer = generateFullName(Gender.whiteMalePatriarch);
            FullName officer2 = generateFullName(Gender.whiteMalePatriarch);
            FullName suspect = generateFullName();
            return MajorEventContent(
              headline: "COPS LIED",
              storyText: "${randomCityName()} - Police officers "
                  "${officer.firstLast} and ${officer2.firstLast} are under "
                  "investigation for shooting ${suspect.firstLast} and then "
                  "providing false testimony that resulted in the victim being "
                  "wrongfully convicted of attempted murder.&r"
                  "  The incident took place after ${officer.last} and "
                  "${officer2.last} were called to a domestic disturbance at "
                  "a neighbor's home.  ${officer.last} and ${officer2.last} "
                  "entered the wrong building and opened fire on "
                  "${suspect.last}, who was hit in the chest six times "
                  "and nearly killed.&r"
                  "  The officers accused ${suspect.last} "
                  "of attacking them with a gun, and the jury convicted "
                  "${suspect.last} of attempted murder and "
                  "sentenced ${suspect.gender.himHer} to life in prison.  "
                  "However, the subsequent leak of previously unreleased "
                  "body camera footage "
                  "revealed that ${suspect.last} was asleep when "
                  "the officers entered the room and shot "
                  "${suspect.gender.himHer}.&r"
                  "  ${officer.last} and ${officer2.last} have been placed "
                  "on paid leave.&r",
            );
        }

      case View.torture:
        switch (lcsRandom(3)) {
          case 0:
            // Domestic black site raid
            return MajorEventContent(
                headline: "BLACK SITE",
                storyText:
                    "${randomCityName()} - Police raided a warehouse where dozens "
                    "of missing Americans were found chained to the walls in small "
                    "cells, most of them starved, tortured, and subjected to other "
                    "forms of abuse.  The warehouse was located in a remote area "
                    "of the county and was reportedly guarded by a mysterious "
                    "security force that abandoned the building shortly before "
                    "the police arrived.&r"
                    "  All of the prisoners were released and taken to a local "
                    "hospital for treatment.  Several of the victims have been "
                    "identified as former political activists, including some "
                    "who went missing years ago.&r"
                    "  The federal government has denied any knowledge or "
                    "involvement in the situation.&r");
          case 1:
            // Domestic law enforcement torture produces dozens of false
            // confessions
            String city = randomCityName();
            FullName suspect = generateFullName();
            FullName supposedVictim = generateFullName();
            return MajorEventContent(
                headline: "PAIN AND LIES",
                storyText:
                    "$city - Local authorities have come under intense scrutiny after "
                    "a suspect, ${suspect.firstLast} confessed to a staggering "
                    "list of crimes under police torture, only for the "
                    "alleged murder victim, ${supposedVictim.firstLast}, to "
                    "turn up alive.  A media investigation by a local "
                    "newspaper revealed similar forced confessions, and in "
                    "the subsequent scandal, several other suspects had their "
                    "convictions overturned on appeal despite supposedly "
                    "confessing to the crimes they were accused of.&r"
                    "  Despite growing public outrage, the police department "
                    "has completely denied wrongdoing.  \"We stand by the "
                    "conviction of ${suspect.firstLast} in this case,\" a "
                    "spokesperson said.  \"If ${suspect.gender.heShe} came "
                    "out of 'The Confession Factory', as we like to call it, "
                    "saying ${suspect.gender.heShe} killed "
                    "${supposedVictim.last}, then that's what happened.  "
                    "Why would anyone admit to a crime they didn't do?  That's "
                    "stupid and you should all be embarrassed.  This fake "
                    "news about ${supposedVictim.last} being alive is the "
                    "real false confession.  The only issue here is public "
                    "perception.\"&r"
                    "  Despite claiming no wrongdoing, the police have placed "
                    "the officers involved on paid leave.&r");
          default:
            // Overseas black site leak reveals torture
            FullName whistleblower = generateFullName();
            List<String> protestSigns = [
              "We Prefer Our Spooks To Be At Least Somewhat Less Evil",
              "Could You Just Not Do That",
              "Just Ask Them Nicely",
              "Torture Doesn't Even Work Anyway",
              "Why Are We Having This Conversation Again",
            ];
            String allProtestSigns =
                "\"${protestSigns.randomPop()}\", \"${protestSigns.randomPop()}\", and \"${protestSigns.randomPop()}\"";
            return MajorEventContent(
                headline: "TORTURED",
                storyText: "Washington, D.C. - Photos leaked from an "
                    "overseas facility operated by the CIA reveals the brutal "
                    "conditions that prisoners are subjected to.  The photos, "
                    "which were revealed by whistleblower "
                    "${whistleblower.firstLast}, show prisoners "
                    "being tortured and abused by US agents.  The photos have "
                    "caused an international outcry and prompted calls for the "
                    "United Nations to investigate the United States' torture "
                    "practices.&r"
                    "  Response within the United States has been notably muted "
                    "relative to the international outrage about the incident, "
                    "with only a few small protests featuring tired-looking "
                    "leftists carrying signs like $allProtestSigns.&r");
        }

      default:
        return MajorEventContent(
          headline: "BUGGY GAME",
          storyText: "There's no good news story for $view",
        );
    }
  } else {
    switch (view) {
      case View.lgbtRights:
        switch (lcsRandom(4)) {
          case 0:
            String cityName = randomCityName();
            FullName owner = generateFullName(Gender.whiteMalePatriarch);
            String transgenderWoman = switch (politics.laws[Law.lgbtRights]) {
              DeepAlignment.archConservative =>
                "so-called \"transgender woman\"",
              _ => "transgender woman",
            };
            String woman = switch (politics.laws[Law.lgbtRights]) {
              DeepAlignment.archConservative => "so-called \"woman\"",
              _ => "woman",
            };
            String cityReaction = "declared a state of emergency";
            FullName activist = generateFullName(Gender.whiteMalePatriarch);

            return MajorEventContent(
                headline: "TOILET CRISIS",
                storyText:
                    "$cityName - The government of $cityName $cityReaction "
                    "after a $transgenderWoman used the "
                    "restroom at a local restaurant.  Reports indicate that the "
                    "$woman \"needed to pee\" and \"felt like she had to go.\"&r"
                    "  \"Not again,\" vented the restaurant's owner, "
                    "${owner.firstLast}.  \"I don't know where trans people get "
                    "off thinking they're allowed to use the toilet.  We need to "
                    "draw a line in the sand by arresting trans people "
                    "if they go in the toilet matching their identity and "
                    "beating them up if they go in the toilet matching their "
                    "birth.\"&r"
                    "  \"He's right, you know,\" added "
                    "${activist.firstLast}, a local anti-trans activist. \"We "
                    "can't keep letting this happen.  It's well past time to "
                    "stand up for traditional values and protect our children "
                    "from these radical lunatics and their extremist potty "
                    "agenda.\"&r");
          case 1:
            return MajorEventContent(
              headline: "GAY BOOKS",
              storyText: "${randomCityName()} - A local library has come under "
                  "fire after it was discovered that the library's "
                  "\"diversity\" program was promoting books that were "
                  "considered to be pornographic and offensive to "
                  "traditional values.  The books, which were recommended to "
                  "children as part of the library's diversity program, "
                  "included titles such as \"Everybody Is Accepted\" and "
                  "\"My Friend Has Two Dads\".&r"
                  "  \"I'm terrified.  I thought I could bring my kids into "
                  "the library and not have to worry about them being "
                  "groomed by the liberal agenda to think gay people are "
                  "human,\" said a local parent.  \"I have every right to "
                  "decide who and what my kids should hate, and it shakes "
                  "me to my core to think that this so-called 'library' "
                  "is stocking books that say things I don't like.\"&r"
                  "  Following the controversy, the library has decided to "
                  "remove the books from its shelves.&r",
            );
          case 2:
            FullName primaryPartner = generateFullName();
            Gender gender = primaryPartner.gender;
            int inappropriatePartnerIndex = lcsRandom(10);
            String inappropriatePartner({bool firstPerson = false}) =>
                switch (inappropriatePartnerIndex) {
                  0 => firstPerson
                      ? "my beloved ${firstName(Gender.female)}"
                      : "${gender.hisHer} goldfish",
                  1 => firstPerson ? "baby grands" : "a piano",
                  2 => firstPerson ? "gas cooking" : "a stove",
                  3 => firstPerson
                      ? "my ringa-ding-dingle"
                      : "${gender.hisHer} cellphone",
                  4 => firstPerson
                      ? "${firstName()}'s smooth synthetic voice and seductive word choice"
                      : "an AI chatbot",
                  5 => firstPerson
                      ? "albacore"
                      : "a particularly tasty tuna fish casserole",
                  6 => firstPerson
                      ? "the Cavendish cultivar"
                      : "a bunch of bananas",
                  7 => firstPerson ? "smear frames" : "a cartoon character",
                  8 => firstPerson
                      ? "my beloved ${firstName(Gender.female)}"
                      : "${gender.hisHer} anime waifu",
                  9 => firstPerson
                      ? "big fluffy ears and a tail"
                      : "${gender.hisHer} fursona",
                  _ => firstPerson
                      ? "my bug collection"
                      : "an especially gross bug collection",
                };
            FullName spiritualGuide = generateFullName();
            FullName activist = generateFullName(Gender.whiteMalePatriarch);
            return MajorEventContent(
                headline: "WHAT THE LOVE",
                storyText: "${randomCityName()} - A local wedding venue has "
                    "conducted a so-called \"wedding\" between a "
                    "${gender.manWoman} and ${inappropriatePartner()}.  The "
                    "${gender.manWoman}, ${primaryPartner.firstLast}, "
                    "was escorted down the aisle by ${gender.hisHer} spiritual "
                    "guru, ${spiritualGuide.firstLast}.&r"
                    "  \"I'm so happy to be here today,\" said "
                    "${primaryPartner.firstLast}.  \"I've been waiting for "
                    "this day for so long.  I'm so glad to be able to "
                    "share my love of ${inappropriatePartner(firstPerson: true)}.\"&r"
                    "  Others haven't been so celebratory.  \"When we said "
                    "the LGBTQ agenda was undermining the sanctity of marriage "
                    "and the moral fabric of this country, this is exactly what "
                    "we were talking about,\" said ${activist.firstLast}, a "
                    "local activist who is clearly not a fan of the LGBTQ "
                    "agenda.  \"I said it, didn't I? I said we were going to "
                    "see somebody try to marry ${inappropriatePartner()}.  I "
                    "literally said exactly that.\"&r"
                    "  At press time, ${spiritualGuide.last}, ${activist.last}, "
                    "and ${primaryPartner.last} were all seen making out in the "
                    "parking lot, leading to some confusion in our press room "
                    "about what the relationship between these people is "
                    "and why we're reporting on any of this.&r");
          default:
            return MajorEventContent(
              headline: "KINKY WINKY",
              pictureId: pictureTinkyWinky,
              subheadline: switch (lcsRandom(12)) {
                0 =>
                  "Jerry Falwell's zombie rises to warn us about Tinky Winky.  Again.",
                1 => "The Tinky Winky controversy is back in the news.  Again.",
                2 =>
                  "Jerry Fallwell is back from the dead and he's mega pissed about something.",
                3 =>
                  "We're having a slow news day, so here's a picture of Tinky Winky.",
                4 => "Tinky Winky is back in the news for some reason.",
                5 =>
                  "The latest memes on social media are all about Tinky Winky being gay.",
                6 => "Look, Tinky Winky has a purple triangle on his head!",
                7 => "It's Jerry Fallwell's fault.  Again.",
                8 =>
                  "We're all doomed because the Tinky Winky issue won't die.",
                9 => "Polls show people could not care less about Tinky Winky.",
                10 =>
                  "Is the effeminate Tinky Winky a symbol of the LGBT agenda?",
                11 =>
                  "It's finally time to have a frank conversation about Tinky Winky.",
                _ => "Teletubbies reruns reignite the Tinky Winky controversy.",
              },
            );
        }
      case View.immigration:
        FullName criminal = generateFullName();
        String crime = [
          "stealing a bike from a kid",
          "punching a dog in the face",
          "dunking on a white guy in a pickup game",
          "swinging a baseball bat at a stray cat",
          if (noProfanity)
            "[doing stinky things] on the U.S. flag"
          else
            "defecating on the U.S. flag",
        ].random;
        String bastard = noProfanity ? "[jerk]" : "bastard";
        String solution = [
          "to build a border wall",
          "to increase border patrols",
          "to deport everyone who isn't white",
          "to end birthright citizenship",
          "to crack down on sanctuary cities",
          "stricter immigration laws"
        ].random;
        String impact = [
          "draining local resources",
          "taking jobs from American citizens",
          "increasing crime rates",
          "overwhelming social services",
          "lowering wages",
          "increasing housing costs",
          "straining public schools"
        ].random;
        String congressman = politics.house
                .any((member) => member == DeepAlignment.archConservative)
            ? "Congressman ${lastName(Gender.whiteMalePatriarch)}"
            : "some random local who walked up to our reporter and started "
                "talking about how they're not a fan of immigration";
        String illegalImmigrant = switch (laws[Law.immigration]) {
          DeepAlignment.archConservative => "illegal",
          DeepAlignment.conservative => "illegal alien",
          DeepAlignment.moderate => "illegal immigrant",
          DeepAlignment.liberal => "undocumented immigrant",
          _ => "immigrant",
        };

        return MajorEventContent(
            headline: "FINALLY GONE",
            storyText: "${randomCityName()} - The nationwide manhunt is over "
                "after authorities finally caught ${criminal.firstLast}, an "
                "$illegalImmigrant who captured national attention after "
                "${criminal.gender.heShe} was seen $crime in a viral video.&r"
                "  \"We got ${criminal.gender.himHer}, but we all know "
                "this $bastard should never have been here in the "
                "first place.  Criminals like this are exactly why we need "
                "$solution,\" said $congressman.  "
                "\"We can't continue to allow our immigration laws to be "
                "flouted by these sick monsters while our children "
                "suffer.\"&r"
                "  Local residents have expressed growing concern about the "
                "impact of immigration on their community, with many "
                "calling for new laws to help keep foreign criminals from "
                "$impact.&r");
      case View.drugs:
        String drug = [
          "marijuana",
          "cocaine",
          "heroin",
          "methamphetamine",
          "fentanyl",
          "prescription painkillers",
          "MDMA",
          "LSD",
          "psilocybin mushrooms",
        ].random;
        FullName drugExpert = generateFullName();
        FullName influencer = generateFullName();
        String hell = noProfanity ? "[heaven]" : "hell";
        String addendum = [
          "I'm literally dead right now.",
          "don't forget to like and subscribe.",
          "if you come at me with $drug, you'd better not miss.",
          "it's a blin wayzo thing, you wouldn't understand.",
          "weepa weepa weepa, woof woof woof!",
          "ciao, I'm out.",
          "shoutout to my homies.",
          "you should really try these chips, they're pretty good.",
          "I ship it, I ship it, don't at me.",
        ].random;
        String consequence = [
          "instantly die",
          "become a drug addict",
          "get arrested",
          "start hallucinating",
          "get punched in the face by God",
          "smell like a funky funk",
          "develop mental health issues",
          "be completely emasculated",
          "lose your job",
        ].random;

        return MajorEventContent(
            headline: "DRUG PANIC",
            storyText: "${randomCityName()} - Chaos erupted online after "
                "self-proclaimed drug expert ${drugExpert.firstLast} "
                "went viral with a short form video claiming that \"every "
                "single person who comes within a six-foot radius of "
                "$drug will $consequence.\"  The "
                "panic took a bizarre turn when social media influencers "
                "started dramatically faking their own drug-related deaths "
                "to prove the point.&r"
                "  \"I'm not even going to try to "
                "explain this,\" said social media influencer "
                "${influencer.firstLast}.  \"But it's funny as $hell.  Also, "
                "$addendum\"&r"
                "  Health officials are scrambling to communicate the truth, "
                "even as a rash of people have begun to claim they've "
                "overdosed on substances they haven't even used.  Critics "
                "argue that the rampant misinformation is fueling "
                "moral panic rather than addressing real addiction issues.  "
                "\"Lying about drugs isn't going to stop anyone from trying "
                "them, it's just discrediting our efforts to educate people "
                "about the dangers of drugs in the eyes of those predisposed "
                "to experiment,\" warned a spokesperson from the FDA.  "
                "\"Still, I'm glad people are thinking about the dangers of "
                "$drug and I'm hopeful some constructive dialogue will come "
                "out of this.\"&r");
      case View.military:
        // Major new deployment to fight in some foreign country that
        // rallies public opinion for military
        CountryName country = generateCountryName();
        return MajorEventContent(
            headline: "ARMY ROLLS OUT",
            storyText:
                "Washington, D.C. - As the U.S. military prepares to deploy "
                "to the ${country.name} to defend democracy against the threat "
                "of terrorism, people around the country are "
                "rallying behind the troops.&r"
                "  \"We need to stand up for democracy and beat "
                "the bad guys,\" said a military spokesperson.  \"Don't "
                "worry, we learned from the last time we invaded a country, "
                "and this one's going to be easy.  In and out, no problem.\"&r"
                "  The military has already started training for the mission, "
                "and the troops are ready to go.  \"I can't wait to shoot some "
                "people,\" one particularly enthusiastic soldier said.  "
                "\"I joined the military to go fight wars, so I'm really "
                "looking forward to this.\"&r"
                "  Meanwhile, on the home front, civilians across the country "
                "are turning out to show their support for the troops.  "
                "\"You can buy our new ${country.shortName} Invasion "
                "Value Meal,\" a national fast food chain spokesperson said.  "
                "\"It's a great way to show your patriotism.\"  At press time, "
                "hundreds of people were lined up around the block in hopes of "
                "getting the burger and fries.&r");
      case View.civilRights:
        switch (lcsRandom(3)) {
          case 0:
            FullName racist = generateFullName(Gender.whiteMalePatriarch);
            String racistDescription = [
              "a famously garbage human being",
              "a miserable hatemonger",
              "a curmudgeon who hated everyone",
              "one of the most infamous people to have ever lived in the area",
              "who appears in history books as a symbol of white supremacy",
            ].random;
            return MajorEventContent(
                headline: "STATUE GONE",
                storyText:
                    "${randomCityName()} - A local white supremacist group has "
                    "seen a surge in membership after a local statue of a racist "
                    "icon was removed from a local park.  The statue depicted "
                    "${racist.first} ${racist.middle} ${racist.last}, "
                    "$racistDescription.  The statue was eventually "
                    "removed from the park after pressure from civil rights "
                    "groups, leading to outrage from some who view the act as "
                    "one of cultural genocide.&r"
                    "  \"Why would we be sorry?  ${racist.firstLast} was an "
                    "absolutely massive fascist, and "
                    "we've been trying to get this statue removed for years,\" said "
                    "a local civil rights leader.  "
                    "\"Haters gonna hate, but we carried this day.\"&r"
                    "  Back at the park, the sentiment was different.  \"This is "
                    "a slap in the face to our heritage,\" one man yelled into a "
                    "megaphone.  \"We're all good people here, we used to be "
                    "friends with those people, but then they started asking for "
                    "unreasonable things.  Removing Mr. ${racist.last} is "
                    "symbolic of their larger effort to sideline our historic "
                    "control of the country.  We're not going to let them do it!  "
                    "White people, stand up!\"&r");
          case 1:
            FullName newBoss = generateFullName();
            return MajorEventContent(
                headline: "WOKE HIRE",
                storyText:
                    "${randomCityName()} - A local company has been accused of "
                    "discrimination after promoting ${newBoss.firstLast}, a "
                    "black ${newBoss.gender.manWoman}, into a "
                    "high-level position.  ${newBoss.last}, who had previously "
                    "been a software engineer at the company for 27 years, "
                    "has been cited by disgruntled employees as unqualified.&r"
                    "  \"I got passed over for that lazy ass?\" "
                    "said one mail room clerk who had never met the new boss "
                    "and works in a completely different department.  "
                    "\"I work way harder than ${newBoss.gender.heShe} does, "
                    "everybody knows that.\"&r"
                    "  The controversy has led to a wave of complaints against "
                    "${newBoss.last}.  \"I bet ${newBoss.gender.heShe} doesn't "
                    "even know how to use the computer,\" one employee said.  "
                    "\"${newBoss.gender.heSheCap} probably just got promoted "
                    "to make the company look good.\"&r");
          default:
            String civilRightsMarch = "large civil rights march";
            String marchers = "marchers";
            String conclusion = "the march completed without any violence";
            String couldntCareLessAbout = "whatever the march was about";
            String protesting = "protesting";
            if (ns.publicationAlignment == DeepAlignment.archConservative) {
              civilRightsMarch = "bunch of black people";
              marchers = "black people";
              conclusion = "finished whatever they were doing without any "
                  "further incident";
              couldntCareLessAbout = "all the noise they were making";
              protesting = "kicking up all this fuss";
            }

            return MajorEventContent(
                headline: "JAMMED UP",
                storyText: "${randomCityName()} - A $civilRightsMarch blocked "
                    "traffic on a major street for fifteen minutes, leading "
                    "to frustration from drivers.&r"
                    "  Although the $marchers moved on relatively quickly "
                    "and $conclusion, many "
                    "uninterested bystanders who couldn't care less about "
                    "$couldntCareLessAbout were still annoyed that "
                    "somebody was making them late.&r"
                    "  \"I'm not sure why they're $protesting,\" said one "
                    "driver who was stuck in traffic for fifteen minutes.  "
                    "\"I wasn't really listening.  How do they have "
                    "so much free time on their hands anyway?  Maybe they "
                    "should get off their asses and get a job.  That "
                    "would probably fix whatever it is they're going on "
                    "about in the first place.\"&r");
        }
      case View.torture:
        String methodToMakeItMoreHuman = [
          "scented candles and soothing music",
          "before-and-after massages",
          "a hot bath and a new pair of shoes",
          "guided meditation to help them relax",
          "opportunities to connect with an AI therapist",
        ].random;
        String insidiousPlot = [
          "blow up the sun",
          "destroy the moon",
          "facilitate an alien invasion",
          "attack and dethrone God",
          "corrupt the youth of the world with space lasers",
          "stop the jet stream",
          "smite the earth with a plague of locusts",
          "invent a new form of energy that would make the world a better place",
        ].random;
        return MajorEventContent(
            headline: "COMFY TORTURE",
            storyText:
                "${randomCityName()} - Torture isn't what it used to be, "
                "according to a leaked classified report.  The CIA has "
                "pioneered a new method of humane torture that offsets the "
                "physical agony with $methodToMakeItMoreHuman.&r"
                "  \"I don't know who gave you that paper, but I guess now "
                "that it's out, there's no harm confirming it,\" a CIA "
                "spokesperson said.  \"We've been exploring the use of "
                "luxury interrogation suites that achieve several major "
                "benchmarks.  Focus groups agree that the new method looks "
                "much more humane than the old ones, and the results are "
                "nothing short of miraculous.  We had one guy confess "
                "to everything we wanted him to confess, he even admitted "
                "plotting to $insidiousPlot!  Good thing we stopped that "
                "before it happened.\"&r"
                "  While critics say this is just a new spin on old abuses, "
                "some have hailed the new methods as the next stage in "
                "interrogation techniques, and called on the approach to "
                "be adopted by police forces across the country.&r");
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

        return MajorEventContent(
          headline: "LET'S FRY 'EM",
          storyText:
              "${randomCityName()} - Perhaps parents can rest easier tonight.  "
              "The authorities have apprehended their primary suspect in the "
              "String of brutal child killings that has kept everyone in the area on edge, "
              "according to a spokesperson for the police department here.&r"
              "  $serialKiller was detained yesterday afternoon, reportedly in "
              "possession of $heWasFoundInPosessionOf.  Over twenty children in "
              "the past two years have gone missing, only to turn up later "
              "$victimsFound.  Sources say that the police got a break in the "
              "case when $theBreakthrough.&r"
              "  The district attorney's office has already repeatedly said "
              "$howTheDAReacts in this case.&r",
        );
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

        return MajorEventContent(
          headline: "ARMED CITIZEN",
          subheadline: "SAVES LIVES",
          storyText: "${randomCityName()}"
              " - In an uplifting turn, a $massShooting was prevented "
              "by a bystander with a gun.  After ${shooter.firstLast} opened "
              "fire at $venue, ${hero.firstLast} sprang into action.  "
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
              "heroic actions.\"&r",
        );
      case View.womensRights:
        FullName author = generateFullName();
        String bookTitle = "${author.first} ${author.last}'s "
            "memoir, \"${[
          "Aborted Regret", "The Abortion Chronicles", "The Abortion Diaries",
          "The Abortion Papers", "The Abortion Files", //
        ].random}\"";
        FullName politician = generateFullName();
        String politicianName = "${politician.first} ${politician.last}";
        String callToAction = switch (laws[Law.abortion]) {
          DeepAlignment.archConservative => "resisting any attempt by the "
              "soulless elite to legalize the murder of children",
          _ => "pass new laws to protect the most vulnerable children "
              "in our society from being slaughtered by Liberals",
        };
        return MajorEventContent(
          headline: "CLINIC REGRET",
          storyText:
              "${randomCityName()} - A new book has quickly risen to the top "
              "of the bestseller lists, $bookTitle.  The author, a former "
              "abortion doctor, has dedicated ${author.gender.hisHer} retirement "
              "to discouraging women from having abortions.  The book includes many "
              "stories about women who regret having abortions and interviews with "
              "adult survivors of failed abortions.  Reviews say that the book is "
              "powerful and moving, and many readers have changed the way they "
              "think about the morality of abortion.&r"
              "  According to U.S. Representative $politicianName, one of "
              "the most vocal pro-life representatives in Congress, the book is "
              "\"a clear message to Americans, calling on us to $callToAction.\"&r",
        );
      case View.taxes:
        String str = "${["Great", "Noble", "True", "Pure", "Golden"].random} ${[
          "Leadership", "Courage", "Pioneer", "Communicator", "Faith" //
        ].random}: A new book lauding Reagan and the greatest generation.";
        return MajorEventContent(
          headline: "REAGAN THE MAN",
          pictureId: pictureReaganBook,
          subheadline: str,
        );
      case View.nuclearPower:
        return const MajorEventContent(
          headline: "OIL CRUNCH",
          pictureId: pictureOil,
          subheadline:
              "OPEC cuts oil production sharply in response to a US foreign policy decision.",
        );
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

        return MajorEventContent(
          headline: "APE EXPLORERS",
          storyText: "${randomCityName()} - Researchers $fromCountry "
              "report that they have discovered an amazing new wonder drug.  "
              "Called $drugName, the drug apparently $drugEffect.&r"
              "  Fielding questions about the ethics of their experiments from "
              "reporters during a press conference yesterday, a spokesperson for "
              "the research team stated that, \"It really isn't so bad as all "
              "that.  Chimpanzees are very resilient creatures.  "
              "$responseToEthics.  We have a very experienced research team.  "
              "While we understand your concerns, any worries are entirely "
              "unfounded.  I think the media should be focusing on the enormous "
              "benefits of this drug.\"&r"
              "  The first phase of human trials is slated to begin in a few "
              "months.&r",
        );
      case View.policeBehavior:
        return MajorEventContent(
          headline: noProfanity ? "[JERKS]" : "BASTARDS",
          pictureId: pictureTerroristAttack,
        );
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

        return MajorEventContent(
          headline: "HOSTAGE SLAIN",
          storyText: "${randomCityName()}"
              " - The hostage crisis at the $prisonName Correctional Facility "
              "ended tragically yesterday with the death of both the prison "
              "guard being held hostage and ${guardGender.hisHer} captor.&r"
              "  Two weeks ago, convicted $rapist ${perp.firstLast}, an inmate "
              "at $prisonName, overpowered ${guard.firstLast} and barricaded "
              "${perpGender.himselfHerself} with the guard in a prison tower.  "
              "Authorities locked down the prison and attempted to negotiate by "
              "phone for ${lcsRandom(18) + 5} days, but talks were cut short when "
              "${perp.firstLast} reportedly screamed into the receiver, \""
              "$imKillingThisPig\"&r"
              "  The tower was breached in an attempt to "
              "reach the hostage, but ${perp.last} had already $killedTheGuard.  "
              "The prisoner was $beatenToDeath while \"resisting capture\", "
              "according to a prison spokesperson.&r",
        );
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

        return MajorEventContent(
          headline: "DODGED BULLET",
          storyText:
              "Washington, DC - The CIA announced yesterday that it has averted "
              "a terror attack that would have occurred on American soil.&r"
              "  According to a spokesperson for the agency, $terrorists "
              "planned to $attackChoice.  "
              "However, intelligence garnered from deep within the mysterious "
              "terrorist organization allowed the plot to be foiled just days "
              "before it was to occur.&r"
              "  The spokesperson further stated, \""
              "I won't compromise our sources and methods, but let me just say "
              "that we are grateful to the Congress and this Administration for "
              "providing us with the tools we need to neutralize these enemies of "
              "civilization before they can destroy American families.  "
              "However, let me also say that there's more that needs to be done.  "
              "The Head of the Agency will be sending a request to Congress "
              "for what we feel are the essential tools for combating terrorism in "
              "this new age.\"&r",
        );
      case View.freeSpeech:
        return const MajorEventContent(
          headline: "HATE RALLY",
          pictureId: pictureHateRally,
          subheadline:
              "Free speech advocates fight hard to let a white supremacist rally take place.",
          remapSkinTones: true,
        );
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

        return MajorEventContent(
          headline: "GM FOOD FAIRE",
          storyText: "${randomCityName()}"
              " - The genetic foods industry staged a major event here yesterday "
              "to showcase its upcoming products.  Over thirty companies set up "
              "booths and gave talks to wide-eyed onlookers."
              "&r"
              "  One such corporation, $corporation, presented their product, "
              "\"$product\", during an afternoon PowerPoint presentation.  "
              "According to the public relations representative speaking, "
              "this amazing new product actually $benefit.&r"
              "  Spokespeople for the GM corporations were universal "
              "in their dismissal of the criticism which often follows "
              "the industry.  One in particular said, \""
              "Look, these products are safe.  That thing about the "
              "$incident is just a load of $hooey.  Would we stake the "
              "reputation of our company on unsafe products?  No.  That's "
              "just ridiculous.  I mean, sure companies have put unsafe "
              "products out, but the GM industry operates at a higher ethical "
              "standard.  That goes without saying.\"&r",
        );
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

        return MajorEventContent(
          headline: "JUSTICE AMOK",
          storyText: "${randomCityName()}"
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
              "  A spokesperson for the district attorney has stated that the "
              "case will not be retried, due to the current economic doldrums "
              "that have left the state completely strapped for cash.&r",
        );
      case View.sweatshops:
        String storyText = month >= 8 && month <= 11
            ? "Fall fashions hit the stores across the country."
            : "Fall fashions are previewed in stores across the country.";
        return MajorEventContent(
          headline: "THEY ARE HERE",
          pictureId: pictureFashionLine,
          subheadline: storyText,
        );
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

        return MajorEventContent(
          headline: "LOOKING UP",
          storyText: "${randomCityName()}"
              " - Pollution might not be so bad after all.  The $thinkTankName "
              "recently released a wide-ranging report detailing recent trends "
              "and the latest science on the issue.  "
              "Among the most startling of the think tank's findings is that "
              "$absurdBehavior might actually $pollutionBenefit.&r"
              "  When questioned about the science behind these results, "
              "a spokesperson stated that, \"$scienceIsAnArtReally.  You have to "
              "realize that $theLiberals often distort these issues to their own "
              "advantage.  All we've done is introduced a little clarity into "
              "the ongoing debate.  Why is there contention on the pollution "
              "question?  It's because there's work left to be done.  We should "
              "study much more before we urge any action.  Society really just "
              "needs to take a breather on this one.  We don't see why there's "
              "such a rush to judgment here.\"&r",
        );
      case View.corporateCulture:
        String techGiantName = "${[
          "Ameri", "Gen", "Oro", "Amelia", "Vivo", "Benji", "Amal", "Ply",
          "Seli", "Rio" //
        ].random}${[
          "tech", "com", "zap", "cor", "dyne", "bless", "chip", "co", "wire",
          "rex" //
        ].random}";

        return MajorEventContent(
          headline: "NEW JOBS",
          storyText: "${randomCityName()}"
              " - Several major companies have announced at a joint news "
              "conference here that they will be expanding their work forces "
              "considerably during the next quarter.  Over thirty thousand jobs "
              "are expected in the first month, with tech giant $techGiantName "
              "increasing its payrolls by over ten thousand workers alone.  "
              "Given the state of the economy recently and in light of the "
              "tendency of large corporations to export jobs overseas these "
              "days, this welcome news is bound to be a pleasant surprise to "
              "those in the unemployment lines.&r"
              "  The markets reportedly "
              "responded to the announcement with mild interest, although the "
              "dampened movement might be expected due to the uncertain futures "
              "of some of the companies in the tech sector.  On the whole, "
              "however, analysts suggest that not only does the expansion "
              "speak to the health of the tech industry but is also indicative "
              "of a full economic recovery.&r",
        );
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
              "screamed \"[Darn] the police those [big old jerks].  I got a [parking] ticket this morning and I'm [so angry].\"",
              "[consumed milk] from [a lady]",
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

        return MajorEventContent(
          headline: "FM OBSCENITY",
          storyText: "${randomCityName()}"
              " - Infamous FM radio shock jock ${shockJock.firstLast} has "
              "brought radio entertainment to a new low.  During yesterday's "
              "broadcast of the program \"${shockJock.first}'s $showName\", "
              "${shockJock.firstLast} reportedly $shockingBehavior on the air.&r"
              "  Although ${shockJock.firstLast} later apologized, the FCC "
              "received several hundred complaints from irate listeners from "
              "all over the state.  A spokesperson for the FCC stated that the "
              "incident is under investigation.&r",
        );
      default:
        return MajorEventContent(
          headline: "BUGGY GAME",
          storyText: "There's no bad news story for $view",
        );
    }
  }
}
