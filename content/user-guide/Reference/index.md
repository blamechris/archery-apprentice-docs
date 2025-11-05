---
title: "Reference Materials"
description: "Quick reference materials, terminology, and definitions"
category: "user-guide"
audience: "users"
status: "active"
tags:
  - reference
  - glossary
  - terminology
---

[Home](/) > [User Guide](../) > Reference

---

# Reference Materials

Quick reference for terminology, scoring systems, equipment types, and app concepts used in Archery Apprentice.

## Scoring Systems

### 10-Ring System
- **Rings:** 10, 9, 8, 7, 6, 5, 4, 3, 2, 1
- **X-Ring:** Inner 10 (for tie-breaking)
- **Miss:** 0 points
- **Use:** Olympic recurve, standard target archery
- **Targets:** 122cm, 80cm outdoor

### 6-Ring System
- **Rings:** 6, 5, 4, 3, 2, 1
- **Use:** NFAA field archery, casual practice
- **Note:** Simplified scoring

### 5-Zone System
- **Zones:** 5, 4, 3, 2, 1
- **Use:** Practice, beginner training
- **Note:** Very simplified

### X-Ring Compound
- **Rings:** Same as 10-ring
- **X-Ring:** Smaller inner 10
- **Use:** Compound bow competitions
- **Note:** X-ring size differs from recurve

---

## Equipment Types

### Bow Components
- **Riser** - Central bow body (brand, model, length, material)
- **Limbs** - Energy-storing arms (brand, model, poundage, limb length)
- **Bow String** - Connects limbs (brand, model, strand count, serving)

### Sighting & Aiming
- **Sight** - Aiming device (brand, model, material)
- **Sight Marks** - Distance-specific settings

### Stabilization
- **Stabilizer** - Vibration reduction, balance (length, weight, straightness)
- **Weights** - Additional balance weights (ounces)

### Arrow Rest System
- **Plunger** - Fine-tune arrow flight (adjustment settings)
- **Rest** - Arrow support (type: magnetic, flipper, blade)

### Arrows
- **Arrow Set** - Complete arrow configuration
- **Spine** - Arrow stiffness (e.g., 500, 600)
- **Length** - Shaft length in inches
- **Weight** - Total arrow weight in grains
- **Point** - Arrow tip (brand, model, weight)
- **Nock** - Rear fitting (brand, model)

### Accessories
- **Generic** - Other equipment (tabs, chest guards, quivers, etc.)

---

## Round Status Meanings

| Status | Description | Meaning |
|--------|-------------|---------|
| **PLANNED** | Created but not started | Round exists, no scores yet |
| **IN_PROGRESS** | Currently scoring | Active scoring session |
| **PAUSED** | Temporarily stopped | Can resume later, progress saved |
| **COMPLETED** | Finished scoring | All ends scored, final stats available |
| **CANCELLED** | Abandoned | Invalid round, excluded from statistics |

---

## Common Terms

### Round Components
- **End** - Group of arrows shot before retrieving (e.g., 6-arrow end)
- **Arrow** - Individual shot within an end
- **Round** - Complete scoring session (multiple ends)

### Scoring
- **X-Ring** - Inner 10, used for tie-breaking
- **10-Ring** - Outermost yellow ring (or inner for compound)
- **Miss** - Arrow off target (0 points)
- **Running Total** - Cumulative score up to current end
- **End Total** - Sum of arrows in one end

### Equipment
- **Bow Setup** - Complete equipment configuration
- **Setup Version** - Snapshot of equipment at a point in time
- **Guest Setup** - Temporary setup auto-generated for participants
- **Soft Delete** - Marked inactive but preserved (bow setups)

### Analytics
- **Accuracy** - Score as percentage of maximum possible
- **Average per Arrow** - Total score / number of arrows
- **X-Count** - Number of X-ring hits
- **Ring Distribution** - How many arrows in each ring
- **Eccentricity** - How "stretched" a shot group is (0-1)
- **Radial SD** - Arrow spread from group center
- **Bias** - Directional tendency of shot group
- **Fatigue Drop** - Performance decline early vs late ends

### Participants
- **Local User** - You (the app owner)
- **Guest Archer** - Temporary participant in multi-participant round
- **Participant Theme** - SINGLE_USER or MULTI_PARTICIPANT mode

---

## Distance & Measurement Units

### Metric
- **18 meters** - Indoor standard
- **30 meters** - Short outdoor
- **50 meters** - Mid outdoor
- **70 meters** - Olympic outdoor
- **90 meters** - Long outdoor

### Imperial
- **20 yards** - Indoor standard
- **30 yards** - Short outdoor
- **50 yards** - Mid outdoor
- **60 yards** - Long outdoor

### Target Sizes
- **40cm** - Small indoor
- **60cm** - Standard indoor
- **80cm** - Small outdoor
- **122cm** - Standard outdoor

---

## Typical Score Ranges

| Level | 10-Ring (60 arrows) | Description |
|-------|---------------------|-------------|
| **Beginner** | 200-300 | Learning form, occasional good shots |
| **Intermediate** | 300-400 | Consistent form, improving accuracy |
| **Advanced** | 400-500 | Solid technique, competitive scores |
| **Expert** | 500-550 | High-level competition scores |
| **Elite** | 550+ | World-class performance |

*Note: Varies by distance, target size, and conditions*

---

## App-Specific Concepts

### Setup Versioning
- Equipment changes auto-create new versions
- Rounds always reference exact version used
- Preserves historical accuracy

### Multi-Participant Mode
- Up to 4 participants (you + 3 guests)
- Guest setups auto-generated
- Separate stats per participant

### Scoring Methods
- **Manual Entry** - Type scores directly
- **Target Face** - Tap arrow positions on target visual
- **Quick Entry** - Streamlined rapid input

### Session Management
- **Start** - Begin new round
- **Pause** - Stop temporarily
- **Resume** - Continue paused round
- **Complete** - Finalize round
- **Cancel** - Abandon invalid round

---

## FAQs

**Q: Can I change equipment mid-round?**
A: No. Complete the current round, then create a new round with the updated setup.

**Q: Why can't I delete a bow setup?**
A: Bow setups use soft delete (marked inactive) to preserve historical data integrity.

**Q: What's the difference between X-ring and 10-ring?**
A: X-ring is the inner 10, used for tie-breaking. All X's are 10s, but not all 10s are X's.

**Q: Can I edit scores after completing a round?**
A: Generally no, to preserve data integrity. Catch mistakes before completing the round.

**Q: How many participants can I add to a round?**
A: Up to 4 total (yourself + 3 guests).

**Q: Why use Target Face scoring?**
A: Captures arrow coordinates for advanced grouping analysis (eccentricity, bias, radial SD).

**Q: What happens to guest setups after multi-participant rounds?**
A: They're preserved for historical accuracy but don't clutter your main equipment list.

---

## Related Documentation

- [Quick Start Guide](../quick-start/) - Getting started basics
- [Analytics Features](../features/analytics/) - Understanding statistics
- [Equipment Tasks](../how-to/equipment-tasks/) - Managing equipment
- [Scoring Scenarios](../how-to/scoring-scenarios/) - Scoring workflows

---

**Have a question not answered here? [Open an issue](https://github.com/blamechris/archery-apprentice/issues) on GitHub.**
