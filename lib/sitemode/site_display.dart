import 'dart:ui';

import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';
import 'package:lcs_new_age/utils/colors.dart';

int _diff(int a, int b) => a > b ? a - b : b - a;

// Imperfect but quick and dirty line of sight check
// Only works if the target point is at most two spaces
// away in any direction
bool _lineOfSight(int x, int y, int z) {
  if (x < 0 || y < 0 || x >= MAPX || y >= MAPY) return false;
  if (levelMapTile(x, y, z).known) {
    return true; // already explored
  }
  if (_diff(x, locx) > 2 || _diff(y, locy) > 2) return false; // too far away

  if (_diff(x, locx) <= 1 && _diff(y, locy) <= 1) {
    return true; // right next to us or right where we're standing
  }
  int x1, x2, y1, y2;

  if (_diff(x, locx) == 1) {
    x1 = locx;
    x2 = x;
  } else {
    x1 = x2 = (x + locx) ~/ 2; // difference is either 0 or 2
  }

  if (_diff(y, locy) == 1) {
    y1 = locy;
    y2 = y;
  } else {
    y1 = y2 = (y + locy) ~/ 2; // difference is either 0 or 2
  }

  // Check for obstructions
  if (levelMap[x1][y2][z].losObstructed && levelMap[x2][y1][z].losObstructed) {
    return false; // Blocked on some axis
  }

  return true;
}

// Prints the map graphics in the bottom right of the screen
void printSiteMap(int x, int y, int z) {
  int xscreen, xsite, yscreen, ysite;

  // Build the frame
  mvaddstrc(8, 53, lightGray,
      "\u252C${"".padRight(25, "\u2500")}\u252C"); // 27 characters - top of map
  mvaddstr(24, 53,
      "\u2514${"".padRight(25, "\u2500")}\u2518"); // 27 characters - bottom of map
  for (yscreen = 9; yscreen < 24; yscreen++) {
    mvaddstr(yscreen, 53,
        "\u2502                         \u2502"); // 27 characters - the map itself
  }

  // Do a preliminary Line of Sight iteration for better Line of Sight detection
  for (xsite = x - 2; xsite < x + 3; xsite++) {
    for (ysite = y - 2; ysite < y + 3; ysite++) {
      if (_lineOfSight(xsite, ysite, z)) {
        levelMap[xsite][ysite][z].known = true;
      }
    }
  }

  // Display the map
  xscreen = 79 - 5 * 5;
  for (xsite = x - 2; xsite < x + 3; xscreen += 5, xsite++) {
    yscreen = 24 - 3 * 5;
    for (ysite = y - 2; ysite < y + 3; yscreen += 3, ysite++) {
      printBlock(xsite, ysite, z, xscreen, yscreen);
    }
  }

  //PRINT SPECIAL
  String str;
  switch (levelMap[locx][locy][locz].special) {
    case TileSpecial.cagedRabbits:
      str = "Caged Animals";
    case TileSpecial.nuclearControlRoom:
      str = "Reactor Control Room";
    case TileSpecial.cagedMonsters:
      str = "Caged \"Animals\"";
    case TileSpecial.policeStationLockup:
      str = "Police Detention Room";
    case TileSpecial.courthouseLockup:
      str = "Courthouse Jail";
    case TileSpecial.courthouseJuryRoom:
      str = "Jury Room";
    case TileSpecial.prisonControl:
    case TileSpecial.prisonControlLow:
    case TileSpecial.prisonControlMedium:
    case TileSpecial.prisonControlHigh:
      str = "Prison Control Room";
    case TileSpecial.intelSupercomputer:
      str = "Supercomputer";
    case TileSpecial.sweatshopEquipment:
      str = "Textile Equipment";
    case TileSpecial.polluterEquipment:
      str = "Factory Equipment";
    case TileSpecial.armory:
      str = "Armory";
    case TileSpecial.ceoOffice:
      str = "CEO's Study";
    case TileSpecial.ceoSafe:
    case TileSpecial.corporateFiles:
      str = "Safe";
    case TileSpecial.radioBroadcastStudio:
      str = "Radio Broadcast Room";
    case TileSpecial.cableBroadcastStudio:
      str = "News Broadcast Studio";
    case TileSpecial.apartmentLandlord:
      str = "Landlord's Office";
    case TileSpecial.signOne:
    case TileSpecial.signTwo:
    case TileSpecial.signThree:
      str = "Sign";
    case TileSpecial.displayCase:
      str = "Display Case";
    case TileSpecial.stairsUp:
      str = "Stairs Up";
    case TileSpecial.stairsDown:
      str = "Stairs Down";
    case TileSpecial.table:
      str = "Table";
    case TileSpecial.computer:
      str = "Computer";
    case TileSpecial.parkBench:
      str = "Bench";
    case TileSpecial.bankVault:
      str = "Bank Vault";
    case TileSpecial.bankTeller:
      str = "Bank Teller";
    case TileSpecial.bankMoney:
      str = "Oh Wow So Much Money";
    case TileSpecial.ccsBoss:
      str = "CCS Boss";
    case TileSpecial.ovalOfficeNW:
    case TileSpecial.ovalOfficeNE:
    case TileSpecial.ovalOfficeSW:
    case TileSpecial.ovalOfficeSE:
      str = "The Office of the President";
    default:
      str = "";
      break;
  }
  if (levelMap[locx][locy][locz].special != TileSpecial.none) {
    mvaddstrc(24, 67 - (str.length >> 1), white, str);
  }

  //PRINT PARTY
  int partyalive = activeSquad!.livingMembers.length;
  if (partyalive > 0) {
    setColor(lightGreen);
  } else {
    setColor(darkGray);
  }
  mvaddstr(16, 64, "SQUAD");

  int encsize = encounter.length;
  //PRINT ANY OPPOSING FORCE INFO
  if (encsize > 0) {
    setColor(yellow);
    if (levelMap[locx][locy][locz].siegeHeavyUnit) {
      mvaddstr(17, 64, "ARMOR");
    } else if (levelMap[locx][locy][locz].siegeUnit) {
      mvaddstr(17, 64, "ENEMY");
    } else if (levelMap[locx][locy][locz].siegeUnitDamaged) {
      mvaddstr(17, 64, "enemy");
    } else {
      mvaddstr(17, 64, "ENCTR");
    }

    printEncounter();
  }

  if (groundLoot.isNotEmpty) {
    mvaddstrc(15, 64, purple, "LOOT!");

    printEncounter();
  }
}

const wallUp = 0;
const wallDown = 1;
const wallLeft = 2;
const wallRight = 3;
const cornerUL = 4;
const cornerUR = 5;
const cornerDL = 6;
const cornerDR = 7;

void printWall(int x, int y, int z, int px, int py) {
  List<bool> visible = [false, false, false, false, false, false, false, false];
  List<bool> bloody = [false, false, false, false, false, false, false, false];
  List<String> graffiti = ["   ", "   ", "   ", "   "];
  List<Color> graffiticolor = [black, black, black, black];

  // What are we drawing here? Wall/door? Locked/jammed? Metal/normal?
  SiteTile tile = levelMapTile(x, y, z);

  // Now follows a series of checks to determine the faces of the wall that should be
  // displayed. Note the order of these checks is important:
  //
  // 1) You will see the wall if it's the upward face and you're above it (directional visibility)...
  // 2) ...unless your line of sight is blocked (LOS)...
  // 3) ...but line of sight and directional visibility is not important if you have already seen that
  //          tile (memory)...
  // 4) ...and regardless of any of the above, if there's a physical obstruction that would prevent you
  //          from seeing it even if you were near it, like a wall, it should not be shown (blockages).
  //
  // The order of the remainder of the checks is not crucial.

  // 1) Check for directional visibility
  if (x > locx && x < MAPX) visible[wallLeft] = true;
  if (x > 0 && x < locx) visible[wallRight] = true;
  if (y > locy && y < MAPY) visible[wallUp] = true;
  if (y > 0 && y < locy) visible[wallDown] = true;

  if (y > locy && y < MAPY && x > locx && x < MAPX) visible[cornerUL] = true;
  if (y > locy && y < MAPY && x > 0 && x < locx) visible[cornerUR] = true;
  if (y > 0 && y < locy && x > locx && x < MAPX) visible[cornerDL] = true;
  if (y > 0 && y < locy && x > 0 && x < locx) visible[cornerDR] = true;

  // 2) Check LOS
  if (!_lineOfSight(x - 1, y, z)) visible[wallLeft] = false;
  if (!_lineOfSight(x + 1, y, z)) visible[wallRight] = false;
  if (!_lineOfSight(x, y - 1, z)) visible[wallUp] = false;
  if (!_lineOfSight(x, y + 1, z)) visible[wallDown] = false;

  if (!_lineOfSight(x - 1, y - 1, z)) visible[cornerUL] = false;
  if (!_lineOfSight(x + 1, y - 1, z)) visible[cornerUR] = false;
  if (!_lineOfSight(x - 1, y + 1, z)) visible[cornerDL] = false;
  if (!_lineOfSight(x + 1, y + 1, z)) visible[cornerDR] = false;

  // 3) Check for memory
  if (levelMapTile(x - 1, y, z).known) {
    visible[wallLeft] = true;
  }
  if (levelMapTile(x + 1, y, z).known) {
    visible[wallRight] = true;
  }
  if (levelMapTile(x, y - 1, z).known) {
    visible[wallUp] = true;
  }
  if (levelMapTile(x, y + 1, z).known) {
    visible[wallDown] = true;
  }

  if (levelMapTile(x - 1, y - 1, z).known) {
    visible[cornerUL] = true;
  }
  if (levelMapTile(x + 1, y - 1, z).known) {
    visible[cornerUR] = true;
  }
  if (levelMapTile(x - 1, y + 1, z).known) {
    visible[cornerDL] = true;
  }
  if (levelMapTile(x + 1, y + 1, z).known) {
    visible[cornerDR] = true;
  }

  // 4) Check for blockages
  if (levelMapTile(x - 1, y, z).blocked) {
    visible[wallLeft] = false;
  }
  if (levelMapTile(x + 1, y, z).blocked) {
    visible[wallRight] = false;
  }
  if (levelMapTile(x, y - 1, z).blocked) {
    visible[wallUp] = false;
  }
  if (levelMapTile(x, y + 1, z).blocked) {
    visible[wallDown] = false;
  }

  if (levelMapTile(x - 1, y - 1, z).blocked) {
    visible[cornerUL] = false;
  }
  if (levelMapTile(x + 1, y - 1, z).blocked) {
    visible[cornerUR] = false;
  }
  if (levelMapTile(x - 1, y + 1, z).blocked) {
    visible[cornerDL] = false;
  }
  if (levelMapTile(x + 1, y + 1, z).blocked) {
    visible[cornerDR] = false;
  }

  // Below not used for doors
  if (levelMapTile(x, y, z).wall) {
    // Check for bloody walls
    if (levelMapTile(x - 1, y, z).megaBloody) {
      bloody[wallLeft] = true;
    }
    if (levelMapTile(x + 1, y, z).megaBloody) {
      bloody[wallRight] = true;
    }
    if (levelMapTile(x, y - 1, z).megaBloody) {
      bloody[wallUp] = true;
    }
    if (levelMapTile(x, y + 1, z).megaBloody) {
      bloody[wallDown] = true;
    }

    if (levelMapTile(x - 1, y - 1, z).megaBloody) {
      bloody[cornerUL] = true;
    }
    if (levelMapTile(x + 1, y - 1, z).megaBloody) {
      bloody[cornerUR] = true;
    }
    if (levelMapTile(x - 1, y + 1, z).megaBloody) {
      bloody[cornerDL] = true;
    }
    if (levelMapTile(x + 1, y + 1, z).megaBloody) {
      bloody[cornerDR] = true;
    }

    // Check for other graffiti
    String tag = graffitiFromCoordinates(x, y);
    if (levelMapTile(x - 1, y, z).graffitiOther) {
      graffiti[wallLeft] = tag;
      graffiticolor[wallLeft] = black;
    }
    if (levelMapTile(x + 1, y, z).graffitiOther) {
      graffiti[wallRight] = tag;
      graffiticolor[wallRight] = black;
    }
    if (levelMapTile(x, y - 1, z).graffitiOther) {
      graffiti[wallUp] = tag;
      graffiticolor[wallUp] = black;
    }
    if (levelMapTile(x, y + 1, z).graffitiOther) {
      graffiti[wallDown] = tag;
      graffiticolor[wallDown] = black;
    }

    // Check for CCS graffiti
    if (levelMapTile(x - 1, y, z).graffitiCCS) {
      graffiti[wallLeft] = "CCS";
      graffiticolor[wallLeft] = red;
    }
    if (levelMapTile(x + 1, y, z).graffitiCCS) {
      graffiti[wallRight] = "CCS";
      graffiticolor[wallRight] = red;
    }
    if (levelMapTile(x, y - 1, z).graffitiCCS) {
      graffiti[wallUp] = "CCS";
      graffiticolor[wallUp] = red;
    }
    if (levelMapTile(x, y + 1, z).graffitiCCS) {
      graffiti[wallDown] = "CCS";
      graffiticolor[wallDown] = red;
    }

    // Check for LCS graffiti
    if (levelMapTile(x - 1, y, z).graffitiLCS) {
      graffiti[wallLeft] = "LCS";
      graffiticolor[wallLeft] = green;
    }
    if (levelMapTile(x + 1, y, z).graffitiLCS) {
      graffiti[wallRight] = "LCS";
      graffiticolor[wallRight] = green;
    }
    if (levelMapTile(x, y - 1, z).graffitiLCS) {
      graffiti[wallUp] = "LCS";
      graffiticolor[wallUp] = green;
    }
    if (levelMapTile(x, y + 1, z).graffitiLCS) {
      graffiti[wallDown] = "LCS";
      graffiticolor[wallDown] = green;
    }
  }

  for (int dir = 4; dir < 8; dir++) {
    x = px;
    y = py;

    // Draw the corner
    if (visible[dir] && tile.wall) {
      // Position cursor in the correct corner
      //if(dir==CORNER_UL) // Nothing to do in this case
      if (dir == cornerUR) x += 4;
      if (dir == cornerDL) y += 2;
      if (dir == cornerDR) {
        y += 2;
        x += 4;
      }

      // Blood overrides gray base wall color
      if (bloody[dir]) {
        setColor(darkRed, background: darkRed);
      } else {
        setColor(lightGray, background: lightGray);
      }

      // The corner's ready to draw now
      mvaddchar(y, x, ' ');
    }
  }

  for (int dir = 0; dir < 4; dir++) {
    x = px;
    y = py;

    // Draw the wall/door
    if (visible[dir]) {
      if (tile.wall) {
        // Position cursor at the start of where the graffiti tag would go
        //if(dir==WALL_LEFT) // Nothing to do in this case
        if (dir == wallRight) x += 4;
        if (dir == wallUp) x++;
        if (dir == wallDown) {
          y += 2;
          x++;
        }

        // Blood overrides graffiti overrides gray base wall color
        if (bloody[dir]) {
          setColor(darkRed, background: darkRed);
        } else if (graffiti[dir][0] != ' ') {
          setColor(graffiticolor[dir], background: lightGray);
        } else {
          setColor(lightGray, background: lightGray);
        }

        // Draw the chunk of wall where the graffiti would/will go
        for (int gchar = 0; gchar < 3; gchar++) {
          mvaddchar(y, x, graffiti[dir][gchar]);
          if (dir == wallRight || dir == wallLeft) {
            y++;
          } else {
            x++;
          }
        }

        // For the long faces (top and bottom) of the wall, there is
        // additional space to either side of the 'tag' (or lack of tag)
        // that needs to be filled in with wall or blood color
        if (dir == wallUp || dir == wallDown) {
          if (bloody[dir]) {
            setColor(darkRed, background: darkRed);
          } else {
            setColor(lightGray, background: lightGray);
          }
          if (!visible[wallLeft]) mvaddchar(y, px, ' ');
          if (!visible[wallRight]) mvaddchar(y, px + 4, ' ');
        }
      } else if (tile.door) {
        // Doors are, thankfully, much simpler, as they do not
        // support blood or graffiti

        // Position cursor at the start of face
        if (dir == wallDown) y += 2;
        if (dir == wallRight) x += 4;

        // Pick color
        if (tile.metal) {
          setColor(white, background: lightGray);
        } else if (tile.cantUnlock && tile.locked) {
          setColor(red, background: darkRed);
        } else if (tile.knownLock && tile.locked) {
          setColor(darkGray);
        } else {
          setColor(orange, background: black);
        }

        // Draw face
        if (dir == wallRight || dir == wallLeft) {
          for (int i = 0; i < 3; i++) {
            mvaddstr(y++, x, "\u2551");
          }
        } else {
          for (int i = 0; i < 5; i++) {
            mvaddstr(y, x++, "\u2550");
          }
        }

        // Corners are possible if walls nearby are blown away, although this is rare
        if ((dir == wallLeft && visible[wallUp]) ||
            (dir == wallUp && visible[wallLeft])) mvaddstr(py, px, "+");
        if ((dir == wallRight && visible[wallUp]) ||
            (dir == wallUp && visible[wallRight])) mvaddstr(py, px + 4, "+");
        if ((dir == wallLeft && visible[wallDown]) ||
            (dir == wallDown && visible[wallLeft])) mvaddstr(py + 2, px, "+");
        if ((dir == wallRight && visible[wallDown]) ||
            (dir == wallDown && visible[wallRight])) {
          mvaddstr(py + 2, px + 4, "+");
        }
      }
    }
  }
}

void printBlock(int x, int y, int z, int px, int py) {
  if (!_lineOfSight(x, y, z)) {
    setColor(black);
    for (x = px; x < px + 5; x++) {
      for (y = py; y < py + 3; y++) {
        mvaddchar(y, x, ' ');
      }
    }
    return;
  }
  levelMapTile(x, y, z).known = true;
  if (levelMapTile(x, y, z).blocked) {
    printWall(x, y, z, px, py);
    return;
  }
  Color backcolor = black;
  String ch = ' ';
  if (levelMapTile(x, y, z).restricted) {
    setColor(darkGray);
    ch = '+';
  } else if (levelMapTile(x, y, z).grass) {
    setColor(green);
    ch = '.';
  } else if (levelMapTile(x, y, z).outdoor) {
    setColor(darkGray);
    ch = ' ';
  } else {
    setColor(darkGray);
    ch = ' ';
  }

  for (int px2 = px; px2 < px + 5; px2++) {
    for (int py2 = py; py2 < py + 3; py2++) {
      mvaddchar(py2, px2, ch);
    }
  }

  if (levelMapTile(x, y, z).debris) {
    setColor(white, background: backcolor);
    mvaddchar(py + 0, px + 1, '.');
    mvaddchar(py + 0, px + 4, '^');
    mvaddchar(py + 1, px + 0, '=');
    mvaddchar(py + 1, px + 3, '.');
    mvaddchar(py + 1, px + 4, '|');
    mvaddchar(py + 2, px + 1, '.');
    mvaddchar(py + 2, px + 4, '\\');
  }

  if (levelMapTile(x, y, z).fireStart) {
    setColor(red, background: backcolor);
    mvaddchar(py + 0, px + 1, '.');
    setColor(yellow, background: backcolor);
    mvaddchar(py + 1, px + 3, '.');
    mvaddchar(py + 2, px + 1, '.');
  }

  if (levelMapTile(x, y, z).firePeak) {
    setColor(red, background: backcolor);
    mvaddchar(py + 0, px + 1, ':');
    mvaddchar(py + 1, px + 0, '*');
    setColor(yellow, background: backcolor);
    mvaddchar(py + 0, px + 4, '\$');
    mvaddchar(py + 1, px + 3, ':');
    mvaddchar(py + 1, px + 4, '%');
    mvaddchar(py + 2, px + 1, ':');
    mvaddchar(py + 2, px + 4, '*');
  }

  if (levelMapTile(x, y, z).fireEnd) {
    setColor(red, background: backcolor);
    mvaddchar(py + 1, px + 0, '*');
    setColor(yellow, background: backcolor);
    mvaddchar(py + 0, px + 4, '~');
    mvaddchar(py + 2, px + 4, '#');
    setColor(white, background: backcolor);
    mvaddchar(py + 0, px + 1, '.');
    mvaddchar(py + 1, px + 3, '.');
    mvaddchar(py + 1, px + 4, '|');
    mvaddchar(py + 2, px + 1, '.');
  }

  if (levelMapTile(x, y, z).megaBloody) {
    setColor(darkRed, background: backcolor);
    mvaddchar(py + 1, px + 1, '%');
    mvaddchar(py + 2, px + 1, '.');
    mvaddchar(py + 1, px + 2, '.');
  } else if (levelMapTile(x, y, z).bloody) {
    setColor(darkRed, background: backcolor);
    mvaddchar(py + 2, px + 1, '.');
    mvaddchar(py + 1, px + 2, '.');
  }

  if (levelMapTile(x, y, z).exit) {
    setColor(lightGray, background: backcolor);
    mvaddstr(py + 1, px + 1, "EXT");
  } else if (levelMapTile(x, y, z).loot) {
    setColor(purple, background: backcolor);
    mvaddstr(py, px + 1, "~\$~");
  }

  if (levelMapTile(x, y, z).siegeTrap) {
    setColor(yellow, background: backcolor);
    mvaddstr(py + 1, px, "TRAP!");
  } else if (levelMapTile(x, y, z).siegeUnit) {
    setColor(darkRed, background: backcolor);
    mvaddstr(py + 2, px, "enemy");
  } else if (levelMapTile(x, y, z).special != TileSpecial.none) {
    setColor(yellow, background: backcolor);

    switch (levelMapTile(x, y, z).special) {
      case TileSpecial.nuclearControlRoom:
        mvaddstr(py, px, "POWER");
      case TileSpecial.cagedRabbits:
      case TileSpecial.cagedMonsters:
        mvaddstr(py, px, "CAGES");
      case TileSpecial.policeStationLockup:
      case TileSpecial.courthouseLockup:
        mvaddstr(py, px, "CELLS");
      case TileSpecial.courthouseJuryRoom:
        mvaddstr(py, px, "JURY!");
      case TileSpecial.prisonControl:
      case TileSpecial.prisonControlLow:
      case TileSpecial.prisonControlMedium:
      case TileSpecial.prisonControlHigh:
        mvaddstr(py, px, "CTROL");
      case TileSpecial.intelSupercomputer:
        mvaddstr(py, px, "INTEL");
      case TileSpecial.sweatshopEquipment:
      case TileSpecial.polluterEquipment:
        mvaddstr(py, px, "EQUIP");
      case TileSpecial.armory:
        mvaddstr(py, px, "ARMRY");
      case TileSpecial.ceoOffice:
        mvaddstr(py, px + 1, "CEO");
      case TileSpecial.ceoSafe:
      case TileSpecial.corporateFiles:
        mvaddstr(py, px, "SAFE!");
      case TileSpecial.radioBroadcastStudio:
        mvaddstr(py, px + 1, "MIC");
      case TileSpecial.cableBroadcastStudio:
        mvaddstr(py, px, "STAGE");
      case TileSpecial.apartmentLandlord:
        mvaddstr(py, px, "RENT?");
      case TileSpecial.signOne:
      case TileSpecial.signTwo:
      case TileSpecial.signThree:
        mvaddstr(py, px, "SIGN!");
      case TileSpecial.stairsUp:
        mvaddstr(py, px + 1, "UP\u2191");
      case TileSpecial.stairsDown:
        mvaddstr(py, px + 1, "DN\u2193");
      case TileSpecial.table:
        mvaddstr(py, px, "TABLE");
      case TileSpecial.computer:
        mvaddstr(py, px + 1, "CPU");
      case TileSpecial.parkBench:
        mvaddstr(py, px, "BENCH");
      case TileSpecial.securityMetalDetectors:
        mvaddstr(py, px, "METAL");
      case TileSpecial.securityCheckpoint:
        mvaddstr(py, px, "GUARD");
      case TileSpecial.displayCase:
        mvaddstr(py, px, "CASE");
      case TileSpecial.bankVault:
        mvaddstr(py, px, "VAULT");
      case TileSpecial.bankTeller:
        mvaddstr(py, px, "TELER");
      case TileSpecial.bankMoney:
        mvaddstr(py, px, "MONEY");
      case TileSpecial.ccsBoss:
        mvaddstr(py, px, "BOSS!");
      case TileSpecial.ovalOfficeNW:
        mvaddstr(py, px + 3, "OV");
      case TileSpecial.ovalOfficeNE:
        mvaddstr(py, px, "AL");
      case TileSpecial.ovalOfficeSW:
        mvaddstr(py, px + 2, "OFF");
      case TileSpecial.ovalOfficeSE:
        mvaddstr(py, px, "ICE");
      default:
        break;
    }
  }
  if (levelMapTile(x, y, z).siegeHeavyUnit) {
    setColor(red, background: backcolor);
    mvaddstr(py + 2, px, "ARMOR");
  } else if (levelMapTile(x, y, z).siegeUnit) {
    setColor(red, background: backcolor);
    mvaddstr(py + 2, px, "ENEMY");
  }
}

void clearSceneAreas() {
  clearCommandArea();
  clearMessageArea();
  clearMapArea();
}

void clearCommandArea() {
  eraseArea(startY: 9, endY: 16, startX: 0, endX: 53);
}

void clearMessageArea([bool? redrawMapArea]) {
  redrawMapArea ??= true;
  bool siteMode = mode == GameMode.site;
  int endX = 80;
  if (!redrawMapArea || siteMode) endX = 53;
  eraseArea(startY: 16, endY: 18, startX: 0, endX: endX);
  if (redrawMapArea && siteMode) printSiteMap(locx, locy, locz);
}

void clearEncounterArea() {
  eraseArea(startY: 19, endY: 25, startX: 0, endX: 53);
}

void clearMapArea({bool lower = true, bool upper = true}) {
  int startY = upper ? 8 : 15;
  int endY = lower ? 25 : 15;
  eraseArea(startY: startY, endY: endY, startX: 53, endX: 80);
  makeDelimiter();
}

/* prints the names of creatures you see */
void printEncounter() {
  if (mode == GameMode.carChase || mode == GameMode.footChase) {
    printChaseEncounter();
  } else {
    printBasicEncounter();
  }
}

void printBasicEncounter() {
  clearEncounterArea();

  int px = 1, py = 19;
  for (Creature e in encounter) {
    if (!e.alive) {
      setColor(darkGray);
    } else {
      setColor(e.align.color);
    }
    mvaddstr(py, px, e.name);

    px += 18;
    if (px > 37) {
      px = 1;
      py++;
    }
  }
}

/* prints the names of creatures you see in car chases */
void printChaseEncounter() {
  clearMapArea(upper: false);
  clearEncounterArea();

  if (chaseSequence?.enemycar.isNotEmpty == true) {
    List<int> carsy = [20, 20, 20, 20];

    for (int v = 0; v < chaseSequence!.enemycar.length; v++) {
      mvaddstrc(19, v * 20 + 1, white, chaseSequence!.enemycar[v].fullName());
    }

    for (Creature e in encounter) {
      for (int v = 0; v < chaseSequence!.enemycar.length; v++) {
        if (chaseSequence!.enemycar[v].id == e.carId) {
          mvaddstrc(carsy[v], v * 20 + 1, red, e.name);
          if (e.isDriver) addstr("-D");
          carsy[v]++;
        }
      }
    }
  } else {
    printBasicEncounter();
  }
}

String graffitiFromCoordinates(int x, int y) {
  int seed = 97 * x + 61 * y;
  List<String> options = [
    "ORB", "YES", "FUK", "SHT", "DIE", "COO", "MOM", "DAD", "GOD", "GNG", //
    "WAX", "WTF", "OMG", "LOL", "WHO", "WUT", "LIM", "KIT", "BIG", "FAT",
    "TOD", "LIV", "JUP", "BOI", "WIN", "LSD", "DMT", "MOL", "ECO", "CRP",
    "BLM", "MGA", "DUD", "FUN", "SUX",
  ];
  return options[seed % options.length];
}
