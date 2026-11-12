/// Riverpod 3 retries a provider that fails (with growing delays). Our
/// failures are not temporary (bad id, unreadable data), and screens show a
/// "Try again" button instead, so providers use this to turn retry off.
Duration? noRetry(int retryCount, Object error) => null;
