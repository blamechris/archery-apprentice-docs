# Developer Guide

Welcome to the Archery Apprentice Developer Guide! This section contains technical documentation for developers contributing to the project.

**Status:** 🚧 Content migration in progress

---

## Getting Started

New to the codebase? Start here:

- **[[getting-started|Getting Started Guide]]** - Complete setup and onboarding guide ✨ NEW
- **[[architecture/system-architecture|System Architecture]]** - Understand the codebase organization
- **[[contributing/index|Contributing]]** - How to contribute to the project

---

## Architecture

Understand how Archery Apprentice is built:

### Core Architecture
- **[Architecture Overview](architecture/overview.md)** - High-level system design (Coming soon)
- **[MVVM Pattern](architecture/patterns.md#mvvm)** - ViewModel and UI architecture (Coming soon)
- **[Repository Pattern](architecture/patterns.md#repository)** - Data access layer (Coming soon)

### Layers
- **[UI Layer](architecture/layers/ui.md)** - Jetpack Compose UI (Coming soon)
- **[Domain Layer](architecture/layers/domain.md)** - Business logic (Coming soon)
- **[Data Layer](architecture/layers/data.md)** - Room database & repositories (Coming soon)

### Diagrams
- **[System Architecture Diagram](architecture/diagrams/system.md)** (Coming soon)
- **[Data Flow Diagrams](architecture/diagrams/data-flow.md)** (Coming soon)
- **[Component Diagrams](architecture/diagrams/components.md)** (Coming soon)

---

## Development Guides

Step-by-step guides for common development tasks:

### Adding Features
- **[Add a New Feature](guides/adding-features.md)** - End-to-end feature development (Coming soon)
- **[Add a New Screen](guides/new-screen.md)** - Create a new UI screen (Coming soon)
- **[Add a New Repository](guides/new-repository.md)** - Implement data access (Coming soon)

### Best Practices
- **[Code Style Guide](guides/best-practices/code-style.md)** (Coming soon)
- **[Compose Best Practices](guides/best-practices/compose.md)** (Coming soon)
- **[Repository Best Practices](guides/best-practices/repository.md)** (Coming soon)
- **[Testing Best Practices](guides/best-practices/testing.md)** (Coming soon)

### Working With
- **[Room Database](guides/working-with/room.md)** - Database development (Coming soon)
- **[Firebase](guides/working-with/firebase.md)** - Firebase integration (Coming soon)
- **[Compose UI](guides/working-with/compose.md)** - UI development (Coming soon)
- **[ViewModels](guides/working-with/viewmodels.md)** - State management (Coming soon)

---

## API Reference

Technical reference for key components: ✨ NEW SECTION

**[[technical-reference/api/index|📚 Complete API Reference →]]**

Quick links:
- **[[technical-reference/api/viewmodels/index|ViewModels]]** - UI state management (21 ViewModels)
- **[[technical-reference/api/repositories/index|Repositories]]** - Data access layer (17 Repositories)
- **[[technical-reference/api/services/index|Services]]** - Business logic services (19 Services)
- **[[technical-reference/api/daos/index|DAOs]]** - Database access objects (15 DAOs)

**Top documented components:**
- [[technical-reference/api/viewmodels/live-scoring-view-model|LiveScoringViewModel]]
- [[technical-reference/api/viewmodels/round-view-model|RoundViewModel]]
- [[technical-reference/api/services/end-completion-service|EndCompletionService]]
- [[technical-reference/api/services/tournament-sync-service|TournamentSyncService]]

---

## Testing

Comprehensive testing documentation:

- **[Testing Strategy](testing/strategy.md)** - Overall testing approach (Coming soon)
- **[Unit Testing](testing/unit-tests.md)** - Writing unit tests (Coming soon)
- **[Integration Testing](testing/integration-tests.md)** - Integration test guide (Coming soon)
- **[UI Testing](testing/ui-tests.md)** - Compose UI testing (Coming soon)
- **[Test Infrastructure](testing/infrastructure.md)** - Test utilities and helpers (Coming soon)

---

## CI/CD

Continuous integration and deployment:

- **[GitHub Actions Workflows](ci-cd/workflows.md)** (Coming soon)
- **[Build Configuration](ci-cd/build-config.md)** (Coming soon)
- **[Deployment Process](ci-cd/deployment.md)** (Coming soon)
- **[Self-Hosted Runners](ci-cd/runners.md)** (Coming soon)

---

## Advanced Topics

Deep dives into specific areas:

- **[KMP Migration](../internal/kmp-migration/)** - Kotlin Multiplatform migration project
- **[Performance Optimization](advanced/performance.md)** (Coming soon)
- **[Architecture Decisions](../../Architecture-Decisions/)** - ADR documentation
- **[Tech Debt](advanced/tech-debt.md)** (Coming soon)

---

## Tools & Resources

Development tools and utilities:

- **[IDE Setup](tools/ide-setup.md)** - Android Studio configuration (Coming soon)
- **[Debugging Tools](tools/debugging.md)** (Coming soon)
- **[Code Generation](tools/code-gen.md)** (Coming soon)

---

## Need User Documentation?

If you're looking for user-facing documentation:

→ **[User Guide](../user-guide/)** - App usage and features

---

## Contributing

Ready to contribute?

1. Read **[CONTRIBUTING.md](../../CONTRIBUTING.md)** (Coming soon)
2. Check the **[Good First Issues](https://github.com/blamechris/archery-apprentice/labels/good-first-issue)**
3. Join the **[Discussion](https://github.com/blamechris/archery-apprentice/discussions)**

---

**Last Updated:** 2025-10-31
**Phase:** Structure created, content migration pending
