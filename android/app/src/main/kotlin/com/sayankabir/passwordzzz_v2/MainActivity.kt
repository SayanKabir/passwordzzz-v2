package com.sayankabir.passwordzzz_v2

import android.os.Bundle
import android.view.WindowManager
import androidx.biometric.BiometricManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * FlutterFragmentActivity (not FlutterActivity) is required for BiometricPrompt.
 */
class MainActivity : FlutterFragmentActivity() {

    private lateinit var vaultKeystore: VaultKeystore

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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        vaultKeystore = VaultKeystore(this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasVaultKey" -> result.success(vaultKeystore.hasVaultKey())

                "canAuthenticate" -> result.success(
                    when (vaultKeystore.canAuthenticate()) {
                        BiometricManager.BIOMETRIC_SUCCESS -> "available"
                        BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> "not_enrolled"
                        BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE,
                        BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE ->
                            "no_hardware"
                        else -> "unavailable"
                    }
                )

                "createVaultKey" -> vaultKeystore.createVaultKey(
                    title = call.argument<String>("title") ?: "Create your vault",
                    subtitle = call.argument<String>("subtitle") ?: "",
                ) { r ->
                    when (r) {
                        is VaultKeystore.Result.Created ->
                            result.success(
                                mapOf("vaultKey" to r.vaultKey, "strongBox" to r.strongBox)
                            )
                        is VaultKeystore.Result.Error ->
                            result.error(r.code, r.message, null)
                        else -> result.error("unexpected", "Unexpected result.", null)
                    }
                }

                "unlockVaultKey" -> {
                    // The prompt is async and the callback fires exactly once,
                    // so the MethodChannel result is completed there.
                    vaultKeystore.unlockVaultKey(
                        title = call.argument<String>("title") ?: "Unlock vault",
                        subtitle = call.argument<String>("subtitle") ?: "",
                    ) { r ->
                        when (r) {
                            is VaultKeystore.Result.Unlocked -> result.success(r.vaultKey)
                            is VaultKeystore.Result.Error ->
                                result.error(r.code, r.message, null)
                            else -> result.error("unexpected", "Unexpected result.", null)
                        }
                    }
                }

                "deleteVaultKey" -> {
                    vaultKeystore.deleteVaultKey()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    /**
     * Secure by default, including in debug builds.
     *
     * FLAG_SECURE also blocks `adb screencap`, which makes visual verification
     * during development impossible. It can be lifted for a single launch:
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
        const val CHANNEL = "passwordzzz/keystore"
    }
}
