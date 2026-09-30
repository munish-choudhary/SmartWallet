import '../../portfolio/data/models/token_asset.dart';

/// A locally re-validated swap proposal. Per CLAUDE.md the AI only ever
/// returns intents; this is what remains once the app has checked the
/// tokens exist and the balance covers the amount.
class SwapQuote {
  const SwapQuote({
    required this.from,
    required this.to,
    required this.payAmount,
    required this.receiveAmount,
    required this.route,
    required this.priceImpactPercent,
    required this.networkFeeUsd,
    required this.slippagePercent,
  });

  final TokenAsset from;
  final TokenAsset to;
  final double payAmount;
  final double receiveAmount;
  final String route;
  final double priceImpactPercent;
  final double networkFeeUsd;
  final double slippagePercent;

  double get payUsd => payAmount * from.priceUsd;
  double get receiveUsd => receiveAmount * to.priceUsd;
}

sealed class AiMessage {
  const AiMessage({required this.at});
  final DateTime at;
}

class AiUserMessage extends AiMessage {
  const AiUserMessage(this.text, {required super.at});
  final String text;
}

class AiTextMessage extends AiMessage {
  const AiTextMessage(this.text, {required super.at});
  final String text;
}

class AiSwapMessage extends AiMessage {
  const AiSwapMessage(this.intro, this.quote, {required super.at});
  final String intro;
  final SwapQuote quote;
}
