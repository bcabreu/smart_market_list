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
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  String _formatBudget(double value) {
    return _numberFormat.format(value);
  }

  @override
  void didUpdateWidget(BudgetInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No need to update controller - modal sets its own value
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Focus handling is now managed by modal
  }

  void _showBudgetModal() {
    final locale = Localizations.localeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final currencySymbol = locale.languageCode == 'pt' ? 'R\$' : '\$';
    
    // Clear controller so placeholder shows current value
    _controller.clear();
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.budgetLimit,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          widget.list.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Budget Input
              Row(
                children: [
                  Text(
                    currencySymbol,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [CurrencyInputFormatter(locale: locale.toString())],
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: _formatBudget(widget.list.budget),
                        hintStyle: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _save();
                        Navigator.pop(dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Salvar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

  void _startEditing() {
    _showBudgetModal();
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
              InkWell(
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
