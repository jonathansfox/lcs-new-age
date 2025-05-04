import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/dice.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/hostages/tend_hostage.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> handleLoveBombing(
    InterrogationSession intr, Creature lead, Creature cr, int y) async {
  double rapportTemp = intr.rapport[lead.id] ?? 0;
  int attack = lead.skill(Skill.psychology) * 2;
  attack += Dice.r2d6.roll();
  attack += cr.daysSinceJoined;

  if (intr.techniques[Technique.props] == true) attack += 10;
  attack += (rapportTemp * 2).round();

  String message;
  if (intr.techniques[Technique.props] == true) {
    List<String> miniOptions = [
      "protest sign workshop",
      "drag show",
      "puppet show",
      "movie showing",
      "yoga session",
      "speech",
      "poetry slam",
      "chill session",
      "fashion show",
      "big hug",
      "miniature concert",
      "book reading",
      "feast",
      "mock protest",
      "board game",
      "live chicken",
    ];
    message = "${lead.name} ${[
      "serves ${cr.name} an incredible vegan feast, complete with quinoa "
          "casserole and an oat milk latte, insisting that ${cr.gender.heShe} "
          "try it all while ${lead.name} explains the comparative carbon "
          "footprint of the ingredients and contrasts this against the "
          "carbon footprint of a traditional meat-based meal.",
      "holds an in-depth microaggression workshop with ${cr.name}, engaging "
          "${cr.gender.himHer} in a series of elaborate role-playing scenarios "
          "where they dissect even the most innocuous phrases for hidden biases "
          "and discuss how this impacts ${cr.name} and others around them.",
      "puts together a poetry slam for ${cr.name}, where at first ${lead.name} "
          "reads some of ${lead.gender.hisHer} own poetry before ${cr.name} "
          "is given the stage to join in with several verses of ${cr.gender.hisHer} own, "
          "to be followed by a long discussion about the poetic form and the "
          "lived experiences that feed into their respective verses.",
      "holds a mock protest to bring ${cr.name} into the movement in spirit, "
          "starting with an extended planning session where they pick out "
          "phrases and put together protest signs about issues that really "
          "matter to ${cr.gender.himHer}.",
      "holds a movie night with ${cr.name}, with a marathon of documentaries "
          "on topics like renewable energy and intersectionality, pausing "
          "frequently for collaborative discussions on \"what it all means\".",
      "has ${cr.name} brainstorm protest sign ideas on issues that matter to "
          "${cr.gender.himHer}, then helps ${cr.gender.himHer} to "
          "put together a sign ${cr.gender.heShe} can take out into the street "
          "once ${cr.name} is released.",
      "puts on a drag brunch for ${cr.name}, encouraging ${cr.gender.himHer} to "
          "embrace self-expression and self-love through glitter, pancakes, "
          "and RuPaul quotes.",
      "sets up a supervised drug experimentation day for ${cr.name}, with a "
          "variety of substances to try, including Cannabis, LSD, MDMA, "
          "and psilocybin, making sure that ${cr.gender.heShe} is "
          "comfortable with the process and has a safe space to explore "
          "altered states of consciousness while minimizing risk to "
          "${cr.gender.hisHer} health.",
      "assigns ${cr.name} a stack of progressive literature, focused on readings "
          "from bell hooks, Audre Lorde, and other feminist icons, so ${cr.gender.heShe} "
          "can break through the barriers of ${cr.gender.hisHer} old mindset "
          "and start to understand the importance of intersectional feminism.",
      "assigns ${cr.name} a stack of progressive literature, focused on readings "
          "from Ngũgĩ wa Thiong'o, Edward Said, and other postcolonial theorists, "
          "so ${cr.gender.heShe} can start to understand the importance of "
          "decolonizing ${cr.gender.hisHer} mind.",
      "assigns ${cr.name} a stack of progressive literature, focused on readings "
          "from Angela Davis, Frantz Fanon, and other revolutionary thinkers, "
          "so ${cr.gender.heShe} can start to understand some of the ideas "
          "that underpin revolutionary left-wing politics.",
      "assigns ${cr.name} a stack of progressive literature, focused on readings "
          "from Peter Kropotkin, Emma Goldman, and other anarchist thinkers, "
          "so ${cr.gender.heShe} can start to question the absolute authority "
          "of the state and the need for a more just and equitable society.",
      "assigns ${cr.name} a stack of progressive literature, focused on readings "
          "from Judith Butler, Michel Foucault, and other queer theorists, "
          "so ${cr.gender.heShe} can start to understand the politics of "
          "queer liberation and the fight against gender-based oppression.",
      "holds a mandatory self-care bootcamp for ${cr.name}, complete with yoga "
          "sessions, aromatherapy, and journaling prompts like \"What does "
          "your political inner child look like?\"",
      "hosts a \"paint your feelings\" session for ${cr.name}, where ${cr.gender.heShe} "
          "is encouraged to express the flaws in ${cr.gender.hisHer} ideology "
          "through abstract art, with no judgment or critique, but a deep "
          "compassion.",
      "organizes a personalized concert of protest-inspired music, inviting "
          "${cr.name} to join in on the harmonies, with a focus on uplifting "
          "songs about love and unity early in the session, and then moving "
          "into more complex and forceful pieces as the session progresses.",
      "holds an inclusive fashion show for ${cr.name}, where ${cr.gender.heShe} "
          "can try on a variety of outfits that challenge traditional gender "
          "norms and incorporate elements of niche subcultures, each item "
          "linked to a discussion about the history and significance of the "
          "style and the subculture it comes from.",
      "brings in gardening supplies and teaches ${cr.name} how to grow ${cr.gender.hisHer} own "
          "food, narrating how sowing literal seeds of change mirrors the "
          "LCS's mission to uproot harmful ideologies.",
      "builds an intricate escape room for ${cr.name}, full of puzzles about "
          "systemic inequality, where ${cr.gender.heShe} can only solve each "
          "puzzle by first escaping ${cr.gender.hisHer} old mindset.",
      "stages a puppet show for ${cr.name}, featuring characters like "
          "Karl Marx and Rosa Luxemburg in a series of skits about the "
          "history of the LCS and the importance of revolutionary "
          "politics.",
      "throws a holiday party for ${cr.name} celebrating ${[
        "Intersectional Justice Jubilee",
        "Hug-Your-Haters Day",
        "Intersectionality Awareness Day",
        "Queer Liberation Day",
        "Decolonization Day",
        "Anarchist Abolitionist Day",
        "Feminist Resistance Day",
        "Trans Unity Day",
        "Rainbow Butterfly Day",
        "Incredible Inclusivity Day",
        "Black Power Day",
        "African Roots Day",
        "Black And Proud Day",
        "Black Lives Do In Fact Matter Day",
        "Love Wins Day",
        "Liberalism Day",
        "Leftist Pride Day",
        "Social Justice Day",
        "Adopt-A-Conservative Day",
        "Fuck The Police Day",
        "Radical Self-Care Day",
        "Resistance Day",
        "Even Prouder Pride Day",
        "I'm A Liberal Day",
        "Damn It's Good To Be A Liberal Day",
        "Liberalism Is The New Black Day",
        "Join The LCS Day",
        "Stop Being A Conservative Day",
      ].random}, complete with a ${miniOptions.randomPop()}, a ${miniOptions.randomPop()}, and a ${miniOptions.randomPop()}.",
      "gives ${cr.name} a live chicken to hold while ${lead.name} plays "
          "a series of undercover videos of factory farms and slaughterhouses "
          "for ${cr.gender.himHer}, then encourages ${cr.gender.himHer} to "
          "get in touch with ${cr.gender.hisHer} true feelings.",
    ].random}";
  } else {
    message = "${lead.name} ${[
      "raves about how good vegan food is to ${cr.name}.",
      "explains microaggressions to ${cr.name}.",
      "recites some spoken word poetry for ${cr.name}.",
      "quizzes ${cr.name} about correct recycling habits.",
      "enthuses about the benefits of regular meditation to ${cr.name} "
          "and offers to teach ${cr.gender.himHer} how to do it.",
      "shows ${cr.name} pictures of people having fun at a protest and "
          "suggests ${cr.gender.heShe} would get a lot out of it.",
      "describes a progressive film to ${cr.name} and tells ${cr.gender.himHer} "
          "about what it means.",
      "tells ${cr.name} about some clever protest signs people have come up "
          "with in the past.",
      "tells ${cr.name} how much fun drag shows are and offers to answer "
          "any questions ${cr.gender.himHer} has about them.",
      "recommends ${cr.name} read some theory when ${cr.gender.heShe} gets "
          "a chance, and tries to explain some of the complex ideas "
          "from memory.",
      "asks ${cr.name} \"What does your political inner child look like?\"",
      "tries to do a guided meditation with ${cr.name}, and asks "
          "${cr.gender.himHer} to visualize ${cr.gender.hisHer} feelings "
          "like a painting.",
      "plays a selection of protest songs on ${lead.gender.hisHer} cell "
          "phone and asks ${cr.gender.himHer} what ${cr.gender.heShe} thinks "
          "they mean.",
      "challenges ${cr.name} to imagine a world without posessions, and "
          "wonders if ${cr.gender.heShe} can.",
      "suggests ${cr.name} would look good in a hemp tunic.",
      "says ${cr.name} would could be a totally epic left-wing punk rebel "
          "if ${cr.gender.heShe} is interested in that sort of thing.",
      "tells ${cr.name} about the importance of intersectionality.",
      "explains to ${cr.name} that fair trade coffee actually tastes better "
          "and is better for the world.",
      "works with ${cr.name} to imagine the best possible world.",
      "asks ${cr.name} to imagine a world without prisons, and tries to "
          "engage ${cr.gender.himHer} in a discussion about how "
          "conflicts would be resolved if locking people away wasn't "
          "an option.",
      "asks ${cr.name} to imagine a world without borders, where moving "
          "between countries is as easy as moving between cities.",
      "tries to help ${cr.name} escape ${cr.gender.hisHer} old mindset.",
      "encourages ${cr.name} to admit ${cr.gender.hisHer} past mistakes, "
          "everything ${cr.gender.heShe} feels guilty or ashamed of, "
          "so ${lead.gender.heShe} can show unconditional acceptance and "
          "understanding of them instead of the rejection ${cr.name} was "
          "expecting.",
    ].random}";
  }
  addparagraph(y, 0, message);
  y = console.y + 1;

  await getKey();

  //Target is swayed by Liberal Reason -- skilled interrogators, time held,
  //and rapport contribute to the likelihood of this
  int marginOfSuccess = cr.attribute(Attribute.wisdom) * 2 +
      cr.skill(Skill.business) +
      cr.skill(Skill.religion) +
      cr.skill(Skill.science) +
      cr.skill(Skill.psychology) * 2;
  if (marginOfSuccess < attack) {
    // Reduce juice if any is there
    if (cr.juice > 0) {
      cr.juice -= marginOfSuccess;
      if (cr.juice < 0) cr.juice = 0;
    } else if (cr.juice == 0) {
      // Otherwise, modify heart and wisdom when juice is 0
      if (cr.attribute(Attribute.wisdom) > 1) {
        cr.adjustAttribute(Attribute.wisdom, -1);
      }
      if (cr.attribute(Attribute.heart) < 10) {
        cr.adjustAttribute(Attribute.heart, 1);
      }
    }

    //Improve rapport with interrogator
    intr.rapport.update(lead.id, (v) => v + 1 + lcsRandom(5) * 0.2,
        ifAbsent: () => 1 + lcsRandom(5) * 0.2);

    mvaddstr(y++, 0, cr.name);
    addstr([
      "'s Conservative beliefs are shaken.",
      " quietly considers these ideas.",
      " is beginning to see Liberal reason.",
      " has a revelation of understanding.",
      " grudgingly admits sympathy for LCS ideals.",
      " is beginning to see the error of ${cr.gender.hisHer} ways.",
      " is beginning to understand where the LCS is coming from.",
      " never really thought about things this way before.",
    ].random);

    await getKey();
  }
  //Target is not sold on the LCS arguments and holds firm
  //This is the worst possible outcome if you use props
  else if (!cr.skillCheck(
          Skill.psychology, lead.attribute(Attribute.heart) + 5) ||
      intr.techniques[Technique.props] == true) {
    //Loses rapport
    intr.rapport.update(lead.id, (v) => v - 0.2 - lcsRandom(5) * 0.1,
        ifAbsent: () => -0.2 - lcsRandom(5) * 0.1);

    String description;
    if (rapportTemp > lcsRandom(3) ||
        cr.skill(Skill.psychology) > lead.skill(Skill.psychology)) {
      if (cr.skill(Skill.psychology) > lead.skill(Skill.psychology)) {
        description = [
          "${cr.name} plays along but somehow makes everything seem so "
              "silly and trivial.",
          "${lead.name} somehow ends up on the defensive as ${cr.name} calls "
              "out every manipulative comment ${lead.gender.heShe} makes "
              "in the effort to get ${cr.gender.himHer} to change "
              "${cr.gender.hisHer} views.",
          "${cr.name} sardonically critiques this \"recruitment strategy\" "
              "of love bombing hostages until they think this miserable "
              "existence as a criminal on the fringes of society is somehow "
              "better than the alternative.",
          "${cr.name} suggests ${lead.name} should see a therapist to deal "
              "with ${lead.gender.hisHer} issues instead of kidnapping and "
              "brainwashing people.",
          "${cr.name} offers some sardonically deadpan advice on how "
              "${lead.name} could make this more coercive and convincing.",
          "${cr.name} keeps asking ${lead.name} the same questions for "
              "some reason and it's just pissing ${lead.gender.himHer} off.",
          "${cr.name} dismisses the activities and asks some rather "
              "rather uncomfortable questions about ${lead.name}'s past.",
        ].random;
        lead.train(Skill.psychology, cr.skill(Skill.psychology) * 4);
        intr.rapport[lead.id] =
            (intr.rapport[lead.id] ?? 0) - lcsRandom(10) * 0.1;
      } else if (cr.skill(Skill.religion) > lead.skill(Skill.religion)) {
        description = [
          "${lead.name} is unable to shake ${cr.name}'s religious conviction.",
          "${cr.name} draws strength from God.",
          "${lead.name}'s efforts to shake ${cr.name}'s faith seem futile.",
          "${cr.name} explains the Conservative tenets of ${cr.gender.hisHer} faith.",
          "${cr.name} praises the Lord for this moment to converse.",
          "${cr.name} prays that health finds them both.",
          "${cr.name} asks ${lead.name} if ${lead.gender.heShe} ever think${lead.gender.s} about Jesus.",
        ].random;
        lead.train(Skill.religion, cr.skill(Skill.religion) * 4);
      } else if (cr.skill(Skill.business) > lead.skill(Skill.business)) {
        description = [
          "${cr.name} offers to make a deal.",
          "${cr.name} asks if there's a ransom.",
          "${cr.name} asks if the LCS plans to make money from kidnapping.",
          "${cr.name} suggests the interrogation room could be better decorated.",
          "${cr.name} explains the basics of supply and demand.",
          "${cr.name} talks about economic theory.",
          "${cr.name} mounts a defense of Reaganomics.",
          "${cr.name} talks about the importance of the free market.",
          "${cr.name} explains the importance of capitalism.",
          "${cr.name} professes faith in the invisible hand.",
        ].random;
        lead.train(Skill.business, cr.skill(Skill.business) * 4);
      } else {
        description = [
          "The conversation is polite.",
          "${cr.name} engages but is not swayed.",
          "${cr.name} is not convinced.",
          "${cr.name} asks questions, but seems unmoved.",
          "${cr.name} teases ${lead.name} a bit.",
          "${cr.name} asks for ${[
            "coffee",
            "tea",
            "water",
            "a burger",
          ].random}.",
          "${cr.name} explains why ${cr.gender.heShe} disagrees.",
          "${cr.name} debates the points raised.",
        ].random;
      }
    } else {
      description = [
        "${cr.name} just stares.",
        "${cr.name} demands to be released.",
        "${cr.name} refuses to speak.",
        "${cr.name} yells at ${lead.name}.",
        "${cr.name} huffs indignantly.",
        "${cr.name} insults ${lead.name}.",
        "${cr.name} looks at the walls.",
        "${cr.name} ignores ${lead.name}.",
      ].random;
    }
    addparagraph(y, 0, description);
    y = console.y + 1;
    await getKey();
  }
  //Target actually wins the argument so successfully that the Liberal
  //interrogator's convictions are the ones that are shaken
  else {
    //Consolation prize is that they end up liking each other more
    intr.rapport.update(lead.id, (v) => v + 1.5, ifAbsent: () => 1.5);

    lead.adjustAttribute(Attribute.wisdom, 1);

    addparagraph(
        y,
        0,
        "${cr.name} makes some fascinating points that ${lead.name} has "
        "never considered before...");
    y = console.y + 1;

    mvaddstrc(y++, 0, red, "${lead.name} has been tainted with wisdom!");
    await getKey();
  }
}
