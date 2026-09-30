import 'evm_hex.dart';

/// Local decoding of calldata for the review sheet. Names come from a fixed
/// table of well-known selectors — never from the dApp — so a hostile page
/// cannot label a dangerous call with a friendly name.
abstract final class TxDecoder {
  static const _selectors = <String, String>{
    '0x095ea7b3': 'approve',
    '0xa9059cbb': 'transfer',
    '0x23b872dd': 'transferFrom',
    '0xa22cb465': 'setApprovalForAll',
    '0x42842e0e': 'safeTransferFrom',
    '0xd0e30db0': 'deposit',
    '0x2e1a7d4d': 'withdraw',
    '0x7ff36ab5': 'swapExactETHForTokens',
    '0x18cbafe5': 'swapExactTokensForETH',
    '0x38ed1739': 'swapExactTokensForTokens',
    '0x3593564c': 'execute (Universal Router)',
    '0xa694fc3a': 'stake',
    '0x2e17de78': 'unstake',
  };

  static String? selector(String? data) {
    if (data == null || data.length < 10) return null;
    return data.substring(0, 10).toLowerCase();
  }

  static String? methodName(String? data) => _selectors[selector(data)];

  /// ERC-20 `approve(spender, amount)`; null when [data] isn't one.
  static ({String spender, BigInt amount})? approve(String? data) {
    if (selector(data) != '0x095ea7b3') return null;
    // 4-byte selector + two 32-byte words.
    if (data!.length != 2 + 8 + 128 || !EvmHex.isData(data)) return null;
    final spenderWord = data.substring(10, 74);
    final amountWord = data.substring(74);
    if (!spenderWord.startsWith('0' * 24)) return null;
    return (
      spender: '0x${spenderWord.substring(24)}',
      amount: BigInt.parse(amountWord, radix: 16),
    );
  }

  /// ERC-721/1155 `setApprovalForAll(operator, approved)`.
  static ({String operator, bool approved})? setApprovalForAll(String? data) {
    if (selector(data) != '0xa22cb465') return null;
    if (data!.length != 2 + 8 + 128 || !EvmHex.isData(data)) return null;
    final operatorWord = data.substring(10, 74);
    if (!operatorWord.startsWith('0' * 24)) return null;
    final approved = BigInt.parse(data.substring(74), radix: 16) != BigInt.zero;
    return (operator: '0x${operatorWord.substring(24)}', approved: approved);
  }
}
