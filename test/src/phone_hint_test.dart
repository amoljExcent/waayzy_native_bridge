import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waayzy_native_bridge/waayzy_native_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final channelName = NativeChannels.name('phone_hint');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void mockNative(Future<Object?>? Function(MethodCall call)? handler) {
    messenger.setMockMethodCallHandler(MethodChannel(channelName), handler);
  }

  PhoneHint build({bool isAndroid = true, NativeLogger? onLog}) =>
      PhoneHint(isAndroid: isAndroid, onLog: onLog);

  tearDown(() => mockNative(null));

  test('channel name carries the package prefix', () {
    expect(channelName, 'com.excentsolutions.waayzy_native_bridge/phone_hint');
  });

  group('normalize', () {
    test('strips the country code and punctuation', () {
      expect(PhoneHint.normalize('+919876543210'), '9876543210');
      expect(PhoneHint.normalize('+91 98765-43210'), '9876543210');
      expect(PhoneHint.normalize('919876543210'), '9876543210');
    });

    test('keeps a bare 10-digit number', () {
      expect(PhoneHint.normalize('9876543210'), '9876543210');
    });

    test('keeps the last 10 digits whatever comes before them', () {
      expect(PhoneHint.normalize('09876543210'), '9876543210');
      expect(PhoneHint.normalize('+09876543210'), '9876543210');
      expect(PhoneHint.normalize('+91 09876543210'), '9876543210');
      expect(PhoneHint.normalize('0091 9876543210'), '9876543210');
      expect(PhoneHint.normalize('+91 91 9123456789'), '9123456789');
      // From a real device.
      expect(PhoneHint.normalize('+44918283904467'), '8283904467');
    });

    test('drops numbers with fewer than 10 digits', () {
      expect(PhoneHint.normalize('12345'), isNull);
      expect(PhoneHint.normalize('+91 98765'), isNull);
      expect(PhoneHint.normalize(''), isNull);
    });

    test('honours another national length', () {
      expect(
        PhoneHint.normalize('+4915112345678', nationalLength: 11),
        '15112345678',
      );
    });
  });

  group('requestPhoneNumber', () {
    test('returns the normalised number the native side picked', () async {
      mockNative((call) async {
        expect(call.method, 'getPhoneNumber');
        return '+919876543210';
      });

      expect(await build().requestPhoneNumber(), '9876543210');
    });

    test('returns null when the sheet is dismissed', () async {
      mockNative((_) async => null);

      expect(await build().requestPhoneNumber(), isNull);
    });

    test('returns null and logs a native fault at error level', () async {
      final logged = <(NativeLogLevel, String, StackTrace?)>[];
      mockNative((_) async {
        throw PlatformException(code: NativeErrorCodes.unavailable);
      });

      final number = await build(
        onLog: (level, message, stack) => logged.add((level, message, stack)),
      ).requestPhoneNumber();

      expect(number, isNull);
      expect(logged.single.$1, NativeLogLevel.error);
      expect(logged.single.$2, contains(NativeErrorCodes.unavailable));
      expect(logged.single.$3, isNotNull);
    });

    test('logs "no phone number on device" at info level, no stack', () async {
      final logged = <(NativeLogLevel, String, StackTrace?)>[];
      mockNative((_) async {
        throw PlatformException(
          code: NativeErrorCodes.noResult,
          message: '16: [28438] No phone number is found on this device.',
        );
      });

      final number = await build(
        onLog: (level, message, stack) => logged.add((level, message, stack)),
      ).requestPhoneNumber();

      expect(number, isNull);
      expect(logged.single.$1, NativeLogLevel.info);
      expect(logged.single.$2, contains('No phone number is found'));
      expect(logged.single.$3, isNull);
    });

    test('logs the shape, not the number, when it cannot be used', () async {
      final logged = <String>[];
      mockNative((_) async => '+91 98765');

      final number = await build(
        onLog: (level, message, _) {
          expect(level, NativeLogLevel.info);
          logged.add(message);
        },
      ).requestPhoneNumber();

      expect(number, isNull);
      // The raw number is logged separately (debug only); this message must
      // describe the shape without repeating it.
      final shape = logged.singleWhere((m) => m.contains('could not be used'));
      expect(shape, contains('7 digits'));
      expect(shape, isNot(contains('98765')));
    });

    test('logs the raw number from the device before normalising', () async {
      final logged = <String>[];
      mockNative((_) async => '+91 0 98765 43210');

      final number = await build(
        onLog: (level, message, _) {
          expect(level, NativeLogLevel.info);
          logged.add(message);
        },
      ).requestPhoneNumber();

      expect(number, '9876543210');
      expect(logged.single, contains('+91 0 98765 43210'));
    });

    test('returns null when no native handler exists', () async {
      mockNative(null);

      expect(await build().requestPhoneNumber(), isNull);
    });

    test('does not call native off Android', () async {
      var called = false;
      mockNative((_) async {
        called = true;
        return '+919876543210';
      });

      expect(await build(isAndroid: false).requestPhoneNumber(), isNull);
      expect(called, isFalse);
    });
  });

  group('NativeChannel.invoke', () {
    test('maps a PlatformException to a NativeFailure with its code', () async {
      mockNative((_) async {
        throw PlatformException(
          code: NativeErrorCodes.noActivity,
          message: 'nope',
        );
      });

      final result = await build().invoke<String>('getPhoneNumber');

      expect(result, isA<NativeFailure>());
      final failure = result as NativeFailure;
      expect(failure.code, NativeErrorCodes.noActivity);
      expect(failure.message, 'nope');
    });

    test('maps a missing handler to UNSUPPORTED', () async {
      mockNative(null);

      final result = await build().invoke<String>('getPhoneNumber');

      expect((result as NativeFailure).code, NativeErrorCodes.unsupported);
    });

    test('a null value is still a success', () async {
      mockNative((_) async => null);

      final result = await build().invoke<String>('getPhoneNumber');

      expect(result, isA<NativeSuccess<String>>());
      expect((result as NativeSuccess<String>).value, isNull);
    });
  });
}
