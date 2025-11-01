---
title: "[Guide Title]"
description: "Brief description (max 160 chars)"
category: "development"
audience: ["developers"]
difficulty: "beginner | intermediate | advanced"
status: "draft"
last_updated: "YYYY-MM-DD"
tags:
  primary: []
  topic: []
  layer: []  # ui, viewmodel, repository, database, service
related_docs:
  - title: ""
    path: ""
    relationship: "prerequisite | follow-up | related"
prerequisites:
  - knowledge: []  # e.g., "Kotlin coroutines", "MVVM pattern"
  - tools: []      # e.g., "Android Studio", "Firebase CLI"
---

[Home](/) > [Development](/Development/) > [Category] > [Guide Title]

---

# [Guide Title]

**Status:** 🟡 Draft
**Last Updated:** YYYY-MM-DD
**Audience:** 👨‍💻 Developers
**Difficulty:** ⭐⭐ Intermediate

---

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Architecture Context](#architecture-context)
- [Step-by-Step Guide](#step-by-step-guide)
- [Code Examples](#code-examples)
- [Testing](#testing)
- [Best Practices](#best-practices)
- [Common Pitfalls](#common-pitfalls)
- [Troubleshooting](#troubleshooting)

---

## Overview

### What This Guide Covers

[Clear explanation of what developers will learn]

### Why It Matters

[Explain the importance and use cases]

### What You'll Build

[Describe the end result of following this guide]

---

## Prerequisites

### Required Knowledge
- **[Topic 1]:** [Brief description of what you need to know]
- **[Topic 2]:** [Brief description]

### Required Tools
- **[Tool 1]:** [Version requirements]
- **[Tool 2]:** [Version requirements]

### Required Setup
- [ ] [Setup step 1]
- [ ] [Setup step 2]
- [ ] [Setup step 3]

---

## Architecture Context

### Where This Fits

[Explain where this feature/component fits in the architecture]

> **[DIAGRAM PLACEHOLDER]**
> Description: Architecture diagram showing where this fits
> Path: `/assets/images/diagrams/architecture/[guide-name]-context.png`

### Related Components

| Component | Layer | Relationship |
|-----------|-------|--------------|
| [Component 1] | [Layer] | [How it relates] |
| [Component 2] | [Layer] | [How it relates] |

### Design Patterns Used

- **[Pattern 1]:** [Why it's used here]
- **[Pattern 2]:** [Why it's used here]

---

## Step-by-Step Guide

### Step 1: [Action Title]

**Goal:** [What this step accomplishes]

**Implementation:**

```kotlin
// Location: path/to/file.kt

// Brief explanation of what this code does
class ExampleClass {
    // Implementation details
}
```

**Key Points:**
- Point 1
- Point 2
- Point 3

**Why This Approach:**
[Explanation of design decisions]

---

### Step 2: [Action Title]

**Goal:** [What this step accomplishes]

**Implementation:**

```kotlin
// Location: path/to/file.kt

// Code example
```

**Key Points:**
- Point 1
- Point 2

---

### Step 3: [Action Title]

[Continue with additional steps as needed]

---

## Code Examples

### Example 1: [Common Use Case]

**Scenario:** [Describe when you'd use this]

```kotlin
// Complete working example
class Example {
    fun demonstrateFeature() {
        // Implementation
    }
}
```

**Explanation:**
- Line 1-5: [What this section does]
- Line 6-10: [What this section does]

---

### Example 2: [Another Use Case]

**Scenario:** [Describe when you'd use this]

```kotlin
// Complete working example
```

---

## Testing

### Unit Tests

**What to Test:**
- [ ] [Test case 1]
- [ ] [Test case 2]
- [ ] [Test case 3]

**Example Test:**

```kotlin
// Location: path/to/test/file.kt

@Test
fun `test description`() {
    // Given
    val setup = TestSetup()

    // When
    val result = performAction()

    // Then
    assertThat(result).isEqualTo(expected)
}
```

### Integration Tests

[If applicable, describe integration test requirements]

---

## Best Practices

### Do's ✅

1. **[Practice 1]:** [Why it's important]
   ```kotlin
   // Good example
   ```

2. **[Practice 2]:** [Why it's important]
   ```kotlin
   // Good example
   ```

### Don'ts ❌

1. **[Anti-pattern 1]:** [Why to avoid]
   ```kotlin
   // Bad example
   ```

2. **[Anti-pattern 2]:** [Why to avoid]
   ```kotlin
   // Bad example
   ```

---

## Common Pitfalls

### Pitfall 1: [Issue Description]

**Problem:**
[Describe what developers often get wrong]

**Solution:**
```kotlin
// Correct approach
```

**Why It Happens:**
[Explanation]

---

### Pitfall 2: [Issue Description]

**Problem:**
[Description]

**Solution:**
```kotlin
// Correct approach
```

---

## Troubleshooting

### Issue: [Problem]

**Symptoms:**
- Symptom 1
- Symptom 2

**Diagnosis:**
```bash
# Commands to diagnose
./gradlew testDebugUnitTest --tests="*SpecificTest*"
```

**Solution:**
[Step-by-step fix]

---

### Issue: [Another Problem]

**Symptoms:**
- Symptom 1

**Solution:**
[Fix]

---

## Performance Considerations

> **⚡ Performance Tips**
> - **[Tip 1]:** [Description]
> - **[Tip 2]:** [Description]

---

## Related Documentation

### Prerequisites
- [Document Title](/path/to/doc.md) - What you should understand first

### Next Steps
- [Document Title](/path/to/doc.md) - What to learn next

### Reference Documentation
- [API Reference](/Technical-Reference/API/[component].md)
- [Architecture Overview](/Development/Architecture/[topic].md)

---

## Code References

**Files Modified/Created:**
- `app/src/main/kotlin/path/to/file.kt:123` - [Description]
- `app/src/test/kotlin/path/to/test.kt:45` - [Description]

---

## Feedback

Found an issue or have a suggestion? [Report it on GitHub](https://github.com/blamechris/archery-apprentice/issues/new?labels=documentation&template=documentation-issue.md)

---

**Document Info:**
- **Version:** 1.0
- **Last Updated:** YYYY-MM-DD
- **Maintained By:** [Team/Person]
- **Related PRs:** #123, #456
