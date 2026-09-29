import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_durations.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/design_system/ambient_background.dart';
import '../../../core/vault/vault.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Brief branded logo/glow screen, then routes to Welcome (no wallet yet)
/// or straight to the Portfolio placeholder (wallet already exists — a
/// real `/lock` unlock screen is a follow-up; see the onboarding delivery
/// report for why the Figma "Splash" frame isn't used verbatim here).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppDurations.splash);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery.of needs an established element, so this — not
    // initState — is the correct place to read it once, on first build.
    if (_started) return;
    _started = true;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) _controller.duration = Duration.zero;
    _controller.forward();
    _navigateWhenReady();
  }

  Future<void> _navigateWhenReady() async {
    final hasWallet = context.read<Vault>().hasAnyWallet();
    final minDisplay = Future<void>.delayed(AppDurations.splash);
    final results = await Future.wait([hasWallet, minDisplay]);
    if (!mounted) return;
    context.go((results[0] as bool) ? Routes.portfolio : Routes.welcome);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = Curves.easeOut.transform(_controller.value);
              return Opacity(
                opacity: t,
                child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.4),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: AppColors.accent,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 24),
                Text(l10n.appName, style: AppTypography.displayLarge),
                const SizedBox(height: 8),
                Text(l10n.splashTagline, style: AppTypography.body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
