import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/models/token_asset.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import 'widgets/portfolio_ambient_background.dart';
import 'widgets/slippage_settings_sheet.dart';
import 'widgets/token_selector_sheet.dart';
import 'transaction_pending_screen.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({
    super.key,
    required this.allTokens,
    this.initialFromToken,
    this.initialToToken,
  });

  final List<TokenAsset> allTokens;
  final TokenAsset? initialFromToken;
  final TokenAsset? initialToToken;

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  late TokenAsset _fromToken;
  late TokenAsset _toToken;
  late final TextEditingController _amountController;

  double _slippage = 0.5;
  bool _mevProtection = true;
  final String _networkFee = '~\$4.20 (0.0012 ETH)';
  final String _route = 'Uniswap v3 (Direct)';

  @override
  void initState() {
    super.initState();
    _fromToken = widget.initialFromToken ??
        widget.allTokens.firstWhere(
          (t) => t.symbol == 'BTC',
          orElse: () => widget.allTokens.first,
        );
    _toToken = widget.initialToToken ??
        widget.allTokens.firstWhere(
          (t) => t.symbol == 'ETH',
          orElse: () => widget.allTokens.length > 1
              ? widget.allTokens[1]
              : widget.allTokens.first,
        );

    _amountController = TextEditingController(text: '1.04');
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _inputAmount => double.tryParse(_amountController.text) ?? 0.0;

  double get _exchangeRate {
    if (_toToken.priceUsd == 0) return 1.0;
    return _fromToken.priceUsd / _toToken.priceUsd;
  }

  double get _outputAmount => _inputAmount * _exchangeRate;

  void _invertTokens() {
    setState(() {
      final temp = _fromToken;
      _fromToken = _toToken;
      _toToken = temp;
    });
  }

  void _showTokenSelector(bool isFrom) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => TokenSelectorSheet(
        tokens: widget.allTokens,
        selectedToken: isFrom ? _fromToken : _toToken,
        onTokenSelected: (token) {
          setState(() {
            if (isFrom) {
              if (token.id == _toToken.id) {
                _toToken = _fromToken;
              }
              _fromToken = token;
            } else {
              if (token.id == _fromToken.id) {
                _fromToken = _toToken;
              }
              _toToken = token;
            }
          });
        },
      ),
    );
  }

  void _showSlippageSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SlippageSettingsSheet(
        initialSlippage: _slippage,
        initialMevProtection: _mevProtection,
        onSettingsSaved: (slip, mev) {
          setState(() {
            _slippage = slip;
            _mevProtection = mev;
          });
        },
      ),
    );
  }

  void _showAiAssistant() => context.push(Routes.aiAssistant);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131317),
      body: PortfolioAmbientBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Scrollable Swap Content
              SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: 72,
                  left: 20,
                  right: 20,
                  bottom: 120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar Header inside content
                    _buildSubHeader(),
                    const SizedBox(height: 12),

                    // Cards Container with Overlapping Switch Button
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          children: [
                            // FROM Card
                            _buildFromCard(),
                            const SizedBox(height: 8),
                            // TO Card
                            _buildToCard(),
                          ],
                        ),

                        // Overlapping Invert Switch Button
                        Positioned(
                          child: GestureDetector(
                            onTap: _invertTokens,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD4EE6B),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(212, 238, 107, 0.45),
                                    blurRadius: 24,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.swap_vert_rounded,
                                  size: 24,
                                  color: Color(0xFF181E00),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Route / Rate Summary Card
                    _buildRouteSummaryCard(),
                    const SizedBox(height: 16),

                    // Primary Swap Action CTA
                    _buildPrimaryCta(),
                    const SizedBox(height: 16),

                    // Market Sentiment Quick Pulse
                    _buildSentimentCard(),
                  ],
                ),
              ),

              // Fixed Top Navigation Header Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(),
              ),

              // Floating AI Swap Assistant Button (bottom right)
              Positioned(
                right: 20,
                bottom: 32,
                child: _buildFloatingAiButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(19, 19, 23, 0.8),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.04),
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 22,
                            color: Color(0xFFE4E1E7),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Instant Swap',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Gas status pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F23),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.local_gas_station_rounded,
                          size: 14,
                          color: Color(0xFFD4EE6B),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '18 Gwei',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.44,
                            color: Color(0xFFE4E1E7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: const Color(0xFF1F1F23),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _showSlippageSettings,
                      child: const SizedBox(
                        width: 38,
                        height: 38,
                        child: Center(
                          child: Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: Color(0xFFE4E1E7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubHeader() {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFFD4EE6B),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0xFFD4EE6B),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'BEST ROUTE ACTIVE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.44,
            color: Color(0xFFC6C8B2),
          ),
        ),
      ],
    );
  }

  Widget _buildFromCard() {
    final fiatValue = _inputAmount * _fromToken.priceUsd;
    return Container(
      width: double.infinity,
      height: 174,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(42, 41, 46, 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.05),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Token selector pill
              GestureDetector(
                onTap: () => _showTokenSelector(true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(53, 52, 57, 0.8),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(_fromToken.iconBgColor),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _fromToken.symbol.substring(0, 1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _fromToken.symbol,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: Color(0xFFC6C8B2),
                      ),
                    ],
                  ),
                ),
              ),

              // Half & Max pills
              Row(
                children: [
                  _quickAmountPill(
                    'HALF',
                    () {
                      setState(() {
                        _amountController.text =
                            (_fromToken.balance / 2).toStringAsFixed(2);
                      });
                    },
                    isMax: false,
                  ),
                  const SizedBox(width: 6),
                  _quickAmountPill(
                    'MAX',
                    () {
                      setState(() {
                        _amountController.text =
                            _fromToken.balance.toStringAsFixed(2);
                      });
                    },
                    isMax: true,
                  ),
                ],
              ),
            ],
          ),

          // Amount Input field
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              color: Colors.white,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => setState(() {}),
          ),

          // Balance & USD value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance: ${_fromToken.formattedBalance} ${_fromToken.symbol}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.26,
                  color: Color(0xFFC6C8B2),
                ),
              ),
              Text(
                '\$${fiatValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.44,
                  color: Color(0xFFC6C6C7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToCard() {
    final fiatValue = _outputAmount * _toToken.priceUsd;
    return Container(
      width: double.infinity,
      height: 174,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(42, 41, 46, 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.05),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Token selector pill
              GestureDetector(
                onTap: () => _showTokenSelector(false),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(53, 52, 57, 0.8),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(_toToken.iconBgColor),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _toToken.symbol.substring(0, 1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _toToken.symbol,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: Color(0xFFC6C8B2),
                      ),
                    ],
                  ),
                ),
              ),

              // Estimated badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(14, 14, 18, 0.8),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: const Text(
                  'ESTIMATED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.44,
                    color: Color(0xFFC6C8B2),
                  ),
                ),
              ),
            ],
          ),

          // Amount output
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _outputAmount.toStringAsFixed(
                _outputAmount < 1 ? 4 : 2,
              ),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
                color: Colors.white,
              ),
            ),
          ),

          // Balance & USD value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance: ${_toToken.formattedBalance} ${_toToken.symbol}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.26,
                  color: Color(0xFFC6C8B2),
                ),
              ),
              Text(
                '\$${fiatValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.44,
                  color: Color(0xFFC6C6C7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(31, 31, 35, 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _summaryRow(
            label: 'Exchange Rate',
            value:
                '1 ${_fromToken.symbol} ≈ ${_exchangeRate.toStringAsFixed(2)} ${_toToken.symbol}',
            hasInfoIcon: true,
          ),
          const SizedBox(height: 10),
          _summaryRow(
            label: 'Best Route',
            value: _route,
            valueColor: const Color(0xFFD4EE6B),
            isLiveIndicator: true,
          ),
          const SizedBox(height: 10),
          _summaryRow(
            label: 'Slippage Tolerance',
            value: '$_slippage%',
          ),
          const SizedBox(height: 10),
          _summaryRow(
            label: 'Est. Network Fee',
            value: _networkFee,
          ),
          const SizedBox(height: 10),
          _summaryRow(
            label: 'Price Impact',
            value: '< 0.05% (Minimal)',
            valueColor: const Color(0xFFC6C8B2),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required String label,
    required String value,
    Color? valueColor,
    bool hasInfoIcon = false,
    bool isLiveIndicator = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.12,
            color: Color(0xFFC6C6C7),
          ),
        ),
        Row(
          children: [
            if (isLiveIndicator) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4EE6B),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.44,
                color: valueColor ?? const Color(0xFFFFFFFF),
              ),
            ),
            if (hasInfoIcon) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Color(0xFFC6C8B2),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPrimaryCta() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TransactionPendingScreen(
              amount: _outputAmount.toStringAsFixed(4),
              tokenSymbol: _toToken.symbol,
              amountUsd: (_outputAmount * _toToken.priceUsd).toStringAsFixed(2),
              recipient: 'Uniswap v3 Router',
              network: 'Ethereum Mainnet',
              estimatedTime: '~15 Seconds',
              gasTier: '18 Gwei',
            ),
          ),
        );
      },
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(9999),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(255, 255, 255, 0.18),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Review Swap',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: Color(0xFF1A1C1C),
              ),
            ),
            SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: Color(0xFF1A1C1C),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(27, 27, 31, 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 18,
                color: Color(0xFFD4EE6B),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Market Pulse: High ETH Liquidity',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.44,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Optimal time to execute swap',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.12,
                      color: Color(0xFFC6C8B2),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F23),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: const Text(
              '94%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.44,
                color: Color(0xFFD4EE6B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAmountPill(String label, VoidCallback onTap, {required bool isMax}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isMax
              ? const Color.fromRGBO(53, 52, 57, 0.9)
              : const Color.fromRGBO(53, 52, 57, 0.7),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.44,
            color: isMax ? const Color(0xFFD4EE6B) : const Color(0xFFC6C8B2),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingAiButton() {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: _showAiAssistant,
        child: Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Color(0xFF5B3E8C),
                Color(0xFFC8733A),
                Color(0xFFE4FF7A),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(212, 238, 107, 0.35),
                blurRadius: 28,
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color.fromRGBO(14, 14, 18, 0.9),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 24,
                color: Color(0xFFD4EE6B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
