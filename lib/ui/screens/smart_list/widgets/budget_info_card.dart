import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/data/models/shopping_list.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.list.budget.toStringAsFixed(2));
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(BudgetInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.list.budget != oldWidget.list.budget && !_isEditing) {
      _controller.text = widget.list.budget.toStringAsFixed(2);
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
      _controller.text = widget.list.budget.toStringAsFixed(2);
    });
    _focusNode.requestFocus();
  }

  void _save() {
    // Handle PT-BR number format: remove thousand separators (.), replace decimal separator (,) with (.)
    String cleanText = _controller.text.replaceAll('.', '').replaceAll(',', '.');
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
                'Total Atual',
                style: TextStyle(
                  fontSize: 12,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'R\$ ${widget.list.totalSpent.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),

          // Limite Section
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Limite',
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
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: limitColor,
                            ),
                            decoration: const InputDecoration(
                              prefixText: 'R\$ ',
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                            'R\$ ${widget.list.budget.toStringAsFixed(2)}',
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
