#!/usr/bin/env python3
"""
Migrate all directories and files to kebab-case naming.

Usage:
    python scripts/migrate-to-kebab-case.py --dry-run  # Preview changes
    python scripts/migrate-to-kebab-case.py            # Execute changes
"""

import os
import re
import subprocess
import sys
from pathlib import Path
from typing import List, Tuple

def to_kebab_case(name: str) -> str:
    """
    Convert PascalCase, Mixed-Case, or spaces to kebab-case.

    Examples:
        'DataModels' → 'data-models'
        'API Reference' → 'api-reference'
        'KMP Migration' → 'kmp-migration'
        'view-models' → 'view-models' (unchanged)
    """
    # Replace spaces with hyphens
    s = name.replace(' ', '-')

    # Handle PascalCase: DataModels → data-models
    # Insert hyphen before uppercase letters that follow lowercase
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1-\2', s)

    # Handle acronyms: APIReference → api-reference
    s2 = re.sub('([a-z0-9])([A-Z])', r'\1-\2', s1)

    # Lowercase everything
    s3 = s2.lower()

    # Clean up multiple consecutive hyphens
    s4 = re.sub('-+', '-', s3)

    # Remove leading/trailing hyphens
    s5 = s4.strip('-')

    return s5

def find_non_kebab_dirs(root_path: Path) -> List[Tuple[Path, str]]:
    """
    Find all directories that aren't kebab-case.
    Returns list of (full_path, kebab_name) tuples.
    """
    non_kebab = []

    # Walk directory tree bottom-up to rename deepest directories first
    for dirpath, dirnames, filenames in os.walk(root_path, topdown=False):
        for dirname in dirnames:
            kebab = to_kebab_case(dirname)
            if dirname != kebab:
                full_path = Path(dirpath) / dirname
                non_kebab.append((full_path, kebab))

    return non_kebab

def find_non_kebab_files(root_path: Path) -> List[Tuple[Path, str]]:
    """
    Find all .md files that aren't kebab-case.
    Returns list of (full_path, kebab_name) tuples.
    """
    non_kebab = []

    for filepath in root_path.rglob('*.md'):
        filename = filepath.name
        name_without_ext = filepath.stem
        kebab = to_kebab_case(name_without_ext)

        if name_without_ext != kebab:
            new_filename = f"{kebab}{filepath.suffix}"
            non_kebab.append((filepath, new_filename))

    return non_kebab

def git_mv(old_path: Path, new_path: Path, dry_run: bool = False) -> bool:
    """
    Move a file/directory using git mv to preserve history.
    Handles Windows case-sensitivity issues with a two-step rename.
    Returns True if successful, False otherwise.
    """
    if dry_run:
        print(f"  [DRY-RUN] git mv '{old_path}' '{new_path}'")
        return True

    # Check if this is a case-only rename (same path but different case)
    if old_path.parent == new_path.parent and old_path.name.lower() == new_path.name.lower():
        # Two-step rename for case-only changes (Windows compatibility)
        temp_path = old_path.parent / f"{old_path.name}_temp_rename"

        try:
            # Step 1: Rename to temporary name
            subprocess.run(
                ['git', 'mv', str(old_path), str(temp_path)],
                check=True,
                capture_output=True,
                text=True
            )

            # Step 2: Rename to final name
            subprocess.run(
                ['git', 'mv', str(temp_path), str(new_path)],
                check=True,
                capture_output=True,
                text=True
            )

            print(f"  OK Renamed (2-step): {old_path} => {new_path}")
            return True
        except subprocess.CalledProcessError as e:
            print(f"  ERROR renaming {old_path}: {e.stderr}")
            # Try to clean up temp path if it exists
            if temp_path.exists():
                try:
                    subprocess.run(['git', 'mv', str(temp_path), str(old_path)], check=False)
                except:
                    pass
            return False
    else:
        # Direct rename for non-case-only changes
        try:
            subprocess.run(
                ['git', 'mv', str(old_path), str(new_path)],
                check=True,
                capture_output=True,
                text=True
            )
            print(f"  OK Renamed: {old_path} => {new_path}")
            return True
        except subprocess.CalledProcessError as e:
            print(f"  ERROR renaming {old_path}: {e.stderr}")
            return False

def remove_redundant_nesting(dry_run: bool = False) -> int:
    """
    Remove the redundant content/internal/kmp-migration/kmp-migration/ directory.
    Returns number of directories removed.
    """
    redundant_dir = Path('content/internal/kmp-migration/kmp-migration')

    if not redundant_dir.exists():
        print("No redundant kmp-migration/kmp-migration/ directory found.")
        return 0

    print("\n=== Fixing Redundant Nesting ===\n")
    print(f"Removing duplicate directory: {redundant_dir}")

    if dry_run:
        print(f"  [DRY-RUN] Would remove: {redundant_dir}")
        return 1
    else:
        try:
            # Use git rm -r to remove directory while preserving history
            subprocess.run(
                ['git', 'rm', '-r', str(redundant_dir)],
                check=True,
                capture_output=True,
                text=True
            )
            print(f"  OK Removed redundant directory: {redundant_dir}")
            return 1
        except subprocess.CalledProcessError as e:
            print(f"  ERROR removing {redundant_dir}: {e.stderr}")
            return 0

def rename_directories(root_path: Path, dry_run: bool = False) -> int:
    """
    Rename all non-kebab-case directories.
    Returns number of directories renamed.
    """
    non_kebab = find_non_kebab_dirs(root_path)

    if not non_kebab:
        print("No directories need renaming.")
        return 0

    print(f"\n=== Found {len(non_kebab)} directories to rename ===\n")

    success_count = 0
    for old_path, new_name in non_kebab:
        new_path = old_path.parent / new_name
        print(f"Directory: {old_path.relative_to(root_path)}")
        print(f"  => {new_name}")

        if git_mv(old_path, new_path, dry_run):
            success_count += 1
        print()

    return success_count

def rename_files(root_path: Path, dry_run: bool = False) -> int:
    """
    Rename all non-kebab-case .md files.
    Returns number of files renamed.
    """
    non_kebab = find_non_kebab_files(root_path)

    if not non_kebab:
        print("No files need renaming.")
        return 0

    print(f"\n=== Found {len(non_kebab)} files to rename ===\n")

    success_count = 0
    for old_path, new_name in non_kebab:
        new_path = old_path.parent / new_name
        print(f"File: {old_path.relative_to(root_path)}")
        print(f"  => {new_name}")

        if git_mv(old_path, new_path, dry_run):
            success_count += 1
        print()

    return success_count

def main():
    dry_run = '--dry-run' in sys.argv
    root = Path('content')

    if not root.exists():
        print(f"Error: {root} directory not found!")
        print("Run this script from the repository root.")
        sys.exit(1)

    print("=" * 70)
    print("Kebab-Case Migration Script")
    print("=" * 70)

    if dry_run:
        print("\n[DRY-RUN MODE] - No changes will be made\n")
    else:
        print("\n[LIVE MODE] - Changes will be applied\n")
        response = input("Continue? (yes/no): ")
        if response.lower() != 'yes':
            print("Aborted.")
            sys.exit(0)

    # Phase 1: Remove redundant nesting
    removed_count = remove_redundant_nesting(dry_run)

    # Phase 2: Rename directories
    dir_count = rename_directories(root, dry_run)

    # Phase 3: Rename files
    file_count = rename_files(root, dry_run)

    # Summary
    print("=" * 70)
    print("Migration Summary")
    print("=" * 70)
    print(f"Redundant directories removed: {removed_count}")
    print(f"Directories renamed: {dir_count}")
    print(f"Files renamed: {file_count}")
    print(f"Total changes: {removed_count + dir_count + file_count}")

    if dry_run:
        print("\nDry-run complete. Run without --dry-run to apply changes.")
    else:
        print("\nMigration complete!")
        print("\nNext steps:")
        print("1. Run: npx quartz build")
        print("2. Check for broken links")
        print("3. Commit changes")

if __name__ == '__main__':
    main()
