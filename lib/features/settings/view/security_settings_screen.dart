import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/result/result.dart';
import '../data/auto_lock_option.dart';
import '../data/security_settings_repository.dart';
import 'widgets/settings_palette.dart';
import 'widgets/settings_sub_header.dart';

/// Entry point of Settings → Security. Rows that have a screen link to it;
/// the rest (passcode change, biometrics, signing auth)
/// aren't built yet and say so instead of showing switches that do nothing.
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  AutoLockOption? _autoLock;

  @override
  void initState() {
    super.initState();
    _loadAutoLock();
  }

  Future<void> _loadAutoLock() async {
    final result = await context.read<SecuritySettingsRepository>().getAutoLock();
    if (mounted) setState(() => _autoLock = result.valueOrNull);
  }

  void _comingSoon(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what is not available yet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: 'Security Settings',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _EnclaveCard(),
          const SizedBox(height: 24),
          const _SectionHeader('AUTHENTICATION & ACCESS'),
          _Group(
            children: [
              _Row(
                icon: Icons.pin_outlined,
                title: 'Change Passcode',
                subtitle: 'Update 6-digit access PIN',
                trailing: const _Chevron(),
                onTap: () => _comingSoon('Change Passcode'),
              ),
              _Row(
                icon: Icons.fingerprint_rounded,
                title: 'Biometric Unlock',
                subtitle: 'Use Face ID / Touch ID to open',
                trailing: const _Chevron(),
                onTap: () => _comingSoon('Biometric settings'),
              ),
              _Row(
                icon: Icons.timer_outlined,
                title: 'Auto-Lock',
                subtitle: 'Lock wallet when idle',
                trailing: _ValuePill(_autoLock?.shortLabel ?? '—'),
                onTap: () async {
                  await context.push(Routes.autoLock);
                  if (mounted) await _loadAutoLock();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionHeader('TRANSACTION PROTECTION'),
          _Group(
            children: [
              _Row(
                icon: Icons.lock_outline_rounded,
                title: 'Require Auth for Signing',
                subtitle: 'Authorize before network broadcast',
                trailing: const _Chevron(),
                onTap: () => _comingSoon('Signing authentication settings'),
              ),
              _Row(
                icon: Icons.visibility_off_outlined,
                title: 'Hide Balances on Launch',
                subtitle: 'Mask monetary figures in public spaces',
                trailing: const _Chevron(),
                onTap: () => context.push(Routes.balancePrivacy),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionHeader(
            'VAULT CREDENTIALS & BACKUP',
            color: SettingsPalette.danger,
            trailing: 'Zero Cloud Copy',
          ),
          _Group(
            children: [
              _Row(
                icon: Icons.key_rounded,
                title: 'Show Recovery Phrase',
                subtitle: '12-word master seed key',
                badge: const _Badge(
                  'PROTECTED',
                  SettingsPalette.accent,
                  SettingsPalette.onAccent,
                ),
                trailing: const _Chevron(),
                onTap: () => context.push(Routes.showRecoveryPhrase),
              ),
              _Row(
                icon: Icons.warning_amber_rounded,
                title: 'Export Raw Private Key',
                subtitle: 'Single chain raw cryptographic key',
                danger: true,
                badge: const _Badge(
                  'CRITICAL',
                  Color(0x66FFB4AB),
                  SettingsPalette.dangerText,
                ),
                trailing: const _Chevron(),
                onTap: () => context.push(Routes.exportPrivateKey),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _ZeroKnowledgeCard(),
          const SizedBox(height: 24),
          const _SectionHeader('SUPPORT'),
          _Group(
            children: [
              _Row(
                icon: Icons.help_outline_rounded,
                title: 'Help & About',
                subtitle: 'Support, legal and app info',
                trailing: const _Chevron(),
                onTap: () => context.push(Routes.helpAbout),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on AutoLockOption {
  String get shortLabel => switch (this) {
        AutoLockOption.immediately => 'Now',
        AutoLockOption.oneMinute => '1 min',
        AutoLockOption.fiveMinutes => '5 min',
        AutoLockOption.fifteenMinutes => '15 min',
        AutoLockOption.never => 'Never',
      };
}

class _EnclaveCard extends StatelessWidget {
  const _EnclaveCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SettingsPalette.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: SettingsPalette.accent),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ENCLAVE ACTIVE • LEVEL 3 SHIELD',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SettingsPalette.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.44,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SettingsPalette.chip,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'HSM V2.4',
                  style: TextStyle(
                    color: SettingsPalette.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: SettingsPalette.chip,
                child: Icon(Icons.verified_user_rounded,
                    color: SettingsPalette.accent),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hardware Enclave Protected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SettingsPalette.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Secure Element isolated from OS memory',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SettingsPalette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: SettingsPalette.cardMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_person_outlined,
                    size: 16, color: SettingsPalette.textPrimary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tamper Sensor',
                    style: TextStyle(
                      color: SettingsPalette.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
                Icon(Icons.circle, size: 6, color: SettingsPalette.accent),
                SizedBox(width: 6),
                Text(
                  'Armed & Nominal',
                  style: TextStyle(
                    color: SettingsPalette.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
    this.text, {
    this.color = SettingsPalette.textSecondary,
    this.trailing,
  });
  final String text;
  final Color color;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.44,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      );
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(children: children),
      );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.badge,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;
  final Widget? badge;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: danger ? const Color(0x3393000A) : SettingsPalette.card,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    danger ? SettingsPalette.dangerBadge : SettingsPalette.cardAlt,
                child: Icon(
                  icon,
                  size: 18,
                  color: danger
                      ? SettingsPalette.danger
                      : SettingsPalette.textSecondary,
                ),
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
                            style: TextStyle(
                              color: danger
                                  ? SettingsPalette.dangerText
                                  : SettingsPalette.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (badge != null) ...[const SizedBox(width: 8), badge!],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: danger
                            ? SettingsPalette.danger
                            : SettingsPalette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) => const Icon(
        Icons.chevron_right_rounded,
        color: SettingsPalette.textSecondary,
      );
}

class _ValuePill extends StatelessWidget {
  const _ValuePill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: SettingsPalette.chip,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: SettingsPalette.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(Icons.expand_more_rounded,
                size: 16, color: SettingsPalette.textPrimary),
          ],
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.background, this.foreground);
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: foreground,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _ZeroKnowledgeCard extends StatelessWidget {
  const _ZeroKnowledgeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SettingsPalette.cardMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, size: 20, color: SettingsPalette.accent),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zero-Knowledge Enclave',
                  style: TextStyle(
                    color: SettingsPalette.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Lexor Pocket keeps cryptographic entropy bound to your '
                  'hardware module. Keys are never transmitted, backed up to '
                  'iCloud/Google Drive, or logged.',
                  style: TextStyle(
                    color: SettingsPalette.textSecondary,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
