import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:smart_market_list/core/services/ad_service.dart';
import 'package:smart_market_list/providers/user_provider.dart';
import 'package:smart_market_list/providers/user_profile_provider.dart';
import 'package:smart_market_list/data/models/user_profile.dart'; // import ImagePicker
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/core/utils/currency_input_formatter.dart';
import 'package:smart_market_list/data/models/shopping_list.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/providers/autocomplete_provider.dart';
import 'package:smart_market_list/providers/categories_provider.dart';
import 'package:smart_market_list/data/models/product_suggestion.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';

import 'package:smart_market_list/data/static/product_catalog.dart';
import 'package:smart_market_list/providers/hidden_suggestions_provider.dart';
import 'package:smart_market_list/providers/history_provider.dart';
import 'package:intl/intl.dart';

class AddItemModal extends ConsumerStatefulWidget {
  final Function(ShoppingItem) onAdd;
  final ShoppingItem? itemToEdit;

  const AddItemModal({super.key, required this.onAdd, this.itemToEdit});

  @override
  ConsumerState<AddItemModal> createState() => _AddItemModalState();
}

class _AddItemModalState extends ConsumerState<AddItemModal> {
  late TextEditingController _nameController;
  late TextEditingController _qtyController;
  late TextEditingController _priceController;
  late TextEditingController _newCategoryController;
  
  String _selectedCategory = 'outros';
  bool _isCreatingCategory = false;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    _nameController = TextEditingController(text: item?.name ?? '');
    _qtyController = TextEditingController(text: item?.quantity ?? '');
    _priceController = TextEditingController(); // Filled in didChangeDependencies
    _newCategoryController = TextEditingController();
    
    if (item != null) {
      _selectedCategory = item.category;
      _imagePath = item.imageUrl.isNotEmpty ? item.imageUrl : null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final item = widget.itemToEdit;
    final locale = Localizations.localeOf(context).toString();
    if (item != null) {
       _priceController.text = NumberFormat.currency(locale: locale, symbol: '', decimalDigits: 2).format(item.price).trim();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.isNotEmpty) {
      final item = ShoppingItem(
        id: widget.itemToEdit?.id, // Preserve ID if editing
        name: _nameController.text,
        quantity: _qtyController.text.isEmpty ? '1 un' : _qtyController.text,
        price: _parsePrice(_priceController.text),
        category: _selectedCategory,
        imageUrl: _imagePath ?? '',
        checked: widget.itemToEdit?.checked ?? false, // Preserve checked status
      );
      
      // Remove from hidden suggestions if it was previously hidden
      // This ensures that if the user explicitly adds an item they previously deleted, it comes back
      await ref.read(hiddenSuggestionsProvider.notifier).unhide(item.name);

      // Save to history for future suggestions
      await ref.read(historyProvider.notifier).addOrUpdate(item);
      
      final userProfile = ref.read(userProfileProvider).value;
      final isPremium = userProfile != null && (userProfile.planType == PlanType.premium_individual || userProfile.planType == PlanType.premium_family);
      
      void completeAdd() {
        widget.onAdd(item);
        if (mounted) {
          Navigator.pop(context);
        }
      }

      if (!isPremium) {
         // Check if we need to show an ad (every 10 items)
         final triggered = AdService.instance.checkItemAdTrigger(onContinue: completeAdd);
         if (!triggered) {
           // If false, it called completeAdd immediately, so we don't need to do anything.
           // But actually checkItemAdTrigger calls onContinue inside.
         }
      } else {
         completeAdd();
      }
    }
  }

  bool _isSystemItem(String? name) {
    if (name == null) return false;
    final cleanName = name.trim().toLowerCase();
    final languageCode = Localizations.localeOf(context).languageCode;
    return ProductCatalog.getItems(languageCode).any((item) => item.name.trim().toLowerCase() == cleanName);
  }

  double _parsePrice(String text) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'pt') {
      return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
    } else {
       return double.tryParse(text.replaceAll(',', '')) ?? 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(itemSuggestionsProvider);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Theme.of(context).scaffoldBackgroundColor;
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey[100];
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.grey[400] : Colors.grey[700];
    final hintColor = isDark ? Colors.grey[600] : Colors.grey[500];
    final iconColor = isDark ? Colors.grey[400] : Colors.grey[600];
    
    final isSystemItem = _isSystemItem(widget.itemToEdit?.name);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.itemToEdit != null ? l10n.editItem : l10n.addItemTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.fillFields,
                      style: TextStyle(
                        fontSize: 14,
                        color: labelColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF333333) : Colors.grey[100],
                    shape: const CircleBorder(),
                  ),
                  icon: Icon(Icons.close, size: 20, color: textColor),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Field with Autocomplete
                  _buildLabel(l10n.itemName, Icons.inventory_2_outlined, isDark),
                  const SizedBox(height: 8),
                  Autocomplete<ProductSuggestion>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.length < 2) {
                        return const Iterable<ProductSuggestion>.empty();
                      }
                      return suggestions.where((ProductSuggestion option) {
                        return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    displayStringForOption: (ProductSuggestion option) => option.name,
                    onSelected: (ProductSuggestion selection) {
                      _nameController.text = selection.name;
                      _qtyController.text = selection.defaultQuantity;
                      setState(() {
                        _selectedCategory = selection.category;
                        if (selection.imageUrl.isNotEmpty) {
                          _imagePath = selection.imageUrl;
                        }
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      if (controller.text != _nameController.text && _nameController.text.isNotEmpty && controller.text.isEmpty) {
                         controller.text = _nameController.text;
                      }
                      controller.addListener(() {
                        _nameController.text = controller.text;
                      });

                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        enabled: widget.itemToEdit == null || !isSystemItem,
                        style: TextStyle(
                          color: (widget.itemToEdit != null && isSystemItem) ? textColor.withOpacity(0.6) : textColor,
                        ),
                        decoration: _inputDecoration(
                          l10n.itemNameHint, 
                          isDark,
                          suffixIcon: (widget.itemToEdit != null && isSystemItem)
                              ? Icon(Icons.lock_outline, color: (iconColor ?? Colors.grey).withOpacity(0.5), size: 20)
                              : null,
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      final hiddenSuggestions = ref.watch(hiddenSuggestionsProvider);
                      final hiddenSet = hiddenSuggestions.map((e) => e.toLowerCase()).toSet();
                      final visibleOptions = options.where((o) => !hiddenSet.contains(o.name.toLowerCase())).toList();

                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.transparent,
                          child: Container(
                            width: MediaQuery.of(context).size.width - 48,
                            constraints: const BoxConstraints(maxHeight: 300),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFFFD700)), // Gold star
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.suggestions,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
                                Flexible(
                                  child: ListView.separated(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: visibleOptions.length,
                                    separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
                                    itemBuilder: (BuildContext context, int index) {
                                      final ProductSuggestion option = visibleOptions.elementAt(index);
                                      final isSystem = _isSystemItem(option.name);
                                      
                                      return InkWell(
                                        onTap: () => onSelected(option),
                                        child: Container(
                                          color: index == 0 
                                              ? (isDark ? const Color(0xFF4DB6AC).withOpacity(0.1) : const Color(0xFFE0F2F1))
                                              : null,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              // Image
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  color: Colors.grey[200],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: option.imageUrl.isNotEmpty
                                                      ? CachedNetworkImage(
                                                          imageUrl: option.imageUrl,
                                                          fit: BoxFit.cover,
                                                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                                                          errorWidget: (context, url, error) => Center(
                                                            child: Text(
                                                              _getCategoryEmoji(option.category),
                                                              style: const TextStyle(fontSize: 24),
                                                            ),
                                                          ),
                                                        )
                                                      : Center(
                                                          child: Icon(Icons.image, color: Colors.grey[400], size: 24),
                                                        ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              // Text Info
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      option.name,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${_getLocalizedCategoryName(option.category, l10n)} • ${option.defaultQuantity}',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Delete Action (Only for User Items)
                                              if (!isSystem)
                                                IconButton(
                                                  onPressed: () {
                                                    // Hide from suggestions (Local preference)
                                                    ref.read(hiddenSuggestionsProvider.notifier).add(option.name);
                                                    
                                                    // Remove from history & Cloud (Permanent delete)
                                                    ref.read(historyProvider.notifier).remove(option.name);
                                                  },
                                                  icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
                                                ),
                                              // Arrow (Always show for system items, or if not deleting)
                                              if (isSystem)
                                                const Icon(
                                                  Icons.arrow_forward,
                                                  size: 18,
                                                  color: Color(0xFF4DB6AC),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 20),

                  // Quantity Field
                  _buildLabel(l10n.quantity, Icons.local_offer_outlined, isDark),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _qtyController,
                    style: TextStyle(color: textColor),
                    decoration: _inputDecoration(l10n.quantityHint, isDark),
                  ),

                  const SizedBox(height: 20),

                  // Price Field
                  _buildLabel(l10n.priceOptional, Icons.attach_money, isDark),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        NumberFormat.simpleCurrency(locale: locale.toString()).currencySymbol,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [CurrencyInputFormatter(locale: locale.toString())],
                          style: TextStyle(color: textColor),
                          decoration: _inputDecoration(locale.languageCode == 'pt' ? '0,00' : '0.00', isDark),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Category Field
                  _buildLabel(l10n.category, Icons.category_outlined, isDark),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: inputFillColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final RenderBox button = context.findRenderObject() as RenderBox;
                          final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
                          final RelativeRect position = RelativeRect.fromRect(
                            Rect.fromPoints(
                              button.localToGlobal(Offset.zero, ancestor: overlay),
                              button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                            ),
                            Offset.zero & overlay.size,
                          );

                          final categories = ref.read(categoriesProvider); 
                          
                          showMenu<String>(
                            context: context,
                            position: position.shift(const Offset(24, 460)), // Adjust position to align with field
                            color: const Color(0xFF333333), // Dark background
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            items: [
                              ...categories.map((cat) {
                                final isSelected = _selectedCategory == cat;
                                final isDefault = AppColors.categoryGradients.containsKey(cat);
                                return PopupMenuItem<String>(
                                  value: cat,
                                  child: Row(
                                    children: [
                                      if (isSelected)
                                        const Icon(Icons.check, color: Colors.white, size: 16)
                                      else
                                        const SizedBox(width: 16),
                                      const SizedBox(width: 8),
                                      Text(_getCategoryEmoji(cat), style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _getLocalizedCategoryName(cat, l10n),
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                        ),
                                      ),

                                      if (!isDefault)
                                        InkWell(
                                          onTap: () {
                                            ref.read(categoriesProvider.notifier).removeCategory(cat);
                                            if (_selectedCategory == cat) {
                                              setState(() => _selectedCategory = 'outros');
                                            }
                                            Navigator.pop(context); // Close menu to refresh
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.all(4.0),
                                            child: Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                              PopupMenuItem<String>(
                                value: 'new',
                                child: Row(
                                  children: [
                                    const SizedBox(width: 16),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.add, color: Colors.grey, size: 18),
                                    const SizedBox(width: 12),
                                    Text(
                                      l10n.createCategory,
                                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ).then((val) {
                            if (val == 'new') {
                              setState(() => _isCreatingCategory = true);
                            } else if (val != null) {
                              setState(() => _selectedCategory = val);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Text(_getCategoryEmoji(_selectedCategory), style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Text(
                                _getLocalizedCategoryName(_selectedCategory, l10n),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),

                              const Spacer(),
                              Icon(Icons.keyboard_arrow_down, color: iconColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // New Category Input
                  if (_isCreatingCategory) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newCategoryController,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: l10n.newCategoryName,
                              hintStyle: TextStyle(color: hintColor),
                              filled: true,
                              fillColor: inputFillColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 2), // Teal border
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Confirm Button
                        InkWell(
                          onTap: () {
                            if (_newCategoryController.text.isNotEmpty) {
                              final newCat = _newCategoryController.text;
                              ref.read(categoriesProvider.notifier).addCategory(newCat);
                              setState(() {
                                _selectedCategory = newCat;
                                _isCreatingCategory = false;
                                _newCategoryController.clear();
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1), // Light teal
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.check, color: Color(0xFF4DB6AC)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Cancel Button
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isCreatingCategory = false;
                              _newCategoryController.clear();
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF333333) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.close, color: textColor),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Photo Field
                  _buildLabel(l10n.productPhotoOptional, Icons.camera_alt_outlined, isDark),
                  const SizedBox(height: 8),
                  if (_imagePath != null)
                    Stack(
                      children: [
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: _imagePath!.startsWith('http') 
                                  ? CachedNetworkImageProvider(_imagePath!) as ImageProvider
                                  : FileImage(File(_imagePath!)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _imagePath = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 20, color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.productPhotoOptional,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildActionButton(
                                      context,
                                      icon: Icons.camera_alt,
                                      label: l10n.camera,
                                      onTap: () {
                                        Navigator.pop(context);
                                        _pickImage(ImageSource.camera);
                                      },
                                    ),
                                    _buildActionButton(
                                      context,
                                      icon: Icons.photo_library,
                                      label: l10n.gallery,
                                      onTap: () {
                                        Navigator.pop(context);
                                        _pickImage(ImageSource.gallery);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: CustomPaint(
                        painter: _DashedBorderPainter(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 32, color: iconColor),
                              const SizedBox(height: 8),
                              Text(
                                l10n.takePhotoOrGallery,
                                style: TextStyle(color: labelColor, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),


                  if (!Platform.isAndroid) ...[
                    const SizedBox(height: 32),
                    _buildButton(context, l10n),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
          if (Platform.isAndroid)
            Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + math.max(MediaQuery.of(context).viewPadding.bottom, 45.0)),
              child: _buildButton(context, l10n),
            ),

        ],
      ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4DB6AC), Color(0xFF26A69A)], // Teal gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4DB6AC).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _submit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.itemToEdit != null ? Icons.save : Icons.add, 
                    size: 24, 
                    color: Colors.white
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.itemToEdit != null ? l10n.editItem : l10n.addItemTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      l10n.confirm,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text, bool isDark, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }

  Widget _buildLabel(String text, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark, {String? prefix, Widget? suffixIcon}) {
    final fillColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey[100];
    final hintColor = isDark ? Colors.grey[600] : Colors.grey[500];
    
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      suffixIcon: suffixIcon,
      hintStyle: TextStyle(color: hintColor),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
    );
  }
  String _getLocalizedCategoryName(String category, AppLocalizations l10n) {
    switch (category.toLowerCase()) {
      case 'hortifruti': return l10n.cat_hortifruti;
      case 'padaria': return l10n.cat_padaria;
      case 'laticinios': return l10n.cat_laticinios;
      case 'acougue': return l10n.cat_acougue;
      case 'mercearia': return l10n.cat_mercearia;
      case 'bebidas': return l10n.cat_bebidas;
      case 'limpeza': return l10n.cat_limpeza;
      case 'higiene': return l10n.cat_higiene;
      case 'congelados': return l10n.cat_congelados;
      case 'doces': return l10n.cat_doces;
      case 'pet': return l10n.cat_pet;
      case 'bebe': return l10n.cat_bebe;
      case 'utilidades': return l10n.cat_utilidades;
      case 'outros': return l10n.cat_outros;
      default: 
        if (category.isEmpty) return l10n.cat_outros;
        return category[0].toUpperCase() + category.substring(1);
    }
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
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DashedBorderPainter({required this.color, this.strokeWidth = 1.0, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ));

    final Path dashPath = Path();
    final double dashWidth = 10.0;
    final double dashSpace = gap;
    double distance = 0.0;

    for (final PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
