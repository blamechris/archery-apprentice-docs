---
title: Archery Apprentice - Project Overview
tags:
  - project
  - overview
  - android
created: 2025-10-08
---

# Archery Apprentice

## Project Information

**Project Name:** Archery Apprentice

**Tech Stack:**
- **Language:** Kotlin
- **UI Framework:** Jetpack Compose
- **Database:** Room Database
- **Architecture:** MVVM (Model-View-ViewModel)
- **Platform:** Android

## Purpose

Android application for archery equipment management and scoring. The app helps archers:
- Manage and track archery equipment (bows, arrows, sights, etc.)
- Score archery rounds and tournaments
- Analyze performance statistics
- Track equipment performance over time

## Current Status

**Completion:** ~85% core features

### Completed Features
- Equipment management system
- Round scoring functionality
- Tournament support
- Analytics and statistics
- Multi-participant scoring

### In Progress
- Performance optimizations
- Code refactoring (reducing god classes)
- Enhanced test coverage
- Database query optimization

## Key Challenges

1. **God Classes:** RoundViewModel (2,058 lines), ActiveScoringScreen (1,896 lines)
2. **Performance:** Database queries need optimization
3. **Architecture:** Gradual refactoring while maintaining stability

## Links

- [[MVVM-Patterns|Architecture Patterns]]
- [[Development-Journal/2025-10-08-Session|Latest Session]]
