# Archery Apprentice Documentation Deployment Script
# Run this after updating documentation to publish to GitHub Pages

Write-Host "?? Deploying Archery Apprentice Documentation..." -ForegroundColor Cyan

# Commit documentation changes
Write-Host "`n1??  Committing documentation updates..." -ForegroundColor Yellow
git add .
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
git commit -m "Update documentation: $timestamp"
git push origin main

# Build the site with Quartz
Write-Host "`n2??  Building site with Quartz..." -ForegroundColor Yellow
npx quartz build

# Deploy to GitHub Pages
Write-Host "`n3??  Deploying to GitHub Pages..." -ForegroundColor Yellow
cd public
git add .
git commit -m "Deploy site: $timestamp"
git push -f origin gh-pages
cd ..

Write-Host "`n? Documentation successfully deployed!" -ForegroundColor Green
Write-Host "?? Site live at: https://blamechris.github.io/archery-apprentice-docs/" -ForegroundColor Cyan
Write-Host "`n?? Deployment completed at: $timestamp" -ForegroundColor Gray
