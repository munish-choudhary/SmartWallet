import 'package:flutter/material.dart';

/// A dApp's logo: its remote icon when available, otherwise a brand-color
/// gradient with the app's initial. dApp metadata is untrusted input — a
/// broken/slow/hostile icon URL must never break the layout, so every
/// failure path falls back to the gradient.
class DappIcon extends StatelessWidget {
  const DappIcon({
    super.key,
    required this.name,
    required this.brandColor,
    this.iconUrl,
    this.size = 48,
    this.glow = false,
  });

  final String name;
  final int brandColor;
  final String? iconUrl;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final base = Color(brandColor);
    final hsl = HSLColor.fromColor(base);
    final light = hsl
        .withLightness((hsl.lightness + 0.2).clamp(0.0, 0.85))
        .toColor();
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [base, light],
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: base.withValues(alpha: 0.35),
                  blurRadius: size * 0.36,
                ),
              ]
            : null,
      ),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );

    final url = iconUrl;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) {
      return fallback;
    }
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          url!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : fallback,
        ),
      ),
    );
  }
}
