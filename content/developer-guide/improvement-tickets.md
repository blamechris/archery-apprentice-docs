---
tags: [tickets, improvement, refactoring, architecture, performance, testing]
created: 2025-01-22
related:
  - "[[Architecture]]"
  - "[[RoundViewModel-Audit]]"
  - "[[RoundViewModel-Refactoring-Plan]]"
  - "[[Refactoring-Roadmap]]"
  - "[[Tech-Debt]]"
note: "This is a condensed version. Full source: docs/development/IMPROVEMENT_TICKETS.md (1058 lines)"
---

# Archery Apprentice - Actionable Improvement Tickets

## Overview

This document contains specific, actionable tickets for implementing the improvements identified in the comprehensive architectural audit. Each ticket includes problem description, impact assessment, proposed solution, effort estimation, dependencies, and success criteria.

## Ticket Categories

- **🚨 CRITICAL** - Blocking issues requiring immediate attention
- **⚠️ HIGH** - Important improvements with significant impact
- **📋 MEDIUM** - Valuable enhancements that improve code quality
- **💡 LOW** - Nice-to-have optimizations and polish

---

## 🚨 CRITICAL TICKETS (4 tickets)

### CRIT-001: Break Down RoundViewModel God Class
**Priority:** CRITICAL | **Effort:** XL (5-7 days) | **Labels:** architecture, refactoring, god-class

**Problem:** RoundViewModel.kt is a god class with 2,058 lines and 55 public methods

**Solution:** Split into 4 specialized ViewModels:
- RoundStateViewModel (~300 lines)
- RoundScoringViewModel (~500 lines)
- RoundAnalyticsViewModel (~400 lines)
- RoundSessionViewModel (~300 lines)

**Success Criteria:**
- [ ] Each ViewModel <500 lines
- [ ] Single responsibility per ViewModel
- [ ] All existing functionality preserved
- [ ] Test coverage maintained >95%

---

### CRIT-002: Fix UI Framework Dependencies in ViewModels
**Priority:** CRITICAL | **Effort:** S (1-2 days) | **Labels:** architecture, layer-violation

**Problem:** ViewModels import UI framework classes (`androidx.compose.ui.geometry.Offset`)

**Solution:** Create domain models and transformation services
- Create `ArrowCoordinate` data class
- Create `CoordinateTransformationService`
- Update ViewModels to use domain models

**Success Criteria:**
- [ ] No UI framework imports in ViewModels
- [ ] Domain models used for business logic
- [ ] UI transformation at presentation boundary only

---

### CRIT-003: Add Critical Database Indexes
**Priority:** CRITICAL | **Effort:** S (1 day) | **Labels:** performance, database

**Problem:** Missing database indexes causing 100-500ms query delays

**Solution:** Add performance-critical indexes via new migration:
```sql
CREATE INDEX idx_arrow_scores_equipment_time ON arrow_scores(bowSetupId, scoredAt);
CREATE INDEX idx_end_scores_round_participant ON end_scores(roundId, participantId);
CREATE INDEX idx_rounds_status_date ON rounds(status, createdAt DESC);
CREATE INDEX idx_arrow_scores_end_arrow ON arrow_scores(endScoreId, arrowNumber);
```

**Success Criteria:**
- [ ] Equipment performance queries <50ms
- [ ] Multi-participant operations <100ms
- [ ] Round loading improved by 60-80%

---

### CRIT-004: Fix N+1 Query Problems in RoundRepository
**Priority:** CRITICAL | **Effort:** M (2-3 days) | **Labels:** performance, database

**Problem:** RoundRepository.getRoundWithDetails() performs N+1 queries (30-end round = 31+ queries)

**Solution:** Replace with single optimized query using JOINs

**Success Criteria:**
- [ ] Single query per round load operation
- [ ] Round loading <100ms for 30-end rounds
- [ ] Memory usage reduced for large datasets

---

## ⚠️ HIGH PRIORITY TICKETS (4 tickets)

### HIGH-001: Extract ActiveScoringScreen Components
**Priority:** HIGH | **Effort:** M (3-4 days) | **Labels:** ui, refactoring

**Problem:** ActiveScoringScreen.kt is 1,896 lines of monolithic UI code

**Solution:** Extract major UI sections:
- ScoreInputSection
- ParticipantManagementPanel
- RealTimeStatisticsPanel
- EndCompletionSection

---

### HIGH-002: Fix Compose Recomposition Issues
**Priority:** HIGH | **Effort:** M (2-3 days) | **Labels:** performance, compose

**Problem:** Multiple StateFlow derivations causing excessive recompositions

**Solution:** Combine StateFlow derivations into single state objects, add stable keys to LazyColumn

---

### HIGH-003: Add Equipment ViewModel Tests
**Priority:** HIGH | **Effort:** M (3-4 days) | **Labels:** testing

**Problem:** 11 equipment ViewModels lack test coverage

**Solution:** Create comprehensive test coverage for all equipment ViewModels

---

### HIGH-004: Implement LRU Caching for Memory Management
**Priority:** HIGH | **Effort:** S (1-2 days) | **Labels:** performance, memory

**Problem:** ViewModels use unbounded caches causing memory growth to 50-100MB+

**Solution:** Replace with LRU caches with proper invalidation

---

## 📋 MEDIUM PRIORITY TICKETS (3 tickets)

### MED-001: Extract Magic Numbers to Constants
**Priority:** MEDIUM | **Effort:** S (1-2 days)

**Problem:** 50+ hardcoded magic numbers throughout codebase

**Solution:** Create comprehensive constants files (ScoringConstants, UIConstants, DatabaseConstants)

---

### MED-002: Add Repository Tests for Critical Data Operations
**Priority:** MEDIUM | **Effort:** M (2-3 days)

**Problem:** 11 repositories lack test coverage

**Solution:** Create comprehensive repository tests focusing on critical operations

---

### MED-003: Implement Data Pagination for Historical Views
**Priority:** MEDIUM | **Effort:** M (3-4 days)

**Problem:** Historical screens load all data at once (slow for users with 100+ rounds)

**Solution:** Implement Paging 3 with progressive loading

---

## 💡 LOW PRIORITY TICKETS (4 tickets)

### LOW-001: Add Architectural Testing
**Priority:** LOW | **Effort:** S (1-2 days)

**Problem:** No automated validation of architectural rules

**Solution:** Implement ArchUnit tests for architectural validation

---

### LOW-002: Implement Use Case Pattern for Complex Business Logic
**Priority:** LOW | **Effort:** M (3-4 days)

**Problem:** Complex business logic scattered across ViewModels and repositories

**Solution:** Implement use case pattern (ScoreArrowUseCase, CompleteEndUseCase, etc.)

---

### LOW-003: Migrate to Compose Navigation
**Priority:** LOW | **Effort:** M (3-4 days)

**Problem:** Current navigation lacks type safety

**Solution:** Migrate to Compose Navigation with type-safe arguments

---

## Implementation Priority Matrix

### Week 1-2: Foundation (CRITICAL)
1. **CRIT-001**: Break Down RoundViewModel God Class
2. **CRIT-002**: Fix UI Framework Dependencies
3. **CRIT-003**: Add Critical Database Indexes
4. **CRIT-004**: Fix N+1 Query Problems

### Week 3-4: Performance & UI (HIGH)
1. **HIGH-001**: Extract ActiveScoringScreen Components
2. **HIGH-002**: Fix Compose Recomposition Issues
3. **HIGH-003**: Add Equipment ViewModel Tests
4. **HIGH-004**: Implement LRU Caching

### Week 5-6: Quality & Stability (MEDIUM)
1. **MED-001**: Extract Magic Numbers to Constants
2. **MED-002**: Add Repository Tests
3. **MED-003**: Implement Data Pagination

### Week 7-8: Polish & Future-Proofing (LOW)
1. **LOW-001**: Add Architectural Testing
2. **LOW-002**: Implement Use Case Pattern
3. **LOW-003**: Migrate to Compose Navigation

---

## Success Metrics Dashboard

### Code Quality Metrics
- [ ] **Files >500 lines:** Reduce from 15 to <5
- [ ] **God classes:** Reduce from 24 to <10
- [ ] **Layer violations:** 0 critical violations
- [ ] **Test coverage:** Maintain >75%

### Performance Metrics
- [ ] **Database queries:** <50ms for UI operations
- [ ] **UI responsiveness:** <100ms for all interactions
- [ ] **Memory usage:** <20MB per ViewModel
- [ ] **App startup:** <2 seconds cold start

### Architecture Metrics
- [ ] **MVVM compliance:** 100% ViewModels follow pattern
- [ ] **Dependency direction:** All dependencies flow correctly
- [ ] **Single responsibility:** Each class has clear purpose
- [ ] **Testability:** All business logic unit testable

---

**Source**: `docs/development/IMPROVEMENT_TICKETS.md` (1058 lines total)  
**Total Tickets**: 15 (4 Critical, 4 High, 3 Medium, 4 Low)  
**See Also**: [[RoundViewModel-Audit]], [[Refactoring-Roadmap]]

*This is a condensed overview. See source file for full implementation details, code examples, and dependencies for each ticket.*