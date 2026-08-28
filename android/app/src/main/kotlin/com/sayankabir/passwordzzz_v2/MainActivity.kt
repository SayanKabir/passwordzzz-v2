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
        // Blocks screenshots, screen recording, and the contents of the
        // recents-switcher thumbnail. v1 allowed all three while a decrypted
        // password was on screen.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
        super.onCreate(savedInstanceState)
    }
}
