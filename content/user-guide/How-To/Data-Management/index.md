---
title: "Data Management"
description: "Managing, backing up, and syncing your archery data"
category: "user-guide"
audience: "users"
status: "active"
tags:
  - how-to
  - data
  - sync
  - backup
  - export
  - import
---

[Home](/) > [User Guide](../../) > [How-To](../) > Data Management

---

# Data Management

Archery Apprentice provides comprehensive data management features to help you backup, export, import, share, and sync your archery data across devices. This guide covers all workflows for managing your data safely and effectively.

---

## Overview

Data management features include:
- **Export** - Save rounds, equipment, and analytics to CSV, JSON, or PDF
- **Import** - Load data from external sources with validation
- **Backup** - Create automatic or manual backups of your database
- **Share** - Share data via email, cloud storage, or external apps
- **Cloud Sync** - Synchronize data across devices with Firebase
- **Cleanup** - Archive or delete old rounds to free up storage
- **Offline Mode** - Use the app without internet connectivity

---

## 1. Exporting Your Data

Exporting allows you to save your archery data in standard formats for spreadsheet analysis, external tools, or long-term archival.

### Supported Export Formats

| Format | Use Case | Data Included |
|--------|----------|---------------|
| **CSV** | Spreadsheet analysis, Excel | Round scores, statistics, ring distributions |
| **JSON** | Programming, data analysis, backups | Complete data model with relationships |
| **PDF** | Printing, reports, sharing | Statistics summary, formatted reports |
| **Archery GB** | Competition submission | Archery GB compliant format |
| **WA Ianseo** | World Archery competitions | Ianseo scoring format |

### Export Individual Rounds

**When to use:** Share a single practice session or competition round.

**Steps:**
1. Navigate to **Round Scoring** → **Historical Rounds**
2. Long-press the round you want to export (or tap for details)
3. Tap **Export** from the menu
4. Select export format:
   - **CSV** - For spreadsheets
   - **JSON** - For complete data
   - **PDF** - For printable reports
5. Configure export options:
   - ✅ Include equipment details
   - ✅ Include statistics (X-count, 10-count, etc.)
   - ✅ Include notes and comments
6. Tap **Export**
7. Choose destination (email, cloud storage, download)

**Result:** File saved with name like `Round_IndoorPractice_2025-11-04.csv`

### Export Multiple Rounds

**When to use:** Analyze performance across multiple sessions or backup a date range.

**Steps:**
1. Navigate to **Round Scoring** → **Historical Rounds**
2. Tap the **Select Multiple** icon (checkbox)
3. Select rounds to export (tap each round)
4. Tap **Export Selected** from bottom action bar
5. Choose format (CSV recommended for multi-round analysis)
6. Apply filters (optional):
   - Date range (e.g., "Last 30 days", "January 2025")
   - Distance filter (e.g., "Only 70m rounds")
   - Equipment filter (e.g., "Competition Bow only")
7. Tap **Export**
8. Choose share destination

**Result:** Combined CSV file with all selected rounds.

### Export Equipment Configuration

**When to use:** Share your bow setup with other archers or backup equipment configurations.

**Steps:**
1. Navigate to **Equipment Page**
2. Scroll to **Bow Setups** section
3. Long-press the setup you want to export
4. Tap **Export Setup**
5. Select format:
   - **JSON** - Complete equipment details
   - **PDF** - Printable equipment sheet
6. Tap **Export**
7. Share via email, cloud storage, or save to device

**JSON Export Structure:**
```json
{
  "bowSetup": {
    "name": "Competition Bow",
    "riser": {"brand": "Hoyt", "model": "Formula X", "length": "25 inches"},
    "limbs": {"brand": "Win&Win", "model": "Wiawis One", "poundage": "38 lbs"},
    "sight": {...},
    "stabilizer": {...},
    "arrows": {...}
  },
  "metadata": {
    "exportedAt": "2025-11-04T14:30:00Z",
    "appVersion": "2.0.0"
  }
}
```

### Export Analytics Data

**When to use:** Analyze performance trends in Excel or share statistics reports.

**Steps:**
1. Navigate to **Round Detail** → Tap **View Analytics**
2. Tap the **Export** icon (share icon)
3. Select export type:
   - **Round Statistics** - Single round metrics
   - **Equipment Performance** - Performance by bow setup
   - **Distance Statistics** - Performance by distance
   - **Fatigue Analysis** - Performance drop metrics
   - **Shot Grouping** - Grouping metrics (requires target face scoring)
4. Choose format:
   - **CSV** - For Excel/Google Sheets
   - **JSON** - For programmatic analysis
5. Apply date range filter (if applicable)
6. Tap **Export**
7. Share via preferred method

**CSV Export Example:**
```csv
Date,Round Name,Distance,Target Size,Total Score,Avg per End,Avg per Arrow,Equipment,X-Count,10-Count,Accuracy %
2025-11-04,Indoor 18m,18m,40cm,680,56.7,9.4,Competition Bow,42,68,94.4%
2025-11-03,Outdoor 70m,70m,122cm,650,54.2,9.0,Competition Bow,28,54,90.3%
```

### Export All Data (Full Backup)

**When to use:** Complete database backup before major changes, device migration, or long-term archival.

**Steps:**
1. Navigate to **Settings** → **Data Management**
2. Tap **Export All Data**
3. Select export options:
   - ✅ Include all rounds
   - ✅ Include all equipment
   - ✅ Include all statistics
   - ✅ Include archived data
   - ✅ Include settings
4. Choose format:
   - **JSON** - Recommended for full backup (includes all relationships)
   - **CSV** - For data analysis only (loses some relationships)
5. Tap **Create Backup**
6. Save to secure location:
   - ✅ Cloud storage (Google Drive, Dropbox)
   - ✅ Email to yourself
   - ⚠️ Local device (less secure - device loss = data loss)

**Result:** File named `ArcheryApprentice_Backup_2025-11-04.json`

**⚠️ Backup Best Practice:** Export full backup monthly and before major app updates.

---

## 2. Importing Data

Importing allows you to load data from external sources, restore backups, or migrate from other archery apps.

### Supported Import Formats

- **JSON** - Full data model (rounds, equipment, statistics)
- **CSV** - Round scores only (simplified)
- **Archery GB** - Import from Archery GB systems
- **WA Ianseo** - Import from Ianseo scoring

### Import Round Data from CSV

**When to use:** Import scores from spreadsheets or other archery apps.

**Steps:**
1. Prepare CSV file with required format:
   ```csv
   Date,Round Name,Distance,Target Size,Scoring System,Arrows per End,Num Ends,Score
   2025-11-04,Indoor Practice,18m,40cm,10-ring,6,10,680
   ```
2. Navigate to **Settings** → **Data Management**
3. Tap **Import Data**
4. Select **Import from CSV**
5. Choose CSV file from device
6. **Validation Phase:**
   - App checks format compatibility
   - Verifies required columns exist
   - Detects potential conflicts
7. **Preview Phase:**
   - Shows rounds to be imported
   - Highlights any warnings or conflicts
   - Example: "3 rounds will be imported, 1 duplicate detected"
8. **Conflict Resolution:**
   - **Skip** - Don't import duplicate rounds
   - **Overwrite** - Replace existing round with imported data
   - **Create New** - Import as separate round (recommended)
9. Tap **Import** to confirm
10. Review import results:
    - "✅ 3 rounds imported successfully"
    - "⚠️ 1 round skipped (duplicate)"

**CSV Format Requirements:**
- Required columns: Date, Round Name, Distance, Scoring System, Score
- Optional columns: Equipment, Target Size, Notes
- Date format: YYYY-MM-DD (e.g., 2025-11-04)

### Import Equipment from JSON

**When to use:** Load equipment configurations shared by other archers or restore equipment backups.

**Steps:**
1. Obtain JSON equipment file (from export or shared source)
2. Navigate to **Equipment Page** → **⋮** (menu) → **Import Equipment**
3. Select JSON file
4. **Validation:**
   - Checks JSON structure
   - Verifies database version compatibility
   - Detects duplicate equipment
5. **Preview:**
   - Shows equipment to be imported
   - Example: "Bow Setup: Competition Bow (Riser: Hoyt Formula X, Limbs: Win&Win Wiawis One)"
6. **Conflict Resolution:**
   - Equipment with same brand/model exists?
     - **Skip** - Don't import
     - **Import as Variant** - Add as separate item (e.g., "Hoyt Formula X (2)")
     - **Merge** - Update existing equipment with new details
7. Tap **Import**
8. Review import results

**JSON Structure (Minimum Required):**
```json
{
  "bowSetup": {
    "name": "Competition Bow",
    "riser": {"brand": "Hoyt", "model": "Formula X"},
    "limbs": {"brand": "Win&Win", "model": "Wiawis One"}
  }
}
```

### Import from Full Backup

**When to use:** Restore complete database after device migration, data loss, or app reinstall.

**Steps:**
1. Locate your backup file (e.g., `ArcheryApprentice_Backup_2025-11-04.json`)
2. Navigate to **Settings** → **Data Management**
3. Tap **Restore from Backup**
4. Select backup file
5. **Validation Phase:**
   - Checks backup file integrity
   - Verifies app version compatibility
   - Example: "Backup created on 2025-11-04 with app v2.0.0"
6. **⚠️ Warning:** "This will overwrite all current data. Continue?"
7. Choose restore mode:
   - **Full Restore** - Replace entire database (⚠️ destructive)
   - **Merge Import** - Add backup data to existing data (safer)
8. Tap **Restore**
9. Wait for import to complete (progress bar shown)
10. Review import summary:
    - "✅ 125 rounds restored"
    - "✅ 8 equipment setups restored"
    - "✅ Statistics recalculated"

**⚠️ Critical:** Always export current data before full restore in case you need to recover.

### Troubleshooting Import Issues

**"Invalid file format" Error:**
- Verify file is valid CSV or JSON
- Check file isn't corrupted
- Ensure file extension matches format (.csv or .json)

**"Incompatible database version" Error:**
- Update app to latest version
- Export data from source app in compatible format
- Try importing in smaller batches

**"Duplicate data detected" Warnings:**
- Review conflict resolution options
- Use "Skip" to avoid duplicates
- Use "Create New" if data is actually different

**"Missing required columns" (CSV Import):**
- Ensure CSV has Date, Round Name, Distance, Score columns
- Check column headers match exactly (case-sensitive)
- Verify no empty rows at top of CSV

---

## 3. Backing Up Your Scores

Regular backups protect against data loss from device failure, app issues, or accidental deletion.

### Automatic Cloud Backup (Firebase Sync)

**When to use:** Always! This is your automatic safety net.

**Setup:**
1. Navigate to **Settings** → **Cloud Sync**
2. Tap **Enable Cloud Sync**
3. Sign in with Firebase account:
   - Google account
   - Email/password
   - Anonymous (limited - tied to device)
4. Grant permissions when prompted
5. Initial sync begins automatically
6. Status: "✅ Synced 2 minutes ago"

**What Gets Backed Up:**
- ✅ All completed rounds
- ✅ All equipment configurations
- ✅ Tournament participation data
- ✅ Settings and preferences
- ❌ Cancelled rounds (excluded by design)
- ❌ Temporary/draft data

**Sync Frequency:**
- **Automatic:** After completing each round
- **Real-time:** Tournament leaderboards (when online)
- **Background:** Every 30 minutes when app is open
- **Manual:** Pull-to-refresh on main screens

**Offline-First Design:** All changes saved locally first, then synced to cloud when internet available.

### Manual Backup (Export Method)

**When to use:** Before major app updates, device changes, or as additional safety.

**Recommended Schedule:**
- **Monthly** - Export full database backup
- **Before Updates** - Export before major app updates
- **Before Device Change** - Export before switching phones/tablets
- **After Important Events** - Export after competitions or milestones

**Steps:** (See "Export All Data" section above)

### Archive Old Rounds

**When to use:** Free up storage while preserving data you may need later.

**Steps:**
1. Navigate to **Settings** → **Data Management**
2. Tap **Archive Old Rounds**
3. Choose archival criteria:
   - **Older than 1 year** (recommended)
   - **Older than 6 months**
   - **Custom date range**
4. Preview rounds to be archived:
   - "45 rounds from 2023 will be archived"
5. Tap **Archive**
6. Rounds moved to compressed archive storage
7. Access archived rounds:
   - **Settings** → **Data Management** → **View Archives**
   - Restore individual rounds if needed

**Archive vs Delete:**
- **Archive:** Data preserved, compressed, can be restored
- **Delete:** Permanent removal (with soft-delete undo period)

**Automatic Archival Rules:**
- Rounds older than 1 year → Auto-archive (if enabled in settings)
- Archives older than 2 years → Prompt for deletion

---

## 4. Sharing Your Data

Share rounds, equipment setups, or statistics with coaches, friends, or for competition submission.

### Share Individual Round

**When to use:** Send practice results to coach, share competition scores with club.

**Steps:**
1. Navigate to **Round Detail**
2. Tap **Share** icon (⋯ menu → Share)
3. Choose share format:
   - **PDF** - Visual report with statistics (best for sharing)
   - **CSV** - Raw data for analysis
   - **JSON** - Complete data with metadata
4. Select share method:
   - **Email** - Attach file to email
   - **Messaging** - Send via WhatsApp, Telegram, etc.
   - **Cloud Storage** - Upload to Drive, Dropbox
   - **Copy Link** - If using Firebase public sharing
5. Add optional message
6. Tap **Send**

**Shared Data Includes:**
- Round name, date, distance, target size
- Total score, average per arrow, accuracy %
- X-count, 10-count, ring distribution
- End-by-end breakdown
- Equipment used
- Notes and comments

### Share Equipment Setup

**When to use:** Share bow configuration with friends, get setup advice from coach.

**Steps:**
1. Navigate to **Equipment Page** → **Bow Setups**
2. Long-press the setup to share
3. Tap **Share Setup**
4. Choose format:
   - **PDF** - Formatted equipment sheet (best for sharing)
   - **JSON** - For others to import into their app
5. Select share destination
6. Tap **Send**

**PDF Equipment Sheet Includes:**
- Bow setup name and description
- Riser details (brand, model, length, material)
- Limbs details (brand, model, poundage, limb length)
- Sight configuration and sight marks
- Stabilizer setup (length, weight)
- Arrow specifications (spine, length, weight, point, nock)
- Accessories

### Share Analytics Report

**When to use:** Share performance analysis with coach, demonstrate improvement.

**Steps:**
1. Navigate to **Analytics** → Select report type
2. Tap **Share** icon
3. Choose report:
   - **Equipment Comparison** - Side-by-side setup performance
   - **Distance Statistics** - Performance at specific distances
   - **Fatigue Analysis** - Performance drop metrics
   - **Shot Grouping** - Grouping metrics and visualizations
4. Select format (PDF recommended for reports)
5. Share via preferred method

### Share for Competition Submission

**When to use:** Submit scores to Archery GB, World Archery, or club competitions.

**Steps:**
1. Navigate to **Round Detail** (competition round)
2. Tap **⋯** menu → **Export for Competition**
3. Select competition format:
   - **Archery GB** - UK competition submission
   - **WA Ianseo** - World Archery format
   - **Generic CSV** - Universal format
4. Verify round details match competition requirements
5. Export and submit via competition system

**Verification Checklist:**
- ✅ Round name matches competition
- ✅ Distance and target size correct
- ✅ Scoring system matches (10-ring, 6-ring, etc.)
- ✅ Date is competition date
- ✅ Equipment recorded (if required)

---

## 5. Cleaning Up Old Data

Keep your app running smoothly by archiving or deleting old rounds you no longer need.

### Delete Individual Rounds

**When to use:** Remove invalid practice sessions, accidental rounds, or test data.

**Steps:**
1. Navigate to **Round Scoring** → **Historical Rounds**
2. Long-press the round to delete
3. Tap **Delete**
4. **Soft Delete with Undo:**
   - Snackbar appears: "Round deleted. UNDO?"
   - Tap **UNDO** within 10 seconds to restore
   - After 10 seconds, round marked for permanent deletion
5. Permanent deletion happens:
   - Automatically after 30 days
   - Or manually via **Settings** → **Data Management** → **Permanently Delete Marked Rounds**

**What Gets Deleted:**
- ✅ Round metadata (name, date, distance)
- ✅ All end scores
- ✅ All arrow scores
- ✅ Round statistics
- ❌ Equipment (preserved for historical data)

**⚠️ Important:** Deleted rounds are excluded from statistics and equipment performance calculations.

### Bulk Delete Multiple Rounds

**When to use:** Clean up test rounds, old practice sessions, or entire date ranges.

**Steps:**
1. Navigate to **Round Scoring** → **Historical Rounds**
2. Tap **Select Multiple** icon
3. Select rounds to delete (tap each round)
4. Tap **Delete Selected** from bottom action bar
5. Confirm bulk deletion:
   - "Delete 15 selected rounds?"
6. Tap **Delete**
7. Undo available for 10 seconds (for entire batch)

**Bulk Deletion Result:**
```
✅ 15 rounds deleted
✅ 180 end scores removed
✅ 1,080 arrow scores removed
✅ Equipment preserved for history
```

### Delete Old Rounds by Date

**When to use:** Remove all rounds older than specific date to free storage.

**Steps:**
1. Navigate to **Settings** → **Data Management**
2. Tap **Delete Old Rounds**
3. Choose criteria:
   - **Older than 2 years** (recommended for deletion)
   - **Older than 1 year**
   - **Custom date** (select specific cutoff)
4. Preview rounds to be deleted:
   - "68 rounds from 2022-2023 will be deleted"
   - Shows total storage to be freed (e.g., "~12 MB")
5. **⚠️ Warning:** "This cannot be undone. Export backup first?"
   - Tap **Export Backup** → Backup created automatically
   - Or tap **Skip** if you already have backup
6. Tap **Delete**
7. Deletion completes with summary

**⚠️ Best Practice:** Always export backup before bulk deletion by date.

### View and Restore Deleted Rounds

**When to use:** Recover recently deleted rounds within 30-day grace period.

**Steps:**
1. Navigate to **Settings** → **Data Management**
2. Tap **Deleted Rounds** (shows count in badge)
3. View list of soft-deleted rounds
4. Select round to restore
5. Tap **Restore**
6. Round moved back to active rounds list
7. Statistics recalculated to include restored round

**Deleted Rounds List Shows:**
- Round name and date
- Days until permanent deletion (e.g., "23 days remaining")
- Total score and distance
- Restore button

**Permanent Deletion:**
- After 30 days, rounds permanently deleted
- Cannot be recovered after permanent deletion
- Manual option: **Permanently Delete All** (immediate, irreversible)

---

## 6. Cloud Sync Setup

Cloud sync keeps your data synchronized across multiple devices and provides automatic backup.

### Enable Cloud Sync

**Steps:**
1. Navigate to **Settings** → **Cloud Sync**
2. Tap **Enable Cloud Sync**
3. Choose authentication method:
   - **Google Account** (recommended - easiest)
   - **Email/Password** (create Firebase account)
   - **Anonymous** (⚠️ limited - tied to device only)
4. Grant permissions:
   - Internet access
   - Cloud storage access
5. Initial sync begins:
   - Progress bar shown
   - "Syncing 125 rounds... 45% complete"
6. Sync completes: "✅ All data synced to cloud"

**Initial Sync Duration:**
- 10-50 rounds: 10-30 seconds
- 50-200 rounds: 1-2 minutes
- 200+ rounds: 2-5 minutes

### Sync Across Multiple Devices

**When to use:** Use app on both phone and tablet, or upgrade to new device.

**Steps (on second device):**
1. Install Archery Apprentice on second device
2. Open app → Navigate to **Settings** → **Cloud Sync**
3. Tap **Sign In to Sync**
4. Sign in with same account used on first device
5. Tap **Download Cloud Data**
6. Choose sync mode:
   - **Replace Local Data** - Overwrite device with cloud data (for new device)
   - **Merge Data** - Combine device data with cloud data (if both have rounds)
7. Sync downloads cloud data
8. Status: "✅ Synced with cloud"

**Real-Time Sync:**
- Changes on Device A → Sync to cloud → Device B downloads changes
- Happens automatically in background
- Manual refresh: Pull-to-refresh on main screens

### Conflict Resolution

**When conflicts occur:** Same round edited on multiple devices while offline.

**Conflict Detection:**
- App compares timestamps of local and cloud versions
- If both versions modified since last sync → Conflict detected

**Resolution Strategies:**

1. **Last Write Wins (Default)**
   - Most recent edit takes precedence
   - Older version discarded
   - ✅ Simple, automatic
   - ⚠️ May lose some edits

2. **Manual Resolution**
   - App shows both versions side-by-side
   - User chooses which version to keep
   - ✅ Full control
   - ⚠️ Requires user intervention

**Steps for Manual Resolution:**
1. Sync conflict notification appears
2. Tap notification or go to **Settings** → **Cloud Sync** → **Resolve Conflicts**
3. View conflicting rounds:
   - "Local version: Score 680, edited 2 mins ago"
   - "Cloud version: Score 675, edited 5 mins ago"
4. Choose version:
   - **Keep Local** - Use device version
   - **Keep Cloud** - Use cloud version
   - **Keep Both** - Create separate rounds
5. Tap **Resolve**
6. Conflict resolved and synced

**⚠️ Preventing Conflicts:** Ensure device is online when completing rounds to sync immediately.

### Sync Status and Troubleshooting

**Check Sync Status:**
- **Settings** → **Cloud Sync** → View sync status
  - "✅ Synced 2 minutes ago" (all good)
  - "⏳ Syncing..." (in progress)
  - "⚠️ Sync failed - Retry?" (error)

**Sync Indicators:**
- Cloud icon on round cards:
  - ☁️ with checkmark = Synced to cloud
  - ☁️ with upload arrow = Waiting to sync
  - ☁️ with X = Sync failed
  - No icon = Not yet synced

**Common Sync Issues:**

**"Sync failed - No internet connection"**
- Solution: Connect to WiFi or mobile data
- App will retry automatically when connection restored

**"Sync failed - Authentication expired"**
- Solution: Re-authenticate
  - **Settings** → **Cloud Sync** → **Sign Out**
  - Sign back in with same account
  - Sync resumes automatically

**"Sync failed - Server error"**
- Solution: Retry with exponential backoff
  - App automatically retries: 1s, 2s, 4s, 8s, 16s delays
  - If still failing, wait 30 minutes and try manual sync
  - **Settings** → **Cloud Sync** → **Sync Now**

**Manual Sync:**
- Pull-to-refresh on main screens
- Or: **Settings** → **Cloud Sync** → **Sync Now**

### Disable Cloud Sync

**When to use:** Privacy concerns, want offline-only usage, or troubleshooting.

**Steps:**
1. Navigate to **Settings** → **Cloud Sync**
2. Tap **Disable Cloud Sync**
3. **⚠️ Warning:** "Cloud backup will stop. Local data preserved."
4. Choose option:
   - **Export Backup First** - Create local backup before disabling
   - **Disable Without Backup** - Just turn off sync
5. Confirm disable
6. Cloud sync stopped

**What Happens:**
- ✅ All local data preserved on device
- ❌ No more automatic cloud backups
- ❌ No sync across devices
- ✅ Can re-enable anytime (data will re-sync)

---

## 7. Offline Mode

Archery Apprentice is designed **offline-first** - all core features work without internet.

### Offline-First Architecture

**What Works Offline:**
- ✅ Create and score rounds
- ✅ Add and edit equipment
- ✅ View historical rounds and statistics
- ✅ View equipment analytics
- ✅ Export data to local files
- ✅ Archive and delete rounds

**What Requires Internet:**
- ❌ Cloud sync (automatic backup)
- ❌ Tournament leaderboards (real-time updates)
- ❌ Firebase authentication (initial sign-in)
- ❌ Sharing via cloud links

**How It Works:**
1. All data saved to local Room database first
2. User sees immediate success (no waiting for network)
3. Background sync queues changes for upload
4. When internet available, changes uploaded to cloud
5. If sync fails, retries automatically with exponential backoff

### Using the App Completely Offline

**Scenario:** Competition venue with no WiFi, remote outdoor range, airplane mode.

**Steps:**
1. Ensure app is installed and opened at least once (while online)
2. Disable cloud sync (optional, to avoid error notifications):
   - **Settings** → **Cloud Sync** → **Pause Sync While Offline**
3. Use app normally:
   - Score rounds → Saved locally
   - Add equipment → Saved locally
   - View statistics → Calculated from local data
4. When back online:
   - Re-enable cloud sync or tap **Sync Now**
   - All offline changes upload to cloud automatically

**⚠️ Offline Limitations:**
- Tournament leaderboards won't update (shows cached data)
- Can't join new tournaments (requires internet)
- Can't view other participants' scores in tournaments

### Sync After Being Offline

**When you reconnect to internet:**
1. App detects connection restored
2. Automatic sync begins in background
3. Notification: "Syncing offline changes... 15 rounds"
4. Progress indicator in notification tray
5. Completion notification: "✅ All offline changes synced"

**If conflicts detected:** See "Conflict Resolution" section above.

---

## 8. Data Privacy & Storage

Understanding where your data is stored and how it's protected.

### Local Storage (Room Database)

**Where:** Android device internal storage (app-private directory)
- Path: `/data/data/com.archeryapprentice/databases/archery_apprentice.db`
- Accessible only to the app (Android security sandbox)
- Encrypted at rest (Android 6.0+ automatic full-disk encryption)

**What's Stored Locally:**
- All rounds, ends, and arrow scores
- All equipment configurations
- Tournament participation data
- Settings and preferences
- Cached analytics calculations

**Storage Size:**
- Typical: 5-20 MB for 100-500 rounds
- Large databases: 50-100 MB for 1,000+ rounds with full equipment history

### Cloud Storage (Firebase Firestore)

**Where:** Google Cloud Platform (Firebase Firestore)
- Servers located in: us-central1 (Iowa, USA) by default
- Other regions available: europe-west, asia-east

**What's Stored in Cloud:**
- All completed rounds (cancelled rounds excluded)
- Equipment configurations
- Tournament data (if participating in tournaments)
- User settings

**Security:**
- ✅ TLS encryption in transit (HTTPS)
- ✅ Encrypted at rest (Google Cloud encryption)
- ✅ Access controlled by Firebase Security Rules
- ✅ User authentication required (Firebase Auth)

**Firebase Security Rules:**
```javascript
// Users can only read/write their own data
match /users/{userId} {
  allow read, write: if request.auth.uid == userId;
}

// Tournament data readable by all participants
match /tournaments/{tournamentId} {
  allow read: if request.auth.uid in resource.data.participantIds;
  allow write: if request.auth.uid == resource.data.creatorId;
}
```

### Data Privacy

**Personal Data Collected:**
- Firebase UID (anonymous identifier)
- Username (if provided in settings)
- Email (if using email/password authentication)
- Round scores and equipment data

**Data NOT Collected:**
- Real name (unless you enter it as username)
- Location data (beyond what you manually enter as range name)
- Device identifiers (IMEI, MAC address)
- Contacts or other app data

**Data Sharing:**
- ❌ Never shared with third parties
- ❌ Never sold or used for advertising
- ✅ Only you can access your data (via authentication)
- ✅ Tournament data shared only with tournament participants

**Data Retention:**
- **Local:** Kept until you delete rounds or uninstall app
- **Cloud:** Kept until you delete account or request data deletion
- **Deleted rounds:** 30-day soft delete period, then permanent removal

### Delete All Your Data

**When to use:** Stop using app, privacy concerns, start fresh.

**Steps:**
1. Navigate to **Settings** → **Data Management**
2. Scroll to **Data Privacy**
3. Tap **Delete All Data**
4. **⚠️ Critical Warning:** "This will permanently delete ALL local and cloud data. This cannot be undone."
5. Choose option:
   - **Export Backup First** (recommended)
   - **Delete Without Backup**
6. Confirm deletion by typing: "DELETE ALL DATA"
7. Tap **Permanently Delete**
8. Deletion process:
   - Local database wiped
   - Cloud data deleted from Firebase
   - Account authentication removed
9. App resets to fresh install state

**What's Deleted:**
- ✅ All rounds and scores
- ✅ All equipment
- ✅ All settings
- ✅ Cloud backups
- ✅ Firebase authentication

**⚠️ This is irreversible!** Export backup if there's any chance you'll want the data later.

### Data Portability

**Your right to your data:** You can export all data at any time.

**Export Everything:**
1. **Settings** → **Data Management** → **Export All Data**
2. Choose JSON format (most complete)
3. Save to secure location

**What You Get:**
- Complete JSON file with all rounds, equipment, statistics
- Can import into other archery apps (if they support format)
- Can analyze with programming tools (Python, R, JavaScript)
- Permanent record of your archery journey

---

## Best Practices

### Daily Use
- ✅ Enable cloud sync for automatic backup
- ✅ Complete rounds properly (don't abandon mid-session)
- ✅ Use descriptive round names for easy searching later

### Weekly
- ✅ Check sync status (ensure cloud backup is current)
- ✅ Review and delete invalid test rounds

### Monthly
- ✅ Export full backup to external storage
- ✅ Review storage usage, archive old rounds if needed

### Before Major Events
- ✅ Export backup before app updates
- ✅ Export backup before device changes
- ✅ Verify cloud sync is working
- ✅ Test offline mode at practice session

### Privacy-Conscious Users
- ✅ Use anonymous authentication (no email required)
- ✅ Don't enter personal info in round notes
- ✅ Export and delete cloud data periodically
- ✅ Use offline mode exclusively if desired

---

## Troubleshooting

### "Export Failed - Storage Full"
- Free up device storage space
- Delete cached files: **Settings** → **Storage** → **Clear Cache**
- Archive old rounds to compress data

### "Import Failed - Invalid Format"
- Verify file is valid CSV or JSON
- Check file extension matches format
- Try re-exporting from source app

### "Sync Failed - Authentication Error"
- Sign out and sign back in: **Settings** → **Cloud Sync** → **Sign Out**
- Re-authenticate with same account
- Check internet connection

### "Cannot Delete Round - In Use"
- Round may be referenced by equipment statistics
- This is expected behavior to preserve data integrity
- Archive round instead of deleting

### "Backup File Too Large"
- Export in smaller batches (date ranges)
- Export CSV instead of JSON (smaller file size)
- Archive old rounds before export

---

## Related Documentation

**Learn More:**
- [Sync Features](../../features/sync/) - Cloud synchronization details
- [Analytics Features](../../features/analytics/) - Understanding what data is exported
- [Equipment Features](../../features/equipment/) - Equipment management and export
- [Troubleshooting](../../troubleshooting/) - Common issues and solutions

**Developer Documentation:**
- [Data Lifecycle Services](/developer-guide/technical-reference/api/services/data-lifecycle-services-reference/) - Technical API details
- [Integration Flows](/Technical-Reference/Flows/Integration-Flows/) - Firebase sync architecture

---

## Summary

Archery Apprentice data management features help you:
- ✅ **Export** rounds, equipment, and analytics in multiple formats
- ✅ **Import** data from external sources with validation
- ✅ **Backup** automatically via cloud sync or manually via export
- ✅ **Share** data with coaches, friends, or for competition submission
- ✅ **Sync** across multiple devices with conflict resolution
- ✅ **Work offline** with full functionality and automatic sync when reconnected
- ✅ **Protect privacy** with encrypted storage and user-controlled data deletion
- ✅ **Clean up** old data with archival and deletion tools

**Your data is always under your control - backup regularly and shoot with confidence!**
