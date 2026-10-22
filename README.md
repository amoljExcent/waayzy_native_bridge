# waayzy_native_bridge

Reusable bridges from Flutter to native Android/iOS features for Waayzy apps. One
feature = one MethodChannel (`com.excentsolutions.waayzy_native_bridge/<feature>`),
all hosted by a single Flutter plugin that registers itself — host apps do not
edit `MainActivity` or `AppDelegate`.

| Feature | Dart | Android | iOS |
|---|---|---|---|
| Phone Number Hint | `PhoneHint` | Google Identity (`play-services-auth`) | none (returns `null`) |

## Install

```yaml
dependencies:
  waayzy_native_bridge:
    git:
      url: https://github.com/amoljExcent/waayzy_native_bridge.git
      ref: v0.1.0 # tag; bump to pick up new features
```

(While developing locally: `path: ../waayzy_native_bridge`.)

## Use

```dart
final hint = PhoneHint(
  onLog: (level, message, stack) => logger.log(level.name, message, stack), // optional
);

// Opens the system sheet. Returns the last 10 digits of the picked number
// (whatever prefix Google adds: +91, 0, another country…), e.g. '9876543210', or
// null if the user dismissed it or it isn't available. Never throws.
final phone = await hint.requestPhoneNumber(nationalLength: 10);
```

Requires Android with Google Play services; the app's `minSdk` must be 24+.

## Error contract

Native replies `success(null)` when the user dismisses a system UI (not an
error), or `error(code, message)` with a code from `BridgeErrors.kt` /
`NativeErrorCodes` (`UNAVAILABLE`, `NO_ACTIVITY`, `ALREADY_RUNNING`,
`INTERNAL`). In Dart, `NativeChannel.invoke` turns these — and
`MissingPluginException`, as `UNSUPPORTED` — into a `NativeFailure`; it never
throws.

## Adding a feature

1. **Android** — implement `NativeFeature`
   (`android/src/main/kotlin/.../features/`), using `BridgeChannels.name("<feature>")`,
   and add it to `features` in `WaayzyNativeBridgePlugin`. Override
   `onAttachedToActivity` / `onDetachedFromActivity` if it needs an Activity or
   its results (see `PhoneHintFeature`).
2. **Dart** — `class X extends NativeChannel` with `super(feature: '<feature>')`,
   calling `invoke<T>('method')`; export it from `lib/waayzy_native_bridge.dart`.
3. **iOS** — optional; until implemented, Dart reports `UNSUPPORTED`.
4. Add tests, bump `version` and `CHANGELOG.md`, tag, and bump `ref:` in the apps.

Try it on a device with the `example/` app.
