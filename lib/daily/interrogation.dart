import 'dart:math';

import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/conversion.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/dice.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/advance_day.dart';
import 'package:lcs_new_age/daily/recruitment.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

part 'interrogation.g.dart';

@JsonSerializable()
class InterrogationSession {
  InterrogationSession(this.hostageId);
  factory InterrogationSession.fromJson(Map<String, dynamic> json) =>
      _$InterrogationSessionFromJson(json);
  Map<String, dynamic> toJson() => _$InterrogationSessionToJson(this);

  @JsonKey(name: 'creatureId')
  int hostageId;
  @JsonKey(includeToJson: false)
  Creature get hostage => pool.firstWhere((e) => e.id == hostageId);
  Map<Technique, bool> techniques = {};
  Map<int, double> rapport = {};
  int daysOfDrugUse = 0;
}

enum Technique {
  talk,
  restrain,
  beat,
  props,
  drugs,
  kill,
}

Future<void> tendHostage(InterrogationSession intr) async {
  Creature cr = intr.hostage;
  var rapport = intr.rapport;
  var techniques = intr.techniques;
  List<Creature> tenders = [];

  void addRapport(Creature c, double value) {
    rapport.update(c.id, (v) => v + value, ifAbsent: () => value);
  }

  //Find all tenders who are set to this hostage
  for (Creature p in pool) {
    if (!p.alive) continue;
    if (p.activity.type == ActivityType.interrogation &&
        p.activity.idInt == cr.id) {
      //If they're in the same location as the hostage,
      //include them in the interrogation
      if (p.location == cr.location && p.location != null) {
        tenders.add(p);
      } else {
        //If they're someplace else, take them off the job
        p.activity = Activity.none();
      }
    }
  }

  if (cr.location == null) {
    pool.remove(cr);
    return;
  }

  //possible hostage escape attempt if unattended or unrestrained
  if (tenders.isEmpty || techniques[Technique.restrain] == false) {
    //CHECK FOR HOSTAGE ESCAPE
    if (lcsRandom(200) + 25 * tenders.length <
        cr.attribute(Attribute.intelligence) / 2 +
            cr.attribute(Attribute.agility) / 2 +
            cr.attribute(Attribute.strength) / 2 +
            cr.daysSinceJoined * 2) {
      await showMessage("${cr.name} has escaped!");
      cr.site?.siege.timeUntilCops = 3;

      //clear activities for tenders
      for (int i = 0; i < pool.length; i++) {
        if (!pool[i].alive) continue;
        if (pool[i].activity.type == ActivityType.interrogation &&
            pool[i].activity.idInt == cr.id) {
          pool[i].activity = Activity.none();
        }
      }

      pool.remove(cr);
      return;
    }

    if (tenders.isEmpty) return;
  }

  erase();
  mvaddstrc(
      0, 0, white, "The Education of ${cr.name}: Day ${cr.daysSinceJoined}");

  await getKey();

  setColor(lightGray);

  bool turned = false;

  int y = 3;

  //each day, the attack roll is initialized to the number of days of the stay with
  //the LCS -- they will eventually break, but also eventually become too traumatized
  //to continue
  int business = 0, religion = 0, science = 0, attack = 0;

  List<int> tenderAttack = [for (Creature _ in tenders) 0];

  for (int p = 0; p < tenders.length; p++) {
    Creature tempp = tenders[p];
    business = max(tempp.skill(Skill.business), business);
    religion = max(tempp.skill(Skill.religion), religion);
    science = max(tempp.skill(Skill.science), science);

    tenderAttack[p] =
        tempp.attribute(Attribute.heart) + tempp.skill(Skill.psychology) * 2;

    tenderAttack[p] += tempp.clothing.type.interrogationBasePower;

    if (tenderAttack[p] < 0) tenderAttack[p] = 0;
    if (tenderAttack[p] > attack) attack = tenderAttack[p];
  }

  attack += Dice.r2d10avg.roll();

  List<int> goodp = [];

  for (int p = 0; p < tenders.length; p++) {
    Creature tempp = tenders[p];
    if (tempp.alive && tenderAttack[p] == attack) {
      goodp.add(p);
    }
  }
  Creature lead = tenders[goodp.random];
  void selectNewLead() {
    tenders.removeWhere((e) => e.activity.type != ActivityType.interrogation);
    if (tenders.isNotEmpty) {
      lead = tenders.random;
    }
  }

  attack += tenders.length;
  attack += cr.daysSinceJoined;

  attack += business - cr.skill(Skill.business);
  attack += religion - cr.skill(Skill.religion);
  attack += science - cr.skill(Skill.science);
  attack -= cr.skill(Skill.psychology);

  attack += cr.attribute(Attribute.heart);
  attack -= cr.attribute(Attribute.wisdom);

  while (true) {
    y = 2;
    if (techniques[Technique.kill] == true) {
      setColor(red);
      move(y, 0);
      y += 2;
      addstr("The Execution of an Automaton         ");
    } else {
      setColor(yellow);
      move(y, 0);
      y += 2;
      addstr("Selecting a Liberal Interrogation Plan");
    }

    void planItem(
        Technique technique, String letter, String ifActive, String ifInactive,
        {String? cost}) {
      move(y++, 0);
      if (techniques[Technique.kill] == true) {
        setColor(darkGray);
      } else if (techniques[technique] == true) {
        setColor(white);
      } else {
        setColor(lightGray);
      }
      if (techniques[technique] == true) {
        addstr("$letter - $ifActive");
      } else {
        addstr("$letter - $ifInactive");
      }
      if (cost != null) {
        mvaddstr(y - 1, 33 - cost.length, cost);
      }
    }

    planItem(Technique.talk, "A", "Attempt to Convert", "No Verbal Contact ");
    planItem(Technique.restrain, "B", "Physical Restraints   ",
        "No Physical Restraints");
    planItem(
        Technique.beat, "C", "Violently Beaten    ", "Not Violently Beaten");
    planItem(Technique.props, "D", "Expensive Props   ", "No Expensive Props",
        cost: "(\$250)");
    planItem(Technique.drugs, "E", "Hallucinogenic Drugs   ",
        "No Hallucinogenic Drugs",
        cost: "(\$50)");
    setColor(techniques[Technique.kill] ?? false ? red : lightGray);
    addOptionText(y, 0, "K", "K - Kill the Hostage");
    y += 2;
    addOptionText(y++, 0, "Enter", "Enter - Confirm the Plan");

    showInterrogationSidebar(intr, lead);

    int c = await getKey();
    if (c >= Key.a && c <= Key.e) {
      Technique technique = Technique.values[c - Key.a];
      techniques[technique] = !(techniques[technique] ?? false);
    }
    if (c == Key.k) {
      techniques[Technique.kill] = !(techniques[Technique.kill] ?? false);
    }
    if (isBackKey(c)) break;
  }

  if (techniques[Technique.props] == true && ledger.funds >= 250) {
    ledger.subtractFunds(250, Expense.hostageTending);
  } else {
    techniques[Technique.props] = false;
  }
  if (techniques[Technique.drugs] == true && ledger.funds >= 50) {
    ledger.subtractFunds(50, Expense.hostageTending);
  } else {
    techniques[Technique.drugs] = false;
  }

  if (techniques[Technique.kill] == true) // Kill the Hostage
  {
    erase();
    mvaddstrc(0, 0, white,
        "The Final Education of ${cr.name}: Day ${cr.daysSinceJoined}");
    Creature? killer;

    for (int i = 0; i < tenders.length; i++) {
      if (lcsRandom(50) < tenders[i].juice ||
          lcsRandom(9) + 1 >=
              (tenders[i].rawAttributes[Attribute.heart] ?? 0)) {
        killer = tenders[i];
        break;
      }
    }

    if (killer != null) {
      //delete interrogation information
      setColor(purple);
      cr.die();
      stats.kills++;
      mvaddstr(y++, 0, "${lead.name} executes ${cr.name} by ");
      addstr([
        "strangling it to death.",
        "beating it to death.",
        "burning photos of Trump in front of it.",
        "telling it that taxes have been increased.",
        "telling it its parents wanted to abort it.",
        "administering a lethal dose of opiates.",
      ].random);

      await getKey();

      y = await traumatize(lead, "execution", y);
      if (lead.activity.type == ActivityType.none) {
        selectNewLead();
      }
    } else {
      setColor(brown);
      mvaddstr(y++, 0, "There is no one able to get up the nerve to ");
      mvaddstr(y++, 0, "execute ${cr.name} in cold blood.");

      await getKey();

      //Interrogation will continue as planned, with
      //these restrictions:
      techniques[Technique.talk] = false; //don't talk to them today
      techniques[Technique.beat] = false; //don't beat them today
      techniques[Technique.drugs] = false; //don't administer drugs

      //Food and restraint settings will be applied as normal
    }
    //show_interrogation_sidebar(cr,a);

    mvaddstrc(24, 0, lightGray, "Press any key to reflect on this.");

    await getKey();

    if (!cr.alive) {
      for (Creature p in pool) {
        if (!p.alive) continue;
        if (p.activity.type == ActivityType.interrogation &&
            p.activity.idInt == cr.id) {
          p.activity = Activity.none();
        }
      }
      return;
    }
  }

  erase();
  mvaddstrc(
      0, 0, white, "The Education of ${cr.name}: Day ${cr.daysSinceJoined}");
  y = 2;
  mvaddstr(y++, 0, "The Automaton");
  if (techniques[Technique.restrain] == true) {
    // Restraint
    addstr(" is tied hands and feet to a metal chair");
    mvaddstr(y++, 0, "in the middle of a back room.");
    attack += 5;
  } else {
    addstr(" is locked in a back room ");
    mvaddstr(y++, 0, "converted into a makeshift cell.");
  }
  //show_interrogation_sidebar(cr,a);

  await getKey();

  if (techniques[Technique.drugs] == true) // Hallucinogenic drugs
  {
    mvaddstr(++y, 0, "It is subjected to dangerous hallucinogens.");

    // we won't apply the drug bonus JUST yet
    int drugbonus = 10 + lead.clothing.type.interrogationDrugBonus;
    //Possible permanent health damage
    if (lcsRandom(50) < ++intr.daysOfDrugUse) {
      bool lowHealth = cr.health == 1;
      cr.permanentHealthDamage += 1;
      move(++y, 0);

      await getKey();

      addstr(
          "${cr.name} foams at the mouth and its eyes roll back in its skull.");

      move(++y, 0);

      await getKey();

      Creature doctor = lead; // the lead interrogator is doctor by default
      int maxskill = doctor.skill(Skill.firstAid);
      for (int i = 0; i < tenders.length; i++) // search for the best doctor
      {
        if (tenders[i].skill(Skill.firstAid) > maxskill) {
          doctor = tenders[i];
          maxskill = doctor.skill(Skill.firstAid); // we found a doctor
        }
      }
      if (lowHealth || maxskill == 0) // he's dead, Jim
      {
        if (maxskill > 0) {
          // we have a real doctor but the patient is still dead anyway
          addstr(
              "${doctor.name} administers treatment, but there is nothing ${doctor.gender.heShe} can do.");
        } else {
          addstr("${doctor.name} has a panic attack and ");
          switch (lcsRandom(3)) {
            case 0:
              addstr("faints.");
            case 1:
              addstr("runs away.");
            case 2:
              addstr("just covers ${doctor.gender.hisHer} eyes.");
            case 3:
              if (noProfanity) {
                addstr("[makes a stinky].");
              } else {
                addstr("shits ${doctor.gender.hisHer} pants.");
              }
          }
        }

        move(++y, 0);

        await getKey();

        cr.die();
        setColor(yellow);
        if (maxskill > 0) {
          addstr(
              "${cr.name} dies from a lethal overdose in their weakened state.");
        } else {
          addstr(
              "${cr.name} dies due to ${doctor.name}'s incompetence at first aid.");
          y = await traumatize(doctor, "overdose", ++y);
          if (doctor.activity.type == ActivityType.none && doctor == lead) {
            selectNewLead();
          }
        }
      } else {
        if (doctor.skillCheck(
            Skill.firstAid, Difficulty.hard)) // is the doctor AWESOME?
        {
          doctor.train(Skill.firstAid, 20);
          if (doctor != lead) {
            addstr(
                "${doctor.name} swiftly intervenes and takes control of the interrogation.");
            y++;
            lead = doctor;
          } else {
            addstr("${doctor.name} immediately switches to doctor mode.");
          }
          mvaddstr(y++, 0,
              "${doctor.gender.heSheCap} applies aggressive treatment to flush the drugs from ${cr.name}'s system.");

          await getKey();

          mvaddstr(y++, 0,
              "${cr.name} recovers quickly, with no long-term health damage.");
          mvaddstr(y, 0,
              "${doctor.name} strikes the drug regimen from the schedule for the day.");
          cr.permanentHealthDamage -= 1; // no permanent health damage
          // drugs eliminated from the system
          intr.daysOfDrugUse = 0;
          drugbonus = 0;
          techniques[Technique.drugs] = false;
        } else {
          doctor.train(Skill.firstAid, 10);
          addstr("${doctor.name} steps in to stabilize the situation.");

          move(++y, 0);

          await getKey();

          addstr(cr.name);
          // the patient was out long enough to have a near-death experience
          if (cr.skill(Skill.religion) > 0) {
            addstr(" had a near-death experience and met God in heaven.");
          } else {
            addstr(" had a near-death experience and met John Lennon.");
          }
          // the near-death experience doubles the drug bonus
          drugbonus *= 2;
        }
        // rapport bonus for having life saved by doctor
        addRapport(doctor, 0.5);
      }
    }
    attack += drugbonus; // now we finally apply the drug bonus
    move(++y, 0);
    //show_interrogation_sidebar(cr,a);

    await getKey();
  }

  if (techniques[Technique.beat] == true && !turned && cr.alive) // Beating
  {
    move(++y, 0);

    int forceroll = 0;
    bool tortured = false;

    for (int i = 0; i < tenders.length; i++) {
      //add interrogator's strength to beating strength
      forceroll += tenders[i].attributeRoll(Attribute.strength);
      //reduce rapport with each interrogator
      addRapport(tenders[i], -0.4);
    }

    //Torture captive if lead interrogator has low heart
    //and you funded using extra supplies
    //
    //Yeah, you kinda don't want this to happen
    if (!lead.attributeCheck(Attribute.heart, Difficulty.easy) &&
        techniques[Technique.props] == true) {
      tortured = true;
      //Torture more devastating than normal beating
      forceroll *= 5;
      //Extremely bad for rapport with lead interrogator
      addRapport(lead, -3);

      addstr("${lead.name} ${[
        "re-enacts scenes from Abu Ghraib",
        "whips the Automaton with a steel cable",
        "holds the hostage's head under water",
        "pushes needles under the Automaton's fingernails",
        "beats the hostage with a metal bat",
        "beats the hostage with a belt",
      ].random}");
      addstr(", ");
      mvaddstr(++y, 0, "screaming \"");
      for (int i = 0; i < 2; i++) {
        addstr([
          "I hate you!",
          "Does it hurt?!",
          "Nobody loves you!",
          "God hates you!",
          "Don't fuck with me!",
          "This is Liberalism!",
          "Convert, bitch!",
          "I'm going to kill you!",
          "Do you love me?!",
          "I am your God!",
        ].random);
        if (i < 1) addstr(" ");
      }
      addstr("\" in its face.");

      cr.permanentHealthDamage += 1;
      cr.heartDamage += 1;
    } else {
      if (tenders.length == 1) {
        addstr(tenders[0].name);
        addstr(" beats");
      } else if (tenders.length == 2) {
        addstr(tenders[0].name);
        addstr(" and ");
        addstr(tenders[1].name);
        addstr(" beat");
      } else {
        addstr(cr.name);
        addstr("'s guards beat");
      }
      addstr(" the Automaton");
      if (techniques[Technique.props] == true) {
        switch (lcsRandom(6)) {
          case 0:
            addstr(" with a giant stuffed elephant");
          case 1:
            addstr(" while draped in a Confederate flag");
          case 2:
            addstr(" with a cardboard cutout of Reagan");
          case 3:
            addstr(" with a King James Bible");
          case 4:
            addstr(" with fists full of money");
          case 5:
            addstr(" with Conservative propaganda on the walls");
        }
      }
      addstr(", ");
      move(++y, 0);
      switch (lcsRandom(4)) {
        case 0:
          addstr("scream");
        case 1:
          addstr("yell");
        case 2:
          addstr("shout");
        case 3:
          addstr("holler");
      }
      addstr("ing \"");
      for (int i = 0; i < 3; i++) {
        switch (lcsRandom(20)) {
          case 0:
            addstr("McDonalds");
          case 1:
            addstr("Elon Musk");
          case 2:
            addstr("Mike Pence");
          case 3:
            addstr("Wal-Mart");
          case 4:
            addstr("George W. Bush");
          case 5:
            addstr("ExxonMobil");
          case 6:
            addstr("Ted Cruz");
          case 7:
            addstr("Family values");
          case 8:
            addstr("Conservatism");
          case 9:
            addstr("War on Drugs");
          case 10:
            addstr("Russia");
          case 11:
            addstr("Donald Trump");
          case 12:
            addstr("Tucker Carlson");
          case 13:
            addstr("Tax cuts");
          case 14:
            addstr("Military spending");
          case 15:
            addstr("Sean Hannity");
          case 16:
            addstr("Deregulation");
          case 17:
            addstr("Police");
          case 18:
            addstr("Corporations");
          case 19:
            addstr("Wiretapping");
        }
        if (i < 2) addstr("! ");
      }
      addstr("!\" in its face.");
    }
    y++;

    cr.blood -= (5 + lcsRandom(5)) *
        (1 + (techniques[Technique.props] == true ? 1 : 0));

    //show_interrogation_sidebar(cr,a);

    await getKey();

    if (!cr.attributeCheck(Attribute.wisdom, forceroll)) {
      if (cr.skillCheck(Skill.religion, forceroll)) {
        mvaddstr(y++, 0, cr.name);
        if (techniques[Technique.drugs] != true) {
          switch (lcsRandom(2)) {
            case 0:
              addstr(" prays...");
            case 1:
              addstr(" cries out for God.");
          }
        } else {
          switch (lcsRandom(2)) {
            case 0:
              addstr(" takes solace in the personal appearance of God.");
            case 1:
              addstr(" appears to be having a religious experience.");
          }
        }
      } else if (forceroll >
          cr.attribute(Attribute.wisdom) * 6 +
              cr.attribute(Attribute.heart) * 3) {
        mvaddstr(y++, 0, cr.name);
        switch (lcsRandom(4)) {
          case 0:
            addstr(" screams helplessly for ");
            if (techniques[Technique.drugs] == true) {
              addstr("John Lennon's mercy.");
            } else if (cr.skill(Skill.religion) > 0) {
              addstr("God's mercy.");
            } else {
              addstr("mommy.");
            }
          case 1:
            if (techniques[Technique.restrain] == true) {
              addstr(" goes limp in the restraints.");
            } else {
              addstr(" curls up in the corner and doesn't move.");
            }
          case 2:
            if ((techniques[Technique.drugs] == true && oneIn(5)) ||
                cr.type.dog) {
              addstr(" barks helplessly.");
            } else {
              addstr(" cries helplessly.");
            }
          case 3:
            if (techniques[Technique.drugs] == true && oneIn(3)) {
              addstr(" wonders about apples.");
            } else {
              addstr(" wonders about death.");
            }
        }

        cr.heartDamage += 1;

        if (oneIn(2) && cr.juice > 0) {
          cr.juice = max(0, cr.juice - forceroll);
        } else if (cr.rawAttributes[Attribute.wisdom]! > 1) {
          cr.adjustAttribute(Attribute.wisdom, -forceroll ~/ 10);
          if (cr.rawAttributes[Attribute.wisdom]! < 1) {
            cr.rawAttributes[Attribute.wisdom] = 1;
          }
        }

        Site? workSite =
            cr.workLocation is Site ? cr.workLocation as Site : null;
        if (workSite?.mapped == false && oneIn(5)) {
          //show_interrogation_sidebar(cr,a);

          await getKey();

          mvaddstr(y++, 0,
              "${lead.name} beats information out of the pathetic thing.");

          move(y++, 0);

          await getKey();

          addstr("A detailed map has been created of the ${workSite!.name}.");

          workSite.mapped = true;
          workSite.hidden = false;
        }
      } else {
        mvaddstr(y++, 0, cr.name);
        addstr(" seems to be getting the message.");

        if (cr.juice > 0) if ((cr.juice -= forceroll) < 0) cr.juice = 0;

        if (cr.rawAttributes[Attribute.wisdom]! > 1) {
          cr.adjustAttribute(Attribute.wisdom, -forceroll ~/ 10 - 1);
          if (cr.rawAttributes[Attribute.wisdom]! < 1) {
            cr.rawAttributes[Attribute.wisdom] = 1;
          }
        }
      }

      if (forceroll > cr.health * 5) {
        //show_interrogation_sidebar(cr,a);

        await getKey();

        move(y++, 0);
        if (cr.health > 1) {
          cr.permanentHealthDamage += 1;
          addstr("${cr.name} is badly hurt.");
        } else {
          addstr(
              "${cr.name}'s weakened body crumbles under the brutal assault.");
          cr.die();
        }
        await getKey();
      }
    } else {
      mvaddstr(y++, 0, "${cr.name} takes it well.");
      await getKey();
    }
    //show_interrogation_sidebar(cr,a);

    if (tortured && cr.alive) {
      y = await traumatize(lead, "torture", y);
      if (lead.activity.type == ActivityType.none) {
        selectNewLead();
      }
      setColor(white);
    }
  }

  // Verbal Interrogation
  if (techniques[Technique.talk] == true && cr.alive) {
    double rapportTemp = rapport[lead.id] ?? 0;

    if (techniques[Technique.restrain] != true) attack += 5;
    attack += (rapportTemp * 3).round();

    ++y;
    mvaddstr(y++, 0, lead.name);

    if (techniques[Technique.props] == true) //props
    {
      attack += 10;
      addstr([
        " plays violent video games with ",
        " reads Origin of the Species to ",
        " watches a documentary about police brutality with ",
        " explores an elaborate political fantasy with ",
        " watches controversial avant-garde films with ",
        " plays the anime film Bible Black for ",
        " watches a documentary about Emmett Till with ",
        " watches left-wing video essays with ",
        " listens to Liberal radio shows with ",
      ].random);
    } else {
      switch (lcsRandom(4)) {
        case 0:
          addstr(" talks about ${View.issues.random.label} with ");
        case 1:
          addstr(" argues about ${View.issues.random.label} with ");
        case 2:
          addstr(" tries to expose the true Liberal side of ");
        case 3:
          addstr(" attempts to recruit ");
      }
    }
    addstr(cr.name);
    addstr(".");

    //Hallucinogenic drugs:
    //Re-interprets lead interrogator
    if (techniques[Technique.drugs] == true) {
      //show_interrogation_sidebar(cr,a);

      await getKey();

      move(y++, 0);
      if (cr.skillCheck(Skill.psychology, Difficulty.challenging)) {
        addstr("${cr.name} ${[
          "takes the drug-induced hallucinations with stoicism.",
          "mutters its initials over and over again.",
          "babbles continuous numerical sequences.",
          "manages to remain grounded through the hallucinations.",
        ].random}");
      } else if ((rapportTemp > 1 && oneIn(3)) || oneIn(10)) {
        rapportTemp = 10;
        switch (lcsRandom(4)) {
          case 0:
            addstr(
                "${cr.name} gasps as ${lead.name} is revealed to be an angel.");
          case 1:
            addstr(
                "${cr.name} looks at ${lead.name} and deep truths are revealed.");
          case 2:
            addstr("${cr.name} stammers and ");
            if (techniques[Technique.restrain] == true) {
              addstr("talks about hugging ");
            } else {
              addstr("hugs ");
            }
            addstr("${lead.name}.");
          case 3:
            addstr(
                "${cr.name} begs ${lead.name} to let the colors stay forever.");
        }
      } else if ((rapportTemp < -1 && oneIn(3)) || oneIn(5)) {
        attack = 0;
        switch (lcsRandom(4)) {
          case 0:
            addstr(
                "${cr.name} screams in horror as ${lead.name} devours its soul.");
          case 1:
            addstr(cr.name);
            if (techniques[Technique.restrain] != true) {
              addstr(" curls up and");
            }
            addstr(" begs for the nightmare to end.");
          case 2:
            addstr(
                "${cr.name} screams as ${lead.name} shifts from one demonic form to another.");
          case 3:
            if ((rapport[lead.id] ?? 0) < -3) {
              addstr("${cr.name} begs Hitler to stay and kill ${lead.name}.");
            } else {
              addstr(
                  "${cr.name} screams at ${lead.name} to stop looking like Hitler.");
            }
        }
      } else {
        switch (lcsRandom(4)) {
          case 0:
            addstr(
                "${cr.name} comments on the swirling light ${lead.name} is radiating.");
          case 1:
            addstr("${cr.name} can't stop looking at the moving colors.");
          case 2:
            addstr(
                "${cr.name} laughs hysterically at ${lead.name}'s altered appearance.");
          case 3:
            if (cr.type.dog) {
              addstr("${cr.name} meows and purrs like a cat.");
            } else {
              addstr("${cr.name} barks and woofs like a dog.");
            }
        }
      }
    }

    //show_interrogation_sidebar(cr,a);

    await getKey();

    if (cr.skill(Skill.psychology) > lead.skill(Skill.psychology)) {
      move(y++, 0);
      switch (lcsRandom(4)) {
        case 0:
          addstr("${cr.name} plays mind games with ${lead.name}.");
        case 1:
          addstr("${cr.name} knows how this works, and won't budge.");
        case 2:
          addstr("${cr.name} asks if Liberal mothers would approve of this.");
        case 3:
          addstr("${cr.name} seems resistant to this form of interrogation.");
      }
    }
    //Attempt to convert when the target is brutally treated will
    //just alienate them and make them cynical
    else if (techniques[Technique.beat] == true || rapportTemp < -2) {
      mvaddstr(y++, 0, cr.name);
      switch (lcsRandom(7)) {
        case 0:
          addstr(" babbles mindlessly.");
        case 1:
          addstr(" just whimpers.");
        case 2:
          addstr(" cries helplessly.");
        case 3:
          addstr(" is losing faith in the world.");
        case 4:
          addstr(" only grows more distant.");
        case 5:
          addstr(" is too terrified to even speak to ${lead.name}.");
        case 6:
          addstr(" just hates the LCS even more.");
      }

      if (lead.skillCheck(Skill.seduction, Difficulty.challenging)) {
        //show_interrogation_sidebar(cr,a);

        await getKey();

        mvaddstr(y++, 0, lead.name);
        switch (lcsRandom(7)) {
          case 0:
            addstr(" consoles the Conservative automaton.");
          case 1:
            addstr(" shares some chocolates.");
          case 2:
            addstr(" provides a shoulder to cry on.");
          case 3:
            addstr(" understands ${cr.name}'s pain.");
          case 4:
            addstr("'s heart opens to the poor Conservative.");
          case 5:
            addstr(" helps the poor thing to come to terms with captivity.");
          case 6:
            addstr(
                "'s patience and kindness leaves the Conservative confused.");
        }

        addRapport(lead, 0.7);
        if ((rapport[lead.id] ?? 0) > 3) {
          //show_interrogation_sidebar(cr,a);

          await getKey();

          mvaddstr(y++, 0, cr.name);
          addstr([
            " emotionally clings to ${lead.name}'s sympathy.",
            " begs ${lead.name} for help.",
            " promises to be good.",
            " reveals childhood pains.",
            " thanks ${lead.name} for being merciful.",
            " cries in ${lead.name}'s arms.",
            " really likes ${lead.name}.",
          ].random);

          if ((rapport[lead.id] ?? 0) > 5) turned = true;
        }
      }

      if (cr.attribute(Attribute.heart) > 1) {
        cr.adjustAttribute(Attribute.heart, -1);
      }
    }
    //Failure to break religious convictions
    else if (cr.skill(Skill.religion) >
            religion + lead.skill(Skill.psychology) &&
        techniques[Technique.drugs] != true) {
      move(y++, 0);
      addstr([
        "${lead.name} is unable to shake ${cr.name}'s religious conviction.",
        "${lead.name} will never be broken so long as God grants it strength.",
        "${lead.name}'s efforts to question ${cr.name}'s faith seem futile.",
        "${lead.name} calmly explains the Conservative tenets of its faith.",
      ].random);
      lead.train(Skill.religion, cr.skill(Skill.religion) * 4);
    }
    //Failure to persuade entrenched capitalists
    else if (cr.skill(Skill.business) >
            business + lead.skill(Skill.psychology) &&
        techniques[Technique.drugs] != true) {
      move(y++, 0);
      addstr([
        "${cr.name} will never be moved by ${lead.name}'s pathetic economic ideals.",
        "${cr.name} wishes a big company would just buy the LCS and shut it down.",
        "${cr.name} explains to ${lead.name} why communism failed.",
        "${cr.name} mumbles incoherently about Reaganomics.",
      ].random);
      lead.train(Skill.business, cr.skill(Skill.business) * 4);
    }
    //Failure to persuade scientific minds
    else if (cr.skill(Skill.science) > science + lead.skill(Skill.psychology) &&
        techniques[Technique.drugs] != true) {
      move(y++, 0);
      addstr([
        "${cr.name} wonders what mental disease has possessed ${lead.name}.",
        "${cr.name} explains why nuclear energy is safe.",
        "${cr.name} makes Albert Einstein faces at ${lead.name}.",
        "${cr.name} pities ${lead.name}'s blind ignorance of science.",
      ].random);
      lead.train(Skill.science, cr.skill(Skill.science) * 4);
    }
    //Target is swayed by Liberal Reason -- skilled interrogators, time held,
    //and rapport contribute to the likelihood of this
    else if (!cr.attributeCheck(Attribute.wisdom, (attack / 6).round())) {
      if (cr.juice > 0) {
        cr.juice -= attack;
        if (cr.juice < 0) cr.juice = 0;
      }

      if (cr.attribute(Attribute.heart) < 10) {
        cr.adjustAttribute(Attribute.heart, 1);
      } else {
        cr.adjustAttribute(Attribute.wisdom, -1);
      }
      //Improve rapport with interrogator
      addRapport(lead, 1.5);

      //Join LCS??
      //1) They were liberalized
      if (cr.attribute(Attribute.heart) > cr.attribute(Attribute.wisdom) + 4) {
        turned = true;
      }
      //2) They were befriended
      if ((rapport[lead.id] ?? 0) > 4) turned = true;

      mvaddstr(y++, 0, cr.name);
      addstr([
        "'s Conservative beliefs are shaken.",
        " quietly considers these ideas.",
        " is beginning to see Liberal reason.",
        " has a revelation of understanding.",
        " grudgingly admits sympathy for LCS ideals.",
      ].random);

      await getKey();

      y = await maybeRevealSecrets(cr, lead, y);
    }
    //Target is not sold on the LCS arguments and holds firm
    //This is the worst possible outcome if you use props
    else if (!cr.skillCheck(
            Skill.persuasion, lead.attribute(Attribute.heart) + 10) ||
        techniques[Technique.props] == true) {
      //Not completely unproductive; builds rapport
      addRapport(lead, 0.2);

      mvaddstr(y++, 0, cr.name);
      addstr(" holds firm.");
    }
    //Target actually wins the argument so successfully that the Liberal
    //interrogator's convictions are the ones that are shaken
    else {
      //Consolation prize is that they end up liking the
      //liberal more
      addRapport(lead, 1);

      lead.adjustAttribute(Attribute.wisdom, 1);

      mvaddstr(y++, 0, "${cr.name} turns the tables on ${lead.name}!");

      //show_interrogation_sidebar(cr,a);
      await getKey();

      mvaddstr(y++, 0, "${lead.name} has been tainted with wisdom!");
    }

    //show_interrogation_sidebar(cr,a);
    await getKey();
  }

  //Lead interrogator gets bonus experience
  if (techniques[Technique.kill] != true) {
    lead.train(Skill.psychology, 20);
    //Others also get experience
    for (int i = 0; i < tenders.length; i++) {
      tenders[i].train(Skill.psychology, 10);
    }
  }

  //Possibly suicidal when heart is down to 1 and prisoner has already been
  //captive for a week without rescue
  if (!turned &&
      cr.alive &&
      cr.attribute(Attribute.heart) <= 1 &&
      oneIn(3) &&
      cr.daysSinceJoined > 6) {
    move(++y, 0);

    //can't commit suicide if restrained
    if (!oneIn(6) || techniques[Technique.restrain] == true) {
      setColor(purple);
      addstr(cr.name);
      //can't cut self if restrained
      switch (lcsRandom(5 - (techniques[Technique.restrain] == true ? 1 : 0))) {
        case 0:
          addstr(" mutters about death.");
        case 1:
          addstr(" broods darkly.");
        case 2:
          addstr(" has lost hope of rescue.");
        case 3:
          addstr(" is making peace with God.");
        case 4:
          addstr(" is bleeding from self-inflicted wounds.");
          cr.blood -= lcsRandom(15) + 10;
      }
    } else {
      setColor(red);
      addstr("${cr.name} has committed suicide.");
      cr.die();
    }
    y++;
    //show_interrogation_sidebar(cr,a);

    await getKey();
  }

  //Death
  if (!cr.alive || cr.blood < 1) {
    cr.die();

    stats.kills++;
    move(++y, 0);
    setColor(red);
    addstr(cr.name);
    addstr(" is dead under ");
    addstr(lead.name);
    addstr("'s interrogation.");
    setColor(lightGray);
    y++;
    //show_interrogation_sidebar(cr,a);

    await getKey();

    y = await traumatize(lead, "death", y);
  }

  if (turned && cr.alive) {
    //clear_interrogation_sidebar();
    //delete interrogation information
    mvaddstrc(++y, 0, white,
        "The Automaton has been Enlightened!   Your Liberal ranks are swelling!");
    if (cr.attribute(Attribute.heart) > 7 &&
        cr.attribute(Attribute.wisdom) > 2 &&
        cr.permanentHealthDamage == 0 &&
        cr.kidnapped) {
      mvaddstr(++y, 0,
          "The conversion is convincing enough that the police no longer consider it a kidnapping.");
      //Actually liberalized -- they'll clean up the kidnapping story
      cr.missing = false;
      cr.kidnapped = false;
    }
    cr.brainwashed = true;
    await getKey();

    y += 2;
    cr.hireId = lead.id;
    liberalize(cr);
    stats.recruits++;

    y = await maybeRevealSecrets(cr, lead, y);

    if (cr.missing && !cr.kidnapped) {
      await getKey();

      erase();
      mvaddstrc(y = 1, 0, white,
          "${cr.name}'s disappearance has not yet been reported.");
      y = y + 2;
      await sleeperizePrompt(cr, lead, y);
      cr.missing = false;
      return;
    }
  }

  if (cr.align == Alignment.liberal || !cr.alive) {
    for (Creature p in tenders) {
      p.activity = Activity.none();
    }
  }

  mvaddstrc(24, 0, lightGray, "Press any key to reflect on this.");
  await getKey();
}

Future<int> traumatize(Creature lead, String action, int y) async {
  if (lcsRandom(lead.attribute(Attribute.heart)) > lcsRandom(3)) {
    mvaddstrc(y++, 0, lightGreen,
        "${lead.name} feels sick to ${lead.gender.hisHer} stomach afterward and ");
    lead.heartDamage += 1;
    move(y++, 0);
    addstr([
      "throws up in a trash can.",
      "gets drunk, eventually falling asleep.",
      "curls up in a ball, crying softly.",
      "shoots up and collapses in a heap on the floor.",
      "has a panic attack.",
      "doesn't want to talk to anyone.",
      "can't sleep for days.",
      "is haunted by the memory of the $action.",
      "has nightmares afterwards."
    ].random);
    lead.activity = Activity.none();
  } else if (oneIn(3) && lead.attribute(Attribute.wisdom) < 10) {
    mvaddstrc(y++, 0, lightBlue, "${lead.name} grows colder.");
    lead.adjustAttribute(Attribute.wisdom, 1);
  } else if (oneIn(3) &&
      lead.attribute(Attribute.wisdom) > lead.attribute(Attribute.heart)) {
    String name = lead.name;
    mvaddstrc(y++, 0, lightGray, "$name leaves the safehouse in a daze.");
    await getKey();
    mvaddstrc(
        y++,
        2,
        midGray,
        [
          "$name wanders the streets all night, lost in thought.",
          "$name gets drunk while out and rethinks this life.",
          "$name runs naked through the park at night.",
          "$name wanders aimlessly through the city, unable to think.",
          "$name finds a quiet diner and watches people exist.",
          "$name lies on a park bench, wracked by regret.",
          "$name walks until exhaustion forces ${lead.gender.himHer} to collapse.",
          "$name goes to a bar and meets some new people.",
          "$name lies down in a dumpster, where ${lead.gender.heShe} belongs.",
          "$name knocks on people's doors, turned away every time.",
          "$name sits in a bar, drinking and staring at the wall.",
          "$name stares at a church for hours, before going in.",
          "$name follows flickering streetlights into the darkness.",
          "$name sits in a park, watching people with regular lives.",
          "$name walks until the city dissolves into fog.",
          "$name stares up at the moon as it draws impossibly close.",
          "$name catches a bus, not knowing where it leads.",
          "$name catches a bus and rides it to the end of the line.",
          "$name catches a bus to the next city.",
          "\"I don't want to do this anymore...\"",
          "\"I need to get out of here!\"",
          "\"I can't do this anymore.\"",
          "\"I hate who I've become...\"",
          "\"I don't want to be a part of this...\"",
          "\"I hate this place!\"",
          "\"Fuck all of this!\"",
          "\"Fucking LCS bullshit...\"",
          "\"Who gives a shit about this anyway...\"",
          "\"What am I fucking doing?\"",
          "\"I hate this, I hate myself.\"",
          "\"I used to think I was a good person...\"",
        ].random);
    await getKey();
    if (oneIn(2)) {
      if (oneIn(2)) {
        mvaddstrc(y++, 4, darkGray, "${lead.name} never comes back.");
        lead.location = null;
        lead.die(); // they might be alive, but it doesn't matter to the LCS
        lead.boss?.juice -= 25;
        if (oneIn(2)) {
          lead.base?.siege.timeUntilCops = 2;
        }
      } else {
        lead.location = null;
        lead.hidingDaysLeft = lcsRandom(3) + 2;
        mvaddstrc(y++, 4, darkGray,
            "${lead.name} doesn't come back for several days...");
      }
    } else {
      mvaddstrc(y++, 4, lightGray,
          "${lead.name} returns to the safehouse after a few hours.");
    }
  } else {
    mvaddstrx(y++, 0, "&w${lead.name} &mdoesn't really &Kfeel anything...");
  }
  await getKey();
  if (!lead.alive) {
    await dispersalCheck();
  }
  return y;
}

Future<int> maybeRevealSecrets(Creature cr, Creature lead, int y) async {
  Site? workSite = cr.workLocation is Site ? cr.workLocation as Site : null;
  if (workSite?.mapped == false &&
      (oneIn(5) || cr.align == Alignment.liberal)) {
    y++;
    mvaddstr(y++, 0, "${cr.name} reveals details about the ${workSite!.name}.");
    mvaddstr(y++, 0,
        "${lead.name} was able to create a map of the site with this information.");

    workSite.mapped = true;
    workSite.hidden = false;
    await getKey();
  }
  return y;
}

// Clear sidebar
void cleanInterrogationSidebar() {
  eraseArea(startY: 4, startX: 40, endY: 23, endX: 74);
}

// Shows the interrogation data at the right side of the screen
void showInterrogationSidebar(InterrogationSession intr, Creature a) {
  cleanInterrogationSidebar();

  Creature cr = intr.hostage;
  var rapport = intr.rapport;
  int y = 4;
  move(y, 40);
  setColor(lightGray);
  addstr("Prisoner: ");
  setColor(red);
  addstr(cr.name);
  move(y += 2, 40);
  setColor(lightGray);
  addstr("Health: ");
  printHealthStat(y, 48, cr);
  mvaddstrc(++y, 40, lightGray, "Heart: ${cr.attribute(Attribute.heart)}");
  mvaddstr(++y, 40, "Wisdom: ${cr.attribute(Attribute.wisdom)}");
  mvaddstr(++y, 40, "Health: ${cr.health}");

  move(y = 13, 40);
  setColor(lightGray);
  addstr("Lead Interrogator: ");
  setColor(lightGreen);
  addstr(a.name);
  move(y += 2, 40);
  setColor(lightGray);
  addstr("Health: ");
  printHealthStat(y, 48, a);
  mvaddstrc(
      ++y, 40, lightGray, "Psychology Skill: ${a.skill(Skill.psychology)}");
  move(++y, 40);
  setColor(lightGray);
  addstr("Heart: ${a.attribute(Attribute.heart)}");
  mvaddstr(++y, 40, "Wisdom: ${a.attribute(Attribute.wisdom)}");
  mvaddstr(++y, 40, "Outfit: ${a.clothing.longName}");
  move(y += 2, 40);

  if ((rapport[a.id] ?? 0) > 3) {
    addstr("${cr.name} clings helplessly ");
    mvaddstr(++y, 40, "to ");
    addstr(a.name);
    addstr(" as ${cr.gender.hisHer} only friend.");
  } else if ((rapport[a.id] ?? 0) > 1) {
    addstr("${cr.name} likes ");
    addstr(a.name);
    addstr(".");
  } else if ((rapport[a.id] ?? 0) > -1) {
    addstr("${cr.name} is uncooperative ");
    mvaddstr(++y, 40, "toward ");
    addstr(a.name);
    addstr(".");
  } else if ((rapport[a.id] ?? 0) > -4) {
    addstr("${cr.name} hates ");
    addstr(a.name);
    addstr(".");
  } else {
    addstr("${cr.name} would like to ");
    mvaddstr(++y, 40, "murder ");
    addstr(a.name);
    addstr(".");
  }
}
