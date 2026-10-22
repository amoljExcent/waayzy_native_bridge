import 'native_channel.dart';

/// Outcome of a native call. `null` is a valid [NativeSuccess] value — e.g. the
/// user dismissed a system sheet — and is not a failure.
sealed class NativeResult<T> {
  const NativeResult();

  /// Runs [onSuccess] or [onFailure], whichever applies.
  R when<R>({
    required R Function(T? value) onSuccess,
    required R Function(NativeFailure failure) onFailure,
  }) => switch (this) {
    NativeSuccess<T>(:final value) => onSuccess(value),
    final NativeFailure failure => onFailure(failure),
  };
}

final class NativeSuccess<T> extends NativeResult<T> {
  const NativeSuccess(this.value);

  final T? value;
}

/// A native call that did not complete. [code] is one of `NativeErrorCodes`.
final class NativeFailure extends NativeResult<Never> {
  const NativeFailure({required this.code, required this.message, this.stack});

  final String code;
  final String message;
  final StackTrace? stack;

  /// An ordinary outcome rather than a fault — the device simply has nothing
  /// to give, or the platform doesn't implement the feature. Log it at info
  /// level; it should not reach crash/error reporting.
  bool get isExpected =>
      code == NativeErrorCodes.noResult || code == NativeErrorCodes.unsupported;

  @override
  String toString() => 'NativeFailure($code: $message)';
}
