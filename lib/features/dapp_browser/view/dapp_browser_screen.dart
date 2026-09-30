import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design_system/dapp_icon.dart';
import '../../../core/design_system/lexor_card.dart';
import '../../../core/design_system/lexor_page_scaffold.dart';
import '../../../core/design_system/lexor_palette.dart';
import '../data/browser_url_resolver.dart';
import '../data/models/dapp.dart';
import '../view_model/dapp_browser_cubit.dart';
import '../view_model/dapp_browser_state.dart';
import 'widgets/dapp_tile.dart';

/// dApp discovery: search/enter a URL, browse curated dApps, revisit recents.
class DappBrowserScreen extends StatefulWidget {
  const DappBrowserScreen({super.key});

  @override
  State<DappBrowserScreen> createState() => _DappBrowserScreenState();
}

class _DappBrowserScreenState extends State<DappBrowserScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(Uri uri) => context.push(Routes.dappBrowsePath(uri.toString()));

  void _submit(String text) {
    final resolved = context.read<DappBrowserCubit>().resolve(text);
    switch (resolved) {
      case ResolvedUrl(:final uri) || ResolvedSearch(:final uri):
        _search.clear();
        _open(uri);
      case RejectedInput(:final reason):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reason)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LexorPageScaffold(
      title: 'dApps',
      trailing: LexorHeaderAction(
        icon: Icons.link_rounded,
        semanticLabel: 'WalletConnect',
        onPressed: () => context.push(Routes.walletConnect),
      ),
      child: BlocBuilder<DappBrowserCubit, DappBrowserState>(
        builder: (context, state) => switch (state) {
          DappBrowserLoading() => const Center(
              child: CircularProgressIndicator(color: LexorPalette.accent),
            ),
          DappBrowserFailure() => const Center(
              child: Text(
                "Couldn't load dApps.",
                style: TextStyle(color: LexorPalette.textSecondary),
              ),
            ),
          DappBrowserLoaded() => _Loaded(
              state: state,
              search: _search,
              onSubmit: _submit,
              onOpen: _open,
            ),
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.state,
    required this.search,
    required this.onSubmit,
    required this.onOpen,
  });

  final DappBrowserLoaded state;
  final TextEditingController search;
  final ValueChanged<String> onSubmit;
  final ValueChanged<Uri> onOpen;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DappBrowserCubit>();
    final favorites = state.favorites;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
      children: [
        _SearchField(controller: search, onSubmit: onSubmit),
        const SizedBox(height: 16),
        _CategoryChips(
          selected: state.category,
          onSelected: cubit.selectCategory,
        ),
        if (favorites.isNotEmpty && state.category == null) ...[
          const SizedBox(height: 24),
          const LexorSectionLabel('Favorites'),
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, i) => _FavoriteItem(
                dapp: favorites[i],
                onTap: () => onOpen(Uri.parse(favorites[i].url)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        LexorSectionLabel(
          state.category == null ? 'Featured' : state.category!.label,
        ),
        const SizedBox(height: 12),
        for (final dapp in state.visible) ...[
          DappTile(
            dapp: dapp,
            isFavorite: state.favoriteIds.contains(dapp.id),
            onOpen: () => onOpen(Uri.parse(dapp.url)),
            onToggleFavorite: () => cubit.toggleFavorite(dapp.id),
          ),
          const SizedBox(height: 10),
        ],
        if (state.recents.isNotEmpty && state.category == null) ...[
          const SizedBox(height: 14),
          LexorSectionLabel(
            'Recent',
            trailing: TextButton(
              onPressed: cubit.clearRecents,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Clear',
                style: TextStyle(color: LexorPalette.accent, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final visit in state.recents.take(8))
            _RecentRow(
              host: visit.host,
              title: visit.title,
              onTap: () => onOpen(Uri.parse(visit.url)),
            ),
        ],
        const SizedBox(height: 24),
        const _WarningNote(),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmit,
      textInputAction: TextInputAction.go,
      keyboardType: TextInputType.url,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(color: LexorPalette.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Search or enter a web address',
        hintStyle: const TextStyle(color: LexorPalette.textDisabled),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: LexorPalette.textSecondary,
        ),
        filled: true,
        fillColor: LexorPalette.card,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final DappCategory? selected;
  final ValueChanged<DappCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, DappCategory? value) {
      final active = selected == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: active,
          onSelected: (_) => onSelected(value),
          showCheckmark: false,
          labelStyle: TextStyle(
            color: active ? LexorPalette.onAccent : LexorPalette.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          backgroundColor: LexorPalette.chip,
          selectedColor: LexorPalette.accent,
          side: BorderSide.none,
          shape: const StadiumBorder(),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('All', null),
          for (final category in DappCategory.values)
            chip(category.label, category),
        ],
      ),
    );
  }
}

class _FavoriteItem extends StatelessWidget {
  const _FavoriteItem({required this.dapp, required this.onTap});

  final Dapp dapp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            DappIcon(name: dapp.name, brandColor: dapp.brandColor, size: 52),
            const SizedBox(height: 8),
            Text(
              dapp.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LexorPalette.textPrimary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.host,
    required this.title,
    required this.onTap,
  });

  final String host;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            const Icon(
              Icons.history_rounded,
              size: 18,
              color: LexorPalette.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? host : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LexorPalette.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  if (title.isNotEmpty)
                    Text(
                      host,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LexorPalette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.north_west_rounded,
              size: 16,
              color: LexorPalette.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningNote extends StatelessWidget {
  const _WarningNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(42, 41, 46, 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.gpp_maybe_outlined,
              size: 17.5,
              color: Color(0xFF8E9079),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'dApps are third-party websites. Always check the address '
              'before connecting your wallet, and never enter your '
              'recovery phrase on a website.',
              style: TextStyle(
                color: LexorPalette.textSecondary,
                fontSize: 12,
                letterSpacing: 0.12,
                height: 16 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
