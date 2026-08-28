package com.sayankabir.passwordzzz_v2

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * FlutterFragmentActivity (not FlutterActivity) is required for local_auth's
 * BiometricPrompt.
 */
class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        if (shouldSecureWindow()) {
            // Blocks screenshots, screen recording, and the contents of the
            // recents-switcher thumbnail. v1 allowed all three while a
            // decrypted password was on screen.
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE,
            )
        }
        super.onCreate(savedInstanceState)
    }

    /**
     * Secure by default, including in debug builds.
     *
     * FLAG_SECURE also blocks `adb screencap`, which makes visual verification
     * during development impossible. Rather than weaken every debug build, the
     * flag can be lifted for a single launch:
     *
     *     adb shell am start -n com.sayankabir.passwordzzz_v2/.MainActivity \
     *         --ez allow_screenshots true
     *
     * The opt-out is compiled out of release builds, so no launch intent can
     * disable FLAG_SECURE in a shipped APK.
     */
    private fun shouldSecureWindow(): Boolean {
        if (!BuildConfig.DEBUG) return true
        return !intent.getBooleanExtra(EXTRA_ALLOW_SCREENSHOTS, false)
    }

    private companion object {
        const val EXTRA_ALLOW_SCREENSHOTS = "allow_screenshots"
    }
}
