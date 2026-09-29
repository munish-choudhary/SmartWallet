import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Screen matching the Figma spec: `/* Transaction Success */`
class TransactionSuccessScreen extends StatefulWidget {
  const TransactionSuccessScreen({
    super.key,
    this.amount = '1.2500',
    this.tokenSymbol = 'ETH',
    this.amountUsd = '4,275.62',
    this.recipient = 'vitalik.eth',
    this.networkFee = '0.00042 ETH',
    this.networkFeeUsd = '1.44',
    this.timestamp = 'Sep 24, 2024 · Block #20,819,412',
    this.txHash = '0x7a3f...9b21',
    this.fullTxHash = '0x7a3f8c2b9104f2d8a36c1e9b0ce3606eb481234567890abcdef4e9b21',
    this.onDone,
    this.onViewExplorer,
  });

  final String amount;
  final String tokenSymbol;
  final String amountUsd;
  final String recipient;
  final String networkFee;
  final String networkFeeUsd;
  final String timestamp;
  final String txHash;
  final String fullTxHash;
  final VoidCallback? onDone;
  final VoidCallback? onViewExplorer;

  @override
  State<TransactionSuccessScreen> createState() => _TransactionSuccessScreenState();
}

class _TransactionSuccessScreenState extends State<TransactionSuccessScreen> {
  bool _copied = false;
  Timer? _copyTimer;

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  void _copyTxHash() {
    Clipboard.setData(ClipboardData(text: widget.fullTxHash));
    setState(() {
      _copied = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Transaction hash copied to clipboard',
          style: TextStyle(color: Color(0xFF0E0E12), fontWeight: FontWeight.w700),
        ),
        backgroundColor: Color(0xFFD4EE6B),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _handleDone() {
    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      // Pop to root portfolio
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _handleExplorer() {
    if (widget.onViewExplorer != null) {
      widget.onViewExplorer!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening Etherscan for ${widget.txHash}...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131317),
      body: Stack(
        children: [
          // Ambient Luminous Glow Underlay (rgba(212, 238, 107, 0.15), blur 50px)
          Positioned(
            top: -64,
            left: MediaQuery.of(context).size.width / 2 - 160,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(212, 238, 107, 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // Secondary Soft Lavender Blur (rgba(236, 220, 255, 0.1), blur 60px)
          Positioned(
            top: 192,
            right: -80,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(
                  width: 256,
                  height: 256,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(236, 220, 255, 0.1),
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
                  const SizedBox(height: 8),

                  // Security Verification Pill Badge
                  _buildSecurityBadge(),
                  const SizedBox(height: 20),

                  // Central Hero Celebration Cluster
                  _buildCelebrationCluster(),
                  const SizedBox(height: 28),

                  // Summary Glass Card
                  _buildSummaryCard(),
                  const SizedBox(height: 16),

                  // Interactive Tx Hash Chip
                  _buildTxHashChip(),
                  const SizedBox(height: 32),

                  // Bottom Actions (View on Explorer + Primary Done Button)
                  _buildBottomActions(),
                  const SizedBox(height: 24),

                  // Vault Settlement Assurance Footer
                  _buildAssuranceFooter(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(42, 41, 46, 0.7),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.05),
        ),
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
          // Glowing Neon Dot
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4EE6B).withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
              ),
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
          const SizedBox(width: 8),
          const Text(
            'VERIFIED SETTLEMENT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.55,
              color: Color(0xFFE4E1E7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationCluster() {
    return Column(
      children: [
        // Concentric Halos & Center Neon Checkmark Badge
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Soft Halo
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(212, 238, 107, 0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4EE6B).withValues(alpha: 0.15),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
              // Inner Ring Accent
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(212, 238, 107, 0.2),
                  shape: BoxShape.circle,
                ),
              ),
              // Center Neon Checkmark Circle (80x80)
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4EE6B),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(212, 238, 107, 0.3),
                      blurRadius: 25,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: 42,
                    color: Color(0xFF596C00),
                  ),
                ),
              ),
              // Micro Sparkle Badge (Top Right)
              Positioned(
                right: 4,
                top: 4,
                child: Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: const Color(0xFFD4EE6B).withValues(alpha: 0.9),
                ),
              ),
              // Micro Sparkle Badge (Bottom Left)
              Positioned(
                left: 6,
                bottom: 6,
                child: Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: const Color(0xFFD4EE6B).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Hero Typography
        const Text(
          'Transfer Complete',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: Color(0xFFFFFFFF),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Your transaction has been securely confirmed on-chain.',
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

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(31, 31, 35, 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.05),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 15,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Amount Cluster
          const Text(
            'TOTAL SENT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Color(0xFFC6C6C7),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                widget.amount,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.tokenSymbol,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: Color(0xFFD4EE6B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '≈ \$${widget.amountUsd}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.26,
              color: Color(0xFFC6C6C7),
            ),
          ),
          const SizedBox(height: 20),

          // Data Rows Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(27, 27, 31, 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Recipient Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RECIPIENT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFC6C6C7),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Color(0xFF353439),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: Color(0xFFD4EE6B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.recipient,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.26,
                            color: Color(0xFFE4E1E7),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: Color(0xFFD4EE6B),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Network Fee Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NETWORK FEE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFC6C6C7),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          widget.networkFee,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.26,
                            color: Color(0xFFE4E1E7),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(\$${widget.networkFeeUsd})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFC6C6C7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Timestamp & Block Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TIMESTAMP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFC6C6C7),
                      ),
                    ),
                    Text(
                      widget.timestamp,
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
        ],
      ),
    );
  }

  Widget _buildTxHashChip() {
    return GestureDetector(
      onTap: _copyTxHash,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(42, 41, 46, 0.6),
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: const Color.fromRGBO(255, 255, 255, 0.05),
          ),
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
            const Icon(
              Icons.tag_rounded,
              size: 16,
              color: Color(0xFFC6C6C7),
            ),
            const SizedBox(width: 8),
            Text(
              widget.txHash,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.44,
                color: Color(0xFFE4E1E7),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _copied ? const Color(0xFFD4EE6B) : const Color(0xFF353439),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  _copied ? Icons.check_rounded : Icons.copy_rounded,
                  size: 12,
                  color: _copied ? const Color(0xFF0E0E12) : const Color(0xFFE4E1E7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        // View on Explorer Link
        GestureDetector(
          onTap: _handleExplorer,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(42, 41, 46, 0.7),
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(
                color: const Color.fromRGBO(255, 255, 255, 0.05),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View on Explorer',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.24,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 14,
                  color: Color(0xFFD4EE6B),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Primary CTA: Done Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _handleDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFFFFF),
              foregroundColor: const Color(0xFF0E0E12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: Color(0xFF0E0E12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssuranceFooter() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shield_rounded,
          size: 14,
          color: Color(0xFFD4EE6B),
        ),
        SizedBox(width: 8),
        Text(
          'SECURED BY LEXOR VAULT & MPC',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.44,
            color: Color(0xFFC6C8B2),
          ),
        ),
      ],
    );
  }
}
