---
title: Archive
tags:
  - internal
  - archive
  - meta
created: 2025-11-01
---

# Internal Archive

This directory contains archived internal documentation that is no longer actively used but preserved for historical reference.

## Archive Policy

Content is archived when it meets one or more of these criteria:

### Archival Criteria

1. **Completed Experiments** - Experimental features that were completed, abandoned, or superseded
2. **Historical Debt Tracking** - Technical debt items that have been resolved or are now tracked elsewhere
3. **Stale Analysis** - Code analysis, graphs, or investigations that are outdated
4. **Superseded Documentation** - Content replaced by newer, more accurate documentation

### What Gets Archived

- **Experiments**: Proof-of-concept code, experimental features, research spikes
- **Tech Debt**: Historical technical debt tracking (now in `project-tracking/technical-debt.md`)
- **Code Analysis**: Stale code graphs, dependency analysis, architecture investigations
- **Historical Summaries**: Phase completion summaries, milestone retrospectives

### What Does NOT Get Archived

- **Active Sessions**: Recent session notes (keep sessions from last 3 months)
- **Current KMP Migration**: Active migration documentation stays in `kmp-migration/`
- **Active Project Tracking**: Current status, TODO lists, checkpoint findings
- **Agent Workflows**: Active agent configurations and workflows
- **Meta Documentation**: Templates, guidelines, and active meta content

## Accessing Archived Content

Archived content is still searchable and accessible via Quartz search. If you need to reference historical decisions or experiments, browse this directory.

## Archive Structure

```
archive/
├── code-graph/           # Historical code analysis and dependency graphs
├── experiments/          # Completed experimental features
├── tech-debt/            # Historical technical debt tracking
└── historical-summaries/ # Phase completion summaries and milestones
```

## Related Documentation

- [[project-tracking/technical-debt|Current Technical Debt]]
- [[project-tracking/current-todo|Current TODO List]]
- [[meta/documentation-standards|Documentation Standards]]
- [[sessions/|Recent Sessions]]
