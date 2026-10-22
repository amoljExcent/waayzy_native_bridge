import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_result.dart';

/// Channel names. Must match `BridgeChannels.name` on the Android side.
abstract final class NativeChannels {
  static const _prefix = 'com.excentsolutions.waayzy_native_bridge';

  static String name(String feature) => '$_prefix/$feature';
}

/// Error codes the native side may reply with. Must match `BridgeErrors`.
abstract final class NativeErrorCodes {
  static const unavailable = 'UNAVAILABLE';
  static const noActivity = 'NO_ACTIVITY';
  static const alreadyRunning = 'ALREADY_RUNNING';
  static const internal = 'INTERNAL';

  /// The feature ran but has nothing to give (e.g. no phone number on the
  /// device). Expected, so it is logged at info level.
  static const noResult = 'NO_RESULT';

  /// Dart-side: no handler registered on this platform (e.g. iOS, or a native
  /// feature that hasn't shipped there yet).
  static const unsupported = 'UNSUPPORTED';
}

/// Severity of a [NativeLogger] message.
enum NativeLogLevel {
  /// Expected outcome (see `NativeFailure.isExpected`).
  info,

  /// A real fault.
  error,
}

/// Receives a message whenever a native call fails. Wire it to the app's logger.
/// [stack] is only provided for [NativeLogLevel.error].
typedef NativeLogger =
    void Function(NativeLogLevel level, String message, StackTrace? stack);

/// Base for every feature that talks to native code.
///
/// A subclass is one feature, one channel:
/// ```dart
/// class Foo extends NativeChannel {
///   Foo({super.onLog, super.channel}) : super(feature: 'foo');
///
///   Future<NativeResult<String>> bar() => invoke<String>('bar');
/// }
/// ```
/// Platform errors never escape as exceptions — they come back as a
/// [NativeFailure] carrying the native error code.
abstract class NativeChannel {
  NativeChannel({required String feature, this._onLog, MethodChannel? channel})
    : _channel = channel ?? MethodChannel(NativeChannels.name(feature));

  final MethodChannel _channel;
  final NativeLogger? _onLog;

  /// Sends a message to the app's [NativeLogger], if it gave one.
  @protected
  void log(NativeLogLevel level, String message, [StackTrace? stack]) =>
      _onLog?.call(level, message, stack);

  /// Calls [method] and returns its result.
  Future<NativeResult<T>> invoke<T>(String method, [Object? arguments]) async {
    try {
      return NativeSuccess<T>(
        await _channel.invokeMethod<T>(method, arguments),
      );
    } on MissingPluginException catch (e, s) {
      return _fail(method, NativeErrorCodes.unsupported, e.message, s);
    } on PlatformException catch (e, s) {
      return _fail(method, e.code, e.message, s);
    }
  }

  NativeFailure _fail(
    String method,
    String code,
    String? message,
    StackTrace s,
  ) {
    final failure = NativeFailure(
      code: code,
      message: message ?? code,
      stack: s,
    );
    final text = '${_channel.name}#$method failed: $code $message';
    if (failure.isExpected) {
      _onLog?.call(NativeLogLevel.info, text, null);
    } else {
      _onLog?.call(NativeLogLevel.error, text, s);
    }
    return failure;
  }
}
