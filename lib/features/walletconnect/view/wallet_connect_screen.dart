import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design_system/lexor_card.dart';
import '../../../core/design_system/lexor_page_scaffold.dart';
import '../../../core/design_system/lexor_palette.dart';
import '../data/wc_pairing_uri.dart';
import '../view_model/pairing_cubit.dart';
import '../view_model/pairing_state.dart';
import '../view_model/wallet_connect_cubit.dart';
import '../view_model/wallet_connect_state.dart';
import 'widgets/wc_active_session_card.dart';
import 'widgets/wc_debug_request_simulator.dart';

/// WalletConnect hub: paste a pairing link, see and manage connected apps.
class WalletConnectScreen extends StatefulWidget {
  const WalletConnectScreen({super.key});

  @override
  State<WalletConnectScreen> createState() => _WalletConnectScreenState();
}

class _WalletConnectScreenState extends State<WalletConnectScreen> {
  final _link = TextEditingController();

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  bool get _valid => WcPairingUri.tryParse(_link.text) != null;
  bool get _showError => _link.text.trim().isNotEmpty && !_valid;

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    setState(() => _link.text = text);
  }

  Future<void> _scan() async {
    final link = await context.push<String>(Routes.walletConnectScan);
    if (link == null || !mounted) return;
    setState(() => _link.text = link);
    _connect();
  }

  void _connect() {
    if (!_valid) return;
    final link = _link.text;
    // The link carries the pairing key and is single-use: hand it over and
    // drop it from the field immediately.
    _link.clear();
    setState(() {});
    context.read<PairingCubit>().pair(link);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PairingCubit, PairingState>(
      listenWhen: (previous, current) =>
          current is PairingConnecting && previous is! PairingConnecting,
      listener: (context, state) => context.push(Routes.walletConnectPairing),
      child: LexorPageScaffold(
        title: 'WalletConnect',
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ConnectCard(
              controller: _link,
              showError: _showError,
              canConnect: _valid,
              onChanged: (_) => setState(() {}),
              onPaste: _paste,
              onScan: _scan,
              onConnect: _connect,
            ),
            const SizedBox(height: 24),
            const _SessionsSection(),
            if (kDebugMode &&
                context.read<WalletConnectCubit>().canSimulateRequests) ...[
              const SizedBox(height: 24),
              const WcDebugRequestSimulator(),
            ],
            const SizedBox(height: 24),
            const _TrustNote(),
          ],
        ),
      ),
    );
  }
}

class _ConnectCard extends StatelessWidget {
  const _ConnectCard({
    required this.controller,
    required this.showError,
    required this.canConnect,
    required this.onChanged,
    required this.onPaste,
    required this.onScan,
    required this.onConnect,
  });

  final TextEditingController controller;
  final bool showError;
  final bool canConnect;
  final ValueChanged<String> onChanged;
  final VoidCallback onPaste;
  final VoidCallback onScan;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return LexorCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: LexorPalette.chip,
                ),
                child: const Icon(
                  Icons.link_rounded,
                  size: 20,
                  color: LexorPalette.accent,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Connect to an app',
                  style: TextStyle(
                    color: LexorPalette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "On the app's website choose WalletConnect, copy the link, "
            'then paste it here.',
            style: TextStyle(
              color: LexorPalette.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            onChanged: onChanged,
            minLines: 1,
            maxLines: 3,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.url,
            style: const TextStyle(
              color: LexorPalette.textPrimary,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: 'wc:…@2?relay-protocol=irn&symKey=…',
              hintStyle: const TextStyle(color: LexorPalette.textDisabled),
              filled: true,
              fillColor: LexorPalette.chipSoft,
              contentPadding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              errorText:
                  showError ? "That doesn't look like a WalletConnect link" : null,
              suffixIcon: TextButton(
                onPressed: onPaste,
                child: const Text(
                  'Paste',
                  style: TextStyle(
                    color: LexorPalette.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: Material(
              color: LexorPalette.chip,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onScan,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded,
                        size: 18, color: LexorPalette.accent),
                    SizedBox(width: 8),
                    Text(
                      'Scan QR code',
                      style: TextStyle(
                        color: LexorPalette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: Material(
              color: canConnect ? LexorPalette.accent : LexorPalette.chip,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: canConnect ? onConnect : null,
                child: Center(
                  child: Text(
                    'Connect',
                    style: TextStyle(
                      color: canConnect
                          ? LexorPalette.onAccent
                          : LexorPalette.textDisabled,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionsSection extends StatelessWidget {
  const _SessionsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletConnectCubit, WalletConnectState>(
      builder: (context, state) {
        final count = switch (state) {
          WalletConnectLoaded(:final sessions) => sessions.length,
          _ => 0,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LexorSectionLabel(
              'Active sessions',
              trailing: count == 0
                  ? null
                  : Text(
                      '$count CONNECTED',
                      style: const TextStyle(
                        color: LexorPalette.accentMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.44,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            switch (state) {
              WalletConnectLoading() => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: LexorPalette.accent,
                    ),
                  ),
                ),
              WalletConnectFailure() => const _EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: "Couldn't load connected apps",
                  body: 'Pull back and try again in a moment.',
                ),
              WalletConnectLoaded(:final sessions) when sessions.isEmpty =>
                _EmptyState(
                  icon: Icons.link_off_rounded,
                  title: 'No connected apps',
                  body: 'Apps you connect with WalletConnect will appear '
                      'here, where you can review and revoke access.',
                  action: TextButton(
                    onPressed: () => context.push(Routes.dapps),
                    child: const Text(
                      'Browse dApps',
                      style: TextStyle(
                        color: LexorPalette.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              WalletConnectLoaded(:final sessions) => Column(
                  children: [
                    for (final session in sessions) ...[
                      WcActiveSessionCard(
                        session: session,
                        onTap: () => context.push(
                          Routes.walletConnectSessionPath(session.topic),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
            },
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return LexorCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          Icon(icon, size: 36, color: LexorPalette.textSecondary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: LexorPalette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: LexorPalette.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    );
  }
}

class _TrustNote extends StatelessWidget {
  const _TrustNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(42, 41, 46, 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.gpp_maybe_outlined,
              size: 17.5,
              color: Color(0xFF8E9079),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Only connect to apps you trust. Connecting never gives an '
              'app your keys, and every transaction or signature still '
              'needs your approval.',
              style: TextStyle(
                color: LexorPalette.textSecondary,
                fontSize: 12,
                letterSpacing: 0.12,
                height: 16 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
