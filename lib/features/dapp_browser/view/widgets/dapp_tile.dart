import 'package:flutter/material.dart';

import '../../../../core/design_system/dapp_icon.dart';
import '../../../../core/design_system/lexor_card.dart';
import '../../../../core/design_system/lexor_palette.dart';
import '../../data/models/dapp.dart';

/// A featured dApp row: icon, name, one-line pitch, favorite toggle.
class DappTile extends StatelessWidget {
  const DappTile({
    super.key,
    required this.dapp,
    required this.isFavorite,
    required this.onOpen,
    required this.onToggleFavorite,
  });

  final Dapp dapp;
  final bool isFavorite;
  final VoidCallback onOpen;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return LexorCard(
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          DappIcon(name: dapp.name, brandColor: dapp.brandColor, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        dapp.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LexorPalette.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    LexorTag(dapp.category.label),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  dapp.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LexorPalette.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggleFavorite,
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            icon: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: isFavorite
                  ? LexorPalette.accent
                  : LexorPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
