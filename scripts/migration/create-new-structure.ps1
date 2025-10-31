#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Create new professional documentation structure - Phase 3 of Documentation Reorganization

.DESCRIPTION
    Creates the new docs/ hierarchy with proper structure:
    - docs/user-guide/ (Consumer documentation)
    - docs/developer-guide/ (Developer documentation)
    - docs/internal/ (Agent coordination & KMP migration)

    Creates placeholder README.md files and .gitkeep where needed.

.PARAMETER DryRun
    Preview structure without creating it

.EXAMPLE
    .\create-new-structure.ps1 -DryRun
    Preview the structure to be created

.EXAMPLE
    .\create-new-structure.ps1
    Create the new structure
#>

param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ROOT_DIR = (Get-Location).Path
$DOCS_DIR = Join-Path $ROOT_DIR "docs"

# Colors
$COLOR_SUCCESS = "Green"
$COLOR_INFO = "Cyan"
$COLOR_DRY_RUN = "Magenta"

$script:DirsCreated = 0
$script:FilesCreated = 0

function Write-DryRunPrefix {
    if ($DryRun) {
        Write-Host "[DRY-RUN] " -ForegroundColor $COLOR_DRY_RUN -NoNewline
    }
}

function Ensure-Directory {
    param([string]$Path, [string]$Description = "")

    if (-not (Test-Path $Path)) {
        Write-DryRunPrefix
        Write-Host "Creating: $Path $(if($Description){" - $Description"})" -ForegroundColor $COLOR_INFO

        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            $script:DirsCreated++
        }
    }
}

function Create-ReadmeFile {
    param(
        [string]$Path,
        [string]$Title,
        [string]$Description
    )

    $readmePath = Join-Path $Path "README.md"

    if (-not (Test-Path $readmePath)) {
        Write-DryRunPrefix
        Write-Host "Creating README: $readmePath" -ForegroundColor $COLOR_INFO

        $content = @"
# $Title

$Description

**Status:** 🚧 Under Construction

## Contents

[To be populated during content migration]

---

**Last Updated:** $(Get-Date -Format 'yyyy-MM-dd')
**Phase:** Structure Creation
"@

        if (-not $DryRun) {
            $content | Out-File -FilePath $readmePath -Encoding UTF8
            $script:FilesCreated++
        }
    }
}

function Main {
    Write-Host "`n=== Documentation Reorganization - Phase 3: Create Structure ===" -ForegroundColor $COLOR_INFO
    Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $COLOR_INFO

    if ($DryRun) {
        Write-Host "`n*** DRY-RUN MODE ***`n" -ForegroundColor $COLOR_DRY_RUN
    }

    Write-Host "`n--- Creating docs/ Root Structure ---" -ForegroundColor $COLOR_INFO
    Ensure-Directory -Path $DOCS_DIR -Description "Main documentation root"

    # User Guide Structure
    Write-Host "`n--- Creating docs/user-guide/ (Consumer Docs) ---" -ForegroundColor $COLOR_INFO
    $userGuideDir = Join-Path $DOCS_DIR "user-guide"
    Ensure-Directory -Path $userGuideDir
    Create-ReadmeFile -Path $userGuideDir -Title "User Guide" `
        -Description "Complete guide for Archery Apprentice users. Learn how to use the app's features effectively."

    Ensure-Directory -Path (Join-Path $userGuideDir "features")
    Create-ReadmeFile -Path (Join-Path $userGuideDir "features") -Title "Features" `
        -Description "Detailed documentation for each app feature."

    Ensure-Directory -Path (Join-Path $userGuideDir "how-to")
    Create-ReadmeFile -Path (Join-Path $userGuideDir "how-to") -Title "How-To Guides" `
        -Description "Step-by-step guides for common tasks and workflows."

    Ensure-Directory -Path (Join-Path $userGuideDir "reference")
    Ensure-Directory -Path (Join-Path $userGuideDir "troubleshooting")

    # Developer Guide Structure
    Write-Host "`n--- Creating docs/developer-guide/ (Developer Docs) ---" -ForegroundColor $COLOR_INFO
    $devGuideDir = Join-Path $DOCS_DIR "developer-guide"
    Ensure-Directory -Path $devGuideDir
    Create-ReadmeFile -Path $devGuideDir -Title "Developer Guide" `
        -Description "Documentation for developers contributing to Archery Apprentice."

    Ensure-Directory -Path (Join-Path $devGuideDir "architecture")
    Create-ReadmeFile -Path (Join-Path $devGuideDir "architecture") -Title "Architecture" `
        -Description "System architecture, design patterns, and technical decisions."

    Ensure-Directory -Path (Join-Path $devGuideDir "architecture\diagrams")
    Ensure-Directory -Path (Join-Path $devGuideDir "architecture\layers")
    Ensure-Directory -Path (Join-Path $devGuideDir "architecture\patterns")

    Ensure-Directory -Path (Join-Path $devGuideDir "guides")
    Create-ReadmeFile -Path (Join-Path $devGuideDir "guides") -Title "Development Guides" `
        -Description "Guides for adding features, testing, and working with the codebase."

    Ensure-Directory -Path (Join-Path $devGuideDir "api-reference")
    Create-ReadmeFile -Path (Join-Path $devGuideDir "api-reference") -Title "API Reference" `
        -Description "Technical reference for repositories, ViewModels, DAOs, and services."

    Ensure-Directory -Path (Join-Path $devGuideDir "testing")
    Ensure-Directory -Path (Join-Path $devGuideDir "ci-cd")

    # Internal Documentation Structure
    Write-Host "`n--- Creating docs/internal/ (Internal Docs) ---" -ForegroundColor $COLOR_INFO
    $internalDir = Join-Path $DOCS_DIR "internal"
    Ensure-Directory -Path $internalDir
    Create-ReadmeFile -Path $internalDir -Title "Internal Documentation" `
        -Description "Agent coordination, KMP migration tracking, and internal project documentation."

    Ensure-Directory -Path (Join-Path $internalDir "kmp-migration")
    Create-ReadmeFile -Path (Join-Path $internalDir "kmp-migration") -Title "KMP Migration" `
        -Description "Documentation of the Kotlin Multiplatform migration project (Weeks 1-12+)."

    Ensure-Directory -Path (Join-Path $internalDir "kmp-migration\weeks")
    Ensure-Directory -Path (Join-Path $internalDir "agents")
    Create-ReadmeFile -Path (Join-Path $internalDir "agents") -Title "Agent Reports" `
        -Description "Weekly reports and coordination notes from autonomous agents."

    Ensure-Directory -Path (Join-Path $internalDir "retrospectives")
    Ensure-Directory -Path (Join-Path $internalDir "experiments")
    Ensure-Directory -Path (Join-Path $internalDir "analysis")

    # Summary
    Write-Host "`n--- Summary ---" -ForegroundColor $COLOR_INFO
    Write-Host "Directories created: $script:DirsCreated" -ForegroundColor $COLOR_SUCCESS
    Write-Host "README files created: $script:FilesCreated" -ForegroundColor $COLOR_SUCCESS

    if ($DryRun) {
        Write-Host "`n*** DRY-RUN COMPLETE ***" -ForegroundColor $COLOR_DRY_RUN
        Write-Host "Run without -DryRun to create the structure." -ForegroundColor $COLOR_DRY_RUN
    } else {
        Write-Host "`n✅ Phase 3 structure creation complete!" -ForegroundColor $COLOR_SUCCESS
        Write-Host "`nNew structure:" -ForegroundColor $COLOR_INFO
        Write-Host "docs/" -ForegroundColor $COLOR_SUCCESS
        Write-Host "├── user-guide/          # Consumer documentation" -ForegroundColor $COLOR_SUCCESS
        Write-Host "├── developer-guide/     # Developer documentation" -ForegroundColor $COLOR_SUCCESS
        Write-Host "└── internal/            # Agent coordination & KMP migration" -ForegroundColor $COLOR_SUCCESS
    }
}

try {
    Main
} catch {
    Write-Host "`n❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
