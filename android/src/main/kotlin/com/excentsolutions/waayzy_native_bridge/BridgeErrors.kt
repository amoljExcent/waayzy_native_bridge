package com.excentsolutions.waayzy_native_bridge

import io.flutter.plugin.common.MethodChannel

/**
 * Error codes shared by every feature. Dart reads `PlatformException.code`
 * (see `NativeErrorCodes`), so keep these stable.
 *
 * A user dismissing a system UI is not an error: reply `success(null)`.
 */
object BridgeErrors {
    /** The device or Play services can't provide this feature. */
    const val UNAVAILABLE = "UNAVAILABLE"

    /** The call needs a foreground Activity and there isn't one. */
    const val NO_ACTIVITY = "NO_ACTIVITY"

    /** A request for this feature is already in flight. */
    const val ALREADY_RUNNING = "ALREADY_RUNNING"

    /**
     * The feature ran fine but has nothing to give (e.g. no phone number on the
     * device). Expected, not a fault: Dart logs it at info level.
     */
    const val NO_RESULT = "NO_RESULT"

    const val INTERNAL = "INTERNAL"
}

fun MethodChannel.Result.fail(code: String, message: String? = null, details: Any? = null) =
    error(code, message, details)
