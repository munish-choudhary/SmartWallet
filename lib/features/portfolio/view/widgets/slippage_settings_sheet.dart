import 'dart:ui';

import 'package:flutter/material.dart';

class SlippageSettingsSheet extends StatefulWidget {
  const SlippageSettingsSheet({
    super.key,
    this.initialSlippage = 0.5,
    this.initialMevProtection = true,
    required this.onSettingsSaved,
  });

  final double initialSlippage;
  final bool initialMevProtection;
  final void Function(double slippage, bool mevProtection) onSettingsSaved;

  @override
  State<SlippageSettingsSheet> createState() => _SlippageSettingsSheetState();
}

class _SlippageSettingsSheetState extends State<SlippageSettingsSheet> {
  late double _selectedSlippage;
  late bool _mevProtection;
  final TextEditingController _customController = TextEditingController();

  final List<double> _presets = const [0.1, 0.5, 1.0];

  @override
  void initState() {
    super.initState();
    _selectedSlippage = widget.initialSlippage;
    _mevProtection = widget.initialMevProtection;
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(53, 52, 57, 0.95),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.85),
                blurRadius: 48,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Swap Settings',
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
                      onTap: () {
                        widget.onSettingsSaved(_selectedSlippage, _mevProtection);
                        Navigator.of(context).pop();
                      },
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

              // Slippage Tolerance Section
              const Text(
                'Slippage Tolerance',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.12,
                  color: Color(0xFFC6C6C7),
                ),
              ),
              const SizedBox(height: 8),

              // Preset Buttons & Custom input
              Row(
                children: [
                  ..._presets.map((preset) {
                    final isSelected = _selectedSlippage == preset;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSlippage = preset;
                              _customController.clear();
                            });
                          },
                          child: Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFD4EE6B)
                                  : const Color(0xFF353439),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '$preset%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  letterSpacing: 0.44,
                                  color: isSelected
                                      ? const Color(0xFF181E00)
                                      : const Color(0xFFE4E1E7),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  Expanded(
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF353439),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: TextField(
                          controller: _customController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE4E1E7),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Custom',
                            hintStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9CA3AF),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val);
                            if (parsed != null && parsed > 0) {
                              setState(() {
                                _selectedSlippage = parsed;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // MEV Protection Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MEV Protection',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.26,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Guards against sandwich attacks',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.12,
                          color: Color(0xFFC6C8B2),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _mevProtection = !_mevProtection;
                      });
                    },
                    child: Container(
                      width: 48,
                      height: 28,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _mevProtection
                            ? const Color(0xFFD4EE6B)
                            : const Color(0xFF353439),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Align(
                        alignment: _mevProtection
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF181E00),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
