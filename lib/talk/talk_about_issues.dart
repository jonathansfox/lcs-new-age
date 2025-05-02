import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/recruitment.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/sitemode/site_display.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<bool> talkAboutIssues(Creature a, Creature tk) async {
  Law lw =
      _discussionPoints.keys.toList().random; // pick a random law to talk about
  _DiscussionPoint issue = _discussionPoints[lw]!;

  bool succeeded = false;
  bool youAreStupid = false;
  bool issueTooLiberal = false;

  if ((a.attribute(Attribute.intelligence) < 5 ||
          oneIn(a.attribute(Attribute.intelligence))) &&
      !a.attributeCheck(Attribute.intelligence, Difficulty.average)) {
    youAreStupid = true;
  } else if (laws[lw] == DeepAlignment.eliteLiberal) {
    issueTooLiberal = true;
  }

  clearSceneAreas();
  mvaddstrc(9, 1, white, "${a.name} says, ");
  setColor(lightGreen);
  int y = 10;
  move(y++, 1);

  if (youAreStupid) {
    if (noProfanity && issue.noProfanityStupidPrompt != null) {
      addstr("\"${issue.noProfanityStupidPrompt}\"");
    } else {
      addstr("\"${issue.stupidPrompt}\"");
    }
  } else if (issueTooLiberal) {
    addstr("\"${issue.issueTooLiberal}\"");
  } else {
    addstr("\"${issue.normalPromptLine1}");
    if (issue.normalPromptLine2 != null) {
      mvaddstr(y++, 1, "${issue.normalPromptLine2}");
    }
    addstr("\"");
  }

  await getKey();

  int difficulty = Difficulty.veryEasy;

  if (tk.align == Alignment.conservative) {
    difficulty += DifficultyModifier.aLotHarder;
  }
  if (!tk.type.talkReceptive) difficulty += DifficultyModifier.aLotHarder;
  if (youAreStupid) difficulty += DifficultyModifier.aLittleHarder;
  if (issueTooLiberal) difficulty += DifficultyModifier.aLittleHarder;

  succeeded = a.skillCheck(Skill.persuasion, difficulty);
  debugPrint("Talk about issues: $succeeded, $difficulty");

  // Prisoners never accept to join you, you must liberate them instead
  if (succeeded && tk.name != "Prisoner") {
    y++;
    mvaddstrc(y++, 1, white, "${tk.name} responds,");
    move(y++, 1);
    setColor(lightBlue);
    if (tk.type.id == CreatureTypeIds.mutant &&
        tk.attribute(Attribute.intelligence) < 3) {
      addstr("\"Aaaahhh...\"");
    } else {
      switch (lcsRandom(10)) {
        case 0:
          addstr("\"Dear me! Is there anything we can do?\"");
        case 1:
          addstr("\"That *is* disturbing!   What can I do?\"");
        case 2:
          addstr("\"Gosh!   Is there anything I can do?\"");
        case 3:
          addstr("\"That's frightening!   What can we do?\"");
        case 4:
          addstr("\"Oh, really?\" ");
          await getKey();
          mvaddstrc(y++, 1, lightGreen, "\"Yeah, really!\"");
        case 5:
          addstr("\"Oh my Science!   We've got to do something!\"");
        case 6:
          addstr("\"Dude... that's like... totally bumming me.\"");
        case 7:
          addstr("\"Gadzooks! Something must be done!\"");
        case 8:
          addstr("\"You got anything to smoke on you?\" ");
          addstrc(white, "*cough*");
        case 9:
        default:
          addstr("\"Lawks, I don't think we can allow that.\"");
      }
    }

    await getKey();

    if (!poolAndProspects.contains(tk)) {
      mvaddstrc(++y, 1, white,
          "After more discussion, ${tk.name} agrees to come by later tonight.");
      await getKey();
      tk.nameCreature();
      RecruitmentSession recruitSession = RecruitmentSession(tk, a);
      recruitmentSessions.add(recruitSession);
      encounter.remove(tk);
    } else {
      mvaddstrc(
          ++y, 1, white, "They chat briefly, but ${tk.name} has work to do.");
      await getKey();
    }
    return true;
  } else {
    y++;
    mvaddstrc(y++, 1, white, "${tk.name} responds, ");
    setColor(lightBlue);
    if (tk.type.id == CreatureTypeIds.mutant &&
        tk.attribute(Attribute.intelligence) < 3) {
      mvaddstr(y++, 1, "\"Ugh.  Pfft.\"");
    } else {
      if (tk.align == Alignment.conservative && youAreStupid) {
        move(y++, 1);
        if (tk.type.id == CreatureTypeIds.gangUnit) {
          addstr("\"Do you want me to arrest you?\"");
        } else if (tk.type.id == CreatureTypeIds.deathSquad) {
          addstr("\"If you don't shut up, I'm going to shoot you.\"");
        } else {
          addstr([
            "\"Get away from me, you dirty hippie.\"",
            "\"My heart aches for humanity.\"",
            "\"I'm sorry, but I think I'm done talking to you.\"",
            "\"Do you need some help finding the exit?\"",
            "\"People like you are the reason I'm on medication.\"",
            "\"Everyone is entitled to be stupid, but you abuse the privilege.\"",
            "\"I don't know what you're on, but I hope it's illegal.\"",
            "\"Don't you have a parole meeting to get to?\"",
            "\"Wow. Why am I talking to you again?\"",
            "\"Were you dropped as a child?\""
          ].random);
        }
      } else if (tk.align == Alignment.conservative &&
          tk.attribute(Attribute.intelligence) > 10) {
        mvaddstr(y++, 1, "\"${issue.conservativeResponse}\"");
      } else {
        mvaddstr(y++, 1, "\"Whatever.\"");
      }
    }
    addstrc(white, " <turns away>");

    await getKey();

    tk.isWillingToTalk = false;
    return true;
  }
}

class _DiscussionPoint {
  _DiscussionPoint(
    this.normalPromptLine1,
    this.normalPromptLine2,
    this.stupidPrompt,
    this.issueTooLiberal,
    this.conservativeResponse,
  );
  String normalPromptLine1;
  String? normalPromptLine2;
  String stupidPrompt;
  String? noProfanityStupidPrompt;
  String issueTooLiberal;
  String conservativeResponse;
}

Map<Law, _DiscussionPoint> _discussionPoints = {
  Law.abortion: _DiscussionPoint(
      "Forced birth policies are about control, not life. After all, if it",
      "were about life, they'd fund healthcare and childcare.",
      "Conservatives think women should just hold it in for nine months.",
      "If abortion is really legal, why aren't more women doing it?",
      "Abortion is murder."),
  Law.animalRights: _DiscussionPoint(
      "Animals endure unimaginable suffering in labs, just so we can test",
      "cheap products like shampoo and mascara.",
      "Every time you eat chicken, a chicken ghost haunts your freezer.",
      "We've come so far, but animals are still denied the right to vote!",
      "Don't pretend animals are human."),
  Law.policeReform: _DiscussionPoint(
      "Systemic racism and lack of accountability in policing disproportionately",
      "harm marginalized communities.",
      "Cops write speeding tickets just to fund their donut breaks!",
      "We still haven't abolished the police.",
      "Only criminals have reason to fear police."),
  Law.privacy: _DiscussionPoint(
      "The intelligence community monitors innocent citizens, treating your",
      "private life like a library book they can check out at any time.",
      "The NSA probably has notes on how many holes are in your underwear.",
      "As long as the government has spies, they'll keep undermining privacy.",
      "National security is important."),
  Law.deathPenalty: _DiscussionPoint(
      "The death penalty isn't justice, it's institutionalized revenge.",
      "They're just punishing murder by committing more murder!",
      "They executed this one dude, and like, his head caught on fire.",
      "You can go to prison for life for serious crimes.",
      "Some people deserve to die."),
  Law.nuclearPower: _DiscussionPoint(
      "Radioactive waste is being stored all over the country, and it poses",
      "a serious threat to many families, even in this neighborhood.",
      "Have you seen Godzilla?  Nuclear power is bad!",
      "Some people support legalizing nuclear power.",
      "Nuclear power is clean."),
  Law.pollution: _DiscussionPoint(
      "Industries that stop at nothing to become more profitable are polluting",
      "the environment in ways that hurt not only humans, but animals too.",
      "You wanna look like the Toxic Avenger?  Oppose pollution!",
      "We have a long way to go before we reach zero carbon emissions.",
      "It's not that bad."),
  Law.labor: _DiscussionPoint(
      "Corporate greed has turned full-time jobs into poverty traps, while",
      "workers' rights are eroded daily.",
      "Nobody gets paid a cent unless a union is involved!",
      "Even with unions, corporate bosses still try to jerk us around.",
      "Trust the free market, it hasn't failed us yet."),
  Law.lgbtRights: _DiscussionPoint(
      "Trans people are just like anyone else, yet they're still fighting",
      "against laws that treat them as second-class citizens.",
      "The man doesn't even know you is a pronoun.",
      "We still have work to do ensuring society treats trans people fairly.",
      "I hate trans people."),
  Law.corporate: _DiscussionPoint(
      "Corporate executives use giant corporations as a means to become parasites",
      "that suck wealth out of this country and put it into their pockets.",
      "The corporations are putting you down, dude.",
      "How can we have come this far and still have corporate personhood?",
      "Corporations are an important part of capitalism."),
  Law.freeSpeech: _DiscussionPoint(
      "Protests and demonstrations are regularly and often brutally suppressed in",
      "this country.  People have to watch what they write -- even what they read.",
      "The government won't let me fucking swear!",
      "Free speech is an eternal struggle.  We could easily slide back.",
      "Don't be offensive and you'll be fine.")
    ..noProfanityStupidPrompt =
        "[The government is great and I have nothing to say about it.]",
  Law.flagBurning: _DiscussionPoint(
      "Burning a piece of cloth is actually stigmatized in this country.",
      "You can love freedom and still hate what our government stands for.",
      "The flag is stupid.",
      "The flag represents colonialism and oppression.  We should burn it.",
      "That flag is the sacred symbol of our country.")
    ..noProfanityStupidPrompt = "[I feel sad when I see our flag.]",
  Law.gunControl: _DiscussionPoint(
      "We live in such a backwards country right now that people think it's",
      "a right to walk around with the power to murder at any moment.",
      "Guns *kill* people.",
      "We can't finish banning guns until we repeal the second amendment.",
      "Without guns, we're slaves to the Government."),
  Law.taxes: _DiscussionPoint(
      "The tax code has been designed to perpetuate an unjust class",
      "structure that is keeping you oppressed.",
      "Rich people, like, have money, man.",
      "We should raise taxes even more.  There's so much more we can do.",
      "I want to pay lower taxes."),
  Law.genderEquality: _DiscussionPoint(
      "Sexism is still pervasive, in subtle ways, and women make much less",
      "than they deserve for their labor.",
      "We need more women!",
      "Despite our progress, there's more to be done for women's rights.",
      "Why don't you go burn a bra or something?"),
  Law.civilRights: _DiscussionPoint(
      "Racial discrimination isn't a relic of the past, it's woven into the",
      "fabric of our institutions, holding back true equality.",
      "Racism put on a suit and got a desk job.",
      "Implicit bias is something we all need to struggle against.",
      "Reverse discrimination is still discrimination."),
  Law.drugs: _DiscussionPoint(
      "The government's drug policy is a mess.  We need to stop filling prisons",
      "with drug users, and only intervene when people really need help.",
      "Dude, the government won't let you do drugs.",
      "You can still be fired for using drugs, even without a performance issue.",
      "Drugs are a terrible influence on society."),
  Law.immigration: _DiscussionPoint(
      "Millions of people are treated like criminals for living normal lives.",
      "Immigration is an act of hope that deserves our respect, not rejection.",
      "Borders are just lines on a map, man.",
      "We shouldn't rest until we have truly open borders.",
      "Immigration undermines our economy and culture."),
  Law.elections: _DiscussionPoint(
      "Political favors are bought and sold for campaign contributions,",
      "and the voting system enforces two party dominance.",
      "The politicians are just tools of the corporations!",
      "Politicians who self-finance their campaigns essentially buy their office.",
      "Unregulated campaigning is a matter of free speech."),
  Law.military: _DiscussionPoint(
      "We spend billions on weapons while schools and hospitals beg for funding.",
      null,
      "I bet the Pentagon has a secret budget for laser sharks.",
      "Every penny we spend on the military could be better spent elsewhere.",
      "The military protects us and enables our way of life."),
  Law.torture: _DiscussionPoint(
      "In the name of national security, we've sacrificed our soul by letting",
      "the government torture and abuse human beings on our behalf.",
      "The government forces people to do extreme sports like waterboarding!",
      "We need to stay vigilant about respecting human rights at all times.",
      "The terrorists would do worse to us."),
  Law.prisons: _DiscussionPoint(
      "The prison system doesn't help criminals by providing rehabilitation, so",
      "when they get released, they mostly become criminals again.",
      "They lock people in tiny rooms with no snacks.  That's messed up.",
      "We need to keep moving and work to achieve a world without prisons.",
      "Criminals deserve what they get in prison."),
};
