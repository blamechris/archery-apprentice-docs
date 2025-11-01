# CI/CD Troubleshooting Guide

**Last Updated:** 2025-10-24
**Scope:** All GitHub Actions workflows (android-ci, deploy-to-play-store, documentation-reminder, deploy-quartz)

---

## Quick Diagnosis

| Symptom | Likely Cause | Section |
|---------|--------------|---------|
| Runner shows offline | Service stopped or network issue | [Runner Connection](#runner-connection-issues) |
| Codecov upload fails on Windows | Missing bash/sh in PATH | [Codecov Issues](#codecov-issues) |
| Google Sign-In fails after deployment | SHA-1 mismatch (app signing vs Firebase) | [Authentication Issues](#authentication-issues) |
| Workflow uses wrong runner | Day-based logic or missing flag | [Runner Selection](#runner-selection-issues) |
| Discord notification missing | Platform-specific step skipped | [Notifications](#discord-notification-issues) |
| Build fails with "SDK not found" | Android SDK permissions (Windows service) | [Android SDK](#android-sdk-issues) |
| Tests fail with timeout | Robolectric download issues | [Robolectric Issues](#robolectric-issues) |
| Workflow skipped unexpectedly | [skip-ci] flag detected | [Workflow Triggers](#workflow-trigger-issues) |
| Coverage report missing | Workflow failed before coverage step | [Coverage Issues](#coverage-and-reporting) |
| Version code conflict | Duplicate run number or manual upload | [Versioning](#versioning-issues) |

---

## Runner Connection Issues

### Runner Shows Offline

**Symptoms:**
- GitHub Settings → Actions → Runners shows "Offline" (gray circle)
- Workflows queue indefinitely waiting for runner
- Error: "No runner available"

**Diagnosis:**

1. **Check service status:**
   ```powershell
   # Windows
   cd C:\actions-runner
   .\svc.sh status

   # Expected output: "Active (running)"
   ```

   ```bash
   # Linux/macOS
   cd ~/actions-runner
   sudo ./svc.sh status

   # Expected output: "actions.runner.*.service: active (running)"
   ```

2. **Check runner logs:**
   ```powershell
   # Windows
   Get-Content C:\actions-runner\_diag\Runner_*.log -Tail 50

   # Linux/macOS
   tail -50 ~/actions-runner/_diag/Runner_*.log
   ```

**Solutions:**

**Service not running:**
```powershell
# Windows
.\svc.sh start

# Linux/macOS
sudo ./svc.sh start
```

**Network connectivity:**
```bash
# Test GitHub connectivity
ping github.com
curl -I https://github.com

# Check proxy settings (if applicable)
echo $HTTP_PROXY
echo $HTTPS_PROXY
```

**Re-register runner:**
```bash
# Remove old registration
./config.sh remove --token YOUR_REMOVAL_TOKEN

# Get new token from: GitHub → Repo Settings → Actions → Runners → New runner
./config.sh --url https://github.com/blamechris/archery-apprentice \
            --token YOUR_NEW_TOKEN \
            --name "archery-runner-1" \
            --labels "self-hosted,Windows,X64"

# Reinstall service
.\svc.sh install
.\svc.sh start
```

### Runner Stuck on Job

**Symptoms:**
- Runner shows "Active" but workflow stuck at "Running..."
- Job exceeds normal time (>60 minutes)
- No progress in logs

**Diagnosis:**
```bash
# Check if runner process is consuming resources
# Windows: Task Manager → Find Runner.Listener.exe
# Linux/macOS: top or htop → Find Runner.Listener
```

**Solutions:**

**Force cancel job:**
```bash
gh run cancel <run-id>
```

**Restart runner:**
```powershell
# Windows
.\svc.sh restart

# Linux/macOS
sudo ./svc.sh restart
```

**Clean work directory:**
```bash
# Stop runner first
.\svc.sh stop

# Clean work directory
rm -rf C:\actions-runner\_work\*  # Windows
rm -rf ~/actions-runner/_work/*   # Linux/macOS

# Restart runner
.\svc.sh start
```

---

## Runner Selection Issues

### Wrong Runner Used

**Symptoms:**
- Workflow uses GitHub-hosted when expecting self-hosted (or vice versa)
- decide_runner job succeeds but wrong runner selected

**Diagnosis:**

1. **Check decide_runner output:**
   ```bash
   gh run view <run-id> --log | grep "Selected runner"
   ```

2. **Verify date logic:**
   ```bash
   date +%d  # Check current day of month
   # Days 1-21 = GitHub-hosted
   # Days 22-31 = Self-hosted
   ```

3. **Check commit message:**
   ```bash
   git log -1 --pretty=format:'%s'
   # Look for [self-hosted], [github], or [skip-ci] flags
   ```

**Solutions:**

**Override with commit flag:**
```bash
# Force self-hosted
git commit --amend -m "$(git log -1 --pretty=format:'%s') [self-hosted]"
git push --force-with-lease

# Force GitHub-hosted
git commit --amend -m "$(git log -1 --pretty=format:'%s') [github]"
git push --force-with-lease
```

**Override with workflow dispatch:**
1. GitHub → Actions → Select workflow
2. Click "Run workflow"
3. Select runner_mode: self-hosted or github
4. Click "Run workflow"

**Fix decide_runner logic:**
If day-based logic is wrong (e.g., day 25 using GitHub):
- Check `.github/workflows/*/decide_runner` job
- Verify PowerShell date logic: `$DAY = (Get-Date).Day`
- Verify threshold: `if ($DAY -ge 22)`

### decide_runner Job Fails

**Symptoms:**
- decide_runner job fails with error
- Downstream jobs skip with "needs not met"

**Common errors:**

**PowerShell syntax error:**
```
Line 5: unexpected token near '='
```

**Solution:** Check PowerShell script syntax in workflow file
```yaml
- name: Determine runner
  shell: powershell
  run: |
    $VAR = "value"  # PowerShell syntax (space around =)
    # NOT: VAR="value" (Bash syntax)
```

**Output not set:**
```
Error: runner_label output not found
```

**Solution:** Verify GITHUB_OUTPUT writes:
```powershell
"runner_label=$RUNNER" >> $env:GITHUB_OUTPUT
"should_skip=false" >> $env:GITHUB_OUTPUT
```

---

## Android SDK Issues

### SDK Not Found (Windows Self-Hosted)

**Symptoms:**
- Error: "SDK location not found"
- Error: "ANDROID_HOME not set"
- Build fails immediately on self-hosted Windows runner

**Root Cause:**
- Windows services run as NETWORK SERVICE account
- Cannot access user AppData folder: `C:\Users\USERNAME\AppData\Local\Android\Sdk`

**Diagnosis:**
```powershell
# Check current SDK location
Get-Content C:\actions-runner\_work\archery-apprentice\archery-apprentice\local.properties

# Expected: sdk.dir=C:/Android/Sdk
# Wrong: sdk.dir=C:/Users/USERNAME/AppData/Local/Android/Sdk
```

**Solution:**

1. **Copy SDK to system-wide location:**
   ```powershell
   # Run as Administrator
   Copy-Item -Path "C:\Users\USERNAME\AppData\Local\Android\Sdk" `
             -Destination "C:\Android\Sdk" `
             -Recurse -Force
   ```

2. **Update local.properties (main repo):**
   ```bash
   echo "sdk.dir=C:/Android/Sdk" > local.properties
   git add local.properties
   git commit -m "fix: Use system-wide Android SDK path for CI"
   git push
   ```

3. **Set environment variables (optional):**
   ```powershell
   # System Properties → Environment Variables → System variables
   ANDROID_HOME = C:\Android\Sdk
   ANDROID_SDK_ROOT = C:\Android\Sdk
   ```

4. **Restart runner:**
   ```powershell
   cd C:\actions-runner
   .\svc.sh restart
   ```

### SDK Licenses Not Accepted

**Symptoms:**
- Error: "You have not accepted the license agreements"
- Build fails during dependency resolution

**Solution:**
```bash
# Navigate to SDK
cd C:\Android\Sdk\cmdline-tools\latest\bin  # Windows
cd ~/android-sdk/cmdline-tools/latest/bin   # Linux/macOS

# Accept all licenses
yes | ./sdkmanager --licenses
```

---

## Codecov Issues

### Codecov Upload Fails on Windows

**Symptoms:**
- Error: `sh: command not found`
- Step: "Upload coverage to Codecov" fails
- Only on self-hosted Windows runner

**Root Cause:**
- codecov-action requires bash/sh
- Windows doesn't have sh in default PATH
- Git Bash exists but not in service PATH

**Current Solution (Implemented):**
```yaml
- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v5
  with:
    fail_ci_if_error: false  # Don't fail workflow
  continue-on-error: true     # Allow step to fail
```

**Impact:**
- Coverage still uploaded via PR comment (JaCoCo summary)
- Coverage HTML artifacts available for download
- Codecov is redundant, non-blocking failure acceptable

**Alternative Solutions (Not Recommended):**

**Add Git Bash to service PATH:**
```powershell
# Requires runner reinstall, brittle
[Environment]::SetEnvironmentVariable("PATH", "C:\Program Files\Git\bin;$env:PATH", "Machine")
.\svc.sh uninstall
.\svc.sh install
.\svc.sh start
```

**Use PowerShell-based upload:**
```yaml
# Would require custom script, not worth complexity
```

### Coverage Not Uploaded

**Symptoms:**
- Codecov succeeds but no coverage on Codecov.io
- PR comment shows coverage but Codecov dashboard empty

**Diagnosis:**
```bash
# Check if CODECOV_TOKEN is set (optional for public repos)
gh secret list | grep CODECOV_TOKEN

# Check Codecov step logs
gh run view <run-id> --log | grep -A 20 "Upload coverage to Codecov"
```

**Solution:**

**Missing token (private repos):**
1. Get token from https://codecov.io/gh/blamechris/archery-apprentice
2. Add as secret: `gh secret set CODECOV_TOKEN`
3. Update workflow:
   ```yaml
   - uses: codecov/codecov-action@v5
     with:
       token: ${{ secrets.CODECOV_TOKEN }}
   ```

**Wrong file path:**
```yaml
# Verify coverage file exists
- uses: codecov/codecov-action@v5
  with:
    files: app/build/reports/jacoco/jacocoTestReport/jacocoTestReport.xml
    fail_ci_if_error: true  # Re-enable to debug
```

---

## Authentication Issues

### Google Sign-In Fails After Deployment

**Symptoms:**
- App deployed to Play Store successfully
- Users can install but Google Sign-In fails
- Error: "Sign in failed" or "API key mismatch"

**Root Cause:**
- Firebase expects app signing SHA-1 certificate hash
- App signing certificate managed by Google Play (different from upload cert)
- Upload cert SHA-1 ≠ App signing cert SHA-1

**Diagnosis:**

1. **Get app signing SHA-1 from Play Console:**
   - https://play.google.com/console
   - Select app → Setup → App integrity
   - Copy SHA-1 from "App signing key certificate"

2. **Check Firebase registered SHA-1s:**
   - https://console.firebase.google.com
   - Select project → Project settings
   - Scroll to "Your apps" → Android app
   - Check "SHA certificate fingerprints"

3. **Compare:**
   ```
   Play Console App Signing SHA-1: A1:B2:C3:D4:E5:F6:...
   Firebase Registered SHA-1s:
     - A1:B2:C3:D4:E5:F6:...  ✅ MATCH (correct)
     - X1:Y2:Z3:...          ❌ Old/upload cert (wrong)
   ```

**Solution:**

**Add app signing SHA-1 to Firebase:**
1. Copy SHA-1 from Play Console → App integrity
2. Firebase Console → Project settings → Android app
3. Click "Add fingerprint"
4. Paste SHA-1
5. Click "Save"

**Wait for propagation:**
- Changes take 5-15 minutes to propagate
- Test Google Sign-In after waiting

**Regenerate google-services.json:**
1. Firebase Console → Project settings
2. Scroll to "Your apps" → Android app
3. Click "google-services.json" download button
4. Update secret:
   ```bash
   cat google-services.json | gh secret set GOOGLE_SERVICES_JSON
   ```
5. Re-deploy (or wait for next deployment)

### OAuth Client Mismatch

**Symptoms:**
- Error: "OAuth client not found"
- google-services.json verification fails
- No Android OAuth clients in config

**Diagnosis:**
```bash
# Check workflow logs for verification step
gh run view <run-id> --log | grep -A 10 "Verify google-services.json"

# Expected:
#   - Android clients (type 1): 1
#   - Web clients (type 3): 1
```

**Solution:**

1. **Add OAuth clients in Firebase Console:**
   - https://console.firebase.google.com
   - Select project → Authentication → Sign-in method
   - Enable Google provider
   - Add Android OAuth client:
     - Package name: com.archeryapprentice
     - SHA-1: (app signing SHA-1 from Play Console)

2. **Download updated google-services.json:**
   ```bash
   # Download from Firebase Console
   cat google-services.json | gh secret set GOOGLE_SERVICES_JSON
   ```

3. **Verify locally:**
   ```bash
   # Check for client_type: 1 (Android) and 3 (Web)
   grep -c '"client_type": 1' google-services.json  # Should be >= 1
   grep -c '"client_type": 3' google-services.json  # Should be >= 1
   ```

---

## Discord Notification Issues

### Notifications Not Sent

**Symptoms:**
- Workflow succeeds but no Discord message
- Discord step shows "skipped"

**Diagnosis:**

1. **Check Discord step condition:**
   ```yaml
   - name: Notify Discord (Windows)
     if: success() && runner.os == 'Windows'  # Only runs on Windows

   - name: Notify Discord (Linux/macOS)
     if: success() && runner.os != 'Windows'  # Only runs on non-Windows
   ```

2. **Verify runner OS:**
   ```bash
   gh run view <run-id> --log | grep "Runner name"
   # Self-hosted Windows: runner.os == 'Windows'
   # ubuntu-latest: runner.os == 'Linux'
   ```

**Solution:**

**Wrong platform step executed:**
- If Windows runner used Linux step (or vice versa), check workflow file
- Ensure both platform-specific steps exist

**Missing secret:**
```bash
# Check if DISCORD_WEBHOOK_URL is set
gh secret list | grep DISCORD_WEBHOOK_URL

# If missing, add it
gh secret set DISCORD_WEBHOOK_URL
# Paste webhook URL from Discord Server Settings → Integrations → Webhooks
```

### Discord Notification Format Broken

**Symptoms:**
- Notification sent but formatting is broken
- Message shows raw JSON or escaped characters

**Root Cause:**
- JSON payload generation differs between curl (Linux) and Invoke-RestMethod (Windows)
- Incorrect escaping or quoting

**Diagnosis:**
```bash
# Check Discord step logs
gh run view <run-id> --log | grep -A 50 "Notify Discord"
```

**Windows PowerShell format:**
```powershell
$payload = @{
  embeds = @(
    @{
      title = "Title"
      description = "Description"
      fields = @(
        @{
          name = "Field"
          value = "Value"
        }
      )
    }
  )
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri $env:DISCORD_WEBHOOK_URL -Method Post -Body $payload -ContentType "application/json"
```

**Linux/macOS curl format:**
```bash
curl -H "Content-Type: application/json" \
-d "{
  \"embeds\": [{
    \"title\": \"Title\",
    \"description\": \"Description\",
    \"fields\": [
      {
        \"name\": \"Field\",
        \"value\": \"Value\"
      }
    ]
  }]
}" \
"$DISCORD_WEBHOOK_URL"
```

**Common issues:**
- Missing `-Depth 10` in ConvertTo-Json (Windows)
- Missing backslash escapes in curl JSON (Linux)
- Variables not interpolated correctly

---

## Robolectric Issues

### Robolectric Download Timeout

**Symptoms:**
- Test failures with network errors
- Error: "Failed to download Robolectric SDK"
- Only first run after cache clear

**Root Cause:**
- Robolectric downloads Android SDK binaries (~500MB)
- Network timeout or slow connection

**Solution:**

**Increase timeout (temporary):**
```yaml
# In android-ci.yml or deploy-to-play-store.yml
- name: Run unit tests
  run: ./gradlew testDebugUnitTest
  timeout-minutes: 30  # Increase from 20
```

**Use cache (permanent):**
```yaml
# Already implemented in workflows
- name: Cache Robolectric dependencies
  uses: actions/cache@v4
  with:
    path: |
      ~/.m2/repository/org/robolectric/
      ~/.robolectric/
      .robolectric/
    key: ${{ runner.os }}-robolectric-${{ hashFiles('**/*.gradle*') }}
```

**Manual pre-download (self-hosted):**
```bash
# Run once on self-hosted runner
cd C:\actions-runner\_work\archery-apprentice\archery-apprentice
CI=true ./gradlew testDebugUnitTest --info

# Robolectric will download to:
# Windows: C:\Users\USERNAME\.robolectric\
# Linux/macOS: ~/.robolectric/
```

### Robolectric Version Mismatch

**Symptoms:**
- Error: "Robolectric version X.X.X not compatible with Android API YY"
- Tests fail with SDK version errors

**Solution:**

**Update Robolectric version:**
```kotlin
// app/build.gradle.kts
testImplementation("org.robolectric:robolectric:4.11.1")  // Update version
```

**Set compatible SDK version:**
```kotlin
// app/build.gradle.kts
testOptions {
    unitTests.all { test ->
        test.systemProperty("robolectric.sdk", "35")  // Match compil eSdk
    }
}
```

---

## Coverage and Reporting

### Coverage Report Missing

**Symptoms:**
- Coverage step succeeds but no artifacts
- PR comment shows "Coverage: N/A"

**Diagnosis:**
```bash
# Check if coverage task ran
gh run view <run-id> --log | grep "jacocoTestReport"

# Check artifacts
gh run view <run-id> | grep -A 5 "Artifacts"
```

**Solution:**

**Coverage task not run:**
```yaml
# Verify workflow runs coverage task
- name: Generate coverage report
  run: ./gradlew jacocoTestReport
```

**Output directory wrong:**
```yaml
# Verify artifact upload path
- uses: actions/upload-artifact@v4
  with:
    name: coverage-reports
    path: |
      app/build/reports/jacoco/jacocoTestReport/html
      app/build/reports/jacoco/jacocoTestReport/jacocoTestReport.xml
```

**JaCoCo plugin not applied:**
```kotlin
// app/build.gradle.kts
plugins {
    id("jacoco")
}
```

### Coverage Percentage Incorrect

**Symptoms:**
- Coverage shows 100% but code clearly untested
- Coverage shows 0% but tests exist

**Root Cause:**
- JaCoCo configuration excludes wrong files
- Generated code not excluded

**Solution:**

**Review exclusions:**
```kotlin
// app/build.gradle.kts
tasks.jacocoTestReport {
    classDirectories.setFrom(
        files(classDirectories.files.map {
            fileTree(it) {
                exclude(
                    "**/R.class",
                    "**/R\$*.class",
                    "**/BuildConfig.*",
                    "**/Manifest*.*",
                    "**/*Test*.*",
                    "android/**/*.*",
                    "**/*\$Lambda$*.*",
                    "**/*Companion*.*",
                    "**/*\$Result.*",
                    "**/*\$Result$*.*",
                    "**/*_Factory.*",
                    "**/*_MembersInjector.*"
                )
            }
        })
    )
}
```

---

## Workflow Trigger Issues

### Workflow Not Triggering

**Symptoms:**
- Push/PR created but workflow doesn't run
- Workflow tab shows no recent runs

**Diagnosis:**

1. **Check workflow file location:**
   ```bash
   ls -la .github/workflows/
   # Must be in .github/workflows/ (not .github/workflow/)
   ```

2. **Check YAML syntax:**
   ```bash
   # Use GitHub Actions UI to validate
   # Or: yq eval '.name' .github/workflows/android-ci.yml
   ```

3. **Check paths-ignore:**
   ```yaml
   on:
     pull_request:
       paths-ignore:
         - '**.md'  # Ignores all markdown files
   ```

**Solution:**

**Syntax error:**
```bash
# Validate YAML
gh workflow view android-ci.yml
# Fix any errors reported
```

**paths-ignore too broad:**
```yaml
# If only changed files match paths-ignore, workflow won't run
# Option 1: Remove paths-ignore
# Option 2: Override with [github] flag in commit message
git commit -m "docs: Update README [github]"
```

### Workflow Skipped by [skip-ci]

**Symptoms:**
- Workflow shows "Skipped" status
- decide_runner sets should_skip=true

**Diagnosis:**
```bash
# Check commit message
git log -1 --pretty=format:'%s'
# Look for [skip-ci] or [ci-skip]
```

**Solution:**

**Unintentional skip:**
```bash
# Amend commit message
git commit --amend -m "New commit message without [skip-ci]"
git push --force-with-lease
```

**Intentional skip, want to re-run:**
```bash
# Trigger manually via workflow dispatch
gh workflow run android-ci.yml -f runner_mode=auto
```

---

## Versioning Issues

### Version Code Conflict

**Symptoms:**
- Play Store deployment fails
- Error: "Version code X already exists"

**Root Cause:**
- Same GitHub run number used twice (re-run)
- Manual upload with same version code

**Diagnosis:**
```bash
# Check latest deployed version
# Play Console → Release → Internal testing → View releases

# Check workflow run number
gh run view <run-id> | grep "Run #"
# Version code = BASE_VERSION + run_number
```

**Solution:**

**Increment BASE_VERSION:**
```yaml
# .github/workflows/deploy-to-play-store.yml
env:
  BASE_VERSION: 5  # Increment from 4 to 5
```

**Wait for next run:**
```bash
# Each new run increments run_number
# Next run will have version code: BASE_VERSION + (run_number + 1)
```

### Version Name Not Updated

**Symptoms:**
- Version code increments but version name stays same
- Play Store shows old version name

**Root Cause:**
- versionName is static in build.gradle.kts
- Only versionCode is auto-incremented

**Solution:**

**Manual version name update:**
```kotlin
// app/build.gradle.kts
android {
    defaultConfig {
        versionCode = 4  // Auto-updated by workflow
        versionName = "1.1.0"  // Manually update before release
    }
}
```

**Semantic versioning pattern:**
- 1.0.0 → Initial release
- 1.1.0 → New features added
- 1.1.1 → Bug fixes
- 2.0.0 → Breaking changes

---

## Build Failures

### Gradle Build Timeout

**Symptoms:**
- Build exceeds time limit (30 minutes)
- Error: "The job running on runner X has exceeded the maximum execution time"

**Solution:**

**Increase timeout:**
```yaml
- name: Build release AAB
  run: ./gradlew bundleRelease
  timeout-minutes: 45  # Increase from 30
```

**Optimize Gradle:**
```bash
# Add to gradle.properties
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configureondemand=true
org.gradle.jvmargs=-Xmx6g -XX:MaxMetaspaceSize=2g -XX:+UseG1GC
```

### Out of Memory Error

**Symptoms:**
- Error: "OutOfMemoryError: Java heap space"
- Build fails during compilation or minification

**Solution:**

**Increase heap size:**
```yaml
# In workflow file
- name: Build release AAB
  env:
    GRADLE_OPTS: "-Xmx8g -XX:MaxMetaspaceSize=2g"  # Increase from 6g to 8g
  run: ./gradlew bundleRelease
```

**Disable daemon in CI:**
```yaml
- run: ./gradlew bundleRelease --no-daemon
# Daemon can consume extra memory, disabled in CI
```

---

## Quartz Deployment Issues

### Deployment Succeeds But Site Not Updated

**Symptoms:**
- deploy-quartz.yml succeeds
- Discord notification sent
- But site still shows old content

**Diagnosis:**

1. **Check gh-pages branch:**
   ```bash
   git fetch origin gh-pages
   git log origin/gh-pages -1
   # Should show recent commit from github-actions[bot]
   ```

2. **Check GitHub Pages settings:**
   - Repository → Settings → Pages
   - Source: "Deploy from a branch"
   - Branch: "gh-pages" / "(root)"

3. **Check for build errors:**
   ```bash
   gh run view <run-id> --log | grep -i error
   ```

**Solution:**

**GitHub Pages cache:**
- Wait 2-3 minutes for cache to clear
- Force refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)

**gh-pages not deployed:**
```bash
# Manually trigger deployment
gh workflow run deploy-quartz.yml
```

**Build errors:**
```bash
# Check Quartz build output
gh run view <run-id> --log | grep -A 20 "Build Quartz site"
```

### Timestamp Not Updated

**Symptoms:**
- Site deployed but "Last Updated" timestamp unchanged

**Diagnosis:**
```bash
# Check if timestamp step ran
gh run view <run-id> --log | grep "Updated timestamp"
```

**Solution:**

**Step skipped (wrong platform):**
```yaml
# Verify both platform-specific steps exist
- name: Update deployment timestamp (Windows)
  if: runner.os == 'Windows'
  # ...

- name: Update deployment timestamp (Linux/macOS)
  if: runner.os != 'Windows'
  # ...
```

**Regex doesn't match:**
```bash
# Check content/index.md format
grep "Last Updated" content/index.md

# Expected: **📅 Last Updated:** 2025-10-24 01:30 PM PT
# Regex: \*\*📅 Last Updated:\*\* .*
```

---

## Debugging Workflow Runs

### Enable Debug Logging

**Re-run with debug logging:**
```bash
# Add secrets to repository
gh secret set ACTIONS_RUNNER_DEBUG --body "true"
gh secret set ACTIONS_STEP_DEBUG --body "true"

# Re-run workflow
gh run rerun <run-id>

# View debug logs
gh run view <run-id> --log
```

### Download All Artifacts

```bash
# List artifacts from run
gh run view <run-id>

# Download all artifacts
gh run download <run-id>

# Download specific artifact
gh run download <run-id> -n coverage-reports
```

### View Specific Job Logs

```bash
# List jobs in run
gh run view <run-id>

# View specific job log
gh run view <run-id> --job <job-id>

# View failed job logs only
gh run view <run-id> --log-failed
```

---

## Prevention Best Practices

### Before Merging Workflow Changes

1. **Test on GitHub-hosted first:**
   ```bash
   git commit -m "feat: Update workflow [github]"
   # Cheap to fail, fast feedback
   ```

2. **Validate YAML syntax:**
   ```bash
   gh workflow view <workflow-name>
   # Reports syntax errors
   ```

3. **Test platform-specific steps:**
   - Run on self-hosted (Windows) with `[self-hosted]` flag
   - Verify both Windows and Linux steps execute correctly

### Regular Maintenance

**Weekly:**
- Check runner status (Settings → Actions → Runners)
- Review recent workflow failures
- Monitor quota usage (Settings → Billing)

**Monthly:**
- Clean Gradle cache on self-hosted runner
- Update runner to latest version
- Review and clean old workflow runs

**Quarterly:**
- Update Gradle version
- Update GitHub Actions versions
- Review and optimize caching strategies

---

## Getting Help

### Logs to Provide

When reporting issues, include:

1. **Workflow run URL:**
   ```
   https://github.com/blamechris/archery-apprentice/actions/runs/12345678
   ```

2. **Failed step logs:**
   ```bash
   gh run view 12345678 --log-failed > failed-logs.txt
   ```

3. **Runner diagnostics:**
   ```bash
   # Self-hosted runner logs
   cat ~/actions-runner/_diag/Runner_*.log | tail -100 > runner-logs.txt
   ```

4. **Environment info:**
   ```bash
   # Runner OS, runner label, day of month
   ```

### Common Commands Reference

```bash
# List recent runs
gh run list --limit 20

# View run details
gh run view <run-id>

# Re-run failed run
gh run rerun <run-id>

# Cancel running workflow
gh run cancel <run-id>

# Watch run in real-time
gh run watch <run-id>

# Trigger workflow manually
gh workflow run <workflow-name>

# List workflows
gh workflow list

# View workflow file
gh workflow view <workflow-name>
```

---

## Related Documentation

- [[Hybrid-Runner-System|Hybrid Runner System]] - Runner setup and configuration
- [[Workflows-Overview|Workflows Overview]] - Detailed workflow documentation
- [[Maintenance-Tasks|Maintenance Tasks]] - Regular maintenance procedures

**External Resources:**
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Gradle Performance Guide](https://docs.gradle.org/current/userguide/performance.html)
- [Robolectric Documentation](http://robolectric.org/)
- [JaCoCo Documentation](https://www.jacoco.org/jacoco/trunk/doc/)

---

**Tags:** #ci-cd #troubleshooting #github-actions #debugging
**Status:** ✅ Comprehensive troubleshooting guide
**Last Updated:** 2025-10-24
