import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/core/utils/currency_input_formatter.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';
import 'package:smart_market_list/data/models/shopping_note.dart';
import 'package:smart_market_list/providers/shopping_notes_provider.dart';
import 'package:smart_market_list/providers/user_provider.dart';
import 'package:smart_market_list/ui/common/modals/paywall_modal.dart';

class AddNoteModal extends ConsumerStatefulWidget {
  const AddNoteModal({super.key});

  @override
  ConsumerState<AddNoteModal> createState() => _AddNoteModalState();
}

class _AddNoteModalState extends ConsumerState<AddNoteModal> {
  final _formKey = GlobalKey<FormState>();
  final _storeController = TextEditingController();
  final _totalController = TextEditingController();
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _storeController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  Future<void> _pickImageGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickImageGallery();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _saveNote() {
    if (_formKey.currentState!.validate()) {
      // final isPremium = ref.read(isPremiumProvider);
      
      // if (!isPremium) {
      //   showModalBottomSheet(
      //     context: context,
      //     isScrollControlled: true,
      //     backgroundColor: Colors.transparent,
      //     builder: (context) => const PaywallModal(),
      //   );
      //   return;
      // }

      // Parse total value
      String cleanValue = _totalController.text.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim();
      double totalValue = double.tryParse(cleanValue) ?? 0.0;

      // Create a single item representing the total purchase
      final items = [
        ShoppingItem(
          name: 'Compra Geral',
          price: totalValue,
          quantity: '1',
        )
      ];

      final note = ShoppingNote(
        storeName: _storeController.text,
        date: DateTime.now(),
        items: items,
        photoUrl: _imagePath,
      );

      ref.read(shoppingNotesServiceProvider).createNote(note);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nova Nota',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Registre sua compra',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store Name
                    _buildLabel('Nome do Mercado', Icons.store_outlined, isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _storeController,
                      decoration: InputDecoration(
                        hintText: 'Ex: Supermercado Central',
                        filled: true,
                        fillColor: inputFillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 24),

                    // Total Value
                    _buildLabel('Valor Total', Icons.attach_money, isDark),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'R\$',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _totalController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [CurrencyInputFormatter()],
                            decoration: InputDecoration(
                              hintText: '0,00',
                              filled: true,
                              fillColor: inputFillColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Obrigatório' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Photo Upload
                    _buildLabel('Foto da Nota (opcional)', Icons.camera_alt_outlined, isDark),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showImageSourceOptions,
                      child: CustomPaint(
                        painter: DashedBorderPainter(color: borderColor),
                        child: Container(
                          width: double.infinity,
                          height: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _imagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(_imagePath!),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt_rounded,
                                      size: 48,
                                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Tirar foto ou escolher da galeria',
                                      style: TextStyle(
                                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Save Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Salvar Nota',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Add safe area padding and extra spacing for bottom
            SizedBox(
              height: MediaQuery.of(context).viewInsets.bottom + 
                     MediaQuery.of(context).padding.bottom + 
                     24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 6,
    this.dashSpace = 4,
    this.radius = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    
    final Path dashPath = Path();
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
  bool shouldRepaint(DashedBorderPainter oldDelegate) => 
      color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
}
