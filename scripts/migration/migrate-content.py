#!/usr/bin/env python3
"""
Content Migration Script for Phase 2
Moves files to new structure and adds YAML frontmatter
"""

import os
import re
from pathlib import Path
from datetime import datetime

class ContentMigrator:
    def __init__(self, base_dir):
        self.base_dir = Path(base_dir)
        self.migrations = []
        self.errors = []

    def add_frontmatter(self, content, metadata):
        """Add YAML frontmatter to content if not already present"""
        # Check if frontmatter already exists
        if content.startswith('---\n'):
            return content

        frontmatter = "---\n"
        for key, value in metadata.items():
            if isinstance(value, list):
                frontmatter += f"{key}:\n"
                for item in value:
                    frontmatter += f"  - {item}\n"
            else:
                frontmatter += f"{key}: \"{value}\"\n"
        frontmatter += "---\n\n"

        return frontmatter + content

    def migrate_file(self, source_path, dest_path, metadata):
        """Migrate a single file with frontmatter"""
        source = self.base_dir / source_path
        dest = self.base_dir / dest_path

        if not source.exists():
            self.errors.append(f"Source not found: {source_path}")
            return False

        # Read source content
        try:
            content = source.read_text(encoding='utf-8')
        except Exception as e:
            self.errors.append(f"Error reading {source_path}: {e}")
            return False

        # Add frontmatter
        content_with_frontmatter = self.add_frontmatter(content, metadata)

        # Create destination directory
        dest.parent.mkdir(parents=True, exist_ok=True)

        # Write to destination
        try:
            dest.write_text(content_with_frontmatter, encoding='utf-8')
            self.migrations.append({
                'source': source_path,
                'dest': dest_path,
                'status': 'success'
            })
            print(f"✅ Migrated: {source_path} → {dest_path}")
            return True
        except Exception as e:
            self.errors.append(f"Error writing {dest_path}: {e}")
            return False

    def generate_report(self, output_path):
        """Generate migration report"""
        report = f"""# Content Migration Report

**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Total Migrations:** {len(self.migrations)}
**Errors:** {len(self.errors)}

---

## Successful Migrations

| Source | Destination | Status |
|--------|-------------|--------|
"""
        for migration in self.migrations:
            report += f"| `{migration['source']}` | `{migration['dest']}` | ✅ |\n"

        if self.errors:
            report += "\n---\n\n## Errors\n\n"
            for error in self.errors:
                report += f"- ❌ {error}\n"

        report_file = self.base_dir / output_path
        report_file.write_text(report, encoding='utf-8')
        print(f"\n📄 Report generated: {output_path}")

# Usage example
if __name__ == "__main__":
    base_dir = "/mnt/c/Users/chris_3zal3ta/Documents/ArcheryApprentice-Docs"
    migrator = ContentMigrator(base_dir)

    # This script is imported and used by the actual migration script
    print("Migration utility loaded. Use from migration scripts.")
