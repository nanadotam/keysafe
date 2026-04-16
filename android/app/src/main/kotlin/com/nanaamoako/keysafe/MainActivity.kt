package com.nanaamoako.keysafe

import android.os.Bundle
import android.view.WindowManager
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity

// IMPORTANT: local_auth uses BiometricPrompt which requires a FragmentActivity.
// Using FlutterActivity (which extends Activity, not FragmentActivity) causes
// "biometric confirmation was cancelled" (ERROR_CANCELED / code 5) on Samsung
// and other OEMs running Android 9+.
// Solution: extend FlutterFragmentActivity instead — this is the official
// recommendation from the local_auth package documentation.
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Prevent screenshots and screen recording (security requirement)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        // Edge-to-edge display
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
