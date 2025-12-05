import 'dart:io';
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

class _ShoppingItemCardState extends ConsumerState<ShoppingItemCard> with SingleTickerProviderStateMixin {
  bool _isEditingPrice = false;
  late TextEditingController _priceController;
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.item.price.toStringAsFixed(2).replaceAll('.', ','));
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Only animate if the item was created OR status changed very recently (e.g., last 500ms)
    final now = DateTime.now();
    final isNew = now.difference(widget.item.createdAt).inMilliseconds < 500;
    final isStatusChanged = widget.item.statusChangedAt != null && 
                           now.difference(widget.item.statusChangedAt!).inMilliseconds < 500;

    if (isNew || isStatusChanged) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0; // Skip animation
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    await _animationController.reverse();
    widget.onDelete();
  }

  Future<void> _handleCheck() async {
    HapticFeedback.selectionClick();
    await _animationController.reverse();
    widget.onCheckChanged(!widget.item.checked);
  }

  @override
  void didUpdateWidget(ShoppingItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.price != oldWidget.item.price && !_isEditingPrice) {
      _priceController.text = widget.item.price.toStringAsFixed(2).replaceAll('.', ',');
    }
  }

  List<Color> _getCategoryGradient(String category) {
    return AppColors.categoryGradients[category.toLowerCase()] ?? AppColors.categoryGradients['outros']!;
  }

  void _submitPrice() {
    final newPrice = double.tryParse(_priceController.text.replaceAll('.', '').replaceAll(',', '.'));
    if (newPrice != null && newPrice != widget.item.price) {
      widget.onPriceChanged(newPrice);
    }
    setState(() {
      _isEditingPrice = false;
    });
  }
  


  @override
  Widget build(BuildContext context) {
    final gradient = _getCategoryGradient(widget.item.category);
    final color = gradient.first; // Use primary color for strip and accents
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Theme.of(context).cardColor;
    final editBtnColor = isDark ? const Color(0xFF1A3F3F) : const Color(0xFFE0F2F1);
    final editIconColor = isDark ? const Color(0xFF4DB6AC) : const Color(0xFF009688);
    final deleteBtnColor = isDark ? const Color(0xFF3F1A1A) : const Color(0xFFFFEBEE);
    final deleteIconColor = isDark ? const Color(0xFFE57373) : const Color(0xFFE57373);
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.transparent;

    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: borderColor) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Color Strip
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: gradient,
                    ),
                  ),
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Checkbox
                        InkWell(
                          onTap: _handleCheck,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.item.checked ? color : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                width: 2,
                              ),
                              color: widget.item.checked ? color : Colors.transparent,
                            ),
                            child: widget.item.checked
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildImage(),
                        ),
                        const SizedBox(width: 12),

                        // Name & Quantity
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.item.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  decoration: widget.item.checked ? TextDecoration.lineThrough : null,
                                  color: widget.item.checked 
                                      ? AppColors.mutedForeground 
                                      : (isDark ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.item.quantity,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Price & Actions
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Price
                            InkWell(
                              onTap: () {
                                if (!_isEditingPrice) {
                                  setState(() {
                                    _isEditingPrice = true;
                                    _priceController.text = widget.item.price.toStringAsFixed(2).replaceAll('.', ',');
                                  });
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'R\$',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isEditingPrice)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 80,
                                              child: TextField(
                                                controller: _priceController,
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                autofocus: true,
                                                textAlign: TextAlign.end,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF4DB6AC),
                                                ),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                                  border: OutlineInputBorder(
                                                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                                                    borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                                                    borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey),
                                                  ),
                                                  focusedBorder: const OutlineInputBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(4)),
                                                    borderSide: BorderSide(color: Color(0xFF4DB6AC)),
                                                  ),
                                                ),
                                                onSubmitted: (_) => _submitPrice(),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: _submitPrice,
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: editBtnColor,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  size: 20,
                                                  color: editIconColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              widget.item.price.toStringAsFixed(2).replaceAll('.', ','),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF4DB6AC), // Teal color
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.edit, size: 12, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        
                        // Action Buttons
                        Row(
                          children: [
                            // Edit Button
                            InkWell(
                              onTap: widget.onEdit,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: editBtnColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isDark ? Colors.transparent : const Color(0xFFB2DFDB)),
                                ),
                                child: Icon(Icons.edit_outlined, size: 18, color: editIconColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Delete Button
                            InkWell(
                              onTap: _handleDelete,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: deleteBtnColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isDark ? Colors.transparent : const Color(0xFFFFCDD2)),
                                ),
                                child: Icon(Icons.delete_outline, size: 18, color: deleteIconColor),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildImage() {
    if (widget.item.imageUrl.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        color: Colors.grey[200],
        child: Icon(Icons.image, color: Colors.grey[400]),
      );
    }

    if (widget.item.imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: widget.item.imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey[200]),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    }

    return Image.file(
      File(widget.item.imageUrl),
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 50,
          height: 50,
          color: Colors.grey[200],
          child: Icon(Icons.broken_image, color: Colors.grey[400]),
        );
      },
    );
  }
}
