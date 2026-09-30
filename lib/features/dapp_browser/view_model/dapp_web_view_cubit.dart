import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../../walletconnect/data/models/wc_chain.dart';
import '../data/browser_url_resolver.dart';
import '../data/dapp_browser_repository.dart';
import '../data/dapp_connection_repository.dart';
import '../data/eip1193/bridge_models.dart';
import '../data/eip1193/dapp_interaction.dart';
import '../data/eip1193/eip1193_bridge.dart';
import '../data/models/browser_visit.dart';
import 'dapp_web_view_state.dart';

/// Backs the in-app browser: page/toolbar state, what the user typed, and
/// the bridge between the page's `window.ethereum` and the wallet.
///
/// The WebView itself is owned by the view; the cubit only hears about
/// page events and issues commands over [navigationCommands].
class DappWebViewCubit extends Cubit<DappWebViewState> {
  DappWebViewCubit({
    required String rawUrl,
    required DappBrowserRepository browserRepository,
    required DappConnectionRepository connections,
    required Eip1193Bridge bridge,
    required DappPromptBroker broker,
    DateTime Function()? now,
  })  : _browserRepository = browserRepository,
        _connections = connections,
        _bridge = bridge,
        _broker = broker,
        _now = now ?? DateTime.now,
        super(_initialState(rawUrl)) {
    final current = state;
    if (current is DappWebViewBrowsing) {
      initialUri = current.page.url;
      unawaited(_refreshConnection());
    }
    _eventsSubscription = _bridge.events.listen(_onBridgeEvent);
  }

  final DappBrowserRepository _browserRepository;
  final DappConnectionRepository _connections;
  final Eip1193Bridge _bridge;
  final DappPromptBroker _broker;
  final DateTime Function() _now;
  late final StreamSubscription<BridgeEvent> _eventsSubscription;
  final _navigation = StreamController<Uri>.broadcast();
  final _pageEvents = StreamController<BridgeEvent>.broadcast();

  /// The page to load first; null when the state is [DappWebViewBlocked].
  Uri? initialUri;

  Stream<Uri> get navigationCommands => _navigation.stream;
  Stream<DappPrompt> get prompts => _broker.prompts;

  /// Provider events for the page that is currently open.
  Stream<BridgeEvent> get pageEvents => _pageEvents.stream;

  static DappWebViewState _initialState(String rawUrl) {
    return switch (BrowserUrlResolver.resolve(rawUrl)) {
      ResolvedUrl(:final uri) || ResolvedSearch(:final uri) =>
        DappWebViewState.browsing(
          page: BrowserPage(url: uri),
          chain: WcChains.ethereum,
        ),
      RejectedInput(:final reason) => DappWebViewState.blocked(reason),
    };
  }

  // ---- address bar ----

  /// Returns an error message when [input] can't be opened, else null and
  /// the view is told to navigate.
  String? submitAddress(String input) {
    switch (BrowserUrlResolver.resolve(input)) {
      case ResolvedUrl(:final uri) || ResolvedSearch(:final uri):
        _navigation.add(uri);
        return null;
      case RejectedInput(:final reason):
        return reason;
    }
  }

  /// Whether the WebView may load [uri] (link taps, redirects, scripts).
  bool allowNavigation(Uri uri) => BrowserUrlResolver.allowsNavigation(uri);

  // ---- page events (from the WebView callbacks) ----

  void _update(BrowserPage Function(BrowserPage page) change) {
    final current = state;
    if (current is! DappWebViewBrowsing) return;
    emit(current.copyWith(page: change(current.page)));
  }

  void onLoadStart(Uri url) {
    _update((p) => p.copyWith(url: url, loading: true, progress: 0.05));
    unawaited(_refreshConnection());
  }

  void onProgress(int percent) =>
      _update((p) => p.copyWith(progress: (percent / 100).clamp(0.0, 1.0)));

  void onLoadStop(Uri url, {String? title}) {
    _update(
      (p) => p.copyWith(
        url: url,
        title: title ?? p.title,
        loading: false,
        progress: 1,
      ),
    );
    if (BrowserUrlResolver.originOf(url) != null) {
      unawaited(
        _browserRepository.recordVisit(
          BrowserVisit.sanitized(
            uri: url,
            title: title ?? '',
            visitedAt: _now(),
          ),
        ),
      );
    }
  }

  void onTitle(String? title) {
    if (title == null) return;
    _update((p) => p.copyWith(title: title));
  }

  void onUrlChanged(Uri url) {
    _update((p) => p.copyWith(url: url));
    unawaited(_refreshConnection());
  }

  void onNavState({required bool canGoBack, required bool canGoForward}) =>
      _update(
        (p) => p.copyWith(canGoBack: canGoBack, canGoForward: canGoForward),
      );

  // ---- wallet bridge ----

  /// Handles one message from the page's `lexorBridge`. Returns the JSON
  /// reply to post back, or null when the message is dropped (not the main
  /// frame, origin unknown/changed, or malformed).
  Future<String?> handleBridgeMessage({
    required Object? message,
    required Uri? sourceOrigin,
    required bool isMainFrame,
  }) async {
    if (!isMainFrame || sourceOrigin == null) return null;
    final origin = BrowserUrlResolver.originOf(sourceOrigin);
    final current = state;
    if (origin == null || current is! DappWebViewBrowsing) return null;
    // The message must come from the page the user is looking at.
    if (BrowserUrlResolver.originOf(current.page.url) != origin) return null;

    final request = BridgeRequest.parse(message, origin: origin);
    if (request == null) return null;
    final response = await _bridge.handle(request);
    if (!isClosed && _changesConnection(request.method)) {
      await _refreshConnection();
    }
    return response.toJsonString();
  }

  static bool _changesConnection(String method) =>
      method == 'eth_requestAccounts' ||
      method == 'wallet_requestPermissions' ||
      method == 'wallet_switchEthereumChain';

  void _onBridgeEvent(BridgeEvent event) {
    final current = state;
    if (current is! DappWebViewBrowsing) return;
    if (BrowserUrlResolver.originOf(current.page.url) != event.origin) return;
    _pageEvents.add(event);
  }

  Future<void> _refreshConnection() async {
    final current = state;
    if (current is! DappWebViewBrowsing) return;
    final origin = BrowserUrlResolver.originOf(current.page.url);
    if (origin == null) {
      emit(current.copyWith(connection: null, chain: WcChains.ethereum));
      return;
    }
    final result = await _connections.connectionFor(origin);
    final latest = state;
    if (isClosed || latest is! DappWebViewBrowsing) return;
    if (BrowserUrlResolver.originOf(latest.page.url) != origin) return;
    final connection = result.valueOrNull;
    emit(
      latest.copyWith(
        connection: connection,
        chain: connection?.chain ?? latest.chain,
      ),
    );
  }

  /// Revokes the current site's access (toolbar → connection sheet).
  Future<void> disconnect() async {
    final current = state;
    if (current is! DappWebViewBrowsing) return;
    final origin = BrowserUrlResolver.originOf(current.page.url);
    if (origin == null) return;
    await _bridge.disconnect(origin);
    await _refreshConnection();
  }

  Future<void> switchChain(WcChain chain) async {
    final current = state;
    if (current is! DappWebViewBrowsing) return;
    final origin = BrowserUrlResolver.originOf(current.page.url);
    if (origin == null) return;
    await _bridge.switchChain(origin, chain);
    if (isClosed) return;
    final latest = state;
    if (latest is DappWebViewBrowsing) {
      emit(latest.copyWith(chain: chain));
    }
    await _refreshConnection();
  }

  @override
  Future<void> close() async {
    _broker.dispose();
    await _eventsSubscription.cancel();
    _bridge.dispose();
    // Not awaited: a broadcast controller's close() future only completes
    // once every listener has seen the done event, and the view may still
    // be subscribed while this cubit is being torn down.
    unawaited(_navigation.close());
    unawaited(_pageEvents.close());
    return super.close();
  }
}
