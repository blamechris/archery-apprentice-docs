#!/usr/bin/env python3
"""
FIXED Content Migration Script for Phase 2
Addresses Agent 1 validation findings:
- Strips old frontmatter completely
- Fixes breadcrumb generation
- Integrates validation
- Tests sample before batch
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

    def strip_old_frontmatter(self, content):
        """
        Strip existing frontmatter completely.
        Handles both ---...--- and +++...+++ styles.
        """
        lines = content.split('\n')

        # Check if file starts with frontmatter delimiter
        if not lines or lines[0].strip() not in ['---', '+++']:
            return content

        delimiter = lines[0].strip()

        # Find closing delimiter
        for i in range(1, len(lines)):
            if lines[i].strip() == delimiter:
                # Return content after frontmatter (skip the closing delimiter line)
                return '\n'.join(lines[i+1:])

        # If no closing delimiter found, return original content
        return content

    def generate_breadcrumb(self, dest_path, title):
        """
        Generate proper breadcrumb navigation.
        Fixed: Now ends with page title, not "---"
        """
        parts = dest_path.split('/')
        breadcrumb_parts = ["[Home](/)"]

        # Build breadcrumb from path
        path_so_far = ""
        for i, part in enumerate(parts[:-1]):  # Exclude filename
            if part in [".", ".."]:
                continue

            # Add major sections
            if part in ["Development", "User-Guide", "Technical-Reference",
                       "Architecture-Decisions", "Project-Management", "Meta"]:
                path_so_far = f"/{part}/"
                display_name = part.replace('-', ' ')
                breadcrumb_parts.append(f"[{display_name}]({path_so_far})")
            # Add subsections
            elif i > 0 and path_so_far:
                path_so_far += part + "/"
                display_name = part.replace('-', ' ')
                breadcrumb_parts.append(f"[{display_name}]({path_so_far})")

        # Add page title at the end (FIXED: was ending with "---")
        breadcrumb = " > ".join(breadcrumb_parts) + f" > {title}"

        return breadcrumb + "\n\n---\n\n"

    def create_frontmatter(self, metadata):
        """Create new-style YAML frontmatter."""
        frontmatter = "---\n"

        # Add fields in specific order
        field_order = [
            'title', 'description', 'category', 'audience',
            'difficulty', 'status', 'last_updated', 'tags', 'related_docs'
        ]

        for field in field_order:
            if field not in metadata:
                continue

            value = metadata[field]

            if isinstance(value, list):
                if not value:  # Skip empty lists
                    continue
                frontmatter += f"{field}:\n"
                for item in value:
                    if isinstance(item, dict):
                        # Handle related_docs structure
                        frontmatter += f"  - title: \"{item.get('title', '')}\"\n"
                        frontmatter += f"    path: \"{item.get('path', '')}\"\n"
                        if 'relationship' in item:
                            frontmatter += f"    relationship: \"{item['relationship']}\"\n"
                    else:
                        frontmatter += f"  - \"{item}\"\n"
            else:
                frontmatter += f"{field}: \"{value}\"\n"

        frontmatter += "---\n\n"
        return frontmatter

    def migrate_file(self, source_path, dest_path, metadata):
        """
        Migrate a single file with proper frontmatter and breadcrumb.
        Returns: (success: bool, validation_issues: list)
        """
        source = self.base_dir / source_path
        dest = self.base_dir / dest_path

        if not source.exists():
            error = f"Source not found: {source_path}"
            self.errors.append(error)
            return False, [error]

        # Read source content
        try:
            content = source.read_text(encoding='utf-8')
        except Exception as e:
            error = f"Error reading {source_path}: {e}"
            self.errors.append(error)
            return False, [error]

        # Step 1: Strip old frontmatter
        content_without_frontmatter = self.strip_old_frontmatter(content)

        # Step 2: Create new frontmatter
        new_frontmatter = self.create_frontmatter(metadata)

        # Step 3: Generate breadcrumb
        title = metadata.get('title', Path(source_path).stem.replace('-', ' '))
        breadcrumb = self.generate_breadcrumb(dest_path, title)

        # Step 4: Combine all parts
        final_content = new_frontmatter + breadcrumb + content_without_frontmatter.lstrip()

        # Step 5: Validate before writing
        validation_issues = self.validate_content(final_content, dest_path)

        # Step 6: Write to destination
        try:
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_text(final_content, encoding='utf-8')

            self.migrations.append({
                'source': source_path,
                'dest': dest_path,
                'status': 'success' if not validation_issues else 'success_with_warnings',
                'validation_issues': validation_issues
            })

            status_icon = "✅" if not validation_issues else "⚠️"
            print(f"{status_icon} Migrated: {source_path} → {dest_path}")

            if validation_issues:
                for issue in validation_issues:
                    print(f"   └─ {issue}")

            return True, validation_issues

        except Exception as e:
            error = f"Error writing {dest_path}: {e}"
            self.errors.append(error)
            return False, [error]

    def validate_content(self, content, filepath):
        """
        Basic validation of migrated content.
        Returns list of validation issues (empty if valid).
        """
        issues = []
        lines = content.split('\n')

        # Check frontmatter
        if not lines[0].strip() == '---':
            issues.append("Missing frontmatter opening")
            return issues

        # Find frontmatter closing
        frontmatter_end = -1
        for i in range(1, min(50, len(lines))):  # Check first 50 lines
            if lines[i].strip() == '---':
                frontmatter_end = i
                break

        if frontmatter_end == -1:
            issues.append("Missing frontmatter closing")
            return issues

        # Extract frontmatter
        frontmatter = '\n'.join(lines[1:frontmatter_end])

        # Check required fields
        required_fields = ['title:', 'description:', 'category:', 'audience:', 'status:']
        for field in required_fields:
            if field not in frontmatter:
                issues.append(f"Missing required field: {field[:-1]}")

        # Check for old Obsidian fields
        old_fields = ['created:', 'related:']  # Note: 'tags:' is valid in both
        for field in old_fields:
            if field in frontmatter:
                issues.append(f"Old Obsidian field found: {field[:-1]}")

        # Check breadcrumb
        breadcrumb_line_idx = frontmatter_end + 1
        if breadcrumb_line_idx < len(lines):
            breadcrumb = lines[breadcrumb_line_idx]
            if '[Home](/)' in breadcrumb:
                if breadcrumb.strip().endswith('> ---'):
                    issues.append("Breadcrumb ends with '> ---' instead of page title")
                if not '>' in breadcrumb:
                    issues.append("Breadcrumb missing navigation arrows")
            else:
                issues.append("No breadcrumb found after frontmatter")

        return issues

def test_migration_on_sample():
    """Test migration on a single sample file before batch processing."""
    print("=" * 70)
    print("TESTING MIGRATION ON SAMPLE FILE")
    print("=" * 70)
    print()

    base_dir = "/mnt/c/Users/chris_3zal3ta/Documents/ArcheryApprentice-Docs"
    migrator = ContentMigrator(base_dir)

    # Test on one file
    test_source = "Testing/Coverage-Guide.md"
    test_dest = "Development/Testing/Coverage-Guide-TEST.md"
    test_metadata = {
        "title": "Test Coverage Guide",
        "description": "Guide to understanding and improving test coverage",
        "category": "development",
        "audience": ["developers"],
        "difficulty": "intermediate",
        "status": "active",
        "last_updated": "2025-10-29",
        "tags": ["testing", "coverage", "quality"],
    }

    success, issues = migrator.migrate_file(test_source, test_dest, test_metadata)

    if success and not issues:
        print("\n✅ TEST PASSED - Sample file migrated correctly!")
        print(f"   Check: {test_dest}")
        return True
    elif success and issues:
        print("\n⚠️  TEST PASSED WITH WARNINGS")
        print(f"   Issues found: {len(issues)}")
        for issue in issues:
            print(f"   - {issue}")
        return True
    else:
        print("\n❌ TEST FAILED")
        print(f"   Errors: {migrator.errors}")
        return False

if __name__ == "__main__":
    print("FIXED Migration Script - Agent 1 Issues Addressed")
    print()
    print("Run test_migration_on_sample() to test before batch migration")
    print()

    # Uncomment to run test:
    # test_migration_on_sample()
