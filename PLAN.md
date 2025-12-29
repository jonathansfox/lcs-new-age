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

## Phase 1: Foundation (Week 1-2)

### 1.1 Core Infrastructure
- [ ] Add `intl` package to `pubspec.yaml`
- [ ] Create `lib/i18n/` module structure
- [ ] Implement `LcsI18n` class with basic translation functions
- [ ] Add ARB file structure in `lib/l10n/`
- [ ] Create console wrapper functions in `engine.dart`

### 1.2 Console Output Interception
- [ ] Wrap `addstr()` and `mvaddstr()` in `engine.dart`
- [ ] Add translation lookup before console output
- [ ] Implement fallback to English for missing translations
- [ ] Test with pseudo-translation (e.g., prefix "[!!]")

### 1.3 Build Integration
- [ ] Configure `intl_translation` for message extraction
- [ ] Set up build_runner integration
- [ ] Create initial ARB files from existing strings
- [ ] Add basic test coverage for translation functions

### 1.4 Language Switching
- [ ] Implement locale detection/selection
- [ ] Add runtime language switching (if feasible)
- [ ] Create language selection UI (basic)
- [ ] Test dynamic switching vs. restart requirement

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

### Console Wrapper Pattern
```dart
// In engine.dart
void addstr(String s) {
  final translated = LcsI18n.translate(s);
  console.addstr(translated);
}

void mvaddstr(int y, int x, String s) {
  final translated = LcsI18n.translate(s);
  console.mvaddstr(y, x, translated);
}
```

### Message Refactoring Examples
```dart
// Before
addstr("${a.name} readies another ${a.weapon.getName()}.");

// After  
LcsI18n.message('combat.ready_weapon', {
  'attacker': a.name,
  'weapon': a.weapon.getName()
});
```

### ICU Plural Handling
```dart
// Before
if (count == 1) {
  addstr("You have 1 item.");
} else {
  addstr("You have $count items.");
}

// After
final message = LcsI18n.plural('inventory.item_count', count, {
  'count': count
});
```

## Success Metrics

### Coverage Goals
- [ ] Phase 1: 100% console output intercepted
- [ ] Phase 2: 50% of high-frequency modules refactored
- [ ] Phase 3: 80% of modules refactored
- [ ] Phase 4: 100% module coverage
- [ ] Phase 5: Production-ready with comprehensive testing

### Quality Goals
- [ ] Zero untranslated strings in core gameplay
- [ ] <5% performance overhead for translation
- [ ] 100% test coverage for i18n infrastructure
- [ ] Complete documentation for translators

## Risk Mitigation

### Technical Risks
- **Performance**: Implement caching and lazy loading
- **Complexity**: Use phased approach, start simple
- **Maintenance**: Automated analyzers and coverage checks

### Content Risks  
- **Grammar Complexity**: Preserve game logic where needed
- **Context Loss**: Add metadata and translator notes
- **Scope Creep**: Strict adherence to phased plan

## Next Steps

1. **Immediate**: Begin Phase 1 implementation
2. **Review**: Validate plan with stakeholders
3. **Tools**: Set up development environment
4. **Testing**: Create initial test framework

---

*This plan is designed to be iterative and adaptable. Each phase builds upon the previous one while maintaining the ability to adjust based on lessons learned and stakeholder feedback.*
