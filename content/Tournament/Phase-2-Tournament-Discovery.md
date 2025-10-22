---
tags:
  - phase-2
  - tournament
  - discovery
  - creation
  - firestore
  - offline-first
  - planning
  - implementation
created: 2025-10-08
related:
  - "[[Tournament-System-Documentation]]"
  - "[[Tournament-UI-Implementation-Plan]]"
  - "[[Firebase-Integration-Plan]]"
---

# Phase 2: Tournament Discovery & Creation - Implementation Plan

## Overview
Implement tournament discovery, creation, and basic management features using Firestore with offline-first architecture.

## Goals
- ✅ Users can discover public tournaments
- ✅ Users can create and configure tournaments
- ✅ Users can join/leave tournaments
- ✅ Preserve offline functionality for local tournaments
- ✅ Foundation for Phase 3 real-time features

---

## Week 1: Firestore Data Models & Repository Layer

### **✅ COMPLETED: Day 1-2: Tournament Data Models**
```kotlin
// Primary models: ✅ ALL IMPLEMENTED
- Tournament.kt (main tournament document) ✅ With security & privacy features
- TournamentParticipant.kt (participant in tournament) ✅ With progress tracking
- TournamentSettings.kt (tournament configuration) ✅ Comprehensive configuration
- TournamentStatus enum (OPEN, IN_PROGRESS, COMPLETED, CANCELLED) ✅
- SecurityModels.kt ✅ GDPR compliance, anti-cheating, privacy controls
- Enhanced Round.kt ✅ Tournament integration fields added
```

### **✅ COMPLETED: Day 3-4: Firestore Repository Implementation**
```kotlin
// Repository layer: ✅ ALL IMPLEMENTED
- TournamentRepository.kt (interface) ✅ 93 comprehensive methods
- FirebaseTournamentRepository.kt (Firestore implementation) ✅ With security validation
- OfflineTournamentRepository.kt (Room-based local tournaments) ✅ In-memory with sync preparation
- HybridTournamentRepository.kt (combines both) ✅ Offline-first strategy
```

### **✅ COMPLETED: Day 5: Integration Testing**
- ✅ Firestore security rules setup (comprehensive anti-cheating measures)
- ✅ Repository integration complete (offline-first with automatic sync)
- ✅ Integration with existing Round model (tournamentId, syncStatus fields added)

---

## Week 2: Tournament Discovery & Management UI

### **Day 1-2: Tournament Discovery Screen**
```kotlin
// UI Components:
- TournamentDiscoveryScreen.kt (main screen)
- TournamentCard.kt (individual tournament display)
- TournamentFilterSheet.kt (filter by status, type, etc.)
```

### **Day 3-4: Tournament Creation Flow**
```kotlin
// Creation workflow:
- CreateTournamentScreen.kt (tournament setup)
- TournamentConfigScreen.kt (rules, participants, etc.)
- TournamentPreviewScreen.kt (review before creation)
```

### **Day 5: Tournament Management**
```kotlin
// Management features:
- MyTournamentsScreen.kt (tournaments user created/joined)
- TournamentDetailsScreen.kt (view tournament info)
- JoinTournamentDialog.kt (join with code/invitation)
```

---

## Week 3: Integration & Polish

### **Day 1-2: Navigation Integration**
- Add tournament routes to MainActivity
- Update landing page with tournament discovery
- Connect with existing round scoring system

### **Day 3-4: Offline Tournament Support**
- Local tournament creation for offline use
- Sync pending changes when online
- Conflict resolution for tournaments

### **Day 5: Testing & Documentation**
- End-to-end testing
- Update feature flags for gradual rollout
- Documentation updates

---

## Technical Implementation Details

### **Firestore Collection Structure**
```
tournaments/{tournamentId}
├── Basic tournament info (name, description, creator, status)
├── participants/{participantId} → TournamentParticipant
├── rounds/{roundId} → Tournament-specific round data
└── settings → TournamentSettings (rules, format, etc.)
```

### **Integration with Existing Round System**
```kotlin
// Enhanced Round model:
data class Round(
    // ... existing fields
    val tournamentId: String? = null,  // Link to tournament
    val tournamentRoundNumber: Int? = null,  // Round number in tournament
    val isLocal: Boolean = true  // Local vs tournament round
)
```

### **Offline-First Strategy**
1. **Create local tournament** → works offline
2. **Sync to Firestore** → when online
3. **Hybrid repository** → seamless online/offline
4. **Conflict resolution** → last-write-wins with versioning

---

## Feature Flags for Gradual Rollout

### **Phase 2A: Tournament Creation (Week 1)**
```kotlin
const val ENABLE_TOURNAMENT_CREATION = false
const val ENABLE_TOURNAMENT_DISCOVERY = false
```

### **Phase 2B: Discovery & Joining (Week 2)**
```kotlin
const val ENABLE_TOURNAMENT_DISCOVERY = true
const val ENABLE_TOURNAMENT_JOINING = false
```

### **Phase 2C: Full Tournament Management (Week 3)**
```kotlin
const val ENABLE_TOURNAMENT_JOINING = true
const val ENABLE_TOURNAMENT_MANAGEMENT = true
```

---

## Success Criteria

### **Week 1 Completion:**
- [x] Tournament data models defined and tested ✅ **COMPLETED**
- [x] Repository layer implemented with offline support ✅ **COMPLETED**
- [x] Basic Firestore operations working ✅ **COMPLETED**
- [x] Security rules configured ✅ **COMPLETED**

**✅ WEEK 1 STATUS: COMPLETED SUCCESSFULLY**

**What Was Accomplished:**
- **Tournament.kt**: Comprehensive tournament entity with security and privacy features
- **TournamentParticipant.kt**: Participant management with progress tracking
- **SecurityModels.kt**: GDPR compliance, anti-cheating, and privacy controls
- **TournamentRepository.kt**: Interface with 93 methods for complete tournament operations
- **FirebaseTournamentRepository.kt**: Full Firestore implementation with security validation
- **OfflineTournamentRepository.kt**: Local tournament support for offline functionality
- **HybridTournamentRepository.kt**: Offline-first strategy with automatic sync
- **Enhanced Round.kt**: Integration with tournament system via tournamentId and sync status

### **Week 2 Completion:**
- [ ] Tournament discovery UI functional
- [ ] Tournament creation workflow complete
- [ ] Users can browse and join tournaments
- [ ] Feature flags controlling access

### **Week 3 Completion:**
- [ ] Full tournament management available
- [ ] Offline tournament creation working
- [ ] Integration with existing round system
- [ ] Documentation and testing complete

---

## Risk Mitigation

### **Technical Risks:**
- **Firestore quota limits** → Implement efficient queries and caching
- **Complex state management** → Use existing StateFlow patterns
- **Offline sync conflicts** → Simple last-write-wins initially

### **UX Risks:**
- **Too many tournament options** → Start with basic tournament types
- **Complex creation flow** → Use existing round creation patterns
- **Confusing offline vs online** → Clear visual indicators

---

## Dependencies & Prerequisites

### **Required Before Starting:**
- ✅ Phase 1 authentication working
- ✅ Real Firebase project with Firestore enabled
- ✅ Security rules configured
- ✅ Existing Round/SessionParticipant models understood

### **External Setup Needed:**
1. **Firestore Database**: Enable in Firebase console
2. **Security Rules**: Configure for tournament access
3. **Indexes**: Create composite indexes for tournament queries
4. **Testing**: Set up Firestore emulator for development

---

## Next Phase Preview (Phase 3)

Phase 2 creates the foundation for Phase 3 real-time features:
- **Tournament lifecycle** → Live tournament progression
- **Participant management** → Real-time join/leave
- **Tournament settings** → Live configuration updates
- **Round integration** → Tournament-specific scoring

The offline-first architecture ensures Phase 3 real-time features enhance rather than replace offline functionality.