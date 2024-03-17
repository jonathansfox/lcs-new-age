import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/saveload/load_cmv_movies.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> runTelevisionNewsStories() async {
  for (int n = newsStories.length - 1; n >= 0; n--) {
    bool del = false;
    if (newsStories[n].type == NewsStories.majorEvent) {
      if (newsStories[n].positive > 0) {
        switch (newsStories[n].view) {
          case View.policeBehavior:
            await movie.loadmovie("lacops.cmv");
            await movie.playmovie(0, 0, remapSkinTones: true);

            mvaddstrc(19, 13, white,
                "┌───────────────────────────────────────────────────┐");
            mvaddstr(20, 13,
                "│     The police have brutally beaten a black man   │");
            mvaddstr(21, 13,
                "│   in Los Angeles.  The entire thing is caught on  │");
            mvaddstr(22, 13,
                "│   video by a passerby and it saturates the news.  │");
            mvaddstr(23, 13,
                "└───────────────────────────────────────────────────┘");

            await getKey();

            del = true;
          case View.cableNews:
            String str = "Tonight on a Cable News channel: ";
            str +=
                ["Inside", "Hard", "Lightning", "Washington", "Capital"].random;
            str += [" Record", " Night", " Talk", " Insider", " Report"].random;
            str += " with ";
            String bname =
                generateFullName(Gender.whiteMalePatriarch).firstLast;
            str += bname;
            erase();
            mvaddstrc(0, 39 - ((str.length - 1) >> 1), white, str);
            mvaddstr(16, 20, bname);
            move(17, 20);
            switch (lcsRandom(3)) {
              case 0:
                addstr("Washington, DC");
              case 1:
                addstr("New York, NY");
              case 2:
                addstr("Atlanta, GA");
            }
            move(16, 41);
            addstr(generateFullName(Gender.nonbinary).firstLast);
            move(17, 41);
            switch (lcsRandom(4)) {
              case 0:
                addstr("Eugene, OR");
              case 1:
                addstr("San Francisco, CA");
              case 2:
                addstr("Cambridge, MA");
              case 3:
                addstr("Ithaca, NY");
            }
            await movie.loadmovie("newscast.cmv");
            await movie.playmovie(1, 1, remapSkinTones: true);
            mvaddstrc(19, 13, white,
                "┌───────────────────────────────────────────────────┐");
            mvaddstr(20, 13,
                "│     A Cable News anchor just accidentally let a   │");
            mvaddstr(21, 13,
                "│   bright Liberal guest finish a sentence.  Many   │");
            mvaddstr(22, 13,
                "│   viewers across the nation were listening.       │");
            mvaddstr(23, 13,
                "└───────────────────────────────────────────────────┘");
            await getKey();
            del = true;
          default:
        }
      } else {
        switch (newsStories[n].view) {
          case View.ceoSalary:
            await movie.loadmovie("glamshow.cmv");
            await movie.playmovie(0, 0);
            mvaddstrc(19, 13, white,
                "┌───────────────────────────────────────────────────┐");
            mvaddstr(20, 13,
                "│     A new show glamorizing the lives of the rich  │");
            mvaddstr(21, 13,
                "│   begins airing this week.  With the nationwide   │");
            mvaddstr(22, 13,
                "│   advertising blitz, it's bound to be popular.    │");
            mvaddstr(23, 13,
                "└───────────────────────────────────────────────────┘");
            await getKey();
            del = true;
          case View.cableNews:
            await movie.loadmovie("anchor.cmv");
            await movie.playmovie(0, 0, remapSkinTones: true);
            mvaddstrc(19, 13, white,
                "┌───────────────────────────────────────────────────┐");
            mvaddstr(20, 13,
                "│     A major Cable News channel has hired a slick  │");
            mvaddstr(21, 13,
                "│   new anchor for one of its news shows.  Guided   │");
            mvaddstr(22, 13,
                "│   by impressive advertising, America tunes in.    │");
            mvaddstr(23, 13,
                "└───────────────────────────────────────────────────┘");
            await getKey();
            del = true;
          case View.womensRights:
            erase();
            await movie.loadmovie("abort.cmv");
            await movie.playmovie(0, 0, remapSkinTones: true);
            mvaddstrc(19, 13, white,
                "┌───────────────────────────────────────────────────┐");
            mvaddstr(20, 13,
                "│     A  failed partial  birth abortion goes on a   │");
            mvaddstr(21, 13,
                "│   popular  afternoon  talk  show.   The  studio   │");
            mvaddstr(22, 13,
                "│   audience and viewers nationwide feel its pain.  │");
            mvaddstr(23, 13,
                "└───────────────────────────────────────────────────┘");
            await getKey();
            del = true;
          default:
        }
      }
    }
    if (del) newsStories.removeAt(n);
  }
}
