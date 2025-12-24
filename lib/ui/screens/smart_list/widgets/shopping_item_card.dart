import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/core/utils/currency_input_formatter.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';
import 'package:intl/intl.dart';

class ShoppingItemCard extends ConsumerStatefulWidget {
  final ShoppingItem item;
  final Function(bool) onCheckChanged;
  final Function(double) onPriceChanged;
  final Function(int) onQuantityChanged;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ShoppingItemCard({
    super.key,
    required this.item,
    required this.onCheckChanged,
    required this.onPriceChanged,
    required this.onQuantityChanged,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  ConsumerState<ShoppingItemCard> createState() => _ShoppingItemCardState();
}

class _ShoppingItemCardState extends ConsumerState<ShoppingItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    
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

  List<Color> _getCategoryGradient(String category) {
    return AppColors.categoryGradients[category.toLowerCase()] ?? AppColors.categoryGradients['outros']!;
  }

  void _showQuickPriceModal() {
    final locale = Localizations.localeOf(context).toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceController = TextEditingController(
      text: NumberFormat.currency(locale: locale, symbol: '', decimalDigits: 2).format(widget.item.price).trim(),
    );
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.attach_money,
                      color: Color(0xFF4DB6AC),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alterar Preço',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          widget.item.name,
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
              
              // Price Input
              Row(
                children: [
                  Text(
                    NumberFormat.simpleCurrency(locale: locale).currencySymbol,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [CurrencyInputFormatter(locale: locale)],
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 2),
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
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
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
                        // Parse the new price
                        final text = priceController.text;
                        double newPrice;
                        if (locale.startsWith('pt')) {
                          newPrice = double.tryParse(text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
                        } else {
                          newPrice = double.tryParse(text.replaceAll(',', '')) ?? 0.0;
                        }
                        
                        if (newPrice != widget.item.price) {
                          widget.onPriceChanged(newPrice);
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4DB6AC),
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
                                ),
                              const SizedBox(height: 4),
                              // Quick Quantity Selector
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Decrement button
                                  InkWell(
                                    onTap: widget.item.unitQuantity > 1 ? () {
                                      HapticFeedback.selectionClick();
                                      widget.onQuantityChanged(widget.item.unitQuantity - 1);
                                    } : null,
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: widget.item.unitQuantity > 1 
                                            ? (isDark ? const Color(0xFF2A4A4A) : const Color(0xFFE0F2F1))
                                            : (isDark ? Colors.grey[800] : Colors.grey[200]),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        size: 16,
                                        color: widget.item.unitQuantity > 1 
                                            ? const Color(0xFF4DB6AC)
                                            : (isDark ? Colors.grey[600] : Colors.grey[400]),
                                      ),
                                    ),
                                  ),
                                  // Quantity Display
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      '${widget.item.unitQuantity}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  // Increment button
                                  InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      widget.onQuantityChanged(widget.item.unitQuantity + 1);
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF2A4A4A) : const Color(0xFFE0F2F1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        size: 16,
                                        color: Color(0xFF4DB6AC),
                                      ),
                                    ),
                                  ),
                                ],
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
                                    // Price
                                    // Price
                            InkWell(
                              onTap: _showQuickPriceModal,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    NumberFormat.simpleCurrency(locale: Localizations.localeOf(context).toString()).currencySymbol,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        NumberFormat.currency(locale: Localizations.localeOf(context).toString(), symbol: '', decimalDigits: 2).format(widget.item.totalPrice).trim(),
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
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        
                        // Action Buttons (Stacked vertically)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Edit Button
                            InkWell(
                              onTap: () {
                                widget.onEdit();
                              },
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
                            const SizedBox(height: 8),
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
        child: Center(
          child: Text(
            _getCategoryEmoji(widget.item.category),
            style: const TextStyle(fontSize: 24),
          ),
        ),
      );
    }

    if (widget.item.imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: widget.item.imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey[200]),
        errorWidget: (context, url, error) => Container(
          width: 50,
          height: 50,
          color: Colors.grey[200],
          child: Center(
            child: Text(
              _getCategoryEmoji(widget.item.category),
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
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
          child: Center(
            child: Text(
              _getCategoryEmoji(widget.item.category),
              style: const TextStyle(fontSize: 24),
            ),
          ),
        );
      },
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'hortifruti': return '🥬';
      case 'padaria': return '🥖';
      case 'laticinios': return '🥛';
      case 'acougue': return '🥩';
      case 'mercearia': return '🥫';
      case 'bebidas': return '🥤';
      case 'limpeza': return '🧹';
      case 'higiene': return '🧴';
      case 'congelados': return '🧊';
      case 'doces': return '🍬';
      case 'pet': return '🐶';
      case 'bebe': return '👶';
      case 'utilidades': return '🛠️';
      case 'outros': return '📦';
      default: return '✨';
    }
  }
}
