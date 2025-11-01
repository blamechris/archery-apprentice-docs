# Hybrid GitHub Actions Runner Implementation Guide

**Date:** 2025-10-23  
**Purpose:** Add intelligent runner selection to manage GitHub Actions minutes quota (3000/month)

---

## Overview

This implementation adds hybrid runner support to Android CI/CD workflows:
- Defaults to GitHub-hosted runners (`ubuntu-latest`)
- Honors commit message flags: `[self-hosted]`, `[github]`, `[skip-ci]`
- Automatically switches to self-hosted after day 20 of month
- Supports manual workflow dispatch override
- Splits jobs: fast checks on GitHub, heavy work on selected runner

---

## Implementation Summary

### Changes Made

1. **android-ci.yml**
   - Added `workflow_dispatch` trigger with runner selection
   - Added `decide_runner` job for runner selection logic
   - Split into 3 jobs: `quick_checks`, `test_and_coverage`, `build_artifacts`
   - Preserved all caching, artifacts, Codecov integration

2. **deploy-to-play-store.yml**
   - Added `workflow_dispatch` trigger with runner selection
   - Added `decide_runner` job
   - Renamed `deploy` → `build_and_deploy` with runner selection
   - Preserved all keystore, signing, deployment steps

3. **documentation-reminder.yml**
   - No changes (lightweight, stays GitHub-hosted)

---

## android-ci.yml - Complete Updated File

Due to file writing issues in the tool, here are the key sections to add/modify:

### Add to `on:` trigger section:
```yaml
on:
  pull_request:
    branches: [main]
    paths-ignore:
      # ... existing paths-ignore ...
  workflow_dispatch:    # ADD THIS
    inputs:
      runner_mode:
        description: 'Runner selection'
        required: false
        default: 'auto'
        type: choice
        options:
          - auto
          - self-hosted
          - github
          - skip
```

### Add new `decide_runner` job (before all other jobs):
```yaml
jobs:
  decide_runner:
    runs-on: ubuntu-latest
    outputs:
      runner_label: ${{ steps.decision.outputs.runner_label }}
      should_skip: ${{ steps.decision.outputs.should_skip }}
    steps:
      - name: Determine runner
        id: decision
        run: |
          COMMIT_MSG="${{ github.event.head_commit.message || github.event.pull_request.title }}"
          INPUT_MODE="${{ github.event.inputs.runner_mode || 'auto' }}"
          RUNNER="ubuntu-latest"
          SKIP="false"

          # Check skip flags
          if [[ "$COMMIT_MSG" =~ \[skip-ci\]|\[ci-skip\] ]] || [[ "$INPUT_MODE" == "skip" ]]; then
            echo "should_skip=true" >> $GITHUB_OUTPUT
            echo "runner_label=ubuntu-latest" >> $GITHUB_OUTPUT
            echo "::notice::CI skipped due to [skip-ci] flag"
            exit 0
          fi

          # Explicit overrides
          if [[ "$COMMIT_MSG" =~ \[self-hosted\] ]] || [[ "$INPUT_MODE" == "self-hosted" ]]; then
            RUNNER="self-hosted"
            echo "::notice::Using self-hosted runner (explicit override)"
          elif [[ "$COMMIT_MSG" =~ \[github\] ]] || [[ "$INPUT_MODE" == "github" ]]; then
            RUNNER="ubuntu-latest"
            echo "::notice::Using GitHub-hosted runner (explicit override)"
          elif [[ "$INPUT_MODE" == "auto" ]]; then
            # Auto mode: Use day-of-month heuristic
            DAY=$(date +%d)
            if [ "$DAY" -gt 20 ]; then
              echo "::notice::Late in month (day $DAY), using self-hosted to conserve quota"
              RUNNER="self-hosted"
            else
              echo "::notice::Early in month (day $DAY), using GitHub-hosted"
              RUNNER="ubuntu-latest"
            fi
          fi

          echo "should_skip=false" >> $GITHUB_OUTPUT
          echo "runner_label=$RUNNER" >> $GITHUB_OUTPUT
          echo "::notice::Selected runner: $RUNNER"
```

### Replace `build-and-test` job with 3 jobs:

#### 1. quick_checks (always GitHub-hosted):
```yaml
  quick_checks:
    runs-on: ubuntu-latest
    needs: decide_runner
    if: needs.decide_runner.outputs.should_skip == 'false'

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: 17

      - name: Grant execute permission for gradlew
        run: chmod +x ./gradlew

      - name: Validate Gradle wrapper
        uses: gradle/actions/wrapper-validation@v4

      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@v4

      - name: Generate google-services.json
        run: |
          echo '${{ secrets.GOOGLE_SERVICES_JSON }}' > app/google-services.json

      - name: Verify google-services.json
        run: |
          # ... existing verification script ...

      - name: Run lint
        run: ./gradlew lint
        continue-on-error: true

      - name: Upload lint reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: lint-reports
          path: |
            app/build/reports/lint-results*.html
            app/build/reports/lint-results*.xml
          retention-days: 7
```

#### 2. test_and_coverage (selected runner):
```yaml
  test_and_coverage:
    runs-on: ${{ needs.decide_runner.outputs.runner_label }}
    needs: [decide_runner, quick_checks]
    if: needs.decide_runner.outputs.should_skip == 'false'

    steps:
      # ... all existing test/coverage steps from original build-and-test ...
      # Include: Checkout, JDK setup, caching, Robolectric, coverage, Codecov
```

#### 3. build_artifacts (selected runner, PR only):
```yaml
  build_artifacts:
    runs-on: ${{ needs.decide_runner.outputs.runner_label }}
    needs: [decide_runner, quick_checks]
    if: |
      needs.decide_runner.outputs.should_skip == 'false' &&
      github.event_name == 'pull_request'

    steps:
      # ... all existing build steps from original build-and-test ...
      # Include: assembleDebug, assembleRelease, testDebugUnitTest
```

---

## deploy-to-play-store.yml - Complete Updated File

### Add to `on:` section:
```yaml
on:
  push:
    branches: [ main ]
  workflow_dispatch:
    inputs:    # MODIFY THIS - add runner_mode
      runner_mode:
        description: 'Runner selection'
        required: false
        default: 'auto'
        type: choice
        options:
          - auto
          - self-hosted
          - github
          - skip
```

### Add `decide_runner` job (same as android-ci.yml):
```yaml
jobs:
  decide_runner:
    runs-on: ubuntu-latest
    outputs:
      runner_label: ${{ steps.decision.outputs.runner_label }}
      should_skip: ${{ steps.decision.outputs.should_skip }}
    steps:
      # ... same decision logic as android-ci.yml ...
```

### Rename `deploy` job to `build_and_deploy` with runner selection:
```yaml
  build_and_deploy:    # RENAMED from 'deploy'
    runs-on: ${{ needs.decide_runner.outputs.runner_label }}    # CHANGED
    needs: decide_runner    # ADDED
    if: needs.decide_runner.outputs.should_skip == 'false'    # ADDED

    steps:
      # ... ALL existing deployment steps unchanged ...
```

---

## Verification Checklist

### android-ci.yml
- [ ] `workflow_dispatch` trigger added with `runner_mode` input
- [ ] `decide_runner` job added (always ubuntu-latest)
- [ ] `quick_checks` job created (always ubuntu-latest)
- [ ] `test_and_coverage` job created (selected runner)
- [ ] `build_artifacts` job created (selected runner, PR only)
- [ ] Job dependencies correct: `needs: [decide_runner, quick_checks]`
- [ ] All caching preserved (Android build cache, Robolectric)
- [ ] Codecov `fail_ci_if_error: true` preserved
- [ ] All artifact uploads preserved (coverage, test reports, lint)
- [ ] All environment variables preserved
- [ ] All `continue-on-error` flags preserved

### deploy-to-play-store.yml
- [ ] `workflow_dispatch` inputs updated with `runner_mode`
- [ ] `decide_runner` job added
- [ ] `deploy` job renamed to `build_and_deploy`
- [ ] Runner selection applied: `runs-on: ${{ needs.decide_runner.outputs.runner_label }}`
- [ ] `needs: decide_runner` dependency added
- [ ] Skip check added: `if: needs.decide_runner.outputs.should_skip == 'false'`
- [ ] All keystore/signing steps preserved
- [ ] All deployment steps preserved
- [ ] Discord notification preserved

---

## Usage Examples

### Commit Message Flags
```bash
# Force self-hosted runner
git commit -m "feat: add new feature [self-hosted]"

# Force GitHub-hosted runner
git commit -m "fix: quick bugfix [github]"

# Skip CI entirely
git commit -m "docs: update README [skip-ci]"
```

### Manual Workflow Dispatch
1. Go to Actions tab → Select workflow
2. Click "Run workflow"
3. Select runner_mode:
   - `auto`: Day > 20 = self-hosted, else GitHub
   - `self-hosted`: Force self-hosted
   - `github`: Force GitHub-hosted
   - `skip`: Skip workflow

### Auto Mode Behavior
- **Day 1-20:** Uses `ubuntu-latest` (GitHub-hosted)
- **Day 21-31:** Uses `self-hosted` to conserve quota
- **Monthly quota:** 3000 minutes

---

## Preserved Functionality

✅ All existing caching strategies
✅ Robolectric dependency management
✅ JaCoCo coverage reports
✅ Codecov integration with strict enforcement
✅ Artifact uploads (test reports, coverage, lint)
✅ Environment variables (CI=true, GRADLE_OPTS, JAVA_OPTS)
✅ Continue-on-error flags
✅ Retention policies (2-7 days)
✅ All if conditions and failure handling
✅ Instrumented test configuration (commented out)
✅ Discord notifications (deployment)
✅ Play Store deployment flow

---

## Notes

1. **Self-hosted runner setup required** before using `self-hosted` mode
2. **Testing**: Start with `[github]` flag to verify changes work
3. **Quota monitoring**: Check usage at Settings → Billing → Actions minutes
4. **Fallback**: Always defaults to `ubuntu-latest` if decision logic fails

---

**Status:** Implementation guide complete
**Next Steps:** Apply changes to workflow files manually
