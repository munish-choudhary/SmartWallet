import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/evm_hex.dart';
import 'package:smart_wallet/features/dapp_browser/data/eip1193/tx_decoder.dart';

void main() {
  group('EvmHex', () {
    test('isAddress is strict', () {
      expect(EvmHex.isAddress('0x71C7656EC7ab88b098defB751B7401B5f6d8976F'), isTrue);
      expect(EvmHex.isAddress('0x71c7656ec7ab88b098defb751b7401b5f6d8976f'), isTrue);
      for (final bad in [
        '71C7656EC7ab88b098defB751B7401B5f6d8976F',
        '0x71C7',
        '0x${'g' * 40}',
        '0x${'a' * 41}',
        null,
        42,
      ]) {
        expect(EvmHex.isAddress(bad), isFalse, reason: '$bad');
      }
    });

    test('sameAddress ignores case', () {
      expect(EvmHex.sameAddress('0xABCDEF', '0xabcdef'), isTrue);
      expect(EvmHex.sameAddress('0xabcdef', '0xabcdee'), isFalse);
    });

    test('quantity parses hex and rejects junk', () {
      expect(EvmHex.quantity('0x0'), BigInt.zero);
      expect(EvmHex.quantity('0x3782dace9d90000'), BigInt.parse('250000000000000000'));
      for (final bad in ['', '0x', '12', '0xZZ', null, 5, '0x${'f' * 65}']) {
        expect(EvmHex.quantity(bad), isNull, reason: '$bad');
      }
    });

    test('isData requires an even number of hex digits', () {
      expect(EvmHex.isData('0x'), isTrue);
      expect(EvmHex.isData('0xdeadbeef'), isTrue);
      expect(EvmHex.isData('0xabc'), isFalse);
      expect(EvmHex.isData('deadbeef'), isFalse);
    });

    group('decodeMessage', () {
      test('plain text passes through', () {
        final m = EvmHex.decodeMessage('Sign in to Example');
        expect(m.text, 'Sign in to Example');
        expect(m.readable, isTrue);
      });

      test('hex-encoded UTF-8 is decoded', () {
        // "Hello\nWorld" 
        final m = EvmHex.decodeMessage('0x48656c6c6f0a576f726c64');
        expect(m.text, 'Hello\nWorld');
        expect(m.readable, isTrue);
      });

      test('binary hex is shown raw and flagged unreadable', () {
        final m = EvmHex.decodeMessage('0xdeadbeef');
        expect(m.text, '0xdeadbeef');
        expect(m.readable, isFalse);
      });

      test('control characters make a message unreadable', () {
        final m = EvmHex.decodeMessage('0x0001020304');
        expect(m.readable, isFalse);
      });
    });

    group('formatUnits', () {
      test('formats whole, fractional and zero values', () {
        final eth = BigInt.parse('1000000000000000000');
        expect(EvmHex.formatUnits(BigInt.zero, 18), '0');
        expect(EvmHex.formatUnits(eth, 18), '1');
        expect(EvmHex.formatUnits(BigInt.parse('250000000000000000'), 18), '0.25');
        expect(EvmHex.formatUnits(BigInt.parse('1234567890000000000'), 18), '1.234567');
        expect(EvmHex.formatUnits(BigInt.from(1500000000), 6), '1500');
      });

      test('a non-zero dust amount is never shown as zero', () {
        expect(EvmHex.formatUnits(BigInt.one, 18), '<0.000001');
      });

      test('large values keep every integer digit', () {
        final v = BigInt.parse('123456789012345678901234567890');
        expect(EvmHex.formatUnits(v, 18), startsWith('123456789012.'));
      });
    });

    test('isUnlimited flags max-uint style amounts only', () {
      final max = BigInt.parse('f' * 64, radix: 16);
      final threshold = BigInt.one << 255;
      expect(EvmHex.isUnlimited(max), isTrue);
      expect(EvmHex.isUnlimited(threshold), isTrue);
      expect(EvmHex.isUnlimited(threshold - BigInt.one), isFalse);
      expect(EvmHex.isUnlimited(BigInt.from(1500000000)), isFalse);
      expect(EvmHex.isUnlimited(BigInt.one << 200), isFalse);
    });

    test('isUnlimitedForBits scales with the type width', () {
      final uint160Max = (BigInt.one << 160) - BigInt.one;
      expect(EvmHex.isUnlimitedForBits(uint160Max, 160), isTrue);
      expect(EvmHex.isUnlimitedForBits(BigInt.from(1500000000), 160), isFalse);
      // Timestamps/nonces (small types) are never relabelled.
      final uint48Max = (BigInt.one << 48) - BigInt.one;
      expect(EvmHex.isUnlimitedForBits(uint48Max, 48), isFalse);
    });
  });

  group('TxDecoder', () {
    const spender = '3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad';
    final unlimited = 'f' * 64;
    String approveData(String amountWord, {String spenderWord = ''}) =>
        '0x095ea7b3${spenderWord.isEmpty ? '${'0' * 24}$spender' : spenderWord}$amountWord';

    test('decodes an ERC-20 approve', () {
      final decoded = TxDecoder.approve(approveData(unlimited))!;
      expect(decoded.spender, '0x$spender');
      expect(EvmHex.isUnlimited(decoded.amount), isTrue);

      final limited = TxDecoder.approve(
        approveData('59682f00'.padLeft(64, '0')),
      )!;
      expect(limited.amount, BigInt.from(1500000000));
    });

    test('rejects malformed approve calldata', () {
      expect(TxDecoder.approve(null), isNull);
      expect(TxDecoder.approve('0x095ea7b3'), isNull); // truncated
      expect(TxDecoder.approve('${approveData(unlimited)}00'), isNull); // extra
      expect(
        TxDecoder.approve(approveData(unlimited, spenderWord: 'f' * 64)),
        isNull, // dirty address padding
      );
      expect(TxDecoder.approve('0xa9059cbb${'0' * 128}'), isNull); // not approve
    });

    test('decodes setApprovalForAll', () {
      final on = TxDecoder.setApprovalForAll(
        '0xa22cb465${'0' * 24}$spender${'0' * 63}1',
      )!;
      expect(on.approved, isTrue);
      expect(on.operator, '0x$spender');
      final off = TxDecoder.setApprovalForAll(
        '0xa22cb465${'0' * 24}$spender${'0' * 64}',
      )!;
      expect(off.approved, isFalse);
    });

    test('names only well-known selectors, case-insensitively', () {
      expect(TxDecoder.methodName('0x095EA7B3${'0' * 128}'), 'approve');
      expect(TxDecoder.methodName('0xa9059cbb${'0' * 128}'), 'transfer');
      expect(TxDecoder.methodName('0xdeadbeef'), isNull);
      expect(TxDecoder.methodName('0x'), isNull);
      expect(TxDecoder.methodName(null), isNull);
    });
  });
}
