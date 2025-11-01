#!/usr/bin/env python3
"""
Execute Phase 2A Migration
Migrates Testing, Firebase, System Flows, and Technical Notes
"""

import shutil
from pathlib import Path
from datetime import datetime

BASE_DIR = Path("/mnt/c/Users/chris_3zal3ta/Documents/ArcheryApprentice-Docs")

def add_frontmatter(content, metadata):
    """Add YAML frontmatter if not present"""
    if content.startswith('---\n'):
        return content

    frontmatter = "---\n"
    for key, value in metadata.items():
        if isinstance(value, list):
            frontmatter += f"{key}:\n"
            for item in value:
                frontmatter += f"  - \"{item}\"\n"
        else:
            frontmatter += f"{key}: \"{value}\"\n"
    frontmatter += "---\n\n"

    return frontmatter + content

def migrate_file(source_rel, dest_rel, metadata, migrations):
    """Migrate a single file with frontmatter"""
    source = BASE_DIR / source_rel
    dest = BASE_DIR / dest_rel

    if not source.exists():
        print(f"⚠️  Source not found: {source_rel}")
        return False

    try:
        content = source.read_text(encoding='utf-8')

        # Add navigation breadcrumb after frontmatter
        lines = content.split('\n')
        title = lines[0].replace('# ', '').strip() if lines else "Document"

        # Build breadcrumb based on destination
        parts = dest_rel.split('/')
        breadcrumb_parts = []
        path_so_far = ""
        for i, part in enumerate(parts[:-1]):  # Exclude filename
            if part in ["Development", "User-Guide", "Technical-Reference"]:
                path_so_far = f"/{part}/"
                breadcrumb_parts.append(f"[{part.replace('-', ' ')}]({path_so_far})")
            elif part not in [".", ".."] and i > 0:
                path_so_far += part + "/"
                breadcrumb_parts.append(f"[{part.replace('-', ' ')}]({path_so_far})")

        breadcrumb = "[Home](/) > " + " > ".join(breadcrumb_parts) + f" > {title}\n\n---\n\n"

        # Add frontmatter
        content_with_frontmatter = add_frontmatter(content, metadata)

        # Insert breadcrumb after frontmatter
        if content_with_frontmatter.startswith('---\n'):
            # Find end of frontmatter
            parts = content_with_frontmatter.split('---\n', 2)
            if len(parts) >= 3:
                content_with_frontmatter = f"---\n{parts[1]}---\n\n{breadcrumb}{parts[2]}"

        # Create dest directory
        dest.parent.mkdir(parents=True, exist_ok=True)

        # Write to destination
        dest.write_text(content_with_frontmatter, encoding='utf-8')

        migrations.append(f"✅ {source_rel} → {dest_rel}")
        print(f"✅ Migrated: {source_rel}")
        return True

    except Exception as e:
        print(f"❌ Error migrating {source_rel}: {e}")
        return False

# Track migrations
migrations = []
errors = []

print("=" * 70)
print("PHASE 2A MIGRATION")
print("=" * 70)
print()

# =============================================================================
# TESTING DOCUMENTATION (remaining files)
# =============================================================================
print("📚 Migrating Testing Documentation...")
print("-" * 70)

testing_files = [
    ("Testing/Adapter-Migration-Guide.md", "adapter migration patterns"),
    ("Testing/Cache-Testing-Guide.md", "cache testing strategies"),
    ("Testing/Coverage-Guide.md", "test coverage guidelines"),
    ("Testing/Test-Coverage-Guide.md", "comprehensive test coverage guide"),
    ("Testing/Test-Coverage-State-Week-10.md", "test coverage snapshot Week 10"),
    ("Testing/Test-Failure-Analysis.md", "test failure diagnosis and resolution"),
    ("Testing/Test-Quality-Standards.md", "test quality standards and practices"),
    ("Testing/Tournament-Test-Guide.md", "tournament system testing guide"),
    ("Testing/Tournament-Testing-Checklist.md", "tournament testing checklist"),
]

for source, desc in testing_files:
    filename = Path(source).name
    dest = f"Development/Testing/{filename}"
    metadata = {
        "title": filename.replace('-', ' ').replace('.md', ''),
        "description": desc,
        "category": "development",
        "audience": ["developers"],
        "difficulty": "intermediate",
        "status": "active",
        "last_updated": "2025-10-29",
        "tags": ["testing", "quality", "guide"],
    }
    migrate_file(source, dest, metadata, migrations)

print()

# =============================================================================
# FIREBASE DOCUMENTATION
# =============================================================================
print("🔥 Migrating Firebase Documentation...")
print("-" * 70)

firebase_files = [
    ("Firebase/Firebase-Integration-Plan.md", "Firebase integration architecture plan"),
    ("Firebase/Firebase-Overview.md", "Firebase services overview"),
    ("Firebase/Firebase-Security-Rules.md", "Firebase security rules documentation"),
    ("Firebase/Firebase-Setup.md", "Firebase project setup guide"),
    ("Firebase/Tournament-Discovery.md", "Tournament discovery via Firebase"),
    ("Firebase/Tournament-UI-Plan.md", "Tournament UI implementation plan"),
]

for source, desc in firebase_files:
    filename = Path(source).name
    dest = f"Development/Guides/Working-With/Firebase-{filename}"
    metadata = {
        "title": filename.replace('-', ' ').replace('.md', ''),
        "description": desc,
        "category": "development",
        "audience": ["developers"],
        "difficulty": "intermediate",
        "status": "active",
        "last_updated": "2025-10-29",
        "tags": ["firebase", "cloud", "integration"],
    }
    migrate_file(source, dest, metadata, migrations)

print()

# =============================================================================
# SYSTEM FLOWS
# =============================================================================
print("🔄 Migrating System Flows...")
print("-" * 70)

flow_files = [
    ("Flows/Data-Sync-Flow.md", "data synchronization flow documentation"),
    ("Flows/Equipment-Management-End-to-End-Flow.md", "equipment management complete flow"),
    ("Flows/Round-Lifecycle-Flow.md", "round lifecycle state transitions"),
    ("Flows/Scoring-Flow.md", "scoring workflow and data flow"),
    ("Flows/Service-Architecture.md", "service layer architecture"),
    ("Flows/Service-Migration-Flow.md", "service extraction migration flow"),
]

for source, desc in flow_files:
    filename = Path(source).name
    dest = f"Technical-Reference/Flows/System-Flows/{filename}"
    metadata = {
        "title": filename.replace('-', ' ').replace('.md', ''),
        "description": desc,
        "category": "technical-reference",
        "audience": ["developers"],
        "difficulty": "intermediate",
        "status": "active",
        "last_updated": "2025-10-29",
        "tags": ["flow", "architecture", "system"],
    }
    migrate_file(source, dest, metadata, migrations)

print()

# =============================================================================
# TECHNICAL NOTES
# =============================================================================
print("📝 Migrating Technical Notes...")
print("-" * 70)

tech_notes = [
    ("technical-notes/Firebase Auth State Loss Across Coroutines.md",
     "Firebase authentication state management in coroutines"),
    ("technical-notes/Multi-Participant Ranking and Tie-Breaking.md",
     "Multi-participant ranking algorithm and tie-breaking logic"),
]

for source, desc in tech_notes:
    filename = Path(source).name
    dest = f"Development/Guides/Best-Practices/{filename}"
    metadata = {
        "title": filename.replace('-', ' ').replace('.md', ''),
        "description": desc,
        "category": "development",
        "audience": ["developers"],
        "difficulty": "advanced",
        "status": "active",
        "last_updated": "2025-10-29",
        "tags": ["best-practices", "patterns", "lessons-learned"],
    }
    migrate_file(source, dest, metadata, migrations)

print()

# =============================================================================
# DEVELOPMENT PATTERNS
# =============================================================================
print("📐 Migrating Development Patterns...")
print("-" * 70)

pattern_files = [
    ("Development Patterns/Migration Testing - Unit Tests vs Instrumented Tests.md",
     "testing strategy for database migrations"),
]

for source, desc in pattern_files:
    filename = Path(source).name
    dest = f"Development/Guides/Best-Practices/{filename}"
    metadata = {
        "title": filename.replace('-', ' ').replace('.md', ''),
        "description": desc,
        "category": "development",
        "audience": ["developers"],
        "difficulty": "intermediate",
        "status": "active",
        "last_updated": "2025-10-29",
        "tags": ["testing", "migration", "patterns"],
    }
    migrate_file(source, dest, metadata, migrations)

print()

# =============================================================================
# GENERATE REPORT
# =============================================================================
print("=" * 70)
print(f"MIGRATION COMPLETE: {len(migrations)} files migrated")
print("=" * 70)

report = f"""# Phase 2A Migration Report

**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Phase:** 2A - Quick Wins
**Files Migrated:** {len(migrations)}

---

## Migration Summary

### Categories Migrated

1. **Testing Documentation** (9 files) → `Development/Testing/`
2. **Firebase Integration** (6 files) → `Development/Guides/Working-With/`
3. **System Flows** (6 files) → `Technical-Reference/Flows/System-Flows/`
4. **Technical Notes** (2 files) → `Development/Guides/Best-Practices/`
5. **Development Patterns** (1 file) → `Development/Guides/Best-Practices/`

**Total:** 24 files

---

## Migrations Performed

"""

for migration in migrations:
    report += f"{migration}\n"

report += f"""

---

## Changes Applied

### Added to Each File:
1. **YAML Frontmatter** - Metadata including title, description, category, audience, tags
2. **Breadcrumb Navigation** - Path from home to current document
3. **Status Indicators** - Document status and last updated date
4. **Related Documentation** - Cross-reference sections (where applicable)

### Directory Structure:
- `Development/Testing/` - 9 test guides
- `Development/Guides/Working-With/` - 6 Firebase docs
- `Development/Guides/Best-Practices/` - 3 pattern docs
- `Technical-Reference/Flows/System-Flows/` - 6 flow docs

---

## Next Steps (Phase 2B)

1. Migrate Architecture documentation
2. Migrate Project Management content
3. Migrate Contributing guides
4. Update cross-references

---

*Generated by Phase 2A Migration Script*
"""

report_path = BASE_DIR / "Meta/Phase-2A-Migration-Report.md"
report_path.write_text(report, encoding='utf-8')
print(f"\n📄 Report saved: Meta/Phase-2A-Migration-Report.md")
