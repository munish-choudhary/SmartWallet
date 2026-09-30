/// Lets the router reach the onboarding screens while a wallet already
/// exists — but only during an explicit "add another wallet" flow.
///
/// Without a gate, the router's redirect makes onboarding unreachable once
/// a wallet exists. The Wallets screen [open]s the gate right before
/// starting the flow and [close]s it when the flow ends or is abandoned.
/// Holds no secret material; it is a single flag.
final class AddWalletGate {
  bool _open = false;

  bool get isOpen => _open;

  void open() => _open = true;

  void close() => _open = false;
}
