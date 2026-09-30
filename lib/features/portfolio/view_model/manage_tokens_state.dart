import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/models/token_asset.dart';

part 'manage_tokens_state.freezed.dart';

@freezed
sealed class ManageTokensState with _$ManageTokensState {
  const ManageTokensState._();

  const factory ManageTokensState.loading() = ManageTokensLoading;
  const factory ManageTokensState.loaded({
    required List<TokenAsset> assets,
    @Default('') String query,
  }) = ManageTokensLoaded;

  List<TokenAsset> get filtered => switch (this) {
        ManageTokensLoaded(:final assets, :final query) => assets.where((a) {
            final q = query.trim().toLowerCase();
            return q.isEmpty ||
                a.name.toLowerCase().contains(q) ||
                a.symbol.toLowerCase().contains(q);
          }).toList(),
        _ => const [],
      };
}
