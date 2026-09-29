import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_record.freezed.dart';

enum TransactionType {
  inbound,
  swap,
  outbound,
}

@freezed
sealed class TransactionRecord with _$TransactionRecord {
  const TransactionRecord._();

  const factory TransactionRecord({
    required String id,
    required String title,
    required String subtitle,
    required double amount,
    required double amountUsd,
    required String tokenSymbol,
    required DateTime timestamp,
    required TransactionType type,
    @Default('Completed') String status,
  }) = _TransactionRecord;

  bool get isInbound => type == TransactionType.inbound;
  bool get isOutbound => type == TransactionType.outbound;
  bool get isSwap => type == TransactionType.swap;

  String get formattedAmount {
    final prefix = isInbound ? '+' : (isOutbound ? '-' : '+');
    return '$prefix${amount.abs().toStringAsFixed(2)} $tokenSymbol';
  }

  String get formattedAmountUsd {
    return '\$${amountUsd.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }
}
