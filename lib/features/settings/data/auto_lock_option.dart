enum AutoLockOption {
  immediately('Immediately', 'Lock the moment you leave the app', Duration.zero),
  oneMinute('1 Minute', 'Recommended balance of safety and comfort', Duration(minutes: 1)),
  fiveMinutes('5 Minutes', 'Lock after 5 minutes in the background', Duration(minutes: 5)),
  fifteenMinutes('15 Minutes', 'Lock after 15 minutes in the background', Duration(minutes: 15)),
  never('Never', 'Wallet stays unlocked until you lock it', null);

  const AutoLockOption(this.label, this.description, this.timeout);

  final String label;
  final String description;

  /// `null` means never auto-lock.
  final Duration? timeout;
}
