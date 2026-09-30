import 'package:flutter/material.dart';

import 'settings_palette.dart';

/// Generative identicon for a wallet: a mirrored 5×5 block pattern derived
/// from [seed] (the address), so the same wallet always gets the same face.
/// Purely cosmetic — not used for anything security-relevant.
class WalletAvatar extends StatelessWidget {
  const WalletAvatar({
    super.key,
    required this.seed,
    this.onEdit,
    this.size = 64,
  });

  final String seed;

  /// Shows the small "edit" button at the bottom-right when set.
  final VoidCallback? onEdit;

  /// Outer diameter; 64 on the identity card, smaller in lists.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  SettingsPalette.keyPanel,
                  SettingsPalette.card,
                  Color(0xFF39393D),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(212, 238, 107, 0.2),
                  blurRadius: 24,
                ),
              ],
            ),
            child: ClipOval(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _IdenticonPainter(seed),
                  size: Size.square(size - 8),
                ),
              ),
            ),
          ),
          if (onEdit != null)
            // 24px visual button inside a 40px hit area.
            Positioned(
              right: -12,
              bottom: -12,
              child: Semantics(
                button: true,
                label: 'Rename wallet',
                child: InkResponse(
                  onTap: onEdit,
                  radius: 20,
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SettingsPalette.accent,
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.1),
                              blurRadius: 15,
                              spreadRadius: -3,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Icon(
                            Icons.edit_rounded,
                            size: 12,
                            color: Color(0xFF181E00),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IdenticonPainter extends CustomPainter {
  _IdenticonPainter(this.seed);

  final String seed;

  /// FNV-1a: stable across runs and platforms (unlike `String.hashCode`).
  static int _hash(String s) {
    var h = 0x811c9dc5;
    for (final unit in s.codeUnits) {
      h = ((h ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return h;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = SettingsPalette.cardMuted,
    );

    final hash = _hash(seed);
    const grid = 5;
    final cell = size.width * 0.6 / grid;
    final origin = (size.width - cell * grid) / 2;
    final paint = Paint()
      ..color = SettingsPalette.accent.withValues(alpha: 0.8);

    // 3 columns of bits, mirrored onto the other 2 to make a face-like shape.
    for (var row = 0; row < grid; row++) {
      for (var col = 0; col < 3; col++) {
        if ((hash >> (row * 3 + col)) & 1 == 0) continue;
        for (final c in {col, grid - 1 - col}) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(origin + c * cell, origin + row * cell, cell, cell)
                  .deflate(1),
              const Radius.circular(2),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_IdenticonPainter old) => old.seed != seed;
}
