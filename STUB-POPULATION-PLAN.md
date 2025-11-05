# Stub Population Plan - November 4, 2025

**Based on:** Codebase exploration of archery-apprentice main repository
**Total Stubs:** 42 stub pages identified
**Approach:** Research-driven content creation from actual codebase

---

## Stub Categorization & Content Mapping

### Category 1: Database Layer Stubs (13 stubs)

**Technical-Reference/Database/** stubs map to `shared/database`:

| Stub Page | Maps To | Content Source |
|-----------|---------|----------------|
| `Database/index.md` | Database schema overview | `ArcheryKmpDatabase.kt`, migration history |
| `Database/Tables/index.md` | All 26 entities | Entity files in `database/entities/` |
| `Database/Migrations/index.md` | Migration history | Database version 17→35, migration classes |

**Technical-Reference/Data-Models/** stubs map to domain models:

| Stub Page | Maps To | Content Source |
|-----------|---------|----------------|
| `Data-Models/Equipment/index.md` | Equipment entities | 13 equipment entities (Riser, Limbs, Sight, etc.) |
| `Data-Models/Scoring/index.md` | Scoring models | Round, EndScore, ArrowScore entities |
| `Data-Models/Tournament/index.md` | Tournament models | Tournament, Participant, Cache entities |
| `Data-Models/Analytics/index.md` | Analytics models | Stats models, grouping metrics, fatigue analysis |

### Category 2: API Reference Stubs (5 stubs)

**Technical-Reference/Code-Examples/** stubs map to patterns:

| Stub Page | Maps To | Content Source |
|-----------|---------|----------------|
| `Code-Examples/Common-Patterns/index.md` | Design patterns | Factory, Repository, Sealed classes, Flow patterns |
| `Code-Examples/Feature-Examples/index.md` | Feature implementations | Equipment CRUD, Scoring flows, Tournament join |
| `Code-Examples/Testing-Examples/index.md` | Test patterns | DAO tests, Repository tests, Integration tests |

### Category 3: User Guide Stubs (7 stubs)

**user-guide/** stubs map to app features:

| Stub Page | Maps To | Content Source |
|-----------|---------|----------------|
| `features/Analytics/index.md` | Analytics features | EquipmentStats, Shot grouping, Fatigue analysis |
| `Quick-Start/index.md` | Getting started | App setup, first round, first equipment |
| `Reference/index.md` | Reference docs | Scoring systems, equipment types, terminology |
| `Troubleshooting/index.md` | Common issues | Known issues, workarounds, support |
| `How-To/Data-Management/index.md` | Data operations | Import/export, backup, sync |
| `How-To/Equipment-Tasks/index.md` | Equipment workflows | Add equipment, create setup, track performance |
| `How-To/Scoring-Scenarios/index.md` | Scoring workflows | Start round, enter scores, review results |

### Category 4: Developer Guide Stubs (17 stubs)

**Development/** tree stubs (LEGACY - should redirect to modern structure):

All Development/ stubs redirect to equivalent developer-guide/ pages:
- `Development/index.md` → `developer-guide/index.md` ✅ Already exists
- `Development/Architecture/*` → `developer-guide/architecture/*` ✅ Already exists
- `Development/Guides/*` → `developer-guide/guides/*` ✅ Already exists

**Technical-Reference/** stubs map to codebase:

| Stub Page | Maps To | Content Source |
|-----------|---------|----------------|
| `Technical-Reference/index.md` | Overview | All repos, DAOs, services |
| `Technical-Reference/Flows/index.md` | User flows | Equipment→Scoring→Analytics flow |
| `Technical-Reference/Flows/User-Flows/index.md` | User journeys | Landing→Round→Scoring complete |
| `Technical-Reference/Flows/System-Flows/index.md` | System processes | Sync flow, auth flow, data repair |
| `Technical-Reference/Flows/Integration-Flows/index.md` | Integration points | Firebase, Room, authentication |
| `Technical-Reference/Performance/index.md` | Performance | Query optimization, caching, indexes |

### Category 5: Project Management Stubs (6 stubs)

**Project-Management/** stubs (LEGACY - low priority):

These are placeholder pages for future project documentation:
- `Project-Management/index.md` - Redirects to internal/project-tracking
- `Project-Management/Roadmap/` - Future feature roadmap
- `Project-Management/Release-Notes/` - Version release notes
- `Project-Management/Known-Issues/` - Issue tracking
- `Project-Management/Status/` - Current status
- `Project-Management/Team/` - Team information

**Recommendation:** Keep as redirects, populate in internal/project-tracking instead

### Category 6: Meta & Misc Stubs (4 stubs)

| Stub Page | Purpose | Content Plan |
|-----------|---------|--------------|
| `Meta/index.md` | Doc about docs | Redirect to internal/meta |
| `Architecture-Decisions/index.md` | ADR directory | Create ADR template, list key decisions |
| `Getting-Started/index.md` | Quick start | Redirect to user-guide/quick-start |

---

## Prioritized Population Plan

### Phase 1: High-Value User Documentation (Priority: HIGH)

**Effort:** 4-6 hours
**Impact:** Immediate value for users

**Stubs to populate:**
1. **user-guide/Quick-Start/index.md** (1 hour)
   - App installation and setup
   - Create first equipment
   - Score first round
   - View analytics

2. **user-guide/features/Analytics/index.md** (1 hour)
   - Equipment performance stats
   - Shot grouping analysis
   - Fatigue metrics
   - Consistency analysis
   - Screenshots from main repo

3. **user-guide/How-To/Equipment-Tasks/index.md** (1 hour)
   - Add each equipment type
   - Create bow setup
   - Link equipment to setups
   - Track equipment usage

4. **user-guide/How-To/Scoring-Scenarios/index.md** (1 hour)
   - Start individual round
   - Start multi-participant round
   - Enter scores (manual, target face)
   - Review and complete round

5. **user-guide/Reference/index.md** (30 min)
   - Scoring systems (10-ring, 6-ring, 5-zone)
   - Equipment types glossary
   - Distance/measurement units
   - Round status meanings

6. **user-guide/Troubleshooting/index.md** (30 min)
   - Common issues from GitHub issues
   - Sync troubleshooting
   - Performance tips

### Phase 2: Technical Reference Documentation (Priority: HIGH)

**Effort:** 6-8 hours
**Impact:** Critical for developers

**Stubs to populate:**
1. **Technical-Reference/Database/index.md** (1 hour)
   - Database schema overview
   - 26 entities organized by category
   - Relationships diagram
   - Migration history (v17→v35)
   - KMP migration status

2. **Technical-Reference/Database/Tables/index.md** (2 hours)
   - All 26 entity descriptions
   - Field details
   - Relationships
   - Indexes and constraints

3. **Technical-Reference/Data-Models/Equipment/index.md** (1 hour)
   - 13 equipment entity details
   - BowSetup configuration
   - Equipment relationships

4. **Technical-Reference/Data-Models/Scoring/index.md** (1 hour)
   - Round entity (25 fields)
   - EndScore entity
   - ArrowScore entity (16 fields)
   - Scoring workflow

5. **Technical-Reference/Data-Models/Tournament/index.md** (1 hour)
   - Tournament entity (40+ fields)
   - Participant tracking
   - Offline sync models

6. **Technical-Reference/Data-Models/Analytics/index.md** (1 hour)
   - AggregateStats
   - AdvancedShotGrouping
   - FatigueMetrics
   - ConsistencyMetrics

7. **Technical-Reference/Flows/** (1-2 hours)
   - User flows with diagrams
   - System flows
   - Integration flows

### Phase 3: Code Examples & Patterns (Priority: MEDIUM)

**Effort:** 4-5 hours
**Impact:** Helps developers learn codebase

**Stubs to populate:**
1. **Technical-Reference/Code-Examples/Common-Patterns/index.md** (2 hours)
   - Factory pattern examples
   - Repository pattern
   - Sealed class usage
   - Flow/StateFlow patterns
   - Guest setup auto-generation

2. **Technical-Reference/Code-Examples/Feature-Examples/index.md** (2 hours)
   - Equipment CRUD example
   - Round creation & scoring
   - Tournament join flow
   - Analytics calculation

3. **Technical-Reference/Code-Examples/Testing-Examples/index.md** (1 hour)
   - DAO test example
   - Repository test example
   - Integration test example

### Phase 4: Clean Up Legacy Stubs (Priority: LOW)

**Effort:** 1 hour
**Impact:** Reduce navigation confusion

**Actions:**
1. Update all `Development/` stubs to redirect to `developer-guide/`
2. Update all `Project-Management/` stubs to redirect to `internal/project-tracking/`
3. Update `Meta/` to redirect to `internal/meta/`
4. Update `Getting-Started/` to redirect to `user-guide/quick-start/`

---

## Content Templates

### Database Entity Template

```markdown
# [Entity Name]

**Table:** `[table_name]`
**Module:** shared:database
**Category:** [Equipment/Scoring/Tournament/Stats]

## Overview

[Brief description of entity purpose]

## Schema

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | Long | PK, AI | Primary key |
| ... | ... | ... | ... |

## Relationships

- **Foreign Keys:** [List]
- **Referenced By:** [List]

## Business Rules

- [Rule 1]
- [Rule 2]

## Usage Examples

[Code examples]

## Related

- [Related entities]
- [Related DAOs]
```

### Feature Documentation Template

```markdown
# [Feature Name]

**Status:** ✅ Implemented
**Version:** [Version added]
**Related Components:** [ViewModels, Repositories, DAOs]

## Overview

[What the feature does]

## User Workflows

### [Workflow 1]

1. Step 1
2. Step 2
3. Step 3

[Screenshot]

### [Workflow 2]

...

## Technical Details

### Data Models

[Models used]

### Architecture

[Flow diagram]

## Code Examples

[Examples]

## Related Documentation

- [Links]
```

---

## Success Metrics

**Before:**
- ❌ 42 stub pages with no content
- ❌ Users/developers have no guidance
- ❌ Confusing navigation with empty pages

**After Phase 1:**
- ✅ 6 high-value user docs complete
- ✅ Users can onboard themselves
- ✅ Common workflows documented

**After Phase 2:**
- ✅ 13 technical reference docs complete
- ✅ Database fully documented
- ✅ Developers understand data models

**After Phase 3:**
- ✅ 3 code example docs complete
- ✅ Developers have working examples
- ✅ Common patterns documented

**After Phase 4:**
- ✅ Legacy stubs cleaned up
- ✅ Clear navigation structure
- ✅ No confusing redirects

---

## Estimated Timeline

**Total Effort:** 15-20 hours

- **Phase 1:** 4-6 hours (user docs)
- **Phase 2:** 6-8 hours (technical reference)
- **Phase 3:** 4-5 hours (code examples)
- **Phase 4:** 1 hour (cleanup)

**Recommended Approach:**
- Day 1: Phase 1 (user docs) - immediate user value
- Day 2-3: Phase 2 (technical reference) - developer foundation
- Day 4: Phase 3 (code examples) - learning resources
- Day 4: Phase 4 (cleanup) - polish

---

## Next Steps

**Immediate Actions:**

1. ✅ Get user confirmation on approach
2. Start Phase 1: User documentation (high priority)
3. Populate stubs with researched content from codebase
4. Add screenshots/diagrams where helpful
5. Test all internal links
6. Deploy and verify on live site

**Ready to begin!**

