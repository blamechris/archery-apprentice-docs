---
tags: [development, contributing, testing, coverage, code-quality]
created: 2025-01-22
related:
  - "[[Coverage-Guide]]"
  - "[[Architecture]]"
  - "[[RoundViewModel-Refactoring-Plan]]"
---

# Contributing to Archery Apprentice

## Development Workflow

### Testing and Coverage

Before making any changes and after completing each development step:

```bash
./gradlew reportCoverage
```

This command will:
1. Clean the build directory
2. Run all unit tests
3. Generate standard and meaningful coverage reports
4. Apply dark theme to HTML reports

Coverage reports are generated in:
- `app/build/reports/jacoco/jacocoTestReport/html/index.html` (standard)
- `app/build/reports/jacoco/meaningfulCoverage/html/index.html` (filtered)

### RoundViewModel Refactoring

When working on RoundViewModel refactoring tasks:

1. **Before each step**: Run `./gradlew reportCoverage` to establish baseline
2. **Make changes**: Follow the refactor plan in `techdebt/README_RoundVM_Refactor.md`
3. **After each step**: Run `./gradlew reportCoverage` to verify coverage maintained
4. **Validate**: Ensure all tests pass and no regression in functionality

The refactoring uses feature flags in `RefactorFlags.kt` to gate UI migrations safely.

## Code Quality Standards

- Maintain or improve test coverage with each change
- Follow existing code conventions and patterns
- All tests must pass before submitting changes
- No runtime behavior changes during refactoring phases

---

**Source**: `docs/development/CONTRIBUTING.md`  
**See Also**: [[Coverage-Guide]] for detailed coverage interpretation