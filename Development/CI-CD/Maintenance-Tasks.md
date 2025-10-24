# CI/CD Maintenance Tasks

**Last Updated:** 2025-10-24
**Purpose:** Regular maintenance procedures for GitHub Actions CI/CD infrastructure
**Frequency:** Weekly, Monthly, Quarterly, Annual

---

## Maintenance Schedule Overview

| Frequency | Duration | Tasks | Priority |
|-----------|----------|-------|----------|
| **Daily** | 2-5 min | Check failed workflows, runner status | High |
| **Weekly** | 10-15 min | Review quota, clean artifacts, verify caching | Medium |
| **Monthly** | 30-45 min | Update dependencies, runner maintenance, verify month rollover | High |
| **Quarterly** | 1-2 hours | Major updates, security review, performance audit | Medium |
| **Annual** | 2-4 hours | Infrastructure review, secret rotation, documentation update | High |

---

## Daily Tasks (2-5 minutes)

### Check Failed Workflows

**Purpose:** Catch and fix issues quickly before they compound

**Commands:**
```bash
# List recent failed workflows
gh run list --status failure --limit 10

# View failure details
gh run view <run-id> --log-failed

# Re-run if transient failure
gh run rerun <run-id>
```

**What to look for:**
- ❌ Flaky tests (intermittent failures)
- ❌ Network timeouts (Robolectric, npm, etc.)
- ❌ Quota exhaustion (day < 22 but quota exceeded)
- ❌ Service outages (GitHub, Play Store, Firebase)

**Actions:**
- Flaky tests → Add to backlog for investigation
- Timeouts → Check runner connectivity, retry
- Quota issues → Use `[self-hosted]` flag temporarily
- Outages → Wait and retry, monitor status pages

### Verify Self-Hosted Runner Status

**Purpose:** Ensure runner is available for end-of-month quota conservation

**Commands:**
```powershell
# Windows
cd C:\actions-runner
.\svc.sh status

# Expected: "Active (running)"
```

```bash
# Linux/macOS
cd ~/actions-runner
sudo ./svc.sh status

# Expected: "active (running)"
```

**What to check:**
- Runner shows "Idle" (green) in GitHub Settings → Actions → Runners
- No stuck jobs (runner busy for >60 minutes)
- Disk space >20GB free

**Actions if offline:**
```powershell
# Restart runner service
.\svc.sh restart

# Check logs if restart fails
Get-Content _diag\Runner_*.log -Tail 50
```

---

## Weekly Tasks (10-15 minutes)

### Review GitHub Actions Quota Usage

**Purpose:** Ensure hybrid runner system is conserving quota as expected

**Location:** GitHub → Settings → Billing → Actions minutes

**Expected usage pattern:**
- Days 1-21: ~150-200 minutes/day (mostly GitHub-hosted)
- Days 22-31: ~0-50 minutes/day (mostly self-hosted)
- Monthly total: ~3,000-3,200 minutes (within quota)

**Check:**
1. Current month usage vs. quota (3000 minutes)
2. Spending velocity (minutes/day)
3. Projected end-of-month usage

**Actions if over-spending:**
```bash
# Temporarily force self-hosted for all commits
git commit -m "feat: New feature [self-hosted]"

# Or adjust day threshold in workflows
# Change: if ($DAY -ge 22) → if ($DAY -ge 15)
```

**Actions if under-spending:**
- Quota conservation working well
- Can safely use GitHub-hosted more often
- Consider adjusting threshold: 22 → 25

### Clean Old Workflow Runs

**Purpose:** Keep Actions tab readable, reduce clutter

**Commands:**
```bash
# List old successful runs (>30 days)
gh run list --status success --created >2024-09-24 --limit 50

# Delete old runs (GitHub UI is easier)
# Settings → Actions → General → Artifact and log retention → 30 days
```

**Settings:**
- Artifact retention: 7-14 days (default: 90)
- Log retention: 30-60 days (default: 90)

**Manual cleanup:**
- Delete old workflow runs via UI (Actions → Select workflow → ... → Delete workflow run)
- Focus on successful runs >30 days old
- Keep failed runs longer for reference

### Verify Caching Effectiveness

**Purpose:** Ensure caches are reducing build times

**Check:**
```bash
# Compare build times with/without cache
gh run list --workflow=android-ci.yml --limit 20

# Look for "Cache hit" vs "Cache miss" in logs
gh run view <run-id> --log | grep -i "cache"
```

**Expected:**
- Gradle dependencies: Cache hit rate >90%
- Robolectric SDK: Cache hit rate >95%
- Node modules (Quartz): Cache hit rate >90%

**Actions if low hit rate:**
- Check cache key stability: `${{ hashFiles('**/*.gradle*') }}`
- Verify cache size limits (10GB max per repo)
- Consider cache compression

### Review Recent Deployments

**Purpose:** Verify deployments are succeeding and Discord notifications working

**Check:**
```bash
# List recent deploy workflow runs
gh run list --workflow=deploy-to-play-store.yml --limit 10

# Verify Discord channel has notifications
```

**Expected:**
- All deploys to main branch successful
- Discord notifications sent for all deploys
- Version codes incrementing correctly

**Actions if issues:**
- Deployment failures → Check Play Console for errors
- Missing Discord notifications → Verify DISCORD_WEBHOOK_URL secret
- Version conflicts → Increment BASE_VERSION

---

## Monthly Tasks (30-45 minutes)

### Verify Month Rollover (First Week of Month)

**Purpose:** Ensure hybrid runner system switches back to GitHub-hosted on day 1

**Check on:** 1st-3rd of each month

**Commands:**
```bash
# Create test commit on day 1-3
git commit --allow-empty -m "test: Verify auto-mode switches to GitHub runner"
git push

# Check which runner was used
gh run list --limit 1
gh run view <run-id> --log | grep "Selected runner"

# Expected output: "Selected runner: ubuntu-latest"
```

**Actions if wrong runner:**
- Check decide_runner logic in workflows
- Verify PowerShell date command: `$DAY = (Get-Date).Day`
- Verify threshold: `if ($DAY -ge 22)`

### Update GitHub Actions Dependencies

**Purpose:** Keep workflows secure and using latest features

**What to update:**
```yaml
# .github/workflows/*.yml

# Update action versions
- uses: actions/checkout@v4           # Check for v5
- uses: actions/setup-java@v4         # Check for v5
- uses: gradle/actions/setup-gradle@v4  # Check for v5
- uses: actions/cache@v4              # Check for v5
- uses: codecov/codecov-action@v5     # Check for v6
- uses: peaceiris/actions-gh-pages@v4 # Check for v5
```

**Process:**
1. Check GitHub Actions Marketplace for newer versions
2. Read changelog/release notes for breaking changes
3. Test with `[github]` flag first (cheap if fails)
4. Update one action at a time
5. Monitor first 2-3 runs for issues

**Common updates:**
- actions/checkout: New features, bug fixes
- gradle/actions: Gradle version support
- codecov/codecov-action: Coverage accuracy improvements

### Update Gradle and Dependencies

**Purpose:** Security patches, bug fixes, performance improvements

**Commands:**
```bash
# Check current Gradle version
./gradlew --version

# Update Gradle wrapper
./gradlew wrapper --gradle-version=8.6

# Update Android Gradle Plugin
# Edit app/build.gradle.kts:
# classpath("com.android.tools.build:gradle:8.2.0")
```

**Update dependencies:**
```kotlin
// app/build.gradle.kts
dependencies {
    // Check for updates
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.compose.ui:ui:1.6.1")
    // etc.
}
```

**Testing:**
```bash
# Run full test suite locally
./gradlew clean testDebugUnitTest

# Commit with GitHub runner test
git commit -m "chore: Update Gradle and dependencies [github]"
git push

# Monitor workflow for failures
gh run watch
```

### Clean Self-Hosted Runner Caches

**Purpose:** Free disk space, prevent cache corruption

**Windows:**
```powershell
# Stop runner
cd C:\actions-runner
.\svc.sh stop

# Clean Gradle cache (~500MB-2GB)
Remove-Item -Recurse -Force $env:USERPROFILE\.gradle\caches\

# Clean Robolectric cache (~500MB)
Remove-Item -Recurse -Force $env:USERPROFILE\.robolectric\

# Clean Android build cache (~1GB)
Remove-Item -Recurse -Force $env:USERPROFILE\.android\build-cache\

# Clean work directory (safe, re-downloaded as needed)
Remove-Item -Recurse -Force C:\actions-runner\_work\*

# Restart runner
.\svc.sh start
```

**Linux/macOS:**
```bash
# Stop runner
cd ~/actions-runner
sudo ./svc.sh stop

# Clean caches
rm -rf ~/.gradle/caches/
rm -rf ~/.robolectric/
rm -rf ~/.android/build-cache/
rm -rf ~/actions-runner/_work/*

# Restart runner
sudo ./svc.sh start
```

**Verify:**
```bash
# Check disk space before and after
df -h  # Linux/macOS
Get-PSDrive C | Select-Object Used,Free  # Windows
```

### Review and Update Secrets

**Purpose:** Ensure secrets are current and secure

**Secrets to review:**
```bash
# List all secrets
gh secret list

# Expected secrets:
# - GOOGLE_SERVICES_JSON (Firebase config)
# - KEYSTORE_BASE64 (Upload signing cert)
# - KEYSTORE_PASSWORD
# - KEY_ALIAS
# - KEY_PASSWORD
# - PLAY_SERVICE_ACCOUNT_JSON (Play Store API)
# - DISCORD_WEBHOOK_URL (Notifications)
# - CODECOV_TOKEN (Coverage, optional)
```

**Check for:**
- Expiring credentials (Play Store service account)
- Outdated Firebase config (OAuth clients, SHA-1s)
- Broken Discord webhook (test with manual run)

**Update process:**
```bash
# Update secret
gh secret set SECRET_NAME
# Paste new value when prompted

# Test with manual workflow run
gh workflow run deploy-to-play-store.yml -f runner_mode=github
gh run watch
```

### Audit Workflow Performance

**Purpose:** Identify optimization opportunities

**Metrics to track:**

| Workflow | Expected Duration | Acceptable Range |
|----------|-------------------|------------------|
| android-ci.yml quick_checks | 3-5 min | 2-8 min |
| android-ci.yml test_and_coverage | 15-20 min | 12-30 min |
| deploy-to-play-store.yml | 20-30 min | 15-40 min |
| deploy-quartz.yml | 5-8 min | 4-12 min |
| documentation-reminder.yml | 30s | 10s-2min |

**Check:**
```bash
# Get recent run durations
gh run list --workflow=android-ci.yml --json durationMs,conclusion,createdAt --limit 20

# Identify slow runs
gh run list --workflow=android-ci.yml --limit 20 | awk '$4 > 30 { print }'
```

**Actions if slow:**
- Review logs for bottlenecks
- Check if cache is working (cache hit/miss)
- Consider splitting jobs further
- Increase runner resources (self-hosted only)

---

## Quarterly Tasks (1-2 hours)

### Major Dependency Updates

**Purpose:** Stay current with major Android/Kotlin/Compose versions

**Updates to consider:**
- Android SDK version (compileSdk, targetSdk)
- Kotlin version
- Jetpack Compose version
- Gradle version (if major version available)
- GitHub Actions runner version

**Process:**
1. Read migration guides and changelogs
2. Create feature branch for updates
3. Update dependencies incrementally
4. Run full test suite after each update
5. Test on both GitHub and self-hosted runners
6. Monitor first few production deployments

**High-risk updates:**
- targetSdk changes (Play Store requirements)
- Kotlin major versions (breaking changes)
- Compose major versions (API changes)

### Security Audit

**Purpose:** Ensure CI/CD pipeline is secure

**Checklist:**

**Workflow Security:**
- [ ] No secrets leaked in logs (search logs for sensitive data)
- [ ] Secrets only used in trusted actions
- [ ] No write permissions on untrusted PR forks
- [ ] Keystore cleaned up after deployment (if: always())

**Runner Security:**
- [ ] Self-hosted runner runs as non-admin user
- [ ] Runner only accessible from GitHub IPs (firewall rules)
- [ ] Runner logs don't contain secrets
- [ ] Runner work directory isolated per repository

**Secret Management:**
- [ ] All secrets rotated in last 12 months
- [ ] No hardcoded secrets in code or workflows
- [ ] Service accounts have minimal permissions
- [ ] DISCORD_WEBHOOK_URL not exposed publicly

**Actions:**
```bash
# Search for potential secrets in logs
gh run list --limit 50 | while read id; do
  gh run view $id --log | grep -iE "(password|token|key|secret)"
done

# Review workflow permissions
grep -r "permissions:" .github/workflows/

# Rotate secrets (annually, see "Annual Tasks")
```

### Performance Optimization

**Purpose:** Maximize build speed and minimize costs

**Areas to optimize:**

**1. Caching:**
```yaml
# Review cache sizes and hit rates
- uses: actions/cache@v4
  with:
    path: |
      ~/.gradle/caches
      ~/.gradle/wrapper
      ~/.robolectric
    key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*') }}
    # Consider adding restore-keys for partial hits
    restore-keys: |
      ${{ runner.os }}-gradle-
```

**2. Parallelization:**
```yaml
# Can any sequential jobs run in parallel?
jobs:
  job1:
    runs-on: ubuntu-latest
  job2:
    runs-on: ubuntu-latest
    # If job2 doesn't depend on job1, remove needs:
    # needs: job1
```

**3. Job splitting:**
```yaml
# Can long jobs be split?
# Example: Split test_and_coverage into separate jobs
test:
  runs-on: ubuntu-latest
  # 10 minutes
coverage:
  needs: test
  runs-on: ubuntu-latest
  # 5 minutes
# Total: 15 min (vs 15 min sequential, same time but better visibility)
```

**4. Conditional execution:**
```yaml
# Skip unnecessary steps
- name: Build release AAB
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  # Only run on main branch pushes, not PRs
```

### Update Runner Software

**Purpose:** Security patches, new features, bug fixes

**Self-Hosted Runner Updates:**

**Check for updates:**
```bash
# Current version
cd C:\actions-runner  # Windows
cd ~/actions-runner   # Linux/macOS

./config.sh --version

# Latest version: https://github.com/actions/runner/releases
```

**Update process:**
```bash
# 1. Stop runner
.\svc.sh stop  # Windows
sudo ./svc.sh stop  # Linux/macOS

# 2. Download latest version
# Windows: Download from GitHub releases
# Linux/macOS: curl -o actions-runner-*.tar.gz

# 3. Uninstall service
.\svc.sh uninstall  # Windows
sudo ./svc.sh uninstall  # Linux/macOS

# 4. Extract new version (overwrite existing files)
# tar xzf actions-runner-*.tar.gz  # Linux/macOS
# Expand-Archive -Force  # Windows

# 5. Reinstall service (config preserved)
.\svc.sh install  # Windows
sudo ./svc.sh install  # Linux/macOS

# 6. Start runner
.\svc.sh start  # Windows
sudo ./svc.sh start  # Linux/macOS

# 7. Verify
.\svc.sh status
```

**Android SDK Updates:**
```bash
# Update SDK components
cd C:\Android\Sdk\cmdline-tools\latest\bin  # Windows
cd ~/android-sdk/cmdline-tools/latest/bin   # Linux/macOS

./sdkmanager --update
./sdkmanager "platforms;android-35" "build-tools;34.0.0"
```

---

## Annual Tasks (2-4 hours)

### Comprehensive Security Review

**Purpose:** Annual security audit and secret rotation

**Tasks:**

**1. Rotate All Secrets:**
```bash
# Generate new keystore (upload cert)
keytool -genkey -v -keystore archery-apprentice-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Convert to base64
base64 archery-apprentice-upload.jks | gh secret set KEYSTORE_BASE64

# Update passwords
gh secret set KEYSTORE_PASSWORD
gh secret set KEY_PASSWORD
```

**2. Regenerate Service Accounts:**
- Google Play Service Account
  - Play Console → API access → Create new service account
  - Download JSON → `gh secret set PLAY_SERVICE_ACCOUNT_JSON`
  - Revoke old service account after 30-day grace period

**3. Rotate Discord Webhook:**
- Discord Server Settings → Integrations → Webhooks
- Create new webhook → Copy URL
- `gh secret set DISCORD_WEBHOOK_URL`
- Delete old webhook after verification

**4. Review GitHub Permissions:**
- Settings → Actions → General → Workflow permissions
  - Ensure "Read and write permissions" (for gh-pages)
  - Review "Allow GitHub Actions to create and approve pull requests"

**5. Audit Repository Access:**
- Settings → Manage access
- Review collaborators and their permissions
- Remove inactive collaborators
- Review deploy keys

### Infrastructure Review

**Purpose:** Evaluate overall CI/CD effectiveness and identify improvements

**Metrics to analyze:**

**1. Reliability:**
```bash
# Calculate success rate by workflow (last 100 runs)
for workflow in android-ci deploy-to-play-store documentation-reminder deploy-quartz; do
  echo "=== $workflow ==="
  total=$(gh run list --workflow=$workflow --limit 100 --json conclusion --jq 'length')
  success=$(gh run list --workflow=$workflow --limit 100 --json conclusion --jq '[.[] | select(.conclusion == "success")] | length')
  echo "Success rate: $((success * 100 / total))% ($success/$total)"
done

# Target: >95% success rate
```

**2. Cost Analysis:**
```
# Total GitHub Actions minutes used (12 months)
# Total self-hosted runner cost (electricity, hardware)
# Cost per deployment
# Cost per test run
```

**3. Developer Experience:**
- Average PR validation time (android-ci.yml)
- Time from merge to production (deploy workflow)
- Frequency of workflow failures due to infra issues

**4. Quota Efficiency:**
```
# Quota saved by hybrid runner system:
# Months before hybrid runner: 4,500-6,750 minutes/month (over quota)
# Months after hybrid runner: ~3,000-3,200 minutes/month (within quota)
# Savings: ~1,500-3,500 minutes/month = 50-60% reduction
```

**Actions:**
- Document findings in vault (Development/CI-CD/Annual-Review-YYYY.md)
- Create backlog items for identified improvements
- Propose infrastructure changes if needed

### Documentation Update

**Purpose:** Keep documentation accurate and comprehensive

**Files to review:**
```
Documentation Repository:
- Development/CI-CD/Hybrid-Runner-System.md
- Development/CI-CD/Workflows-Overview.md
- Development/CI-CD/Troubleshooting-Guide.md
- Development/CI-CD/Maintenance-Tasks.md

Main Repository:
- docs/SELF_HOSTED_RUNNER_SETUP.md
- CLAUDE.md (CI/CD section)
- README.md (Workflow badges)
```

**Check for:**
- Outdated version numbers (Gradle, Android SDK, action versions)
- Broken links (repository URLs, workflow file paths)
- Obsolete troubleshooting steps (fixed issues)
- Missing workflows or new features
- Inaccurate quota estimates

**Update process:**
1. Review each file for accuracy
2. Update version numbers and statistics
3. Add new troubleshooting entries from past year
4. Remove resolved issues
5. Commit and deploy documentation

---

## Emergency Maintenance

### Critical Security Vulnerability

**Response process:**

**1. Assess Impact (10 minutes):**
- Identify affected dependencies
- Check if vulnerability exploitable in CI/CD
- Determine severity (CVSS score)

**2. Immediate Mitigation (30 minutes):**
```bash
# Disable affected workflow if exploitable
gh workflow disable <workflow-name>

# Or use skip flag for all commits
# Add to repo settings or announcement
```

**3. Patch (1-4 hours):**
```bash
# Update vulnerable dependency
# Example: actions/checkout has vulnerability

# Update workflow
sed -i 's/actions\/checkout@v3/actions\/checkout@v4/g' .github/workflows/*.yml

# Test
git commit -m "security: Update actions/checkout to v4 [github]"
git push

# Monitor
gh run watch
```

**4. Verify and Re-enable:**
```bash
# Verify patch effective
# Run security scan if available

# Re-enable workflow
gh workflow enable <workflow-name>
```

**5. Post-Mortem (1 week later):**
- Document vulnerability and response
- Update security procedures if needed
- Schedule dependency update review

### Quota Exhausted

**Response process:**

**1. Immediate Action:**
```bash
# Use self-hosted for ALL workflows until quota resets
# Update workflow files or use [self-hosted] flags

git commit -m "chore: Work in progress [self-hosted]"
git push
```

**2. Identify Cause:**
```bash
# Check quota usage
# Settings → Billing → Actions

# Identify high-usage workflows
gh run list --created >2024-10-01 --limit 100 --json durationMs,name
```

**3. Temporary Measures:**
- Adjust day threshold: `if ($DAY -ge 22)` → `if ($DAY -ge 1)` (all self-hosted)
- Skip non-critical workflows
- Batch changes to reduce workflow runs

**4. Long-Term Fix:**
- Review workflow efficiency
- Consider upgrading GitHub plan (if needed)
- Optimize job duration

### Runner Failure During Important Release

**Response process:**

**1. Assess Urgency:**
- Can wait for runner fix? (30 min - 2 hours)
- Must deploy immediately? (use GitHub-hosted)

**2. If Can Wait:**
```powershell
# Debug runner
cd C:\actions-runner
.\svc.sh status
Get-Content _diag\Runner_*.log -Tail 100

# Try restart
.\svc.sh restart

# If persist, re-register (15 minutes)
.\svc.sh uninstall
./config.sh remove
./config.sh --url ... --token ...
.\svc.sh install
.\svc.sh start
```

**3. If Must Deploy Now:**
```bash
# Override to use GitHub-hosted
git commit --amend -m "$(git log -1 --pretty=%s) [github]"
git push --force-with-lease

# Monitor deployment
gh run watch
```

**4. Post-Release:**
- Fix runner issue
- Document problem and resolution
- Add monitoring if needed

---

## Monitoring and Alerts

### Set Up Notifications

**GitHub Actions Email Notifications:**
- Settings → Notifications → Actions
- Enable: "Only notify for failed workflows"

**Discord Notifications (Already Implemented):**
- Deployment success/failure → Discord webhook
- Documentation deployment → Discord webhook

**Proposed: Additional Monitoring**

**Quota threshold alerts:**
```yaml
# New workflow: .github/workflows/quota-alert.yml
on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight

jobs:
  check-quota:
    runs-on: ubuntu-latest
    steps:
      # Pseudo-code (GitHub API doesn't expose quota directly)
      - name: Check quota
        run: |
          # Fetch quota usage via GitHub API
          # If usage > 2500 minutes (83% of 3000)
          # Send Discord alert
```

**Runner health check:**
```yaml
# New workflow: .github/workflows/runner-health.yml
on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours

jobs:
  ping-runner:
    runs-on: self-hosted
    steps:
      - name: Health check
        run: echo "Runner is healthy"

      # If this fails (runner offline), GitHub sends email
```

---

## Checklist Templates

### Weekly Maintenance Checklist

```markdown
- [ ] Review failed workflows (gh run list --status failure)
- [ ] Verify self-hosted runner status (.\svc.sh status)
- [ ] Check GitHub Actions quota usage (Settings → Billing)
- [ ] Clean old workflow runs (>30 days, if needed)
- [ ] Verify caching effectiveness (check cache hit rates)
- [ ] Review recent deployments (gh run list --workflow=deploy-to-play-store.yml)
```

### Monthly Maintenance Checklist

```markdown
- [ ] Verify month rollover (day 1-3: check auto-mode uses GitHub runner)
- [ ] Update GitHub Actions dependencies (check for new versions)
- [ ] Update Gradle and dependencies (check for security patches)
- [ ] Clean self-hosted runner caches (Gradle, Robolectric, Android)
- [ ] Review and update secrets (verify all secrets current)
- [ ] Audit workflow performance (check run durations)
```

### Quarterly Maintenance Checklist

```markdown
- [ ] Major dependency updates (Android SDK, Kotlin, Compose, Gradle)
- [ ] Security audit (secrets, permissions, workflow security)
- [ ] Performance optimization (caching, parallelization, splitting)
- [ ] Update runner software (self-hosted runner, Android SDK)
```

### Annual Maintenance Checklist

```markdown
- [ ] Comprehensive security review (rotate all secrets)
- [ ] Infrastructure review (metrics, cost analysis, developer experience)
- [ ] Documentation update (all CI/CD docs)
- [ ] Service account renewal (Play Store, Firebase)
- [ ] Certificate renewal (upload keystore, if needed)
```

---

## Related Documentation

- [[Hybrid-Runner-System|Hybrid Runner System]] - Runner setup and configuration
- [[Workflows-Overview|Workflows Overview]] - Detailed workflow documentation
- [[Troubleshooting-Guide|Troubleshooting Guide]] - Common issues and solutions

**External Resources:**
- [GitHub Actions Best Practices](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [Gradle Performance Guide](https://docs.gradle.org/current/userguide/performance.html)
- [Android Best Practices for CI/CD](https://developer.android.com/studio/build/building-cmdline)

---

**Tags:** #ci-cd #maintenance #monitoring #automation
**Status:** ✅ Comprehensive maintenance guide
**Last Updated:** 2025-10-24
**Next Review:** 2025-11-24
