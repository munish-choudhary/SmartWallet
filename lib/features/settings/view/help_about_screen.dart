import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/app_info.dart';
import 'widgets/lexor_emblem.dart';
import 'widgets/settings_palette.dart';
import 'widgets/settings_sub_header.dart';

/// Settings → Help & About: brand card with build info, support and legal
/// link groups, a store-review prompt and community links.
///
/// Every destination here is external (web pages, support chat, store
/// listing, social profiles) and the app has no link launcher yet, so taps
/// say "not available yet" the same way unbuilt rows on Security Settings do.
/// The diagnostics strip is static copy from the design until a real status
/// source exists.
class HelpAboutScreen extends StatelessWidget {
  const HelpAboutScreen({super.key});

  void _comingSoon(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what is not available yet')));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SettingsPageScaffold(
      title: 'Help & About',
      ambient: const _HelpAmbient(),
      headerTrailing: const _HeaderBadge(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
        children: [
          const _BrandCard(),
          const SizedBox(height: 24),
          const _DiagnosticsStrip(),
          const SizedBox(height: 24),
          const _SectionHeader('SUPPORT & DOCUMENTATION'),
          _LinkGroup(
            children: [
              _LinkRow(
                icon: Icons.menu_book_rounded,
                title: 'Help Center',
                subtitle: 'Guides, tutorials and FAQs',
                onTap: () => _comingSoon(context, 'Help Center'),
              ),
              _LinkRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Encrypted Live Desk',
                subtitle: 'Chat with support, end-to-end encrypted',
                badge: const _LiveBadge(),
                onTap: () => _comingSoon(context, 'Live Desk'),
              ),
              _LinkRow(
                icon: Icons.monitor_heart_outlined,
                title: 'System Status',
                subtitle: 'Network and service uptime',
                onTap: () => _comingSoon(context, 'System Status'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionHeader('LEGAL & COMPLIANCE'),
          _LinkGroup(
            children: [
              _LinkRow(
                icon: Icons.description_outlined,
                iconColor: SettingsPalette.iconMuted,
                title: 'Terms of Service',
                subtitle: 'The rules for using Lexor Pocket',
                onTap: () => _comingSoon(context, 'Terms of Service'),
              ),
              _LinkRow(
                icon: Icons.lock_outline_rounded,
                iconColor: SettingsPalette.iconMuted,
                title: 'Privacy & Zero Log',
                subtitle: 'What we collect, and what we never do',
                onTap: () => _comingSoon(context, 'Privacy policy'),
              ),
              _LinkRow(
                icon: Icons.code_rounded,
                iconColor: SettingsPalette.iconMuted,
                title: 'Audits & Open Source',
                subtitle: 'Security reviews and source code',
                onTap: () => _comingSoon(context, 'Audits & Open Source'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _FeedbackBanner(onReview: () => _comingSoon(context, 'Store review')),
          const SizedBox(height: 24),
          _CommunitySection(
            onTap: (network) => _comingSoon(context, network),
          ),
          const SizedBox(height: 32),
          const _LegalFooter(),
        ],
      ),
    );
  }
}

class _HelpAmbient extends StatelessWidget {
  const _HelpAmbient();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          Positioned(
            right: -96,
            top: -96,
            child: _Blob(
              size: 320,
              color: SettingsPalette.accent.withValues(alpha: 0.05),
              sigma: 60,
            ),
          ),
          Positioned(
            left: -128,
            top: 260,
            child: _Blob(
              size: 288,
              color: SettingsPalette.glowGrey.withValues(alpha: 0.3),
              sigma: 50,
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color, required this.sigma});

  final double size;
  final Color color;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge();

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: CircleAvatar(
        radius: 16,
        backgroundColor: SettingsPalette.cardAlt,
        child: Icon(
          Icons.help_outline_rounded,
          size: 16,
          color: SettingsPalette.accent,
        ),
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  const _BrandCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: SettingsPalette.glassCard),
        child: Stack(
          children: [
            Positioned(
              left: -48,
              top: -48,
              child: _Blob(
                size: 176,
                color: SettingsPalette.accent.withValues(alpha: 0.15),
                sigma: 32,
              ),
            ),
            Positioned(
              right: -40,
              bottom: -40,
              child: _Blob(
                size: 160,
                color: SettingsPalette.glowGrey.withValues(alpha: 0.6),
                sigma: 20,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    LexorEmblem(),
                    SizedBox(height: 16),
                    Text(
                      'Lexor Pocket',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SettingsPalette.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        height: 32 / 24,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'A secure, non-custodial multi-chain wallet built for '
                      'speed, privacy and full self-custody.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SettingsPalette.textSecondary,
                        fontSize: 12,
                        letterSpacing: 0.12,
                        height: 16 / 12,
                      ),
                    ),
                    SizedBox(height: 16),
                    _VersionChip(),
                    SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          size: 13,
                          color: SettingsPalette.accent,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Non-custodial • Keys stay on your device',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: SettingsPalette.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: SettingsPalette.glassChip,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: SettingsPalette.accent),
          SizedBox(width: 4),
          Text(
            'V${AppInfo.version} (BUILD ${AppInfo.build})',
            style: TextStyle(
              color: SettingsPalette.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.44,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticsStrip extends StatelessWidget {
  const _DiagnosticsStrip();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SettingsPalette.glassCardSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: SizedBox.square(
                dimension: 12,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SettingsPalette.accent.withValues(alpha: 0.75),
                      ),
                      child: const SizedBox.square(dimension: 12),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SettingsPalette.accent,
                      ),
                      child: SizedBox.square(dimension: 8),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All systems operational',
                    style: TextStyle(
                      color: SettingsPalette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.26,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Signing and network services nominal',
                    style: TextStyle(
                      color: SettingsPalette.textSecondary,
                      fontSize: 12,
                      letterSpacing: 0.12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const _Pill('OK'),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: SettingsPalette.chip,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: SettingsPalette.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.44,
          ),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Semantics(
          header: true,
          child: Text(
            text,
            style: const TextStyle(
              color: SettingsPalette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
      );
}

class _LinkGroup extends StatelessWidget {
  const _LinkGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: SettingsPalette.glassCard),
          child: Material(
            type: MaterialType.transparency,
            child: Column(children: children),
          ),
        ),
      );
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = SettingsPalette.accent,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: SettingsPalette.cardAlt,
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: SettingsPalette.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 24 / 16,
                        ),
                      ),
                      if (badge != null) badge!,
                    ],
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: SettingsPalette.textSecondary,
                      fontSize: 12,
                      letterSpacing: 0.12,
                      height: 16 / 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: SettingsPalette.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: SettingsPalette.accent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'LIVE',
          style: TextStyle(
            color: SettingsPalette.onAccentMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.07,
          ),
        ),
      );
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.onReview});
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SettingsPalette.glassBanner,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 15,
            offset: Offset(0, 10),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Row(
                    children: [
                      for (var i = 0; i < 5; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: SettingsPalette.accent,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Love Lexor Pocket?',
                  style: TextStyle(
                    color: SettingsPalette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 24 / 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'A quick review helps other people find a safer wallet.',
                  style: TextStyle(
                    color: SettingsPalette.textSecondary,
                    fontSize: 12,
                    letterSpacing: 0.12,
                    height: 16 / 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Material(
            color: SettingsPalette.accent,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onReview,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Text(
                  'Review',
                  style: TextStyle(
                    color: Color(0xFF181E00),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.12,
                    height: 16 / 12,
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

/// Generic glyphs stand in for the brand marks — no brand icon assets are
/// bundled, and adding an icon package needs sign-off.
class _CommunitySection extends StatelessWidget {
  const _CommunitySection({required this.onTap});
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'JOIN THE COMMUNITY',
            style: TextStyle(
              color: SettingsPalette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            _SocialButton(
              label: 'X',
              onTap: () => onTap('X'),
              child: const Text(
                'X',
                style: TextStyle(
                  color: SettingsPalette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _SocialButton(
              label: 'Discord',
              onTap: () => onTap('Discord'),
              child: const _SocialIcon(Icons.forum_rounded),
            ),
            _SocialButton(
              label: 'Telegram',
              onTap: () => onTap('Telegram'),
              child: const _SocialIcon(Icons.send_rounded),
            ),
            _SocialButton(
              label: 'GitHub',
              onTap: () => onTap('GitHub'),
              child: const _SocialIcon(Icons.code_rounded),
            ),
            _SocialButton(
              label: 'Warpcast',
              onTap: () => onTap('Warpcast'),
              child: const _SocialIcon(Icons.alternate_email_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: 20, color: SettingsPalette.textPrimary);
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: SettingsPalette.cardAlt,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(dimension: 48, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        '© $year Lexor Pocket. All rights reserved. Lexor Pocket is a '
        'non-custodial wallet: only you hold your recovery phrase, and no one '
        'can recover it for you. Crypto assets carry risk.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: SettingsPalette.textFaint,
          fontSize: 12,
          letterSpacing: 0.12,
          height: 20 / 12,
        ),
      ),
    );
  }
}
