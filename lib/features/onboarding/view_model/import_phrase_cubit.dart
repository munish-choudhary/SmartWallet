import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/result/result.dart';
import '../../../core/vault/vault.dart';
import '../data/bip39_wordlist.dart';

part 'import_phrase_cubit.freezed.dart';

@freezed
sealed class ImportPhraseState with _$ImportPhraseState {
  const factory ImportPhraseState({
    @Default(12) int wordCount,
    @Default(<String>[]) List<String> words,
    @Default(<int>{}) Set<int> invalidIndices,
    @Default(false) bool checksumValid,
    @Default(false) bool validating,
  }) = _ImportPhraseState;
}

/// Normalizes as-typed (trim, lowercase, collapse internal whitespace)
/// per this feature's import-phrase validation spec.
String normalizeWord(String raw) => raw.trim().toLowerCase();

class ImportPhraseCubit extends Cubit<ImportPhraseState> {
  ImportPhraseCubit({required this.vault, required this.wordlist})
    : super(ImportPhraseState(words: List.filled(12, '')));

  final Vault vault;
  final Bip39Wordlist wordlist;

  void setWordCount(int count) {
    assert(count == 12 || count == 24, 'count must be 12 or 24');
    emit(
      ImportPhraseState(wordCount: count, words: List.filled(count, '')),
    );
  }

  void setWord(int index, String value) {
    final words = [...state.words];
    words[index] = normalizeWord(value);
    _revalidate(words);
  }

  void pasteAll(String text) {
    final parts = normalizeWord(text).split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    final words = List<String>.filled(state.wordCount, '');
    for (var i = 0; i < parts.length && i < words.length; i++) {
      words[i] = parts[i];
    }
    _revalidate(words);
  }

  void clear() =>
      emit(ImportPhraseState(wordCount: state.wordCount, words: List.filled(state.wordCount, '')));

  List<String> suggestionsFor(int index) {
    if (index < 0 || index >= state.words.length) return const [];
    return wordlist.suggestionsFor(state.words[index]);
  }

  void _revalidate(List<String> words) {
    final invalid = <int>{
      for (var i = 0; i < words.length; i++)
        if (words[i].isNotEmpty && !wordlist.contains(words[i])) i,
    };
    emit(
      state.copyWith(words: words, invalidIndices: invalid, checksumValid: false),
    );
    final complete = invalid.isEmpty && words.every((w) => w.isNotEmpty);
    if (complete) _checkFull(words);
  }

  Future<void> _checkFull(List<String> words) async {
    emit(state.copyWith(validating: true));
    final result = await vault.validateMnemonic(words.join(' '));
    if (state.words.join(' ') != words.join(' ')) {
      return; // input changed again while validating; ignore stale result
    }
    emit(state.copyWith(validating: false, checksumValid: result.isOk));
  }

  bool get isValid => state.checksumValid;

  String get joinedMnemonic => state.words.join(' ');
}
