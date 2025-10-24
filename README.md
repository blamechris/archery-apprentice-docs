# Archery Apprentice Documentation

This repository contains the Obsidian vault for Archery Apprentice project documentation, deployed as a static site using [Quartz](https://quartz.jzhao.xyz/).

**Live Site:** https://blamechris.github.io/archery-apprentice-docs/

---

## Quick Start

### Local Development

```bash
# Install dependencies
npm install

# Preview locally
npx quartz build --serve
# Opens at http://localhost:8080
```

### Deploy to Production

**Method 1: Automatic (on merge to main)**
- Any push to `main` branch triggers GitHub Actions deployment
- Workflow: `.github/workflows/deploy-quartz.yml`
- Uses self-hosted runner on days 22-31, GitHub-hosted on days 1-21

**Method 2: Manual (using deploy script)**
```powershell
# From PowerShell
.\deploy.ps1
```

**Method 3: Manual (GitHub Actions)**
```bash
# Trigger workflow manually
gh workflow run deploy-quartz.yml

# Or with specific runner
gh workflow run deploy-quartz.yml -f runner_mode=self-hosted
gh workflow run deploy-quartz.yml -f runner_mode=github
```

---

## Self-Hosted Runner Setup

**When needed:** Private repos with quota limits, or for faster local builds during quota exhaustion.

### Prerequisites

- Windows 10/11, Ubuntu 20.04+, or macOS 11+
- Admin/sudo access
- Node.js 20+ (for Quartz builds)

### Installation (Windows)

#### 1. Create runner directory

```powershell
mkdir C:\actions-runner-docs
cd C:\actions-runner-docs
```

#### 2. Download runner

```powershell
# Download Windows x64 runner (check for latest version at https://github.com/actions/runner/releases)
Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-win-x64-2.311.0.zip -OutFile actions-runner-win-x64-2.311.0.zip

# Extract
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD/actions-runner-win-x64-2.311.0.zip", "$PWD")
```

#### 3. Get registration token

1. Go to: https://github.com/blamechris/archery-apprentice-docs/settings/actions/runners/new
2. Copy the registration token from the page

#### 4. Configure and install runner

```powershell
# Configure runner
.\config.cmd --url https://github.com/blamechris/archery-apprentice-docs `
             --token YOUR_REGISTRATION_TOKEN `
             --name "archery-docs-runner-1" `
             --labels "self-hosted,Windows,X64" `
             --work _work

# When prompted:
# - Runner group: [press Enter for Default]
# - Runner name: [press Enter to use "archery-docs-runner-1"]
# - Additional labels: [press Enter to skip]
# - Work folder: [press Enter for "_work"]
# - Run as service: Y
# - User account: [press Enter for NT AUTHORITY\NETWORK SERVICE]

# Service is automatically installed and started
```

#### 5. Verify runner

Check: https://github.com/blamechris/archery-apprentice-docs/settings/actions/runners

You should see your runner name with a green "Idle" status.

### Installation (Linux/macOS)

```bash
# Create runner directory
mkdir -p ~/actions-runner-docs
cd ~/actions-runner-docs

# Download runner (Linux x64)
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

# Extract
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# Configure runner
./config.sh --url https://github.com/blamechris/archery-apprentice-docs \
            --token YOUR_REGISTRATION_TOKEN \
            --name "archery-docs-runner-1" \
            --labels "self-hosted,Linux,X64" \
            --work _work

# Install as service
sudo ./svc.sh install

# Start service
sudo ./svc.sh start

# Verify
sudo ./svc.sh status
```

### Managing the Runner Service

**Windows:**
```powershell
cd C:\actions-runner-docs

# Check status
.\svc.sh status

# Start service
.\svc.sh start

# Stop service
.\svc.sh stop

# Restart service
.\svc.sh restart

# Uninstall service
.\svc.sh uninstall
```

**Linux/macOS:**
```bash
cd ~/actions-runner-docs

# Check status
sudo ./svc.sh status

# Start service
sudo ./svc.sh start

# Stop service
sudo ./svc.sh stop

# Restart service
sudo ./svc.sh restart

# Uninstall service
sudo ./svc.sh uninstall
```

### Removing the Runner

```powershell
# Windows
cd C:\actions-runner-docs
.\svc.sh stop
.\svc.sh uninstall
.\config.cmd remove --token YOUR_REMOVAL_TOKEN

# Linux/macOS
cd ~/actions-runner-docs
sudo ./svc.sh stop
sudo ./svc.sh uninstall
./config.sh remove --token YOUR_REMOVAL_TOKEN
```

Get removal token from: https://github.com/blamechris/archery-apprentice-docs/settings/actions/runners

---

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy-quartz.yml    # Automated deployment workflow
├── content/                      # Quartz content (symlink to root)
├── Development/
│   └── CI-CD/                   # CI/CD documentation
│       ├── Hybrid-Runner-System.md
│       ├── Workflows-Overview.md
│       ├── Troubleshooting-Guide.md
│       └── Maintenance-Tasks.md
├── Architecture/                 # System architecture docs
├── Flows/                        # User flows and diagrams
├── Code-Graph/                   # Code structure and relationships
├── projects/                     # Project-specific documentation
├── quartz/                       # Quartz framework
├── quartz.config.ts             # Quartz configuration
├── deploy.ps1                    # Manual deployment script
├── package.json                  # Node.js dependencies
└── README.md                     # This file
```

---

## Workflow Configuration

### Hybrid Runner System

The deploy workflow (`.github/workflows/deploy-quartz.yml`) uses a hybrid runner strategy:

**Automatic Mode (default):**
- **Days 1-21:** Uses GitHub-hosted runners (`ubuntu-latest`)
- **Days 22-31:** Uses self-hosted runner (conserve quota)

**Manual Overrides:**

Via commit message flags:
```bash
git commit -m "docs: Update content [self-hosted]"  # Force self-hosted
git commit -m "docs: Update content [github]"       # Force GitHub-hosted
git commit -m "docs: Update content [skip-ci]"      # Skip CI entirely
```

Via workflow dispatch (GitHub Actions UI):
1. Actions tab → Deploy Quartz to GitHub Pages
2. Run workflow → Select runner_mode:
   - `auto` (default) - Day-based selection
   - `self-hosted` - Force self-hosted
   - `github` - Force GitHub-hosted
   - `skip` - Skip workflow

### Deployment Process

When triggered, the workflow:

1. **Selects runner** (decide_runner job, ~4s)
2. **Builds site** (deploy job, ~5-8 min):
   - Checks out repository
   - Sets up Node.js 20
   - Installs dependencies (`npm install`)
   - Updates deployment timestamp in `content/index.md`
   - Builds Quartz site (`npx quartz build`)
   - Deploys to `gh-pages` branch
   - Sends Discord notification (success/failure)

3. **GitHub Pages deploys** (~2-3 min)
   - Site available at: https://blamechris.github.io/archery-apprentice-docs/

**Total time from push to live:** ~8-12 minutes

---

## Troubleshooting

### Workflow stuck "Waiting for runner"

**Cause:** No self-hosted runner available for this repository

**Solution:**
1. Check runner status: https://github.com/blamechris/archery-apprentice-docs/settings/actions/runners
2. If offline, restart runner service (see "Managing the Runner Service" above)
3. If no runner exists, follow "Self-Hosted Runner Setup" above
4. Or override to use GitHub-hosted: `gh workflow run deploy-quartz.yml -f runner_mode=github`

### Discord notification not sent

**Cause:** Platform-specific step skipped (Windows vs Linux)

**Solution:** Verify `DISCORD_WEBHOOK_URL` secret is set:
```bash
gh secret list | grep DISCORD_WEBHOOK_URL

# If missing, add it:
gh secret set DISCORD_WEBHOOK_URL
# Paste webhook URL from Discord Server Settings → Integrations → Webhooks
```

### Site not updating after deployment

**Cause:** GitHub Pages cache or build errors

**Solution:**
1. Wait 2-3 minutes for GitHub Pages to refresh
2. Hard refresh browser: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
3. Check workflow logs for errors:
   ```bash
   gh run list --workflow=deploy-quartz.yml --limit 1
   gh run view <run-id> --log
   ```

### Timestamp not updated

**Cause:** Platform-specific step didn't run

**Solution:** Verify both Windows and Linux timestamp steps exist in workflow (`.github/workflows/deploy-quartz.yml:89-102`)

---

## Development Workflow

### Adding New Documentation

1. **Create/edit files in Obsidian vault** (this repository)
2. **Commit changes:**
   ```bash
   git add .
   git commit -m "docs: Add new documentation"
   git push
   ```
3. **Deployment happens automatically** via GitHub Actions
4. **Verify deployment** at https://blamechris.github.io/archery-apprentice-docs/

### Local Preview Before Deploying

```bash
# Build and serve locally
npx quartz build --serve

# Opens at http://localhost:8080
# Ctrl+C to stop
```

### Manual Deployment (Without Pushing)

```powershell
# Using deploy script
.\deploy.ps1

# Or manually
npx quartz build
# Then manually commit and push to gh-pages branch
```

---

## GitHub Actions Quota

**Free tier:** 3000 minutes/month (private repos)

**This workflow usage:**
- ~5-8 minutes per deployment
- ~2-3 deployments/month typical
- **Total:** ~15-25 minutes/month

**Quota conservation strategies:**
1. Hybrid runner system (automatic on days 22-31)
2. Self-hosted runner (zero quota usage)
3. Skip CI for minor changes: `[skip-ci]` flag
4. Manual trigger instead of auto-deploy

---

## Related Documentation

**In this repo:**
- [Hybrid Runner System](Development/CI-CD/Hybrid-Runner-System.md)
- [Workflows Overview](Development/CI-CD/Workflows-Overview.md)
- [Troubleshooting Guide](Development/CI-CD/Troubleshooting-Guide.md)
- [Maintenance Tasks](Development/CI-CD/Maintenance-Tasks.md)

**Main repo (archery-apprentice):**
- [Self-Hosted Runner Setup](https://github.com/blamechris/archery-apprentice/blob/main/docs/SELF_HOSTED_RUNNER_SETUP.md)
- [CLAUDE.md CI/CD Section](https://github.com/blamechris/archery-apprentice/blob/main/CLAUDE.md)

**External:**
- [Quartz Documentation](https://quartz.jzhao.xyz/)
- [GitHub Actions Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)

---

**Last Updated:** 2025-10-24
**Maintained By:** @blamechris
