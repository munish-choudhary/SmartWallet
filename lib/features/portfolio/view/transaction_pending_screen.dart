import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'transaction_success_screen.dart';

/// Screen matching the Figma spec: `/* Transaction Pending */`
/// Displays animated concentric orbital rings, live block confirmation counters,
/// transfer details, and transitions smoothly to `TransactionSuccessScreen`.
class TransactionPendingScreen extends StatefulWidget {
  const TransactionPendingScreen({
    super.key,
    this.amount = '1.2500',
    this.tokenSymbol = 'ETH',
    this.amountUsd = '4,275.62',
    this.recipient = 'vitalik.eth',
    this.recipientAddress = '0xd8dA...6045',
    this.network = 'Ethereum Mainnet',
    this.networkTag = 'L1',
    this.estimatedTime = '~30 Seconds',
    this.gasTier = '24 Gwei',
    this.gasTierLabel = 'FAST',
    this.autoCompleteSeconds = 4,
    this.onClose,
  });

  final String amount;
  final String tokenSymbol;
  final String amountUsd;
  final String recipient;
  final String recipientAddress;
  final String network;
  final String networkTag;
  final String estimatedTime;
  final String gasTier;
  final String gasTierLabel;
  final int autoCompleteSeconds;
  final VoidCallback? onClose;

  @override
  State<TransactionPendingScreen> createState() => _TransactionPendingScreenState();
}

class _TransactionPendingScreenState extends State<TransactionPendingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  Timer? _autoTransitionTimer;
  Timer? _blockStageTimer;
  int _currentBlockStage = 2;
  static const int _totalBlockStages = 12;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Increment confirmation stage every second for realistic animation
    _blockStageTimer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_currentBlockStage < _totalBlockStages) {
        setState(() {
          _currentBlockStage++;
        });
      } else {
        t.cancel();
      }
    });

    // Auto-proceed to TransactionSuccessScreen after specified duration
    if (widget.autoCompleteSeconds > 0) {
      _autoTransitionTimer = Timer(Duration(seconds: widget.autoCompleteSeconds), () {
        if (!mounted) return;
        _navigateToSuccess();
      });
    }
  }

  @override
  void dispose() {
    _blockStageTimer?.cancel();
    _autoTransitionTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _navigateToSuccess() {
    _blockStageTimer?.cancel();
    _autoTransitionTimer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => TransactionSuccessScreen(
          amount: widget.amount,
          tokenSymbol: widget.tokenSymbol,
          amountUsd: widget.amountUsd,
          recipient: widget.recipient,
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
          // Ambient Atmospheric Aura Orbs
          // Top right aura
          Positioned(
            top: -64,
            right: -80,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
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
          // Bottom right aura
          Positioned(
            bottom: 48,
            right: 0,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  width: 256,
                  height: 256,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(212, 238, 107, 0.1),
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

                  // Top Status Badge: TRANSACTION IN FLIGHT
                  _buildTopStatusBadge(),
                  const SizedBox(height: 24),

                  // Central Concentric Orbital Loader Graphic (Animated)
                  _buildOrbitalLoader(),
                  const SizedBox(height: 20),

                  // Header Headline Section
                  _buildHeadline(),
                  const SizedBox(height: 24),

                  // Transfer Details Card (Glassmorphic)
                  _buildTransferDetailsCard(),
                  const SizedBox(height: 20),

                  // Interactive Explorer Link
                  _buildExplorerLink(),
                  const SizedBox(height: 24),

                  // Bottom Fixed Actions: Primary Pill CTA & Security Footer
                  _buildBottomActions(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStatusBadge() {
    return Container(
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
            'TRANSACTION IN FLIGHT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.55,
              color: Color(0xFFC6C8B2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbitalLoader() {
    return Column(
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring glow underlay
                  Container(
                    width: 176,
                    height: 176,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4EE6B).withValues(alpha: 0.12),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),

                  // Outer Dashed Rotating Ring (176px)
                  Transform.rotate(
                    angle: _animController.value * 2 * math.pi,
                    child: const CustomPaint(
                      size: Size(176, 176),
                      painter: _DashedCirclePainter(
                        color: Color(0xFF353439),
                        dashWidth: 4,
                        dashSpace: 4,
                        strokeWidth: 1.5,
                      ),
                    ),
                  ),

                  // Orbiting Accent Dot on Outer Ring
                  Transform.rotate(
                    angle: _animController.value * 2 * math.pi,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD4EE6B),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFD4EE6B),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Middle Counter-Rotating Ring (144px)
                  Transform.rotate(
                    angle: -_animController.value * 2 * math.pi,
                    child: const CustomPaint(
                      size: Size(144, 144),
                      painter: _ArcRingPainter(
                        baseColor: Color(0xFF353439),
                        accentColor: Color(0xFFD4EE6B),
                        strokeWidth: 2.2,
                      ),
                    ),
                  ),

                  // Inner High-Speed Ring (112px)
                  Transform.rotate(
                    angle: _animController.value * 4 * math.pi,
                    child: CustomPaint(
                      size: const Size(112, 112),
                      painter: _DashedCirclePainter(
                        color: const Color(0xFFC6C8B2).withValues(alpha: 0.35),
                        dashWidth: 3,
                        dashSpace: 3,
                        strokeWidth: 1.2,
                      ),
                    ),
                  ),

                  // Core Glass Hex/Orb Housing (48x48)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(42, 41, 46, 0.85),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.2),
                          blurRadius: 15,
                          offset: Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFD4EE6B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color.fromRGBO(14, 14, 18, 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sync_rounded,
                          size: 20,
                          color: Color(0xFFD4EE6B),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Live Stage Counter Badge: CONFIRMING BLOCK 2/12
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B1F),
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CONFIRMING BLOCK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.44,
                  color: Color(0xFFC6C8B2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$_currentBlockStage/$_totalBlockStages',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.44,
                  color: Color(0xFFD4EE6B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeadline() {
    return const Column(
      children: [
        Text(
          'Transaction Submitted',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: Color(0xFFFFFFFF),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Broadcasting to the network. Funds are securely in transit.',
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

  Widget _buildTransferDetailsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(31, 31, 35, 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.05),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.15),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Top Highlight Sheen
            Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color.fromRGBO(255, 255, 255, 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Primary Outgoing Block
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SENDING',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.24,
                              color: Color(0xFFC6C6C7),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.amount} ${widget.tokenSymbol}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '≈ \$${widget.amountUsd}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                              color: Color(0xFFC6C8B2),
                            ),
                          ),
                        ],
                      ),
                      // Token Emblem
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF353439),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.diamond_outlined,
                            size: 22,
                            color: Color(0xFF627EEA),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Divider
                  Container(
                    height: 1,
                    color: const Color.fromRGBO(53, 52, 57, 0.6),
                  ),
                  const SizedBox(height: 12),

                  // Detail Rows
                  // Recipient Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.24,
                          color: Color(0xFFC6C6C7),
                        ),
                      ),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: Color(0xFF353439),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person,
                                  size: 12,
                                  color: Color(0xFFD4EE6B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                widget.recipient,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.26,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${widget.recipientAddress})',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                                color: Color(0xFFC6C6C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Network Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'NETWORK',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.24,
                          color: Color(0xFFC6C6C7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                            Flexible(
                              child: Text(
                                widget.network,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.26,
                                  color: Color(0xFFE4E1E7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF353439),
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                              ),
                              child: Text(
                                widget.networkTag,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFC6C8B2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Estimated Time Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ESTIMATED TIME',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.24,
                          color: Color(0xFFC6C6C7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: Color(0xFFD4EE6B),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.estimatedTime,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Gas Tier Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'NETWORK GAS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.24,
                          color: Color(0xFFC6C6C7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.gasTier,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFE4E1E7),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2A292E),
                                borderRadius: BorderRadius.all(Radius.circular(9999)),
                              ),
                              child: Text(
                                widget.gasTierLabel,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFC6C8B2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplorerLink() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viewing transaction in mempool explorer...')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(27, 27, 31, 0.6),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View on Explorer',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.24,
                color: Color(0xFFE4E1E7),
              ),
            ),
            SizedBox(width: 6),
            Icon(
              Icons.arrow_outward_rounded,
              size: 12,
              color: Color(0xFFD4EE6B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        // Primary High-Contrast Pill CTA: Speed Up
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _navigateToSuccess,
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
                  'Speed Up',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.16,
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

        // Discreet Shield Security Footer
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 12,
              color: Color(0xFFD4EE6B),
            ),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'End-to-end cryptographic integrity monitored by Lexor Sentinel',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                  color: Color(0xFFC6C6C7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Helper custom painter for animated dashed ring
class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
    required this.strokeWidth,
  });

  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();
    final adjustedDashAngle = (2 * math.pi) / dashCount;
    final dashPortionAngle = adjustedDashAngle * (dashWidth / (dashWidth + dashSpace));

    for (var i = 0; i < dashCount; i++) {
      final startAngle = i * adjustedDashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius - strokeWidth),
        startAngle,
        dashPortionAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) => false;
}

/// Helper painter for middle counter-rotating ring with neon arc
class _ArcRingPainter extends CustomPainter {
  const _ArcRingPainter({
    required this.baseColor,
    required this.accentColor,
    required this.strokeWidth,
  });

  final Color baseColor;
  final Color accentColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    final basePaint = Paint()
      ..color = baseColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final accentPaint = Paint()
      ..color = accentColor
      ..strokeWidth = strokeWidth + 0.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, basePaint);

    // Accent Arc (~90 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi / 2,
      false,
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcRingPainter oldDelegate) => false;
}
