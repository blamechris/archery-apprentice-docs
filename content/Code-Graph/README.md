---
tags:
  - code-graph
  - codebase-map
  - navigation
  - architecture
created: 2025-10-08
---

# Code Graph - Codebase Navigation Map

Welcome to the Archery Apprentice codebase navigation system! This directory provides a structured, navigable map of the entire codebase to help you understand how components connect and interact.

## Purpose

The Code Graph serves as:
- **Interactive Documentation**: Navigate the codebase through [[WikiLinks]]
- **Architecture Reference**: Understand the layered architecture at a glance
- **Onboarding Tool**: Help new developers quickly understand the structure
- **Pattern Library**: Document common patterns used throughout the codebase

## Structure

### 📋 [[Architecture-Overview]]
High-level architecture diagram with links to detailed sections:
- UI Layer (Composables)
- ViewModel Layer (State Management)  
- Repository Layer (Business Logic)
- Database Layer (Room DAOs)
- Service Layer (Extracted Services)

### 🏗️ Layer-Specific Documentation

#### ViewModels
- [[Equipment-ViewModels]] - Equipment component ViewModels
- [[Scoring-ViewModels]] - Round scoring ViewModels (8 total)
- [[Tournament-ViewModels]] - Tournament management ViewModels

#### Repositories  
- [[Equipment-Repositories]] - Equipment data repositories
- [[Scoring-Repositories]] - Round and scoring repositories
- [[Tournament-Repositories]] - Tournament repositories (3 implementations)

#### Services
- [[Tournament-Services]] - Extracted tournament services
- [[Scoring-Services]] - Extracted scoring services

### 🎯 [[Key-Patterns]]
Common patterns and practices:
- SaveResult Pattern
- Repository Pattern
- StateFlow Usage Pattern
- Copy-Delegate-Validate Pattern

## How to Use

1. **Start with [[Architecture-Overview]]** to understand the overall structure
2. **Follow [[WikiLinks]]** to navigate to specific components
3. **Reference [[Key-Patterns]]** to understand implementation patterns
4. **Use layer-specific docs** to dive deep into particular areas

## Quick Links

### Major Components
- **God Classes** (Being Refactored):
  - `LiveScoringViewModel` (2,304 lines) - See [[LiveScoringVM-Analysis]]
  - `RoundViewModel` (2,079 lines) - See [[RoundViewModel-Audit]]
  
- **Extracted Services**:
  - `TournamentSyncService` (556 lines) - See [[TournamentSyncService-Extraction-Plan]]
  - `ScoreConflictResolutionService` (262 lines)
  - `EndCompletionService` (400 lines)

### Documentation Cross-References
- [[Architecture]] - Overall architecture documentation
- [[Tech-Debt]] - Known technical debt
- [[Implementation-Status-10-07-25]] - Current project status

## Navigation Tips

- **Follow the layers**: Start at UI → ViewModel → Repository → Database
- **Check dependencies**: Each component page lists what it depends on
- **Look for patterns**: Similar components follow similar structures
- **Use backlinks**: Obsidian shows what links to each component

---

**Last Updated**: October 8, 2025
**Codebase Version**: Database v31, 97.5% Complete
**Total ViewModels**: 24 (13 equipment + 8 scoring + 3 tournament)
**Total Repositories**: 18+ specialized repositories
