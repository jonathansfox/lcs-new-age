# Localization Helper Scripts

This directory contains scripts to help with internationalization (i18n) of LCS New Age.

## find_translatable_strings.dart

Finds all user-facing strings in the codebase that should be translated.

### Usage

Run from the project root:

```bash
dart run scripts/find_translatable_strings.dart
```

### What It Does

1. Scans all `.dart` files in the `lib/` directory
2. Finds string literals passed to console wrapper functions (addstr, mvaddstr, addstrx, mvaddstrx)
3. Finds string literals in variable assignments and returns that are likely user-facing
4. Filters out technical strings, paths, IDs, and other non-user-facing content
5. Deduplicates and counts occurrences
6. Outputs a sorted list with file locations

### Output Format

```
"STRING_LITERAL" (count: N)
  path/to/file.dart:line (function)
  path/to/other_file.dart:line (function)
```

### Filtering

The script automatically excludes:
- Very short strings (< 4 chars)
- Strings that look like file paths or URLs
- Hex codes, IDs, or numeric values
- Technical strings (DEBUG, TODO, FIXME)
- Strings with only technical characters
- Empty or whitespace-only strings

### Use Cases

1. **Find new strings to translate**: Run the script and compare output to current ARB files
2. **Track translation coverage**: Monitor unique string count over time
3. **Identify frequently used strings**: High-count strings are priority for translation
4. **Audit codebase**: Find hardcoded user-facing text that should use the params API

### Example Workflow

```bash
# Find all translatable strings
dart run scripts/find_translatable_strings.dart > translatable_strings.txt

# Search for specific pattern
dart run scripts/find_translatable_strings.dart | grep "rescue"

# Count total unique strings
dart run scripts/find_translatable_strings.dart | grep "Total:" | awk '{print $2}'
```

### Notes

- This is a heuristic tool - some false positives/negatives may occur
- Manual review of results is recommended
- Focus on high-count strings first for translation priority
- Console wrapper calls are the primary target for translation
