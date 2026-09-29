import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/token_asset.dart';

/// Modal bottom sheet displaying a high-tech QR code, public address,
/// and safety warnings for receiving a selected cryptocurrency.
class ReceiveQrSheet extends StatefulWidget {
  const ReceiveQrSheet({
    super.key,
    required this.token,
    this.customAddress,
  });

  final TokenAsset token;
  final String? customAddress;

  @override
  State<ReceiveQrSheet> createState() => _ReceiveQrSheetState();
}

class _ReceiveQrSheetState extends State<ReceiveQrSheet> {
  bool _isCopied = false;
  Timer? _copyTimer;

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  String get _depositAddress {
    if (widget.customAddress != null) return widget.customAddress!;
    switch (widget.token.symbol.toUpperCase()) {
      case 'SOL':
        return '8xG3kW9VzQ72LpNaBC56mPqRsTuVwXyZ1234';
      case 'BTC':
        return 'bc1q9d8da6045a498b21c4b97a3f8c2b91044e9b21';
      default:
        return '0x48a1B92fD498A4c7b8C2a19F90a068471c261b9';
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _depositAddress));
    setState(() {
      _isCopied = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.token.symbol} address copied to clipboard',
          style: const TextStyle(color: Color(0xFF0E0E12), fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFD4EE6B),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final address = _depositAddress;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F23),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.6),
            blurRadius: 30,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
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
              const SizedBox(height: 20),

              // Token Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Color(widget.token.iconBgColor).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.token.symbol.substring(0, 1),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(widget.token.iconBgColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Receive ${widget.token.name}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                              color: Colors.white,
                            ),
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
                                '${widget.token.network} Network',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFC6C8B2),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: Color(0xFFC6C6C7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // QR Code Graphic Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF131317),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color.fromRGBO(255, 255, 255, 0.06),
                  ),
                ),
                child: Column(
                  children: [
                    CustomPaint(
                      size: const Size(180, 180),
                      painter: _CryptoQrPainter(
                        data: address,
                        accentColor: const Color(0xFFD4EE6B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Scan to deposit directly to this wallet',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Address Box Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(42, 41, 46, 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color.fromRGBO(255, 255, 255, 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YOUR DEPOSIT ADDRESS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: Color(0xFFC6C8B2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            address,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Courier',
                              letterSpacing: -0.2,
                              color: Color(0xFFE4E1E7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _copyToClipboard,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isCopied
                              ? const Color(0xFFD4EE6B)
                              : const Color(0xFF353439),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isCopied ? Icons.check_rounded : Icons.copy_rounded,
                              size: 14,
                              color: _isCopied ? const Color(0xFF0E0E12) : Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isCopied ? 'Copied' : 'Copy',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _isCopied ? const Color(0xFF0E0E12) : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Safety Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(42, 41, 46, 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color.fromRGBO(212, 238, 107, 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: Color(0xFFD4EE6B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Send only ${widget.token.name} (${widget.token.symbol}) via ${widget.token.network} to this address. Sending other assets will cause permanent loss.',
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFC6C8B2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons: Share & Done
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _copyToClipboard();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE4E1E7),
                        side: const BorderSide(color: Color(0xFF353439)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share_outlined, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Share Address',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFFFF),
                        foregroundColor: const Color(0xFF0E0E12),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for crisp Web3 QR matrix representation with center emblem
class _CryptoQrPainter extends CustomPainter {
  const _CryptoQrPainter({
    required this.data,
    required this.accentColor,
  });

  final String data;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final matrixPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final darkBgPaint = Paint()
      ..color = const Color(0xFF131317)
      ..style = PaintingStyle.fill;

    const gridSize = 21;
    final cellSize = size.width / gridSize;

    // Draw finder pattern at given grid coordinates (row, col)
    void drawFinderPattern(int startRow, int startCol) {
      final rect = Rect.fromLTWH(
        startCol * cellSize,
        startRow * cellSize,
        7 * cellSize,
        7 * cellSize,
      );
      // Outer 7x7 dark box with rounded corner
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cellSize * 1.5)),
        matrixPaint,
      );
      // Inner 5x5 cutout
      final innerCutout = Rect.fromLTWH(
        (startCol + 1) * cellSize,
        (startRow + 1) * cellSize,
        5 * cellSize,
        5 * cellSize,
      );
      canvas.drawRect(innerCutout, darkBgPaint);
      // Center 3x3 solid block in accent color
      final centerBlock = Rect.fromLTWH(
        (startCol + 2) * cellSize,
        (startRow + 2) * cellSize,
        3 * cellSize,
        3 * cellSize,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(centerBlock, Radius.circular(cellSize * 0.8)),
        accentPaint,
      );
    }

    drawFinderPattern(0, 0); // Top-Left
    drawFinderPattern(0, gridSize - 7); // Top-Right
    drawFinderPattern(gridSize - 7, 0); // Bottom-Left

    // Draw pseudo-random reproducible QR data modules
    final hash = data.hashCode.abs();
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        // Skip finder pattern zones
        final inTopLeft = r < 8 && c < 8;
        final inTopRight = r < 8 && c >= gridSize - 8;
        final inBottomLeft = r >= gridSize - 8 && c < 8;
        final inCenter = r >= 8 && r <= 12 && c >= 8 && c <= 12;

        if (inTopLeft || inTopRight || inBottomLeft || inCenter) continue;

        // Deterministic dot placement
        final val = ((r * 31 + c * 17 + hash) ^ (r + c)) % 100;
        if (val < 45) {
          final isAccent = val < 8;
          final cellRect = Rect.fromLTWH(
            c * cellSize + 0.6,
            r * cellSize + 0.6,
            cellSize - 1.2,
            cellSize - 1.2,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(cellRect, Radius.circular(cellSize * 0.3)),
            isAccent ? accentPaint : matrixPaint,
          );
        }
      }
    }

    // Center Logo Housing
    final centerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cellSize * 5,
      height: cellSize * 5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect, Radius.circular(cellSize * 1.5)),
      darkBgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect, Radius.circular(cellSize * 1.5)),
      Paint()
        ..color = accentColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Mini center shield glyph
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = cellSize * 1.2;
    path.moveTo(cx, cy - r);
    path.lineTo(cx + r, cy - r * 0.4);
    path.lineTo(cx + r * 0.6, cy + r * 0.7);
    path.lineTo(cx, cy + r);
    path.lineTo(cx - r * 0.6, cy + r * 0.7);
    path.lineTo(cx - r, cy - r * 0.4);
    path.close();
    canvas.drawPath(path, accentPaint);
  }

  @override
  bool shouldRepaint(covariant _CryptoQrPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.accentColor != accentColor;
}
