#!/usr/bin/env python3
"""Create README files for all documentation folders"""

import os
from pathlib import Path

# Define folder structure with descriptions
folders = {
    "User-Guide": "comprehensive user documentation",
    "User-Guide/Quick-Start": "getting started guides for users",
    "User-Guide/Features": "detailed feature documentation",
    "User-Guide/Features/Scoring": "scoring system documentation",
    "User-Guide/Features/Equipment": "equipment management documentation",
    "User-Guide/Features/Analytics": "analytics and statistics documentation",
    "User-Guide/Features/Sync": "sync and cloud features documentation",
    "User-Guide/How-To": "step-by-step guides for common tasks",
    "User-Guide/How-To/Scoring-Scenarios": "guides for different scoring situations",
    "User-Guide/How-To/Equipment-Tasks": "guides for equipment management tasks",
    "User-Guide/How-To/Data-Management": "guides for managing your data",
    "User-Guide/Reference": "quick reference materials",
    "User-Guide/Troubleshooting": "solutions to common problems",
    "Development": "developer documentation and guides",
    "Development/Getting-Started": "setup guides for developers",
    "Development/Architecture": "architecture documentation",
    "Development/Architecture/Layers": "layer architecture documentation",
    "Development/Architecture/Patterns": "design patterns and best practices",
    "Development/Architecture/Diagrams": "architecture diagrams and visualizations",
    "Development/Guides": "developer how-to guides",
    "Development/Guides/Adding-Features": "guides for adding new features",
    "Development/Guides/Working-With": "guides for working with specific systems",
    "Development/Guides/Best-Practices": "coding standards and best practices",
    "Development/Testing": "testing guides and strategies",
    "Development/Contributing": "contribution guidelines",
    "Development/Tools": "development tools documentation",
    "Technical-Reference": "technical API and system documentation",
    "Technical-Reference/Database": "database schema and documentation",
    "Technical-Reference/Database/Tables": "database table schemas",
    "Technical-Reference/Database/Migrations": "database migration history",
    "Technical-Reference/API": "API documentation",
    "Technical-Reference/API/Repositories": "repository layer API documentation",
    "Technical-Reference/API/ViewModels": "ViewModel API documentation",
    "Technical-Reference/API/Services": "service layer API documentation",
    "Technical-Reference/API/DAOs": "DAO layer API documentation",
    "Technical-Reference/Flows": "system and user flow documentation",
    "Technical-Reference/Flows/User-Flows": "user interaction flows",
    "Technical-Reference/Flows/System-Flows": "internal system flows",
    "Technical-Reference/Flows/Integration-Flows": "integration and sync flows",
    "Technical-Reference/Data-Models": "data model documentation",
    "Technical-Reference/Data-Models/Equipment": "equipment data models",
    "Technical-Reference/Data-Models/Scoring": "scoring data models",
    "Technical-Reference/Data-Models/Tournament": "tournament data models",
    "Technical-Reference/Data-Models/Analytics": "analytics data models",
    "Technical-Reference/Code-Examples": "code examples and snippets",
    "Technical-Reference/Code-Examples/Common-Patterns": "common coding patterns",
    "Technical-Reference/Code-Examples/Feature-Examples": "feature implementation examples",
    "Technical-Reference/Code-Examples/Testing-Examples": "testing code examples",
    "Technical-Reference/Performance": "performance guidelines and optimization",
    "Architecture-Decisions": "architecture decision records (ADRs)",
    "Project-Management": "project tracking and status",
    "Project-Management/Roadmap": "project roadmap and planning",
    "Project-Management/Release-Notes": "version release notes",
    "Project-Management/Known-Issues": "known issues and workarounds",
    "Project-Management/Status": "current project status",
    "Project-Management/Team": "team information and contacts",
    "Meta": "documentation about the documentation",
    "Meta/Templates": "documentation templates",
    "assets": "images, videos, and downloadable files",
    "assets/images": "all image assets",
    "assets/videos": "video tutorials and demos",
    "assets/downloads": "downloadable files and samples",
}

base_dir = Path("/mnt/c/Users/chris_3zal3ta/Documents/ArcheryApprentice-Docs")

for folder_path, description in folders.items():
    folder_name = folder_path.split("/")[-1].replace("-", " ")
    readme_path = base_dir / folder_path / "README.md"

    # Ensure directory exists
    readme_path.parent.mkdir(parents=True, exist_ok=True)

    content = f"""# {folder_name}

This folder contains: {description}

**Status:** 🚧 Under Construction

Contents:
- [Will be populated during documentation creation]
"""

    readme_path.write_text(content, encoding='utf-8')
    print(f"✅ Created {readme_path}")

print(f"\n✨ Created {len(folders)} README files!")
