# PowerShell Emoji Encoding in GitHub Actions

**Problem Discovered:** 2025-10-24
**Status:** Solved
**Impact:** Discord webhook notifications

## Problem

Emojis embedded directly in GitHub Actions YAML files get corrupted when passed to PowerShell scripts on Windows runners.

### Symptom
Discord notifications show `??` instead of emojis like 📚 or ✅.

### Root Cause
When GitHub Actions creates temporary PowerShell script files from YAML content, emojis get corrupted during the file encoding process:
- YAML contains: `title = "📚 Documentation Deployed"`
- Temp script receives: `title = "ðŸ"š Documentation Deployed"`
- PowerShell parser fails with: `Unexpected token 'š' in expression`

## Solutions Attempted

### ❌ Attempt 1: Unicode Code Points
```powershell
$bookEmoji = [char]0xD83D + [char]0xDCDA
```
**Result:** PowerShell accepted it, but Discord still displayed `??` because the encoding wasn't proper UTF-8.

### ✅ Attempt 2: UTF-8 Byte Arrays (WORKING)
```powershell
$utf8 = [System.Text.Encoding]::UTF8
$bookEmoji = $utf8.GetString([byte[]](0xF0, 0x9F, 0x93, 0x9A))  # 📚
$checkEmoji = $utf8.GetString([byte[]](0xE2, 0x9C, 0x85))      # ✅
$crossEmoji = $utf8.GetString([byte[]](0xE2, 0x9D, 0x8C))      # ❌
```

**Why It Works:**
- Constructs emoji from proper UTF-8 byte sequence
- Discord receives correctly encoded JSON
- No YAML-to-file corruption

## Implementation

### Before (Broken)
```yaml
- name: Notify Discord
  shell: powershell
  run: |
    $payload = @{
      embeds = @(
        @{
          title = "📚 Documentation Deployed"  # Gets corrupted
        }
      )
    } | ConvertTo-Json -Depth 10
```

### After (Working)
```yaml
- name: Notify Discord
  shell: powershell
  run: |
    # Use UTF-8 byte arrays to properly construct emojis
    $utf8 = [System.Text.Encoding]::UTF8
    $bookEmoji = $utf8.GetString([byte[]](0xF0, 0x9F, 0x93, 0x9A))

    $payload = @{
      embeds = @(
        @{
          title = "$bookEmoji Documentation Deployed"
        }
      )
    } | ConvertTo-Json -Depth 10

    Invoke-RestMethod -Uri $env:WEBHOOK_URL `
      -Method Post `
      -Body $payload `
      -ContentType "application/json; charset=utf-8"
```

## Common Emoji UTF-8 Encodings

| Emoji | Character | UTF-8 Bytes | PowerShell Code |
|-------|-----------|-------------|-----------------|
| ✅ | Checkmark | `E2 9C 85` | `$utf8.GetString([byte[]](0xE2, 0x9C, 0x85))` |
| ❌ | Cross Mark | `E2 9D 8C` | `$utf8.GetString([byte[]](0xE2, 0x9D, 0x8C))` |
| 📚 | Books | `F0 9F 93 9A` | `$utf8.GetString([byte[]](0xF0, 0x9F, 0x93, 0x9A))` |
| 📅 | Calendar | `F0 9F 93 85` | `$utf8.GetString([byte[]](0xF0, 0x9F, 0x93, 0x85))` |
| 🚀 | Rocket | `F0 9F 9A 80` | `$utf8.GetString([byte[]](0xF0, 0x9F, 0x9A, 0x80))` |
| ⚠️ | Warning | `E2 9A A0 EF B8 8F` | `$utf8.GetString([byte[]](0xE2, 0x9A, 0xA0, 0xEF, 0xB8, 0x8F))` |

## Finding UTF-8 Bytes for Emojis

**Option 1: Online Tool**
- Visit: https://www.fileformat.info/info/unicode/
- Search for emoji name
- Look for "UTF-8 (hex)" section

**Option 2: PowerShell**
```powershell
# Get UTF-8 bytes for an emoji
$emoji = "📚"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($emoji)
$bytes | ForEach-Object { "0x{0:X2}" -f $_ }
# Output: 0xF0 0x9F 0x93 0x9A
```

## References

- **Issue:** PR#137 self-hosted runner emoji encoding
- **Fixed In:** Commits `4181313`, `162de59`, `74a3df2`, `be14c95`
- **Affected Files:**
  - `.github/workflows/deploy-quartz.yml` (docs repo)
  - `.github/workflows/deploy-to-play-store.yml` (main repo)

## Best Practices

1. **Always use UTF-8 byte arrays** for emojis in PowerShell scripts called from GitHub Actions
2. **Add comments** explaining what emoji each byte array represents
3. **Specify charset** in `Invoke-RestMethod`: `ContentType "application/json; charset=utf-8"`
4. **Test locally** by creating a temp PowerShell script file and running it

---

**Last Updated:** 2025-10-24
**Pattern Status:** Proven, In Production
