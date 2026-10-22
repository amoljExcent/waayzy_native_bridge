import 'package:flutter/foundation.dart';

import '../native_channel.dart';

/// Google's Phone Number Hint (Android only): the user picks one of the
/// device's phone numbers from a system sheet, with no SMS/phone permission.
///
/// Best-effort by design — every failure (unsupported platform, no SIM, no Play
/// services, sheet dismissed) comes back as `null`, so a sign-in screen can
/// simply fall back to typing.
class PhoneHint extends NativeChannel {
  PhoneHint({super.onLog, super.channel, bool? isAndroid})
    : _isAndroid = isAndroid ?? defaultTargetPlatform == TargetPlatform.android,
      super(feature: 'phone_hint');

  final bool _isAndroid;

  /// Shows the sheet and returns the pick as the last [nationalLength] digits
  /// of the number, e.g. `9876543210`, or `null`. See [normalize].
  Future<String?> requestPhoneNumber({int nationalLength = 10}) async {
    if (!_isAndroid) return null;
    final result = await invoke<String>('getPhoneNumber');
    return result.when(
      onSuccess: (raw) {
        if (raw == null) return null;
        // The number itself is personal data and logs are written to a file,
        // so this is debug builds only.
        if (kDebugMode) {
          log(NativeLogLevel.info, 'phone_hint raw number from device: $raw');
        }
        final number = normalize(raw, nationalLength: nationalLength);
        // Silent `null` here would look exactly like "user dismissed it".
        // Log the shape, never the number itself.
        if (number == null) {
          log(
            NativeLogLevel.info,
            'phone_hint returned a number that could not be used: '
            '${raw.replaceAll(RegExp(r'\D'), '').length} digits '
            '(need at least $nationalLength)',
          );
        }
        return number;
      },
      onFailure: (_) => null,
    );
  }

  /// The last [nationalLength] digits of [raw], whatever comes before them
  /// (`+91`, `0`, `0091`, another country's code…): `+91 98765-43210` →
  /// `9876543210`. `null` if there are fewer than [nationalLength] digits.
  static String? normalize(String raw, {int nationalLength = 10}) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < nationalLength) return null;
    return digits.substring(digits.length - nationalLength);
  }
}
