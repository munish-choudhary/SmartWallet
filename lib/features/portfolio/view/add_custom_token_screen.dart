import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/lexor_page_scaffold.dart';
import '../../../core/design_system/lexor_palette.dart';
import '../view_model/add_custom_token_cubit.dart';

class AddCustomTokenScreen extends StatefulWidget {
  const AddCustomTokenScreen({super.key});

  @override
  State<AddCustomTokenScreen> createState() => _AddCustomTokenScreenState();
}

class _AddCustomTokenScreenState extends State<AddCustomTokenScreen> {
  static const _networks = ['ERC-20', 'BEP-20', 'Polygon', 'Arbitrum', 'Base'];

  final _address = TextEditingController();
  final _symbol = TextEditingController();
  final _decimals = TextEditingController(text: '18');
  String _network = _networks.first;

  @override
  void dispose() {
    _address.dispose();
    _symbol.dispose();
    _decimals.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: LexorPalette.textSecondary),
        filled: true,
        fillColor: LexorPalette.cardSolid,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddCustomTokenCubit, AddCustomTokenState>(
      listener: (context, state) {
        if (state is AddTokenSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${state.symbol} added')),
          );
          context.pop();
        }
      },
      builder: (context, state) {
        final saving = state is AddTokenEditing && state.saving;
        final error = state is AddTokenEditing ? state.error : null;
        const text = TextStyle(color: LexorPalette.textPrimary);
        return LexorPageScaffold(
          title: 'Add Custom Token',
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _network,
                dropdownColor: LexorPalette.cardSolid,
                style: text,
                decoration: _decoration('Network'),
                items: [
                  for (final n in _networks)
                    DropdownMenuItem(value: n, child: Text(n)),
                ],
                onChanged: (v) => setState(() => _network = v ?? _network),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _address,
                style: text,
                autocorrect: false,
                decoration: _decoration('Contract address (0x…)'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _symbol,
                style: text,
                textCapitalization: TextCapitalization.characters,
                decoration: _decoration('Token symbol'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _decimals,
                style: text,
                keyboardType: TextInputType.number,
                decoration: _decoration('Decimals'),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: LexorPalette.accent,
                  foregroundColor: LexorPalette.onAccent,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: saving
                    ? null
                    : () => context.read<AddCustomTokenCubit>().save(
                          network: _network,
                          contractAddress: _address.text,
                          symbol: _symbol.text,
                          decimals: _decimals.text,
                        ),
                child: saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add Token'),
              ),
            ],
          ),
        );
      },
    );
  }
}
