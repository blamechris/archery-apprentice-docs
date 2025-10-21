---
tags:
  - reference
  - abbreviations
  - development-guide
  - llm-context
created: 2025-10-08
related:
  - "[[Contributing]]"
  - "[[Architecture]]"
  - "[[Scoring-ViewModel-Architecture]]"
  - "[[Tournament-System-Documentation]]"
---

# Abbreviations (for LLM context)

**Purpose:** Shared shorthand used across prompts, code, and reviews. Treat these as canonical.

## Participants / Modes
- **MU** – Main User (primary scoring user; owner of the round).
- **GU** – Guest User (non‑owner participant; currently limited to one when MP is enabled).
- **AP** – Active Participant (whose turn/view is currently selected for input & stats).
- **SP** – Single‑participant Scoring mode.
- **MP** – Multi‑participant Scoring mode.

## UI Cards / Screens
- **Header** – Fixed top card showing round/series summary and actions.
- **UT** – UserTabs (visible in MP; switch AP).
- **CES** – Current End Summary (shows current arrow to be scored; also used in VS).
- **MS** – Manual Scoring (tap a score value; no coordinates; includes VS button).
- **VS** – Visual Scoring (target face input; captures coordinates → score).
- **LS** – Live Statistics (performance metrics for AP).
- **LC** – Live Competition (leader/runner‑up vs AP; tap → Roster List).
- **PE** – Previous Ends Summary (per‑end totals and arrow scores; future: tap → target preview).
- **RL** – Roster List (all participants; tap a card to set AP).

## Data / Domain
- **End** – Fixed number of arrows (e.g., 3) per participant segment within a round.
- **Round** – Collection of Ends with shared settings (distance, target, etc.).
- **Finalize End** – Mark an AP's current end immutable; prevents further arrow inserts.
- **Finalize Round** – Mark the round complete *only when all participants finish all ends*.

## Dev / Testing
- **CI** – Continuous Integration.
- **UI Tests** – Instrumented tests in `androidTest`.
- **Unit Tests** – Local JVM tests in `test`.
- **Repo** – Data layer repository.
- **VM** – ViewModel.

> Include this file in prompts so LLMs can use the short forms without re‑explaining.

---

**Source**: `docs/abbreviations.md` (38 lines)

**Usage**: These abbreviations are used consistently across documentation, code comments, test names, and development discussions to maintain clarity and reduce verbosity.

**Related Documentation**:
- [[Contributing]] - Development workflow and coding standards
- [[Architecture]] - Architecture documentation references these terms
- [[Scoring-ViewModel-Architecture]] - Uses MU, GU, AP, SP, MP terminology
- [[Tournament-System-Documentation]] - Tournament features use these abbreviations
