package com.excentsolutions.waayzy_native_bridge

import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * One native capability exposed to Flutter, served on its own MethodChannel.
 *
 * To add a feature: implement this, then add an instance to `features` in
 * [WaayzyNativeBridgePlugin]. Nothing else on the Android side changes.
 */
interface NativeFeature {
    /** Unique channel name, built with [BridgeChannels.name]. */
    val channelName: String

    fun onMethodCall(call: MethodCall, result: MethodChannel.Result)

    /** Called when an Activity is available. Override if you need it or its results. */
    fun onAttachedToActivity(binding: ActivityPluginBinding) {}

    /** Called when the Activity goes away. Release anything tied to it. */
    fun onDetachedFromActivity() {}
}

object BridgeChannels {
    private const val PREFIX = "com.excentsolutions.waayzy_native_bridge"

    /** Must match `NativeChannels.name` on the Dart side. */
    fun name(feature: String) = "$PREFIX/$feature"
}
