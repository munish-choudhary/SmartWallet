import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design_system/lexor_card.dart';
import '../../../core/design_system/lexor_page_scaffold.dart';
import '../../../core/design_system/lexor_palette.dart';
import '../view_model/buy_sell_cubit.dart';
import '../view_model/buy_sell_state.dart';

class BuySellScreen extends StatelessWidget {
  const BuySellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LexorPageScaffold(
      title: 'Buy / Sell',
      child: BlocBuilder<BuySellCubit, BuySellState>(
        builder: (context, state) => switch (state) {
          BuySellLoading() => const Center(
              child: CircularProgressIndicator(color: LexorPalette.accent),
            ),
          final BuySellReady ready => _Form(state: ready),
        },
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.state});

  final BuySellReady state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BuySellCubit>();
    final buying = state.side == TradeSide.buy;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<TradeSide>(
            segments: const [
              ButtonSegment(value: TradeSide.buy, label: Text('Buy')),
              ButtonSegment(value: TradeSide.sell, label: Text('Sell')),
            ],
            selected: {state.side},
            onSelectionChanged: (s) => cubit.setSide(s.first),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in state.tokens)
                ChoiceChip(
                  label: Text(t.symbol),
                  selected: t.id == state.token.id,
                  onSelected: (_) => cubit.selectToken(t),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LexorCard(
            radius: 20,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  buying ? 'You pay' : 'You sell (USD value)',
                  style: const TextStyle(
                    color: LexorPalette.textSecondary,
                    fontSize: 12,
                  ),
                ),
                TextField(
                  onChanged: cubit.setAmount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: LexorPalette.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    hintText: '0',
                    border: InputBorder.none,
                    errorText: state.exceedsBalance
                        ? 'Exceeds your ${state.token.symbol} balance '
                            '(${state.token.formattedFiatValue})'
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LexorCard(
            radius: 16,
            child: Column(
              children: [
                _row(
                  'Price',
                  state.token.formattedPrice,
                ),
                _row('Provider fee (1.5%)',
                    '\$${state.feeUsd.toStringAsFixed(2)}'),
                _row(
                  buying ? 'You receive' : 'You get (USD)',
                  buying
                      ? '${state.tokenAmount.toStringAsFixed(6)} ${state.token.symbol}'
                      : '\$${(state.amountUsd - state.feeUsd).toStringAsFixed(2)}',
                  emphasize: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Quotes are estimates. Fiat providers are not connected yet.',
            style: TextStyle(color: LexorPalette.textDisabled, fontSize: 11),
          ),
          const SizedBox(height: 20),
          FilledButton(
            // The on/off-ramp provider integration is a follow-up; the
            // button stays disabled until there is something to submit to.
            onPressed: null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(buying ? 'Continue to buy' : 'Continue to sell'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: LexorPalette.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: emphasize ? LexorPalette.accent : LexorPalette.textPrimary,
              fontSize: 13,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
