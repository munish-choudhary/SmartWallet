import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design_system/lexor_card.dart';
import '../../../core/design_system/lexor_page_scaffold.dart';
import '../../../core/design_system/lexor_palette.dart';
import '../view_model/manage_tokens_cubit.dart';
import '../view_model/manage_tokens_state.dart';

class ManageTokenListScreen extends StatelessWidget {
  const ManageTokenListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LexorPageScaffold(
      title: 'Manage Token List',
      trailing: IconButton(
        tooltip: 'Add custom token',
        icon: const Icon(Icons.add_rounded, color: LexorPalette.accent),
        onPressed: () => context.push(Routes.addCustomToken),
      ),
      child: BlocBuilder<ManageTokensCubit, ManageTokensState>(
        builder: (context, state) {
          if (state is ManageTokensLoading) {
            return const Center(
              child: CircularProgressIndicator(color: LexorPalette.accent),
            );
          }
          final tokens = state.filtered;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  onChanged: context.read<ManageTokensCubit>().setQuery,
                  style: const TextStyle(color: LexorPalette.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search token name or symbol',
                    hintStyle: const TextStyle(
                      color: LexorPalette.textSecondary,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: LexorPalette.textSecondary,
                    ),
                    filled: true,
                    fillColor: LexorPalette.cardSolid,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: tokens.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching tokens',
                          style: TextStyle(color: LexorPalette.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
                        itemCount: tokens.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final t = tokens[i];
                          return LexorCard(
                            radius: 16,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      Color(t.iconBgColor).withValues(alpha: 0.2),
                                  child: Text(
                                    t.symbol.characters.first,
                                    style: TextStyle(
                                      color: Color(t.iconBgColor),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.name,
                                        style: const TextStyle(
                                          color: LexorPalette.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${t.formattedBalance} ${t.symbol}',
                                        style: const TextStyle(
                                          color: LexorPalette.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: !t.isHidden,
                                  activeThumbColor: LexorPalette.onAccent,
                                  activeTrackColor: LexorPalette.accent,
                                  onChanged: (_) => context
                                      .read<ManageTokensCubit>()
                                      .toggleHidden(t.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
