import 'package:flutter/material.dart';

import '../../../../app/theme/app_durations.dart';
import '../../../../core/result/result.dart';
import '../../view_model/add_custom_network_state.dart';
import 'settings_palette.dart';

/// Pill in the RPC card's label row: latency + grade once the endpoint has
/// answered, otherwise what state the probe is in.
class RpcPingPill extends StatelessWidget {
  const RpcPingPill({super.key, required this.check});

  final RpcCheck check;

  @override
  Widget build(BuildContext context) {
    final (Widget lead, String primary, String? secondary, Color color) =
        switch (check) {
      RpcIdle() => (
          const _Dot(SettingsPalette.textSecondary),
          'Not tested',
          null,
          SettingsPalette.textSecondary,
        ),
      RpcChecking() => (
          const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: SettingsPalette.accent,
            ),
          ),
          'Testing…',
          null,
          SettingsPalette.textSecondary,
        ),
      final RpcReachable r => (
          _Dot(r.grade == LatencyGrade.slow
              ? SettingsPalette.textSecondary
              : SettingsPalette.accent),
          '${r.latency.inMilliseconds}ms',
          switch (r.grade) {
            LatencyGrade.fast => 'Fast',
            LatencyGrade.good => 'Good',
            LatencyGrade.slow => 'Slow',
          },
          r.grade == LatencyGrade.slow
              ? SettingsPalette.textPrimary
              : SettingsPalette.accent,
        ),
      RpcFailed(:final failure) => (
          const _Dot(SettingsPalette.danger),
          failure is ChainErrorFailure ? 'Invalid reply' : 'Unreachable',
          null,
          SettingsPalette.danger,
        ),
    };

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: SettingsPalette.chip,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            lead,
            const SizedBox(width: 6),
            Text(
              primary,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.07,
              ),
            ),
            if (secondary != null) ...[
              const SizedBox(width: 6),
              Text(
                secondary,
                style: const TextStyle(
                  color: SettingsPalette.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.07,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

/// Thin bar under the RPC field that fills as latency drops. Empty until an
/// endpoint has answered.
class RpcLatencyBar extends StatelessWidget {
  const RpcLatencyBar({super.key, required this.check});

  final RpcCheck check;

  @override
  Widget build(BuildContext context) {
    final fill = switch (check) {
      final RpcReachable r => r.barFill,
      _ => 0.0,
    };
    return ExcludeSemantics(
      child: Container(
        height: 4,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: SettingsPalette.keyPanel,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedFractionallySizedBox(
          duration: AppDurations.medium,
          curve: Curves.easeOut,
          alignment: Alignment.centerLeft,
          widthFactor: fill,
          child: const DecoratedBox(
            decoration: BoxDecoration(color: SettingsPalette.accent),
          ),
        ),
      ),
    );
  }
}
