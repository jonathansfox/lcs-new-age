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

  if (!a.attributeCheck(Attribute.intelligence, Difficulty.easy)) {
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

  if (tk.align == Alignment.conservative) difficulty += 15;
  if (!tk.type.talkReceptive) difficulty += 15;
  if (youAreStupid) difficulty += 9;
  if (issueTooLiberal) difficulty += 9;

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
      "The government is systematically trying to rob women of the right",
      "to control their own destinies.",
      "Conservatives make women turn to coat hangers.",
      "Conservatives don't like abortion.",
      "Abortion is murder."),
  Law.animalRights: _DiscussionPoint(
      "Animals are routinely subjected to inhumane treatment in labs in this",
      "country.",
      "Richard Gere put a gerbil in his butt!",
      "Animals are denied the right to vote.",
      "Don't pretend animals are human."),
  Law.policeReform: _DiscussionPoint(
      "The police regularly torture minority suspects during interrogations.",
      null,
      "Fuck the police!",
      "The police are still out there.",
      "Only criminals have reason to fear police.")
    ..noProfanityStupidPrompt =
        "[The police are not doing their job very well!]",
  Law.privacy: _DiscussionPoint(
      "Files are being kept on innocent citizens whose only crime is to",
      "speak out against a system that is trying to farm them like beasts.",
      "Better watch what you say.  They've got ears everywhere.",
      "The government runs intelligence agencies.",
      "National security is important."),
  Law.deathPenalty: _DiscussionPoint(
      "Over thirty innocent people have been executed over the past decade.",
      null,
      "They executed this one dude, and like, his head caught on fire.",
      "You can go to prison for life for serious crimes.",
      "Some people deserve to die."),
  Law.nuclearPower: _DiscussionPoint(
      "Radioactive waste is being stored all over the country, and it poses",
      "a serious threat to many families, even in this neighborhood.",
      "Have you seen Godzilla?  Nuclear power is bad, yo.",
      "Some people support legalizing nuclear power.",
      "Nuclear power is clean."),
  Law.pollution: _DiscussionPoint(
      "Industries that stop at nothing to become more profitable are polluting",
      "the environment in ways that hurt not only humans, but animals too.",
      "You wanna look like the Toxic Avenger?  Oppose pollution!",
      "We're still polluting a little bit.",
      "It's not that bad."),
  Law.labor: _DiscussionPoint(
      "Have you noticed how people are working more and more hours for less and",
      "less money?  It's all part of a plan to keep you enslaved, man.",
      "Conservatives want to make babies work!",
      "Corporate bosses don't always give in to unions.",
      "Trust the free market, it hasn't failed us yet."),
  Law.lgbtRights: _DiscussionPoint(
      "Trans people are just like anyone else, and yet they are treated in this",
      "country as if they are deviants fit only for cheap entertainment.",
      "The man won't say trans rights!",
      "Not everybody likes trans people.",
      "I hate trans people."),
  Law.corporate: _DiscussionPoint(
      "Corporate executives use giant corporations as a means to become parasites",
      "that suck wealth out of this country and put it into their pockets.",
      "The corporations are putting you down, dude.",
      "There are corporations.",
      "Corporations are part of capitalism."),
  Law.freeSpeech: _DiscussionPoint(
      "Protests and demonstrations are regularly and often brutally suppressed in",
      "this country.  People have to watch what they write -- even what they read.",
      "The government won't let me fucking swear!",
      "People get mad if you swear a lot in public.",
      "Don't be offensive and you'll be fine.")
    ..noProfanityStupidPrompt = "The government won't let me [kindly] swear!",
  Law.flagBurning: _DiscussionPoint(
      "Burning a piece of cloth is actually stigmatized in this country.",
      "You can love freedom and still hate what our government stands for.",
      "The flag is stupid.",
      "The flag code says you shouldn't make it into clothing.",
      "That flag is the sacred symbol of our country.")
    ..noProfanityStupidPrompt = "[I feel sad when I see our flag.]",
  Law.gunControl: _DiscussionPoint(
      "We live in such a backwards country right now that people think it's",
      "a right to walk around with the power to murder at any moment.",
      "Guns *kill* people.",
      "We need to repeal the second amendment.",
      "Without guns, we're slaves to the Government."),
  Law.taxes: _DiscussionPoint(
      "The tax code has been designed to perpetuate an unjust class",
      "structure that is keeping you oppressed.",
      "Rich people, like, have money, man.",
      "There's still inequality in this country.",
      "I want to pay lower taxes."),
  Law.genderEquality: _DiscussionPoint(
      "Sexism is still pervasive, in subtle ways, and women make much less",
      "than they deserve for their labor.",
      "We need more women!",
      "Some people are sexist.",
      "Why don't you go burn a bra or something?"),
  Law.civilRights: _DiscussionPoint(
      "Despite our progress, this society is still strangled by its continuing",
      "legacy of racial discrimination and inequality.",
      "Conservatives are all racists!",
      "I knew some people that were pretty racist.",
      "Reverse discrimination is still discrimination."),
  Law.drugs: _DiscussionPoint(
      "The government's drug policy is a mess.  We need to stop filling",
      "prisons with drug users, and only intervene when people really need help.",
      "Dude, the government won't let you do drugs.",
      "Drugs are expensive.",
      "Drugs are a terrible influence on society."),
  Law.immigration: _DiscussionPoint(
      "Millions of people are doing jobs most folks don't even want, and",
      "saving their families from poverty, but we just try to kick them out.",
      "They're all trying to keep people out of the country.",
      "All the immigrants, not everybody likes them.",
      "Immigration undermines our economy and culture."),
  Law.elections: _DiscussionPoint(
      "Political favors are bought and sold for campaign contributions,",
      "and the voting system enforces two party dominance.",
      "The politicians are just tools of the corporations!",
      "Some of these politicians rub me the wrong way.",
      "Unregulated campaigning is a matter of free speech."),
  Law.military: _DiscussionPoint(
      "Take a breath and think about the world we live in, that we're spending",
      "hundreds of billions on new ways to kill people.  This has to stop!",
      "Patriots are idiots! Give peace a chance!",
      "We still have a military.",
      "The military protects us and enables our way of life."),
  Law.torture: _DiscussionPoint(
      "In the name of national security, we've sacrificed our soul by letting",
      "the government torture and abuse human beings on our behalf",
      "Torture is bad!",
      "Some conservatives support torture.",
      "The terrorists would do worse to us."),
  Law.prisons: _DiscussionPoint(
      "The prison system doesn't help criminals by providing rehabilitation, so",
      "when they get released, they mostly become criminals again.",
      "Prisoners don't have freedom!",
      "Prisons still exist.",
      "Criminals deserve what they get in prison."),
};
