package com.sayankabir.passwordzzz_v2

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import android.security.keystore.StrongBoxUnavailableException
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.fragment.app.FragmentActivity
import java.io.File
import java.security.KeyStore
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import androidx.core.content.ContextCompat

/**
 * Wraps the vault key under a hardware-backed Android Keystore key.
 *
 * Threat model: an attacker with the device's storage (a backup, a pulled
 * image, root) gets only the wrapped blob. The key encryption key (KEK) never
 * leaves the TEE/StrongBox and is bound to user authentication, so unwrapping
 * requires a live biometric or device-credential prompt on that specific
 * device.
 *
 * The prompt is bound to the Cipher via [BiometricPrompt.CryptoObject]. That
 * binding is the point: without it, the KEK would merely be *available* for a
 * window after any authentication, and any code running in the process could
 * use it. With it, this exact Cipher instance is unusable unless this exact
 * prompt succeeded.
 */
class VaultKeystore(private val activity: FragmentActivity) {

    companion object {
        private const val KEY_ALIAS = "pz_vault_kek"
        private const val KEYSTORE = "AndroidKeyStore"
        private const val TRANSFORM = "AES/GCM/NoPadding"
        private const val GCM_TAG_BITS = 128
        private const val BLOB_FILE = "vault.kek"
        private const val VAULT_KEY_BYTES = 32
    }

    private val blobFile: File get() = File(activity.filesDir, BLOB_FILE)

    fun hasVaultKey(): Boolean = blobFile.exists() && keyStoreEntry() != null

    /** Whether any credential exists that could authorise an unwrap. */
    fun canAuthenticate(): Int =
        BiometricManager.from(activity).canAuthenticate(allowedAuthenticators())

    /**
     * Generates a fresh 256-bit vault key, wraps it under a new Keystore KEK,
     * and persists the wrapped blob.
     *
     * Requires authentication, exactly as unwrapping does. The KEK is created
     * with per-use authentication (`setUserAuthenticationParameters(0, …)`),
     * which applies to *every* operation including encryption — an earlier
     * version assumed encrypt-mode was exempt and died with
     * KEY_USER_NOT_AUTHENTICATED on the first run. Prompting here is also the
     * safer flow: it proves the user can authenticate before we commit a key
     * that would otherwise lock them out of their own vault.
     *
     * Returns the raw vault key so Dart can encrypt records with it. This is
     * the only moment it exists outside the wrap; it lives in Dart memory only
     * while the vault is unlocked.
     */
    fun createVaultKey(
        title: String,
        subtitle: String,
        onResult: (Result) -> Unit,
    ) {
        val strongBox: Boolean
        val cipher: Cipher
        try {
            strongBox = generateKek()
            cipher = Cipher.getInstance(TRANSFORM).apply {
                init(Cipher.ENCRYPT_MODE, requireKek())
            }
        } catch (e: Exception) {
            onResult(Result.Error("create_failed", e.message ?: e.toString()))
            return
        }

        val vaultKey = ByteArray(VAULT_KEY_BYTES).also {
            SecureRandom().nextBytes(it)
        }

        prompt(title, subtitle, cipher) { authed ->
            when (authed) {
                is CipherResult.Ok -> try {
                    val wrapped = authed.cipher.doFinal(vaultKey)
                    writeBlob(authed.cipher.iv, wrapped)
                    onResult(Result.Created(vaultKey, strongBox))
                } catch (e: Exception) {
                    // Leave no half-created key behind: a KEK with no matching
                    // blob would make hasVaultKey() lie on the next launch.
                    deleteVaultKey()
                    onResult(Result.Error("wrap_failed", e.message ?: e.toString()))
                }
                is CipherResult.Failed -> {
                    deleteVaultKey()
                    onResult(Result.Error(authed.code, authed.message))
                }
            }
        }
    }

    /**
     * Shows the authentication prompt and, on success, unwraps the vault key.
     *
     * [onResult] is always called exactly once.
     */
    fun unlockVaultKey(
        title: String,
        subtitle: String,
        onResult: (Result) -> Unit,
    ) {
        val blob = readBlob()
        if (blob == null) {
            onResult(Result.Error("no_vault", "No wrapped vault key on device."))
            return
        }

        val cipher = try {
            Cipher.getInstance(TRANSFORM).apply {
                init(
                    Cipher.DECRYPT_MODE,
                    requireKek(),
                    GCMParameterSpec(GCM_TAG_BITS, blob.iv),
                )
            }
        } catch (e: KeyPermanentlyInvalidatedException) {
            // Fires when biometric enrolment changed. The wrapped key can never
            // be recovered on this device; the recovery code is the only way
            // back, so say so plainly rather than reporting a generic failure.
            onResult(
                Result.Error(
                    "key_invalidated",
                    "Device biometrics changed, so the stored key is no longer " +
                        "usable. Restore with your recovery code.",
                )
            )
            return
        } catch (e: Exception) {
            onResult(Result.Error("cipher_failed", e.message ?: e.toString()))
            return
        }

        prompt(title, subtitle, cipher) { authed ->
            when (authed) {
                is CipherResult.Ok -> try {
                    onResult(Result.Unlocked(authed.cipher.doFinal(blob.ciphertext)))
                } catch (e: Exception) {
                    onResult(Result.Error("unwrap_failed", e.message ?: e.toString()))
                }
                is CipherResult.Failed ->
                    onResult(Result.Error(authed.code, authed.message))
            }
        }
    }

    private sealed class CipherResult {
        class Ok(val cipher: Cipher) : CipherResult()
        class Failed(val code: String, val message: String) : CipherResult()
    }

    /**
     * Shows the prompt with [cipher] bound to it, and hands back the same
     * Cipher once Keystore has authorised it. [onResult] fires exactly once.
     */
    private fun prompt(
        title: String,
        subtitle: String,
        cipher: Cipher,
        onResult: (CipherResult) -> Unit,
    ) {
        val prompt = BiometricPrompt(
            activity,
            ContextCompat.getMainExecutor(activity),
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(
                    result: BiometricPrompt.AuthenticationResult
                ) {
                    val c = result.cryptoObject?.cipher
                    if (c == null) {
                        onResult(
                            CipherResult.Failed(
                                "no_crypto_object",
                                "Authentication was not bound to the cipher.",
                            )
                        )
                        return
                    }
                    onResult(CipherResult.Ok(c))
                }

                override fun onAuthenticationError(code: Int, msg: CharSequence) {
                    val kind = when (code) {
                        BiometricPrompt.ERROR_USER_CANCELED,
                        BiometricPrompt.ERROR_NEGATIVE_BUTTON,
                        BiometricPrompt.ERROR_CANCELED -> "cancelled"
                        BiometricPrompt.ERROR_LOCKOUT -> "locked_out"
                        BiometricPrompt.ERROR_LOCKOUT_PERMANENT -> "locked_out_permanent"
                        BiometricPrompt.ERROR_NO_DEVICE_CREDENTIAL,
                        BiometricPrompt.ERROR_NO_BIOMETRICS -> "not_set_up"
                        else -> "auth_failed"
                    }
                    onResult(CipherResult.Failed(kind, msg.toString()))
                }
                // onAuthenticationFailed (a rejected finger) is deliberately not
                // terminal — the prompt stays up for another attempt.
            },
        )

        val info = BiometricPrompt.PromptInfo.Builder()
            .setTitle(title)
            .setSubtitle(subtitle)
            .setAllowedAuthenticators(allowedAuthenticators())
            .apply {
                // A negative button is required when device credential is not
                // among the allowed authenticators, and forbidden when it is.
                if (!deviceCredentialAllowed()) setNegativeButtonText("Cancel")
            }
            .setConfirmationRequired(false)
            .build()

        prompt.authenticate(info, BiometricPrompt.CryptoObject(cipher))
    }

    fun deleteVaultKey() {
        runCatching { keyStore().deleteEntry(KEY_ALIAS) }
        runCatching { blobFile.delete() }
    }

    // --- internals -------------------------------------------------------

    /**
     * Device credential can only accompany a CryptoObject from API 30. Below
     * that the combination throws, so those devices get biometric-only.
     */
    private fun deviceCredentialAllowed() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R

    private fun allowedAuthenticators(): Int =
        if (deviceCredentialAllowed()) {
            BiometricManager.Authenticators.BIOMETRIC_STRONG or
                BiometricManager.Authenticators.DEVICE_CREDENTIAL
        } else {
            BiometricManager.Authenticators.BIOMETRIC_STRONG
        }

    /** Returns true when the key landed in StrongBox. */
    private fun generateKek(): Boolean {
        runCatching { keyStore().deleteEntry(KEY_ALIAS) }
        return try {
            buildKek(strongBox = true)
            true
        } catch (e: StrongBoxUnavailableException) {
            // Most devices have no StrongBox chip; TEE-backed is the norm and
            // still keeps the KEK out of app-readable memory.
            buildKek(strongBox = false)
            false
        }
    }

    private fun buildKek(strongBox: Boolean) {
        val spec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .setUserAuthenticationRequired(true)
            .apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    // 0 = authentication required for *every* use, which is
                    // only enforceable with a CryptoObject-bound prompt.
                    setUserAuthenticationParameters(
                        0,
                        KeyProperties.AUTH_BIOMETRIC_STRONG or
                            KeyProperties.AUTH_DEVICE_CREDENTIAL,
                    )
                } else {
                    @Suppress("DEPRECATION")
                    setUserAuthenticationValidityDurationSeconds(-1)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    // Enrolling a new fingerprint invalidates the key. That is
                    // deliberate: it stops someone who can add a finger to an
                    // unlocked device from reading the vault.
                    setInvalidatedByBiometricEnrollment(true)
                }
                if (strongBox && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    setIsStrongBoxBacked(true)
                }
            }
            .build()

        KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE)
            .apply { init(spec) }
            .generateKey()
    }

    private fun keyStore(): KeyStore =
        KeyStore.getInstance(KEYSTORE).apply { load(null) }

    private fun keyStoreEntry(): SecretKey? =
        runCatching { keyStore().getKey(KEY_ALIAS, null) as? SecretKey }.getOrNull()

    private fun requireKek(): SecretKey =
        keyStoreEntry() ?: throw IllegalStateException("Vault KEK missing.")

    private class Blob(val iv: ByteArray, val ciphertext: ByteArray)

    private fun writeBlob(iv: ByteArray, ciphertext: ByteArray) {
        // [1-byte iv length][iv][ciphertext]
        blobFile.outputStream().use {
            it.write(iv.size)
            it.write(iv)
            it.write(ciphertext)
        }
    }

    private fun readBlob(): Blob? {
        if (!blobFile.exists()) return null
        return runCatching {
            val all = blobFile.readBytes()
            val ivLen = all[0].toInt()
            Blob(
                all.copyOfRange(1, 1 + ivLen),
                all.copyOfRange(1 + ivLen, all.size),
            )
        }.getOrNull()
    }

    sealed class Result {
        class Created(val vaultKey: ByteArray, val strongBox: Boolean) : Result()
        class Unlocked(val vaultKey: ByteArray) : Result()
        class Error(val code: String, val message: String) : Result()
    }
}
