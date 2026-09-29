import 'dart:ui';

import 'package:flutter/material.dart';

import 'transaction_pending_screen.dart';

/// Screen matching the Figma spec: `/* Transaction Failed */`
class TransactionFailedScreen extends StatelessWidget {
  const TransactionFailedScreen({
    super.key,
    this.errorReason = 'OUT_OF_GAS',
    this.errorCode = 'CODE: EVM-0x02',
    this.errorDescription =
        'The gas limit provided (21,000) was insufficient during block congestion, or the contract execution ran out of computational gas.',
    this.attemptedAmount = '1.2500',
    this.tokenSymbol = 'ETH',
    this.attemptedAmountUsd = '4,275.62',
    this.blockNumber = '#20,819,412',
    this.onRetry,
    this.onDismiss,
  });

  final String errorReason;
  final String errorCode;
  final String errorDescription;
  final String attemptedAmount;
  final String tokenSymbol;
  final String attemptedAmountUsd;
  final String blockNumber;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  void _handleDismiss(BuildContext context) {
    if (onDismiss != null) {
      onDismiss!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleRetry(BuildContext context) {
    if (onRetry != null) {
      onRetry!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => TransactionPendingScreen(
            amount: attemptedAmount,
            tokenSymbol: tokenSymbol,
            amountUsd: attemptedAmountUsd,
            gasTier: '36 Gwei',
            gasTierLabel: 'BOOSTED',
          ),
        ),
      );
    }
  }

  void _showTechnicalTrace(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F1F23),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF353439),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'EVM Execution Trace',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF131317),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'opcode: 0xFD (REVERT)\ngas_used: 21000\ngas_limit: 21000\ncall_data: 0xa9059cbb...\nreturn_data: 0x4e487b710000000000000000000000000000000000000000000000000000000000000011',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 11,
                    color: Color(0xFFC6C8B2),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF353439),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close Trace'),
                ),
              ),
            ],
          ),
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
          // Moody Ambient Radial Aura (Soft Crimson Glow: rgba(147, 0, 10, 0.3))
          Positioned(
            top: -40,
            left: MediaQuery.of(context).size.width / 2 - 160,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(147, 0, 10, 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // Secondary Soft Crimson Blur (rgba(255, 180, 171, 0.1))
          Positioned(
            top: 192,
            left: MediaQuery.of(context).size.width / 2 - 128,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  width: 256,
                  height: 256,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(255, 180, 171, 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // Main Scrollable Area
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Navigation & Status Section
                  _buildTopNav(context),
                  const SizedBox(height: 24),

                  // Central Visual Identity (Emblem + Revert Heading)
                  _buildVisualIdentity(),
                  const SizedBox(height: 24),

                  // Diagnostic / Error Reason Card
                  _buildDiagnosticCard(context),
                  const SizedBox(height: 24),

                  // Interactive Action Buttons (Primary Retry & Secondary Dismiss)
                  _buildActionButtons(context),
                  const SizedBox(height: 16),

                  // Auxiliary Diagnostic Trigger Drawer
                  _buildDiagnosticTrigger(context),
                  const SizedBox(height: 32),

                  // Footer Support Link
                  _buildFooterSupport(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNav(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Dismiss screen button (X)
        GestureDetector(
          onTap: () => _handleDismiss(context),
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
                Icons.close_rounded,
                size: 20,
                color: Color(0xFFE4E1E7),
              ),
            ),
          ),
        ),

        // Status Pill: TRANSACTION REVERTED
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(42, 41, 46, 0.9),
            borderRadius: BorderRadius.circular(9999),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.05),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Crimson Dot
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB4AB).withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFB4AB),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Text(
                'TRANSACTION REVERTED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.55,
                  color: Color(0xFFFFB4AB),
                ),
              ),
            ],
          ),
        ),

        // Network Indicator / Block Context
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color.fromRGBO(42, 41, 46, 0.8),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'EVM',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFC6C6C7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualIdentity() {
    return Column(
      children: [
        // 80px Failure Emblem with Layered Neon Glow
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Crimson Blur
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 180, 171, 0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB4AB).withValues(alpha: 0.2),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
              // Frosted Background Circle
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(14, 14, 18, 0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.25),
                      blurRadius: 25,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
              ),
              // Inner Core in Soft Crimson
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(147, 0, 10, 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.priority_high_rounded,
                    size: 30,
                    color: Color(0xFFFFB4AB),
                  ),
                ),
              ),
              // Orbiting Alert Particle
              Positioned(
                right: 8,
                top: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFB4AB),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFFB4AB),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Title & Subtitle
        const Text(
          'Execution Reverted',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            color: Color(0xFFFFFFFF),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'The network rejected this transaction before state finality.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFFC6C6C7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosticCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(27, 27, 31, 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromRGBO(255, 180, 171, 0.15),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.15),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error Reason Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: Color(0xFFFFB4AB),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ERROR REASON',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.24,
                          color: Color(0xFFFFB4AB),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        errorReason,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.16,
                          color: Color(0xFFE4E1E7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF353439),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  errorCode,
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
          const SizedBox(height: 14),

          // Error Description Narrative
          Text(
            errorDescription,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.5,
              letterSpacing: 0.12,
              color: Color(0xFFB4B5B5),
            ),
          ),
          const SizedBox(height: 16),

          // Attempted Transaction Snapshot Mini-Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(31, 31, 35, 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ATTEMPTED TX',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.55,
                        color: Color(0xFFC6C6C7),
                      ),
                    ),
                    Text(
                      'BLOCK $blockNumber',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.44,
                        color: Color(0xFFB4B5B5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFF353439),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.diamond_outlined,
                              size: 14,
                              color: Color(0xFF627EEA),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$attemptedAmount $tokenSymbol',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(53, 52, 57, 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '≈ \$$attemptedAmountUsd',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Safe Funds Assurance Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(42, 41, 46, 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD4EE6B).withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_rounded,
                  size: 16,
                  color: Color(0xFFD4EE6B),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Funds are safe. No asset balances were deducted other than the base network gas fee.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      letterSpacing: 0.12,
                      color: Color(0xFFD4EE6B),
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

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Primary Pill CTA: TRY AGAIN WITH BOOSTED GAS
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => _handleRetry(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFFFFF),
              foregroundColor: const Color(0xFF0E0E12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TRY AGAIN WITH BOOSTED GAS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.bolt_rounded,
                  size: 16,
                  color: Color(0xFF0E0E12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary Text/Ghost Action: DISMISS & RETURN
        SizedBox(
          width: double.infinity,
          height: 44,
          child: TextButton(
            onPressed: () => _handleDismiss(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC6C6C7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            child: const Text(
              'DISMISS & RETURN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosticTrigger(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTechnicalTrace(context),
      behavior: HitTestBehavior.opaque,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'View Technical Trace',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.44,
              color: Color(0xFFC6C8B2),
            ),
          ),
          SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 14,
            color: Color(0xFFC6C8B2),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSupport(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connecting to 24/7 Lexor Concierge...')),
        );
      },
      child: const Text(
        'Need help? Contact 24/7 Lexor Concierge',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.12,
          color: Color(0xFFC6C6C7),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
