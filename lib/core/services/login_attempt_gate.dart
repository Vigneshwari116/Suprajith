/// Tracks consecutive failed logins and enforces a cooldown after [maxAttempts].
class LoginAttemptGate {
  LoginAttemptGate({
    this.maxAttempts = 5,
    this.blockDuration = const Duration(seconds: 30),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final int maxAttempts;
  final Duration blockDuration;
  final DateTime Function() _now;

  int _consecutiveFailures = 0;
  DateTime? _blockedUntil;

  void _clearExpiredBlock() {
    if (_blockedUntil != null && !_now().isBefore(_blockedUntil!)) {
      _blockedUntil = null;
      _consecutiveFailures = 0;
    }
  }

  bool get isBlocked {
    _clearExpiredBlock();
    return _blockedUntil != null;
  }

  Duration? get remainingBlock {
    if (!isBlocked) return null;
    final remaining = _blockedUntil!.difference(_now());
    if (remaining.isNegative) return Duration.zero;
    return remaining;
  }

  void recordFailure() {
    _clearExpiredBlock();
    if (isBlocked) return;
    _consecutiveFailures++;
    if (_consecutiveFailures >= maxAttempts) {
      _blockedUntil = _now().add(blockDuration);
      _consecutiveFailures = 0;
    }
  }

  void recordSuccess() {
    _consecutiveFailures = 0;
    _blockedUntil = null;
  }
}
