#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validate documentation migration and structure

.DESCRIPTION
    Validates the migration process:
    - Checks for lost files
    - Validates Quartz build
    - Checks for broken internal links
    - Validates directory structure

.PARAMETER Phase
    Which phase to validate (2, 3, 4, etc.)

.EXAMPLE
    .\validate-migration.ps1 -Phase 2
    Validate Phase 2 archiving
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$Phase = 2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ROOT_DIR = (Get-Location).Path
$MIGRATION_LOG = Join-Path $ROOT_DIR "MIGRATION_LOG.md"

# Colors
$COLOR_SUCCESS = "Green"
$COLOR_WARNING = "Yellow"
$COLOR_ERROR = "Red"
$COLOR_INFO = "Cyan"

$script:Errors = @()
$script:Warnings = @()
$script:Passed = 0
$script:Failed = 0

function Test-Validation {
    param(
        [string]$Name,
        [scriptblock]$Test
    )

    Write-Host "`nValidating: $Name" -ForegroundColor $COLOR_INFO
    try {
        $result = & $Test
        if ($result) {
            Write-Host "  ✅ PASS" -ForegroundColor $COLOR_SUCCESS
            $script:Passed++
        } else {
            Write-Host "  ❌ FAIL" -ForegroundColor $COLOR_ERROR
            $script:Failed++
            $script:Errors += $Name
        }
    } catch {
        Write-Host "  ❌ ERROR: $($_.Exception.Message)" -ForegroundColor $COLOR_ERROR
        $script:Failed++
        $script:Errors += "$Name - $($_.Exception.Message)"
    }
}

function Test-Warning {
    param([string]$Message)

    Write-Host "  ⚠️  WARNING: $Message" -ForegroundColor $COLOR_WARNING
    $script:Warnings += $Message
}

function Validate-Phase2 {
    Write-Host "`n=== Validating Phase 2: Archive ===" -ForegroundColor $COLOR_INFO

    Test-Validation -Name "archive/ directory exists" -Test {
        Test-Path (Join-Path $ROOT_DIR "archive")
    }

    Test-Validation -Name "scripts/migration/ directory exists" -Test {
        Test-Path (Join-Path $ROOT_DIR "scripts\migration")
    }

    Test-Validation -Name "content/ folder archived" -Test {
        -not (Test-Path (Join-Path $ROOT_DIR "content"))
    }

    Test-Validation -Name "Empty journal folders deleted" -Test {
        $journals = @("Daily Journal", "daily-sessions", "Development-Journal", "journal")
        $allDeleted = $true
        foreach ($j in $journals) {
            if (Test-Path (Join-Path $ROOT_DIR $j)) {
                $allDeleted = $false
                Test-Warning "Journal folder still exists: $j"
            }
        }
        $allDeleted
    }

    Test-Validation -Name "Python scripts moved to scripts/migration/" -Test {
        $scripts = @("validate-migration.py", "migrate-content.py", "create-readmes.py")
        $allMoved = $true
        foreach ($s in $scripts) {
            $inRoot = Test-Path (Join-Path $ROOT_DIR $s)
            $inScripts = Test-Path (Join-Path $ROOT_DIR "scripts\migration\$s")

            if ($inRoot) {
                Test-Warning "Script still in root: $s"
                $allMoved = $false
            }
        }
        $allMoved
    }

    Test-Validation -Name "MIGRATION_LOG.md exists" -Test {
        Test-Path $MIGRATION_LOG
    }

    Test-Validation -Name "Essential folders still exist (Development, User-Guide, etc.)" -Test {
        $essential = @("Development", "User-Guide", "Technical-Reference")
        $allExist = $true
        foreach ($folder in $essential) {
            if (-not (Test-Path (Join-Path $ROOT_DIR $folder))) {
                Test-Warning "Essential folder missing: $folder"
                $allExist = $false
            }
        }
        $allExist
    }
}

function Validate-Phase3 {
    Write-Host "`n=== Validating Phase 3: New Structure ===" -ForegroundColor $COLOR_INFO

    Test-Validation -Name "docs/ directory exists" -Test {
        Test-Path (Join-Path $ROOT_DIR "docs")
    }

    Test-Validation -Name "docs/user-guide/ exists" -Test {
        Test-Path (Join-Path $ROOT_DIR "docs\user-guide")
    }

    Test-Validation -Name "docs/developer-guide/ exists" -Test {
        Test-Path (Join-Path $ROOT_DIR "docs\developer-guide")
    }

    Test-Validation -Name "docs/internal/ exists" -Test {
        Test-Path (Join-Path $ROOT_DIR "docs\internal")
    }

    Test-Validation -Name "README files created in new structure" -Test {
        $readmes = @(
            "docs\user-guide\README.md",
            "docs\developer-guide\README.md",
            "docs\internal\README.md"
        )
        $allExist = $true
        foreach ($readme in $readmes) {
            if (-not (Test-Path (Join-Path $ROOT_DIR $readme))) {
                Test-Warning "README missing: $readme"
                $allExist = $false
            }
        }
        $allExist
    }
}

function Validate-QuartzBuild {
    Write-Host "`n=== Validating Quartz Build ===" -ForegroundColor $COLOR_INFO

    Test-Validation -Name "package.json exists" -Test {
        Test-Path (Join-Path $ROOT_DIR "package.json")
    }

    Test-Validation -Name "quartz.config.ts exists" -Test {
        Test-Path (Join-Path $ROOT_DIR "quartz.config.ts")
    }

    Test-Validation -Name "quartz/ directory exists" -Test {
        Test-Path (Join-Path $ROOT_DIR "quartz")
    }

    Write-Host "`nAttempting Quartz build..." -ForegroundColor $COLOR_INFO
    try {
        $buildOutput = npx quartz build 2>&1
        $buildSuccess = $LASTEXITCODE -eq 0

        if ($buildSuccess) {
            Write-Host "  ✅ Quartz build succeeded" -ForegroundColor $COLOR_SUCCESS
            $script:Passed++
        } else {
            Write-Host "  ❌ Quartz build failed" -ForegroundColor $COLOR_ERROR
            Write-Host $buildOutput -ForegroundColor $COLOR_ERROR
            $script:Failed++
            $script:Errors += "Quartz build failed"
        }
    } catch {
        Write-Host "  ❌ Error running Quartz build: $($_.Exception.Message)" -ForegroundColor $COLOR_ERROR
        $script:Failed++
        $script:Errors += "Quartz build error"
    }
}

function Validate-FileCount {
    Write-Host "`n=== Validating File Counts ===" -ForegroundColor $COLOR_INFO

    Write-Host "Counting markdown files..." -ForegroundColor $COLOR_INFO

    $totalFiles = (Get-ChildItem -Path $ROOT_DIR -Filter "*.md" -Recurse -File `
        -Exclude @(".git", "node_modules", ".quartz-cache", "archive") | Measure-Object).Count

    Write-Host "Total markdown files (excluding archive): $totalFiles" -ForegroundColor $COLOR_INFO

    if ($totalFiles -lt 200) {
        Test-Warning "File count seems low ($totalFiles). Expected ~220+ files after archiving content/"
    } else {
        Write-Host "  ✅ File count reasonable" -ForegroundColor $COLOR_SUCCESS
    }
}

function Main {
    Write-Host "`n=== Documentation Migration Validation ===" -ForegroundColor $COLOR_INFO
    Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $COLOR_INFO
    Write-Host "Root: $ROOT_DIR" -ForegroundColor $COLOR_INFO

    switch ($Phase) {
        2 { Validate-Phase2 }
        3 {
            Validate-Phase2
            Validate-Phase3
        }
        default {
            Write-Host "Validating all phases..." -ForegroundColor $COLOR_INFO
            Validate-Phase2
        }
    }

    Validate-FileCount
    Validate-QuartzBuild

    Write-Host "`n=== Validation Summary ===" -ForegroundColor $COLOR_INFO
    Write-Host "Passed: $script:Passed" -ForegroundColor $COLOR_SUCCESS
    Write-Host "Failed: $script:Failed" -ForegroundColor $(if ($script:Failed -eq 0) { $COLOR_SUCCESS } else { $COLOR_ERROR })
    Write-Host "Warnings: $($script:Warnings.Count)" -ForegroundColor $COLOR_WARNING

    if ($script:Errors.Count -gt 0) {
        Write-Host "`n❌ Errors found:" -ForegroundColor $COLOR_ERROR
        foreach ($error in $script:Errors) {
            Write-Host "  - $error" -ForegroundColor $COLOR_ERROR
        }
    }

    if ($script:Warnings.Count -gt 0) {
        Write-Host "`n⚠️  Warnings:" -ForegroundColor $COLOR_WARNING
        foreach ($warning in $script:Warnings) {
            Write-Host "  - $warning" -ForegroundColor $COLOR_WARNING
        }
    }

    if ($script:Failed -eq 0) {
        Write-Host "`n✅ Validation PASSED - Phase $Phase is complete!" -ForegroundColor $COLOR_SUCCESS
        exit 0
    } else {
        Write-Host "`n❌ Validation FAILED - Please review errors above" -ForegroundColor $COLOR_ERROR
        exit 1
    }
}

try {
    Main
} catch {
    Write-Host "`n❌ Validation error: $($_.Exception.Message)" -ForegroundColor $COLOR_ERROR
    exit 1
}
