# Branch Protection Configuration

**Repository:** archery-apprentice (main repo)
**Protected Branch:** `main`
**Last Updated:** 2025-10-24

## Required Status Checks

### ✅ Required: `test_and_coverage`

**Purpose:** Primary quality gate that ensures code meets quality standards before merge.

**What It Does:**
- Builds both debug and release APKs
- Runs full unit test suite (`testDebugUnitTest`)
- Generates code coverage reports with JaCoCo
- Posts coverage report to PR
- **Blocks merge if tests fail** ✅

**Configuration:**
```
Settings → Branches → Branch protection rules → main
☑️ Require status checks to pass before merging
☑️ Require branches to be up to date before merging
☑️ test_and_coverage
```

**Typical Duration:** 5-8 minutes

---

### ⚪ Optional: `quick_checks`

**Purpose:** Early feedback on lint and configuration issues.

**What It Does:**
- Validates Gradle wrapper security
- Verifies `google-services.json` configuration
- Runs Android lint
- **Does NOT block merge** (lint uses `continue-on-error: true`)

**Why It's Optional:**
Lint failures don't block the job, so this check always passes. It's useful for early visibility but not a true quality gate.

---

### ❌ Do NOT Require: `decide_runner`

**Purpose:** Infrastructure job that determines which runner to use (self-hosted vs GitHub-hosted).

**Why Not Required:**
- Not a quality check
- Just selects runner based on date/quota
- Other jobs depend on it, so it will run anyway
- Requiring it adds no value

---

## Migration from Old Configuration

### Before (Pre-PR#137)
```
Required status checks:
- build-and-test  (old job name)
```

### After (Current)
```
Required status checks:
- test_and_coverage  (new job name)
```

**Action Required:** Update branch protection rules to replace `build-and-test` with `test_and_coverage`.

---

## Workflow Job Architecture

### Job Dependency Chain
```
decide_runner (infrastructure)
    ↓
    ├── quick_checks (optional, non-blocking)
    └── test_and_coverage (REQUIRED, blocks merge)
```

### Job Responsibilities

| Job | Type | Blocking | Purpose |
|-----|------|----------|---------|
| `decide_runner` | Infrastructure | N/A | Select runner (self-hosted vs GitHub) |
| `quick_checks` | Validation | No* | Lint + config verification |
| `test_and_coverage` | Quality Gate | **Yes** | Build + Test + Coverage |

*`quick_checks` uses `continue-on-error` for lint, so it never fails.

---

## Status Check Best Practices

### ✅ DO Require
- Jobs that run tests
- Jobs that validate build integrity
- Jobs that check code quality (if blocking)

### ❌ DO NOT Require
- Infrastructure jobs (runner selection, setup)
- Jobs with `continue-on-error: true` (they always pass)
- Jobs that only provide informational output

---

## Troubleshooting

### "Required status check is missing"

**Cause:** Old `build-and-test` check still configured but job was renamed.

**Solution:**
1. Go to Settings → Branches → Edit branch protection rule
2. Remove `build-and-test` from required checks
3. Add `test_and_coverage` to required checks
4. Save changes

### "Status check never completes"

**Cause:** Job skipped due to `[skip-ci]` flag or path filters.

**Solution:**
- Check PR title/commit message for `[skip-ci]`
- Verify changed files aren't all in `paths-ignore` filters
- Check workflow logs for skip messages

---

## References

- **Android CI Workflow:** `.github/workflows/android-ci.yml`
- **PR Discussion:** PR#137 review comments
- **Related:** [[Workflows-Overview]], [[Hybrid-Runner-System]]

---

**Last Updated:** 2025-10-24
**Maintained By:** @blamechris
