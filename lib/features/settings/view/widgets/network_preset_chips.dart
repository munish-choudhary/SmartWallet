import 'package:flutter/material.dart';

import '../../data/network_preset.dart';
import 'settings_palette.dart';

/// Horizontally scrolling row of preset chips. Brings its own 20px side
/// padding so the row can run edge to edge inside a padded page.
class NetworkPresetChips extends StatelessWidget {
  const NetworkPresetChips({
    super.key,
    required this.presets,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final List<NetworkPreset> presets;
  final NetworkPreset? selected;
  final ValueChanged<NetworkPreset> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final preset = presets[i];
          return Center(
            child: _PresetChip(
              label: preset.label,
              selected: preset == selected,
              onTap: enabled ? () => onSelected(preset) : null,
            ),
          );
        },
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: SettingsPalette.card.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected
                ? SettingsPalette.accent.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: onTap,
          child: SizedBox(
            height: 34,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? SettingsPalette.accent
                          : const Color(0xFFE2E2E2),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: SettingsPalette.accent
                                    .withValues(alpha: 0.8),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: SettingsPalette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.26,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
