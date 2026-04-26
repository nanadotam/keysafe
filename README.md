# KeySafe

KeySafe is a Flutter-based mobile password manager built as a final-year mobile application project. It is designed around a zero-knowledge model: sensitive credential data is encrypted on the device before it is stored or synced, and the app uses several mobile-local resources to improve security, usability, and resilience.

## Project Links

- Frontend repository: https://github.com/nanadotam/keysafe
- Backend repository: https://github.com/nanadotam/amoako-pass-go
- Demo video placeholder: https://www.youtube.com/watch?v=YOUR_DEMO_VIDEO_ID
- Backend API base URL: https://amoako-pass-go.onrender.com/api/v1

## Overview

The app targets users who manage many personal, work, and shared credentials and need a secure mobile experience that still works well when connectivity is unreliable. KeySafe combines:

- device-side encryption and secure key storage
- offline-first SQLite caching
- biometric and device-auth based unlock
- security monitoring for weak and compromised passwords
- QR-based credential sharing
- import/export utilities for portability

## Main Features

### 1. Authentication and session security

- User login and registration against a Go REST backend
- Local AES key derivation from the master password
- JWT-based authenticated API access
- Biometric or device-auth unlock for returning users
- Auto-lock when the app backgrounds

### 2. Encrypted password vault

- Create, edit, view, search, and delete password entries
- Organize entries by category
- Password strength scoring
- Password generator integration when creating or updating entries
- Recently deleted flow for recovery

### 3. Offline-first vault behavior

- SQLite is used as the first-read source for the vault
- Cached entries remain available without internet
- Pending create, update, and delete operations can be queued locally
- Background refresh updates the local cache when connectivity returns

### 4. Security dashboard

- Weak password detection
- Reused password analysis
- Compromised password checks through the backend utility endpoint
- Login history and trusted-location review

### 5. Import, export, and sharing

- CSV import flow for migrating password data
- Password-protected vault export flow
- QR code generation for short-lived credential sharing
- QR code scanning module for import workflows

## Local Resources Used

One of the strongest parts of the app, relative to the project brief, is the use of local mobile resources. The implementation supports more than the required four.

| Local resource | How KeySafe uses it | Status |
|---|---|---|
| Biometric / device authentication | Unlocking the vault with fingerprint, face authentication, or device credential fallback | Implemented |
| Camera | QR scanning for credential import | Implemented |
| Geolocation | Capturing login location context and reverse geocoding it to city/country | Implemented |
| Notifications | Local security alerts, clipboard alerts, sync notices, and login-location alerts | Implemented |
| Secure storage / keychain | Persisting tokens, AES key material, and sensitive local flags | Implemented |
| SQLite local storage | Offline-first vault cache, soft-delete state, and pending operations | Implemented |
| Clipboard control | Copy-and-auto-clear flow for sensitive passwords | Implemented |
| Native splash resources | Branded startup assets and launch experience | Implemented |

## Architecture Summary

### Frontend

- Flutter for Android and iOS UI
- Riverpod for state management
- go_router for navigation
- Dio for API communication
- flutter_secure_storage for secure device persistence
- sqflite for local relational caching

### Backend

- Go REST API
- JWT authentication
- PostgreSQL / Supabase-backed data layer
- Render deployment

## Design Approach

The app is structured around feature folders and service boundaries:

- `features/auth` handles onboarding, login, lock, and session flows
- `features/vault` handles encrypted password CRUD, import, and offline cache logic
- `features/security` handles breach checks, password quality, and login history
- `features/settings` handles export, auto-lock, biometrics, notifications, and account-level flows
- `core/services` wraps device capabilities such as biometrics, notifications, clipboard, and location

This keeps UI concerns, repository logic, local persistence, and device integration reasonably separated.

## Current Strong Demo Features

These are the safest features to emphasize in a project demo and report:

- biometric unlock
- offline vault loading
- password generation and encrypted storage
- security dashboard
- login-location awareness
- QR sharing with expiry
- settings for auto-lock, clipboard clearing, and notifications

## Current Limitations

To keep the documentation accurate, these points should be stated carefully in the report or demo:

- The ambient-sensor dark mode flow has a UI configuration layer, but the live sensor stream is currently stubbed.
- The QR scan module exists, but it is not strongly integrated into the main navigation flow.
- The Wi-Fi password section exists, but it is not as complete or as central as the main vault feature.
- Backend schema alignment must match the Go backend contract for registration and login to work reliably.

## Getting Started

### Prerequisites

- Flutter 3.x
- Dart SDK compatible with the project
- Android Studio or Xcode for mobile builds
- A running backend configured with the expected database schema

### Install dependencies

```bash
flutter pub get
```

### Run on emulator or device

```bash
flutter run -d emulator-5554
```

### Analyze

```bash
flutter analyze
```

## Documentation Files

- Report markdown: [docs/KeySafe_Project_Report.md](docs/KeySafe_Project_Report.md)
- Video demo script: [docs/video_demo_script.md](docs/video_demo_script.md)
- Features and local resources deep dive: [docs/feature_design_and_local_resources.md](docs/feature_design_and_local_resources.md)

## Repository Purpose

This repository contains the Flutter mobile client. The backend service lives separately in:

- https://github.com/nanadotam/amoako-pass-go

If you are preparing a submission, replace the YouTube placeholder link above with the final public demo URL before submitting.
