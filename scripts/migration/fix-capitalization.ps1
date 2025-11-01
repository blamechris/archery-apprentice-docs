# Fix Capitalization Issues
# Renames files to follow Title-Case-With-Hyphens.md standard

param(
    [switch]$DryRun = $false
)

$ROOT_DIR = "C:\Users\chris_3zal3ta\Documents\ArcheryApprentice-Docs"
$LOG_FILE = Join-Path $ROOT_DIR "CAPITALIZATION_LOG.md"

# Files that MUST be renamed (spaces → hyphens, lowercase start → Title Case)
$renames = @(
    # Files with spaces
    @{
        Old = "content/developer-guide/ci-cd/Hybrid Runner Implementation Guide.md"
        New = "content/developer-guide/ci-cd/Hybrid-Runner-Implementation-Guide.md"
    },
    @{
        Old = "content/developer-guide/guides/Firebase Auth State Loss Across Coroutines.md"
        New = "content/developer-guide/guides/Firebase-Auth-State-Loss-Across-Coroutines.md"
    },
    @{
        Old = "content/developer-guide/guides/Migration Testing - Unit Tests vs Instrumented Tests.md"
        New = "content/developer-guide/guides/Migration-Testing-Unit-Tests-Vs-Instrumented-Tests.md"
    },
    @{
        Old = "content/developer-guide/guides/Multi-Participant Ranking and Tie-Breaking.md"
        New = "content/developer-guide/guides/Multi-Participant-Ranking-And-Tie-Breaking.md"
    },
    @{
        Old = "content/developer-guide/guides/best-practices/Build Quality Patterns and Test Best Practices.md"
        New = "content/developer-guide/guides/best-practices/Build-Quality-Patterns-And-Test-Best-Practices.md"
    },
    @{
        Old = "content/internal/development-patterns/Migration Testing - Unit Tests vs Instrumented Tests.md"
        New = "content/internal/development-patterns/Migration-Testing-Unit-Tests-Vs-Instrumented-Tests.md"
    },
    @{
        Old = "content/internal/experiments/Agentic LLM Workflow Experiment.md"
        New = "content/internal/experiments/Agentic-LLM-Workflow-Experiment.md"
    },
    @{
        Old = "content/internal/kmp-migration/KMP Migration Project.md"
        New = "content/internal/kmp-migration/KMP-Migration-Project.md"
    },
    @{
        Old = "content/internal/kmp-migration/Week 2 Completion - KMP Migration.md"
        New = "content/internal/kmp-migration/Week-2-Completion-KMP-Migration.md"
    },
    @{
        Old = "content/internal/kmp-migration/kmp-migration/Week 2 Final Completion.md"
        New = "content/internal/kmp-migration/kmp-migration/Week-2-Final-Completion.md"
    },
    @{
        Old = "content/internal/kmp-migration/kmp-migration/Week 5 Service Migration.md"
        New = "content/internal/kmp-migration/kmp-migration/Week-5-Service-Migration.md"
    },
    @{
        Old = "content/internal/kmp-migration/kmp-migration/Week 5-8 Overall Status.md"
        New = "content/internal/kmp-migration/kmp-migration/Week-5-8-Overall-Status.md"
    },
    @{
        Old = "content/internal/kmp-migration/kmp-migration/Week 6-7 Database Planning.md"
        New = "content/internal/kmp-migration/kmp-migration/Week-6-7-Database-Planning.md"
    },
    @{
        Old = "content/internal/kmp-migration/kmp-migration/Week 7-8 Pattern 3 Implementation.md"
        New = "content/internal/kmp-migration/kmp-migration/Week-7-8-Pattern-3-Implementation.md"
    },
    @{
        Old = "content/internal/kmp-migration/kmp-migration/Week 7-8 Test Coverage.md"
        New = "content/internal/kmp-migration/kmp-migration/Week-7-8-Test-Coverage.md"
    },
    @{
        Old = "content/internal/kmp-migration/kmp-migration/Architecture/KMP Data Layer Architecture.md"
        New = "content/internal/kmp-migration/kmp-migration/Architecture/KMP-Data-Layer-Architecture.md"
    },
    @{
        Old = "content/internal/kmp-migration/kmp-migration/Architecture/Repository Migration Strategy.md"
        New = "content/internal/kmp-migration/kmp-migration/Architecture/Repository-Migration-Strategy.md"
    },
    @{
        Old = "content/internal/kmp-migration/kmp-migration/Architecture/Room KMP Architecture.md"
        New = "content/internal/kmp-migration/kmp-migration/Architecture/Room-KMP-Architecture.md"
    },
    @{
        Old = "content/internal/kmp-migration/kmp-migration/Project Management/KMP Migration Progress.md"
        New = "content/internal/kmp-migration/kmp-migration/Project-Management/KMP-Migration-Progress.md"
    },
    @{
        Old = "content/internal/sessions/Tournament Settings and Display Names Fix.md"
        New = "content/internal/sessions/Tournament-Settings-And-Display-Names-Fix.md"
    },
    @{
        Old = "content/internal/technical-notes/Firebase Auth State Loss Across Coroutines.md"
        New = "content/internal/technical-notes/Firebase-Auth-State-Loss-Across-Coroutines.md"
    },
    @{
        Old = "content/internal/technical-notes/Multi-Participant Ranking and Tie-Breaking.md"
        New = "content/internal/technical-notes/Multi-Participant-Ranking-And-Tie-Breaking.md"
    },
    # Files starting with lowercase
    @{
        Old = "content/developer-guide/architecture/expect-actual-Pattern.md"
        New = "content/developer-guide/architecture/Expect-Actual-Pattern.md"
    },
    @{
        Old = "content/developer-guide/architecture/room-database-entity-mapping.md"
        New = "content/developer-guide/architecture/Room-Database-Entity-Mapping.md"
    },
    @{
        Old = "content/developer-guide/architecture/settings-architecture.md"
        New = "content/developer-guide/architecture/Settings-Architecture.md"
    }
)

if ($DryRun) {
    Write-Host "DRY RUN MODE - No files will be renamed" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Renaming $($renames.Count) files to fix capitalization..." -ForegroundColor Cyan
Write-Host ""

$renamed = 0
$failed = 0

foreach ($rename in $renames) {
    $oldPath = Join-Path $ROOT_DIR $rename.Old
    $newPath = Join-Path $ROOT_DIR $rename.New

    if (-not (Test-Path $oldPath)) {
        Write-Host "⚠️  SKIP: File not found - $($rename.Old)" -ForegroundColor Yellow
        continue
    }

    # Check if this is just a case change (Windows case-insensitive filesystem)
    $isCaseChangeOnly = $oldPath.ToLower() -eq $newPath.ToLower()

    if ((Test-Path $newPath) -and -not $isCaseChangeOnly) {
        Write-Host "⚠️  SKIP: Destination exists - $($rename.New)" -ForegroundColor Yellow
        continue
    }

    if ($DryRun) {
        Write-Host "[DRY RUN] Would rename:" -ForegroundColor Cyan
        Write-Host "  FROM: $($rename.Old)" -ForegroundColor Gray
        Write-Host "  TO:   $($rename.New)" -ForegroundColor Gray
        $renamed++
    } else {
        try {
            # Use git mv to preserve history
            $gitOld = $rename.Old -replace '\\', '/'
            $gitNew = $rename.New -replace '\\', '/'

            if ($isCaseChangeOnly) {
                # Windows case-insensitive rename: use temp file
                $tempName = $gitNew + ".tmp"
                git mv "$gitOld" "$tempName" 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    git mv "$tempName" "$gitNew" 2>&1 | Out-Null
                }
            } else {
                git mv "$gitOld" "$gitNew" 2>&1 | Out-Null
            }

            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Renamed: $($rename.Old) → $(Split-Path $rename.New -Leaf)" -ForegroundColor Green
                $renamed++
            } else {
                Write-Host "❌ FAILED: $($rename.Old)" -ForegroundColor Red
                $failed++
            }
        } catch {
            Write-Host "❌ ERROR: $($rename.Old) - $($_.Exception.Message)" -ForegroundColor Red
            $failed++
        }
    }
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Renamed: $renamed" -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host "  Failed: $failed" -ForegroundColor Red
}

if (-not $DryRun -and $renamed -gt 0) {
    # Create log file
    $logContent = @"
# Capitalization Fix Log

**Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Files Renamed:** $renamed
**Files Failed:** $failed

---

## Renames Performed

$(foreach ($rename in $renames) {
    if (Test-Path (Join-Path $ROOT_DIR $rename.New)) {
        "- ✅ ``$($rename.Old)`` → ``$($rename.New)``"
    }
})

---

## Capitalization Standard

**File Naming Convention:** Title-Case-With-Hyphens.md

**Rules:**
1. Each word starts with a capital letter
2. Words are separated by hyphens (-)
3. No spaces in file names
4. Exceptions: README.md, index.md

**Examples:**
- ✅ Firebase-Auth-State-Loss.md
- ✅ KMP-Migration-Project.md
- ✅ Multi-Participant-Ranking.md
- ❌ Firebase Auth State Loss.md (spaces)
- ❌ kmp-migration-project.md (lowercase start)
- ❌ multiParticipantRanking.md (camelCase)

---

**Generated by:** fix-capitalization.ps1
"@

    $logContent | Out-File -FilePath $LOG_FILE -Encoding UTF8
    Write-Host ""
    Write-Host "Log created: CAPITALIZATION_LOG.md" -ForegroundColor Green
}
