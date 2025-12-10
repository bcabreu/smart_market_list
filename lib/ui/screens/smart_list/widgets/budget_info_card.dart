import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/core/utils/currency_input_formatter.dart';
import 'package:smart_market_list/data/models/shopping_list.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:intl/intl.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';

import 'package:smart_market_list/providers/tax_provider.dart';

class BudgetInfoCard extends ConsumerStatefulWidget {
  final ShoppingList list;
  
  const BudgetInfoCard({super.key, required this.list});

  @override
  ConsumerState<BudgetInfoCard> createState() => _BudgetInfoCardState();
}


class _BudgetInfoCardState extends ConsumerState<BudgetInfoCard> {
  bool _isEditing = false;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  
  // These will be initialized in build or didChangeDependencies to respect locale
  late NumberFormat _currencyFormat;
  late NumberFormat _numberFormat;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    final symbol = locale.languageCode == 'pt' ? 'R\$' : '\$';
    _currencyFormat = NumberFormat.currency(locale: locale.toString(), symbol: symbol);
    _numberFormat = NumberFormat.decimalPattern(locale.toString());
    
    // Update controller text if not editing, to reflect new locale format
    if (!_isEditing) {
        _controller = TextEditingController(text: _formatBudget(widget.list.budget));
    }
  }

  @override
  void initState() {
    super.initState();
    // Controller will be re-initialized in didChangeDependencies
    _controller = TextEditingController(text: ''); 
    _focusNode.addListener(_onFocusChange);
  }

  String _formatBudget(double value) {
    return _numberFormat.format(value);
  }

  @override
  void didUpdateWidget(BudgetInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.list.budget != oldWidget.list.budget && !_isEditing) {
      _controller.text = _formatBudget(widget.list.budget);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _save();
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _controller.text = _formatBudget(widget.list.budget);
    });
    _focusNode.requestFocus();
  }

  void _save() {
    final locale = Localizations.localeOf(context);
    String cleanText = _controller.text;
    
    if (locale.languageCode == 'pt') {
        cleanText = cleanText.replaceAll('.', '').replaceAll(',', '.');
    } else {
        cleanText = cleanText.replaceAll(',', '');
    }

    final newBudget = double.tryParse(cleanText) ?? widget.list.budget;
    
    if (newBudget != widget.list.budget) {
      final service = ref.read(shoppingListServiceProvider);
      // Create a copy with the new budget and update
      final updatedList = widget.list.copyWith(budget: newBudget);
      service.updateList(updatedList);
    }

    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    
    final cardColor = isDark 
        ? const Color(0xFF1E2C2C)
        : const Color(0xFFE0F7FA).withOpacity(0.5);
    final borderColor = isDark
        ? const Color(0xFF2C4A4A)
        : const Color(0xFFB2EBF2);
    
    final labelColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final valueColor = AppColors.primary;
    final limitColor = isDark ? Colors.white : Colors.black87;

    return Container(
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Total Atual Section
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.currentTotal,
                style: TextStyle(
                  fontSize: 12,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 2),
              Consumer(
                builder: (context, ref, child) {
                  final taxRate = ref.watch(taxRateProvider);
                  final taxAmount = widget.list.totalSpent * (taxRate / 100);
                  final totalWithTax = widget.list.totalSpent + taxAmount;
                  
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: totalWithTax),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      final isOverBudget = widget.list.budget > 0 && value > widget.list.budget;
                      final color = isOverBudget ? const Color(0xFFEF5350) : valueColor;

                      if (taxRate > 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currencyFormat.format(value),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: color,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              '${_currencyFormat.format(widget.list.totalSpent)} + ${taxRate.toStringAsFixed(1)}% Tax',
                              style: TextStyle(
                                fontSize: 10,
                                color: labelColor,
                              ),
                            ),
                          ],
                        );
                      }

                      return Text(
                        _currencyFormat.format(value),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: color,
                          letterSpacing: -1,
                        ),
                      );
                    },
                  );
                }
              ),
            ],
          ),

          // Limite Section
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.budgetLimit,
                style: TextStyle(
                  fontSize: 12,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 2),
              _isEditing
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [CurrencyInputFormatter(locale: locale.toString())],
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: limitColor,
                            ),
                            decoration: InputDecoration(
                              prefixText: locale.languageCode == 'pt' ? 'R\$ ' : '\$ ',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: Colors.grey, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: Colors.grey, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                            onSubmitted: (_) => _save(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _save,
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 24,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : InkWell(
                      onTap: _startEditing,
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currencyFormat.format(widget.list.budget),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: limitColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: labelColor,
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
