import 'package:flutter/services.dart' show rootBundle;

/// Loads and caches the bundled BIP-39 English wordlist
/// (`assets/bip39/english.txt`, the canonical 2048-word list). Used by
/// [FakeVault] for word validation/suggestions and by the import-phrase
/// screen for autocomplete chips.
final class Bip39Wordlist {
  Bip39Wordlist._(this.words) : _indexByWord = {
    for (var i = 0; i < words.length; i++) words[i]: i,
  };

  final List<String> words;
  final Map<String, int> _indexByWord;

  static Bip39Wordlist? _cached;

  static Future<Bip39Wordlist> load() async {
    final cached = _cached;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/bip39/english.txt');
    final words = raw
        .split('\n')
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList(growable: false);
    final loaded = Bip39Wordlist._(words);
    _cached = loaded;
    return loaded;
  }

  bool contains(String word) => _indexByWord.containsKey(word);

  /// The word's 0-2047 index in the canonical list, or null if not found.
  int? indexOf(String word) => _indexByWord[word];

  /// Up to [limit] words starting with [prefix], for autocomplete chips.
  List<String> suggestionsFor(String prefix, {int limit = 5}) {
    if (prefix.isEmpty) return const [];
    final matches = <String>[];
    for (final word in words) {
      if (word.startsWith(prefix)) {
        matches.add(word);
        if (matches.length >= limit) break;
      }
    }
    return matches;
  }
}
