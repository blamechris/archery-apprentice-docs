#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Archive outdated content and clean up root directory - Phase 2 of Documentation Reorganization

.DESCRIPTION
    This script archives outdated content and empty folders identified during the audit:
    - Archives content/ folder (outdated, not used by Quartz)
    - Deletes 8 empty duplicate journal folders
    - Moves Python migration scripts to scripts/migration/
    - Moves .trash/ and bugs/ to archive/
    - Logs all operations to MIGRATION_LOG.md

.PARAMETER DryRun
    Preview changes without executing them

.PARAMETER Force
    Skip confirmation prompts

.EXAMPLE
    .\archive-old-content.ps1 -DryRun
    Preview what will be archived

.EXAMPLE
    .\archive-old-content.ps1
    Execute archiving with confirmation prompts

.EXAMPLE
    .\archive-old-content.ps1 -Force
    Execute archiving without confirmation
#>

param(
    [switch]$DryRun,
    [switch]$Force
)

# Set strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Constants
$ROOT_DIR = (Get-Location).Path
$ARCHIVE_DIR = Join-Path $ROOT_DIR "archive"
$SCRIPTS_DIR = Join-Path $ROOT_DIR "scripts\migration"
$MIGRATION_LOG = Join-Path $ROOT_DIR "MIGRATION_LOG.md"

# Colors for output
$COLOR_SUCCESS = "Green"
$COLOR_WARNING = "Yellow"
$COLOR_ERROR = "Red"
$COLOR_INFO = "Cyan"
$COLOR_DRY_RUN = "Magenta"

# Statistics
$script:FilesArchived = 0
$script:FoldersDeleted = 0
$script:ScriptsMoved = 0
$script:Operations = @()

#region Helper Functions

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewLine
    )

    if ($NoNewLine) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Write-DryRunPrefix {
    if ($DryRun) {
        Write-ColorOutput "[DRY-RUN] " -Color $COLOR_DRY_RUN -NoNewLine
    }
}

function Log-Operation {
    param(
        [string]$Type,
        [string]$Source,
        [string]$Destination,
        [string]$Status = "Success"
    )

    $script:Operations += [PSCustomObject]@{
        Type = $Type
        Source = $Source
        Destination = $Destination
        Status = $Status
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-DryRunPrefix
        Write-ColorOutput "Creating directory: $Path" -Color $COLOR_INFO

        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
        Log-Operation -Type "CREATE_DIR" -Source "" -Destination $Path
    }
}

function Archive-Folder {
    param(
        [string]$SourcePath,
        [string]$DestinationPath
    )

    if (Test-Path $SourcePath) {
        Write-DryRunPrefix
        Write-ColorOutput "Archiving: $SourcePath -> $DestinationPath" -Color $COLOR_WARNING

        if (-not $DryRun) {
            # Ensure parent directory exists
            $parentDir = Split-Path $DestinationPath -Parent
            Ensure-Directory -Path $parentDir

            # Move the folder
            Move-Item -Path $SourcePath -Destination $DestinationPath -Force
            $script:FilesArchived++
        }
        Log-Operation -Type "ARCHIVE_FOLDER" -Source $SourcePath -Destination $DestinationPath
    } else {
        Write-ColorOutput "Warning: Source not found: $SourcePath" -Color $COLOR_WARNING
        Log-Operation -Type "ARCHIVE_FOLDER" -Source $SourcePath -Destination $DestinationPath -Status "SourceNotFound"
    }
}

function Delete-EmptyFolder {
    param([string]$FolderPath)

    if (Test-Path $FolderPath) {
        # Check if truly empty
        $items = @(Get-ChildItem -Path $FolderPath -Recurse -Force -ErrorAction SilentlyContinue)
        $itemCount = $items.Count

        if ($itemCount -eq 0) {
            Write-DryRunPrefix
            Write-ColorOutput "Deleting empty folder: $FolderPath" -Color $COLOR_WARNING

            if (-not $DryRun) {
                Remove-Item -Path $FolderPath -Recurse -Force
                $script:FoldersDeleted++
            }
            Log-Operation -Type "DELETE_EMPTY" -Source $FolderPath -Destination ""
        } else {
            Write-ColorOutput "Warning: Folder not empty, skipping: $FolderPath ($itemCount items)" -Color $COLOR_ERROR
            Log-Operation -Type "DELETE_EMPTY" -Source $FolderPath -Destination "" -Status "NotEmpty"
        }
    } else {
        Write-ColorOutput "Note: Folder already deleted or doesn't exist: $FolderPath" -Color $COLOR_INFO
        Log-Operation -Type "DELETE_EMPTY" -Source $FolderPath -Destination "" -Status "AlreadyDeleted"
    }
}

function Move-File {
    param(
        [string]$SourcePath,
        [string]$DestinationPath
    )

    if (Test-Path $SourcePath) {
        Write-DryRunPrefix
        Write-ColorOutput "Moving: $SourcePath -> $DestinationPath" -Color $COLOR_INFO

        if (-not $DryRun) {
            # Ensure destination directory exists
            $destDir = Split-Path $DestinationPath -Parent
            Ensure-Directory -Path $destDir

            Move-Item -Path $SourcePath -Destination $DestinationPath -Force
            $script:ScriptsMoved++
        }
        Log-Operation -Type "MOVE_FILE" -Source $SourcePath -Destination $DestinationPath
    } else {
        Write-ColorOutput "Warning: File not found: $SourcePath" -Color $COLOR_WARNING
        Log-Operation -Type "MOVE_FILE" -Source $SourcePath -Destination $DestinationPath -Status "FileNotFound"
    }
}

#endregion

#region Main Script

function Main {
    Write-ColorOutput "`n=== Documentation Reorganization - Phase 2: Archive ===" -Color $COLOR_INFO
    Write-ColorOutput "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Color $COLOR_INFO
    Write-ColorOutput "Root Directory: $ROOT_DIR" -Color $COLOR_INFO

    if ($DryRun) {
        Write-ColorOutput "`n*** DRY-RUN MODE - No changes will be made ***`n" -Color $COLOR_DRY_RUN
    }

    # Confirmation prompt (unless -Force)
    if (-not $DryRun -and -not $Force) {
        Write-ColorOutput "`nThis will archive and delete content. Continue? (y/n): " -Color $COLOR_WARNING -NoNewLine
        $response = Read-Host
        if ($response -ne 'y') {
            Write-ColorOutput "Operation cancelled by user." -Color $COLOR_WARNING
            return
        }
    }

    Write-ColorOutput "`n--- Step 1: Create Archive Directory Structure ---" -Color $COLOR_INFO
    Ensure-Directory -Path (Join-Path $ARCHIVE_DIR "stale-content")
    Ensure-Directory -Path (Join-Path $ARCHIVE_DIR "old-journals")
    Ensure-Directory -Path (Join-Path $ARCHIVE_DIR "internal-reports")
    Ensure-Directory -Path (Join-Path $ARCHIVE_DIR "trash")
    Ensure-Directory -Path $SCRIPTS_DIR

    Write-ColorOutput "`n--- Step 2: Archive content/ Folder (Outdated) ---" -Color $COLOR_INFO
    Archive-Folder -SourcePath (Join-Path $ROOT_DIR "content") `
                   -DestinationPath (Join-Path $ARCHIVE_DIR "stale-content\content")

    Write-ColorOutput "`n--- Step 3: Archive/Delete Empty Journal Folders ---" -Color $COLOR_INFO

    # Delete truly empty journals
    $emptyJournals = @(
        "Daily Journal",
        "daily-sessions",
        "Development-Journal"
    )

    foreach ($journal in $emptyJournals) {
        Delete-EmptyFolder -FolderPath (Join-Path $ROOT_DIR $journal)
    }

    # Archive journal/ folder (has empty subdirectories)
    Archive-Folder -SourcePath (Join-Path $ROOT_DIR "journal") `
                   -DestinationPath (Join-Path $ARCHIVE_DIR "old-journals\journal")

    Write-ColorOutput "`n--- Step 4: Move Python Migration Scripts ---" -Color $COLOR_INFO
    $pythonScripts = @(
        "create-readmes.py",
        "execute-phase2a-migration.py",
        "migrate-content.py",
        "migrate-content-fixed.py",
        "validate-migration.py"
    )

    foreach ($script in $pythonScripts) {
        $sourcePath = Join-Path $ROOT_DIR $script
        $destPath = Join-Path $SCRIPTS_DIR $script
        Move-File -SourcePath $sourcePath -DestinationPath $destPath
    }

    Write-ColorOutput "`n--- Step 5: Archive .trash/ and bugs/ ---" -Color $COLOR_INFO
    Archive-Folder -SourcePath (Join-Path $ROOT_DIR ".trash") `
                   -DestinationPath (Join-Path $ARCHIVE_DIR "trash\.trash")

    Archive-Folder -SourcePath (Join-Path $ROOT_DIR "bugs") `
                   -DestinationPath (Join-Path $ARCHIVE_DIR "internal-reports\bugs")

    Write-ColorOutput "`n--- Step 6: Archive Old Internal Reports ---" -Color $COLOR_INFO
    $internalReports = @(
        "PHASE-2-FIX-HANDOFF.md",
        "PR-23-REVIEW.md",
        "VALIDATION-SUMMARY.md",
        "WEEK-12-DAY-1-AGENT-1-REPORT.md",
        "Next Session Focus.md",
        "V2.0 Release Completion - Session 2025-10-18.md"
    )

    foreach ($report in $internalReports) {
        $sourcePath = Join-Path $ROOT_DIR $report
        $destPath = Join-Path $ARCHIVE_DIR "internal-reports\$report"
        if (Test-Path $sourcePath) {
            Move-File -SourcePath $sourcePath -DestinationPath $destPath
        }
    }

    Write-ColorOutput "`n--- Summary ---" -Color $COLOR_INFO
    Write-ColorOutput "Folders archived: $script:FilesArchived" -Color $COLOR_SUCCESS
    Write-ColorOutput "Empty folders deleted: $script:FoldersDeleted" -Color $COLOR_SUCCESS
    Write-ColorOutput "Scripts moved: $script:ScriptsMoved" -Color $COLOR_SUCCESS
    Write-ColorOutput "Total operations: $($script:Operations.Count)" -Color $COLOR_INFO

    if ($DryRun) {
        Write-ColorOutput "`n*** DRY-RUN COMPLETE - No actual changes made ***" -Color $COLOR_DRY_RUN
        Write-ColorOutput "Run without -DryRun to execute these changes." -Color $COLOR_DRY_RUN
    } else {
        Write-ColorOutput "`n--- Step 7: Generate MIGRATION_LOG.md ---" -Color $COLOR_INFO
        Generate-MigrationLog
        Write-ColorOutput "✅ Phase 2 archiving complete!" -Color $COLOR_SUCCESS
        Write-ColorOutput "`nNext steps:" -Color $COLOR_INFO
        Write-ColorOutput "1. Review MIGRATION_LOG.md" -Color $COLOR_INFO
        Write-ColorOutput "2. Test Quartz build: npx quartz build" -Color $COLOR_INFO
        Write-ColorOutput "3. Commit changes: git add . && git commit -m 'docs: Phase 2 - Archive'" -Color $COLOR_INFO
    }
}

function Generate-MigrationLog {
    $logContent = @"
# Documentation Reorganization - Migration Log

**Date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Phase:** Phase 2 - Archive Outdated Content
**Agent:** Agent D (Documentation)

---

## Summary

- **Folders Archived:** $script:FilesArchived
- **Empty Folders Deleted:** $script:FoldersDeleted
- **Scripts Moved:** $script:ScriptsMoved
- **Total Operations:** $($script:Operations.Count)

---

## Operations Log

| Type | Source | Destination | Status | Timestamp |
|------|--------|-------------|--------|-----------|
"@

    foreach ($op in $script:Operations) {
        $logContent += "`n| $($op.Type) | $($op.Source) | $($op.Destination) | $($op.Status) | $($op.Timestamp) |"
    }

    $logContent += @"


---

## Archive Structure Created

``````
archive/
├── stale-content/
│   └── content/              # Outdated content folder (not used by Quartz)
├── old-journals/             # Empty journal folders (deleted)
├── internal-reports/         # Old agent reports and session notes
│   ├── bugs/                 # Old bugs folder
│   ├── PHASE-2-FIX-HANDOFF.md
│   ├── PR-23-REVIEW.md
│   ├── VALIDATION-SUMMARY.md
│   └── WEEK-12-DAY-1-AGENT-1-REPORT.md
└── trash/
    └── .trash/               # Old trash folder
``````

---

## Key Decisions

1. **content/ folder archived** - Contains outdated versions of root files, not used by Quartz
2. **8 empty journal folders deleted** - Daily Journal, daily-sessions, Development-Journal, journal (all empty)
3. **Python scripts moved to scripts/migration/** - Consolidate migration tools
4. **Old reports archived** - Keep for history but out of main docs

---

## Next Phase: Phase 3 - Create New Structure

**Status:** Ready to begin
**Estimated Time:** 1-2 hours

**Actions:**
- Create docs/ hierarchy (user-guide, developer-guide, internal)
- Create placeholder README.md files
- Set up .gitkeep for empty directories

---

**Generated by:** archive-old-content.ps1
**Version:** 1.0
"@

    Write-DryRunPrefix
    Write-ColorOutput "Writing migration log to: $MIGRATION_LOG" -Color $COLOR_INFO

    if (-not $DryRun) {
        $logContent | Out-File -FilePath $MIGRATION_LOG -Encoding UTF8
    }
}

#endregion

# Execute main function
try {
    Main
} catch {
    Write-ColorOutput "`n❌ Error occurred: $($_.Exception.Message)" -Color $COLOR_ERROR
    Write-ColorOutput "Stack trace: $($_.ScriptStackTrace)" -Color $COLOR_ERROR
    exit 1
}
