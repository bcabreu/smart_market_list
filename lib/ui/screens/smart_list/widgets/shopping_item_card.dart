import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';

class ShoppingItemCard extends ConsumerStatefulWidget {
  final ShoppingItem item;
  final Function(bool) onCheckChanged;
  final Function(double) onPriceChanged;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ShoppingItemCard({
    super.key,
    required this.item,
    required this.onCheckChanged,
    required this.onPriceChanged,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  ConsumerState<ShoppingItemCard> createState() => _ShoppingItemCardState();
}

class _ShoppingItemCardState extends ConsumerState<ShoppingItemCard> {
  bool _isEditingPrice = false;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.item.price.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  List<Color> _getCategoryGradient(String category) {
    return AppColors.categoryGradients[category.toLowerCase()] ?? AppColors.categoryGradients['outros']!;
  }

  void _submitPrice() {
    final newPrice = double.tryParse(_priceController.text.replaceAll(',', '.'));
    if (newPrice != null) {
      widget.onPriceChanged(newPrice);
    }
    setState(() {
      _isEditingPrice = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getCategoryGradient(widget.item.category);

    return Dismissible(
      key: Key(widget.item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.budgetDanger,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Checkbox
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onCheckChanged(!widget.item.checked);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.item.checked ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: widget.item.checked ? AppColors.primary : AppColors.mutedForeground,
                    width: 2,
                  ),
                ),
                child: widget.item.checked
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: widget.item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.item.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 60,
                        height: 60,
                        color: AppColors.muted,
                        child: const Icon(Icons.image_not_supported, size: 20),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: AppColors.muted,
                      child: const Icon(Icons.shopping_bag, color: AppColors.mutedForeground),
                    ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: widget.item.checked ? TextDecoration.lineThrough : null,
                      color: widget.item.checked ? AppColors.mutedForeground : AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        widget.item.quantity,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.item.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Inline Price Edit
                  if (_isEditingPrice)
                    SizedBox(
                      height: 30,
                      width: 100,
                      child: TextField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        autofocus: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          prefixText: 'R\$ ',
                        ),
                        onSubmitted: (_) => _submitPrice(),
                      ),
                    )
                  else
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isEditingPrice = true;
                        });
                      },
                      child: Text(
                        'R\$ ${widget.item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Actions
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: AppColors.mutedForeground),
              onPressed: widget.onEdit,
            ),
          ],
        ),
      ),
    );
  }
}
