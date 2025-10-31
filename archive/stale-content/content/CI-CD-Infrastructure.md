---
title: CI/CD Infrastructure - Self-Hosted Runners
---

# CI/CD Infrastructure - Self-Hosted Runners

**Date Created:** 2025-10-27
**Last Updated:** 2025-10-27
**Status:** #production-ready #infrastructure

## Overview

The Archery Apprentice project uses a **hybrid runner system** combining GitHub-hosted and self-hosted runners to manage GitHub Actions quota (3000 minutes/month on Pro plan) while maintaining fast CI/CD pipelines.

### Runner Inventory

**Main Repository (archery-apprentice):**
- `win-runner-01` - Self-hosted Windows runner (primary)
- `win-runner-02` - Self-hosted Windows runner (secondary)
- `ubuntu-latest` - GitHub-hosted runner (early month)

**Docs Repository (archery-apprentice-docs):**
- `win-runner-01` - Self-hosted Windows runner (docs deployment)
- `ubuntu-latest` - GitHub-hosted runner (fallback)

**Labels:** All self-hosted runners use `self-hosted`, `Windows`, `X64`, `android`

---

## Runner Selection Strategy

### Day-of-Month Heuristic (Auto Mode)

All workflows use a `decide_runner` job that selects runner based on day of month:

```yaml
decide_runner:
  runs-on: self-hosted
  outputs:
    runner_label: ${{ steps.decision.outputs.runner_label }}
  steps:
    - name: Determine runner
      shell: powershell
      run: |
        $DAY = (Get-Date).Day
        if ($DAY -ge 22) {
          $RUNNER = "self-hosted"  # Late month: conserve quota
        } else {
          $RUNNER = "ubuntu-latest"  # Early month: use GitHub
        }
        "runner_label=$RUNNER" >> $env:GITHUB_OUTPUT
```

**Rationale:**
- **Days 1-21:** Use GitHub-hosted runners (plenty of quota)
- **Days 22-31:** Use self-hosted runners (conserve quota for next month)
- **Automatic reset:** First of month switches back to GitHub-hosted

### Manual Overrides

**Commit Message Flags:**
```bash
git commit -m "feat: Add feature [self-hosted]"  # Force self-hosted
git commit -m "fix: Quick fix [github]"           # Force GitHub-hosted
git commit -m "docs: Update [skip-ci]"           # Skip CI entirely
```

**Workflow Dispatch:**
- Go to Actions → Select workflow → Run workflow
- Choose `runner_mode`: auto / self-hosted / github / skip

---

## Workflows Using Self-Hosted Runners

### android-ci.yml (Pull Request Validation)
**Triggers:** Pull requests to main
**Runner Strategy:** Auto (day-based)
**Uses Gradle:** ✅ Yes (Android builds)
**Daemon Cleanup:** ✅ Required
**Concurrency Control:** ❌ Removed (2 runners available)

**Jobs:**
1. `decide_runner` - Selects runner
2. `quick_checks` - Lint, validation
3. `test_and_coverage` - Unit tests, JaCoCo coverage

**Critical:** Includes Gradle daemon cleanup before builds

---

### deploy-to-play-store.yml (Production Deployment)
**Triggers:** Push to main
**Runner Strategy:** Auto (day-based)
**Uses Gradle:** ✅ Yes (Release AAB build)
**Daemon Cleanup:** ✅ Required
**Concurrency Control:** ✅ Active (one deployment at a time)

**Jobs:**
1. `decide_runner` - Selects runner
2. `deploy` - Build AAB, sign, upload to Play Store

**Why Concurrency Kept:** Deployments should never run in parallel (data integrity)

---

### docs-only-check.yml (Fast-Path for Docs PRs)
**Triggers:** Pull requests with only docs changes
**Runner Strategy:** Auto (day-based)
**Uses Gradle:** ❌ No (GitHub Actions scripts only)
**Daemon Cleanup:** ❌ Not needed
**Concurrency Control:** ❌ Removed (rarely runs, lightweight)

**Jobs:**
1. `decide_runner` - Selects runner
2. `docs-only-pass` - Validates PR is docs-only, creates passing check

---

### deploy-quartz.yml (Docs Vault Deployment)
**Repository:** archery-apprentice-docs
**Triggers:** Push to main
**Runner Strategy:** Auto (day-based)
**Uses Gradle:** ❌ No (Node.js/npm)
**Daemon Cleanup:** ❌ Not needed
**Concurrency Control:** ✅ Active (one deployment at a time)

**Jobs:**
1. `decide_runner` - Selects runner
2. `deploy` - Build Quartz site, deploy to GitHub Pages

**Why Concurrency Kept:** Prevents concurrent docs deployments from interfering

---

## The Gradle Daemon Issue (Oct 2025)

### Problem: "Gradle build daemon has been stopped: stop command received"

**Symptom:** CI builds failing with daemon termination error mid-build

**Root Causes (3 Issues Discovered):**

#### Issue 1: Memory Exhaustion (PR #175)
**Problem:** Kotlin compiler daemon running out of memory
**Error:** `java.lang.OutOfMemoryError: Java heap space`
**Fix:** Increased Kotlin daemon memory to 4GB
```properties
# gradle.properties
kotlin.daemon.jvmargs=-Xmx4096m
```

#### Issue 2: Daemon Race Condition (PR #178)
**Problem:** Pre-download step starts daemon, cleanup kills it mid-build
**Timeline:**
1. Step: Pre-download Robolectric dependencies → Starts Gradle daemon
2. Step: Stop Gradle daemons → Kills daemon
3. Step: Build project → No daemon, tries to start, gets "stop command" error

**Fix:** Removed pre-download step, added `--no-daemon` flag
```yaml
# Before (BROKEN)
- name: Pre-download Robolectric
  run: .\gradlew.bat help -Drobolectric.enabledSdks=35
- name: Stop daemons
  run: .\gradlew.bat --stop
- name: Build
  run: .\gradlew.bat assembleDebug  # FAILS: daemon was stopped

# After (FIXED)
- name: Stop daemons
  run: |
    .\gradlew.bat --stop
    Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*GradleDaemon*' } | Stop-Process -Force
- name: Build
  run: .\gradlew.bat assembleDebug --no-daemon
```

#### Issue 3: Concurrent Job Interference (PR #180)
**Problem:** Multiple PRs running simultaneously, Job 2's cleanup kills Job 1's daemon

**Initial Fix (PR #180):** Added concurrency control to queue jobs
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: false  # Queue instead of cancel
```

**Revised Fix (Oct 27):** Removed concurrency control
- **Rationale:** 2 separate runners = 2 separate daemons (no interference)
- **Kept:** Daemon cleanup steps (still prevent within-job conflicts)
- **Benefit:** 2x CI throughput (both runners utilized)

---

## Concurrency Control Decision Matrix

### When to Use Concurrency Control

✅ **Use concurrency control for:**
- **Deployments** (deploy-to-play-store.yml, deploy-quartz.yml)
  - Reason: Prevent multiple deployments from interfering
  - Pattern: `group: deploy-[workflow]-${{ github.ref }}`

- **Data migrations** (if added in future)
  - Reason: Database schema changes must be sequential

❌ **Don't use concurrency control for:**
- **CI validation** (android-ci.yml, docs-only-check.yml)
  - Reason: Multiple runners can handle parallel jobs safely
  - Daemon cleanup prevents within-job conflicts

### How to Re-Enable Concurrency (If Daemon Issues Return)

**If you see "daemon stopped" errors again:**

1. **Check runner distribution:**
   ```bash
   gh api repos/blamechris/archery-apprentice/actions/runners
   ```
   - If both jobs running on SAME runner → Re-enable concurrency

2. **Add concurrency block back:**
   ```yaml
   # Add this AFTER permissions section in workflow
   concurrency:
     group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
     cancel-in-progress: false  # Queue jobs instead of cancelling
   ```

3. **Where to add:**
   - `android-ci.yml` (line ~30, after `permissions`)
   - `docs-only-check.yml` (line ~30, after `permissions`)

4. **Test with:**
   ```bash
   # Open 2 PRs quickly, watch if they queue or run parallel
   gh run list --workflow android-ci.yml --limit 5
   ```

**Marker for easy re-enable:** Look for `# CONCURRENCY_DISABLED_2025_10_27` comments in workflows

---

## Self-Hosted Runner Setup & Management

### Initial Setup (Per Runner)

**Prerequisites:**
- Windows 10/11 machine (8GB+ RAM recommended)
- PowerShell 5.1+ as Administrator
- Android SDK installed (for Android builds)
- Node.js 20+ (for docs builds)

**Setup Script:**
```powershell
# C:\actions-runners\setup-self-hosted-runners.ps1
# (See archery-apprentice repo for full script)

# Key steps:
1. Download GitHub Actions runner
2. Configure with repository token
3. Install as Windows service
4. Configure auto-start
5. Verify connection
```

**Reference:** See `docs/SELF_HOSTED_RUNNER_SETUP.md` in archery-apprentice repo

### Service Management

**Check runner status:**
```powershell
# List all runner services
Get-Service -Name "actions.runner.*" | Format-Table Name, Status

# Check GitHub registration
gh api repos/blamechris/archery-apprentice/actions/runners
```

**Restart runners:**
```powershell
Restart-Service -Name "actions.runner.*archery-apprentice*"
```

**View logs:**
```powershell
# Service logs
Get-EventLog -LogName Application -Source "actions.runner.*" -Newest 50

# Runner diagnostics
C:\actions-runners\win-runner-01\_diag\
```

### Common Issues & Solutions

#### Runner Offline
**Symptom:** Runner shows "offline" in GitHub Actions
**Fixes:**
1. Check service: `Get-Service -Name "actions.runner.*"`
2. Restart service: `Restart-Service -Name "actions.runner.*"`
3. Check network connectivity
4. Verify token not expired (regenerate if > 1 hour old)

#### File Lock Errors
**Symptom:** `AccessDeniedException` on Android SDK files
**Fixes:**
```powershell
# Stop all Gradle daemons
.\gradlew.bat --stop

# Kill Java processes
Get-Process -Name "*java*" | Stop-Process -Force

# Take file ownership (if needed)
takeown /f "C:\...\core-lambda-stubs.jar"
icacls "C:\...\core-lambda-stubs.jar" /grant username:F
```

#### Build Hangs/Timeouts
**Symptom:** CI builds hang or timeout
**Fixes:**
1. Check for orphaned Gradle/Java processes
2. Clear Gradle cache: `.\gradlew clean`
3. Check disk space (need > 10GB free)
4. Restart runner service

**Incident Report:** See `docs/SELF_HOSTED_RUNNER_INCIDENT_2025-10-26.md` for detailed troubleshooting example

---

## Daemon Cleanup Pattern (Critical for Gradle Workflows)

### Why Daemon Cleanup is Required

**Problem:** Gradle daemons persist between workflow runs, causing:
- File locks on Android SDK files
- Memory leaks (daemons accumulate)
- "Daemon stopped" errors if cleanup runs mid-build

**Solution:** Always cleanup BEFORE starting new daemon

### Standard Cleanup Steps

**Windows (PowerShell):**
```yaml
- name: Stop any running Gradle daemons (Windows)
  if: runner.os == 'Windows'
  shell: powershell
  run: |
    echo "Stopping any running Gradle daemons..."
    .\gradlew.bat --stop

    # Kill any orphaned Gradle daemon processes
    echo "Killing orphaned Gradle daemon processes..."
    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
      Where-Object { $_.CommandLine -like '*GradleDaemon*' } |
      ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

    # Wait for processes to fully terminate
    Start-Sleep -Seconds 2
    echo "Cleanup complete"
  continue-on-error: true
```

**Linux/macOS:**
```yaml
- name: Stop any running Gradle daemons (Linux/macOS)
  if: runner.os != 'Windows'
  run: |
    echo "Stopping any running Gradle daemons..."
    ./gradlew --stop || true
    sleep 2
    echo "Cleanup complete"
  continue-on-error: true
```

**When to add:** BEFORE any `gradlew` build commands

---

## Monitoring & Metrics

### Runner Utilization

**Check current jobs:**
```bash
# All active runs
gh run list --limit 10

# Specific workflow
gh run list --workflow android-ci.yml --limit 5

# Watch live run
gh run watch [run-id]
```

**Runner busy status:**
```bash
gh api repos/blamechris/archery-apprentice/actions/runners --jq '.runners[] | {name: .name, busy: .busy, status: .status}'
```

### Quota Tracking

**GitHub Actions quota:**
- Go to Settings → Billing → Actions usage
- Pro plan: 3000 minutes/month
- Self-hosted runners: Don't count against quota

**Monthly strategy:**
- Days 1-21: ~1680 minutes available (21 days × 80 min/day)
- Days 22-31: Switch to self-hosted (conserve remaining ~1320 minutes)

### Performance Metrics

**Average CI times (GitHub-hosted):**
- Lint + validation: ~2 min
- Unit tests: ~8 min
- Coverage report: ~5 min
- **Total:** ~15 min per PR

**Average CI times (Self-hosted):**
- Lint + validation: ~1.5 min
- Unit tests: ~5 min
- Coverage report: ~3 min
- **Total:** ~9.5 min per PR

**Speed improvement:** Self-hosted ~40% faster (cached dependencies, more CPU/RAM)

---

## Future Improvements

### Short-Term (Week 11+)
1. **Automated runner health checks** - Daily cron job to verify runner status
2. **Disk space monitoring** - Alert when runners < 10GB free
3. **Performance baselines** - Track build time trends, alert on degradation

### Medium-Term (Month 2+)
4. **macOS runner** - Add macOS self-hosted runner for iOS builds (KMP migration)
5. **Test parallelization** - Split test suite across 2 runners
6. **Cache optimization** - Gradle/Robolectric dependency caching

### Long-Term (Quarter 2+)
7. **Runner auto-scaling** - Add/remove runners based on queue length
8. **Dedicated deployment runner** - Separate runner for Play Store uploads
9. **Runner fleet management** - Terraform/Ansible for runner provisioning

---

## Related Documentation

**Code Repository:**
- `docs/SELF_HOSTED_RUNNER_SETUP.md` - Runner setup guide
- `docs/SELF_HOSTED_RUNNER_INCIDENT_2025-10-26.md` - Incident report
- `docs/CLAUDE.md` - CI/CD section with quick reference
- `.github/workflows/` - All workflow files

**Pull Requests:**
- #175 - Memory fix (kotlin.daemon.jvmargs)
- #178 - Daemon race condition fix (cleanup + --no-daemon)
- #180 - Concurrent job fix (concurrency control)
- #181 - docs-only-check concurrency
- (This doc created) - Concurrency removal for 2-runner utilization

**Obsidian Vault:**
- [[Build Quality Patterns and Test Best Practices]] - Related testing patterns
- [[Agent-Work/Agent-O-Week-10-Summary]] - Week 10 CI/CD fixes (when created)

---

## Quick Reference

### Emergency Commands

**Stop everything:**
```powershell
# Windows
.\gradlew.bat --stop
Get-Process -Name "*java*" | Stop-Process -Force
Restart-Service -Name "actions.runner.*"
```

**Clean rebuild:**
```bash
.\gradlew clean build --no-daemon
```

**Verify runner connectivity:**
```bash
gh api repos/blamechris/archery-apprentice/actions/runners
```

### Decision Tree: "Should I use self-hosted?"

```
Is it late in month (day >= 22)?
├─ YES → Use self-hosted (conserve quota)
└─ NO → Is it a critical hotfix?
    ├─ YES → Use GitHub-hosted (faster start)
    └─ NO → Is it a large build (> 10 min)?
        ├─ YES → Use self-hosted (40% faster)
        └─ NO → Use GitHub-hosted (default)
```

---

*Last Updated: 2025-10-27*
*Maintained by: Agent O (Orchestrator)*
*Status: Production-ready, actively maintained*
