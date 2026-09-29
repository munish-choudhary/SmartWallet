import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/models/token_asset.dart';
import 'widgets/receive_qr_sheet.dart';

/// Screen matching the Figma spec: `/* Receive – Select Token */`
/// Allows users to search, filter by network, and tap an asset to view its
/// QR code and deposit address.
class ReceiveTokenScreen extends StatefulWidget {
  const ReceiveTokenScreen({
    super.key,
    this.tokens,
    this.initialSelectedToken,
    this.onCustomTokenImport,
  });

  final List<TokenAsset>? tokens;
  final TokenAsset? initialSelectedToken;
  final VoidCallback? onCustomTokenImport;

  @override
  State<ReceiveTokenScreen> createState() => _ReceiveTokenScreenState();
}

class _ReceiveTokenScreenState extends State<ReceiveTokenScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedNetworkFilter = 'All';
  String _searchQuery = '';

  static const List<String> _networks = [
    'All',
    'Ethereum',
    'Solana',
    'Bitcoin',
    'Polygon',
    'Arbitrum',
    'Base',
  ];

  late final List<TokenAsset> _allTokens;

  @override
  void initState() {
    super.initState();
    _allTokens = widget.tokens ?? _defaultReceiveTokens;
    if (widget.initialSelectedToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openTokenQrSheet(widget.initialSelectedToken!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TokenAsset> get _filteredTokens {
    return _allTokens.where((token) {
      final matchesQuery = _searchQuery.isEmpty ||
          token.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          token.symbol.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          token.network.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesNetwork = _selectedNetworkFilter == 'All' ||
          token.network.toLowerCase().contains(_selectedNetworkFilter.toLowerCase()) ||
          token.name.toLowerCase().contains(_selectedNetworkFilter.toLowerCase());

      return matchesQuery && matchesNetwork;
    }).toList();
  }

  void _openTokenQrSheet(TokenAsset token) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReceiveQrSheet(token: token),
    );
  }

  void _showGuidanceDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F23),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFFD4EE6B), size: 20),
            SizedBox(width: 8),
            Text(
              'Deposit Safety Guide',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Always verify that the network of your sending wallet matches the destination network shown on the QR modal.',
              style: TextStyle(color: Color(0xFFC6C8B2), fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 10),
            Text(
              '• Never send unsupported tokens to a chain address — e.g. do not send Solana SPL tokens to an Ethereum ERC-20 address.',
              style: TextStyle(color: Color(0xFFC6C8B2), fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 10),
            Text(
              '• All deposits are non-custodial and settle straight to your on-chain keypair.',
              style: TextStyle(color: Color(0xFFC6C8B2), fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood', style: TextStyle(color: Color(0xFFD4EE6B), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = _filteredTokens;

    return Scaffold(
      backgroundColor: const Color(0xFF131317),
      body: Stack(
        children: [
          // Ambient Atmospheric Glowing Orbs
          // Top right purple aura (#5B3E8C, blur 55px)
          Positioned(
            top: -64,
            right: 0,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
                child: Container(
                  width: 256,
                  height: 256,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(91, 62, 140, 0.25),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          // Mid left orange aura (#C8733A, blur 50px)
          Positioned(
            top: 320,
            left: -64,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  width: 224,
                  height: 224,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(200, 115, 58, 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Header (Height 64px matching CSS)
                _buildHeader(context),

                // Scrollable List Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Subtitle Context & QR Shortcut Action Bar
                        _buildSubtitleBar(),
                        const SizedBox(height: 12),

                        // Interactive Search Bar
                        _buildSearchBar(),
                        const SizedBox(height: 16),

                        // Network Filter Chips
                        _buildNetworkFilterCarousel(),
                        const SizedBox(height: 16),

                        // Section Header: SUPPORTED ASSETS
                        _buildSectionHeader(tokens.length),
                        const SizedBox(height: 8),

                        // Token List Stack
                        if (tokens.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No matching deposit assets found',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFC6C8B2),
                                ),
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: tokens.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final token = tokens[index];
                                return _buildTokenItem(token);
                              },
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Interactive Security & Import Token Footer Helper
                        _buildFooterHelper(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(19, 19, 23, 0.8),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.12),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(42, 41, 46, 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: Color(0xFFE4E1E7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title + Category
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECEIVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.55,
                          color: Color(0xFFD4EE6B),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Select Asset to Deposit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: Color(0xFFE4E1E7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Profile Badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B3E8C), Color(0xFFD4EE6B)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.1),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'LP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF131317),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitleBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INSTANT DEPOSIT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.55,
                    color: Color(0xFFD4EE6B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Select a token to view your dedicated recipient address and QR code.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFC6C8B2),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              // Scan QR Button
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Camera ready for direct QR scan'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(42, 41, 46, 0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.05),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 20,
                      color: Color(0xFFE4E1E7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Safety Guidance Button
              GestureDetector(
                onTap: _showGuidanceDialog,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(42, 41, 46, 0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.05),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.help_outline_rounded,
                      size: 20,
                      color: Color(0xFFE4E1E7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(42, 41, 46, 0.7),
          borderRadius: BorderRadius.circular(9999),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              size: 20,
              color: Color(0xFFC6C6C7),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search token name, symbol, or network...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFB4B5B5),
                    letterSpacing: -0.3,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: const Icon(
                  Icons.cancel_rounded,
                  size: 18,
                  color: Color(0xFFB4B5B5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkFilterCarousel() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _networks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final net = _networks[index];
          final isSelected = net == _selectedNetworkFilter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedNetworkFilter = net;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFD4EE6B)
                    : const Color.fromRGBO(42, 41, 46, 0.8),
                borderRadius: BorderRadius.circular(9999),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.1),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                net,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF181E00)
                      : const Color(0xFFE4E1E7),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'SUPPORTED ASSETS ($count)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.55,
                  color: Color(0xFFC6C6C7),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4EE6B),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const Text(
            'VERIFIED ONLY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.44,
              color: Color(0xFFC6C8B2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenItem(TokenAsset token) {
    return GestureDetector(
      onTap: () => _openTokenQrSheet(token),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(27, 27, 31, 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color.fromRGBO(255, 255, 255, 0.04),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Token Emblem with verified badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(token.iconBgColor).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      token.symbol.substring(0, 1),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(token.iconBgColor),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1B1B1F), width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Token Name & Network
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          token.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE4E1E7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        token.symbol,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC6C6C7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(53, 52, 57, 0.8),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      token.network,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC6C6C7),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Balance & Chevron
            Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      token.formattedFiatValue,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: Color(0xFFE4E1E7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${token.balance.toStringAsFixed(2)} ${token.symbol}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFC6C6C7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFFC6C6C7),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterHelper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't see your token? ",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFC6C6C7),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (widget.onCustomTokenImport != null) {
                    widget.onCustomTokenImport!();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Custom Token Import modal opened')),
                    );
                  }
                },
                child: const Text(
                  'Import Custom Token',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD4EE6B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: const BoxDecoration(
              color: Color.fromRGBO(14, 14, 18, 0.8),
              borderRadius: BorderRadius.all(Radius.circular(9999)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 12,
                  color: Color(0xFFD4EE6B),
                ),
                SizedBox(width: 6),
                Text(
                  'Direct on-chain deposits. No intermediary custody.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    color: Color(0xFFC6C8B2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fallback tokens list matching the Figma receive token spec
final List<TokenAsset> _defaultReceiveTokens = [
  const TokenAsset(
    id: 'ethereum',
    name: 'Ethereum',
    symbol: 'ETH',
    network: 'ERC-20',
    balance: 14.10,
    priceUsd: 3420.50,
    change24h: 5.2,
    iconBgColor: 0xFF627EEA,
    contractAddress: '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2',
    marketCap: '\$275.4B',
    volume24h: '\$14.28B',
    sparklinePoints: [3100.0, 3200.0, 3180.0, 3350.0, 3420.5],
    stakedBalance: 3.10,
  ),
  const TokenAsset(
    id: 'bitcoin',
    name: 'Bitcoin',
    symbol: 'BTC',
    network: 'BTC',
    balance: 1.04,
    priceUsd: 64250.00,
    change24h: 3.1,
    iconBgColor: 0xFFF7931A,
    contractAddress: 'Native (UTXO)',
    marketCap: '\$1.26T',
    volume24h: '\$28.50B',
    sparklinePoints: [62000.0, 62800.0, 63400.0, 64250.0],
    stakedBalance: 0.0,
  ),
  const TokenAsset(
    id: 'solana',
    name: 'Solana',
    symbol: 'SOL',
    network: 'SOL',
    balance: 38.50,
    priceUsd: 148.20,
    change24h: 8.4,
    iconBgColor: 0xFF14F195,
    contractAddress: 'Native (Solana)',
    marketCap: '\$68.9B',
    volume24h: '\$4.15B',
    sparklinePoints: [130.0, 138.0, 142.0, 148.2],
    stakedBalance: 12.0,
  ),
  const TokenAsset(
    id: 'usdc',
    name: 'USD Coin',
    symbol: 'USDC',
    network: 'ERC-20',
    balance: 10450.00,
    priceUsd: 1.00,
    change24h: 0.01,
    iconBgColor: 0xFF2775CA,
    contractAddress: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
    marketCap: '\$35.2B',
    volume24h: '\$5.80B',
    sparklinePoints: [1.0, 1.0, 1.0, 1.0],
    stakedBalance: 0.0,
  ),
  const TokenAsset(
    id: 'usdt',
    name: 'Tether USD',
    symbol: 'USDT',
    network: 'ERC-20',
    balance: 5200.00,
    priceUsd: 1.00,
    change24h: -0.02,
    iconBgColor: 0xFF26A17B,
    contractAddress: '0xdac17f958d2ee523a2206206994597c13d831ec7',
    marketCap: '\$118.4B',
    volume24h: '\$42.10B',
    sparklinePoints: [1.0, 1.0, 1.0, 1.0],
    stakedBalance: 0.0,
  ),
  const TokenAsset(
    id: 'avalanche',
    name: 'Avalanche',
    symbol: 'AVAX',
    network: 'AVAX',
    balance: 120.00,
    priceUsd: 28.40,
    change24h: -1.8,
    iconBgColor: 0xFFE84142,
    contractAddress: '0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7',
    marketCap: '\$11.2B',
    volume24h: '\$890M',
    sparklinePoints: [30.0, 29.5, 28.8, 28.4],
    stakedBalance: 40.0,
  ),
];
