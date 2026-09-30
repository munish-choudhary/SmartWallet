import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../data/models/token_asset.dart';
import '../data/models/transaction_record.dart';
import 'widgets/interactive_sparkline_chart.dart';
import 'widgets/portfolio_ambient_background.dart';
import 'activity_history_screen.dart';
import 'transaction_pending_screen.dart';
import 'transaction_success_screen.dart';

class TokenDetailScreen extends StatefulWidget {
  const TokenDetailScreen({
    super.key,
    required this.asset,
    required this.recentTransactions,
    this.onSwapPressed,
    this.onSendPressed,
    this.onReceivePressed,
    this.onStakePressed,
  });

  final TokenAsset asset;
  final List<TransactionRecord> recentTransactions;
  final VoidCallback? onSwapPressed;
  final VoidCallback? onSendPressed;
  final VoidCallback? onReceivePressed;
  final VoidCallback? onStakePressed;

  @override
  State<TokenDetailScreen> createState() => _TokenDetailScreenState();
}

class _TokenDetailScreenState extends State<TokenDetailScreen> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.asset.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;

    return Scaffold(
      backgroundColor: const Color(0xFF131317),
      body: PortfolioAmbientBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Scrollable content
              SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: 72,
                  left: 20,
                  right: 20,
                  bottom: 120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub-header Bar: Currency Identity & Actions
                    _buildSubHeader(asset),
                    const SizedBox(height: 16),

                    // Price & Market Status
                    _buildPriceSection(asset),
                    const SizedBox(height: 16),

                    // Chart Canvas with Time Interval dock
                    InteractiveSparklineChart(
                      points: asset.sparklinePoints,
                      currentPrice: asset.priceUsd,
                      isPositive: asset.isPositiveChange,
                    ),
                    const SizedBox(height: 16),

                    // User Vault Holdings Glass Card
                    _buildHoldingsCard(asset),
                    const SizedBox(height: 16),

                    // Primary Action Dock (Send / Receive / Swap)
                    _buildActionDock(asset),
                    const SizedBox(height: 16),

                    // Staking & Yield Banner
                    _buildStakingBanner(asset),
                    const SizedBox(height: 24),

                    // Recent Token Ledger Activity
                    _buildActivitySection(),
                    const SizedBox(height: 24),

                    // Security Protocol & Contract Verification Note
                    _buildSecurityNote(asset),
                  ],
                ),
              ),

              // Fixed Top Navigation Header Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopHeader(asset),
              ),

              // Floating AI Copilot Button (bottom right)
              Positioned(
                right: 20,
                bottom: 32,
                child: _buildFloatingAiButton(asset),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(TokenAsset asset) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(19, 19, 23, 0.8),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.04),
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 22,
                            color: Color(0xFFE4E1E7),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    asset.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      color: Color(0xFFE4E1E7),
                    ),
                  ),
                ],
              ),
              // Account profile avatar
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF7255A5), Color(0xFFD4EE6B)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 18, color: Color(0xFF131317)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubHeader(TokenAsset asset) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(42, 41, 46, 0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color.fromRGBO(255, 255, 255, 0.1),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.diamond_outlined,
                  size: 20,
                  color: Color(asset.iconBgColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      asset.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: Color(0xFFE4E1E7),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A292E),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        asset.symbol,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.44,
                          color: Color(0xFFC6C8B2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4EE6B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live on ${asset.network}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.12,
                        color: Color(0xFFC6C8B2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Favorite & Share buttons
        Row(
          children: [
            _circularButton(
              icon: _isFavorite
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              iconColor: _isFavorite
                  ? const Color(0xFFD4EE6B)
                  : const Color(0xFFE4E1E7),
              onTap: () {
                setState(() {
                  _isFavorite = !_isFavorite;
                });
              },
            ),
            const SizedBox(width: 8),
            _circularButton(
              icon: Icons.share_rounded,
              iconColor: const Color(0xFFE4E1E7),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sharing ${asset.name} details...'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceSection(TokenAsset asset) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          asset.formattedPrice,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: Color(0xFFE4E1E7),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(212, 238, 107, 0.2),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    asset.isPositiveChange
                        ? Icons.arrow_outward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 12,
                    color: const Color(0xFFD4EE6B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${asset.formattedChange} (+\$168.40)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.44,
                      color: Color(0xFFD4EE6B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Vol (24h): ${asset.volume24h} • Market Cap: ${asset.marketCap}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.44,
            color: Color(0xFFC6C8B2),
          ),
        ),
      ],
    );
  }

  Widget _buildHoldingsCard(TokenAsset asset) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(31, 31, 35, 0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'YOUR HOLDINGS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: Color(0xFFC6C8B2),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF353439),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: const Text(
                  '17.5% of Portfolio',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.44,
                    color: Color(0xFFD4EE6B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    asset.formattedFiatValue,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: Color(0xFFE4E1E7),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'USD',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.16,
                      color: Color(0xFFC6C8B2),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(212, 238, 107, 0.1),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: const Text(
                  '+\$2,450.12',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.44,
                    color: Color(0xFFD4EE6B),
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${asset.formattedBalance} ${asset.symbol}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.26,
                  color: Color(0xFFC6C8B2),
                ),
              ),
              const Text(
                'All-Time PnL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.44,
                  color: Color(0xFFC6C8B2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Micro visual allocation metric
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: 78,
                    child: Container(color: const Color(0xFFD4EE6B)),
                  ),
                  Expanded(
                    flex: 22,
                    child: Container(color: const Color(0xFF7255A5)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available: ${(asset.balance - asset.stakedBalance).toStringAsFixed(2)} ${asset.symbol}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.07,
                  color: Color(0xFFC6C8B2),
                ),
              ),
              Text(
                'Staked: ${asset.stakedBalance.toStringAsFixed(2)} ${asset.symbol}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.07,
                  color: Color(0xFFC6C8B2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionDock(TokenAsset asset) {
    return Row(
      children: [
        Expanded(
          child: _subActionButton(
            label: 'Send',
            icon: Icons.arrow_outward_rounded,
            onTap: widget.onSendPressed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _subActionButton(
            label: 'Receive',
            icon: Icons.arrow_downward_rounded,
            onTap: widget.onReceivePressed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: widget.onSwapPressed,
            child: Container(
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFD4EE6B),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(212, 238, 107, 0.32),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF181E00),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.sync_alt_rounded,
                        size: 16,
                        color: Color(0xFFD4EE6B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Swap ${asset.symbol}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.24,
                      color: Color(0xFF181E00),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _subActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(31, 31, 35, 0.75),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF353439),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, size: 16, color: const Color(0xFFE4E1E7)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.24,
                color: Color(0xFFE4E1E7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStakingBanner(TokenAsset asset) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(42, 41, 46, 0.9),
            Color.fromRGBO(31, 31, 35, 0.85),
            Color(0xFF1B1B1F),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(114, 85, 165, 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.percent_rounded,
                    size: 20,
                    color: Color(0xFFD5BBFF),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Earn up to 4.2% APY',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE4E1E7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Stake ${asset.symbol} with Lido & Rocket Pool',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.12,
                      color: Color(0xFFC6C8B2),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Material(
            color: const Color(0xFF353439),
            borderRadius: BorderRadius.circular(9999),
            child: InkWell(
              borderRadius: BorderRadius.circular(9999),
              onTap: widget.onStakePressed,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Text(
                  'Stake',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.24,
                    color: Color(0xFFE4E1E7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: Color(0xFFE4E1E7),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4EE6B),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ActivityHistoryScreen(),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.24,
                  color: Color(0xFFD4EE6B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.recentTransactions.map((tx) => _buildTransactionItem(tx)),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionRecord tx) {
    return GestureDetector(
      onTap: () {
        if (tx.isOutbound) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TransactionPendingScreen(
                amount: tx.amount.abs().toStringAsFixed(4),
                tokenSymbol: tx.tokenSymbol,
                amountUsd: tx.amountUsd.toStringAsFixed(2),
                recipient: tx.subtitle.replaceFirst('To ', ''),
              ),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TransactionSuccessScreen(
                amount: tx.amount.abs().toStringAsFixed(4),
                tokenSymbol: tx.tokenSymbol,
                amountUsd: tx.amountUsd.toStringAsFixed(2),
                recipient: tx.subtitle,
              ),
            ),
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(31, 31, 35, 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF353439),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      tx.isInbound
                          ? Icons.arrow_downward_rounded
                          : (tx.isOutbound
                                ? Icons.arrow_outward_rounded
                                : Icons.sync_alt_rounded),
                      size: 16,
                      color: tx.isInbound
                          ? const Color(0xFFD4EE6B)
                          : (tx.isOutbound
                                ? const Color(0xFFFFB4AB)
                                : const Color(0xFFE4E1E7)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.07,
                        color: Color(0xFFE4E1E7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.44,
                        color: Color(0xFFC6C8B2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tx.formattedAmount,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.16,
                    color: tx.isInbound
                        ? const Color(0xFFD4EE6B)
                        : const Color(0xFFE4E1E7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tx.formattedAmountUsd,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.44,
                    color: Color(0xFFC6C8B2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityNote(TokenAsset asset) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(27, 27, 31, 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 16,
                color: Color(0xFFD4EE6B),
              ),
              const SizedBox(width: 8),
              Text(
                'Contract: ${asset.contractAddress.length > 20 ? "${asset.contractAddress.substring(0, 8)}...${asset.contractAddress.substring(asset.contractAddress.length - 6)}" : asset.contractAddress}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.44,
                  color: Color(0xFFC6C8B2),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: asset.contractAddress));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contract address copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text(
              'Copy',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.44,
                color: Color(0xFFD4EE6B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingAiButton(TokenAsset asset) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => context.push(Routes.aiAssistantPath(token: asset.symbol)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(42, 41, 46, 0.9),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: const Color(0xFFD4EE6B).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 12,
                    color: Color(0xFFD4EE6B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ask AI about ${asset.symbol}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.07,
                      color: Color.fromRGBO(255, 255, 255, 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF5B3E8C),
                    Color(0xFF7B4BA6),
                    Color(0xFFC8733A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(228, 255, 122, 0.4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.smart_toy_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circularButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color.fromRGBO(42, 41, 46, 0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(child: Icon(icon, size: 20, color: iconColor)),
        ),
      ),
    );
  }
}
