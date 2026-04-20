# KeySafe — Device Testing Report
**Date:** April 20, 2026  
**Device:** Android Emulator (emulator-5554)  
**Account tested:** sorotechnologies@protonmail.com  

---

## ✅ Working Features

| Feature | Screen | Notes |
|---|---|---|
| Home screen loads | Home | Shows 5 passwords, 100 security score stat cards |
| Password list | Home | All 5 entries visible (Netflix, Twitter, Amazon, GitHub, Gmail) |
| Search / filter | Home | Real-time filtering by search text ✅ |
| Category filter chips | Home | All, Social, Finance, Email, Shopping buttons work |
| FAB → Add Password | Home | Opens Add Password screen correctly |
| Password detail view | Detail | Username, masked password, website, notes, created/modified dates |
| Copy username button | Detail | Tap works (no visual confirmation in a11y tree but no crash) |
| Reveal password toggle | Detail | Toggle button present |
| Share via QR | Detail → QR | QR code renders with 60s countdown timer + extend button + share image button |
| Edit password | Detail → Edit | Opens via AppBar icon (at x≈900, y=137); all fields pre-filled |
| Delete password | Detail | Confirmation dialog shows with Cancel / Delete buttons |
| Back: detail → home | Navigation | Back button returns to home list ✅ |
| Back: edit → detail | Navigation | Back button returns to detail ✅ |
| Back: profile → home | Navigation | Back button returns to home ✅ |
| Back: QR → detail | Navigation | Back button returns to detail ✅ |
| Password Generator | Generator | Opens from Add screen; Random + Memorable modes both work |
| Generator — Random mode | Generator | Length slider, Uppercase/Numbers/Symbols/Avoid-ambiguous toggles all render |
| Generator — Memorable mode | Generator | Pronounceable groups with dashes; toggles adapt |
| Generator — Regenerate | Generator | New password generated on tap |
| Generator — Use This Password | Generator | Password populated into Add/Edit form field |
| Add category dialog | Add/Edit | "Add category" button opens dialog with text field |
| Lock screen | Lock | Shows after restart; biometric button + master password fallback |
| Lock screen — master password field | Lock | Shows/hides on toggle; obscure eye icon works |

---

## ❌ Bugs / Issues Found

### 1. Add Category — App Goes Blank (Critical)
**Screen:** Add Password / Edit Password  
**Steps to reproduce:**
1. Open Add Password
2. Fill in Service Name and Username
3. Tap "Add category"
4. Type a new category name in the dialog
5. Tap "Add"

**Result:** UI drops to 0 accessibility nodes — screen goes blank/black. App requires force-stop and manual restart.  
**Expected:** New category is saved and selected in the dropdown.  
**Severity:** High — makes custom categories completely unusable.

---

### 2. Edit Icon Hidden Behind Delete Icon (Minor / UX)
**Screen:** Password Detail AppBar  
**Issue:** The two unnamed AppBar action buttons (@e12, @e13) both resolve to the same coordinate (1017, 137) in the accessibility tree. The edit icon sits at approximately x=900, y=137 and can only be reached by tapping a raw coordinate — not via accessibility node.  
**Impact:** Low for real users (icons are visually distinct), but indicates the edit icon may not have a semantic label set (missing `tooltip` or `semanticLabel`).

---

### 3. Unlock Hangs When Emulator Has No Internet (Minor)
**Screen:** Lock Screen  
**Issue:** After the category crash restart, the emulator lost internet connectivity. Master password entry on the lock screen appeared to submit but the screen did not transition.  
**Note:** The hash comparison is local (SHA-256), so this may be a UI-state issue where `_isVerifying` got stuck, or the AES key was not stored for the new account. More investigation needed with working network.

---

## 🔲 Not Yet Tested

- Security tab (breach check, login history, password health)
- Settings tab (all sub-screens)
- Ambient Dark Mode screen (3 strategies)
- Notifications settings
- Biometric settings
- Recently Deleted screen
- Import Vault (CSV)
- WiFi entries
- Change Master Password flow
- Wipe Vault flow
- Profile stats (Vault entries count, categories count)
- Double-back-to-exit on Home screen

---

---

## Fixes Applied (Apr 20, 2026)

| Bug | Fix |
|---|---|
| URL suggestion locks on "S" → snapchat.com | Added `_urlAutoFilled` flag — suggestion now updates while user is still typing; stops updating once user manually edits the URL field |
| Add category crash (0 nodes / blank screen) | Wrapped `FlutterSecureStorage.write()` in try-catch in `CategoriesNotifier.addCategory()`; added `context.mounted` guard in `_showAddCategoryDialog` before calling `onChanged` |
| Restore from Recently Deleted doesn't refresh home list | Added public `reloadFromLocal()` to `VaultNotifier`; called after `restore()` both in the notifier and explicitly in `RecentlyDeletedScreen._restore()` |
| Double-back-to-exit toast not showing | Moved `PopScope(canPop:false)` with snackbar logic from `HomeScreen` to `_MainShell` in `app.dart` — the shell's navigator was intercepting before the child's `PopScope` could fire |
| Silent "no email client" error on Wipe Vault & Change Master Password | Replaced raw exception text in SnackBar with a friendly message: "No email app found. Please set up an email client and try again." |

## Notes
- App is in **manual dark mode** — screenshots appear all black. Accessibility tree used for all verification.
- Backend (Render.com) has ~30–60s cold start. Network-dependent features need emulator with internet.
- `head` in PATH is XAMPP's HTTP client (not Unix `head`) — avoid piping to `head -N` in this shell.
