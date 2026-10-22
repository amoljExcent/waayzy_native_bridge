package com.excentsolutions.waayzy_native_bridge.features

import android.app.Activity
import android.content.Intent
import android.content.IntentSender
import com.excentsolutions.waayzy_native_bridge.BridgeChannels
import com.excentsolutions.waayzy_native_bridge.BridgeErrors
import com.excentsolutions.waayzy_native_bridge.NativeFeature
import com.excentsolutions.waayzy_native_bridge.fail
import com.google.android.gms.auth.api.identity.GetPhoneNumberHintIntentRequest
import com.google.android.gms.auth.api.identity.Identity
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.api.CommonStatusCodes
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Google's Phone Number Hint: lets the user pick one of the device's phone
 * numbers from a system sheet, without the app needing any SMS/phone permission.
 *
 * `getPhoneNumber` -> the number as the device reports it (usually `+91…`), or
 * `null` when the user dismisses the sheet, or a `NO_RESULT` error when the
 * device has no number to offer.
 */
class PhoneHintFeature : NativeFeature, PluginRegistry.ActivityResultListener {
    override val channelName = BridgeChannels.name("phone_hint")

    private var binding: ActivityPluginBinding? = null

    // Kept across an Activity re-creation (rotation): the sheet's result is
    // still delivered to the new Activity, and this is who is waiting for it.
    private var pending: MethodChannel.Result? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPhoneNumber" -> requestHint(result)
            else -> result.notImplemented()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.binding?.removeActivityResultListener(this)
        this.binding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        binding?.removeActivityResultListener(this)
        binding = null
    }

    private fun requestHint(result: MethodChannel.Result) {
        val activity = binding?.activity
            ?: return result.fail(BridgeErrors.NO_ACTIVITY, "No foreground activity")
        if (pending != null) {
            return result.fail(BridgeErrors.ALREADY_RUNNING, "Phone hint already showing")
        }
        pending = result

        val request = GetPhoneNumberHintIntentRequest.builder().build()
        Identity.getSignInClient(activity)
            .getPhoneNumberHintIntent(request)
            .addOnSuccessListener { pendingIntent ->
                try {
                    activity.startIntentSenderForResult(
                        pendingIntent.intentSender, REQUEST_CODE, null, 0, 0, 0,
                    )
                } catch (e: IntentSender.SendIntentException) {
                    complete { fail(BridgeErrors.UNAVAILABLE, e.message) }
                }
            }
            .addOnFailureListener { e -> completeWithFailure(e) }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false

        val activity = binding?.activity
        if (resultCode != Activity.RESULT_OK || data == null || activity == null) {
            complete { success(null) }
            return true
        }
        try {
            val number = Identity.getSignInClient(activity).getPhoneNumberFromIntent(data)
            complete { success(number) }
        } catch (e: ApiException) {
            completeWithFailure(e)
        }
        return true
    }

    /**
     * "No phone number is found on this device" (no SIM, or none shared with
     * Google) arrives as a CANCELED status. That is an ordinary outcome, not a
     * fault, so it gets its own code instead of UNAVAILABLE.
     */
    private fun completeWithFailure(e: Exception) {
        if (e is ApiException && e.statusCode == CommonStatusCodes.CANCELED) {
            complete { fail(BridgeErrors.NO_RESULT, e.message) }
        } else {
            complete { fail(BridgeErrors.UNAVAILABLE, e.message) }
        }
    }

    /** Replies at most once and frees the slot, whichever path gets here first. */
    private fun complete(reply: MethodChannel.Result.() -> Unit) {
        val result = pending ?: return
        pending = null
        result.reply()
    }

    private companion object {
        const val REQUEST_CODE = 0x7068 // "ph"
    }
}
