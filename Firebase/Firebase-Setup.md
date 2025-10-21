---
title: Firebase Setup Guide
tags:
  - firebase
  - setup
  - configuration
  - deployment
created: 2025-10-08
source: docs/firebase/FIREBASE_SETUP.md
status: current
---

# Firebase Setup

This project uses Firebase for authentication and other services. The `google-services.json` file contains sensitive credentials and is not included in version control.

## Local Development Setup

### 1. Get Firebase Configuration

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `archeryapprentice-48e09`
3. Go to Project Settings > General
4. Download the `google-services.json` file
5. Place it in the `app/` directory

### 2. Verify Setup

```bash
# The file should exist here:
app/google-services.json

# And should contain your project configuration
```

## CI/CD Setup

The CI/CD pipeline generates `google-services.json` from GitHub Secrets. Configure these in your repository settings.

### Required GitHub Secrets

- `FIREBASE_PROJECT_NUMBER`: Your Firebase project number
- `FIREBASE_PROJECT_ID`: Your Firebase project ID (e.g., `archeryapprentice-48e09`)
- `FIREBASE_STORAGE_BUCKET`: Your Firebase storage bucket
- `FIREBASE_MOBILE_SDK_APP_ID`: Your mobile SDK app ID
- `FIREBASE_OAUTH_CLIENT_ID`: Your OAuth client ID
- `FIREBASE_API_KEY`: Your Firebase API key

### Setting Up Secrets

1. Go to your GitHub repository
2. Navigate to Settings > Secrets and variables > Actions
3. Add each secret with the corresponding value from your `google-services.json`

## Security Notes

**⚠️ Important Security Practices:**

- **Never commit `google-services.json`** to version control
- The file is automatically ignored by `.gitignore`
- Use environment variables or secrets for CI/CD environments
- Rotate API keys periodically for security
- Keep Firebase console access restricted to authorized team members

## Template File

A template file (`google-services.json.template`) is provided showing the expected structure with placeholder variables.

## Firebase Services Used

### Authentication

- **Email/Password** authentication
- **Google Sign-in** provider
- Anonymous authentication for testing
- Account linking capabilities

### Firestore Database

- **Tournaments**: Tournament data and real-time sync
- **Participants**: Tournament participant information
- **Scores**: Real-time score submission and leaderboards
- **Security**: Comprehensive security rules

### Cloud Functions (Planned)

- Tournament lifecycle management
- Score validation and anti-cheating
- Leaderboard calculations
- Notifications and announcements

## Troubleshooting

### google-services.json Not Found

```bash
# Verify file location
ls -la app/google-services.json

# If missing, download from Firebase Console
```

### Authentication Not Working

1. Verify SHA-1 fingerprints are configured in Firebase Console
2. Check that google-services.json is in app/ directory
3. Ensure Firebase Authentication is enabled in console
4. Verify internet connection for first-time setup

### Firestore Security Rules Blocking Access

1. Review security rules in Firebase Console
2. Check user authentication state
3. Verify user permissions for tournament access
4. Review Firestore logs for detailed error messages

## Related Documentation

- [[Firebase-Integration-Plan]] - Complete Firebase integration strategy
- [[Tournament-Discovery]] - Tournament system implementation
- [[System-Architecture]] - Overall system architecture

---

*Last Updated: 2025*
*Source: `docs/firebase/FIREBASE_SETUP.md`*