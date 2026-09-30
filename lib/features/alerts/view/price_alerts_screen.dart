import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design_system/lexor_card.dart';
import '../../../core/design_system/lexor_page_scaffold.dart';
import '../../../core/design_system/lexor_palette.dart';
import '../../portfolio/data/models/token_asset.dart';
import '../data/price_alert.dart';
import '../view_model/price_alerts_cubit.dart';
import '../view_model/price_alerts_state.dart';

class PriceAlertsScreen extends StatelessWidget {
  const PriceAlertsScreen({super.key});

  Future<void> _openCreate(BuildContext context, List<TokenAsset> tokens) {
    final cubit = context.read<PriceAlertsCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LexorPalette.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _CreateAlertSheet(tokens: tokens),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PriceAlertsCubit, PriceAlertsState>(
      builder: (context, state) {
        final loaded = state is PriceAlertsLoaded ? state : null;
        return LexorPageScaffold(
          title: 'Price Alerts',
          trailing: loaded == null
              ? null
              : LexorHeaderAction(
                  icon: Icons.add_alert_rounded,
                  semanticLabel: 'New alert',
                  onPressed: () => _openCreate(context, loaded.tokens),
                ),
          child: loaded == null
              ? const Center(
                  child: CircularProgressIndicator(color: LexorPalette.accent),
                )
              : loaded.alerts.isEmpty
                  ? const Center(
                      child: Text(
                        'No alerts yet. Tap + to create one.',
                        style: TextStyle(color: LexorPalette.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                      itemCount: loaded.alerts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _AlertTile(alert: loaded.alerts[i]),
                    ),
        );
      },
    );
  }
}

String _price(double v) => '\$${v.toStringAsFixed(v >= 100 ? 0 : 2)}';

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final PriceAlert alert;

  @override
  Widget build(BuildContext context) {
    final above = alert.direction == AlertDirection.above;
    return Dismissible(
      key: ValueKey(alert.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => context.read<PriceAlertsCubit>().remove(alert.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: LexorPalette.dangerFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: LexorPalette.danger),
      ),
      child: LexorCard(
        radius: 16,
        child: Row(
          children: [
            Icon(
              above ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: above ? LexorPalette.accent : LexorPalette.danger,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.symbol,
                    style: const TextStyle(
                      color: LexorPalette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${above ? 'Rises above' : 'Falls below'} ${_price(alert.targetUsd)}',
                    style: const TextStyle(
                      color: LexorPalette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: alert.enabled,
              activeThumbColor: LexorPalette.onAccent,
              activeTrackColor: LexorPalette.accent,
              onChanged: (v) => context
                  .read<PriceAlertsCubit>()
                  .setEnabled(alert.id, enabled: v),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateAlertSheet extends StatefulWidget {
  const _CreateAlertSheet({required this.tokens});

  final List<TokenAsset> tokens;

  @override
  State<_CreateAlertSheet> createState() => _CreateAlertSheetState();
}

class _CreateAlertSheetState extends State<_CreateAlertSheet> {
  late TokenAsset _token = widget.tokens.first;
  AlertDirection _direction = AlertDirection.above;
  final _target = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await context.read<PriceAlertsCubit>().create(
          token: _token,
          targetUsd: double.tryParse(_target.text) ?? 0,
          direction: _direction,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _invalid = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New price alert',
            style: TextStyle(
              color: LexorPalette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final t in widget.tokens)
                ChoiceChip(
                  label: Text(t.symbol),
                  selected: t.id == _token.id,
                  onSelected: (_) => setState(() => _token = t),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Current price ${_token.formattedPrice}',
            style: const TextStyle(color: LexorPalette.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SegmentedButton<AlertDirection>(
            segments: const [
              ButtonSegment(value: AlertDirection.above, label: Text('Above')),
              ButtonSegment(value: AlertDirection.below, label: Text('Below')),
            ],
            selected: {_direction},
            onSelectionChanged: (s) => setState(() => _direction = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: LexorPalette.textPrimary),
            decoration: InputDecoration(
              prefixText: '\$ ',
              hintText: 'Target price',
              errorText: _invalid ? 'Enter a price greater than 0' : null,
              filled: true,
              fillColor: LexorPalette.cardSolid,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: LexorPalette.accent,
                foregroundColor: LexorPalette.onAccent,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Create alert'),
            ),
          ),
        ],
      ),
    );
  }
}
