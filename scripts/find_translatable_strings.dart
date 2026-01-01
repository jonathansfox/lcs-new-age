#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

void main(List<String> args) async {
  print('Finding translatable strings in LCS New Age...\n');

  final scriptDir = Directory.current;
  Directory libDir;

  if (Directory('lib').existsSync()) {
    libDir = Directory('lib');
  } else if (Directory('..${Platform.pathSeparator}lib').existsSync()) {
    libDir = Directory('..${Platform.pathSeparator}lib');
  } else {
    print(
      'Error: lib/ directory not found (searched in $scriptDir and parent)',
    );
    exit(1);
  }

  if (!libDir.existsSync()) {
    print('Error: lib/ directory not found');
    exit(1);
  }

  final stringInfo = <String, StringInfo>{};

  await for (final entity in libDir.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final file = entity;
      final content = await file.readAsString();
      final lines = content.split('\n');

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final lineNumber = i + 1;

        // Find strings passed to console wrapper functions
        final consoleCallPatterns = [
          (RegExp(r'\baddstr\s*\(\s*"([^"]+)"'), 'addstr'),
          (RegExp(r"\baddstr\s*\(\s*'([^']+)'"), 'addstr'),
          (RegExp(r'\bmvaddstr\s*\([^,]+,\s*[^,]+,\s*"([^"]+)"'), 'mvaddstr'),
          (RegExp(r"\bmvaddstr\s*\([^,]+,\s*[^,]+,\s*'([^']+)'"), 'mvaddstr'),
          (RegExp(r'\baddstrx\s*\(\s*"([^"]+)"'), 'addstrx'),
          (RegExp(r"\baddstrx\s*\(\s*'([^']+)'"), 'addstrx'),
          (RegExp(r'\bmvaddstrx\s*\([^,]+,\s*[^,]+,\s*"([^"]+)"'), 'mvaddstrx'),
          (RegExp(r"\bmvaddstrx\s*\([^,]+,\s*[^,]+,\s*'([^']+)'"), 'mvaddstrx'),
        ];

        for (final entry in consoleCallPatterns) {
          final pattern = entry.$1;
          final function = entry.$2;

          for (final match in pattern.allMatches(line)) {
            final stringLiteral = match.group(1);
            if (stringLiteral != null && _isUserFacing(stringLiteral)) {
              final relativePath = file.path.replaceFirst(
                '${libDir.path}/',
                '',
              );
              final key = stringLiteral;

              stringInfo.putIfAbsent(
                key,
                () => StringInfo(text: stringLiteral, locations: [], count: 0),
              );

              final info = stringInfo[key]!;
              info.count++;
              if (!info.locations.any((l) => l.contains(relativePath))) {
                info.locations.add('$relativePath:$lineNumber ($function)');
              }
            }
          }
        }

        // Find string literals in variable assignments or returns that might be user-facing
        final otherPatterns = [
          RegExp(r'\b([a-zA-Z_]\w*)\s*=\s*"([^"]{10,})"'),
          RegExp(r"\b([a-zA-Z_]\w*)\s*=\s*'([^']{10,})'"),
          RegExp(r'return\s+"([^"]{10,})"'),
          RegExp(r"return\s+'([^']{10,})'"),
        ];

        for (final pattern in otherPatterns) {
          for (final match in pattern.allMatches(line)) {
            final stringLiteral = match.group(match.groupCount);
            if (stringLiteral != null && _isUserFacing(stringLiteral)) {
              final relativePath = file.path.replaceFirst(
                '${libDir.path}/',
                '',
              );
              final key = stringLiteral;

              stringInfo.putIfAbsent(
                key,
                () => StringInfo(text: stringLiteral, locations: [], count: 0),
              );

              final info = stringInfo[key]!;
              info.count++;
              if (!info.locations.any((l) => l.contains(relativePath))) {
                info.locations.add(
                  '$relativePath:$lineNumber (variable/return)',
                );
              }
            }
          }
        }
      }
    }
  }

  // Output results
  final sortedStrings = stringInfo.values.toList();
  sortedStrings.sort((a, b) => b.count.compareTo(a.count));

  print('Found ${sortedStrings.length} unique translatable strings\n');
  print('Format: STRING_LITERAL (count: N)');
  print('Locations: file.dart:line (context)\n');
  final separator = '=' * 80;
  print(separator);

  for (final info in sortedStrings) {
    print('');
    print('"${info.text}" (count: ${info.count})');
    for (final location in info.locations) {
      print('  $location');
    }
  }

  print('\n$separator');
  print('\nTotal: ${sortedStrings.length} strings');
}

bool _isUserFacing(String str) {
  // Very short strings (likely not meaningful)
  if (str.length < 4) return false;

  // Empty or whitespace only
  if (str.trim().isEmpty) return false;

  // Strings that look like file paths or URLs
  if (str.contains('/') || str.contains('\\')) return false;

  // Strings that look like hex codes or IDs
  if (RegExp(r'^[0-9a-fA-FxX]+$').hasMatch(str)) return false;

  // Strings that look like numeric values
  if (RegExp(r'^[\d.]+$').hasMatch(str)) return false;

  // Common internal/debug strings
  if (str.startsWith('@@')) return false;
  if (str.toUpperCase().startsWith('DEBUG')) return false;
  if (str.toUpperCase().startsWith('TODO')) return false;
  if (str.toUpperCase().startsWith('FIXME')) return false;

  // Strings that are purely technical characters
  final techPattern = RegExp(
    r'^[a-zA-Z0-9_./\\$@#%&*+\-=\[\]{}()|;:<>?,!\"]+$',
  );
  if (techPattern.hasMatch(str)) {
    return false;
  }

  // Include if it contains letters and has some meaningful content
  final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(str);
  final hasContent = str.length >= 3;

  return hasLetters && hasContent;
}

class StringInfo {
  StringInfo({
    required this.text,
    required this.locations,
    required this.count,
  });

  String text;
  List<String> locations;
  int count;
}
