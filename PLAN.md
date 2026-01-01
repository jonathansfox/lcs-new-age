# LCS-New-Age Localization Implementation Plan

## Overview
This document outlines a phased approach to implementing internationalization (i18n) and localization (l10n) for Liberal Crime Squad: New Age, preserving the existing curses-style architecture while enabling multi-language support.

## Architecture Decisions

### Translation Format
- **Primary**: ARB (Application Resource Bundle) format for Dart/Flutter compatibility
- **Export**: PO (Portable Object) format for translator tooling compatibility
- **Tools**: Dart `intl` package with custom ARB→PO conversion scripts

### Message Key Strategy
- **Source Text Keys**: Use English strings as identifiers for codebase readability
- **Test Coverage**: Create analyzers to detect i18n coverage breakage during testing
- **Fallback**: English text as ultimate fallback for missing translations

### Scope & Approach
- **Initial**: Minimal implementation with console wrapper pattern
- **Evolution**: Phased expansion to comprehensive coverage
- **Plurals**: ICU Message Format where possible, preserve game logic where intertwined

### Language Support
- **Current**: Left-to-right languages only
- **Switching**: Dynamic language switching (fallback to static if too complex)
- **Workflow**: Manual translation management, community-ready architecture

## Phase 1: Foundation (Week 1-2) ✅ COMPLETE

### 1.1 Core Infrastructure ✅
- ✅ Add `intl` package to `pubspec.yaml`
- ✅ Create `lib/i18n/` module structure
- ✅ Implement `LcsI18n` class with basic translation functions
- ✅ Add ARB file structure in `lib/l10n/`
- ✅ Create console wrapper functions in `engine.dart`
- ✅ Initialize LcsI18n in `launch_game.dart`

### 1.2 Console Output Interception ✅
- ✅ Wrap `addstr()` and `mvaddstr()` in `engine.dart`
- ✅ Wrap `addstrx()` and `mvaddstrx()` in `engine.dart`
- ✅ Add translation lookup before console output
- ✅ Implement fallback to English for missing translations
- ✅ Test with pseudo-translation (e.g., prefix "[!!]")
- ✅ **Add transparent params support for formatting and plurals**

### 1.3 Build Integration ✅
- ✅ Configure `intl_translation` for message extraction
- ✅ Set up build_runner integration (via pubspec.yaml)
- ✅ Create initial ARB files from existing strings (skeleton exists)
- ✅ Add basic test coverage for translation functions
- ✅ Add integration tests for console wrapper functions

### 1.4 Language Switching ✅
- ✅ Implement locale detection/selection (basic `setLocale()` method loads ARB files)
- ✅ Add runtime language switching (setLocale actually loads translations)
- ⏳ Create language selection UI (basic)
- ⏳ Test dynamic switching vs. restart requirement

## Phase 2: Core Content (Week 3-4)

### 2.1 High-Frequency Modules
Target modules with highest output volume:
- [ ] `sitemode/fight.dart` (296 console calls)
- [ ] `talk/drop_a_pickup_line.dart` (271 console calls)
- [ ] `common_display/print_creature_info.dart` (155 console calls)

### 2.2 String Pattern Refactoring
- [ ] Convert string interpolation to parameterized messages
- [ ] Replace concatenation patterns with message templates
- [ ] Implement ICU plural handling for common patterns
- [ ] Add context metadata for ambiguous strings

### 2.3 Translation Files
- [ ] Create comprehensive English ARB template
- [ ] Add placeholder metadata for all parameters
- [ ] Implement ARB→PO export scripts
- [ ] Create translation guidelines document

### 2.4 Quality Assurance
- [ ] Add pseudo-translation testing
- [ ] Implement missing translation logging
- [ ] Create coverage analysis tools
- [ ] Add regression tests for translation integrity

## Phase 3: Advanced Features (Week 5-6)

### 3.1 Complex Grammar
- [ ] Identify grammar-dependent code patterns
- [ ] Implement gender-aware messages where needed
- [ ] Handle possessive forms and articles
- [ ] Create custom formatters for game-specific terms

### 3.2 Module Expansion
Continue with remaining high-volume modules:
- [ ] `daily/siege.dart` (143 console calls)
- [ ] `sitemode/site_display.dart` (143 console calls)
- [ ] `basemode/review_mode.dart` (129 console calls)
- [ ] `daily/dating.dart` (127 console calls)

### 3.3 Tooling Enhancement
- [ ] Develop automated string extraction tools
- [ ] Create translation validation scripts
- [ ] Implement coverage reporting
- [ ] Add pre-commit hooks for i18n validation

## Phase 4: Comprehensive Coverage (Week 7-8)

### 4.1 Remaining Modules
Complete all 74 files with console output:
- [ ] Medium-volume modules (50-100 console calls each)
- [ ] Low-volume modules (under 50 console calls each)
- [ ] Error messages and system notifications
- [ ] Title screen and menu systems

### 4.2 Advanced ICU Features
- [ ] Implement select() for gender/condition-based text
- [ ] Add ordinal number handling
- [ ] Create date/time localization
- [ ] Handle currency and number formatting

### 4.3 Community Preparation
- [ ] Document translation workflow
- [ ] Create translator guidelines
- [ ] Set up contribution templates
- [ ] Prepare for external translation platforms

## Phase 5: Production Readiness (Week 9-10)

### 5.1 Performance Optimization
- [ ] Optimize translation lookup performance
- [ ] Implement translation caching
- [ ] Reduce memory footprint
- [ ] Profile and optimize startup time

### 5.2 Testing & Validation
- [ ] Comprehensive testing across all languages
- [ ] UI layout testing with different text lengths
- [ ] Edge case handling (empty strings, special characters)
- [ ] Performance testing with large translation sets

### 5.3 Documentation & Maintenance
- [ ] Complete developer documentation
- [ ] Create maintenance procedures
- [ ] Document analyzer configuration
- [ ] Prepare release notes

## Technical Implementation Details

### Core API - NCurses-Style with Transparent Translation

The API is designed to be as NCurses-like as possible while supporting full internationalization:

- **Simple strings:** `addstr("text")` - just write English
- **Parameters:** `addstr("{key} text", params: {"key": value})` - transparent formatting
- **Plurals:** `addstr("text {count}", params: {"count": n, "context": "plural_id"})` - transparent pluralization

No explicit `LcsI18n` calls needed in game code!

### Console Wrapper Pattern
```dart
// In lib/engine/engine.dart
void addstr(String s, {Map<String, dynamic>? params}) {
  String finalString = s;
  if (params != null) {
    // Handle plurals if count is provided with a context
    final count = params['count'];
    final pluralContext = params['context'] as String?;
    if (count is int && pluralContext != null) {
      finalString = LcsI18n.plural(count, context: pluralContext);
    } else {
      // Handle regular formatting
      finalString = LcsI18n.format(s, params);
    }
  } else {
    finalString = LcsI18n.translate(s);
  }
  console.addstr(finalString);
}

// All wrappers support params
void mvaddstr(int y, int x, String s, {Map<String, dynamic>? params});
void addstrx(String s, {Map<String, dynamic>? params, bool restoreOldColor = true, String? mouseClickKey});
void mvaddstrx(int y, int x, String s, {Map<String, dynamic>? params, bool restoreOldColor = true, String? mouseClickKey});
```

### Implementation Directives

**No generic plural contexts** - Game code keeps its business logic. Translation layer only looks up exact strings.

**Minimal code changes** - The transparent API means most strings work unchanged. Only change string interpolation to params when adding translations.

**Add translations incrementally** - As strings are encountered during development/play, add them to ARB files. No mass refactoring needed.

**Parameters (transparent formatting):**
```dart
// Before
addstr("$name has been rescued.");

// After - use placeholder + params
addstr("{name} has been rescued.", params: {"name": name});

mvaddstr(10, 5, "{attacker} hits {target}!", params: {
  "attacker": attacker.name,
  "target": target.name
});
```

**Plurals (transparent pluralization):**
```dart
// Before (manual plural logic)
if (numEscaped == 1) {
  mvaddstr(11, 1, "Another imprisoned LCS member also gets out!");
} else if (numEscaped > 1) {
  mvaddstr(11, 1, "$numEscaped other LCS members escape in the riot!");
}

// After - clean and NCurses-like!
mvaddstr(11, 1, "{count} other LCS members escape in the riot!",
         params: {"count": numEscaped, "context": "members_escape"});
```



### Parameter Handling Logic

When `params` is provided to console wrappers:

1. **If contains both `count` (int) and `context` (String):** Uses ICU plural rules
   ```dart
   addstr("You have {count} items.", params: {
     "count": 5,
     "context": "inventory_items"
   });
   // English: "You have 5 items."
   // Portuguese: "Você tem 5 itens."
   ```

2. **Otherwise:** Uses string formatting
   ```dart
   addstr("Hello {name}!", params: {"name": "World"});
   // English: "Hello World!"
   // Portuguese: "Olá World!"
   ```

### LcsI18n Class (lib/i18n/i18n.dart)

```dart
class LcsI18n {
  // Initialize translation system
  static Future<void> initialize([String locale = 'en_US']);

  // Change locale at runtime
  static Future<void> setLocale(String locale);

  // Translate literal English string (used internally by wrappers)
  static String translate(String englishText, {String? context});

  // Format string with named parameters (used internally by wrappers)
  static String format(String englishTemplate, Map<String, dynamic> params);

  // Handle plural forms using ICU (used internally by wrappers)
  static String plural(int count, {required String context});

  // Get missing translations for coverage analysis
  static Set<String> getMissingTranslations();

  // Reset state (for testing)
  static void reset();
}
```

### Migration Strategy

**No code changes required** - The translation layer is transparent. Existing game code works as-is.

**Optional enhancements:**
- Replace `addstr("$name has been rescued")` with `addstr("{name} has been rescued", params: {"name": name})` when adding translations
- Manual plural logic stays in game code - translation layer handles string lookup transparently
- Add translations to ARB files as strings are encountered during play



## Risk Mitigation

### Technical Risks
- Performance: Implement caching and lazy loading (not needed for NCurses-style text game)
- Complexity: Use phased approach, start simple
- Maintenance: Automated analyzers and coverage checks

### Content Risks  
- Grammar Complexity: Preserve game logic where needed (no generic plurals - game code handles logic)
- Context Loss: Add metadata and translator notes
- Scope Creep: Strict adherence to phased plan

## Current Status

**Last Updated**: 2025-01-01

### Phase 1: Complete ✅

**Completed:**
- Core i18n infrastructure (`LcsI18n` class)
- Console wrapper functions (`addstr`, `mvaddstr`, `addstrx`, `mvaddstrx`) with params support
- Translation system initialization in game launch
- ARB file structure (`lib/l10n/` with `app_en.arb` and `app_pt.arb`)
- ARB file loading mechanism (reads JSON from assets)
- Translation lookup from ARB files
- Runtime language switching (`setLocale()` loads ARB files)
- Portuguese translations as prototype
- Language selection submenu in title screen
- Language persistence in gameOptions

## Next Steps

1. **Begin Phase 2** 🚀
   - Start with **low-frequency, simple modules** to build confidence before complex ones
   - **Recommended starting modules:**
     - `lib/basemode/help_system.dart` (1 console call) - help system descriptions
     - `lib/creature/sort_creatures.dart` (1 console call) - sorting descriptions  
     - `lib/daily/hostages/release.dart` (1 console call) - hostage release
     - `lib/items/item.dart` (1 console call) - item display
     - `lib/newspaper/major_event.dart` (1 console call) - news event
     - `lib/utils/interface_options.dart` (1 console call) - interface display
     - `lib/title_screen/title_screen.dart` (2 console calls) - title screen
     - `lib/title_screen/new_game.dart` (1 console call) - new game screen

2. **Refactoring approach:**
   - Convert string interpolation → params **only when adding translations**
   - Keep manual plurals in game code (translation layer handles lookup, not logic)
   - Add translations to ARB files as strings are encountered
   - No mass refactoring - incremental, transparent approach

3. **Note on locale-specific content:**
   - Some strings (names, jokes, cultural references) only make sense in specific locales
   - **Goal for future:** Properly localize these instead of literal translation
   - **For now:** Translate literally, or keep English when locale-specific
   - **Do not add generic plural contexts** - let game logic handle complexity
   - When locale-specific humor doesn't translate, accept literal translation

4. **Example demonstration:**
   - **Parameterized strings found** in low-frequency modules:
   - `lib/daily/activities/recruiting.dart`:
     ```dart
     mvaddstr(11, 0, "${cr.name} asks around for a $name...");
     mvaddstrc(10, 0, lightGray, "${cr.name} managed to set up a meeting with ");
     ```
   - These are perfect for conversion to params API when adding translations:
   ```dart
     _body("{squad} asks around for a {location} will not be "
         "able to do anything else that day.", 
         params: {"squad": squadName, "location": locationName});
     ```
   - This could be refactored to use params when adding translations:
   ```dart
   _body("{squad} acting with their squad to visit a {location} will not "
         "be able to do anything else that day.", 
         params: {"squad": squadName, "location": locationName});
   ```
   - This could be refactored to use params when adding translations:
   ```dart
   _body("{squad} acting with their squad to visit a {location} will not "
         "be able to do anything else that day.", 
         params: {"squad": squadName, "location": locationName});
   ```

1. **Immediate**: Complete Phase 1.4 (language selection UI)
   - Add simple language selection menu in title screen
   - Persist language preference to gameOptions
   - Test language switching in actual gameplay

2. **Next**: Begin Phase 2 (high-frequency module refactoring)
   - Start with `sitemode/fight.dart` (296 console calls)
   - Convert string interpolation to params
   - Add plural contexts for complex plural scenarios
   - Expand translation coverage in both languages

3. **Review**: Validate plan with stakeholders
4. **Testing**: Expand test coverage as modules are refactored
5. **Documentation**: Keep this plan updated with progress

---

*This plan is designed to be iterative and adaptable. Each phase builds upon the previous one while maintaining the ability to adjust based on lessons learned and stakeholder feedback.*
4. **Example demonstration:**
   - **Parameterized strings found** in low-frequency modules:
     ```dart
     mvaddstr(11, 0, "${p.name}'s corpse has been recovered.");
     mvaddstr(11, 0, "${p.name} has been rescued.");
     mvaddstr(11, 0, "The police confiscate everything");
     mvaddstr(11, 0, "The soldiers confiscate everything");
     mvaddstr(11, 0, ", including vehicles");
     mvaddstr(11, 0, "The compound fortifications are dismantled.");
     ```
   - These are perfect for conversion to params API when adding translations:
     ```dart
     mvaddstr(11, 0, "{p.name} has been recovered.", params: {"p": p.name});
     mvaddstr(11, 0, "{p.name} has been rescued.", params: {"p": p.name});
     mvaddstr(11, 0, "The police confiscate everything", params: {});
     mvaddstr(11, 0, "The soldiers confiscate everything", params: {});
     mvaddstr(11, 0, ", including vehicles", params: {});
     mvaddstr(11, 0, "The compound fortifications are dismantled.", params: {});
     ```

5. **Testing:** Verify translations work in actual gameplay after each module refactored
