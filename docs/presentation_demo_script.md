# KeySafe Presentation Demo Script

This script is based on the current `docs/` content and the Flutter app implementation in this repository. It is written as a slide-by-slide guide so you can present the app while clearly highlighting the local resources used on the device.

## Presentation Goal

Show that KeySafe is not just a password manager UI. It is a mobile app that actively uses device-local capabilities to improve security, speed, and usability:

- native splash screens and app assets
- secure local storage
- offline SQLite caching
- biometrics
- local notifications
- clipboard control
- location services for login awareness
- camera access for QR scanning
- temporary local files for export and QR sharing
- a sensor-based dark-mode flow in the UI architecture

## Recommended Demo Story

Use one simple story throughout the presentation:

"I am a returning user opening KeySafe on my phone, unlocking the vault, accessing a saved password instantly from local storage, seeing login-location awareness, sharing a password with QR, and showing how the app uses on-device resources to keep the experience secure and responsive."

## Slide 1: Title And Problem

### Slide title
`KeySafe: A Zero-Knowledge Mobile Vault Powered by Local Resources`

### What to say

"KeySafe is a Flutter-based password manager, but the main idea is not just storing passwords. The main idea is that security-critical work happens on the device. The app uses local mobile resources like secure storage, SQLite, biometrics, notifications, location services, camera access, and native splash assets to make the experience secure and fast."

### What to show

- Opening slide only
- Optional screenshot of the app logo or splash

## Slide 2: Launch Experience And Splash Screen

### Slide title
`First Impression: Splash Screen And App Initialization`

### What to say

"When the app launches, the first thing the user sees is a branded splash experience. This is not just decoration. It is part of the startup flow while the app checks onboarding state, package info, and authentication state. The project uses local image assets and native splash configuration so launch feels like a real mobile product rather than a plain Flutter loading screen."

### What to show in the app

- Launch the app from a cold start
- Pause briefly on the splash screen
- Point out the logo, progress indicator, and branding

### Technical points to mention

- Splash assets come from `assets/images/splash_logo.png` and `assets/images/logo.png`
- Native splash configuration is defined in `pubspec.yaml` using `flutter_native_splash`
- Android and iOS launch resources are present in platform folders

### Presenter line

"This is where the app bridges Flutter and native mobile experience. Before the user reaches the vault, the app is already using packaged local assets and native startup resources."

## Slide 3: Authentication And Secure Session Setup

### Slide title
`Secure Login: Device-Side Key Setup`

### What to say

"After login, KeySafe derives the AES vault key on the device and stores session material locally. The master password is not treated like a normal cloud-only credential. The app uses it to derive the encryption key locally, then stores only the secure artifacts needed for future access."

### What to show in the app

- Sign in as a returning user
- Point out the login UI and the zero-knowledge message

### Technical points to mention

- `AuthRepository` derives the AES key locally after login
- `KeyStore` stores:
  - AES key
  - access token
  - refresh token
  - user metadata
  - hashed master password for offline verification
- Storage is backed by `flutter_secure_storage`
- On Android it uses encrypted shared preferences
- On iOS it uses Keychain accessibility tied to device passcode

### Presenter line

"This means the device becomes part of the trust model. Secure storage is not an extra feature here. It is central to how the app works."

## Slide 4: Local Storage Architecture

### Slide title
`Offline-First By Design: SQLite + Secure Storage`

### What to say

"One of the strongest local-resource features in KeySafe is the two-layer local storage design. The app uses SQLite as the fast local vault cache, and it also keeps a secure snapshot in protected storage. This gives us speed, offline access, and recovery resilience."

### What to show in the app

- Open the vault home screen
- Scroll immediately through saved passwords
- Mention that this list can render from local cache before any cloud sync finishes

### Technical points to mention

- SQLite database file: `keysafe_vault.db`
- Secure fallback snapshot stored in secure storage as `vault_snapshot`
- Deleted items are stored in a local trash table for 30 days
- There is also a local `pending_ops` queue for offline-style sync behavior

### Presenter line

"The practical effect is simple: the vault opens fast because it reads local data first. The network becomes a background update, not a blocker for basic usage."

## Slide 5: Demoing The Main Use Case

### Slide title
`Main User Journey: Open Vault And Access Credentials`

### What to say

"This is the core use case. A user opens the app, reaches the vault, searches locally, filters by category, and opens a stored credential. This is where the local-first design becomes visible to the user."

### What to show in the app

- On the home screen, use search
- Filter by category
- Open a password detail page

### Technical points to mention

- Search and filtering operate on locally cached entries
- Category filtering and list rendering rely on the local vault state
- Sensitive values are stored encrypted, not in plain text

### Presenter line

"The interface feels immediate because the app is not waiting on the server just to let me browse my own vault."

## Slide 6: Biometrics, Auto-Lock, And Device Security

### Slide title
`Using Device Security: Biometrics And Auto-Lock`

### What to say

"KeySafe uses the device's own authentication capabilities. If biometric unlock is enabled, the user can unlock with fingerprint or Face ID, and the app also supports device PIN or screen lock fallback through the OS prompt."

### What to show in the app

- Go to `Settings`
- Open `Biometric Unlock`
- If possible, show the lock screen and biometric prompt
- Mention auto-lock delay in settings

### Technical points to mention

- Uses `local_auth`
- Biometric enablement is stored locally
- Lock/unlock behavior is tied to app lifecycle events
- Auto-lock is scheduled when the app goes inactive or paused

### Presenter line

"This is a strong example of a mobile-local resource. Instead of reinventing authentication, the app integrates with trusted device security already provided by the operating system."

## Slide 7: Location Services For Login Awareness

### Slide title
`Location As A Security Signal`

### What to say

"Another local resource used by the app is location. On login, KeySafe can capture the device location, reverse-geocode it into a readable city and country, save it in local login history, and warn the user when a sign-in happens from a new place."

### What to show in the app

- After login, open the `Security` screen
- Open `Login History`
- Point out trusted and new locations if available

### Technical points to mention

- Uses `geolocator` and `geocoding`
- Login history is saved locally in `keysafe_login_history.db`
- New location events can trigger local notifications
- Trusted locations are managed locally

### Presenter line

"This is a good example of using a phone capability for context-aware security. The app does not just store passwords. It also watches for unusual sign-in context using local device data."

## Slide 8: Clipboard Protection And Local Notifications

### Slide title
`Protecting Sensitive Data After Copy`

### What to say

"Copying a password is useful, but it creates a risk because other apps may read the clipboard. KeySafe reduces that risk by scheduling a local clipboard clear and optionally notifying the user."

### What to show in the app

- Open a password detail page
- Copy a password
- Mention the timer-based clear behavior
- If available, show the notification behavior

### Technical points to mention

- Clipboard handling uses `ClipboardService`
- Passwords can be cleared after a configurable delay
- Notifications are initialized locally at app startup
- Security, sync, clipboard, and login alerts are all local notification flows

### Presenter line

"This is a small feature, but it shows mature mobile thinking. Security is not only about encryption at rest. It is also about what happens after the user interacts with the secret."

## Slide 9: Camera And QR-Based Sharing

### Slide title
`Camera Access And QR Exchange`

### What to say

"KeySafe also uses the camera as a local device resource. A user can generate a QR code for a credential and another user can scan it inside the app. The QR payload carries encrypted password data, not plain text."

### What to show in the app

- Open a stored vault entry
- Choose QR sharing
- Point out the expiry timer
- Then show the scan screen if you want to explain the receiving flow

### Technical points to mention

- QR generation uses `qr_flutter`
- QR scanning uses `mobile_scanner`
- Shared QR data includes encrypted password content
- QR images can be captured locally and shared as PNG files

### Presenter line

"This combines multiple local resources at once: rendering, camera access, temporary file creation, and on-device handling of encrypted credential data."

## Slide 10: Temporary Files, Export, And Local File Handling

### Slide title
`Working With Local Files`

### What to say

"The app also uses local file system access for practical features like export and QR sharing. For example, an export is built as a password-protected ZIP file in temporary storage before being sent out."

### What to show in the app

- Go to `Settings`
- Point to `Export Vault`
- Explain that the export is built locally before email sharing

### Technical points to mention

- Uses `path_provider` to access temporary directories
- Export creates a CSV, packages it into a password-protected ZIP, and stores it temporarily
- QR share also captures the widget as a local PNG file before sharing

### Presenter line

"This is another example of how KeySafe behaves like a real mobile app, not just a thin frontend. Important work happens on the device using local file APIs."

## Slide 11: Ambient Dark Mode And Sensor-Oriented UI

### Slide title
`Sensor-Oriented Design: Ambient Dark Mode`

### What to say

"The settings section includes an ambient dark mode feature with manual, scheduled, and sensor-based strategies. This is useful in the presentation because it shows that the app architecture is designed to respond to device conditions, not just button taps."

### What to show in the app

- Go to `Settings`
- Open `Dark Mode`
- Show the three modes: manual, scheduled, ambient sensor

### Important accuracy note

Be careful how you describe this slide:

- The UI and provider architecture for ambient sensor mode are present
- The config is persisted locally in secure storage
- The current implementation uses an empty lux stream and falls back to system theme when no live sensor stream is available

### Safe presenter line

"This screen demonstrates the sensor-aware direction of the app. Manual and scheduled theme changes are implemented, and the sensor-based mode is architected in the app with a graceful fallback to system theme where live lux readings are not currently available."

### Why this wording matters

It lets you highlight sensors and adaptive UI without claiming that a fully wired ambient light sensor pipeline is already active in the current build.

## Slide 12: Security Dashboard And Local Analysis

### Slide title
`Local Analysis For Better Security Decisions`

### What to say

"The security screen brings together several local and remote ideas, but from the user's perspective it feels like one security dashboard. It calculates a security score, shows weak and reused passwords, and connects that to login history and breach awareness."

### What to show in the app

- Open the `Security` tab
- Point to the score ring
- Point to weak, reused, secure, and compromised groupings

### Technical points to mention

- The UI works from locally available vault entries
- Decryption and strength-related logic are part of app-side processing
- Login history is backed by local SQLite storage

### Presenter line

"This shows how local data is not only stored, but also turned into meaningful security feedback for the user."

## Slide 13: Wrap-Up

### Slide title
`Why Local Resources Matter In KeySafe`

### What to say

"The strongest takeaway is that local resources are not optional add-ons in KeySafe. They are part of the core product design. Splash assets improve launch experience. Secure storage protects secrets. SQLite enables offline-first access. Biometrics improve secure usability. Location and notifications support login awareness. Camera and files enable QR workflows and export. Altogether, these device capabilities make the app practical, secure, and presentation-worthy as a mobile system."

## Short 3-Minute Version

If you need a faster version, use this sequence:

1. Splash screen and app branding
2. Login and explain secure local key setup
3. Home screen and offline-first local vault
4. Settings for biometrics and auto-lock
5. Security screen for login history and notifications
6. QR share and scan as camera-based local functionality
7. Dark mode screen to mention sensor-oriented architecture
8. Close with "local resources are core to the product"

## Live Demo Order

Use this order during the actual presentation to keep the flow smooth:

1. Cold launch the app and pause on splash
2. Sign in and explain local AES key derivation
3. Open the home vault and search an entry
4. Open settings and show biometrics, auto-lock, clipboard, notifications
5. Open dark mode and mention manual, scheduled, and sensor modes
6. Open security and show login history
7. Open a password entry and show copy behavior
8. Show QR share
9. Mention export from settings as the final "local files" example

## Backup Lines If The Demo Is Slow

Use these lines if you need to talk while the app is loading or navigating:

- "This screen is backed by local state, so the user is not blocked by the network for routine vault access."
- "KeySafe uses the phone's secure storage and not just plain local preferences for secret material."
- "The login history feature is useful because it turns location data into a real security signal."
- "The QR flow is a good demonstration that local device hardware, storage, and security can work together in one feature."
- "The dark-mode screen also shows that the app is designed to respond to environment and context, not only direct user input."

## Final Presentation Angle

If your lecturer or audience asks, "What local resources does this app actually use?", your concise answer can be:

"KeySafe uses native splash assets, secure storage, SQLite databases, biometrics, local notifications, clipboard access, location services, camera-based QR scanning, temporary local file generation for sharing and export, and a sensor-oriented dark-mode configuration flow."
