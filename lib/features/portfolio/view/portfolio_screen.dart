import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/token_asset.dart';
import '../view_model/portfolio_cubit.dart';
import '../view_model/portfolio_state.dart';
import 'activity_history_screen.dart';
import 'receive_token_screen.dart';
import 'swap_screen.dart';
import 'token_detail_screen.dart';
import 'transaction_pending_screen.dart';
import 'widgets/ai_swap_insights_sheet.dart';
import 'widgets/lexor_ai_floating_button.dart';
import 'widgets/manage_token_list_card.dart';
import 'widgets/portfolio_ambient_background.dart';
import 'widgets/portfolio_balance_card.dart';
import 'widgets/portfolio_bottom_nav_bar.dart';
import 'widgets/portfolio_filter_bar.dart';
import 'widgets/portfolio_header.dart';
import 'widgets/token_asset_card.dart';
import '../../walletconnect/view/wallet_connect_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  PortfolioNavTab _currentTab = PortfolioNavTab.portfolio;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openTokenDetail(TokenAsset asset, PortfolioState state) {
    state.mapOrNull(
      loaded: (loaded) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TokenDetailScreen(
              asset: asset,
              recentTransactions: loaded.data.recentTransactions,
              onSwapPressed: () => _openSwap(initialFrom: asset),
              onSendPressed: () => _openSend(token: asset),
              onReceivePressed: () => _openReceive(initialToken: asset),
              onStakePressed: () => _showQuickActionMessage('Staking pool opened for ${asset.symbol}'),
            ),
          ),
        );
      },
    );
  }

  void _openReceive({TokenAsset? initialToken}) {
    final state = context.read<PortfolioCubit>().state;
    state.mapOrNull(
      loaded: (loaded) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReceiveTokenScreen(
              tokens: loaded.data.assets,
              initialSelectedToken: initialToken,
            ),
          ),
        );
      },
    );
  }

  void _openSend({TokenAsset? token}) {
    final selected = token ??
        context.read<PortfolioCubit>().state.mapOrNull(
              loaded: (l) => l.data.assets.firstOrNull,
            );
    final symbol = selected?.symbol ?? 'ETH';
    final amount = selected != null
        ? (selected.balance > 0 ? (selected.balance * 0.1).toStringAsFixed(4) : '0.4500')
        : '0.4500';
    final amountUsd = selected != null
        ? (selected.balance > 0
            ? (selected.balance * 0.1 * selected.priceUsd).toStringAsFixed(2)
            : '1,530.45')
        : '1,530.45';

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionPendingScreen(
          amount: amount,
          tokenSymbol: symbol,
          amountUsd: amountUsd,
          recipient: 'vitalik.eth',
          recipientAddress: '0xd8dA...6045',
          network: selected?.network ?? 'Ethereum Mainnet',
        ),
      ),
    );
  }

  void _openActivityHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ActivityHistoryScreen(),
      ),
    );
  }

  void _openSwap({TokenAsset? initialFrom}) {
    final state = context.read<PortfolioCubit>().state;
    state.mapOrNull(
      loaded: (loaded) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SwapScreen(
              allTokens: loaded.data.assets,
              initialFromToken: initialFrom,
            ),
          ),
        );
      },
    );
  }

  void _openWalletConnect() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const WalletConnectScreen(),
      ),
    );
  }

  void _showQuickActionMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _openAiAssistant() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AiSwapInsightsSheet(
        onApplyOptimalRoute: () {
          _openSwap();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131317),
      body: PortfolioAmbientBackground(
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<PortfolioCubit, PortfolioState>(
            builder: (context, state) {
              return state.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4EE6B)),
                  ),
                ),
                failure: (failure) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: Color(0xFFFFB4AB),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Failed to load portfolio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.read<PortfolioCubit>().refresh(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFD4EE6B),
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
                loaded: (data, refreshing, activeFilter, searchQuery, selectedToken) {
                  final tokens = state.visibleAssets;

                  return Stack(
                    children: [
                      // Scrollable content
                      RefreshIndicator(
                        onRefresh: () => context.read<PortfolioCubit>().refresh(),
                        color: const Color(0xFFD4EE6B),
                        backgroundColor: const Color(0xFF1F1F23),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(
                            top: 72,
                            left: 20,
                            right: 20,
                            bottom: 120,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Main Balance Card
                              PortfolioBalanceCard(
                                snapshot: data,
                                onSendPressed: () => _openSend(),
                                onReceivePressed: () => _openReceive(),
                                onSwapPressed: () => _openSwap(),
                                onBuyPressed: () => _showQuickActionMessage('Fiat on-ramp opened'),
                                onSearchPressed: () {
                                  setState(() {
                                    _isSearchActive = !_isSearchActive;
                                    if (!_isSearchActive) {
                                      _searchController.clear();
                                      context.read<PortfolioCubit>().setSearchQuery('');
                                    }
                                  });
                                },
                                onAlertsPressed: () => _showQuickActionMessage('Price alerts active'),
                                onNetworkSelectorPressed: () => _showQuickActionMessage('Network: All Networks active'),
                              ),
                              const SizedBox(height: 16),

                              // Optional Search Input Row
                              if (_isSearchActive) ...[
                                Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1F1F23),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.search_rounded,
                                        size: 20,
                                        color: Color(0xFFC6C6C7),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          autofocus: true,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: 'Search token name or symbol...',
                                            hintStyle: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFFC6C8B2),
                                            ),
                                            border: InputBorder.none,
                                            isDense: true,
                                          ),
                                          onChanged: (val) {
                                            context.read<PortfolioCubit>().setSearchQuery(val);
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: Color(0xFFC6C8B2),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isSearchActive = false;
                                            _searchController.clear();
                                            context.read<PortfolioCubit>().setSearchQuery('');
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Filter Pills Bar (All, Tokens, DeFi + tune)
                              PortfolioFilterBar(
                                selectedFilter: activeFilter,
                                onFilterChanged: (filter) {
                                  context.read<PortfolioCubit>().setFilter(filter);
                                },
                                onTunePressed: () => _showQuickActionMessage('Asset filter settings'),
                              ),
                              const SizedBox(height: 12),

                              // Token List Cards
                              if (tokens.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                    child: Text(
                                      'No matching tokens found',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFFC6C8B2),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...tokens.map((token) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: TokenAssetCard(
                                      asset: token,
                                      onTap: () => _openTokenDetail(token, state),
                                    ),
                                  );
                                }),

                              const SizedBox(height: 4),

                              // Manage Token List Card
                              ManageTokenListCard(
                                onTap: () => _showQuickActionMessage('Manage Token List modal'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Fixed Header (Top)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: PortfolioHeader(
                          networkName: data.activeNetwork,
                          onNotificationPressed: _openWalletConnect,
                          onProfilePressed: () => _showQuickActionMessage('Profile: 0x48...1b9'),
                        ),
                      ),

                      // Floating Lexor AI Assistant (Bottom Right above nav bar)
                      Positioned(
                        right: 20,
                        bottom: 96,
                        child: LexorAiFloatingButton(
                          onTap: _openAiAssistant,
                        ),
                      ),

                      // Floating Bottom Navigation Bar
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 16,
                        child: Center(
                          child: PortfolioBottomNavBar(
                            currentTab: _currentTab,
                            onTabSelected: (tab) {
                              setState(() {
                                _currentTab = tab;
                              });
                              if (tab == PortfolioNavTab.swap) {
                                _openSwap();
                              } else if (tab == PortfolioNavTab.activity) {
                                _openActivityHistory();
                              } else if (tab == PortfolioNavTab.browser) {
                                _openWalletConnect();
                              } else if (tab != PortfolioNavTab.portfolio) {
                                _showQuickActionMessage('${tab.name.toUpperCase()} tab');
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
