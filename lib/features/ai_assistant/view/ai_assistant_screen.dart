import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design_system/lexor_page_scaffold.dart';
import '../../../core/design_system/lexor_palette.dart';
import '../../portfolio/view/swap_screen.dart';
import '../data/ai_message.dart';
import '../view_model/ai_chat_cubit.dart';
import '../view_model/ai_chat_state.dart';
import 'widgets/ai_orb.dart';
import 'widgets/swap_quote_card.dart';

class AiAssistantScreen extends StatefulWidget {
  /// [tokenSymbol] pre-fills the input when opened from a token page.
  const AiAssistantScreen({super.key, this.tokenSymbol});

  final String? tokenSymbol;

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  static const _suggestions = [
    'Swap 500 USDC to SOL',
    'How is my portfolio doing?',
    'Set a price alert for ETH',
  ];

  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final symbol = widget.tokenSymbol;
    if (symbol != null && symbol.isNotEmpty) {
      _input.text = 'Tell me about $symbol';
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final value = text ?? _input.text;
    if (value.trim().isEmpty) return;
    context.read<AiChatCubit>().send(value);
    _input.clear();
  }

  Future<void> _reviewSwap(SwapQuote quote) async {
    final tokens = await context.read<AiChatCubit>().swapTokens();
    if (!mounted || tokens.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SwapScreen(allTokens: tokens, initialFromToken: quote.from),
      ),
    );
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LexorPalette.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const _Glows(),
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: _Header(onClear: context.read<AiChatCubit>().clear),
              ),
              Expanded(
                child: BlocConsumer<AiChatCubit, AiChatState>(
                  listener: (_, __) => _scrollToEnd(),
                  builder: (context, state) => switch (state) {
                    AiChatEmpty() => _Home(onPick: _send),
                    AiChatActive(:final messages) => _thread(messages, false),
                    AiChatResponding(:final messages) => _thread(
                      messages,
                      true,
                    ),
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: _InputDock(controller: _input, onSend: _send),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thread(List<AiMessage> messages, bool responding) {
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      itemCount: messages.length + (responding ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, i) {
        if (i == messages.length) {
          return const _AiRow(child: _Bubble(child: _Typing()));
        }
        return switch (messages[i]) {
          AiUserMessage(:final text) => _UserBubble(text: text),
          AiTextMessage(:final text) => _AiRow(
            child: _Bubble(child: _BubbleText(text)),
          ),
          AiSwapMessage(:final intro, :final quote) => _AiRow(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Bubble(child: _BubbleText(intro)),
                const SizedBox(height: 16),
                SwapQuoteCard(quote: quote, onReview: () => _reviewSwap(quote)),
              ],
            ),
          ),
        };
      },
    );
  }
}

class _Glows extends StatelessWidget {
  const _Glows();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -64,
            child: _glow(320, const Color.fromRGBO(213, 187, 255, 0.1)),
          ),
          Positioned(
            left: -64,
            bottom: 160,
            child: _glow(224, LexorPalette.glowLime),
          ),
        ],
      ),
    );
  }

  Widget _glow(double size, Color color) => ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color.fromRGBO(19, 19, 23, 0.8),
      child: Row(
        children: [
          const LexorBackButton(),
          const SizedBox(width: 8),
          const Text(
            'Lexor AI',
            style: TextStyle(
              color: LexorPalette.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: LexorPalette.accent,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: const Text(
              'BETA',
              style: TextStyle(
                color: Color(0xFF596C00),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.44,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'New chat',
            onPressed: onClear,
            icon: const Icon(
              Icons.add_comment_outlined,
              size: 20,
              color: LexorPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Column(
        children: [
          const AiOrb(size: 112, glow: true),
          const SizedBox(height: 24),
          const Text(
            'How can I help?',
            style: TextStyle(
              color: LexorPalette.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask about your portfolio or prepare a swap.\n'
            'Nothing is signed without your review.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LexorPalette.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          for (final s in _AiAssistantScreenState._suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: LexorPalette.card,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onPick(s),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: LexorPalette.accent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s,
                            style: const TextStyle(
                              color: LexorPalette.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 287),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(53, 52, 57, 0.8),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: LexorPalette.textPrimary,
              fontSize: 14,
              height: 1.43,
            ),
          ),
        ),
      ),
    );
  }
}

class _AiRow extends StatelessWidget {
  const _AiRow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AiOrb(),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(31, 31, 35, 0.7),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: child,
    );
  }
}

class _BubbleText extends StatelessWidget {
  const _BubbleText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: LexorPalette.textPrimary,
      fontSize: 14,
      height: 1.6,
    ),
  );
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color: LexorPalette.accent,
    ),
  );
}

class _InputDock extends StatelessWidget {
  const _InputDock({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 56,
            padding: const EdgeInsets.only(left: 20, right: 8),
            color: const Color.fromRGBO(42, 41, 46, 0.85),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    style: const TextStyle(
                      color: LexorPalette.textPrimary,
                      fontSize: 14,
                    ),
                    cursorColor: LexorPalette.accent,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Ask Lexor anything…',
                      hintStyle: TextStyle(
                        color: Color.fromRGBO(198, 200, 178, 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Material(
                  color: LexorPalette.accent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onSend,
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 18,
                        color: Color(0xFF596C00),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
