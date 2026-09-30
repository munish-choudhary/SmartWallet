import 'package:flutter/material.dart';

import 'lexor_palette.dart';

/// Static translucent glass card (no live blur — safe inside lists).
class LexorCard extends StatelessWidget {
  const LexorCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 12,
    this.onTap,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: borderColor == null
          ? BorderSide.none
          : BorderSide(color: borderColor!),
    );
    return Material(
      color: color ?? LexorPalette.card,
      shape: shape,
      elevation: 0,
      shadowColor: Colors.black,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Uppercase section label used above cards ("AUTHORIZED NETWORKS").
class LexorSectionLabel extends StatelessWidget {
  const LexorSectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            text.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: LexorPalette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              height: 16 / 12,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Small rounded tag ("DEFI", "VERIFIED DOMAIN").
class LexorTag extends StatelessWidget {
  const LexorTag(
    this.label, {
    super.key,
    this.icon,
    this.color = LexorPalette.textPrimary,
    this.background = LexorPalette.chipMuted,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.44,
                height: 14 / 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum LexorNoticeSeverity { info, caution, danger }

/// Inline callout for risk/safety messages on review sheets.
class LexorNotice extends StatelessWidget {
  const LexorNotice({
    super.key,
    required this.title,
    this.body,
    this.severity = LexorNoticeSeverity.caution,
  });

  final String title;
  final String? body;
  final LexorNoticeSeverity severity;

  @override
  Widget build(BuildContext context) {
    final (color, fill, border, icon) = switch (severity) {
      LexorNoticeSeverity.info => (
          LexorPalette.textSecondary,
          LexorPalette.chipSoft,
          LexorPalette.divider,
          Icons.info_outline_rounded,
        ),
      LexorNoticeSeverity.caution => (
          LexorPalette.caution,
          LexorPalette.cautionFill,
          LexorPalette.cautionBorder,
          Icons.warning_amber_rounded,
        ),
      LexorNoticeSeverity.danger => (
          LexorPalette.danger,
          LexorPalette.dangerFill,
          LexorPalette.dangerBorder,
          Icons.gpp_bad_rounded,
        ),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 18 / 13,
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    body!,
                    style: const TextStyle(
                      color: LexorPalette.textPrimary,
                      fontSize: 12,
                      height: 16 / 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
