import Flutter
import UIKit

/// iOS has no native features yet. Registering no channels is deliberate: Dart
/// then gets a MissingPluginException, which NativeChannel reports as an
/// UNSUPPORTED failure. When a feature gains an iOS implementation, register
/// its own FlutterMethodChannel here (channel name: see NativeChannels.name).
public class WaayzyNativeBridgePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {}
}
