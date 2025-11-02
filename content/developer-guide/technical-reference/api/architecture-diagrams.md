---
title: API Architecture Diagrams
tags:
  - architecture
  - diagrams
  - api
  - mvvm
  - layers
created: 2025-11-01
---

# API Architecture Diagrams

Visual reference for understanding the Archery Apprentice API architecture.

---

## Layer Architecture

```mermaid
graph TB
    UI[UI Layer - Jetpack Compose]
    VM[ViewModel Layer - MVVM]
    Service[Service Layer - Business Logic]
    Repo[Repository Layer - Data Abstraction]
    DAO[DAO Layer - Database Access]
    DB[(Room Database)]
    Firebase[(Firebase/Cloud)]

    UI --> VM
    VM --> Service
    VM --> Repo
    Service --> Repo
    Repo --> DAO
    Repo --> Firebase
    DAO --> DB

    style UI fill:#e1f5fe
    style VM fill:#fff9c4
    style Service fill:#f0f4c3
    style Repo fill:#dcedc8
    style DAO fill:#c8e6c9
    style DB fill:#b2dfdb
    style Firebase fill:#ffccbc
```

---

## MVVM Pattern

```mermaid
graph LR
    View[View/Composable]
    ViewModel[ViewModel]
    Model[Model/Repository]

    View -->|User Actions| ViewModel
    ViewModel -->|UI State| View
    ViewModel -->|Data Requests| Model
    Model -->|Data/Results| ViewModel

    style View fill:#e1f5fe
    style ViewModel fill:#fff9c4
    style Model fill:#dcedc8
```

---

## Scoring Flow Architecture

```mermaid
sequenceDiagram
    participant UI as LiveScoringScreen
    participant VM as LiveScoringViewModel
    participant ECS as EndCompletionService
    participant Repo as RoundRepository
    participant DAO as EndScoreDao/ArrowScoreDao
    participant DB as Room Database

    UI->>VM: recordArrowScore(10)
    VM->>VM: Update UI State
    VM-->>UI: currentArrowScores updated

    UI->>VM: completeEnd()
    VM->>ECS: completeEnd(roundId, endNumber, arrows)
    ECS->>Repo: createEndScore(endScore)
    Repo->>DAO: insertEndScore(endScore)
    DAO->>DB: INSERT INTO end_scores
    DB-->>DAO: endScoreId
    DAO-->>Repo: Result.success(endScoreId)

    ECS->>Repo: createArrowScores(arrows)
    Repo->>DAO: insertArrowScores(arrows)
    DAO->>DB: BATCH INSERT arrow_scores
    DB-->>DAO: Success
    DAO-->>Repo: Result.success()

    Repo-->>ECS: Result.success()
    ECS-->>VM: Result.success()
    VM->>VM: Advance to next end
    VM-->>UI: UI State updated
```

---

## Repository Pattern with Offline-First

```mermaid
graph TB
    VM[ViewModel]
    HR[HybridRepository]
    OR[OfflineRepository]
    FR[FirebaseRepository]
    Local[(Local DB)]
    Cloud[(Firebase)]
    NM[NetworkMonitor]

    VM --> HR
    HR --> OR
    HR --> FR
    HR --> NM
    OR --> Local
    FR --> Cloud

    HR -.->|"1. Return local data immediately"| OR
    HR -.->|"2. Sync in background (if connected)"| FR

    style VM fill:#fff9c4
    style HR fill:#dcedc8
    style OR fill:#c8e6c9
    style FR fill:#ffccbc
    style Local fill:#b2dfdb
    style Cloud fill:#ffccbc
    style NM fill:#e1bee7
```

---

## Service Extraction Pattern

```mermaid
graph TB
    subgraph "Before: God ViewModel (2,808 lines)"
        VM1[LiveScoringViewModel<br/>- Arrow Input<br/>- End Completion<br/>- Tournament Sync<br/>- Conflict Resolution<br/>- Participant Management<br/>- Round Lifecycle<br/>- Progress Tracking<br/>- Statistics<br/>- Equipment<br/>- UI State<br/>- Error Handling<br/>- Logging]
    end

    subgraph "After: Thin ViewModel + Services (1,200 lines)"
        VM2[LiveScoringViewModel<br/>- UI State Management<br/>- Coordination]
        S1[EndCompletionService]
        S2[TournamentSyncService]
        S3[ConflictResolutionService]
        S4[RoundLifecycleService]
        S5[ParticipantManagementService]

        VM2 --> S1
        VM2 --> S2
        VM2 --> S3
        VM2 --> S4
        VM2 --> S5
    end

    VM1 -.->|Refactor| VM2

    style VM1 fill:#ffcdd2
    style VM2 fill:#c8e6c9
    style S1 fill:#f0f4c3
    style S2 fill:#f0f4c3
    style S3 fill:#f0f4c3
    style S4 fill:#f0f4c3
    style S5 fill:#f0f4c3
```

---

## Equipment Component Relationships

```mermaid
graph TB
    BowSetup[BowSetup]
    Sight[SightConfiguration]
    Rest[RestConfiguration]
    Stab[StabilizerConfiguration]
    Plunger[PlungerConfiguration]
    String[StringConfiguration]
    Limbs[LimbsConfiguration]
    Riser[RiserConfiguration]
    Tab[TabConfiguration]
    Clicker[ClkrConfiguration]
    ReleaseAid[ReleaseAidConfiguration]

    BowSetup -->|hasOne| Sight
    BowSetup -->|hasOne| Rest
    BowSetup -->|hasOne| Stab
    BowSetup -->|hasOne| Plunger
    BowSetup -->|hasOne| String
    BowSetup -->|hasOne| Limbs
    BowSetup -->|hasOne| Riser
    BowSetup -->|hasOne| Tab
    BowSetup -->|hasOne| Clicker
    BowSetup -->|hasOne| ReleaseAid

    style BowSetup fill:#fff9c4
    style Sight fill:#e1f5fe
    style Rest fill:#e1f5fe
    style Stab fill:#e1f5fe
    style Plunger fill:#e1f5fe
    style String fill:#e1f5fe
    style Limbs fill:#e1f5fe
    style Riser fill:#e1f5fe
    style Tab fill:#e1f5fe
    style Clicker fill:#e1f5fe
    style ReleaseAid fill:#e1f5fe
```

---

## Round Data Relationships

```mermaid
erDiagram
    Round ||--o{ EndScore : "has many"
    EndScore ||--o{ ArrowScore : "has many"
    Round ||--o{ RoundParticipant : "has many"
    Round }o--|| BowSetup : "uses"
    Round }o--|| ArrowSetup : "uses"

    Round {
        long id PK
        string name
        string status
        int endsCount
        int arrowsPerEnd
        int finalScore
        int xCount
    }

    EndScore {
        long id PK
        long roundId FK
        int endNumber
        int totalScore
        int xCount
    }

    ArrowScore {
        long id PK
        long endScoreId FK
        int arrowNumber
        int score
        boolean isX
    }

    RoundParticipant {
        long roundId FK
        long participantId FK
    }

    BowSetup {
        long id PK
        string name
        boolean isActive
    }

    ArrowSetup {
        long id PK
        string name
        boolean isActive
    }
```

---

## State Flow Pattern

```mermaid
graph LR
    Repo[(Repository)]
    DAO[DAO]
    Flow[Flow&lt;T&gt;]
    SF[StateFlow&lt;T&gt;]
    UI[Composable]

    DAO -->|observeAll| Flow
    Repo -->|observeAll| Flow
    Flow -->|stateIn| SF
    SF -->|collectAsState| UI

    style DAO fill:#c8e6c9
    style Repo fill:#dcedc8
    style Flow fill:#fff9c4
    style SF fill:#fff9c4
    style UI fill:#e1f5fe
```

---

## Component Count Overview

```mermaid
pie title API Components (Total: 72)
    "ViewModels" : 21
    "Services" : 19
    "Repositories" : 17
    "DAOs" : 15
```

---

## Documentation Coverage

```mermaid
pie title Documentation Progress
    "Documented" : 21
    "Remaining" : 51
```

**Current Coverage:**
- ViewModels: 6/21 (29%)
- Repositories: 5/17 (29%)
- Services: 6/19 (32%)
- DAOs: 4/15 (27%)

---

## Related Documentation

**Architecture:**
- [[../../../architecture/system-architecture|System Architecture]]
- [[../../../architecture/mvvm-patterns|MVVM Patterns]]
- [[../../../architecture/service-architecture|Service Architecture]]

**API Reference:**
- [[index|API Reference Home]]
- [[viewmodels/index|ViewModels]]
- [[repositories/index|Repositories]]
- [[services/index|Services]]
- [[daos/index|DAOs]]

**Flows:**
- [[../../flows/scoring-flow|Scoring Flow]]
- [[../../flows/data-sync-flow|Data Sync Flow]]
- [[../../flows/equipment-management-end-to-end-flow|Equipment Management Flow]]

---

**Last Updated:** 2025-11-01
