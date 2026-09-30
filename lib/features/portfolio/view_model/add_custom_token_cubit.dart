import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../data/models/token_asset.dart';
import '../data/portfolio_repository.dart';

sealed class AddCustomTokenState {
  const AddCustomTokenState();
}

class AddTokenEditing extends AddCustomTokenState {
  const AddTokenEditing({this.saving = false, this.error});

  final bool saving;
  final String? error;
}

class AddTokenSaved extends AddCustomTokenState {
  const AddTokenSaved(this.symbol);

  final String symbol;
}

class AddCustomTokenCubit extends Cubit<AddCustomTokenState> {
  AddCustomTokenCubit({required PortfolioRepository repository})
      : _repository = repository,
        super(const AddTokenEditing());

  final PortfolioRepository _repository;

  static final _evmAddress = RegExp(r'^0x[0-9a-fA-F]{40}$');

  Future<void> save({
    required String network,
    required String contractAddress,
    required String symbol,
    required String decimals,
  }) async {
    final address = contractAddress.trim();
    final sym = symbol.trim().toUpperCase();
    final dec = int.tryParse(decimals.trim());

    if (!_evmAddress.hasMatch(address)) {
      return emit(const AddTokenEditing(error: 'Enter a valid contract address'));
    }
    if (sym.isEmpty || sym.length > 11) {
      return emit(const AddTokenEditing(error: 'Enter a token symbol'));
    }
    if (dec == null || dec < 0 || dec > 36) {
      return emit(const AddTokenEditing(error: 'Decimals must be 0–36'));
    }

    emit(const AddTokenEditing(saving: true));
    final result = await _repository.addCustomToken(
      TokenAsset(
        id: '${network.toLowerCase()}:${address.toLowerCase()}',
        name: sym,
        symbol: sym,
        network: network,
        balance: 0,
        priceUsd: 0,
        change24h: 0,
        iconBgColor: 0xFF8E8EA0,
        contractAddress: address,
        marketCap: '--',
        volume24h: '--',
        sparklinePoints: const [],
      ),
    );
    switch (result) {
      case Ok():
        emit(AddTokenSaved(sym));
      case Err(:final failure):
        emit(AddTokenEditing(
          error: switch (failure) {
            UnknownFailure(:final message) => message,
            _ => 'Could not add token',
          },
        ));
    }
  }
}
