import 'package:freezed_annotation/freezed_annotation.dart';

import '../../walletconnect/data/models/wc_chain.dart';
import '../data/models/dapp_connection.dart';

part 'dapp_web_view_state.freezed.dart';

/// What the toolbar needs to know about the page on screen.
@freezed
sealed class BrowserPage with _$BrowserPage {
  const BrowserPage._();

  const factory BrowserPage({
    required Uri url,
    @Default('') String title,

    /// 0.0–1.0
    @Default(0.0) double progress,
    @Default(true) bool loading,
    @Default(false) bool canGoBack,
    @Default(false) bool canGoForward,
  }) = _BrowserPage;

  bool get isSecure => url.scheme == 'https';
  String get host => url.host;
}

@freezed
sealed class DappWebViewState with _$DappWebViewState {
  /// The requested address can't be opened (unsupported scheme, etc.).
  const factory DappWebViewState.blocked(String reason) = DappWebViewBlocked;

  const factory DappWebViewState.browsing({
    required BrowserPage page,

    /// The user's connection for this page's origin, if any.
    DappConnection? connection,

    /// Network the page sees (the connection's, or the default).
    required WcChain chain,
  }) = DappWebViewBrowsing;
}
