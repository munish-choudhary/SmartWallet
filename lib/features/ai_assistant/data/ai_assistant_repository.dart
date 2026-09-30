import '../../../core/result/result.dart';
import '../../portfolio/data/models/token_asset.dart';
import '../../portfolio/data/portfolio_repository.dart';
import 'ai_message.dart';

/// Turns a prompt into assistant messages.
///
/// The LLM lives on the backend (CLAUDE.md) and is not wired yet, so this
/// recognises the swap phrasing locally. Whatever produces an intent, it is
/// re-validated here against the portfolio (tokens exist, balance covers the
/// amount) before a card is built — the same path a backend intent takes.
abstract interface class AiAssistantRepository {
  Future<Result<List<AiMessage>>> respond(String prompt);

  /// Tokens the swap screen needs to open pre-filled from a quote card.
  Future<List<TokenAsset>> swapTokens();
}

class LocalAiAssistantRepository implements AiAssistantRepository {
  LocalAiAssistantRepository({required PortfolioRepository portfolio})
    : _portfolio = portfolio;

  final PortfolioRepository _portfolio;

  static final _swapPattern = RegExp(
    r'swap\s+([\d.,]+)\s*([a-z0-9]+)\s+(?:to|for|into)\s+([a-z0-9]+)',
    caseSensitive: false,
  );

  @override
  Future<Result<List<AiMessage>>> respond(String prompt) async {
    final now = DateTime.now();
    final match = _swapPattern.firstMatch(prompt.trim());
    if (match == null) {
      return Result.ok([
        AiTextMessage(
          'I can prepare swaps for you — try "Swap 500 USDC to SOL". '
          'You always review and confirm before anything is signed.',
          at: now,
        ),
      ]);
    }

    final snapshot = await _portfolio.getSnapshot();
    final assets = snapshot.valueOrNull?.assets;
    if (assets == null) {
      return Result.err(
        snapshot.failureOrNull ??
            const AppFailure.network('Portfolio unavailable'),
      );
    }

    final amount = double.tryParse(match.group(1)!.replaceAll(',', ''));
    final from = _find(assets, match.group(2)!);
    final to = _find(assets, match.group(3)!);

    if (amount == null ||
        amount <= 0 ||
        from == null ||
        to == null ||
        from.id == to.id) {
      return Result.ok([
        AiTextMessage(
          "I couldn't match that swap to tokens in your wallet. "
          'Check the symbols and amount and try again.',
          at: now,
        ),
      ]);
    }
    if (amount > from.balance) {
      return Result.ok([
        AiTextMessage(
          'You only hold ${from.formattedBalance} ${from.symbol}, '
          'which is less than the ${match.group(1)} you asked to swap.',
          at: now,
        ),
      ]);
    }
    if (to.priceUsd <= 0) {
      return Result.ok([
        AiTextMessage(
          'No price available for ${to.symbol} right now.',
          at: now,
        ),
      ]);
    }

    const feeRate = 0.003;
    final quote = SwapQuote(
      from: from,
      to: to,
      payAmount: amount,
      receiveAmount: amount * from.priceUsd / to.priceUsd * (1 - feeRate),
      route: 'Best route',
      priceImpactPercent: 0.12,
      networkFeeUsd: 1.85,
      slippagePercent: 0.5,
    );
    return Result.ok([
      AiSwapMessage(
        'Here is a swap of ${_trim(amount)} ${from.symbol} to ${to.symbol}. '
        'Review the details, then continue to confirm.',
        quote,
        at: now,
      ),
    ]);
  }

  @override
  Future<List<TokenAsset>> swapTokens() async =>
      (await _portfolio.getSnapshot()).valueOrNull?.assets ?? const [];

  static TokenAsset? _find(List<TokenAsset> assets, String symbol) {
    for (final a in assets) {
      if (a.symbol.toLowerCase() == symbol.toLowerCase()) return a;
    }
    return null;
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(4);
}
