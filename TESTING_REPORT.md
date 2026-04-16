# KeySafe — UI Testing Report

**Date:** April 13, 2026  
**Device:** Android Emulator (`emulator-5554`, Android SDK built for arm64)  
**Build:** Debug (`flutter run -d emulator-5554`)  
**Tester:** Claude Code (agent-device automation)

---

## Summary

| Category | Count |
|---|---|
| Pages tested | 15 |
| Issues found | 10 |
| Back-button bugs | 5 |
| Unreachable screens | 2 |
| Stub/unimplemented features | 1 |
| Data inconsistencies | 2 |

---

## Pages Tested

| Screen | AppBar Back | System Back | Notes |
|---|---|---|---|
| Onboarding (slides 1–3) | N/A (no AppBar) | Exits app ⚠️ | In-slide Back button works correctly |
| Register | ✅ (goes back) | ❌ Exits app | Issue #1 |
| Login | ✅ (goes back) | ❌ Exits app | Issue #2 |
| Lock Screen | N/A | N/A | Issue #3 — no inline password |
| Home | N/A | ❌ Exits app | Issue #4 |
| Add Password | ✅ | ✅ | Works correctly |
| Password Detail | ✅ | ✅ | Works correctly |
| Edit Password | ✅ | ✅ | Works correctly |
| Password Generator | ✅ | ✅ | Works correctly |
| Security (tab) | N/A | ❌ Exits app | Issue #5 |
| Settings (tab) | N/A | ❌ Exits app | Issue #5 |
| Profile | ✅ | ✅ | Data issue — see Issue #9 |
| QR Share | ✅ | ✅ | 60s expiry timer works correctly |
| QR Scan | N/A | N/A | Issue #7 — unreachable |
| Wi-Fi Passwords | N/A | N/A | Issue #8 — unreachable |

---

## Issues

### Issue #1 — Register screen: system back exits app

**Severity:** Medium  
**Screen:** Register (`/register`)

Pressing the Android system back button from the Register screen exits the app entirely (returns to the device launcher) instead of going back to the Onboarding screen.

**Root cause:** `OnboardingScreen` uses `context.go(Routes.register)` which replaces the navigation stack. There is no back history to pop.

**Fix:** Change navigation to `context.push(Routes.register)` in `onboarding_screen.dart:51`.

```dart
// onboarding_screen.dart — _next()
// Before:
context.go(Routes.register);
// After:
context.push(Routes.register);
```

---

### Issue #2 — Login screen: system back exits app

**Severity:** Medium  
**Screen:** Login (`/login`)

Same root cause as Issue #1. Navigating from Onboarding to Login uses `context.go(Routes.login)` (line 102 of `onboarding_screen.dart`), clearing the back stack.

**Fix:** Change to `context.push(Routes.login)` in `onboarding_screen.dart:102`. Also update the cross-links between Register and Login screens so back-navigation is consistent:

- `register_screen.dart:144` — "Already have an account? Sign in" uses `context.go(Routes.login)` → change to `context.push`
- `login_screen.dart:188` — "Don't have an account? Register" uses `context.go(Routes.register)` → change to `context.push`

---

### Issue #3 — Lock Screen: "Use Master Password" navigates away instead of unlocking inline

**Severity:** Medium  
**Screen:** Lock Screen (`/lock`)

Tapping "Use Master Password" on the Lock Screen uses `context.go(Routes.login)` (`lock_screen.dart:105`), which navigates to the full Sign In screen. This is confusing for two reasons:

1. The Lock Screen messaging says *"Your vault is locked"*, implying a local unlock — but the user ends up on a screen titled "Sign In" which makes a network call.
2. The user's session is still valid; they only need to re-enter their master password locally, not re-authenticate with the server.

**Fix (recommended):** Add an inline `TextFormField` for master password on the Lock Screen. Call a local `unlockWithMasterPassword()` action on the auth notifier that re-derives the AES key from the stored credentials + entered password, without making a new network call.

**Fix (minimal):** Change the button label to "Sign In" and the Lock Screen body copy to "Sign in again to access your vault" to align language with the actual behavior.

---

### Issue #4 — Home tab: system back exits app

**Severity:** Low–Medium  
**Screen:** Home (`/home`)

Pressing system back from the Home tab (the root tab) exits the app with no confirmation. On Android, it is conventional to either:
- Show a "Press back again to exit" snackbar/toast, or
- Do nothing (intercept the back gesture) while on the root destination.

**Fix:** Add a `PopScope` widget wrapping the `HomeScreen` (or the shell) that intercepts the first back press and shows a confirmation or toast.

---

### Issue #5 — Security and Settings tabs: system back exits app

**Severity:** Low–Medium  
**Screens:** Security (`/security`), Settings (`/settings`)

Same as Issue #4. Pressing system back from any bottom-nav tab exits the app instead of navigating to the Home tab or staying in the app.

**Fix:** Add `PopScope` (or `WillPopScope`) at the `_MainShell` level (`app.dart:193`) to intercept the back gesture when a non-home tab is selected and switch to the home tab rather than exiting.

```dart
// _MainShellState.build() — wrap Scaffold with PopScope
PopScope(
  canPop: selectedIndex == 0, // allow exit only from Home
  onPopInvokedWithResult: (didPop, _) {
    if (!didPop && selectedIndex != 0) {
      context.go(Routes.home);
    }
  },
  child: Scaffold(...),
)
```

---

### Issue #6 — "Change Master Password" is a stub

**Severity:** High  
**Screen:** Settings → Account

The "Change Master Password" list tile has `onTap: () {}` — it does nothing when tapped (`settings_screen.dart:140`). There is no visual feedback (no snackbar, no dialog, no navigation).

**Fix:** Implement the change-password flow, or at minimum add a "Coming soon" snackbar so the user isn't confused by a tap with no response.

---

### Issue #7 — QR Scan screen is unreachable

**Severity:** Medium  
**Screen:** QR Scan (`/qr-scan`)

The `QrScanScreen` is registered in the router (`app.dart:87`) but there is no button, menu item, or entry point anywhere in the app UI that navigates to it. `Routes.qrScan` appears only in `app.dart` — no `context.push(Routes.qrScan)` call exists in any screen.

**Fix:** Add a "Scan QR Code" entry point — the most natural location is the Home screen AppBar (alongside the profile icon) or as an option in the Add Password screen.

---

### Issue #8 — Wi-Fi Passwords screen is unreachable

**Severity:** Medium  
**Screen:** Wi-Fi (`/wifi`)

Same as Issue #7. `WifiScreen` is a fully built screen with an add-wifi bottom sheet, but `Routes.wifi` is never navigated to from any screen in the app.

The Home screen does include a **"wifi"** category filter chip, which suggests Wi-Fi entries should appear in the vault list — but there is no way to create or view Wi-Fi passwords via the UI.

**Fix:** Add a "Wi-Fi Passwords" navigation item. Options:
- Add a dedicated tab or FAB option on the Home screen
- Add a "Wi-Fi Passwords" tile to the Profile screen quick-links
- Add a floating menu button on Home that offers "Add Password" and "Add Wi-Fi"

---

### Issue #9 — Profile screen stats don't match actual data

**Severity:** Low–Medium  
**Screen:** Profile

After creating 1 vault entry (Gmail), the Profile screen shows:
- **Vault Entries:** 0 ❌ (should be 1)
- **Security Score:** 0 ❌ (Home screen shows 100)

The Profile screen fetches stats from the server API (`GET /user/profile`). The server is either:
- Not updating counts immediately on entry creation, or
- Returning a stale/default response

Additionally, the **Security Score** is computed two different ways:
- **Home screen:** Calculated locally — `entries.isEmpty ? 100 : (100 - weakCount * 5).clamp(0, 100)` 
- **Profile screen:** Pulled from the server API field `security_score`

This means the same metric shows different values in two places in the same session.

**Fix:**
1. Investigate the `/user/profile` API — ensure it returns live counts.
2. Use the same local computation for the security score on the Profile screen, or document that the API value is "historical" and the home value is "live".

---

### Issue #10 — Security screen rows show chevron arrows but aren't tappable

**Severity:** Low  
**Screen:** Security

The four stat rows ("Compromised", "Weak Passwords", "Reused", "Secure") each show a `chevron_right` icon in their trailing widget (`security_screen.dart:165–193`), which strongly implies they are tappable and will drill into a filtered list. However, none of them have an `onTap` handler.

**Fix:** Either:
- Add `onTap` to each row that navigates to a filtered list of the relevant entries, or
- Remove the `chevron_right` icon from the `_SecurityRow` trailing widget.

---

## Flow Tested (Happy Path)

```
Onboarding (slide 1 → 2 → 3) 
  → Register (create account) 
  → Home (empty vault)
    → Add Password (Gmail entry) 
    → Home (1 entry shown)
      → Password Detail 
        → Edit Password (back to detail) ✅
        → QR Share (back to detail) ✅
      → Profile (back to home) ✅
    → Security tab ✅
    → Settings tab 
      → Auto-lock dialog ✅
      → Change Master Password (no-op ⚠️)
```

---

## Additional Observations

- **Auto-lock (60s default):** The app locks aggressively. During testing, the vault locked every time the emulator went background (e.g., system dialogs). This is correct security behaviour but means the 60-second default may feel too aggressive for users — consider making the first-launch default longer (e.g., 5 minutes) or prompting the user to choose on first login.

- **QR Share 60-second expiry:** Works correctly — the timer counts down and the screen auto-dismisses at 0. Good UX.

- **Password Generator:** Returns to the calling screen correctly via `context.push` + `then((v) {...})`. The "Use This Password" button correctly fills the password field.

- **Delete confirmation dialog:** Works correctly — shows "Delete 'Gmail'? This cannot be undone." with Cancel/Delete buttons.

- **Onboarding in-slide Back button:** Correctly hidden on slide 1, visible on slides 2–3, and navigates backwards through slides.

- **Register screen `AppBar` back:** The `RegisterScreen` has an `AppBar` (`register_screen.dart:69`) which provides an AppBar back button. This works and takes the user back — but only when navigated to via `context.push`. See Issue #1.

---

## Files to Change (Summary)

| File | Change |
|---|---|
| `lib/features/auth/presentation/onboarding_screen.dart` | `context.go` → `context.push` for register and login |
| `lib/features/auth/presentation/register_screen.dart` | `context.go(Routes.login)` → `context.push` |
| `lib/features/auth/presentation/login_screen.dart` | `context.go(Routes.register)` → `context.push` |
| `lib/features/auth/presentation/lock_screen.dart` | Add inline password field OR update copy |
| `lib/app.dart` | Add `PopScope` to `_MainShell` to prevent back-exit from tabs |
| `lib/features/settings/presentation/settings_screen.dart` | Implement Change Master Password |
| `lib/features/vault/presentation/home_screen.dart` | Add entry point for QR Scan and Wi-Fi |
| `lib/features/security/presentation/security_screen.dart` | Remove chevron icons or add onTap to rows |
| `lib/features/profile/presentation/profile_screen.dart` | Align security score computation with Home |
