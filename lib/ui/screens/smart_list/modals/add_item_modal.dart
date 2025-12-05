import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';
import 'package:smart_market_list/providers/autocomplete_provider.dart';
import 'package:smart_market_list/providers/categories_provider.dart';

class AddItemModal extends ConsumerStatefulWidget {
  final Function(ShoppingItem) onAdd;

  const AddItemModal({super.key, required this.onAdd});

  @override
  ConsumerState<AddItemModal> createState() => _AddItemModalState();
}

class _AddItemModalState extends ConsumerState<AddItemModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();
  
  String _selectedCategory = 'outros';
  bool _isCreatingCategory = false;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

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

  void _addItem() {
    if (_nameController.text.isNotEmpty) {
      final item = ShoppingItem(
        name: _nameController.text,
        quantity: _qtyController.text.isEmpty ? '1 un' : _qtyController.text,
        price: double.tryParse(_priceController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0,
        category: _selectedCategory,
        imageUrl: _imagePath ?? '',
      );
      widget.onAdd(item);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(itemSuggestionsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
                    const Text(
                      'Adicionar Item',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Preencha os campos',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    shape: const CircleBorder(),
                  ),
                  icon: const Icon(Icons.close, size: 20),
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
                  _buildLabel('Nome do Item', Icons.inventory_2_outlined),
                  const SizedBox(height: 8),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.length < 2) {
                        return const Iterable<String>.empty();
                      }
                      return suggestions.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      _nameController.text = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      // Sync external controller with internal one if needed, 
                      // but here we just use the internal one for the value and keep our _nameController updated manually or via listener if complex.
                      // Actually, Autocomplete uses its own controller. We need to extract the value on save.
                      // A better approach for simple usage:
                      if (controller.text != _nameController.text && _nameController.text.isNotEmpty && controller.text.isEmpty) {
                         controller.text = _nameController.text;
                      }
                      
                      // Bind the internal controller to our _nameController listener to keep them in sync? 
                      // No, simpler: just use the controller provided here for the UI, and read from it on submit.
                      // But we need to access it in _addItem. 
                      // Let's assign the passed controller to our _nameController reference? No, that breaks lifecycle.
                      // We'll just listen to it.
                      controller.addListener(() {
                        _nameController.text = controller.text;
                      });

                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: _inputDecoration('Ex: Tomate, Pão, Leite...'),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: MediaQuery.of(context).size.width - 48,
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Quantity Field
                  _buildLabel('Quantidade', Icons.local_offer_outlined),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _qtyController,
                    decoration: _inputDecoration('Ex: 1kg, 2 litros, 500g...'),
                  ),

                  const SizedBox(height: 20),

                  // Price Field
                  _buildLabel('Preço (opcional)', Icons.attach_money),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'R\$',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _inputDecoration('0,00'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Category Field
                  _buildLabel('Categoria', Icons.category_outlined),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
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
                                          cat[0].toUpperCase() + cat.substring(1),
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
                              const PopupMenuItem<String>(
                                value: 'new',
                                child: Row(
                                  children: [
                                    SizedBox(width: 16),
                                    SizedBox(width: 8),
                                    Icon(Icons.add, color: Colors.grey, size: 18),
                                    SizedBox(width: 12),
                                    Text(
                                      'Criar nova categoria',
                                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
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
                                _selectedCategory[0].toUpperCase() + _selectedCategory.substring(1),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
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
                            decoration: InputDecoration(
                              hintText: 'Nome da nova categoria',
                              filled: true,
                              fillColor: Colors.grey[50],
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
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.close, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Photo Field
                  _buildLabel('Foto do Produto (opcional)', Icons.camera_alt_outlined),
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
                              image: FileImage(File(_imagePath!)),
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
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            child: SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text('Tirar foto'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.camera);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: const Text('Escolher da galeria'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.gallery);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: CustomPaint(
                        painter: _DashedBorderPainter(color: Colors.grey[300]!),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 32, color: Colors.grey[600]),
                              const SizedBox(height: 8),
                              Text(
                                'Tirar foto ou escolher da galeria',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),


                  const SizedBox(height: 32),

                  // Add Button
                  Container(
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
                        onTap: _addItem,
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
                                child: const Icon(Icons.add, size: 24, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Adicionar Item',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Confirmar',
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
                  ),
                  const SizedBox(height: 24), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      filled: true,
      fillColor: Colors.grey[100], // Light grey background
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
  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'hortifruti': return '🥬';
      case 'padaria': return '🥖';
      case 'laticinios': return '🥛';
      case 'outros': return '📦';
      default: return '✨';
    }
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
