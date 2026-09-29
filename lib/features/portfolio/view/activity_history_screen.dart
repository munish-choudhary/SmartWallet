import 'dart:ui';

import 'package:flutter/material.dart';

import 'transaction_failed_screen.dart';
import 'transaction_pending_screen.dart';
import 'transaction_success_screen.dart';

/// Screen matching the Figma spec: `/* Activity History */`
/// Displays transaction ledger, total volume metric, horizontal filter chips,
/// and grouped transaction cards with full navigation to Pending, Success, and Failed screens.
class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({
    super.key,
    this.onBackPressed,
  });

  final VoidCallback? onBackPressed;

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  String _activeFilter = 'All';

  static const List<String> _filters = [
    'All',
    'Sends',
    'Receives',
    'Swaps',
    'Approvals',
  ];

  void _handleBack() {
    if (widget.onBackPressed != null) {
      widget.onBackPressed!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _openPendingTx() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TransactionPendingScreen(
          amount: '0.5000',
          tokenSymbol: 'ETH',
          amountUsd: '1,710.25',
          recipient: 'vitalik.eth',
          recipientAddress: '0xd8dA...6045',
          network: 'Ethereum Mainnet',
          estimatedTime: '~45 Seconds',
          gasTier: '28 Gwei',
        ),
      ),
    );
  }

  void _openSuccessTx({
    required String amount,
    required String tokenSymbol,
    required String amountUsd,
    required String recipient,
    String? timestamp,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionSuccessScreen(
          amount: amount,
          tokenSymbol: tokenSymbol,
          amountUsd: amountUsd,
          recipient: recipient,
          timestamp: timestamp ?? 'Sep 24, 2024 · Block #20,819,412',
        ),
      ),
    );
  }

  void _openFailedTx() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TransactionFailedScreen(
          errorReason: 'OUT_OF_GAS',
          errorCode: 'CODE: EVM-0x02',
          errorDescription:
              'The gas limit provided (21,000) was insufficient during block congestion, or the contract execution ran out of computational gas.',
          attemptedAmount: '0.5000',
          tokenSymbol: 'ETH',
          attemptedAmountUsd: '1,710.25',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131317),
      body: Stack(
        children: [
          // Ambient Atmospheric Cosmic Underlay
          // Top right purple aura (#7255A5, blur 60px)
          Positioned(
            top: -48,
            right: -64,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(
                  width: 288,
                  height: 288,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(114, 85, 165, 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          // Mid left lime aura (#D4EE6B, blur 65px)
          Positioned(
            top: 320,
            left: -80,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 65, sigmaY: 65),
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(212, 238, 107, 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // Main Layout
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Header (Height 64px)
                _buildHeader(context),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 12,
                      bottom: 48,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Activity Metric Card
                        _buildMetricCard(),
                        const SizedBox(height: 16),

                        // Filter Chips Carousel
                        _buildFilterCarousel(),
                        const SizedBox(height: 20),

                        // Group: TODAY
                        if (_shouldShowGroup('today')) ...[
                          _buildGroupHeader('TODAY', '3 TXS'),
                          const SizedBox(height: 8),

                          // Item: Sent ETH (Pending)
                          if (_shouldShowItem('sends'))
                            _buildTransactionCard(
                              icon: Icons.north_east_rounded,
                              iconBgColor: const Color.fromRGBO(147, 0, 10, 0.4),
                              iconColor: const Color(0xFFFFB4AB),
                              title: 'Sent ETH',
                              status: 'Pending',
                              statusColor: const Color(0xFFB8D253),
                              statusHasDot: true,
                              subtitle: 'To: vitalik.eth',
                              amountText: '-0.5000 ETH',
                              amountUsdText: '-\$1,710.25',
                              amountUsdColor: const Color(0xFFFFB4AB),
                              detailLeftIcon: Icons.schedule_rounded,
                              detailLeftText: '14:32',
                              detailRightText: 'Ethereum Mainnet',
                              onTap: _openPendingTx,
                            ),
                          const SizedBox(height: 10),

                          // Item: Uniswap v3 Swap (Completed)
                          if (_shouldShowItem('swaps'))
                            _buildTransactionCard(
                              icon: Icons.sync_alt_rounded,
                              iconBgColor: const Color.fromRGBO(212, 238, 107, 0.2),
                              iconColor: const Color(0xFFD4EE6B),
                              title: 'Swap ETH → USDC',
                              status: 'Completed',
                              statusColor: const Color(0xFFD4EE6B),
                              subtitle: 'Uniswap v3',
                              amountText: '+1,705.50 USDC',
                              amountColor: const Color(0xFFD4EE6B),
                              amountUsdText: '-0.5000 ETH',
                              detailLeftIcon: Icons.check_circle_outline_rounded,
                              detailLeftText: '11:15',
                              detailRightText: 'Rate: 1 ETH = 3,411 USDC',
                              onTap: () => _openSuccessTx(
                                amount: '1,705.50',
                                tokenSymbol: 'USDC',
                                amountUsd: '1,705.50',
                                recipient: 'Uniswap v3 Router',
                                timestamp: 'Sep 24, 2024 · 11:15',
                              ),
                            ),
                          const SizedBox(height: 10),

                          // Item: Failed Contract Call (Failed)
                          if (_shouldShowItem('all'))
                            _buildTransactionCard(
                              icon: Icons.priority_high_rounded,
                              iconBgColor: const Color.fromRGBO(147, 0, 10, 0.3),
                              iconColor: const Color(0xFFFFB4AB),
                              title: 'Aave Deposit',
                              status: 'Failed',
                              statusColor: const Color(0xFFFFB4AB),
                              statusBgColor: const Color.fromRGBO(147, 0, 10, 0.6),
                              subtitle: 'Contract Execution Reverted',
                              amountText: '0.0000 ETH',
                              amountColor: const Color(0xFFFFB4AB),
                              amountUsdText: 'Gas: \$4.20',
                              detailLeftIcon: Icons.error_outline_rounded,
                              detailLeftText: '09:40',
                              detailRightText: 'OUT_OF_GAS',
                              detailRightColor: const Color(0xFFFFB4AB),
                              onTap: _openFailedTx,
                            ),
                          const SizedBox(height: 20),
                        ],

                        // Group: YESTERDAY
                        if (_shouldShowGroup('yesterday')) ...[
                          _buildGroupHeader('YESTERDAY', '2 TXS'),
                          const SizedBox(height: 8),

                          // Item: Received ETH
                          if (_shouldShowItem('receives'))
                            _buildTransactionCard(
                              icon: Icons.south_west_rounded,
                              iconBgColor: const Color.fromRGBO(212, 238, 107, 0.2),
                              iconColor: const Color(0xFFD4EE6B),
                              title: 'Received ETH',
                              status: 'Confirmed',
                              statusColor: const Color(0xFFD4EE6B),
                              subtitle: 'From: 0x48a...1b9',
                              amountText: '+2.4000 ETH',
                              amountColor: const Color(0xFFD4EE6B),
                              amountUsdText: '+\$8,208.00',
                              amountUsdColor: const Color.fromRGBO(212, 238, 107, 0.8),
                              detailLeftIcon: Icons.check_circle_outline_rounded,
                              detailLeftText: '18:20',
                              detailRightText: 'Block #20,815,102',
                              onTap: () => _openSuccessTx(
                                amount: '2.4000',
                                tokenSymbol: 'ETH',
                                amountUsd: '8,208.00',
                                recipient: 'Self (0x48a...1b9)',
                                timestamp: 'Sep 23, 2024 · 18:20',
                              ),
                            ),
                          const SizedBox(height: 10),

                          // Item: dApp Approval
                          if (_shouldShowItem('approvals'))
                            _buildTransactionCard(
                              icon: Icons.shield_outlined,
                              iconBgColor: const Color.fromRGBO(236, 220, 255, 0.2),
                              iconColor: const Color(0xFFD5BBFF),
                              title: 'OpenSea',
                              status: 'Active',
                              statusColor: const Color(0xFFD5BBFF),
                              subtitle: 'ERC-20 Token Permit (USDC)',
                              amountText: 'Unlimited',
                              amountUsdText: 'Gas: \$0.85',
                              detailLeftIcon: Icons.key_rounded,
                              detailLeftText: '14:10',
                              detailRightText: 'Revoke Permission',
                              detailRightUnderline: true,
                              detailRightColor: const Color(0xFFD4EE6B),
                              onTap: () => _openSuccessTx(
                                amount: 'Unlimited',
                                tokenSymbol: 'USDC Permit',
                                amountUsd: '0.85',
                                recipient: 'OpenSea Seaport 1.5',
                                timestamp: 'Sep 23, 2024 · 14:10',
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],

                        // Group: SEP 20, 2024
                        if (_shouldShowGroup('older')) ...[
                          _buildGroupHeader('SEP 20, 2024', '1 TX'),
                          const SizedBox(height: 8),

                          // Item: Sent SOL
                          if (_shouldShowItem('sends'))
                            _buildTransactionCard(
                              icon: Icons.north_east_rounded,
                              iconBgColor: const Color(0xFF2A292E),
                              iconColor: const Color(0xFFC6C6C7),
                              title: 'Sent SOL',
                              status: 'Confirmed',
                              statusColor: const Color(0xFFC6C8B2),
                              subtitle: 'To: 8xG...3kW',
                              amountText: '-15.0000 SOL',
                              amountUsdText: '-\$2,223.00',
                              detailLeftIcon: Icons.check_circle_outline_rounded,
                              detailLeftText: '10:05',
                              detailRightText: 'Solana Cluster',
                              onTap: () => _openSuccessTx(
                                amount: '15.0000',
                                tokenSymbol: 'SOL',
                                amountUsd: '2,223.00',
                                recipient: '8xG...3kW',
                                timestamp: 'Sep 20, 2024 · 10:05',
                              ),
                            ),
                        ],
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

  bool _shouldShowGroup(String group) {
    if (_activeFilter == 'All') return true;
    if (_activeFilter == 'Sends') return group == 'today' || group == 'older';
    if (_activeFilter == 'Receives') return group == 'yesterday';
    if (_activeFilter == 'Swaps') return group == 'today';
    if (_activeFilter == 'Approvals') return group == 'yesterday';
    return true;
  }

  bool _shouldShowItem(String type) {
    if (_activeFilter == 'All') return true;
    if (_activeFilter == 'Sends' && type == 'sends') return true;
    if (_activeFilter == 'Receives' && type == 'receives') return true;
    if (_activeFilter == 'Swaps' && type == 'swaps') return true;
    if (_activeFilter == 'Approvals' && type == 'approvals') return true;
    return false;
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
                  GestureDetector(
                    onTap: _handleBack,
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
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACTIVITY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.55,
                          color: Color(0xFFD4EE6B),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Transaction Ledger',
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
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5B3E8C), Color(0xFFD4EE6B)],
                  ),
                  shape: BoxShape.circle,
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

  Widget _buildMetricCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(31, 31, 35, 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.05),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  const Text(
                    'TOTAL VOLUME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: Color(0xFFC6C8B2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                '\$148,920.40',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A292E),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: const Text(
                  '+12.4%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.44,
                    color: Color(0xFFD4EE6B),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Last 30 Days',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFC6C8B2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCarousel() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _activeFilter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _activeFilter = filter;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFD4EE6B)
                    : const Color(0xFF1F1F23),
                borderRadius: BorderRadius.circular(9999),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF181E00)
                      : const Color(0xFFC6C6C7),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupHeader(String title, String countText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.55,
            color: Color(0xFFC6C8B2),
          ),
        ),
        Text(
          countText,
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

  Widget _buildTransactionCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String status,
    required Color statusColor,
    Color? statusBgColor,
    bool statusHasDot = false,
    required String subtitle,
    required String amountText,
    Color amountColor = Colors.white,
    required String amountUsdText,
    Color amountUsdColor = const Color(0xFFC6C8B2),
    required IconData detailLeftIcon,
    required String detailLeftText,
    required String detailRightText,
    Color detailRightColor = const Color(0xFFC6C8B2),
    bool detailRightUnderline = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(31, 31, 35, 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color.fromRGBO(255, 255, 255, 0.04),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Row
            Row(
              children: [
                // Icon Emblem
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                ),
                const SizedBox(width: 14),

                // Title + Status Pill + Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusBgColor ?? const Color(0xFF2A292E),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (statusHasDot) ...[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFC6C8B2),
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amountText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      amountUsdText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: amountUsdColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bottom Detail Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(detailLeftIcon, size: 12, color: const Color(0xFFC6C8B2)),
                    const SizedBox(width: 4),
                    Text(
                      detailLeftText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.44,
                        color: Color(0xFFC6C8B2),
                      ),
                    ),
                  ],
                ),
                Text(
                  detailRightText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.44,
                    color: detailRightColor,
                    decoration: detailRightUnderline
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
