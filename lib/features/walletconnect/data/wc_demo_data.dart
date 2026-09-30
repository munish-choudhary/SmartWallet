import 'models/wc_chain.dart';
import 'models/wc_dapp.dart';
import 'models/wc_request.dart';
import 'models/wc_session.dart';
import 'models/wc_session_proposal.dart';

/// Seed data for [InMemoryWalletConnectRepository]: fake dApps, sessions,
/// proposals and requests so every WalletConnect screen can be exercised
/// without a relay. Nothing here touches the network.
abstract final class WcDemoData {
  static const uniswap = WcDapp(
    name: 'Uniswap',
    url: 'https://app.uniswap.org',
    description: 'Swap, earn, and build on the leading decentralized crypto '
        'trading protocol.',
    brandColor: 0xFFFF007A,
    tags: ['DeFi', 'DEX'],
    verification: WcVerification.verified,
  );

  static const aave = WcDapp(
    name: 'Aave',
    url: 'https://app.aave.com',
    description: 'Non-custodial liquidity protocol to lend and borrow.',
    brandColor: 0xFFB6509E,
    tags: ['DeFi', 'Lending'],
    verification: WcVerification.verified,
  );

  static const openSea = WcDapp(
    name: 'OpenSea',
    url: 'https://opensea.io',
    description: 'The largest NFT marketplace.',
    brandColor: 0xFF2081E2,
    tags: ['NFT'],
    verification: WcVerification.verified,
  );

  static const freeMint = WcDapp(
    name: 'Free Mint Portal',
    url: 'https://free-mint-portal.xyz',
    description: 'Claim your free airdrop now!',
    brandColor: 0xFF7A4B1F,
    tags: ['NFT'],
    verification: WcVerification.unverified,
  );

  static const phishing = WcDapp(
    name: 'Uniswap',
    url: 'https://app-uniswap-claim.top',
    description: 'Claim your UNI airdrop.',
    brandColor: 0xFFFF007A,
    tags: ['DeFi'],
    verification: WcVerification.flagged,
  );

  static List<WcSession> sessions(DateTime now, String address, String label) {
    return [
      WcSession(
        topic: 'a1f3c8d2e5b7',
        dapp: uniswap,
        accountAddress: address,
        accountLabel: label,
        chains: const [WcChains.ethereum, WcChains.arbitrum],
        permissions: const [
          WcPermission.viewAccount,
          WcPermission.sendTransactions,
          WcPermission.signMessages,
        ],
        connectedAt: now.subtract(const Duration(days: 1, hours: 3)),
        expiresAt: now.add(const Duration(days: 6, hours: 21)),
        lastActivityAt: now.subtract(const Duration(minutes: 2)),
        lastActivityLabel: 'Transaction approved',
      ),
      WcSession(
        topic: '9be04a7c1d63',
        dapp: openSea,
        accountAddress: address,
        accountLabel: label,
        chains: const [WcChains.ethereum, WcChains.polygon],
        permissions: const [
          WcPermission.viewAccount,
          WcPermission.signMessages,
          WcPermission.signTypedData,
        ],
        connectedAt: now.subtract(const Duration(days: 4)),
        expiresAt: now.add(const Duration(days: 3)),
        lastActivityAt: now.subtract(const Duration(hours: 5)),
        lastActivityLabel: 'Signed a message',
      ),
    ];
  }

  /// Proposals handed out, in order, to successive pairings: a verified
  /// dApp, an unverified one, and a flagged look-alike.
  static List<WcSessionProposal> proposals(DateTime now) {
    final expiry = now.add(const Duration(minutes: 5));
    return [
      WcSessionProposal(
        id: 'seed',
        dapp: aave,
        requiredChains: const [WcChains.ethereum],
        optionalChains: const [WcChains.polygon, WcChains.arbitrum, WcChains.base],
        permissions: const [
          WcPermission.viewAccount,
          WcPermission.sendTransactions,
          WcPermission.signMessages,
        ],
        expiresAt: expiry,
      ),
      WcSessionProposal(
        id: 'seed',
        dapp: freeMint,
        requiredChains: const [WcChains.ethereum],
        optionalChains: const [WcChains.base],
        permissions: const [
          WcPermission.viewAccount,
          WcPermission.sendTransactions,
          WcPermission.signTypedData,
        ],
        expiresAt: expiry,
      ),
      WcSessionProposal(
        id: 'seed',
        dapp: phishing,
        requiredChains: const [WcChains.ethereum],
        optionalChains: const [],
        permissions: const [
          WcPermission.viewAccount,
          WcPermission.sendTransactions,
          WcPermission.signTypedData,
        ],
        expiresAt: expiry,
      ),
    ];
  }
}

enum WcSimulatedRequestKind { message, typedData, swap, unlimitedApproval }

/// Implemented by repositories that can fabricate incoming requests, so
/// the review sheets can be exercised without a live dApp. Debug-only —
/// the hub only offers it under `kDebugMode`.
abstract interface class WcRequestSimulator {
  Future<bool> simulateRequest(WcSimulatedRequestKind kind);
}

/// Builds a request of [kind] for [session], shaped like what a real
/// dApp would send.
WcRequest buildDemoRequest({
  required WcSimulatedRequestKind kind,
  required String id,
  required WcSession session,
  required DateTime now,
}) {
  final dapp = session.dapp;
  final chain = session.chains.first;
  final signer = session.accountAddress;
  switch (kind) {
    case WcSimulatedRequestKind.message:
      return WcPersonalSignRequest(
        id: id,
        dapp: dapp,
        chain: chain,
        signer: signer,
        receivedAt: now,
        message: '${dapp.host} wants you to sign in with your Ethereum account:\n'
            '$signer\n\n'
            'Sign in to ${dapp.name}. This request will not trigger a '
            'blockchain transaction or cost any gas fees.\n\n'
            'URI: ${dapp.url}\nVersion: 1\nChain ID: ${chain.chainId}\n'
            'Nonce: 8f3a91c2d7\nIssued At: ${now.toUtc().toIso8601String()}',
      );
    case WcSimulatedRequestKind.typedData:
      return WcTypedDataRequest(
        id: id,
        dapp: dapp,
        chain: chain,
        signer: signer,
        receivedAt: now,
        primaryType: 'PermitSingle',
        authorizesTransfers: true,
        domain: [
          const WcTypedField('name', 'Permit2'),
          WcTypedField('chainId', '${chain.chainId}'),
          const WcTypedField(
            'verifyingContract',
            '0x000000000022D473030F116dDEE9F6B43aC78BA3',
          ),
        ],
        fields: const [
          WcTypedField('details', ''),
          WcTypedField(
            'token',
            '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
            depth: 1,
          ),
          WcTypedField('amount', '1,000.00 USDC', depth: 1),
          WcTypedField('expiration', 'in 30 days', depth: 1),
          WcTypedField('nonce', '0', depth: 1),
          WcTypedField(
            'spender',
            '0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD',
          ),
          WcTypedField('sigDeadline', 'in 30 minutes'),
        ],
      );
    case WcSimulatedRequestKind.swap:
      return WcTransactionRequest(
        id: id,
        dapp: dapp,
        chain: chain,
        signer: signer,
        receivedAt: now,
        to: '0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD',
        valueDisplay: '0.25 ETH',
        valueUsd: 855.13,
        networkFeeDisplay: '0.0021 ETH',
        networkFeeUsd: 7.18,
        methodName: 'swapExactETHForTokens',
        dataHex: '0x7ff36ab5000000000000000000000000000000000000000000000000'
            '0000000030d4a1c2',
        balanceChanges: const [
          WcBalanceChange(
            symbol: 'ETH',
            amountDisplay: '0.2500',
            isOutgoing: true,
          ),
          WcBalanceChange(
            symbol: 'USDC',
            amountDisplay: '851.94',
            isOutgoing: false,
          ),
        ],
      );
    case WcSimulatedRequestKind.unlimitedApproval:
      return WcTransactionRequest(
        id: id,
        dapp: dapp,
        chain: chain,
        signer: signer,
        receivedAt: now,
        to: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
        valueDisplay: '0 ETH',
        networkFeeDisplay: '0.0009 ETH',
        networkFeeUsd: 3.08,
        methodName: 'approve',
        dataHex: '0x095ea7b3000000000000000000000000'
            '3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad'
            'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
        approval: const WcTokenApproval(
          tokenSymbol: 'USDC',
          spender: '0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD',
          requestedAmountDisplay: 'Unlimited',
          isUnlimited: true,
        ),
        risks: const [
          WcRiskFlag(
            severity: WcRiskSeverity.danger,
            title: 'Unlimited token approval',
            detail: 'This lets the spender move all of your USDC, now and '
                'in the future. Set a spending cap instead.',
          ),
        ],
      );
  }
}
