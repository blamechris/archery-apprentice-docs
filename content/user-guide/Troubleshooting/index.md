---
title: "Troubleshooting"
description: "Solutions to common problems and issues"
category: "user-guide"
audience: "users"
status: "active"
tags:
  - troubleshooting
  - help
  - support
---

[Home](/) > [User Guide](../) > Troubleshooting

---

# Troubleshooting

Common issues and solutions for Archery Apprentice.

## Scoring Issues

### Scores Won't Save

**Symptoms:**
- Can't move to next end
- "Save" button disabled
- Error message when saving scores

**Possible Causes & Solutions:**

**1. Not all arrows entered**
- Problem: Entered 5 arrows in a 6-arrow end
- Solution: Enter all required arrow scores before proceeding

**2. Invalid score for scoring system**
- Problem: Entered "11" in a 10-ring system
- Solution: Verify score is valid for your scoring system (0-10 for 10-ring, 0-6 for 6-ring, etc.)

**3. Missing X-ring data**
- Problem: X-ring checkbox required but not marked
- Solution: Mark X-ring hits appropriately

### Can't Complete Round

**Symptoms:**
- "Complete Round" button disabled
- Error when trying to complete

**Possible Causes & Solutions:**

**1. Not all ends scored**
- Problem: Scored 5 of 6 ends
- Solution: Score all remaining ends before completing

**2. Round is PAUSED**
- Problem: Round status is PAUSED, not IN_PROGRESS
- Solution: Resume the round first, then complete

**3. Multi-participant missing scores**
- Problem: One or more participants have incomplete ends
- Solution: Ensure all participants have scored all ends

### Accidentally Cancelled a Round

**Symptoms:**
- Round disappeared from active list
- Status shows CANCELLED

**Solutions:**
- Toggle "Show Cancelled" to view cancelled rounds
- Review the round data (preserved but marked cancelled)
- Note: Cannot "uncancel" a round
- Tip: Create a new round with correct data

---

## Equipment Issues

### Equipment Won't Save

**Symptoms:**
- Save button doesn't work
- Error when creating equipment
- Equipment not appearing in list

**Possible Causes & Solutions:**

**1. Missing required fields**
- Problem: Brand or Model not filled in
- Solution: Fill in all required fields (usually Brand and Model)

**2. Invalid data format**
- Problem: Letters in numeric fields (e.g., "38 pounds" in Poundage field)
- Solution: Use numbers only for numeric fields (e.g., "38")

### Bow Setup Won't Save

**Symptoms:**
- Can't create bow setup
- Setup not saving changes

**Possible Causes & Solutions:**

**1. Missing equipment**
- Problem: Selected equipment was deleted
- Solution: Verify selected riser/limbs still exist in equipment list

**2. Equipment in use by another setup**
- Problem: Some implementations limit equipment to one setup
- Solution: Check if equipment is already assigned

### Can't Delete Equipment

**Symptoms:**
- Delete button disabled
- Error when deleting

**Possible Causes & Solutions:**

**1. Equipment in active bow setup**
- Problem: Equipment is currently used in a setup
- Solution: Remove from all setups first, then delete

**2. Equipment used in historical rounds**
- Problem: Equipment referenced by completed rounds
- Solution: This is intentional - equipment is preserved for data integrity

### Bow Setup Deleted But Still Appears

**Symptoms:**
- Setup shows as "inactive" or grayed out
- Can still see setup in lists

**Explanation:**
- Bow setups use "soft delete" (marked inactive, not permanently removed)
- This preserves historical data integrity
- Historical rounds still reference the setup

**Solutions:**
- Toggle "Hide Inactive" to remove from view
- Inactive setups won't appear in dropdowns for new rounds
- This is normal behavior to protect data

---

## Performance Issues

### App Running Slowly

**Symptoms:**
- Lag when navigating
- Slow to load equipment or rounds
- Delayed screen updates

**Solutions:**

**1. Too much historical data**
- Clear old cancelled rounds
- Archive completed rounds from previous seasons
- Consider data export and cleanup

**2. Device storage low**
- Check device storage space
- Clear Android cache (Settings → Apps → Archery Apprentice → Clear Cache)
- Free up space on device

**3. Background apps**
- Close other apps
- Restart device
- Ensure sufficient RAM available

### App Crashes

**Symptoms:**
- App suddenly closes
- Returns to home screen unexpectedly

**Solutions:**

**1. Update the app**
- Check for latest version in Play Store
- Install pending updates

**2. Clear app cache**
- Settings → Apps → Archery Apprentice → Clear Cache
- Note: This won't delete your data

**3. Restart device**
- Simple restart often resolves crashes
- Clears memory and background processes

**4. Report the crash**
- Note what you were doing when it crashed
- Report via GitHub Issues with details

---

## Data Issues

### Missing Scores

**Symptoms:**
- Round completed but scores not showing
- Equipment stats missing data

**Possible Causes & Solutions:**

**1. Round was cancelled**
- Problem: Round status is CANCELLED
- Solution: Cancelled rounds don't contribute to statistics (by design)

**2. Equipment not linked**
- Problem: Round created without selecting bow setup
- Solution: Always select bow setup when creating rounds for proper tracking

**3. Filter active**
- Problem: Viewing filtered data (e.g., specific distance only)
- Solution: Check filter settings, remove filters to see all data

### Equipment Stats Not Updating

**Symptoms:**
- Completed rounds not showing in equipment performance
- Analytics showing old data

**Possible Causes & Solutions:**

**1. No bow setup selected**
- Problem: Rounds scored without equipment selection
- Solution: Select bow setup when creating rounds

**2. Wrong bow setup selected**
- Problem: Used different setup than intended
- Solution: Verify which setup was used (view round details)

**3. Setup version mismatch**
- Problem: Looking at wrong setup version
- Solution: Check if equipment was changed (creates new version)

---

## Multi-Participant Issues

### Guest Scores Not Saving

**Symptoms:**
- Guest participant scores missing
- Only my scores saved

**Possible Causes & Solutions:**

**1. Didn't switch participants**
- Problem: Entered all scores under your name
- Solution: Tap participant name to switch before entering their scores

**2. Participant not added**
- Problem: Forgot to add guest when creating round
- Solution: Can't add participants mid-round - restart round with guests added

### Can't Add More Guests

**Symptoms:**
- Add guest button disabled
- Limit reached message

**Explanation:**
- Maximum 4 participants total (you + 3 guests)
- This is by design for performance and UI reasons

**Solution:**
- If you need more than 4, create separate rounds
- Or use tournament mode for larger groups

---

## Getting Help

### Before Reporting Issues

Gather this information:
- Android version
- App version (Settings → About)
- What you were trying to do
- Exact error message (if any)
- Steps to reproduce the problem

### Where to Get Help

**Bug Reports:**
- [GitHub Issues](https://github.com/blamechris/archery-apprentice/issues)
- Include device/app version and steps to reproduce
- Attach screenshots if helpful

**Feature Requests:**
- [GitHub Issues](https://github.com/blamechris/archery-apprentice/issues)
- Label as "enhancement"
- Describe the feature and use case

**Questions:**
- [GitHub Discussions](https://github.com/blamechris/archery-apprentice/discussions)
- Search existing discussions first
- Be specific about your question

### Quick Self-Help

**Try these first:**
1. Restart the app
2. Check for updates
3. Clear app cache (not data)
4. Restart device
5. Review this troubleshooting guide

---

## Known Limitations

**Equipment Deletion:**
- Bow setups can't be permanently deleted (soft delete only)
- Equipment used in rounds is preserved for history

**Round Editing:**
- Can't edit scores after completing a round
- Catch mistakes before completion

**Multi-Participant:**
- Maximum 4 participants per round
- Can't add/remove participants after round starts

**Scoring Systems:**
- Can't change scoring system mid-round
- Must complete or cancel first

**Setup Versioning:**
- Equipment changes auto-create versions
- Can't manually control version numbers

---

## Tips to Avoid Common Issues

### Equipment Management
- ✅ Fill in Brand and Model for all equipment
- ✅ Use descriptive names for bow setups
- ✅ Select bow setup when creating rounds
- ❌ Don't delete equipment still in use

### Scoring
- ✅ Enter all arrow scores before moving to next end
- ✅ Verify end total before continuing
- ✅ Select correct scoring system when creating round
- ❌ Don't cancel rounds just because you shot poorly

### Multi-Participant
- ✅ Add all guests before starting round
- ✅ Switch participants before entering their scores
- ✅ Verify participant name before each end
- ❌ Don't try to add participants mid-round

### Performance
- ✅ Clear cache periodically
- ✅ Keep app updated
- ✅ Archive old rounds when list gets large
- ❌ Don't run many apps simultaneously

---

## Related Documentation

- [Quick Start Guide](../quick-start/) - Basics of using the app
- [Reference Guide](../reference/) - Terminology and definitions
- [Equipment Tasks](../how-to/equipment-tasks/) - Equipment management help
- [Scoring Scenarios](../how-to/scoring-scenarios/) - Scoring workflows

---

**Still having issues? [Report on GitHub](https://github.com/blamechris/archery-apprentice/issues) with details.**
