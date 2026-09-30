import 'dart:convert';

import '../../../walletconnect/data/models/wc_request.dart';
import 'evm_hex.dart';

/// Turns an `eth_signTypedData_v4` payload into display rows.
///
/// The payload is attacker-controlled, so: depth and row count are capped,
/// long values are truncated, and only fields declared in `types` are read.
final class ParsedTypedData {
  const ParsedTypedData({
    required this.primaryType,
    required this.chainId,
    required this.domain,
    required this.fields,
    required this.authorizesTransfers,
  });

  final String primaryType;

  /// `domain.chainId`, when present and parseable.
  final int? chainId;
  final List<WcTypedField> domain;
  final List<WcTypedField> fields;
  final bool authorizesTransfers;
}

abstract final class TypedDataParser {
  static const _maxRows = 60;
  static const _maxDepth = 5;
  static const _maxValueLength = 200;

  static final _transferLike = RegExp(
    r'permit|order|allowance|delegat|seaport|bid|approval',
    caseSensitive: false,
  );

  /// Null when [raw] isn't a valid typed-data document.
  static ParsedTypedData? parse(Object? raw) {
    final Object? json;
    if (raw is String) {
      if (raw.length > 512 * 1024) return null;
      try {
        json = jsonDecode(raw);
      } on FormatException {
        return null;
      }
    } else {
      json = raw;
    }
    if (json is! Map) return null;
    final types = json['types'];
    final primaryType = json['primaryType'];
    final message = json['message'];
    final domain = json['domain'];
    if (types is! Map || primaryType is! String || message is! Map) {
      return null;
    }
    if (types[primaryType] is! List) return null;

    final rows = <WcTypedField>[];
    _flatten(types, primaryType, message, 0, rows);

    final domainRows = <WcTypedField>[];
    int? chainId;
    if (domain is Map) {
      final order = <String>{
        if (types['EIP712Domain'] is List)
          for (final m in types['EIP712Domain'] as List)
            if (m is Map && m['name'] is String) m['name'] as String,
        for (final key in domain.keys)
          if (key is String) key,
      };
      for (final key in order) {
        if (!domain.containsKey(key)) continue;
        final value = domain[key];
        if (key == 'chainId') chainId = _asInt(value);
        domainRows.add(WcTypedField(key, _show(value)));
      }
    }

    return ParsedTypedData(
      primaryType: primaryType,
      chainId: chainId,
      domain: domainRows,
      fields: rows,
      authorizesTransfers: _transferLike.hasMatch(primaryType),
    );
  }

  static void _flatten(
    Map types,
    String typeName,
    Map value,
    int depth,
    List<WcTypedField> out,
  ) {
    final members = types[typeName];
    if (members is! List) return;
    for (final member in members) {
      if (out.length >= _maxRows) {
        if (out.length == _maxRows) {
          out.add(const WcTypedField('…', 'more fields not shown'));
        }
        return;
      }
      if (member is! Map) continue;
      final name = member['name'];
      final type = member['type'];
      if (name is! String || type is! String) continue;
      final v = value[name];
      _emit(types, name, type, v, depth, out);
    }
  }

  static void _emit(
    Map types,
    String label,
    String type,
    Object? v,
    int depth,
    List<WcTypedField> out,
  ) {
    if (out.length >= _maxRows) return;
    if (type.endsWith(']')) {
      final element = type.substring(0, type.lastIndexOf('['));
      if (v is List) {
        for (var i = 0; i < v.length && out.length < _maxRows; i++) {
          _emit(types, '$label[$i]', element, v[i], depth, out);
        }
      }
      return;
    }
    if (types[type] is List) {
      out.add(WcTypedField(label, '', depth: depth));
      if (depth + 1 >= _maxDepth || v is! Map) return;
      _flatten(types, type, v, depth + 1, out);
      return;
    }
    out.add(WcTypedField(label, _show(v, type: type), depth: depth));
  }

  static String _show(Object? v, {String? type}) {
    var text = switch (v) {
      null => '',
      String() => v,
      _ => v.toString(),
    };
    if (type != null && type.startsWith('uint')) {
      final bits = type == 'uint' ? 256 : int.tryParse(type.substring(4));
      final n = BigInt.tryParse(text);
      if (bits != null && n != null && EvmHex.isUnlimitedForBits(n, bits)) {
        return 'Unlimited';
      }
    }
    if (text.length > _maxValueLength) {
      text = '${text.substring(0, _maxValueLength)}…';
    }
    return text;
  }

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is String) {
      if (v.startsWith('0x')) return int.tryParse(v.substring(2), radix: 16);
      return int.tryParse(v);
    }
    return null;
  }
}
