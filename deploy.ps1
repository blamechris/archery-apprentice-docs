# Archery Apprentice Documentation Deployment Script
# Run this after updating documentation to publish to GitHub Pages

param(
    [switch]$Force,
    [switch]$SkipBuild
)

Write-Host "📚 Deploying Archery Apprentice Documentation..." -ForegroundColor Cyan

# Safety Check 1: Verify we're in the right directory
$expectedPath = "C:\Users\chris_3zal3ta\Documents\ArcheryApprentice-Docs"
if ((Get-Location).Path -ne $expectedPath) {
    Write-Host "❌ ERROR: Must run from vault directory" -ForegroundColor Red
    Write-Host "   Current: $((Get-Location).Path)" -ForegroundColor Yellow
    Write-Host "   Expected: $expectedPath" -ForegroundColor Yellow
    exit 1
}

# Safety Check 2: Verify git status
$gitStatus = git status --porcelain
if ($gitStatus -and -not $Force) {
    Write-Host "`n⚠️  WARNING: Uncommitted changes detected:" -ForegroundColor Yellow
    git status --short
    Write-Host "`nYou have uncommitted changes. Options:" -ForegroundColor Yellow
    Write-Host "  1. Review changes above and commit them first" -ForegroundColor Cyan
    Write-Host "  2. Run with -Force to deploy anyway (not recommended)" -ForegroundColor Cyan
    Write-Host "  3. Cancel and commit changes manually (recommended)" -ForegroundColor Green

    $response = Read-Host "`nProceed anyway? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "❌ Deployment cancelled" -ForegroundColor Red
        exit 0
    }
}

# Safety Check 3: Verify on main branch
$currentBranch = git rev-parse --abbrev-ref HEAD
if ($currentBranch -ne 'main') {
    Write-Host "`n⚠️  WARNING: Not on 'main' branch (current: $currentBranch)" -ForegroundColor Yellow
    if (-not $Force) {
        $response = Read-Host "Deploy from '$currentBranch' branch anyway? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Host "❌ Deployment cancelled. Switch to main: git checkout main" -ForegroundColor Red
            exit 0
        }
    }
}

# Safety Check 4: Verify Quartz is installed
if (-not (Test-Path "node_modules")) {
    Write-Host "`n⚠️  WARNING: node_modules not found. Installing dependencies..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
}

# Display what will be committed
if ($gitStatus) {
    Write-Host "`n📝 Files to be committed:" -ForegroundColor Cyan
    git status --short
}

# Commit documentation changes
Write-Host "`n1️⃣  Committing documentation updates..." -ForegroundColor Yellow
git add .
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
git commit -m "docs: Update documentation ($timestamp)" --quiet

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Changes committed" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  No changes to commit" -ForegroundColor Gray
}

Write-Host "`n   Pushing to origin/main..." -ForegroundColor Yellow
git push origin main --quiet

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Pushed to remote" -ForegroundColor Green
} else {
    Write-Host "   ❌ Failed to push. Check network connection." -ForegroundColor Red
    exit 1
}

# Build the site with Quartz
if (-not $SkipBuild) {
    Write-Host "`n2️⃣  Building site with Quartz..." -ForegroundColor Yellow
    npx quartz build --quiet

    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Build completed" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Build failed. Check for markdown syntax errors." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`n2️⃣  Skipping build (--SkipBuild flag)" -ForegroundColor Gray
}

# Deploy to GitHub Pages
Write-Host "`n3️⃣  Deploying to GitHub Pages..." -ForegroundColor Yellow

if (-not (Test-Path "public")) {
    Write-Host "   ❌ public/ directory not found. Build failed?" -ForegroundColor Red
    exit 1
}

Push-Location public

git add .
git commit -m "deploy: Site deployment ($timestamp)" --quiet

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Deployment committed" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  No deployment changes" -ForegroundColor Gray
}

git push -f origin gh-pages --quiet

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Deployed to gh-pages" -ForegroundColor Green
} else {
    Write-Host "   ❌ Deployment push failed" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location

# Success summary
Write-Host "`n✨ Documentation successfully deployed!" -ForegroundColor Green
Write-Host "🌐 Site live at: https://blamechris.github.io/archery-apprentice-docs/" -ForegroundColor Cyan
Write-Host "`n📅 Deployment completed at: $timestamp" -ForegroundColor Gray
Write-Host "⏱️  Changes may take 1-2 minutes to appear on live site" -ForegroundColor Gray

# Optional: Open browser to verify
$response = Read-Host "`nOpen site in browser to verify? (Y/n)"
if ($response -ne 'n' -and $response -ne 'N') {
    Start-Process "https://blamechris.github.io/archery-apprentice-docs/"
}
