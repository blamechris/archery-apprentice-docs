#!/usr/bin/env python3
"""
Migration Validation Script
Validates migrated documentation files for proper frontmatter and structure.

Usage:
    python validate-migration.py

Output:
    - Detailed validation report
    - List of files with issues
    - Suggested fixes
"""

import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple
from datetime import datetime

# Fix Windows console encoding for Unicode characters
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# ANSI color codes for terminal output
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

class ValidationIssue:
    """Represents a validation issue found in a file."""
    def __init__(self, severity: str, category: str, message: str, line_number: int = None):
        self.severity = severity  # 'error', 'warning', 'info'
        self.category = category  # 'frontmatter', 'breadcrumb', 'structure'
        self.message = message
        self.line_number = line_number

    def __str__(self):
        color = Colors.RED if self.severity == 'error' else Colors.YELLOW if self.severity == 'warning' else Colors.BLUE
        prefix = "❌" if self.severity == 'error' else "⚠️" if self.severity == 'warning' else "ℹ️"
        line_info = f" (line {self.line_number})" if self.line_number else ""
        return f"{color}{prefix} [{self.category.upper()}]{line_info} {self.message}{Colors.END}"

class FileValidation:
    """Validation results for a single file."""
    def __init__(self, filepath: Path):
        self.filepath = filepath
        self.issues: List[ValidationIssue] = []
        self.has_frontmatter = False
        self.has_new_style_frontmatter = False
        self.has_old_style_frontmatter = False
        self.has_breadcrumb = False
        self.breadcrumb_valid = False
        self.content_lines = []

    def add_issue(self, severity: str, category: str, message: str, line_number: int = None):
        self.issues.append(ValidationIssue(severity, category, message, line_number))

    def is_valid(self) -> bool:
        return len([i for i in self.issues if i.severity == 'error']) == 0

    def error_count(self) -> int:
        return len([i for i in self.issues if i.severity == 'error'])

    def warning_count(self) -> int:
        return len([i for i in self.issues if i.severity == 'warning'])

def extract_frontmatter(content: str) -> Tuple[str, str, int]:
    """
    Extract frontmatter from markdown content.
    Returns: (frontmatter, remaining_content, frontmatter_end_line)
    """
    lines = content.split('\n')
    if not lines or not lines[0].strip() == '---':
        return "", content, 0

    # Find the closing ---
    for i in range(1, len(lines)):
        if lines[i].strip() == '---':
            frontmatter = '\n'.join(lines[1:i])
            remaining = '\n'.join(lines[i+1:])
            return frontmatter, remaining, i + 1

    return "", content, 0

def validate_new_style_frontmatter(frontmatter: str) -> List[ValidationIssue]:
    """Validate that frontmatter has new-style YAML structure."""
    issues = []

    required_fields = ['title', 'description', 'category', 'audience', 'status']
    recommended_fields = ['difficulty', 'last_updated', 'tags']

    # Check for required fields
    for field in required_fields:
        pattern = rf'^{field}:\s*.+$'
        if not re.search(pattern, frontmatter, re.MULTILINE):
            issues.append(ValidationIssue(
                'error',
                'frontmatter',
                f"Missing required field: '{field}'"
            ))

    # Check for recommended fields
    for field in recommended_fields:
        pattern = rf'^{field}:\s*.+$'
        if not re.search(pattern, frontmatter, re.MULTILINE):
            issues.append(ValidationIssue(
                'warning',
                'frontmatter',
                f"Missing recommended field: '{field}'"
            ))

    # Check for old Obsidian-style fields (should not exist)
    old_style_fields = ['created', 'related']
    for field in old_style_fields:
        pattern = rf'^{field}:\s*.+$'
        if re.search(pattern, frontmatter, re.MULTILINE):
            issues.append(ValidationIssue(
                'error',
                'frontmatter',
                f"Found old Obsidian field: '{field}' (should be removed or converted)"
            ))

    # Check for Obsidian-style links [[...]] in frontmatter
    if '[[' in frontmatter:
        issues.append(ValidationIssue(
            'error',
            'frontmatter',
            "Found Obsidian-style wikilinks [[...]] (should use 'related_docs' array)"
        ))

    # Validate category value
    valid_categories = ['development', 'user-guide', 'technical-reference', 'meta']
    category_match = re.search(r'^category:\s*["\']?(\w+)["\']?$', frontmatter, re.MULTILINE)
    if category_match:
        category = category_match.group(1)
        if category not in valid_categories:
            issues.append(ValidationIssue(
                'warning',
                'frontmatter',
                f"Unusual category value: '{category}' (valid: {', '.join(valid_categories)})"
            ))

    # Validate status value
    valid_statuses = ['active', 'draft', 'archived', 'deprecated']
    status_match = re.search(r'^status:\s*["\']?(\w+)["\']?$', frontmatter, re.MULTILINE)
    if status_match:
        status = status_match.group(1)
        if status not in valid_statuses:
            issues.append(ValidationIssue(
                'warning',
                'frontmatter',
                f"Unusual status value: '{status}' (valid: {', '.join(valid_statuses)})"
            ))

    return issues

def validate_breadcrumb(content: str, filepath: Path) -> List[ValidationIssue]:
    """Validate breadcrumb navigation format."""
    issues = []

    # Look for breadcrumb pattern in first 20 lines after frontmatter
    lines = content.split('\n')[:20]
    breadcrumb_pattern = r'\[Home\]\(/\)\s*>'

    breadcrumb_line = None
    breadcrumb_line_num = None
    for i, line in enumerate(lines):
        if re.search(breadcrumb_pattern, line):
            breadcrumb_line = line.strip()
            breadcrumb_line_num = i + 1
            break

    if not breadcrumb_line:
        issues.append(ValidationIssue(
            'error',
            'breadcrumb',
            "No breadcrumb navigation found (should start with '[Home](/) >')"
        ))
        return issues

    # Check for malformed breadcrumb ending with "---"
    if breadcrumb_line.endswith('> ---'):
        issues.append(ValidationIssue(
            'error',
            'breadcrumb',
            f"Breadcrumb ends with '> ---' (should end with page title)",
            breadcrumb_line_num
        ))

    # Check if breadcrumb ends with a proper page title
    if not breadcrumb_line.endswith('> ---') and '>' in breadcrumb_line:
        # Extract last segment
        last_segment = breadcrumb_line.split('>')[-1].strip()
        if not last_segment or last_segment.startswith('['):
            issues.append(ValidationIssue(
                'warning',
                'breadcrumb',
                f"Breadcrumb may be malformed - last segment: '{last_segment}'",
                breadcrumb_line_num
            ))

    # Validate breadcrumb path matches file location
    relative_path = filepath.relative_to(Path.cwd())
    parts = list(relative_path.parts[:-1])  # Exclude filename

    for part in parts:
        # Convert directory name to expected breadcrumb format
        expected_text = part.replace('-', ' ').title()
        if expected_text not in breadcrumb_line:
            issues.append(ValidationIssue(
                'warning',
                'breadcrumb',
                f"Breadcrumb may not match file path - expected '{expected_text}' in breadcrumb",
                breadcrumb_line_num
            ))
            break  # Only report first mismatch

    return issues

def validate_structure(content: str) -> List[ValidationIssue]:
    """Validate document structure."""
    issues = []

    lines = content.split('\n')

    # Check for main heading (# Title)
    has_h1 = False
    h1_count = 0
    for i, line in enumerate(lines[:30]):  # Check first 30 lines
        if line.startswith('# '):
            has_h1 = True
            h1_count += 1

    if not has_h1:
        issues.append(ValidationIssue(
            'warning',
            'structure',
            "No H1 heading found in first 30 lines"
        ))

    if h1_count > 1:
        issues.append(ValidationIssue(
            'warning',
            'structure',
            f"Multiple H1 headings found ({h1_count}) - should have exactly 1"
        ))

    return issues

def validate_file(filepath: Path) -> FileValidation:
    """Validate a single markdown file."""
    validation = FileValidation(filepath)

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            validation.content_lines = content.split('\n')
    except Exception as e:
        validation.add_issue('error', 'file', f"Failed to read file: {str(e)}")
        return validation

    # Extract frontmatter
    frontmatter, remaining_content, fm_end_line = extract_frontmatter(content)

    if not frontmatter:
        validation.add_issue('error', 'frontmatter', "No frontmatter found (should start with '---')")
        return validation

    validation.has_frontmatter = True

    # Check if it's new-style or old-style frontmatter
    has_title = 'title:' in frontmatter
    has_old_tags = re.search(r'^tags:\s*$', frontmatter, re.MULTILINE)  # Old style: tags at root level
    has_old_created = 'created:' in frontmatter
    has_old_related = 'related:' in frontmatter or '[[' in frontmatter

    if has_title:
        validation.has_new_style_frontmatter = True

    if has_old_tags or has_old_created or has_old_related:
        validation.has_old_style_frontmatter = True
        validation.add_issue('error', 'frontmatter', "Found old Obsidian-style frontmatter (needs migration)")

    # Validate new-style frontmatter
    frontmatter_issues = validate_new_style_frontmatter(frontmatter)
    validation.issues.extend(frontmatter_issues)

    # Validate breadcrumb
    breadcrumb_issues = validate_breadcrumb(remaining_content, filepath)
    validation.issues.extend(breadcrumb_issues)
    if not breadcrumb_issues:
        validation.has_breadcrumb = True
        validation.breadcrumb_valid = True
    elif len([i for i in breadcrumb_issues if i.severity == 'error']) == 0:
        validation.has_breadcrumb = True
        validation.breadcrumb_valid = False

    # Validate structure
    structure_issues = validate_structure(remaining_content)
    validation.issues.extend(structure_issues)

    return validation

def scan_directory(directory: Path) -> List[FileValidation]:
    """Scan directory for markdown files and validate them."""
    validations = []

    # Find all markdown files (excluding README.md)
    for md_file in directory.rglob('*.md'):
        if md_file.name.lower() == 'readme.md':
            continue

        # Only validate files in target directories
        relative_path = md_file.relative_to(directory)
        if relative_path.parts[0] in ['Development', 'Technical-Reference', 'User-Guide', 'Meta']:
            validation = validate_file(md_file)
            validations.append(validation)

    return validations

def generate_report(validations: List[FileValidation]) -> str:
    """Generate a detailed validation report."""
    lines = []

    # Header
    lines.append(f"{Colors.BOLD}{'='*80}{Colors.END}")
    lines.append(f"{Colors.BOLD}Documentation Migration Validation Report{Colors.END}")
    lines.append(f"{Colors.BOLD}{'='*80}{Colors.END}")
    lines.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append("")

    # Summary statistics
    total_files = len(validations)
    valid_files = len([v for v in validations if v.is_valid()])
    invalid_files = total_files - valid_files
    total_errors = sum(v.error_count() for v in validations)
    total_warnings = sum(v.warning_count() for v in validations)

    lines.append(f"{Colors.BOLD}Summary:{Colors.END}")
    lines.append(f"  Total files validated: {total_files}")
    lines.append(f"  {Colors.GREEN}✅ Valid files: {valid_files}{Colors.END}")
    lines.append(f"  {Colors.RED}❌ Files with errors: {invalid_files}{Colors.END}")
    lines.append(f"  {Colors.RED}Total errors: {total_errors}{Colors.END}")
    lines.append(f"  {Colors.YELLOW}Total warnings: {total_warnings}{Colors.END}")
    lines.append("")

    # Frontmatter statistics
    new_style = len([v for v in validations if v.has_new_style_frontmatter])
    old_style = len([v for v in validations if v.has_old_style_frontmatter])
    no_fm = len([v for v in validations if not v.has_frontmatter])

    lines.append(f"{Colors.BOLD}Frontmatter Statistics:{Colors.END}")
    lines.append(f"  New-style frontmatter: {new_style}/{total_files} ({100*new_style/total_files:.1f}%)")
    lines.append(f"  Old-style frontmatter: {old_style}/{total_files} ({100*old_style/total_files:.1f}%)")
    lines.append(f"  No frontmatter: {no_fm}/{total_files}")
    lines.append("")

    # Breadcrumb statistics
    has_breadcrumb = len([v for v in validations if v.has_breadcrumb])
    valid_breadcrumb = len([v for v in validations if v.breadcrumb_valid])

    lines.append(f"{Colors.BOLD}Breadcrumb Statistics:{Colors.END}")
    lines.append(f"  Has breadcrumb: {has_breadcrumb}/{total_files}")
    lines.append(f"  Valid breadcrumb: {valid_breadcrumb}/{total_files}")
    lines.append("")

    # Files with issues
    if invalid_files > 0:
        lines.append(f"{Colors.BOLD}{'='*80}{Colors.END}")
        lines.append(f"{Colors.BOLD}Files with Issues:{Colors.END}")
        lines.append(f"{Colors.BOLD}{'='*80}{Colors.END}")
        lines.append("")

        for validation in validations:
            if not validation.is_valid():
                relative_path = validation.filepath.relative_to(Path.cwd())
                error_count = validation.error_count()
                warning_count = validation.warning_count()

                lines.append(f"{Colors.RED}❌ {relative_path}{Colors.END}")
                lines.append(f"   Errors: {error_count}, Warnings: {warning_count}")

                for issue in validation.issues:
                    lines.append(f"   {issue}")

                lines.append("")

    # Files with only warnings
    warning_only_files = [v for v in validations if v.is_valid() and v.warning_count() > 0]
    if warning_only_files:
        lines.append(f"{Colors.BOLD}{'='*80}{Colors.END}")
        lines.append(f"{Colors.BOLD}Files with Warnings (No Errors):{Colors.END}")
        lines.append(f"{Colors.BOLD}{'='*80}{Colors.END}")
        lines.append("")

        for validation in warning_only_files:
            relative_path = validation.filepath.relative_to(Path.cwd())
            warning_count = validation.warning_count()

            lines.append(f"{Colors.YELLOW}⚠️  {relative_path}{Colors.END} ({warning_count} warnings)")

            for issue in validation.issues:
                if issue.severity == 'warning':
                    lines.append(f"   {issue}")

            lines.append("")

    # Recommendations
    lines.append(f"{Colors.BOLD}{'='*80}{Colors.END}")
    lines.append(f"{Colors.BOLD}Recommendations:{Colors.END}")
    lines.append(f"{Colors.BOLD}{'='*80}{Colors.END}")
    lines.append("")

    if old_style > 0:
        lines.append(f"{Colors.RED}1. Fix Old-Style Frontmatter ({old_style} files){Colors.END}")
        lines.append("   - Remove 'created', 'related', and root-level 'tags' fields")
        lines.append("   - Add required fields: title, description, category, audience, status")
        lines.append("   - Convert [[wikilinks]] to 'related_docs' array")
        lines.append("")

    if invalid_files - old_style > 0:
        lines.append(f"{Colors.RED}2. Fix Malformed Breadcrumbs{Colors.END}")
        lines.append("   - Breadcrumbs should end with page title, not '---'")
        lines.append("   - Format: [Home](/) > [Section](/Section/) > Page Title")
        lines.append("")

    if total_warnings > 0:
        lines.append(f"{Colors.YELLOW}3. Address Warnings{Colors.END}")
        lines.append("   - Add missing recommended fields (difficulty, last_updated, tags)")
        lines.append("   - Verify breadcrumb paths match file locations")
        lines.append("   - Ensure single H1 heading per document")
        lines.append("")

    lines.append(f"{Colors.BOLD}{'='*80}{Colors.END}")

    return '\n'.join(lines)

def main():
    """Main validation entry point."""
    print(f"\n{Colors.BOLD}Starting Documentation Migration Validation...{Colors.END}\n")

    # Get current directory (should be docs repo root)
    docs_root = Path.cwd()

    # Validate that we're in the right directory
    if not (docs_root / 'Development').exists():
        print(f"{Colors.RED}Error: Not in documentation repository root!{Colors.END}")
        print(f"Current directory: {docs_root}")
        print(f"Expected to find 'Development/' directory")
        return 1

    print(f"Scanning directory: {docs_root}")
    print(f"Looking for markdown files in: Development/, Technical-Reference/, User-Guide/, Meta/")
    print("")

    # Scan and validate
    validations = scan_directory(docs_root)

    print(f"Found {len(validations)} files to validate")
    print("")

    # Generate report
    report = generate_report(validations)
    print(report)

    # Save report to file
    report_path = docs_root / 'validation-report.txt'
    with open(report_path, 'w', encoding='utf-8') as f:
        # Strip ANSI color codes for file output
        clean_report = re.sub(r'\033\[[0-9;]+m', '', report)
        f.write(clean_report)

    print(f"\n{Colors.GREEN}Report saved to: {report_path}{Colors.END}\n")

    # Exit code based on validation results
    invalid_count = len([v for v in validations if not v.is_valid()])
    return 0 if invalid_count == 0 else 1

if __name__ == '__main__':
    exit(main())
