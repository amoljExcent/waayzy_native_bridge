package com.excentsolutions.waayzy_native_bridge

import com.excentsolutions.waayzy_native_bridge.features.PhoneHintFeature
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts every [NativeFeature]: gives each its own [MethodChannel] and forwards
 * the Activity lifecycle to all of them, so individual features never touch
 * engine wiring. Flutter registers this plugin automatically in host apps.
 */
class WaayzyNativeBridgePlugin : FlutterPlugin, ActivityAware {

    // Every native capability Flutter can call is registered here.
    private val features: List<NativeFeature> = listOf(
        PhoneHintFeature(),
    )

    private val channels = mutableListOf<MethodChannel>()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        features.forEach { feature ->
            MethodChannel(binding.binaryMessenger, feature.channelName).also { channel ->
                channel.setMethodCallHandler(feature::onMethodCall)
                channels += channel
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channels.forEach { it.setMethodCallHandler(null) }
        channels.clear()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) =
        features.forEach { it.onAttachedToActivity(binding) }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivity() = features.forEach { it.onDetachedFromActivity() }
}
