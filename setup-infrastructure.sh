#!/bin/bash

# Documentation Infrastructure Setup Script
# Creates folder structure and README files for Archery Apprentice docs

BASE_DIR="/mnt/c/Users/chris_3zal3ta/Documents/ArcheryApprentice-Docs"

# Function to create directory and README
create_dir_with_readme() {
    local dir_path="$1"
    local folder_name="$2"
    local description="$3"

    mkdir -p "$dir_path"

    cat > "$dir_path/README.md" << EOF
# $folder_name

This folder contains: $description

**Status:** 🚧 Under Construction

Contents:
- [Will be populated during documentation creation]
EOF
}

# Getting Started
create_dir_with_readme "$BASE_DIR/Getting-Started" "Getting Started" "quick start guides for new users and developers"

# User Guide
create_dir_with_readme "$BASE_DIR/User-Guide" "User Guide" "comprehensive user documentation"
create_dir_with_readme "$BASE_DIR/User-Guide/Quick-Start" "Quick Start" "getting started guides for users"
create_dir_with_readme "$BASE_DIR/User-Guide/Features" "Features" "detailed feature documentation"
create_dir_with_readme "$BASE_DIR/User-Guide/Features/Scoring" "Scoring" "scoring system documentation"
create_dir_with_readme "$BASE_DIR/User-Guide/Features/Equipment" "Equipment" "equipment management documentation"
create_dir_with_readme "$BASE_DIR/User-Guide/Features/Analytics" "Analytics" "analytics and statistics documentation"
create_dir_with_readme "$BASE_DIR/User-Guide/Features/Sync" "Sync" "sync and cloud features documentation"
create_dir_with_readme "$BASE_DIR/User-Guide/How-To" "How-To" "step-by-step guides for common tasks"
create_dir_with_readme "$BASE_DIR/User-Guide/How-To/Scoring-Scenarios" "Scoring Scenarios" "guides for different scoring situations"
create_dir_with_readme "$BASE_DIR/User-Guide/How-To/Equipment-Tasks" "Equipment Tasks" "guides for equipment management tasks"
create_dir_with_readme "$BASE_DIR/User-Guide/How-To/Data-Management" "Data Management" "guides for managing your data"
create_dir_with_readme "$BASE_DIR/User-Guide/Reference" "Reference" "quick reference materials"
create_dir_with_readme "$BASE_DIR/User-Guide/Troubleshooting" "Troubleshooting" "solutions to common problems"

# Development
create_dir_with_readme "$BASE_DIR/Development" "Development" "developer documentation and guides"
create_dir_with_readme "$BASE_DIR/Development/Getting-Started" "Getting Started" "setup guides for developers"
create_dir_with_readme "$BASE_DIR/Development/Architecture" "Architecture" "architecture documentation"
create_dir_with_readme "$BASE_DIR/Development/Architecture/Layers" "Layers" "layer architecture documentation"
create_dir_with_readme "$BASE_DIR/Development/Architecture/Patterns" "Patterns" "design patterns and best practices"
create_dir_with_readme "$BASE_DIR/Development/Architecture/Diagrams" "Diagrams" "architecture diagrams and visualizations"
create_dir_with_readme "$BASE_DIR/Development/Guides" "Guides" "developer how-to guides"
create_dir_with_readme "$BASE_DIR/Development/Guides/Adding-Features" "Adding Features" "guides for adding new features"
create_dir_with_readme "$BASE_DIR/Development/Guides/Working-With" "Working With" "guides for working with specific systems"
create_dir_with_readme "$BASE_DIR/Development/Guides/Best-Practices" "Best Practices" "coding standards and best practices"
create_dir_with_readme "$BASE_DIR/Development/Testing" "Testing" "testing guides and strategies"
create_dir_with_readme "$BASE_DIR/Development/Contributing" "Contributing" "contribution guidelines"
create_dir_with_readme "$BASE_DIR/Development/Tools" "Tools" "development tools documentation"

# Technical Reference
create_dir_with_readme "$BASE_DIR/Technical-Reference" "Technical Reference" "technical API and system documentation"
create_dir_with_readme "$BASE_DIR/Technical-Reference/Database" "Database" "database schema and documentation"
create_dir_with_readme "$BASE_DIR/Technical-Reference/Database/Tables" "Tables" "database table schemas"
create_dir_with_readme "$BASE_DIR/Technical-Reference/Database/Migrations" "Migrations" "database migration history"
create_dir_with_readme "$BASE_DIR/Technical-Reference/API" "API" "API documentation"
create_dir_with_readme "$BASE_DIR/Technical-Reference/API/Repositories" "Repositories" "repository layer API documentation"
create_dir_with_readme "$BASE_DIR/Technical-Reference/API/ViewModels" "ViewModels" "ViewModel API documentation"
create_dir_with_readme "$BASE_DIR/Technical-Reference/API/Services" "Services" "service layer API documentation"
create_dir_with_readme "$BASE_DIR/Technical-Reference/API/DAOs" "DAOs" "DAO layer API documentation"
create_dir_with_readme "$BASE_DIR/Technical-Reference/Flows" "Flows" "system and user flow documentation"
create_dir_with_readme "$BASE_DIR/Technical-Reference/Flows/User-Flows" "User Flows" "user interaction flows"
create_dir_with_readme "$BASE_DIR/Technical-Reference/Flows/System-Flows" "System Flows" "internal system flows"
create_dir_with_readme "$BASE_DIR/Technical-Reference/Flows/Integration-Flows" "Integration Flows" "integration and sync flows"
create_dir_with_readme "$BASE_DIR/Technical-Reference/Data-Models" "Data Models" "data model documentation"
create_dir_with_readme "$BASE_DIR/Technical-Reference/Data-Models/Equipment" "Equipment" "equipment data models"
create_dir_with_readme "$BASE_DIR/Technical-Reference/Data-Models/Scoring" "Scoring" "scoring data models"
create_dir_with_readme "$BASE_DIR/Technical-Reference/Data-Models/Tournament" "Tournament" "tournament data models"
create_dir_with_readme "$BASE_DIR/Technical-Reference/Data-Models/Analytics" "Analytics" "analytics data models"
create_dir_with_readme "$BASE_DIR/Technical-Reference/Code-Examples" "Code Examples" "code examples and snippets"
create_dir_with_readme "$BASE_DIR/Technical-Reference/Code-Examples/Common-Patterns" "Common Patterns" "common coding patterns"
create_dir_with_readme "$BASE_DIR/Technical-Reference/Code-Examples/Feature-Examples" "Feature Examples" "feature implementation examples"
create_dir_with_readme "$BASE_DIR/Technical-Reference/Code-Examples/Testing-Examples" "Testing Examples" "testing code examples"
create_dir_with_readme "$BASE_DIR/Technical-Reference/Performance" "Performance" "performance guidelines and optimization"

# Architecture Decisions
create_dir_with_readme "$BASE_DIR/Architecture-Decisions" "Architecture Decisions" "architecture decision records (ADRs)"

# Project Management
create_dir_with_readme "$BASE_DIR/Project-Management" "Project Management" "project tracking and status"
create_dir_with_readme "$BASE_DIR/Project-Management/Roadmap" "Roadmap" "project roadmap and planning"
create_dir_with_readme "$BASE_DIR/Project-Management/Release-Notes" "Release Notes" "version release notes"
create_dir_with_readme "$BASE_DIR/Project-Management/Known-Issues" "Known Issues" "known issues and workarounds"
create_dir_with_readme "$BASE_DIR/Project-Management/Status" "Status" "current project status"
create_dir_with_readme "$BASE_DIR/Project-Management/Team" "Team" "team information and contacts"

# Meta
create_dir_with_readme "$BASE_DIR/Meta" "Meta" "documentation about the documentation"
create_dir_with_readme "$BASE_DIR/Meta/Templates" "Templates" "documentation templates"

# Assets
mkdir -p "$BASE_DIR/assets/images/screenshots/user-flows"
mkdir -p "$BASE_DIR/assets/images/screenshots/features"
mkdir -p "$BASE_DIR/assets/images/screenshots/ui-components"
mkdir -p "$BASE_DIR/assets/images/diagrams/architecture"
mkdir -p "$BASE_DIR/assets/images/diagrams/flows"
mkdir -p "$BASE_DIR/assets/images/diagrams/database"
mkdir -p "$BASE_DIR/assets/images/icons"
mkdir -p "$BASE_DIR/assets/images/branding"
mkdir -p "$BASE_DIR/assets/videos/tutorials"
mkdir -p "$BASE_DIR/assets/downloads/sample-data"

create_dir_with_readme "$BASE_DIR/assets" "Assets" "images, videos, and downloadable files"
create_dir_with_readme "$BASE_DIR/assets/images" "Images" "all image assets"
create_dir_with_readme "$BASE_DIR/assets/videos" "Videos" "video tutorials and demos"
create_dir_with_readme "$BASE_DIR/assets/downloads" "Downloads" "downloadable files and samples"

echo "✅ Infrastructure setup complete!"
echo "📁 Created folder structure with README files"
