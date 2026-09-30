import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design_system/lexor_page_scaffold.dart';
import '../../../core/design_system/lexor_palette.dart';
import '../../walletconnect/data/models/wc_request.dart';
import '../../walletconnect/data/models/wc_session.dart';
import '../../walletconnect/view/widgets/review_request_sheet.dart';
import '../data/browser_url_resolver.dart';
import '../data/eip1193/dapp_interaction.dart';
import '../data/eip1193/dapp_provider_script.dart';
import '../view_model/dapp_web_view_cubit.dart';
import '../view_model/dapp_web_view_state.dart';
import 'widgets/browser_connection_sheet.dart';
import 'widgets/dapp_connect_sheet.dart';

/// The in-app browser. Deliberately has **no blur or opacity overlays**
/// (CLAUDE.md: platform-view performance) — every surface here is opaque.
///
/// Security posture:
/// * only http(s) pages load; other schemes are cancelled;
/// * camera/microphone/etc. permission prompts from pages are denied;
/// * popups are disabled;
/// * the wallet bridge accepts messages from the main frame only, and the
///   cubit checks the sender's origin against the page on screen.
class DappWebViewScreen extends StatefulWidget {
  const DappWebViewScreen({super.key, this.webViewOverride});

  /// Replaces the platform `InAppWebView` — widget tests can't host one.
  @visibleForTesting
  final Widget? webViewOverride;

  @override
  State<DappWebViewScreen> createState() => _DappWebViewScreenState();
}

class _DappWebViewScreenState extends State<DappWebViewScreen> {
  final _webViewKey = GlobalKey();
  final _addressController = TextEditingController();
  final _addressFocus = FocusNode();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  InAppWebViewController? _controller;
  bool _editingAddress = false;

  /// Null until we know whether this WebView can host the wallet bridge.
  bool? _walletSupported;

  DappWebViewCubit get _cubit => context.read<DappWebViewCubit>();

  @override
  void initState() {
    super.initState();
    _addressFocus.addListener(() {
      if (!_addressFocus.hasFocus && _editingAddress) {
        setState(() => _editingAddress = false);
      }
    });
    unawaited(_detectWalletSupport());
    final cubit = context.read<DappWebViewCubit>();
    _subscriptions
      ..add(cubit.navigationCommands.listen(_load))
      ..add(cubit.prompts.listen(_onPrompt))
      ..add(
        cubit.pageEvents.listen(
          (event) => _controller?.evaluateJavascript(
            source: DappProviderScript.emitScript(event),
          ),
        ),
      );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _addressController.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  Future<void> _detectWalletSupport() async {
    var supported = true;
    if (widget.webViewOverride == null &&
        defaultTargetPlatform == TargetPlatform.android) {
      supported = await WebViewFeature.isFeatureSupported(
        WebViewFeature.WEB_MESSAGE_LISTENER,
      );
    }
    if (mounted) setState(() => _walletSupported = supported);
  }

  // ---- commands to the WebView ----

  void _load(Uri uri) {
    unawaited(
      _controller?.loadUrl(urlRequest: URLRequest(url: WebUri.uri(uri))),
    );
  }

  Future<void> _refreshNavState(InAppWebViewController controller) async {
    final back = await controller.canGoBack();
    final forward = await controller.canGoForward();
    if (mounted) {
      _cubit.onNavState(canGoBack: back, canGoForward: forward);
    }
  }

  // ---- prompts from the wallet bridge ----

  Future<void> _onPrompt(DappPrompt prompt) async {
    if (!mounted) {
      switch (prompt) {
        case ConnectPrompt():
          prompt.respond(false);
        case ReviewPrompt():
          prompt.respond(const WcRequestDecision.reject());
        case NoticePrompt():
          break;
      }
      return;
    }
    switch (prompt) {
      case ConnectPrompt():
        final approved = await showDappConnectSheet(
          context,
          dapp: prompt.dapp,
          account: prompt.account,
        );
        prompt.respond(approved);
      case ReviewPrompt():
        final decision = await showRequestReviewSheet(context, prompt.request);
        prompt.respond(decision);
      case NoticePrompt(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
    }
  }

  // ---- address bar ----

  void _beginEditing(BrowserPage page) {
    setState(() {
      _editingAddress = true;
      _addressController.text = page.url.toString();
      _addressController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _addressController.text.length,
      );
    });
    _addressFocus.requestFocus();
  }

  void _submitAddress(String text) {
    final error = _cubit.submitAddress(text);
    setState(() => _editingAddress = false);
    _addressFocus.unfocus();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _copyLink(BrowserPage page) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: page.url.toString()));
    messenger.showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  void _openConnectionSheet(DappWebViewBrowsing state) {
    final origin = BrowserUrlResolver.originOf(state.page.url);
    if (origin == null) return;
    final cubit = _cubit;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BrowserConnectionSheet(
        origin: origin,
        connection: state.connection,
        chain: state.chain,
        onSwitchChain: cubit.switchChain,
        onDisconnect: cubit.disconnect,
      ),
    );
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DappWebViewCubit, DappWebViewState>(
      builder: (context, state) {
        if (state is DappWebViewBlocked) {
          return LexorPageScaffold(
            title: "Can't open page",
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  state.reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: LexorPalette.textSecondary),
                ),
              ),
            ),
          );
        }
        final browsing = state as DappWebViewBrowsing;
        final page = browsing.page;
        return PopScope(
          canPop: !page.canGoBack,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(_controller?.goBack());
          },
          child: Scaffold(
            backgroundColor: LexorPalette.background,
            body: SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    page: page,
                    editing: _editingAddress,
                    controller: _addressController,
                    focusNode: _addressFocus,
                    onEdit: () => _beginEditing(page),
                    onSubmit: _submitAddress,
                    onClose: () => context.pop(),
                    onReloadOrStop: () => page.loading
                        ? unawaited(_controller?.stopLoading() ?? Future.value())
                        : unawaited(_controller?.reload() ?? Future.value()),
                    onCopy: () => _copyLink(page),
                    onWalletConnect: () => context.push(Routes.walletConnect),
                  ),
                  SizedBox(
                    height: 2,
                    child: page.loading
                        ? LinearProgressIndicator(
                            value: page.progress,
                            minHeight: 2,
                            color: LexorPalette.accent,
                            backgroundColor: Colors.transparent,
                          )
                        : null,
                  ),
                  if (_walletSupported == false)
                    const _UnsupportedBanner(),
                  Expanded(
                    child: _walletSupported == null
                        ? const SizedBox.shrink()
                        : _buildWebView(),
                  ),
                  _BottomBar(
                    state: browsing,
                    onBack: page.canGoBack
                        ? () => unawaited(_controller?.goBack() ?? Future.value())
                        : null,
                    onForward: page.canGoForward
                        ? () => unawaited(
                              _controller?.goForward() ?? Future.value(),
                            )
                        : null,
                    onConnection: () => _openConnectionSheet(browsing),
                    onHome: () => context.pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebView() {
    final override = widget.webViewOverride;
    if (override != null) return override;
    final cubit = _cubit;
    return InAppWebView(
      key: _webViewKey,
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        javaScriptCanOpenWindowsAutomatically: false,
        supportMultipleWindows: false,
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: true,
        allowsInlineMediaPlayback: true,
        isInspectable: kDebugMode,
        allowFileAccess: false,
        allowContentAccess: false,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
        thirdPartyCookiesEnabled: false,
        transparentBackground: false,
      ),
      initialUserScripts: UnmodifiableListView([
        if (_walletSupported ?? false)
          UserScript(
            source: DappProviderScript.source,
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
            forMainFrameOnly: true,
          ),
      ]),
      onWebViewCreated: (controller) async {
        _controller = controller;
        if (_walletSupported ?? false) {
          await controller.addWebMessageListener(
            WebMessageListener(
              jsObjectName: DappProviderScript.bridgeObject,
              // The object is injected into every frame, but the cubit
              // drops anything that isn't the main frame.
              allowedOriginRules: {'*'},
              onPostMessage: (message, sourceOrigin, isMainFrame, replyProxy) async {
                final reply = await cubit.handleBridgeMessage(
                  message: message?.data,
                  sourceOrigin: sourceOrigin == null
                      ? null
                      : Uri.tryParse(sourceOrigin.toString()),
                  isMainFrame: isMainFrame,
                );
                if (reply != null) {
                  unawaited(replyProxy.postMessage(WebMessage(data: reply)));
                }
              },
            ),
          );
        }
        final initial = cubit.initialUri;
        if (initial != null) _load(initial);
      },
      shouldOverrideUrlLoading: (controller, action) async {
        final url = action.request.url;
        final uri = url == null ? null : Uri.tryParse(url.toString());
        if (uri != null && cubit.allowNavigation(uri)) {
          return NavigationActionPolicy.ALLOW;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                uri == null || uri.scheme.isEmpty
                    ? 'Blocked an unsupported link'
                    : 'Blocked a "${uri.scheme}:" link',
              ),
            ),
          );
        }
        return NavigationActionPolicy.CANCEL;
      },
      onLoadStart: (controller, url) {
        final uri = url == null ? null : Uri.tryParse(url.toString());
        if (uri != null) cubit.onLoadStart(uri);
      },
      onLoadStop: (controller, url) async {
        final uri = url == null ? null : Uri.tryParse(url.toString());
        final title = await controller.getTitle();
        if (uri != null) cubit.onLoadStop(uri, title: title);
        await _refreshNavState(controller);
      },
      onProgressChanged: (controller, progress) => cubit.onProgress(progress),
      onTitleChanged: (controller, title) => cubit.onTitle(title),
      onUpdateVisitedHistory: (controller, url, isReload) async {
        final uri = url == null ? null : Uri.tryParse(url.toString());
        if (uri != null) cubit.onUrlChanged(uri);
        await _refreshNavState(controller);
      },
      // Pages never get camera, microphone, geolocation, etc.
      onPermissionRequest: (controller, request) async => PermissionResponse(
        resources: request.resources,
        action: PermissionResponseAction.DENY,
      ),
      onCreateWindow: (controller, action) async => false,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.page,
    required this.editing,
    required this.controller,
    required this.focusNode,
    required this.onEdit,
    required this.onSubmit,
    required this.onClose,
    required this.onReloadOrStop,
    required this.onCopy,
    required this.onWalletConnect,
  });

  final BrowserPage page;
  final bool editing;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onEdit;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClose;
  final VoidCallback onReloadOrStop;
  final VoidCallback onCopy;
  final VoidCallback onWalletConnect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          _RoundButton(
            icon: Icons.close_rounded,
            label: 'Close browser',
            onPressed: onClose,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: editing
                ? TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onSubmitted: onSubmit,
                    textInputAction: TextInputAction.go,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: const TextStyle(
                      color: LexorPalette.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: LexorPalette.cardSolid,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  )
                : _AddressPill(page: page, onTap: onEdit),
          ),
          IconButton(
            onPressed: onReloadOrStop,
            tooltip: page.loading ? 'Stop' : 'Reload',
            icon: Icon(
              page.loading ? Icons.close_rounded : Icons.refresh_rounded,
              color: LexorPalette.textSecondary,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            color: LexorPalette.cardSolid,
            icon: const Icon(
              Icons.more_vert_rounded,
              color: LexorPalette.textSecondary,
            ),
            onSelected: (value) {
              switch (value) {
                case 'copy':
                  onCopy();
                case 'wc':
                  onWalletConnect();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'copy',
                child: Text(
                  'Copy link',
                  style: TextStyle(color: LexorPalette.textPrimary),
                ),
              ),
              PopupMenuItem(
                value: 'wc',
                child: Text(
                  'WalletConnect',
                  style: TextStyle(color: LexorPalette.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressPill extends StatelessWidget {
  const _AddressPill({required this.page, required this.onTap});

  final BrowserPage page;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final secure = page.isSecure;
    return Material(
      color: LexorPalette.cardSolid,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                secure ? Icons.lock_rounded : Icons.lock_open_rounded,
                size: 14,
                color: secure ? LexorPalette.accentMuted : LexorPalette.danger,
                semanticLabel: secure ? 'Secure connection' : 'Not secure',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  page.host.isEmpty ? 'Loading…' : page.host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LexorPalette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!secure && page.host.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    'NOT SECURE',
                    style: TextStyle(
                      color: LexorPalette.danger,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.state,
    required this.onBack,
    required this.onForward,
    required this.onConnection,
    required this.onHome,
  });

  final DappWebViewBrowsing state;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final VoidCallback onConnection;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final connection = state.connection;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: LexorPalette.cardSolid,
        border: Border(top: BorderSide(color: LexorPalette.divider)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: LexorPalette.textPrimary,
            disabledColor: LexorPalette.textDisabled,
          ),
          IconButton(
            onPressed: onForward,
            tooltip: 'Forward',
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            color: LexorPalette.textPrimary,
            disabledColor: LexorPalette.textDisabled,
          ),
          Expanded(
            child: Center(
              child: Material(
                color: connection == null
                    ? LexorPalette.chip
                    : const Color(0xFF2A3400),
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: onConnection,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 14,
                          color: connection == null
                              ? LexorPalette.textSecondary
                              : LexorPalette.accent,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            connection == null
                                ? 'Not connected'
                                : '${shortenAddress(connection.address)} · '
                                    '${state.chain.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: connection == null
                                  ? LexorPalette.textSecondary
                                  : LexorPalette.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onHome,
            tooltip: 'Back to dApps',
            icon: const Icon(Icons.apps_rounded, size: 20),
            color: LexorPalette.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LexorPalette.cardSolid,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 20,
            color: LexorPalette.textPrimary,
            semanticLabel: label,
          ),
        ),
      ),
    );
  }
}

class _UnsupportedBanner extends StatelessWidget {
  const _UnsupportedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: LexorPalette.cautionFill,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Text(
        "Wallet connections aren't supported by this device's web view, so "
        'sites can be browsed but not connected.',
        style: TextStyle(color: LexorPalette.caution, fontSize: 12),
      ),
    );
  }
}
