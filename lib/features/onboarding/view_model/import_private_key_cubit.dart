import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/result/result.dart';
import '../../../core/vault/vault.dart';

part 'import_private_key_cubit.freezed.dart';

@freezed
sealed class ImportPrivateKeyState with _$ImportPrivateKeyState {
  const factory ImportPrivateKeyState({
    @Default(CoinType.ethereum) CoinType network,
    @Default('') String rawKey,
    @Default(false) bool obscured,
    @Default(false) bool formatValid,
    @Default(false) bool validating,
  }) = _ImportPrivateKeyState;
}

class ImportPrivateKeyCubit extends Cubit<ImportPrivateKeyState> {
  ImportPrivateKeyCubit({required this.vault})
    : super(const ImportPrivateKeyState(obscured: true));

  final Vault vault;

  void setNetwork(CoinType network) {
    emit(state.copyWith(network: network));
    _revalidate(state.rawKey, network);
  }

  void setRawKey(String value) {
    emit(state.copyWith(rawKey: value));
    _revalidate(value, state.network);
  }

  void toggleObscured() => emit(state.copyWith(obscured: !state.obscured));

  Future<void> _revalidate(String key, CoinType network) async {
    if (key.isEmpty) {
      emit(state.copyWith(formatValid: false));
      return;
    }
    emit(state.copyWith(validating: true));
    final result = await vault.validatePrivateKey(key, network.chainFamily);
    if (state.rawKey != key || state.network != network) return; // stale
    emit(state.copyWith(validating: false, formatValid: result.isOk));
  }

  bool get isValid => state.formatValid;
}
