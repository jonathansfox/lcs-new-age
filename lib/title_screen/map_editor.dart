import 'dart:convert';

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

  // Enable mouse events for drag functionality
  console.enableMouseEvents((y, x, isDown) {
    if (x >= 0 && x < MAPX && y - 1 >= 0 && y - 1 < MAPY) {
      if (isDown) {
        isDragging = true;
      } else {
        isDragging = false;
      }

      if (isDragging &&
          (selectedTileType != null || selectedSpecialType != null)) {
        SiteTile tile = levelMap[x][y - 1][currentFloor];
        if (selectedTileType != null) {
          selectedTileType.setter(tile);
        } else if (selectedSpecialType != null) {
          tile.special = selectedSpecialType.special;
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

    // Add floor display and controls
    setColor(lightGray);
    mvaddstr(0, 0, "Floor ${currentFloor + 1}");
    addOptionText(24, 0, "X", "X - Exit Map Editor");
    addOptionText(24, 24, nextPageStr.split(" ").first, "$nextPageStr Floor");
    addstr(" / ");
    addInlineOptionText(
        previousPageStr.split(" ").first, "$previousPageStr Floor");
    addOptionText(24, 60, "E", "E - Export Map");

    // Add tile buttons
    setColor(lightGray);
    mvaddstr(1, MAPX + 1, "Tiles");
    for (int i = 0; i < tileTypes.length; i++) {
      int row = i ~/ 8;
      int col = i % 8;
      setColor(tileTypes[i].color);
      addOptionText(
        2 + row,
        MAPX + 1 + col,
        "tile_$i",
        tileTypes[i].symbol,
        baseColorKey: ColorKey.fromColor(tileTypes[i].color),
        highlightColorKey: ColorKey.fromColor(tileTypes[i].color),
      );
    }

    // Add special buttons
    setColor(lightGray);
    mvaddstr(6, MAPX + 1, "Specials");
    for (int i = 0; i < specialTypes.length; i++) {
      int row = i ~/ 8;
      int col = i % 8;
      setColor(specialTypes[i].color);
      addOptionText(
        7 + row,
        MAPX + 1 + col,
        "special_$i",
        specialTypes[i].symbol,
        baseColorKey: ColorKey.fromColor(specialTypes[i].color),
        highlightColorKey: ColorKey.fromColor(specialTypes[i].color),
      );
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
