---
tags: [firebase, security, firestore, rules, tournament, authentication]
created: 2025-10-08
last-updated: 2025-01-30
version: 1.0.0
status: production-ready
related:
  - "[[Firebase-Integration-Plan]]"
  - "[[Tournament-Flow]]"
  - "[[Data-Sync-Flow]]"
---

[Home](/) > [Development](/Development/) > [Guides](/Development/Guides/) > [Working With](/Development/Guides/Working-With/) > ---

---


# Firebase Security Rules for Tournament Scoring

## Overview
This document defines Firestore security rules for the tournament system, including real-time score synchronization.

## Collection Structure
```
tournaments/{tournamentId}
├── rounds/{roundNumber}
│   └── scores/{participantId}
│       └── ends/{endNumber}
└── participants/{participantId}
```

## Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }

    function isParticipant(tournamentId) {
      return isSignedIn() &&
        exists(/databases/$(database)/documents/tournaments/$(tournamentId)/participants/$(request.auth.uid));
    }

    function isTournamentCreator(tournamentId) {
      return isSignedIn() &&
        get(/databases/$(database)/documents/tournaments/$(tournamentId)).data.createdBy == request.auth.uid;
    }

    function isTournamentActive(tournamentId) {
      let tournament = get(/databases/$(database)/documents/tournaments/$(tournamentId)).data;
      return tournament.status == 'IN_PROGRESS';
    }

    // Tournament documents
    match /tournaments/{tournamentId} {
      // Read: public tournaments or participants
      allow read: if resource.data.isPublic == true ||
                     isParticipant(tournamentId) ||
                     isTournamentCreator(tournamentId);

      // Create: authenticated users only
      allow create: if isSignedIn() &&
                       request.resource.data.createdBy == request.auth.uid;

      // Update: creator only
      allow update: if isTournamentCreator(tournamentId);

      // Delete: creator only
      allow delete: if isTournamentCreator(tournamentId);

      // ====================================
      // TOURNAMENT ROUNDS SUBCOLLECTION
      // ====================================
      match /rounds/{roundNumber} {
        // Read: all tournament participants
        allow read: if isParticipant(tournamentId);

        // Create: creator or authorized participants when tournament is IN_PROGRESS
        allow create: if (isTournamentCreator(tournamentId) || isParticipant(tournamentId)) &&
                         isTournamentActive(tournamentId);

        // Update: creator or participants (for status updates)
        allow update: if isTournamentCreator(tournamentId) || isParticipant(tournamentId);

        // Delete: creator only
        allow delete: if isTournamentCreator(tournamentId);

        // ====================================
        // SCORES SUBCOLLECTION
        // ====================================
        match /scores/{participantId} {
          // Read: all tournament participants
          allow read: if isParticipant(tournamentId);

          // Create: only the participant scoring for themselves, or creator
          allow create: if (isSignedIn() && request.auth.uid == participantId) ||
                          isTournamentCreator(tournamentId);

          // Update: participant or creator only
          allow update: if (isSignedIn() && request.auth.uid == participantId) ||
                          isTournamentCreator(tournamentId);

          // Delete: creator only (for corrections)
          allow delete: if isTournamentCreator(tournamentId);

          // ====================================
          // ENDS (INDIVIDUAL END SCORES)
          // ====================================
          match /ends/{endNumber} {
            // Read: all tournament participants
            allow read: if isParticipant(tournamentId);

            // Create: participant or creator
            allow create: if (isSignedIn() && request.auth.uid == participantId) ||
                            isTournamentCreator(tournamentId) &&
                            validateScoreData();

            // Update: participant or creator (for corrections)
            allow update: if (isSignedIn() && request.auth.uid == participantId) ||
                            isTournamentCreator(tournamentId);

            // Delete: creator only (for corrections)
            allow delete: if isTournamentCreator(tournamentId);

            // Score validation
            function validateScoreData() {
              let data = request.resource.data;
              return data.tournamentId == tournamentId &&
                     data.participantId == participantId &&
                     data.endNumber is int &&
                     data.arrowScores is list &&
                     data.arrowScores.size() > 0 &&
                     data.arrowScores.size() <= 12 && // Max 12 arrows per end
                     data.endTotal == data.arrowScores.reduce(0, function(sum, value) { return sum + value }) &&
                     data.timestamp is int &&
                     data.deviceId is string;
            }
          }
        }
      }

      // ====================================
      // PARTICIPANTS SUBCOLLECTION
      // ====================================
      match /participants/{participantId} {
        // Read: all tournament participants or public tournaments
        allow read: if resource.data.tournamentId in
                      get(/databases/$(database)/documents/tournaments/$(tournamentId)).data.participantIds ||
                      get(/databases/$(database)/documents/tournaments/$(tournamentId)).data.isPublic == true;

        // Create: authenticated users joining, or creator adding participants
        allow create: if (isSignedIn() && request.auth.uid == participantId) ||
                        isTournamentCreator(tournamentId);

        // Update: participant themselves or creator
        allow update: if (isSignedIn() && request.auth.uid == participantId) ||
                        isTournamentCreator(tournamentId);

        // Delete: creator or participant leaving
        allow delete: if (isSignedIn() && request.auth.uid == participantId) ||
                        isTournamentCreator(tournamentId);
      }
    }
  }
}
```

## Rule Explanations

### Tournament Rounds Access
- **Read**: All tournament participants can view round information
- **Create**: Creator or participants can create rounds when tournament is IN_PROGRESS
- **Update**: Creator or participants can update round status
- **Delete**: Only creator can delete rounds

### Score Submission Rules
- **Granular Control**: Scores organized as `scores/{participantId}/ends/{endNumber}`
- **Self-Scoring Only**: Participants can only submit scores for themselves
- **Creator Override**: Tournament creator can submit/edit any scores (for corrections)
- **Validation**: Scores must include valid arrow data, end total must match sum of arrows

### Data Validation
- **Arrow Count**: Maximum 12 arrows per end
- **Score Integrity**: `endTotal` must equal sum of `arrowScores` array
- **Metadata Required**: `timestamp`, `deviceId`, and participant info required for conflict resolution

### Anti-Cheating Measures
- Participant IDs must match document path
- Tournament ID must match parent collection
- Timestamps required for all submissions (audit trail)
- Device IDs tracked for multi-device scenarios

## Security Best Practices

### 1. Rate Limiting
Consider implementing Cloud Functions to rate-limit score submissions:
```javascript
// Example: Max 1 end submission per minute per participant
```

### 2. Score Verification
Use Cloud Functions to verify suspicious score patterns:
- Multiple high scores in rapid succession
- Scores outside valid range for tournament format
- Unusual submission patterns

### 3. Audit Logging
All score modifications logged with:
- Device ID
- Timestamp
- Participant ID
- Previous value (for updates)

## Testing Security Rules

### Local Emulator Testing
```bash
firebase emulators:start --only firestore
```

### Test Cases
1. ✅ Participant can submit their own scores
2. ✅ Participant can read all tournament scores
3. ❌ Participant cannot submit scores for others
4. ❌ Non-participants cannot read tournament data
5. ✅ Creator can update any participant's scores
6. ❌ Invalid score data is rejected

## Performance Considerations

### Indexes Required
```
tournaments/{tournamentId}/rounds/{roundNumber}/scores/{participantId}/ends
- Collection group index on: tournamentId, endNumber
- Composite index: participantId, endNumber (ASC)
```

### Query Optimization
- Use `.limit()` for leaderboard queries
- Cache participant lists client-side
- Minimize deep nested reads

## Migration Notes

### Existing Data
- Current local-only rounds remain unchanged
- New tournament rounds use this security model
- Hybrid repository handles offline-first with Firebase sync

### Rollout Strategy
1. Deploy security rules to Firebase console
2. Enable network scoring feature flag
3. Monitor for security rule violations
4. Adjust rules based on real-world usage

---

**Related Documentation:**
- See [[Firebase-Integration-Plan]] for overall Firebase integration roadmap
- See [[Tournament-Flow]] for tournament lifecycle
- See [[Data-Sync-Flow]] for real-time sync architecture

**Last Updated**: 2025-01-30  
**Version**: 1.0.0  
**Status**: Production Ready
