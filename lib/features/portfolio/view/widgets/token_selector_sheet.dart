import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/models/token_asset.dart';

class TokenSelectorSheet extends StatefulWidget {
  const TokenSelectorSheet({
    super.key,
    required this.tokens,
    required this.selectedToken,
    required this.onTokenSelected,
  });

  final List<TokenAsset> tokens;
  final TokenAsset selectedToken;
  final ValueChanged<TokenAsset> onTokenSelected;

  @override
  State<TokenSelectorSheet> createState() => _TokenSelectorSheetState();
}

class _TokenSelectorSheetState extends State<TokenSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTokens = widget.tokens.where((token) {
      if (_query.trim().isEmpty) return true;
      final q = _query.toLowerCase();
      return token.name.toLowerCase().contains(q) ||
          token.symbol.toLowerCase().contains(q);
    }).toList();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          height: 520,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF131317),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Token',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  Material(
                    color: const Color(0xFF353439),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Color(0xFFE4E1E7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search field
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F23),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: Color(0xFFC6C6C7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search by token or address',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFC6C8B2),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _query = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Popular tokens chips row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.tokens.map((token) {
                    final isSelected = token.id == widget.selectedToken.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          widget.onTokenSelected(token);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFD4EE6B)
                                : const Color(0xFF1F1F23),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFD4EE6B)
                                  : const Color.fromRGBO(255, 255, 255, 0.05),
                            ),
                          ),
                          child: Text(
                            token.symbol,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF181E00)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Token List
              Expanded(
                child: ListView.separated(
                  itemCount: filteredTokens.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final token = filteredTokens[index];
                    final isSelected = token.id == widget.selectedToken.id;

                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color.fromRGBO(212, 238, 107, 0.1)
                            : const Color(0xFF1F1F23),
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(color: const Color(0xFFD4EE6B))
                            : null,
                      ),
                      child: ListTile(
                        onTap: () {
                          widget.onTokenSelected(token);
                          Navigator.of(context).pop();
                        },
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFF353439),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.diamond_outlined,
                              size: 18,
                              color: Color(token.iconBgColor),
                            ),
                          ),
                        ),
                        title: Text(
                          token.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          token.network,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFC6C8B2),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              token.formattedBalance,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              token.formattedFiatValue,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFC6C6C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
