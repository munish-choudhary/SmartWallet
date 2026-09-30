import 'package:flutter/material.dart';

import 'settings_palette.dart';

/// Small-caps label above a [GlassGroupCard] ("VAULT CREDENTIALS & SECURITY").
class GlassSectionLabel extends StatelessWidget {
  const GlassSectionLabel(
    this.text, {
    super.key,
    this.color = SettingsPalette.textSecondary,
    this.icon,
  });

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              text.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 16 / 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded translucent surface holding [GlassRowTile]s separated by hairline
/// dividers. Static alpha fill rather than live blur, per CLAUDE.md.
class GlassGroupCard extends StatelessWidget {
  const GlassGroupCard({super.key, required this.children});

  final List<Widget> children;

  static const _divider = ColoredBox(
    color: Color.fromRGBO(42, 41, 46, 0.5),
    child: SizedBox(height: 1, width: double.infinity),
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 15,
            spreadRadius: -3,
            offset: Offset(0, 10),
          ),
        ],
      ),
      // The Material is the surface (not a Container fill) so row ink
      // splashes paint above the background instead of under it.
      child: Material(
        color: SettingsPalette.glassCardSoft,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) _divider,
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// One 72px row: icon tile, title (+ optional [badge]), subtitle, [trailing].
/// Pass a null [onTap] for a row that isn't itself tappable.
class GlassRowTile extends StatelessWidget {
  const GlassRowTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor = SettingsPalette.iconMuted,
    this.monoSubtitle = false,
    this.badge,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  /// Smaller, heavier, letter-spaced subtitle for paths and URLs.
  final bool monoSubtitle;
  final Widget? badge;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SettingsPalette.cardAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SettingsPalette.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        badge!,
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SettingsPalette.textSecondary,
                      fontSize: monoSubtitle ? 11 : 12,
                      fontWeight:
                          monoSubtitle ? FontWeight.w600 : FontWeight.w400,
                      height: monoSubtitle ? 14 / 11 : 16 / 12,
                      letterSpacing: monoSubtitle ? 0.44 : 0.12,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Small rounded tag next to a row title ("DANGER", "3 Active").
class GlassBadge extends StatelessWidget {
  const GlassBadge(
    this.text, {
    super.key,
    required this.background,
    required this.foreground,
    this.radius = 4,
  });

  final String text;
  final Color background;
  final Color foreground;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          height: 2,
          letterSpacing: 0.07,
        ),
      ),
    );
  }
}

class GlassChevron extends StatelessWidget {
  const GlassChevron({super.key});

  @override
  Widget build(BuildContext context) => const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: SettingsPalette.textSecondary,
      );
}
