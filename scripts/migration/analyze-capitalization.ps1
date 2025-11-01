# Capitalization Analysis Script
# Identifies files that don't follow Title-Case-With-Hyphens.md standard

$ROOT_DIR = "C:\Users\chris_3zal3ta\Documents\ArcheryApprentice-Docs"
$CONTENT_DIR = Join-Path $ROOT_DIR "content"

Write-Host "Analyzing file capitalization in $CONTENT_DIR..." -ForegroundColor Cyan
Write-Host ""

# Standard: Title-Case-With-Hyphens.md (except README.md and index.md)
# Exceptions: README.md, index.md (always this exact case)

$issues = @()

Get-ChildItem -Path $CONTENT_DIR -Recurse -Filter "*.md" | ForEach-Object {
    $fileName = $_.Name
    $relativePath = $_.FullName.Replace("$ROOT_DIR\", "")

    # Skip exceptions
    if ($fileName -eq "README.md" -or $fileName -eq "index.md") {
        return
    }

    # Check for issues:
    # 1. Contains spaces (should use hyphens)
    # 2. All lowercase (should be Title Case)
    # 3. Mixed case inconsistencies

    $hasSpaces = $fileName -match " "
    $isAllLowercase = $fileName -match "^[a-z0-9\-\.]+$"
    $hasInconsistentCase = $false

    # Check if it follows Title-Case-With-Hyphens pattern
    # Pattern: Each word starts with capital, words separated by hyphens
    # Example: Firebase-Integration-Plan.md, System-Architecture.md

    if ($hasSpaces) {
        $issues += [PSCustomObject]@{
            File = $relativePath
            Issue = "Contains spaces (should use hyphens)"
            Suggestion = $fileName -replace " ", "-"
        }
    }
    elseif ($isAllLowercase -and $fileName -ne "README.md" -and $fileName -ne "index.md") {
        # Convert to Title Case
        $words = $fileName -replace "\.md$", "" -split "-"
        $titleCase = ($words | ForEach-Object {
            $_.Substring(0,1).ToUpper() + $_.Substring(1)
        }) -join "-"
        $suggestion = "$titleCase.md"

        $issues += [PSCustomObject]@{
            File = $relativePath
            Issue = "All lowercase (should be Title Case)"
            Suggestion = $suggestion
        }
    }
}

Write-Host "Found $($issues.Count) files with capitalization issues:" -ForegroundColor Yellow
Write-Host ""

$issues | Format-Table -AutoSize

# Export to CSV for review
$csvPath = Join-Path $ROOT_DIR "capitalization-issues.csv"
$issues | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host "Exported to: $csvPath" -ForegroundColor Green
