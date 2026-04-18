# KeySafe — Zero-Knowledge Password Manager
### Mobile Application Project Report

---

## Table of Contents

1. [Business Scenario & Problem Statement](#1-business-scenario--problem-statement)
2. [Solution Overview](#2-solution-overview)
3. [System Architecture](#3-system-architecture)
4. [Database Schema (Go Backend)](#4-database-schema-go-backend)
5. [Flutter Application Structure](#5-flutter-application-structure)
6. [Local Resources](#6-local-resources)
7. [Feature Flowcharts](#7-feature-flowcharts)
8. [API Endpoints](#8-api-endpoints)
9. [Security Model](#9-security-model)
10. [Testing & Quality](#10-testing--quality)

---

## 1. Business Scenario & Problem Statement

### Background
Password management is a critical challenge for modern digital users. The average person manages over 100 online accounts, yet 65% reuse the same password across multiple sites (Verizon DBIR, 2023). Traditional password managers store encrypted vaults on their servers, creating a centralised point of failure — if the server is compromised, user data is at risk.

### Problem Statement
Existing solutions suffer from three key weaknesses:

| Problem | Impact |
|---------|--------|
| **Server-side decryption** | Provider can technically access user passwords |
| **Single-platform lock-in** | Difficult to export/import between managers |
| **Opaque breach detection** | Users aren't proactively warned about compromised passwords |

### Target Users
- **Primary:** Individual users aged 18–45 who are security-conscious but non-technical
- **Secondary:** Small business employees managing shared service credentials

### Business Goal
KeySafe provides a **zero-knowledge** password manager: passwords are encrypted on-device before ever reaching the server. Even a full server breach exposes only encrypted blobs, not readable passwords.

---

## 2. Solution Overview

KeySafe is a cross-platform mobile application (Android + iOS) built with **Flutter**, backed by a **Go REST API** on Render, with **PostgreSQL** (Supabase) as the database.

### Core Value Proposition
```
Zero-Knowledge Security:  Your master password never leaves your device.
Offline-First:            The vault works without an internet connection.
Multi-Platform:           Android and iOS from a single codebase.
Open Import/Export:       CSV import (Apple Passwords, 1Password, Bitwarden compatible).
```

### Key Features
- 🔐 **Encrypted Vault** — AES-GCM encryption with PBKDF2 key derivation
- 🤳 **Biometric Unlock** — Face ID / Fingerprint via device keychain
- 🔒 **Auto-lock** — Configurable auto-lock on app backgrounding
- 🔍 **Security Dashboard** — Password strength analysis + HIBP breach detection
- 📶 **Wi-Fi Password Manager** — Separate section for Wi-Fi credentials
- 📲 **QR Code Sharing** — Share credentials securely via scannable QR
- 📥 **CSV Import** — Import passwords from Apple Passwords, Chrome, Bitwarden, 1Password
- 📤 **Vault Export** — Export as password-protected ZIP file
- 🗑️ **Recently Deleted** — 30-day soft-delete trash bin
- 🔔 **Notifications** — Security and clipboard alerts
- 🌙 **Dark Mode** — Full dark/light theme support

---

## 3. System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────┐
│               Flutter App                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │   Auth   │  │  Vault   │  │ Settings │  │
│  │  Feature │  │  Feature │  │  Feature │  │
│  └──────────┘  └──────────┘  └──────────┘  │
│  ┌──────────────────────────────────────┐   │
│  │          Riverpod State Layer        │   │
│  └──────────────────────────────────────┘   │
│  ┌───────────┐  ┌───────────────────────┐   │
│  │  SQLite   │  │  Flutter Secure       │   │
│  │ (Offline) │  │  Storage (Keychain)   │   │
│  └───────────┘  └───────────────────────┘   │
└──────────────────────┬──────────────────────┘
                       │ HTTPS (Dio + JWT)
┌──────────────────────▼──────────────────────┐
│              Go REST API (Render)            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  /auth   │  │  /vault  │  │  /wifi   │  │
│  └──────────┘  └──────────┘  └──────────┘  │
└──────────────────────┬──────────────────────┘
                       │ PostgreSQL driver
┌──────────────────────▼──────────────────────┐
│         Supabase PostgreSQL Database         │
│  users │ passwords │ categories │ wifi_pw    │
└─────────────────────────────────────────────┘
```

### Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Frontend | Flutter 3.x | Cross-platform UI |
| State Management | Riverpod 2.x | Reactive state |
| Navigation | go_router 14.x | Declarative routing |
| Cryptography | PointyCastle + crypto | AES-GCM + PBKDF2 |
| Local Storage | SQLite (sqflite) | Offline-first vault cache |
| Secure Storage | flutter_secure_storage | AES key + tokens in keychain |
| Networking | Dio 5.x | HTTP client with auth interceptor |
| Backend | Go 1.21 + Chi Router | REST API |
| Database | PostgreSQL 15 (Supabase) | Persistent storage |
| Hosting | Render.com | API deployment |

---

## 4. Database Schema (Go Backend)

### users

| Column | Type | Description |
|--------|------|-------------|
| id | UUID PK | Auto-generated |
| email | VARCHAR(255) UNIQUE | Login email |
| username | VARCHAR(100) UNIQUE | Display name |
| password_hash | VARCHAR(255) | bcrypt hash of login password |
| master_key_hash | VARCHAR(255) | bcrypt hash of master key (for verification) |
| salt | VARCHAR(255) | Key derivation salt |
| two_factor_enabled | BOOLEAN | 2FA flag |
| two_factor_secret | VARCHAR(255) | TOTP secret |
| created_at | TIMESTAMPTZ | Account creation time |
| updated_at | TIMESTAMPTZ | Last profile update |
| last_login | TIMESTAMPTZ | Last successful login |
| is_active | BOOLEAN | Account active flag |
| email_verified | BOOLEAN | Email verification status |
| verification_token | VARCHAR(255) | Email verification token |
| reset_token | VARCHAR(255) | Password reset token |
| reset_token_expires | TIMESTAMPTZ | Reset token expiry |

### passwords

| Column | Type | Description |
|--------|------|-------------|
| id | UUID PK | Auto-generated |
| user_id | UUID FK → users | Owner |
| category_id | UUID FK → categories | Optional category |
| website | VARCHAR(255) | Service name |
| username | VARCHAR(255) | Username/email for the service |
| email | VARCHAR(255) | Associated email |
| password_encrypted | TEXT | AES-GCM ciphertext (base64) |
| notes_encrypted | TEXT | Encrypted notes |
| favicon_url | TEXT | Service favicon URL |
| url | TEXT | Full URL |
| is_favorite | BOOLEAN | Starred flag |
| password_strength | INTEGER | 0-100 strength score |
| last_password_change | TIMESTAMPTZ | Last password update |
| password_history | JSONB | Previous encrypted passwords |
| tags | TEXT[] | Searchable tags |
| created_at | TIMESTAMPTZ | Entry creation |
| updated_at | TIMESTAMPTZ | Last modification |
| accessed_at | TIMESTAMPTZ | Last access |
| access_count | INTEGER | Access counter |

### categories

| Column | Type | Description |
|--------|------|-------------|
| id | UUID PK | Auto-generated |
| user_id | UUID FK → users | Owner |
| name | VARCHAR(100) | Category name |
| color | VARCHAR(7) | Hex color code |
| icon | VARCHAR(50) | Material icon name |
| is_default | BOOLEAN | Built-in category flag |
| sort_order | INTEGER | Display order |
| created_at | TIMESTAMPTZ | — |
| updated_at | TIMESTAMPTZ | — |

### wifi_passwords

| Column | Type | Description |
|--------|------|-------------|
| id | UUID PK | Auto-generated |
| user_id | UUID FK → users | Owner |
| network_name | VARCHAR(255) | Wi-Fi SSID |
| password_encrypted | TEXT | AES-GCM ciphertext |
| security_type | VARCHAR(20) | WPA2, WPA3, WEP, Open |
| notes_encrypted | TEXT | Optional notes |
| is_favorite | BOOLEAN | Starred flag |
| location | VARCHAR(255) | Physical location (e.g. "Home") |
| created_at | TIMESTAMPTZ | — |
| updated_at | TIMESTAMPTZ | — |
| accessed_at | TIMESTAMPTZ | — |
| access_count | INTEGER | Access counter |

### audit_logs

| Column | Type | Description |
|--------|------|-------------|
| id | UUID PK | Auto-generated |
| user_id | UUID FK → users | Actor |
| action | VARCHAR(100) | Action type (LOGIN, CREATE, DELETE…) |
| resource_type | VARCHAR(50) | passwords, wifi_passwords, users |
| resource_id | UUID | ID of affected resource |
| ip_address | INET | Client IP |
| user_agent | TEXT | Browser/app user agent |
| details | JSONB | Arbitrary event metadata |
| created_at | TIMESTAMPTZ | Event time |

### Entity Relationship Diagram

```
users ──< passwords ──< (implicit: audit_logs)
  │           │
  │           └──> categories
  │
  ├──< wifi_passwords
  ├──< user_sessions
  ├──< categories
  └──< audit_logs
```

---

## 5. Flutter Application Structure

```
lib/
├── app.dart                    # Router + shell scaffold
├── main.dart                   # App entry point + providers
├── core/
│   ├── constants/
│   │   ├── api_endpoints.dart  # Base URL + route constants
│   │   └── routes.dart         # GoRouter path constants
│   ├── providers/
│   │   └── categories_provider.dart  # Custom categories (secure storage)
│   ├── services/
│   │   ├── biometric_service.dart    # Local Auth wrapper
│   │   ├── clipboard_service.dart    # Auto-clear clipboard
│   │   └── notification_service.dart # flutter_local_notifications
│   ├── settings/
│   │   ├── app_settings.dart         # Settings model
│   │   └── app_settings_provider.dart # Settings state + persistence
│   ├── theme/
│   │   ├── app_colors.dart     # Brand colours
│   │   └── app_theme.dart      # Light/dark theme configs
│   ├── utils/
│   │   └── service_suggestions.dart  # Service name → URL lookup
│   └── widgets/
│       ├── cat_filter_chip.dart
│       ├── category_dropdown.dart    # Shared category picker + add
│       ├── category_icon.dart
│       └── strength_badge.dart
├── crypto/
│   ├── crypto_service.dart     # AES-GCM encrypt/decrypt + PBKDF2
│   └── key_store.dart          # Keychain/Keystore read/write
├── features/
│   ├── auth/
│   │   ├── data/auth_repository.dart
│   │   ├── domain/auth_state.dart (freezed)
│   │   ├── presentation/
│   │   │   ├── splash_screen.dart
│   │   │   ├── onboarding_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── lock_screen.dart
│   │   └── providers/auth_provider.dart
│   ├── profile/
│   │   ├── data/profile_repository.dart
│   │   └── presentation/profile_screen.dart
│   ├── qr/
│   │   └── presentation/
│   │       ├── qr_scan_screen.dart   # Scan keysafe:// URIs
│   │       └── qr_share_screen.dart  # Share via QR + expiry timer
│   ├── security/
│   │   └── presentation/security_screen.dart  # HIBP breach check
│   ├── settings/
│   │   ├── data/vault_export_service.dart
│   │   └── presentation/
│   │       ├── settings_screen.dart
│   │       └── biometric_settings_screen.dart
│   ├── vault/
│   │   ├── data/
│   │   │   ├── vault_local_db.dart   # SQLite + secure snapshot
│   │   │   └── vault_repository.dart # API + offline-first CRUD
│   │   ├── domain/vault_entry.dart (freezed)
│   │   ├── presentation/
│   │   │   ├── home_screen.dart
│   │   │   ├── password_detail_screen.dart
│   │   │   ├── add_password_screen.dart
│   │   │   ├── edit_password_screen.dart
│   │   │   ├── generator_screen.dart
│   │   │   ├── recently_deleted_screen.dart
│   │   │   └── import_vault_screen.dart
│   │   └── providers/vault_provider.dart
│   └── wifi/
│       ├── domain/wifi_entry.dart (freezed)
│       └── presentation/wifi_screen.dart
└── network/
    ├── auth_interceptor.dart   # JWT attach + refresh
    └── dio_client.dart         # Dio factory
```

---

## 6. Local Resources

KeySafe uses **three** primary local resources on the mobile device:

---

### 6.1 Local Storage (SQLite + Flutter Secure Storage)

**Purpose:** Offline-first vault access. The app works without internet connectivity.

**Implementation:**
- **SQLite** (`sqflite` package) stores full vault entries in a local database at `keysafe_vault.db`
- **Flutter Secure Storage** stores an encrypted JSON snapshot of the vault and all secrets (AES key, JWT tokens, user info) in the Android Keystore / iOS Keychain
- **Soft-delete trash table** (`deleted_vault_entries`) keeps deleted entries for 30 days

**Two-phase Load Strategy:**
```
App opens
   │
   ├─1─► Read SQLite cache → render immediately (no loading spinner)
   │
   └─2─► Background: if online → sync from server → update SQLite → refresh UI
```

**Why it matters:** Users see their passwords instantly. Server sync happens silently in the background.

---

### 6.2 Biometrics (Face ID / Fingerprint)

**Purpose:** Quick vault unlock without typing the master password every time.

**Implementation:**
- `local_auth` package for biometric authentication
- AES encryption key is stored in the device keychain after first login
- On app resume (if locked), `LocalAuthentication.authenticate()` is called
- If biometrics fail/cancel → user falls back to master password entry

**Biometric Flow:**
```
App resumes from background
        │
        ▼
   Is vault locked?
        │
        ├─ No ──► Proceed normally
        │
        └─ Yes ──► Biometrics enabled?
                        │
                        ├─ Yes ──► Prompt fingerprint/face
                        │              │
                        │              ├─ Success ──► Load AES key from keychain ──► Unlock
                        │              └─ Fail    ──► Show master password screen
                        │
                        └─ No ──► Show master password screen
```

**Settings:** Managed in `Settings → Biometric Unlock` with ability to enable/disable per device.

---

### 6.3 Notifications (Local Push Notifications)

**Purpose:** Alert users to security events and clipboard operations without requiring server push.

**Implementation:**
- `flutter_local_notifications` package
- Notification channel: `keysafe_channel` (Android) / default (iOS)
- Permission requested on first notification-dependent action

**Notification Events:**

| Event | Notification | ID |
|-------|-------------|-----|
| Password copied to clipboard | "Clipboard will clear in 30s" | 100 |
| Vault wiped | "All vault entries deleted" | 102 |
| Clipboard cleared | "Clipboard cleared" | 101 |

**Permission Flow:**
```
User toggles "Notifications" in Settings
         │
         ▼
NotificationService.requestPermissions()
         │
         ├─ Granted ──► Save setting → show notification events
         └─ Denied  ──► Revert toggle → show snackbar "Permission denied"
```

---

## 7. Feature Flowcharts

### 7.1 Authentication Flow

```
App Launch
    │
    ▼
SplashScreen
    │
    ├─ Has access token? ──► Yes ──► Has AES key? ──► Yes ──► HomeScreen
    │                                               └─ No  ──► LockScreen
    │
    └─ No ──► Onboarding seen? ──► No  ──► OnboardingScreen ──► RegisterScreen
                                └─ Yes ──► LoginScreen

LoginScreen
    │
    ├─ Email + Password
    ▼
POST /auth/login
    │
    ├─ 200 OK ──► Store JWT + AES key ──► HomeScreen
    └─ Error  ──► Show snackbar
```

### 7.2 Add Password Flow

```
HomeScreen → FAB "+"
      │
      ▼
AddPasswordScreen
      │
      ├─ Type service name ──► Auto-suggest URL (Netflix → netflix.com)
      ├─ Enter username/email
      ├─ Enter password (or tap 🎲 to open GeneratorScreen)
      ├─ Select/create category
      │
      ▼
VaultRepository.create()
      │
      ├─ Encrypt password (AES-GCM, key from KeyStore)
      ├─ POST /vault (if online)  ──► 200 OK
      │                           └── Error ──► Queue in pending_ops
      └─ Upsert to SQLite cache
```

### 7.3 Password Generator Flow

```
GeneratorScreen opens
      │
      ├─ Mode: Random
      │       ├─ Length slider (6–64)
      │       ├─ Toggle uppercase / numbers / symbols / avoid ambiguous
      │       └─ Generates: random chars, guaranteed at least 1 of each class
      │
      └─ Mode: Memorable
              ├─ Consonant-Vowel syllable groups (CVC + CVC)
              ├─ 4-digit number segment
              ├─ Optional symbol at end
              └─ Example: "Kobi-4729-Welu!"
      │
      ▼
User taps "Regenerate" ──► New password generated + haptic
User taps "Copy"       ──► Clipboard + schedule clear in 30s
User taps "Use This Password" ──► Returns password to AddPasswordScreen
```

### 7.4 Vault Wipe Flow (with OTP)

```
Settings → Wipe Vault
      │
      ├─ Check vault not empty
      │
      ▼
Show masked email: "We will send OTP to na****o@gmail.com"
      │
      ▼
Open email composer (flutter_email_sender)
      │
User sends OTP email to themselves
      │
      ▼
Enter OTP dialog
      │
      ├─ OTP correct ──► Enter "DELETE PASSWORDS" confirmation
      │                       │
      │                       └─ Correct ──► Delete all entries ──► Show notification
      └─ OTP wrong   ──► "OTP verification failed" snackbar
```

### 7.5 QR Code Share Flow

```
PasswordDetailScreen → Share → QR Code
      │
      ▼
QrShareScreen
      │
      ├─ Encode as: keysafe://import?service=Netflix&username=...&enc=...
      ├─ Show QR + 60-second countdown timer (auto-dismiss)
      ├─ Timer icon → extend to 30s/1m/2m/5m
      └─ Share button → capture QR as PNG → share via system sheet

Receiver scans QR
      │
      ▼
QrScanScreen detects keysafe:// scheme
      │
      ▼
Show "Import Password?" dialog with service/username
      │
      ├─ Import ──► Navigate to AddPasswordScreen (pre-filled)
      └─ Cancel ──► Reset scanner
```

### 7.6 Import Vault (CSV) Flow

```
Settings → Import Vault (CSV)
      │
      ▼
ImportVaultScreen
      │
      ▼
File Picker → Choose .csv file
      │
      ▼
Parse CSV:
  - Auto-detect header columns (name/service, username, password, url, notes, category)
  - Compatible with: Apple Passwords, Chrome, Bitwarden, 1Password, LastPass
      │
      ▼
Show preview (first 5 entries)
      │
      ▼
User taps "Import N Passwords"
      │
      ▼
For each row: VaultRepository.create() → encrypt + save
      │
      ▼
Progress bar → "Imported X / N"
      │
      ▼
Success snackbar → Navigate back to home
```

### 7.7 Back Navigation Flow

```
Any Screen (Security / Profile / Settings)
      │
      Android back button pressed
      │
      ▼
PopScope(canPop: false)
      │
      └─ context.go(Routes.home) ──► HomeScreen

HomeScreen (or OnboardingScreen)
      │
      Android back button pressed (1st time)
      │
      ▼
_lastBackPress = now
"Press back again to exit" snackbar

      │
      Back pressed again within 2 seconds
      │
      ▼
AlertDialog: "Exit KeySafe?"
      │
      ├─ Exit ──► SystemNavigator.pop()
      └─ Stay ──► Dismiss dialog
```

---

## 8. API Endpoints

Base URL: `https://amoako-pass-go.onrender.com/api/v1`

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/auth/register` | Create new account | No |
| POST | `/auth/login` | Login + get JWT | No |
| POST | `/auth/logout` | Invalidate refresh token | Yes |
| POST | `/auth/refresh` | Refresh access token | Yes (refresh) |
| GET | `/vault` | Fetch all vault entries | Yes |
| POST | `/vault` | Create vault entry | Yes |
| PUT | `/vault/:id` | Update vault entry | Yes |
| DELETE | `/vault/:id` | Delete vault entry | Yes |
| GET | `/vault/export` | Export vault as JSON | Yes |
| GET | `/wifi` | Fetch all Wi-Fi entries | Yes |
| POST | `/wifi` | Create Wi-Fi entry | Yes |
| PUT | `/wifi/:id` | Update Wi-Fi entry | Yes |
| DELETE | `/wifi/:id` | Delete Wi-Fi entry | Yes |
| GET | `/user/profile` | Get user profile stats | Yes |
| GET | `/util/hibp-check` | Check password against HIBP | Yes |

### Authentication
All authenticated endpoints require: `Authorization: Bearer <access_token>`

Token refresh is handled automatically by `AuthInterceptor` (Dio interceptor) when a 401 is received.

---

## 9. Security Model

### Zero-Knowledge Encryption

```
User types master password
         │
         ▼
PBKDF2(masterPassword, salt=userId, iterations=100000, keyLen=32)
         │
         ▼
AES-256-GCM key (stored ONLY in device keychain, never sent to server)
         │
         ▼
Encrypt each password:
  ciphertext = AES-GCM.encrypt(plainPassword, key, randomNonce)
  stored = base64(nonce + ciphertext + tag)
```

**What the server sees:**  Base64-encoded encrypted blobs. Without the AES key (which never leaves the device), they are computationally infeasible to decrypt.

### Master Password Change
1. Send OTP via email composer to verify identity
2. Verify current master password matches stored hash
3. Derive new AES key from new master password
4. Store new key + hash locally

> **Note:** Existing vault entries are not re-encrypted on master password change in the current version. This means the encrypted blobs in the backend were encrypted with the old key. The app re-derives the key at login time from whatever password you provide. A full re-encryption migration is planned.

### Threat Model

| Threat | Mitigation |
|--------|-----------|
| Server database breach | Passwords encrypted client-side; server never has keys |
| Device theft (unlocked) | Auto-lock configurable (30s – Never) |
| Device theft (locked) | Biometric or master password required to unlock |
| Clipboard sniffing | Auto-clear clipboard after configurable delay (15–60s) |
| Compromised passwords | HIBP k-anonymity check against 600M+ breached passwords |
| Replay attacks | JWT with short expiry + refresh token rotation |

---

## 10. Testing & Quality

### Static Analysis
```bash
flutter analyze   # Zero issues (as of last build)
```

### Build
```bash
flutter build apk --release      # Android
flutter build ipa                 # iOS
```

### Manual Test Checklist

- [ ] Register new account with full name
- [ ] Login with email + password
- [ ] Add password (verify URL auto-fill for Netflix, GitHub, etc.)
- [ ] Generator: Random mode produces 16-char password with uppercase + numbers + symbols
- [ ] Generator: Memorable mode produces pronounceable password like "Kobi-4729-Welu!"
- [ ] Use generated password in Add Password screen
- [ ] Edit password
- [ ] Delete password → appears in Recently Deleted
- [ ] Restore from Recently Deleted
- [ ] Import CSV from Apple Passwords export
- [ ] Export vault as email attachment
- [ ] Share password via QR → scan on same/other device
- [ ] Security dashboard shows correct strength breakdown
- [ ] HIBP breach check on a known-breached password
- [ ] Change master password (OTP flow)
- [ ] Wipe vault (OTP + masked email + confirmation phrase)
- [ ] Logout shows consequences dialog
- [ ] Back button from Security → goes to Home
- [ ] Double back on Home → Exit dialog
- [ ] Biometric unlock after auto-lock
- [ ] Dark mode toggle
- [ ] Auto-lock: lock after 30 seconds of backgrounding
- [ ] Add custom category → appears in filter chips

---

*Document last updated: April 2026*  
*Application version: 1.0.0*  
*Backend: amoako-pass-go on Render*  
*Database: Supabase PostgreSQL*
