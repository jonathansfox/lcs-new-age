import 'dart:convert';
import 'dart:math' as math;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';
import 'package:lcs_new_age/sitemode/sitemap_from_dame.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';

// Tile types and their properties
class TileType {
  const TileType(this.name, this.symbol, this.color, this.setter, this.key);
  final String name;
  final String symbol;
  final Color color;
  final void Function(SiteTile) setter;
  final String key;
}

final List<TileType> tileTypes = [
  TileType("Wall", "#", darkGray, (tile) => tile.wall = true, "wall"),
  TileType("Door", "+", lightGray, (tile) => tile.door = true, "door"),
  TileType("Locked Door", "+", red, (tile) {
    tile.door = true;
    tile.locked = true;
  }, "locked_door"),
  TileType("Exit", "X", lightGray, (tile) => tile.exit = true, "exit"),
  TileType("Grass", "\"", green, (tile) => tile.grass = true, "grass"),
  TileType("Chainlink", "|", lightGray, (tile) => tile.chainlink = true,
      "chainlink"),
  TileType(
      "Metal Wall", "H", lightGray, (tile) => tile.metal = true, "metal_wall"),
  TileType("Restricted", ".", blue, (tile) {
    tile.wall = false;
    tile.door = false;
    tile.exit = false;
    tile.grass = false;
    tile.chainlink = false;
    tile.metal = false;
    tile.restricted = true;
  }, "restricted"),
  TileType("Floor", ".", lightGray, (tile) {
    tile.wall = false;
    tile.door = false;
    tile.exit = false;
    tile.grass = false;
    tile.chainlink = false;
    tile.metal = false;
    tile.restricted = false;
  }, "floor"),
];

// Special types and their properties
class SpecialType {
  const SpecialType(this.name, this.symbol, this.color, this.special, this.key);
  final String name;
  final String symbol;
  final Color color;
  final TileSpecial special;
  final String key;
}

final List<SpecialType> specialTypes = [
  const SpecialType(
      "Stairs Up", "^", yellow, TileSpecial.stairsUp, "stairs_up"),
  const SpecialType(
      "Stairs Down", "v", yellow, TileSpecial.stairsDown, "stairs_down"),
  const SpecialType("Table", "=", yellow, TileSpecial.table, "table"),
  const SpecialType("Computer", "C", yellow, TileSpecial.computer, "computer"),
  const SpecialType(
      "Park Bench", "B", yellow, TileSpecial.parkBench, "park_bench"),
  const SpecialType("Sign 1", "1", yellow, TileSpecial.signOne, "sign_one"),
  const SpecialType("Sign 2", "2", yellow, TileSpecial.signTwo, "sign_two"),
  const SpecialType("Sign 3", "3", yellow, TileSpecial.signThree, "sign_three"),
  const SpecialType(
      "Bank Vault", "V", yellow, TileSpecial.bankVault, "bank_vault"),
  const SpecialType(
      "Bank Teller", "T", yellow, TileSpecial.bankTeller, "bank_teller"),
  const SpecialType(
      "Bank Money", "\$", yellow, TileSpecial.bankMoney, "bank_money"),
  const SpecialType("Armory", "A", yellow, TileSpecial.armory, "armory"),
  const SpecialType("CEO Safe", "S", yellow, TileSpecial.ceoSafe, "ceo_safe"),
  const SpecialType(
      "CEO Office", "O", yellow, TileSpecial.ceoOffice, "ceo_office"),
  const SpecialType("Corporate Files", "F", yellow, TileSpecial.corporateFiles,
      "corporate_files"),
  const SpecialType("Radio Studio", "R", yellow,
      TileSpecial.radioBroadcastStudio, "radio_studio"),
  const SpecialType("Cable Studio", "C", yellow,
      TileSpecial.cableBroadcastStudio, "cable_studio"),
  const SpecialType(
      "Landlord", "L", yellow, TileSpecial.apartmentLandlord, "landlord"),
  const SpecialType("Bouncer", "B", yellow, TileSpecial.clubBouncer, "bouncer"),
  const SpecialType("Security Check", "C", yellow,
      TileSpecial.securityCheckpoint, "security_check"),
  const SpecialType("Metal Detector", "M", yellow,
      TileSpecial.securityMetalDetectors, "metal_detector"),
  const SpecialType(
      "Caged Rabbits", "r", yellow, TileSpecial.cagedRabbits, "caged_rabbits"),
  const SpecialType("Caged Monsters", "m", yellow, TileSpecial.cagedMonsters,
      "caged_monsters"),
  const SpecialType("Police Lockup", "L", yellow,
      TileSpecial.policeStationLockup, "police_lockup"),
  const SpecialType("Courthouse Lockup", "L", yellow,
      TileSpecial.courthouseLockup, "courthouse_lockup"),
  const SpecialType(
      "Jury Room", "J", yellow, TileSpecial.courthouseJuryRoom, "jury_room"),
  const SpecialType("Prison Control", "P", yellow, TileSpecial.prisonControl,
      "prison_control"),
  const SpecialType("Intel Computer", "I", yellow,
      TileSpecial.intelSupercomputer, "intel_computer"),
  const SpecialType("Sweatshop Equip", "E", yellow,
      TileSpecial.sweatshopEquipment, "sweatshop_equip"),
  const SpecialType("Polluter Equip", "E", yellow,
      TileSpecial.polluterEquipment, "polluter_equip"),
  const SpecialType(
      "Lab Equipment", "E", yellow, TileSpecial.labEquipment, "lab_equip"),
  const SpecialType("Nuclear Control", "N", yellow,
      TileSpecial.nuclearControlRoom, "nuclear_control"),
  const SpecialType("Tent", "T", yellow, TileSpecial.tent, "tent"),
  const SpecialType("No Special", ".", yellow, TileSpecial.none, "no_special"),
];

// Add this function before the editMap function
(int id, String symbol) getSpecialInfo(TileSpecial special) {
  return switch (special) {
    TileSpecial.cagedRabbits => (1, 'r'),
    TileSpecial.cagedMonsters => (2, 'm'),
    TileSpecial.policeStationLockup => (3, 'L'),
    TileSpecial.courthouseLockup => (4, 'L'),
    TileSpecial.courthouseJuryRoom => (5, 'J'),
    TileSpecial.prisonControl => (6, 'P'),
    TileSpecial.prisonControlLow => (7, 'P'),
    TileSpecial.prisonControlMedium => (8, 'P'),
    TileSpecial.prisonControlHigh => (9, 'P'),
    TileSpecial.intelSupercomputer => (10, 'I'),
    TileSpecial.sweatshopEquipment => (11, 'E'),
    TileSpecial.polluterEquipment => (12, 'E'),
    TileSpecial.nuclearControlRoom => (13, 'N'),
    TileSpecial.ceoSafe => (14, 'S'),
    TileSpecial.ceoOffice => (15, 'O'),
    TileSpecial.corporateFiles => (16, 'F'),
    TileSpecial.radioBroadcastStudio => (17, 'R'),
    TileSpecial.cableBroadcastStudio => (18, 'C'),
    TileSpecial.apartmentLandlord => (19, 'L'),
    TileSpecial.signOne => (20, '1'),
    TileSpecial.table => (21, '='),
    TileSpecial.computer => (22, 'C'),
    TileSpecial.parkBench => (23, 'B'),
    TileSpecial.stairsUp => (24, '^'),
    TileSpecial.stairsDown => (25, 'v'),
    TileSpecial.clubBouncer => (26, 'B'),
    TileSpecial.clubBouncerSecondVisit => (27, 'B'),
    TileSpecial.armory => (28, 'A'),
    TileSpecial.displayCase => (29, 'D'),
    TileSpecial.signTwo => (30, '2'),
    TileSpecial.signThree => (31, '3'),
    TileSpecial.securityCheckpoint => (32, 'C'),
    TileSpecial.securityMetalDetectors => (33, 'M'),
    TileSpecial.securitySecondVisit => (34, 'S'),
    TileSpecial.bankVault => (35, 'V'),
    TileSpecial.bankTeller => (36, 'T'),
    TileSpecial.bankMoney => (37, '\$'),
    TileSpecial.ccsBoss => (38, 'B'),
    TileSpecial.ovalOfficeNW => (39, 'O'),
    TileSpecial.ovalOfficeNE => (40, 'O'),
    TileSpecial.ovalOfficeSW => (41, 'O'),
    TileSpecial.ovalOfficeSE => (42, 'O'),
    _ => (0, '?'),
  };
}

// Flood fill function for fill mode
void floodFill(int startX, int startY, int floor, TileType newTileType) {
  if (startX < 0 || startX >= MAPX || startY < 0 || startY >= MAPY) return;

  SiteTile startTile = levelMap[startX][startY][floor];

  // Get the original tile type to match against
  bool originalWall = startTile.wall;
  bool originalDoor = startTile.door;
  bool originalExit = startTile.exit;
  bool originalGrass = startTile.grass;
  bool originalChainlink = startTile.chainlink;
  bool originalMetal = startTile.metal;
  bool originalRestricted = startTile.restricted;
  bool originalLocked = startTile.locked;

  // If the tile is already the target type, no need to fill
  bool isAlreadyTargetType = false;
  if (newTileType.key == "wall" && originalWall) {
    isAlreadyTargetType = true;
  } else if (newTileType.key == "door" && originalDoor && !originalLocked) {
    isAlreadyTargetType = true;
  } else if (newTileType.key == "locked_door" &&
      originalDoor &&
      originalLocked) {
    isAlreadyTargetType = true;
  } else if (newTileType.key == "exit" && originalExit) {
    isAlreadyTargetType = true;
  } else if (newTileType.key == "grass" && originalGrass) {
    isAlreadyTargetType = true;
  } else if (newTileType.key == "chainlink" && originalChainlink) {
    isAlreadyTargetType = true;
  } else if (newTileType.key == "metal_wall" && originalMetal) {
    isAlreadyTargetType = true;
  } else if (newTileType.key == "restricted" && originalRestricted) {
    isAlreadyTargetType = true;
  } else if (newTileType.key == "floor" &&
      !originalWall &&
      !originalDoor &&
      !originalExit &&
      !originalGrass &&
      !originalChainlink &&
      !originalMetal &&
      !originalRestricted) {
    isAlreadyTargetType = true;
  }

  if (isAlreadyTargetType) return;

  // Use a stack-based flood fill
  List<(int, int)> stack = [(startX, startY)];
  Set<(int, int)> visited = {};

  while (stack.isNotEmpty) {
    var (x, y) = stack.removeLast();

    if (x < 0 || x >= MAPX || y < 0 || y >= MAPY) continue;
    if (visited.contains((x, y))) continue;

    SiteTile tile = levelMap[x][y][floor];

    // Check if this tile matches the original type
    bool matchesOriginal = false;
    if (tile.wall == originalWall &&
        tile.door == originalDoor &&
        tile.exit == originalExit &&
        tile.grass == originalGrass &&
        tile.chainlink == originalChainlink &&
        tile.metal == originalMetal &&
        tile.restricted == originalRestricted &&
        tile.locked == originalLocked) {
      matchesOriginal = true;
    }

    if (!matchesOriginal) continue;

    visited.add((x, y));
    newTileType.setter(tile);

    // Add neighbors to stack
    stack.add((x + 1, y));
    stack.add((x - 1, y));
    stack.add((x, y + 1));
    stack.add((x, y - 1));
  }
}

// Preview map function - full screen view with vision and exploration
Future<void> previewMap(int floor) async {
  int playerX = MAPX >> 1; // Start at player spawn position
  int playerY = 1;

  // Create exploration map - tracks what has been seen
  List<List<bool>> explored =
      List.generate(MAPX, (x) => List.generate(MAPY, (y) => false));

  // Mark starting position as explored
  explored[playerX][playerY] = true;

  while (true) {
    erase();

    // Draw the map with vision and exploration
    for (int y = 0; y < MAPY; y++) {
      for (int x = 0; x < MAPX; x++) {
        if (explored[x][y]) {
          SiteTile tile = levelMap[x][y][floor];

          // Check if tile is visible from player position
          bool isVisible = isTileVisible(playerX, playerY, x, y, floor);

          if (isVisible) {
            // Draw tile normally
            String symbol = getTileSymbol(tile);
            Color color = getTileColor(tile);
            Color bgColor = getTileBackgroundColor(tile, true);

            // For normal walls, use background color as foreground to create solid blocks
            if (tile.wall &&
                !tile.burning &&
                !tile.neighbors().any((t) => t.megaBloody) &&
                !tile.neighbors().any((t) => t.graffitiLCS) &&
                !tile.neighbors().any((t) => t.graffitiCCS) &&
                !tile.neighbors().any((t) => t.graffitiOther)) {
              color = bgColor;
            }

            setColor(color, background: bgColor);
            mvaddstr(y, x, symbol);
          } else {
            // Draw as explored but not currently visible (darker)
            String symbol = getTileSymbol(tile);
            Color color = getTileColor(tile);
            Color bgColor = getTileBackgroundColor(tile, false);

            // For normal walls, use background color as foreground to create solid blocks
            if (tile.wall &&
                !tile.burning &&
                !tile.neighbors().any((t) => t.megaBloody) &&
                !tile.neighbors().any((t) => t.graffitiLCS) &&
                !tile.neighbors().any((t) => t.graffitiCCS) &&
                !tile.neighbors().any((t) => t.graffitiOther)) {
              color = bgColor;
            }

            setColor(color, background: bgColor);
            mvaddstr(y, x, symbol);
          }
        } else {
          // Unexplored - show as black space
          setColor(black);
          mvaddstr(y, x, " ");
        }
      }
    }

    // Draw player
    setColor(white);
    mvaddstr(playerY, playerX, "@");

    // Draw UI
    setColor(lightGray);
    mvaddstr(0, 0, "Preview Mode - Floor ${floor + 1}");
    mvaddstr(1, 0, "Position: ($playerX, $playerY)");

    // Show tile info at player position
    if (playerX >= 0 && playerX < MAPX && playerY >= 0 && playerY < MAPY) {
      SiteTile currentTile = levelMap[playerX][playerY][floor];
      String tileInfo = getTileDescription(currentTile);
      mvaddstr(2, 0, "Tile: $tileInfo");
    }

    refresh();

    // Handle input
    String key = await getKeyCaseSensitive();

    if (key == "X" || key == "Escape" || key == "q" || key == "Q") {
      return; // Exit preview
    } else if (key == "Up" || key == "8") {
      if (playerY > 0) {
        int newY = playerY - 1;
        if (canMoveTo(playerX, newY, floor)) {
          playerY = newY;
          exploreArea(playerX, playerY, floor, explored);
        }
      }
    } else if (key == "Down" || key == "2") {
      if (playerY < MAPY - 1) {
        int newY = playerY + 1;
        if (canMoveTo(playerX, newY, floor)) {
          playerY = newY;
          exploreArea(playerX, playerY, floor, explored);
        }
      }
    } else if (key == "Left" || key == "4") {
      if (playerX > 0) {
        int newX = playerX - 1;
        if (canMoveTo(newX, playerY, floor)) {
          playerX = newX;
          exploreArea(playerX, playerY, floor, explored);
        }
      }
    } else if (key == "Right" || key == "6") {
      if (playerX < MAPX - 1) {
        int newX = playerX + 1;
        if (canMoveTo(newX, playerY, floor)) {
          playerX = newX;
          exploreArea(playerX, playerY, floor, explored);
        }
      }
    }
  }
}

// Check if a tile is visible from the player position
bool isTileVisible(int fromX, int fromY, int toX, int toY, int floor) {
  // Simple line-of-sight check
  int dx = (toX - fromX).abs();
  int dy = (toY - fromY).abs();

  // If too far away, not visible
  if (dx > 8 || dy > 8) return false;

  // Check line of sight
  int steps = math.max(dx, dy);
  if (steps == 0) return true;

  double stepX = (toX - fromX) / steps;
  double stepY = (toY - fromY) / steps;

  for (int i = 1; i < steps; i++) {
    int checkX = (fromX + stepX * i).round();
    int checkY = (fromY + stepY * i).round();

    if (checkX >= 0 && checkX < MAPX && checkY >= 0 && checkY < MAPY) {
      SiteTile tile = levelMap[checkX][checkY][floor];
      if (tile.wall || tile.door || tile.metal || tile.chainlink) {
        return false; // Blocked by wall/door
      }
    }
  }

  return true;
}

// Check if player can move to a position
bool canMoveTo(int x, int y, int floor) {
  if (x < 0 || x >= MAPX || y < 0 || y >= MAPY) return false;

  SiteTile tile = levelMap[x][y][floor];

  // Can't move through walls, metal, or chainlink
  if (tile.wall || tile.metal || tile.chainlink) return false;

  // Can move through doors, exits, grass, restricted areas, and floors
  return true;
}

// Explore area around player position
void exploreArea(
    int centerX, int centerY, int floor, List<List<bool>> explored) {
  // Mark current position and surrounding area as explored
  for (int dy = -2; dy <= 2; dy++) {
    for (int dx = -2; dx <= 2; dx++) {
      int x = centerX + dx;
      int y = centerY + dy;

      if (x >= 0 && x < MAPX && y >= 0 && y < MAPY) {
        if (isTileVisible(centerX, centerY, x, y, floor)) {
          explored[x][y] = true;
        }
      }
    }
  }
}

// Get tile symbol for display (using sitemode graphics)
String getTileSymbol(SiteTile tile) {
  if (tile.wall) {
    if (tile.burning) return "¤";
    if (tile.neighbors().any((t) => t.megaBloody)) return " ";
    if (tile.neighbors().any((t) => t.graffitiLCS)) return "L";
    if (tile.neighbors().any((t) => t.graffitiCCS)) return "C";
    if (tile.neighbors().any((t) => t.graffitiOther)) return "g";
    return " ";
  }
  if (tile.door) {
    if (tile.right?.wall == true || tile.left?.wall == true) {
      return "\u2550"; // Horizontal door
    } else {
      return "\u2551"; // Vertical door
    }
  }
  if (tile.special == TileSpecial.stairsUp) return "↑";
  if (tile.special == TileSpecial.stairsDown) return "↓";
  if (tile.exit) return "X";
  if (tile.firePeak) return "₰";
  if (tile.fireEnd) return "৵";
  if (tile.fireStart) return "¤";
  if (tile.special != TileSpecial.none) {
    return switch (tile.special) {
      TileSpecial.apartmentLandlord => "L",
      TileSpecial.armory => "A",
      TileSpecial.bankMoney => "\$",
      TileSpecial.bankTeller => "T",
      TileSpecial.bankVault => "V",
      TileSpecial.cableBroadcastStudio => "S",
      TileSpecial.cagedMonsters => "#",
      TileSpecial.cagedRabbits => "#",
      TileSpecial.ccsBoss => "!",
      TileSpecial.ceoOffice => "O",
      TileSpecial.ceoSafe => "\$",
      TileSpecial.nursingHomeFiles => "\$",
      TileSpecial.nursingHomeManager => "O",
      TileSpecial.nursingHomePatient => "P",
      TileSpecial.nursingHomePatientDone => "P",
      TileSpecial.insuranceFiles => "\$",
      TileSpecial.insuranceCEO => "O",
      TileSpecial.clubBouncer => "B",
      TileSpecial.clubBouncerSecondVisit => "B",
      TileSpecial.computer => "c",
      TileSpecial.corporateFiles => "\$",
      TileSpecial.courthouseJuryRoom => "J",
      TileSpecial.courthouseLockup => "#",
      TileSpecial.displayCase => "d",
      TileSpecial.polluterEquipment => "P",
      TileSpecial.sweatshopEquipment => "S",
      TileSpecial.labEquipment => "L",
      TileSpecial.stairsDown => "↓",
      TileSpecial.stairsUp => "↑",
      TileSpecial.none => "?",
      TileSpecial.policeStationLockup => "#",
      TileSpecial.prisonControl => "#",
      TileSpecial.prisonControlLow => "#",
      TileSpecial.prisonControlMedium => "#",
      TileSpecial.prisonControlHigh => "#",
      TileSpecial.intelSupercomputer => "C",
      TileSpecial.nuclearControlRoom => "C",
      TileSpecial.radioBroadcastStudio => "S",
      TileSpecial.signOne => "?",
      TileSpecial.table => "t",
      TileSpecial.tent => "t",
      TileSpecial.parkBench => "b",
      TileSpecial.signTwo => "?",
      TileSpecial.signThree => "?",
      TileSpecial.securityCheckpoint => "S",
      TileSpecial.securityMetalDetectors => "S",
      TileSpecial.securitySecondVisit => "S",
      TileSpecial.ovalOfficeNW => "┌",
      TileSpecial.ovalOfficeNE => "┐",
      TileSpecial.ovalOfficeSW => "└",
      TileSpecial.ovalOfficeSE => "┘",
    };
  }
  if (tile.siegeTrap) return "%";
  if (tile.loot) return "\$";
  if (tile.megaBloody) return ";";
  if (tile.grass) return ",";
  if (tile.debris) return "~";
  return "."; // Floor
}

// Get tile background color for display (using sitemode colors)
Color getTileBackgroundColor(SiteTile tile, bool isVisible) {
  if (tile.wall) {
    if (tile.burning) return isVisible ? lightGray : darkGray;
    if (tile.neighbors().any((t) => t.megaBloody)) return darkRed;
    if (tile.neighbors().any((t) => t.graffitiLCS)) {
      return isVisible ? lightGray : darkGray;
    }
    if (tile.neighbors().any((t) => t.graffitiCCS)) {
      return isVisible ? lightGray : darkGray;
    }
    if (tile.neighbors().any((t) => t.graffitiOther)) {
      return isVisible ? lightGray : darkGray;
    }
    return isVisible ? lightGray : darkGray;
  }
  if (tile.door) {
    if (tile.metal) return white;
    if (tile.burning) return black;
    if (tile.cantUnlock && tile.locked) return darkRed;
    return black;
  }
  return black; // Default background
}

// Get tile color for display (using sitemode colors)
Color getTileColor(SiteTile tile) {
  if (tile.wall) {
    if (tile.burning) return orange;
    if (tile.neighbors().any((t) => t.megaBloody)) return darkRed;
    if (tile.neighbors().any((t) => t.graffitiLCS)) return green;
    if (tile.neighbors().any((t) => t.graffitiCCS)) return darkRed;
    if (tile.neighbors().any((t) => t.graffitiOther)) return black;
    return lightGray; // Will be overridden by background color for solid walls
  }
  if (tile.door) {
    if (tile.metal) return white;
    if (tile.burning) return orange;
    if (tile.cantUnlock && tile.locked) return red;
    if (tile.knownLock && tile.locked) return darkGray;
    return yellow;
  }
  if (tile.special == TileSpecial.stairsUp ||
      tile.special == TileSpecial.stairsDown) {
    return yellow;
  }
  if (tile.exit) return yellow;
  if (tile.firePeak || tile.fireEnd || tile.fireStart) return orange;
  if (tile.special != TileSpecial.none) {
    return switch (tile.special) {
      TileSpecial.clubBouncer => red,
      TileSpecial.clubBouncerSecondVisit => red,
      TileSpecial.securityCheckpoint => red,
      TileSpecial.securityMetalDetectors => red,
      TileSpecial.ceoOffice => red,
      TileSpecial.ccsBoss => red,
      TileSpecial.ovalOfficeNW ||
      TileSpecial.ovalOfficeNE ||
      TileSpecial.ovalOfficeSW ||
      TileSpecial.ovalOfficeSE =>
        white, // Default for oval office
      _ => yellow,
    };
  }
  if (tile.siegeTrap) return yellow;
  if (tile.loot) return purple;
  if (tile.megaBloody) return red;
  if (tile.grass) {
    if (tile.bloody) return red;
    return lightGreen;
  }
  if (tile.debris) return lightGray;
  if (tile.restricted) return blue;
  if (tile.bloody) return red;
  return lightGray; // Floor
}

// Get tile description for UI
String getTileDescription(SiteTile tile) {
  if (tile.wall) {
    if (tile.burning) return "Burning Wall";
    if (tile.neighbors().any((t) => t.megaBloody)) return "Bloody Wall";
    if (tile.neighbors().any((t) => t.graffitiLCS)) return "LCS Graffiti Wall";
    if (tile.neighbors().any((t) => t.graffitiCCS)) return "CCS Graffiti Wall";
    if (tile.neighbors().any((t) => t.graffitiOther)) {
      return "Gang Graffiti Wall";
    }
    return "Wall";
  }
  if (tile.door) {
    if (tile.metal) return "Metal Door";
    if (tile.burning) return "Burning Door";
    if (tile.cantUnlock && tile.locked) return "Unlockable Door";
    if (tile.knownLock && tile.locked) return "Known Locked Door";
    return tile.locked ? "Locked Door" : "Door";
  }
  if (tile.special == TileSpecial.stairsUp) return "Stairs Up";
  if (tile.special == TileSpecial.stairsDown) return "Stairs Down";
  if (tile.exit) return "Exit";
  if (tile.firePeak) return "Fire Peak";
  if (tile.fireEnd) return "Fire End";
  if (tile.fireStart) return "Fire Start";
  if (tile.special != TileSpecial.none) {
    return switch (tile.special) {
      TileSpecial.apartmentLandlord => "Apartment Landlord",
      TileSpecial.armory => "Armory",
      TileSpecial.bankMoney => "Bank Money",
      TileSpecial.bankTeller => "Bank Teller",
      TileSpecial.bankVault => "Bank Vault",
      TileSpecial.cableBroadcastStudio => "Cable Studio",
      TileSpecial.cagedMonsters => "Caged Monsters",
      TileSpecial.cagedRabbits => "Caged Rabbits",
      TileSpecial.ccsBoss => "CCS Boss",
      TileSpecial.ceoOffice => "CEO Office",
      TileSpecial.ceoSafe => "CEO Safe",
      TileSpecial.nursingHomeFiles => "Nursing Home Files",
      TileSpecial.nursingHomeManager => "Nursing Home Manager",
      TileSpecial.nursingHomePatient => "Nursing Home Patient",
      TileSpecial.nursingHomePatientDone => "Nursing Home Patient (Done)",
      TileSpecial.insuranceFiles => "H. Insurance Files",
      TileSpecial.insuranceCEO => "H. Insurance CEO",
      TileSpecial.clubBouncer => "Club Bouncer",
      TileSpecial.clubBouncerSecondVisit => "Club Bouncer (2nd)",
      TileSpecial.computer => "Computer",
      TileSpecial.corporateFiles => "Corporate Files",
      TileSpecial.courthouseJuryRoom => "Jury Room",
      TileSpecial.courthouseLockup => "Courthouse Lockup",
      TileSpecial.displayCase => "Display Case",
      TileSpecial.polluterEquipment => "Polluter Equipment",
      TileSpecial.sweatshopEquipment => "Sweatshop Equipment",
      TileSpecial.labEquipment => "Lab Equipment",
      TileSpecial.stairsDown => "Stairs Down",
      TileSpecial.stairsUp => "Stairs Up",
      TileSpecial.none => "Unknown",
      TileSpecial.policeStationLockup => "Police Lockup",
      TileSpecial.prisonControl => "Prison Control",
      TileSpecial.prisonControlLow => "Prison Control (Low)",
      TileSpecial.prisonControlMedium => "Prison Control (Medium)",
      TileSpecial.prisonControlHigh => "Prison Control (High)",
      TileSpecial.intelSupercomputer => "Intel Supercomputer",
      TileSpecial.nuclearControlRoom => "Nuclear Control",
      TileSpecial.radioBroadcastStudio => "Radio Studio",
      TileSpecial.signOne => "Sign",
      TileSpecial.table => "Table",
      TileSpecial.tent => "Tent",
      TileSpecial.parkBench => "Park Bench",
      TileSpecial.signTwo => "Sign",
      TileSpecial.signThree => "Sign",
      TileSpecial.securityCheckpoint => "Security Checkpoint",
      TileSpecial.securityMetalDetectors => "Metal Detectors",
      TileSpecial.securitySecondVisit => "Security (2nd)",
      TileSpecial.ovalOfficeNW => "Oval Office (NW)",
      TileSpecial.ovalOfficeNE => "Oval Office (NE)",
      TileSpecial.ovalOfficeSW => "Oval Office (SW)",
      TileSpecial.ovalOfficeSE => "Oval Office (SE)",
    };
  }
  if (tile.siegeTrap) return "Siege Trap";
  if (tile.loot) return "Loot";
  if (tile.megaBloody) return "Mega Bloody";
  if (tile.grass) {
    if (tile.bloody) return "Bloody Grass";
    return "Grass";
  }
  if (tile.debris) return "Debris";
  if (tile.restricted) return "Restricted Area";
  if (tile.bloody) return "Bloody Floor";
  return "Floor";
}

Future<void> editMap(String mapName) async {
  // Clear any old map data
  for (SiteTile tile in levelMap.all) {
    tile.flag = 0;
    tile.special = TileSpecial.none;
    tile.siegeflag = 0;
  }

  // Load the map
  bool loaded = await readDAMEMap(mapName);
  if (!loaded) {
    // If no map exists, create a blank one
    for (SiteTile tile in levelMap.all) {
      tile.flag = 0;
    }
  }

  int currentFloor = 0;
  TileType? selectedTileType;
  SpecialType? selectedSpecialType;
  bool isDragging = false;
  int editMode = 0; // 0 = pencil, 1 = rectangle, 2 = fill
  int? dragStartX;
  int? dragStartY;
  int? dragCurrentX;
  int? dragCurrentY;

  // Enable mouse events for drag functionality
  console.enableMouseEvents((y, x, isDown) {
    dragCurrentX = x;
    dragCurrentY = y - 1;
    if (x >= 0 && x < MAPX && y - 1 >= 0 && y - 1 < MAPY) {
      if (editMode == 1) {
        // Rectangle mode: start on mouse down, commit on mouse up
        if (isDown) {
          if (!isDragging) {
            isDragging = true;
            dragStartX = x;
            dragStartY = y - 1;
          }
        } else {
          if (isDragging &&
              dragStartX != null &&
              dragStartY != null &&
              (selectedTileType != null || selectedSpecialType != null)) {
            int startX = dragStartX!;
            int startY = dragStartY!;
            int endX = dragCurrentX ?? x;
            int endY = dragCurrentY ?? (y - 1);

            if (startX > endX) {
              int t = startX;
              startX = endX;
              endX = t;
            }
            if (startY > endY) {
              int t = startY;
              startY = endY;
              endY = t;
            }

            for (int ry = startY; ry <= endY; ry++) {
              for (int rx = startX; rx <= endX; rx++) {
                SiteTile tile = levelMap[rx][ry][currentFloor];
                if (selectedTileType != null) {
                  selectedTileType.setter(tile);
                } else if (selectedSpecialType != null) {
                  tile.special = selectedSpecialType.special;
                }
              }
            }
          }

          isDragging = false;
          dragStartX = null;
          dragStartY = null;
        }
      } else if (editMode == 2) {
        // Fill mode: flood fill on click (tiles only)
        if (isDown && selectedTileType != null) {
          floodFill(x, y - 1, currentFloor, selectedTileType);
        }
      } else {
        // Pencil mode: paint continuously while dragging
        if (isDown) {
          isDragging = true;
          if (selectedTileType != null || selectedSpecialType != null) {
            SiteTile tile = levelMap[x][y - 1][currentFloor];
            if (selectedTileType != null) {
              selectedTileType.setter(tile);
            } else if (selectedSpecialType != null) {
              tile.special = selectedSpecialType.special;
            }
          }
        } else {
          isDragging = false;
        }
      }
    }
  });

  while (true) {
    erase();

    // Draw the map area
    for (int y = 1; y < MAPY; y++) {
      for (int x = 0; x < MAPX; x++) {
        SiteTile tile = levelMap[x][y - 1][currentFloor];
        String char = '.';
        Color color = lightGray;

        if (tile.wall) {
          char = '#';
          color = darkGray;
        } else if (tile.door) {
          char = '+';
          color = lightGray;
          if (tile.locked) {
            color = red;
          }
        } else if (tile.exit) {
          char = 'X';
          color = lightGray;
        } else if (tile.grass) {
          char = '"';
          color = green;
        } else if (tile.chainlink) {
          char = '|';
          color = lightGray;
        } else if (tile.metal) {
          char = 'H';
          color = lightGray;
        } else if (tile.special != TileSpecial.none) {
          (_, char) = getSpecialInfo(tile.special);
          color = yellow;
        } else if (tile.restricted) {
          char = '.';
          color = blue;
        }

        setColor(color);
        mvaddstrx(y, x, char);
      }
    }

    // Draw player start position indicator
    int playerStartX = MAPX >> 1; // Middle of map horizontally
    int playerStartY = 1; // Second row from top
    if (currentFloor == 0) {
      // Only show on ground floor
      SiteTile startTile = levelMap[playerStartX][playerStartY][currentFloor];

      // Determine color based on tile accessibility
      Color indicatorColor;
      if (startTile.wall ||
          startTile.door ||
          startTile.chainlink ||
          startTile.metal) {
        // Blocked - red
        indicatorColor = red;
      } else if (startTile.restricted) {
        // Restricted - yellow
        indicatorColor = yellow;
      } else {
        // Unrestricted and not blocked - green
        indicatorColor = green;
      }

      setColor(indicatorColor);
      mvaddstr(playerStartY + 1, playerStartX, "@"); // @ symbol for player
    }

    // Rectangle preview overlay while dragging (no map mutation)
    if (editMode == 1 &&
        isDragging &&
        dragStartX != null &&
        dragStartY != null &&
        (selectedTileType != null || selectedSpecialType != null) &&
        dragCurrentX != null &&
        dragCurrentY != null) {
      int startX = dragStartX!;
      int startY = dragStartY!;
      int endX = dragCurrentX!;
      int endY = dragCurrentY!;

      // Clamp to map bounds
      if (endX < 0) endX = 0;
      if (endX >= MAPX) endX = MAPX - 1;
      if (endY < 0) endY = 0;
      if (endY >= MAPY) endY = MAPY - 1;

      // Normalize rectangle
      if (startX > endX) {
        int t = startX;
        startX = endX;
        endX = t;
      }
      if (startY > endY) {
        int t = startY;
        startY = endY;
        endY = t;
      }

      String previewChar;
      Color previewColor;
      if (selectedTileType != null) {
        previewChar = selectedTileType.symbol;
        previewColor = selectedTileType.color;
      } else if (selectedSpecialType != null) {
        previewChar = selectedSpecialType.symbol;
        previewColor = selectedSpecialType.color;
      } else {
        previewChar = "?";
        previewColor = lightGray;
      }

      setColor(previewColor);
      for (int py = startY; py <= endY; py++) {
        for (int px = startX; px <= endX; px++) {
          mvaddstr(py + 1, px, previewChar);
        }
      }
    }

    // Add floor display and controls
    setColor(lightGray);
    mvaddstr(0, 0, "Floor ${currentFloor + 1}");
    addOptionText(24, 0, "X", "X - Exit");
    addOptionText(24, console.x + 2, nextPageStr.split(" ").first, nextPageStr);
    addstr(" / ");
    addInlineOptionText(previousPageStr.split(" ").first, previousPageStr);
    addOptionText(24, console.x + 2, "E", "E - Export");
    String modeText = switch (editMode) {
      0 => "R - Pencil Mode",
      1 => "R - Rectangle Mode",
      2 => "R - Fill Mode",
      _ => "R - Unknown Mode"
    };
    addOptionText(24, console.x + 2, "R", modeText);
    addOptionText(24, console.x + 2, "P", "P - Preview");

    // Add tile buttons
    setColor(lightGray);
    mvaddstr(1, MAPX + 1, "Tiles");
    for (int i = 0; i < tileTypes.length; i++) {
      int row = i ~/ 8;
      int col = i % 8;
      setColor(tileTypes[i].color);
      mvaddstr(2 + row, MAPX + 1 + col, tileTypes[i].symbol);
      // Register mouse region for clicking
      registerMouseRegion(2 + row, MAPX + 1 + col, 1, 1, "tile_$i");
    }

    // Add special buttons
    setColor(lightGray);
    mvaddstr(6, MAPX + 1, "Specials");
    for (int i = 0; i < specialTypes.length; i++) {
      int row = i ~/ 8;
      int col = i % 8;
      setColor(specialTypes[i].color);
      mvaddstr(7 + row, MAPX + 1 + col, specialTypes[i].symbol);
      // Register mouse region for clicking
      registerMouseRegion(7 + row, MAPX + 1 + col, 1, 1, "special_$i");
    }

    // Add hover feedback
    if (console.hoverX != null && console.hoverY != null) {
      // Check if hover coordinates are within map bounds
      if (console.hoverX! >= 0 &&
          console.hoverX! < MAPX &&
          console.hoverY! - 1 >= 0 &&
          console.hoverY! - 1 < MAPY) {
        SiteTile tile =
            levelMap[console.hoverX!][console.hoverY! - 1][currentFloor];
        setColor(lightGray);
        mvaddstr(
            23, 0, "Tile at (${console.hoverX}, ${console.hoverY! - 1}): ");
        if (tile.wall) {
          addstr("Wall");
        } else if (tile.door) {
          addstr("Door${tile.locked ? " (Locked)" : ""}");
        } else if (tile.exit) {
          addstr("Exit");
        } else if (tile.grass) {
          addstr("Grass");
        } else if (tile.chainlink) {
          addstr("Chainlink Fence");
        } else if (tile.metal) {
          addstr("Metal Wall");
        } else if (tile.special != TileSpecial.none) {
          addstr("Special: ${tile.special.name}");
        } else if (tile.restricted) {
          addstr("Restricted Area");
        } else {
          addstr("Floor");
        }
      }
      // Check if hover coordinates are within tile buttons area
      else if (console.hoverX! >= MAPX + 1 &&
          console.hoverX! < MAPX + 9 &&
          console.hoverY! >= 2 &&
          console.hoverY! < 6) {
        int index = (console.hoverY! - 2) * 8 + (console.hoverX! - (MAPX + 1));
        if (index < tileTypes.length) {
          setColor(lightGray);
          mvaddstr(23, 0, "Tile Type: ${tileTypes[index].name}");
        }
      }
      // Check if hover coordinates are within special buttons area
      else if (console.hoverX! >= MAPX + 1 &&
          console.hoverX! < MAPX + 9 &&
          console.hoverY! >= 7 &&
          console.hoverY! < 11) {
        int index = (console.hoverY! - 7) * 8 + (console.hoverX! - (MAPX + 1));
        if (index < specialTypes.length) {
          setColor(lightGray);
          mvaddstr(23, 0, "Special Type: ${specialTypes[index].name}");
        }
      }
    }

    // Show selected type
    setColor(lightGray);
    mvaddstr(23, 40, "Selected: ");
    if (selectedTileType != null) {
      addstr("Tile - ${selectedTileType.name}");
    } else if (selectedSpecialType != null) {
      addstr("Special - ${selectedSpecialType.name}");
    } else {
      addstr("None");
    }

    // Check for key press without blocking
    String key = checkKeyCaseSensitive();
    if (key == "X") {
      console.disableMouseEvents();
      return;
    } else if (key == "E" || key == "export_map") {
      await exportMap(mapName, currentFloor);
    } else if (key == "R") {
      editMode = (editMode + 1) % 3; // Cycle through 0, 1, 2
    } else if (key == "P") {
      await previewMap(currentFloor);
    } else if (isPageUp(key.codePoint) && currentFloor > 0) {
      currentFloor--;
    } else if (isPageDown(key.codePoint) && currentFloor < MAPZ - 1) {
      currentFloor++;
    } else if (key.startsWith("tile_")) {
      // Handle tile button clicks
      int index = int.parse(key.substring(5));
      if (index < tileTypes.length) {
        selectedTileType = tileTypes[index];
        selectedSpecialType = null;
      }
    } else if (key.startsWith("special_")) {
      // Handle special button clicks
      int index = int.parse(key.substring(8));
      if (index < specialTypes.length) {
        selectedSpecialType = specialTypes[index];
        selectedTileType = null;
      }
    } else if (key.startsWith("map_")) {
      // Handle map tile clicks
      List<String> parts = key.split("_");
      if (parts.length == 4) {
        int x = int.parse(parts[1]);
        int y = int.parse(parts[2]);
        int z = int.parse(parts[3]);
        SiteTile tile = levelMap[x][y][z];
        if (selectedTileType != null) {
          selectedTileType.setter(tile);
        } else if (selectedSpecialType != null) {
          tile.special = selectedSpecialType.special;
        }
      }
    }

    // Small delay to prevent excessive CPU usage
    await Future.delayed(const Duration(milliseconds: 16));
  }
}

Future<void> mapEditor() async {
  // Get the asset manifest to check for map files
  final manifest = await assetManifest;
  final assetKeys = manifest.listAssets();

  // Filter out district types and create a list of site types with their map status
  List<(SiteType, bool)> siteTypes = [];
  for (var type in SiteType.values) {
    // Skip district types
    if (type == SiteType.downtown ||
        type == SiteType.commercialDistrict ||
        type == SiteType.universityDistrict ||
        type == SiteType.industrialDistrict ||
        type == SiteType.outOfTown) {
      continue;
    }

    // Get the DAME map name for this site type
    String mapName = switch (type) {
      SiteType.tenement => "ApartmentIndustrial",
      SiteType.apartment => "ApartmentUniversity",
      SiteType.upscaleApartment => "ApartmentDowntown",
      SiteType.warehouse => "Warehouse",
      SiteType.homelessEncampment => "HomelessCamp",
      SiteType.drugHouse => "CrackHouse",
      SiteType.barAndGrill => "BarAndGrill",
      SiteType.bombShelter => "BombShelter",
      SiteType.bunker => "Bunker",
      SiteType.cosmeticsLab => "CosmeticsLab",
      SiteType.geneticsLab => "GeneticsLab",
      SiteType.policeStation => "PoliceStation",
      SiteType.courthouse => "Courthouse",
      SiteType.prison => "Prison",
      SiteType.intelligenceHQ => "IntelligenceHQ",
      SiteType.armyBase => "ArmyBase",
      SiteType.fireStation => "FireStation",
      SiteType.sweatshop => "Sweatshop",
      SiteType.dirtyIndustry => "Factory",
      SiteType.corporateHQ => "CorporateHQ",
      SiteType.ceoHouse => "CEOHouse",
      SiteType.amRadioStation => "RadioStation",
      SiteType.cableNewsStation => "CableNews",
      SiteType.juiceBar => "JuiceBar",
      SiteType.internetCafe => "InternetCafe",
      SiteType.latteStand => "LatteStand",
      SiteType.veganCoOp => "VeganCoOp",
      SiteType.publicPark => "Park",
      SiteType.bank => "Bank",
      SiteType.nuclearPlant => "NuclearPlant",
      SiteType.whiteHouse => "WhiteHouse",
      _ => "",
    };

    // Check if this site type has a DAME map
    bool hasMap = false;
    if (mapName.isNotEmpty) {
      hasMap = assetKeys.contains("assets/maps/mapCSV_${mapName}_Tiles.csv");
    }

    siteTypes.add((type, hasMap));
  }

  await pagedInterface(
    headerPrompt: "Select a site type to edit its map",
    headerKey: {4: "SITE TYPE", 30: "MAP STATUS"},
    footerPrompt:
        "Press a Letter to select a Site Type, or Enter to return to Mod Tools",
    count: siteTypes.length,
    pageSize: 20,
    lineBuilder: (y, key, index) {
      var (type, hasMap) = siteTypes[index];
      setColor(hasMap ? lightGreen : lightGray);
      addOptionText(y, 0, key, "$key - ${type.name}");
      mvaddstr(y, 30, hasMap ? "Has Map" : "No Map");
    },
    onChoice: (index) async {
      var (type, hasMap) = siteTypes[index];
      String mapName = switch (type) {
        SiteType.tenement => "ApartmentIndustrial",
        SiteType.apartment => "ApartmentUniversity",
        SiteType.upscaleApartment => "ApartmentDowntown",
        SiteType.warehouse => "Warehouse",
        SiteType.homelessEncampment => "HomelessCamp",
        SiteType.drugHouse => "CrackHouse",
        SiteType.barAndGrill => "BarAndGrill",
        SiteType.bombShelter => "BombShelter",
        SiteType.bunker => "Bunker",
        SiteType.cosmeticsLab => "CosmeticsLab",
        SiteType.geneticsLab => "GeneticsLab",
        SiteType.policeStation => "PoliceStation",
        SiteType.courthouse => "Courthouse",
        SiteType.prison => "Prison",
        SiteType.intelligenceHQ => "IntelligenceHQ",
        SiteType.armyBase => "ArmyBase",
        SiteType.fireStation => "FireStation",
        SiteType.sweatshop => "Sweatshop",
        SiteType.dirtyIndustry => "Factory",
        SiteType.corporateHQ => "CorporateHQ",
        SiteType.ceoHouse => "CEOHouse",
        SiteType.amRadioStation => "RadioStation",
        SiteType.cableNewsStation => "CableNews",
        SiteType.juiceBar => "JuiceBar",
        SiteType.internetCafe => "InternetCafe",
        SiteType.latteStand => "LatteStand",
        SiteType.veganCoOp => "VeganCoOp",
        SiteType.publicPark => "Park",
        SiteType.bank => "Bank",
        SiteType.nuclearPlant => "NuclearPlant",
        SiteType.whiteHouse => "WhiteHouse",
        _ => "",
      };
      await editMap(mapName);
      return false;
    },
    onOtherKey: (key) => key == Key.enter,
  );
}

Future<void> exportMap(String mapName, int floor) async {
  try {
    // Create tile data
    StringBuffer tileCsv = StringBuffer();

    // Create special data
    StringBuffer specialCsv = StringBuffer();

    // Add data for both files
    for (int y = 0; y < MAPY; y++) {
      List<String> tileRow = [];
      List<String> specialRow = [];

      for (int x = 0; x < MAPX; x++) {
        SiteTile tile = levelMap[x][y][floor];

        // Add tile data - using numeric IDs that match readMapCBTiles
        int tileId = 0; // default floor
        if (tile.wall) {
          tileId = 2; // SITEBLOCK_BLOCK
        } else if (tile.exit) {
          tileId = 3; // SITEBLOCK_EXIT
        } else if (tile.grass) {
          tileId = 4; // SITEBLOCK_GRASSY
        } else if (tile.door) {
          tileId = tile.locked ? 6 : 5; // 6 for locked door, 5 for normal door
        } else if (tile.restricted) {
          tileId = 7; // SITEBLOCK_RESTRICTED
        } else if (tile.chainlink) {
          tileId = 8; // SITEBLOCK_CHAINLINK
        } else if (tile.metal) {
          tileId = 10; // SITEBLOCK_BLOCK | SITEBLOCK_METAL
        }
        tileRow.add(tileId.toString());

        // Add special data if there is one - using numeric IDs that match readMapCBSpecials
        if (tile.special != TileSpecial.none) {
          var (specialId, _) = getSpecialInfo(tile.special);
          specialRow.add(specialId.toString());
        } else {
          specialRow.add("0");
        }
      }

      // Write the rows
      tileCsv.writeln(tileRow.join(","));
      specialCsv.writeln(specialRow.join(","));
    }

    // Save tile file
    String tileFilename =
        "mapCSV_$mapName${floor == 0 ? "" : floor + 1}_Tiles.csv";
    await FileSaver.instance.saveFile(
      name: tileFilename,
      bytes: Uint8List.fromList(utf8.encode(tileCsv.toString())),
      mimeType: MimeType.csv,
    );

    // Save special file
    String specialFilename =
        "mapCSV_$mapName${floor == 0 ? "" : floor + 1}_Specials.csv";
    await FileSaver.instance.saveFile(
      name: specialFilename,
      bytes: Uint8List.fromList(utf8.encode(specialCsv.toString())),
      mimeType: MimeType.csv,
    );

    // Show success message
    setColor(lightGreen);
    mvaddstr(22, 0, "Map exported successfully!");
    await Future.delayed(const Duration(seconds: 2));
  } catch (e) {
    // Show error message
    setColor(red);
    mvaddstr(22, 0, "Error exporting map: $e");
    await Future.delayed(const Duration(seconds: 2));
  }
}
