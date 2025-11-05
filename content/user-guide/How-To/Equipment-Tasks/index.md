---
title: "Equipment Management Tasks"
description: "Step-by-step guides for managing your archery equipment"
category: "user-guide"
audience: "users"
status: "active"
tags:
  - how-to
  - equipment
  - tutorial
---

[Home](/) > [User Guide](../../) > [How-To](../) > Equipment Tasks

---

# Equipment Management Tasks

This guide provides step-by-step instructions for all equipment management tasks in Archery Apprentice. Learn how to add, edit, organize, and track your archery gear effectively.

## Table of Contents

1. [Adding New Equipment](#adding-new-equipment)
2. [Editing Equipment](#editing-equipment)
3. [Creating Bow Setups](#creating-bow-setups)
4. [Managing Bow Setup Versions](#managing-bow-setup-versions)
5. [Deleting Equipment](#deleting-equipment)
6. [Managing Sight Marks](#managing-sight-marks)
7. [Viewing Equipment Performance](#viewing-equipment-performance)
8. [Organizing Equipment](#organizing-equipment)

---

## Adding New Equipment

### General Steps (All Equipment Types)

1. Open the app and tap **Equipment Page** from the landing screen
2. Scroll to the equipment category you want to add
3. Tap the **+** (Add) button for that category
4. Fill in the required and optional fields
5. Tap **Save**

### Equipment Type: Riser

Risers are the central part of your bow.

**Required Fields:**
- **Brand** - Manufacturer (e.g., "Hoyt", "Win&Win", "SF Archery")
- **Model** - Model name (e.g., "Formula X", "Inno CXT")

**Optional Fields:**
- **Length** - Riser length (e.g., "25 inches", "27 inches")
- **Material** - Construction material (e.g., "Carbon", "Aluminum", "Wood")

**Example:**
```
Brand: Hoyt
Model: Formula X
Length: 25 inches
Material: Carbon
```

### Equipment Type: Limbs

Limbs attach to the riser and store the energy when drawn.

**Required Fields:**
- **Brand** - Manufacturer
- **Model** - Model name

**Optional Fields:**
- **Poundage** - Draw weight (e.g., "38 lbs", "42 lbs")
- **Limb Length** - Short, Medium, or Long (e.g., "Long")

**Example:**
```
Brand: Win&Win
Model: Wiawis One
Poundage: 38 lbs
Limb Length: Long
```

### Equipment Type: Sight

Sights help you aim accurately at different distances.

**Required Fields:**
- **Brand** - Manufacturer
- **Model** - Model name

**Optional Fields:**
- **Material** - Construction material (e.g., "Aluminum", "Carbon")

**Sight Marks:**
After creating a sight, you can add **sight marks** for different distances. See [Managing Sight Marks](#managing-sight-marks).

**Example:**
```
Brand: Shibuya
Model: Ultima RC II
Material: Aluminum
```

### Equipment Type: Stabilizer

Stabilizers reduce bow vibration and improve balance.

**Required Fields:**
- **Brand** - Manufacturer
- **Model** - Model name

**Optional Fields:**
- **Length** - Stabilizer length (e.g., "30 inches", "33 inches")
- **Weight** - Weight in ounces (e.g., "12 oz")
- **Straightness Rating** - Quality rating (e.g., "±0.001")

**Example:**
```
Brand: Doinker
Model: Platinum
Length: 30 inches
Weight: 10 oz
Straightness Rating: ±0.001
```

### Equipment Type: Weights

Additional weights for balance and stabilization.

**Required Fields:**
- **Brand** - Manufacturer
- **Model** - Model name

**Optional Fields:**
- **Ounces** - Weight amount (e.g., "4 oz")

**Example:**
```
Brand: Easton
Model: X10 Weights
Ounces: 4 oz
```

### Equipment Type: Plunger

Plungers (cushion plungers/buttons) fine-tune arrow flight.

**Required Fields:**
- **Brand** - Manufacturer
- **Model** - Model name

**Optional Fields:**
- **Adjustment** - Current setting notes (e.g., "Medium tension, 2mm out")

**Example:**
```
Brand: Beiter
Model: Plunger
Adjustment: Medium tension, 2mm out
```

### Equipment Type: Rest

Arrow rests support the arrow before release.

**Required Fields:**
- **Brand** - Manufacturer
- **Model** - Model name

**Optional Fields:**
- **Type** - Rest type (e.g., "Magnetic", "Flipper", "Blade")

**Example:**
```
Brand: Hoyt
Model: Super Rest
Type: Magnetic
```

### Equipment Type: Bow String

Bow strings connect the limbs and transfer energy to the arrow.

**Required Fields:**
- **Brand** - Manufacturer
- **Model** - Model name

**Optional Fields:**
- **Strand Count** - Number of strands (e.g., "18", "20")
- **Serving Material** - Material used for serving (e.g., "BCY 3D", "Halo")

**Example:**
```
Brand: BCY
Model: X99
Strand Count: 18
Serving Material: Halo
```

### Equipment Type: Arrows

Arrow sets include the shaft, point, and nock.

**Required Fields:**
- **Brand** - Manufacturer
- **Model** - Model name

**Optional Fields:**
- **Spine** - Arrow stiffness (e.g., "500", "600", "340")
- **Length** - Arrow length in inches (e.g., "29.5")
- **Weight** - Total arrow weight in grains (e.g., "420")
- **Diameter** - Shaft diameter (e.g., "5.5mm")

**Arrow Point Fields:**
- **Point Brand** - Point manufacturer
- **Point Model** - Point model
- **Point Weight** - Point weight in grains (e.g., "120")

**Arrow Nock Fields:**
- **Nock Brand** - Nock manufacturer
- **Nock Model** - Nock model (e.g., "G Nock", "X Nock")

**Example:**
```
Brand: Easton
Model: X10
Spine: 500
Length: 29.5 inches
Weight: 420 grains
Diameter: 5.5mm

Point Brand: Easton
Point Model: X10 Points
Point Weight: 120 grains

Nock Brand: Easton
Nock Model: G Nock
```

### Equipment Type: Accessories

Any other archery equipment not covered by specific types.

**Required Fields:**
- **Brand** - Manufacturer
- **Model** - Model name

**Optional Fields:**
- **Type** - Accessory type (e.g., "Chest Guard", "Tab", "Quiver")

**Example:**
```
Brand: Fivics
Model: Saker 2
Type: Tab
```

---

## Editing Equipment

You can edit any equipment item after it's been created.

**Steps:**
1. Navigate to **Equipment Page**
2. Find the equipment type category
3. Tap on the specific equipment item
4. You'll see the equipment details screen
5. Tap **Edit** (pencil icon or Edit button)
6. Modify any fields
7. Tap **Save**

**Important Notes:**
- Editing equipment in a **Bow Setup** creates a new setup version automatically
- Historical rounds always reference the equipment version used at that time
- You can't change the equipment type after creation (e.g., can't convert a Riser to Limbs)

---

## Creating Bow Setups

A **Bow Setup** represents a complete configuration of equipment you use together for shooting.

### Why Use Bow Setups?

- Track which equipment combination you used for each round
- Compare performance across different configurations
- Quickly switch between setups (indoor vs outdoor, different distances)
- Maintain equipment history as you make changes

### Creating Your First Setup

**Steps:**
1. Navigate to **Equipment Page**
2. Scroll to the **Bow Setups** section
3. Tap the **+** (Add) button
4. Fill in the setup details:

**Required Fields:**
- **Name** - Descriptive name (e.g., "Outdoor 70m Setup", "Indoor Competition Setup")

**Optional Fields:**
- **Description** - Notes about this configuration

**Equipment Selection:**
- **Riser** - Select from your risers (dropdown)
- **Limbs** - Select from your limbs (dropdown)
- **Sight** - Select from your sights (optional)
- **Stabilizer** - Select from your stabilizers (optional)
- **Plunger** - Select from your plungers (optional)
- **Rest** - Select from your rests (optional)
- **Bow String** - Select from your bow strings (optional)
- **Arrows** - Select from your arrow sets (optional)
- **Weights** - Select from your weights (optional)
- **Accessories** - Select from your accessories (optional)

5. Tap **Save**

**Example Setup:**
```
Name: Main Outdoor Setup
Description: Primary setup for 50m-70m outdoor rounds

Riser: Hoyt Formula X 25"
Limbs: Win&Win Wiawis One 38lbs Long
Sight: Shibuya Ultima RC II
Stabilizer: Doinker Platinum 30"
Plunger: Beiter Plunger
Rest: Hoyt Super Rest
Bow String: BCY X99 18-strand
Arrows: Easton X10 500
Weights: Easton 4oz
```

### Setup Naming Best Practices

**Good Names:**
- ✅ "Outdoor 70m Olympic Setup"
- ✅ "Indoor 18m Competition"
- ✅ "Practice Setup - Testing New Sight"
- ✅ "Backup Setup (Old Limbs)"

**Avoid:**
- ❌ "Setup 1"
- ❌ "Main"
- ❌ "Test"

Use names that tell you:
- **Purpose** (competition, practice, testing)
- **Distance** (18m, 50m, 70m)
- **Environment** (indoor, outdoor)
- **Status** (primary, backup, experimental)

---

## Managing Bow Setup Versions

Every time you modify equipment in a bow setup, the app automatically creates a **new version**.

### Why Versioning?

- **Historical Accuracy** - Rounds always reference the exact equipment used
- **Performance Tracking** - Compare how changes affect your scores
- **Equipment Testing** - See if a new sight, stabilizer, or arrows improve performance
- **Data Integrity** - Never lose track of what equipment produced which results

### How Versioning Works

**Scenario:**
1. You create "Outdoor Setup" with Hoyt riser + Win&Win limbs → **Version 1**
2. You add a Shibuya sight to the setup → **Version 2** created automatically
3. You change to heavier arrows → **Version 3** created automatically

**Round References:**
- Round scored on May 1 → References Version 1 (no sight)
- Round scored on May 15 → References Version 2 (with sight)
- Round scored on June 1 → References Version 3 (sight + heavy arrows)

### Viewing Setup Versions

**Steps:**
1. Navigate to **Equipment Page**
2. Go to **Bow Setups**
3. Tap on a setup to view details
4. Scroll to **Version History** section
5. See all versions with:
   - Version number
   - Date created
   - Equipment changes made

### Version Comparison

Compare performance across versions:
1. Open **Equipment Analytics Hub**
2. Select **Performance by Setup**
3. Choose a setup
4. Filter by version to see how each configuration performed

**Use Cases:**
- "Did adding the stabilizer improve my average?"
- "Were my scores better with the 500 spine or 600 spine arrows?"
- "Has my new sight helped my accuracy?"

---

## Deleting Equipment

You can delete equipment items, but be careful - this affects historical data.

### Deleting Individual Equipment

**Steps:**
1. Navigate to the equipment item
2. Tap on it to open details
3. Tap **Delete** (trash icon or Delete button)
4. Confirm deletion

**What Happens:**
- Equipment is removed from your equipment list
- If it's part of a **Bow Setup**, you'll need to remove it from the setup first
- Historical rounds retain the equipment information (soft delete)

### Deleting Bow Setups

Bow setups use **soft delete** - they're marked as inactive but not permanently removed.

**Steps:**
1. Navigate to **Bow Setups**
2. Tap on the setup to delete
3. Tap **Delete**
4. The setup is marked as **inactive** (`isActive = false`)

**What Happens:**
- Setup is hidden from active setups list
- Historical rounds still reference this setup
- Performance data is preserved
- You can't permanently delete setups to protect data integrity

**Viewing Inactive Setups:**
- Toggle "Show Inactive" in Bow Setups view
- Inactive setups are grayed out or marked clearly

---

## Managing Sight Marks

If you use a **Sight**, you can add sight marks for different distances.

### What are Sight Marks?

Sight marks are distance-specific settings for your sight. They tell you where to position your sight for accurate aiming at each distance.

**Example:**
- 18 meters → Mark at 15.2
- 30 meters → Mark at 22.7
- 50 meters → Mark at 31.5
- 70 meters → Mark at 39.2

### Adding Sight Marks

**Steps:**
1. Navigate to **Equipment Page**
2. Go to **Sights**
3. Tap on your sight to open details
4. Scroll to **Sight Marks** section
5. Tap **Add Sight Mark** or **+**
6. Fill in:
   - **Distance** - The distance (e.g., "50 meters")
   - **Mark Value** - Your sight setting (e.g., "31.5")
   - **Notes** (optional) - Conditions or reminders
7. Tap **Save**

**Example:**
```
Distance: 50 meters
Mark Value: 31.5
Notes: Outdoor, no wind, 122cm target
```

### Editing Sight Marks

**Steps:**
1. Open the sight details
2. Find the sight mark in the list
3. Tap on it
4. Edit the distance, mark value, or notes
5. Tap **Save**

### Deleting Sight Marks

**Steps:**
1. Open the sight details
2. Find the sight mark
3. Swipe left or tap the **delete icon**
4. Confirm deletion

### Using Sight Marks

- Keep a record of your marks for quick setup at practice or competition
- Update marks as you tune your bow or change equipment
- Add notes for environmental conditions (wind, rain, indoor/outdoor)

---

## Viewing Equipment Performance

See how each piece of equipment performs over time.

### Equipment Analytics Hub

**Steps:**
1. Navigate to **Equipment Page**
2. Tap **Analytics Hub** button
3. Choose analysis type:
   - Performance by Setup
   - Performance by Distance
   - Equipment Comparison

### Performance by Setup

View statistics for each bow setup:
- **Total rounds** scored with this setup
- **Average score**
- **Best round** score
- **Accuracy percentage**
- **X-ring and 10-ring counts**

**Use Case:**
"Which of my setups performs best at 50 meters?"

### Performance by Distance

Break down performance by distance:
- See how each setup performs at 18m, 30m, 50m, 70m, etc.
- Identify strong and weak distances
- Make informed practice decisions

**Use Case:**
"My indoor setup averages 285 at 18m, but my outdoor setup only averages 270 at 18m"

### Equipment Comparison

Compare multiple setups side-by-side:
- Select 2-4 setups
- View stats in parallel columns
- Identify best performers

**Use Case:**
"Should I use my heavier or lighter stabilizer for 70m?"

For detailed analytics information, see [Analytics Features](../../features/analytics/).

---

## Organizing Equipment

### Naming Conventions

Use consistent, descriptive names for easy identification:

**Equipment Items:**
- **Include brand and model**: "Hoyt Formula X 25in" (not just "Riser")
- **Add key specs**: "Win&Win Wiawis One 38lbs Long" (not just "Limbs")
- **Be specific**: "Easton X10 500 spine 29.5in" (not just "Arrows")

**Bow Setups:**
- **Include purpose**: "Competition", "Practice", "Testing"
- **Include distance**: "18m", "50m", "70m"
- **Include environment**: "Indoor", "Outdoor"

**Example Organization:**
```
Equipment:
├── Risers
│   ├── Hoyt Formula X 25in Carbon
│   └── Win&Win Inno CXT 27in
├── Limbs
│   ├── Win&Win Wiawis One 38lbs Long
│   └── SF Archery Axiom+ 40lbs Medium
└── Arrows
    ├── Easton X10 500 29.5in (Competition)
    └── Carbon Express Nano Pro 600 29in (Practice)

Bow Setups:
├── Primary Outdoor 70m Setup
├── Indoor 18m Competition Setup
├── Practice Setup (Testing New Arrows)
└── Backup Setup (Old Equipment)
```

### Managing Multiple Setups

**Strategy 1: Purpose-Based**
- Competition Setup
- Practice Setup
- Testing Setup

**Strategy 2: Distance-Based**
- Short Distance Setup (18m-30m)
- Medium Distance Setup (50m-60m)
- Long Distance Setup (70m-90m)

**Strategy 3: Environment-Based**
- Indoor Setup
- Outdoor Setup
- All-Purpose Setup

**Best Practice:**
Combine strategies - e.g., "Indoor Competition 18m Setup"

### Tracking Equipment Changes

Keep notes in equipment descriptions to track changes:

**Example:**
```
Bow Setup: Primary Outdoor Setup
Description: Main competition setup for 50m-70m outdoor rounds
Last updated: 2024-05-15
Changes:
- 2024-05-15: Switched to heavier arrows (500 → 420 spine)
- 2024-04-01: Added new stabilizer (30" Doinker Platinum)
- 2024-03-10: Upgraded sight to Shibuya Ultima
```

---

## Common Tasks Quick Reference

| Task | Navigation | Action |
|------|-----------|---------|
| Add Equipment | Equipment Page → Category → **+** | Fill details, Save |
| Edit Equipment | Equipment Page → Category → Item → **Edit** | Modify, Save |
| Create Setup | Equipment Page → Bow Setups → **+** | Select equipment, Save |
| Add Sight Mark | Equipment Page → Sights → Item → Sight Marks → **+** | Add distance/mark, Save |
| Delete Equipment | Equipment Page → Category → Item → **Delete** | Confirm |
| View Performance | Equipment Page → **Analytics Hub** | Choose analysis |
| Compare Setups | Analytics Hub → Equipment Comparison | Select setups |

---

## Tips for Equipment Management

### Start Simple

- Begin with just riser and limbs
- Add more equipment as you track more details
- Don't feel pressured to fill in every field immediately

### Be Consistent

- Use the same naming format for all equipment
- Always select a bow setup when scoring rounds
- Update sight marks after tuning sessions

### Use Versions Wisely

- Let the app auto-version when you make significant changes
- Don't worry about minor adjustments (small plunger tweaks)
- Major changes (new sight, different arrows) should create new versions

### Track What Matters

- Focus on equipment that affects your scores
- Sight marks are crucial - keep them updated
- Notes fields are helpful for remembering why you made changes

---

## Related Documentation

**Learn More:**
- [Equipment Features](../../features/equipment/) - Detailed equipment capabilities
- [Quick Start Guide](../../quick-start/) - Getting started with equipment
- [Analytics Features](../../features/analytics/) - Understanding equipment performance data

**Advanced Topics:**
- [Bow Setup Versioning](/developer-guide/technical-reference/data-models/equipment/) - Technical details
- [Equipment Statistics](/developer-guide/technical-reference/data-models/analytics/) - How performance is calculated

---

**Ready to manage your equipment like a pro? Start adding your gear today!**
