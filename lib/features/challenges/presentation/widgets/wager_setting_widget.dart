import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WagerSettingWidget extends StatefulWidget {
  const WagerSettingWidget({
    required this.wagerAmount,
    required this.onWagerChanged,
    this.currency = 'USD',
    this.minAmount = 0.0,
    this.maxAmount = 1000.0,
    super.key,
  });

  final double? wagerAmount;
  final ValueChanged<double?> onWagerChanged;
  final String currency;
  final double minAmount;
  final double maxAmount;

  @override
  State<WagerSettingWidget> createState() => _WagerSettingWidgetState();
}

class _WagerSettingWidgetState extends State<WagerSettingWidget> {
  late TextEditingController _controller;
  late bool _hasWager;

  @override
  void initState() {
    super.initState();
    _hasWager = true; // Always require a wager
    _controller = TextEditingController(
      text: widget.wagerAmount != null && widget.wagerAmount! > 0 
          ? widget.wagerAmount!.toStringAsFixed(2) 
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateWager() {
    if (!_hasWager) {
      widget.onWagerChanged(null);
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) {
      widget.onWagerChanged(null);
      return;
    }

    final amount = double.tryParse(text);
    if (amount != null && amount >= widget.minAmount && amount <= widget.maxAmount) {
      widget.onWagerChanged(amount);
    }
  }

  void _setPresetAmount(double amount) {
    setState(() {
      _hasWager = true;
      _controller.text = amount.toStringAsFixed(2);
    });
    widget.onWagerChanged(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Wager Amount',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Set how much you\'re willing to risk for not completing your goals. You only keep your wager if you achieve 100% completion.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),

            // Wager Amount Input
            Text(
              'Enter Amount',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      prefixText: '\$',
                      hintText: '0.00',
                      border: const OutlineInputBorder(),
                      suffixText: widget.currency,
                    ),
                    onChanged: (_) => _updateWager(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Preset Amounts
            Text(
              'Quick Amounts',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                  _PresetChip(
                    amount: 0,
                    onTap: () => _setPresetAmount(0),
                    isSelected: _controller.text == '0.00',
                  ),
                  _PresetChip(
                    amount: 5,
                    onTap: () => _setPresetAmount(5),
                    isSelected: _controller.text == '5.00',
                  ),
                  _PresetChip(
                    amount: 10,
                    onTap: () => _setPresetAmount(10),
                    isSelected: _controller.text == '10.00',
                  ),
                  _PresetChip(
                    amount: 20,
                    onTap: () => _setPresetAmount(20),
                    isSelected: _controller.text == '20.00',
                  ),
                  _PresetChip(
                    amount: 50,
                    onTap: () => _setPresetAmount(50),
                    isSelected: _controller.text == '50.00',
                  ),
                  _PresetChip(
                    amount: 100,
                    onTap: () => _setPresetAmount(100),
                    isSelected: _controller.text == '100.00',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Motivation Tips
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tip',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose an amount that motivates you but won\'t cause financial stress. Research shows that stakes around \$20-50 are effective for most people.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.amount,
    required this.onTap,
    required this.isSelected,
  });

  final double amount;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Text(
          '\$${amount.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected 
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }
}