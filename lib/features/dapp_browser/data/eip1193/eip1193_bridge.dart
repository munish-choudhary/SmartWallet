import 'dart:async';

import '../../../../core/result/result.dart';
import '../../../walletconnect/data/models/wc_chain.dart';
import '../../../walletconnect/data/models/wc_request.dart';
import '../../../walletconnect/data/models/wc_session.dart';
import '../../../walletconnect/data/wallet_account_source.dart';
import '../dapp_catalog.dart';
import '../dapp_connection_repository.dart';
import '../models/dapp.dart';
import '../models/dapp_connection.dart';
import 'bridge_models.dart';
import 'dapp_identity.dart';
import 'dapp_interaction.dart';
import 'evm_hex.dart';
import 'evm_read_client.dart';
import 'tx_decoder.dart';
import 'typed_data_parser.dart';

/// The wallet side of `window.ethereum`: answers EIP-1193 requests coming
/// from a page in the in-app browser.
///
/// Trust model — every input is hostile until proven otherwise:
/// * the origin is supplied by the native layer, never the message;
/// * accounts are only revealed after the user connects that exact origin;
/// * anything that signs or sends goes through [DappInteractionPrompter]
///   (a review sheet) and then [DappSigningGateway]; there is no path that
///   skips the sheet, and the default gateway refuses to sign;
/// * only a fixed allowlist of read-only methods is forwarded to a node.
class Eip1193Bridge {
  Eip1193Bridge({
    required DappConnectionRepository connections,
    required WalletAccountSource accounts,
    required DappInteractionPrompter prompter,
    required DappSigningGateway signer,
    required EvmReadClient reader,
    List<Dapp> catalog = DappCatalog.featured,
    DateTime Function()? now,
  })  : _connections = connections,
        _accounts = accounts,
        _prompter = prompter,
        _signer = signer,
        _reader = reader,
        _catalog = catalog,
        _now = now ?? DateTime.now;

  final DappConnectionRepository _connections;
  final WalletAccountSource _accounts;
  final DappInteractionPrompter _prompter;
  final DappSigningGateway _signer;
  final EvmReadClient _reader;
  final List<Dapp> _catalog;
  final DateTime Function() _now;

  final _events = StreamController<BridgeEvent>.broadcast();
  final Map<String, WcChain> _chains = {};
  int _nextRequestId = 0;

  /// `chainChanged` / `accountsChanged` for the page to receive.
  Stream<BridgeEvent> get events => _events.stream;

  static const _readOnlyMethods = {
    'eth_blockNumber',
    'eth_call',
    'eth_estimateGas',
    'eth_gasPrice',
    'eth_maxPriorityFeePerGas',
    'eth_feeHistory',
    'eth_getBalance',
    'eth_getCode',
    'eth_getStorageAt',
    'eth_getTransactionCount',
    'eth_getTransactionByHash',
    'eth_getTransactionReceipt',
    'eth_getBlockByNumber',
    'eth_getBlockByHash',
    'eth_getLogs',
    'eth_syncing',
    'net_listening',
    'web3_clientVersion',
  };

  Future<BridgeResponse> handle(BridgeRequest request) async {
    try {
      return await _dispatch(request);
    } on Object {
      // Never echo internals (or anything page-supplied) back to the page.
      return BridgeError(request.id, RpcCode.internal, 'Internal error');
    }
  }

  Future<BridgeResponse> _dispatch(BridgeRequest r) async {
    switch (r.method) {
      case 'eth_chainId':
        return BridgeResult(r.id, (await _chainFor(r.origin)).hexChainId);
      case 'net_version':
        return BridgeResult(r.id, '${(await _chainFor(r.origin)).chainId}');
      case 'eth_accounts':
        final connection = await _connection(r.origin);
        return BridgeResult(
          r.id,
          connection == null ? <String>[] : [connection.address],
        );
      case 'eth_requestAccounts':
        return _requestAccounts(r);
      case 'wallet_requestPermissions':
        final response = await _requestAccounts(r);
        return response is BridgeResult
            ? BridgeResult(r.id, [
                {'parentCapability': 'eth_accounts'},
              ])
            : response;
      case 'wallet_getPermissions':
        final connection = await _connection(r.origin);
        return BridgeResult(r.id, [
          if (connection != null) {'parentCapability': 'eth_accounts'},
        ]);
      case 'wallet_switchEthereumChain':
        return _switchChain(r);
      case 'personal_sign':
        return _personalSign(r);
      case 'eth_signTypedData':
      case 'eth_signTypedData_v3':
      case 'eth_signTypedData_v4':
        return _signTypedData(r);
      case 'eth_sendTransaction':
        return _sendTransaction(r);
      case 'eth_sign':
        return BridgeError(
          r.id,
          RpcCode.unsupportedMethod,
          'eth_sign is disabled: it can sign arbitrary data.',
        );
      default:
        if (_readOnlyMethods.contains(r.method)) return _read(r);
        return BridgeError(
          r.id,
          RpcCode.unsupportedMethod,
          'The method ${_safe(r.method)} is not supported.',
        );
    }
  }

  // ---- connection & chain ----

  Future<DappConnection?> _connection(String origin) async =>
      (await _connections.connectionFor(origin)).valueOrNull;

  Future<WcChain> _chainFor(String origin) async {
    final connection = await _connection(origin);
    return connection?.chain ?? _chains[origin] ?? WcChains.ethereum;
  }

  static bool _isSecureOrigin(String origin) {
    final uri = Uri.tryParse(origin);
    if (uri == null) return false;
    if (uri.scheme == 'https') return true;
    return uri.scheme == 'http' &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1');
  }

  Future<BridgeResponse> _requestAccounts(BridgeRequest r) async {
    final existing = await _connection(r.origin);
    if (existing != null) return BridgeResult(r.id, [existing.address]);

    if (!_isSecureOrigin(r.origin)) {
      return BridgeError(
        r.id,
        RpcCode.unauthorized,
        'Wallet connections require a secure (HTTPS) site.',
      );
    }
    final account = await _accounts.activeEvmAccount();
    if (account case Err()) {
      return BridgeError(r.id, RpcCode.internal, 'No account available');
    }
    final wallet = account.valueOrNull!;
    final dapp = DappIdentity.forOrigin(r.origin, catalog: _catalog);
    final approved = await _prompter.confirmConnection(dapp, wallet);
    if (!approved) return _rejected(r.id);

    final chain = await _chainFor(r.origin);
    await _connections.save(
      DappConnection(
        origin: r.origin,
        address: wallet.address,
        chain: chain,
        connectedAt: _now(),
      ),
    );
    return BridgeResult(r.id, [wallet.address]);
  }

  Future<BridgeResponse> _switchChain(BridgeRequest r) async {
    final arg = r.params.isEmpty ? null : r.params.first;
    final hex = arg is Map ? arg['chainId'] : null;
    if (hex is! String) {
      return BridgeError(r.id, RpcCode.invalidParams, 'Missing chainId');
    }
    final chain = WcChains.parse(hex);
    if (chain == null) {
      return BridgeError(
        r.id,
        RpcCode.unrecognizedChain,
        'This network is not supported by Lexor Pocket.',
      );
    }
    _chains[r.origin] = chain;
    final connection = await _connection(r.origin);
    if (connection != null) {
      await _connections.save(connection.withChain(chain));
    }
    _events.add(ChainChangedEvent(r.origin, chain.hexChainId));
    return BridgeResult(r.id, null);
  }

  /// Revokes [origin]'s access and tells the page.
  Future<void> disconnect(String origin) async {
    await _connections.remove(origin);
    _events.add(AccountsChangedEvent(origin, const []));
  }

  /// Switches the active network for a connected [origin] from the UI.
  Future<void> switchChain(String origin, WcChain chain) async {
    _chains[origin] = chain;
    final connection = await _connection(origin);
    if (connection != null) {
      await _connections.save(connection.withChain(chain));
    }
    _events.add(ChainChangedEvent(origin, chain.hexChainId));
  }

  // ---- signing ----

  Future<BridgeResponse> _personalSign(BridgeRequest r) async {
    final connection = await _connection(r.origin);
    if (connection == null) return _notConnected(r.id);
    if (r.params.length < 2) {
      return BridgeError(r.id, RpcCode.invalidParams, 'Expected [message, address]');
    }
    var message = r.params[0];
    var address = r.params[1];
    // Some older dApps send [address, message].
    if (EvmHex.isAddress(message) && !EvmHex.isAddress(address)) {
      (message, address) = (address, message);
    }
    if (message is! String || message.length > 100 * 1024) {
      return BridgeError(r.id, RpcCode.invalidParams, 'Invalid message');
    }
    if (!EvmHex.isAddress(address) ||
        !EvmHex.sameAddress(address as String, connection.address)) {
      return BridgeError(
        r.id,
        RpcCode.unauthorized,
        'The requested account is not connected.',
      );
    }
    final decoded = EvmHex.decodeMessage(message);
    final request = WcPersonalSignRequest(
      id: _newRequestId(),
      dapp: DappIdentity.forOrigin(r.origin, catalog: _catalog),
      chain: connection.chain,
      signer: connection.address,
      receivedAt: _now(),
      origin: WcRequestOrigin.inAppBrowser,
      message: decoded.text,
      messageIsReadable: decoded.readable,
    );
    return _reviewAndExecute(r.id, request);
  }

  Future<BridgeResponse> _signTypedData(BridgeRequest r) async {
    final connection = await _connection(r.origin);
    if (connection == null) return _notConnected(r.id);
    if (r.params.length < 2) {
      return BridgeError(r.id, RpcCode.invalidParams, 'Expected [address, data]');
    }
    var address = r.params[0];
    var data = r.params[1];
    if (!EvmHex.isAddress(address) && EvmHex.isAddress(data)) {
      (address, data) = (data, address);
    }
    if (!EvmHex.isAddress(address) ||
        !EvmHex.sameAddress(address as String, connection.address)) {
      return BridgeError(
        r.id,
        RpcCode.unauthorized,
        'The requested account is not connected.',
      );
    }
    final parsed = TypedDataParser.parse(data);
    if (parsed == null) {
      return BridgeError(r.id, RpcCode.invalidParams, 'Invalid typed data');
    }
    // A signature for another chain must not be obtainable while the user
    // believes they are on this one.
    if (parsed.chainId != null && parsed.chainId != connection.chain.chainId) {
      return BridgeError(
        r.id,
        RpcCode.invalidParams,
        'The typed data is for a different network than the one selected.',
      );
    }
    final request = WcTypedDataRequest(
      id: _newRequestId(),
      dapp: DappIdentity.forOrigin(r.origin, catalog: _catalog),
      chain: connection.chain,
      signer: connection.address,
      receivedAt: _now(),
      origin: WcRequestOrigin.inAppBrowser,
      primaryType: parsed.primaryType,
      domain: parsed.domain,
      fields: parsed.fields,
      authorizesTransfers: parsed.authorizesTransfers,
    );
    return _reviewAndExecute(r.id, request);
  }

  Future<BridgeResponse> _sendTransaction(BridgeRequest r) async {
    final connection = await _connection(r.origin);
    if (connection == null) return _notConnected(r.id);
    final tx = r.params.isEmpty ? null : r.params.first;
    if (tx is! Map) {
      return BridgeError(r.id, RpcCode.invalidParams, 'Expected a transaction object');
    }
    final from = tx['from'];
    if (from != null &&
        !(EvmHex.isAddress(from) &&
            EvmHex.sameAddress(from as String, connection.address))) {
      return BridgeError(
        r.id,
        RpcCode.unauthorized,
        'The requested account is not connected.',
      );
    }
    final to = tx['to'];
    if (to == null) {
      return BridgeError(
        r.id,
        RpcCode.unsupportedMethod,
        'Contract deployment is not supported.',
      );
    }
    if (!EvmHex.isAddress(to)) {
      return BridgeError(r.id, RpcCode.invalidParams, 'Invalid "to" address');
    }
    final rawValue = tx['value'];
    final value = rawValue == null ? BigInt.zero : EvmHex.quantity(rawValue);
    if (value == null) {
      return BridgeError(r.id, RpcCode.invalidParams, 'Invalid "value"');
    }
    final data = tx['data'] ?? tx['input'] ?? '0x';
    if (!EvmHex.isData(data) || (data as String).length > 256 * 1024) {
      return BridgeError(r.id, RpcCode.invalidParams, 'Invalid "data"');
    }
    final txChainId = tx['chainId'];
    if (txChainId != null) {
      final id = txChainId is String ? EvmHex.quantity(txChainId) : null;
      if (id == null || id != BigInt.from(connection.chain.chainId)) {
        return BridgeError(
          r.id,
          RpcCode.invalidParams,
          'The transaction is for a different network than the one selected.',
        );
      }
    }

    final chain = connection.chain;
    final approve = TxDecoder.approve(data);
    final nftApproval = TxDecoder.setApprovalForAll(data);
    final risks = <WcRiskFlag>[];
    WcTokenApproval? approval;
    if (approve != null) {
      final unlimited = EvmHex.isUnlimited(approve.amount);
      approval = WcTokenApproval(
        tokenSymbol: shortenAddress(to as String),
        spender: approve.spender,
        requestedAmountDisplay:
            unlimited ? 'Unlimited' : '${approve.amount} (raw units)',
        isUnlimited: unlimited,
      );
      if (unlimited) {
        risks.add(const WcRiskFlag(
          severity: WcRiskSeverity.danger,
          title: 'Unlimited token approval',
          detail: 'This lets the spender move all of this token in your '
              'wallet, now and in the future. Set a spending cap instead.',
        ));
      }
    } else if (nftApproval != null && nftApproval.approved) {
      risks.add(const WcRiskFlag(
        severity: WcRiskSeverity.danger,
        title: 'Access to all your NFTs in this collection',
        detail: 'The operator will be able to transfer every item you own '
            'in this collection.',
      ));
    } else if (data != '0x' && TxDecoder.methodName(data) == null) {
      risks.add(const WcRiskFlag(
        severity: WcRiskSeverity.caution,
        title: "We couldn't identify this action",
        detail: 'Only continue if you trust this site and understand what '
            'it is asking your wallet to do.',
      ));
    }

    final request = WcTransactionRequest(
      id: _newRequestId(),
      dapp: DappIdentity.forOrigin(r.origin, catalog: _catalog),
      chain: chain,
      signer: connection.address,
      receivedAt: _now(),
      origin: WcRequestOrigin.inAppBrowser,
      to: to as String,
      valueDisplay: '${EvmHex.formatUnits(value, 18)} ${chain.symbol}',
      networkFeeDisplay: _feeDisplay(tx, chain),
      methodName: TxDecoder.methodName(data),
      dataHex: data,
      approval: approval,
      risks: risks,
    );
    return _reviewAndExecute(r.id, request);
  }

  static String _feeDisplay(Map tx, WcChain chain) {
    final gas = EvmHex.quantity(tx['gas'] ?? tx['gasLimit']);
    final price = EvmHex.quantity(tx['maxFeePerGas'] ?? tx['gasPrice']);
    if (gas == null || price == null) return 'Estimated when sent';
    return '${EvmHex.formatUnits(gas * price, 18, maxFraction: 6)} '
        '${chain.symbol}';
  }

  Future<BridgeResponse> _reviewAndExecute(
    Object id,
    WcRequest request,
  ) async {
    final decision = await _prompter.review(request);
    if (!decision.approved) return _rejected(id);
    final result = await _signer.execute(
      request,
      approvalCap: decision.approvalCap,
    );
    switch (result) {
      case Ok(:final value):
        return BridgeResult(id, value);
      case Err(:final failure):
        if (failure is NotImplementedFailure) {
          _prompter.notice(
            "Signing isn't available in this build yet. Nothing was signed "
            'or sent.',
          );
          return BridgeError(
            id,
            RpcCode.unsupportedMethod,
            'Signing is not available yet.',
          );
        }
        return BridgeError(id, RpcCode.internal, 'The request failed.');
    }
  }

  // ---- read-only proxy ----

  Future<BridgeResponse> _read(BridgeRequest r) async {
    final chain = await _chainFor(r.origin);
    final outcome = await _reader.call(chain, r.method, r.params);
    return switch (outcome) {
      RpcSuccess(:final value) => BridgeResult(r.id, value),
      RpcFailure(:final code, :final message, :final data) =>
        BridgeError(r.id, code, message, data: data),
      RpcUnreachable() => BridgeError(
          r.id,
          RpcCode.disconnected,
          'Could not reach the network. Check your connection.',
        ),
    };
  }

  // ---- helpers ----

  String _newRequestId() => 'browser-${_nextRequestId++}';

  BridgeError _rejected(Object id) =>
      BridgeError(id, RpcCode.userRejected, 'User rejected the request.');

  BridgeError _notConnected(Object id) => BridgeError(
        id,
        RpcCode.unauthorized,
        'Not connected. Call eth_requestAccounts first.',
      );

  /// Page-supplied strings echoed into an error are length-limited.
  static String _safe(String value) =>
      value.length > 64 ? '${value.substring(0, 64)}…' : value;

  void dispose() => unawaited(_events.close());
}
