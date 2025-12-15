import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/core/utils/currency_input_formatter.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';
import 'package:smart_market_list/data/models/shopping_note.dart';
import 'package:smart_market_list/providers/shopping_notes_provider.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
              l10n.notePhotoLabel.replaceAll(' (opcional)', ''),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.camera_alt,
                  label: l10n.camera,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                _buildActionButton(
                  icon: Icons.photo_library,
                  label: l10n.gallery,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageGallery();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _saveNote() async {
    if (_formKey.currentState!.validate()) {
      // Parse total value - Handle both dot and comma
      String cleanValue = _totalController.text.trim();
      
      // Remove currency symbol if present
      final locale = Localizations.localeOf(context);
      final currencySymbol = locale.languageCode == 'pt' ? 'R\$' : '\$';
      cleanValue = cleanValue.replaceAll(currencySymbol, '').trim();

      // Normalize decimal separator
      if (cleanValue.contains(',')) {
        cleanValue = cleanValue.replaceAll('.', '').replaceAll(',', '.');
      }

      double totalValue = double.tryParse(cleanValue) ?? 0.0;

      // Create a single item representing the total purchase
      final items = [
        ShoppingItem(
          name: AppLocalizations.of(context)!.generalPurchase,
          price: totalValue,
          quantity: '1',
        )
      ];

      String? permanentImagePath;
      if (_imagePath != null) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          // Ensure directory exists
          if (!await directory.exists()) {
             await directory.create(recursive: true);
          }
          
          final extension = p.extension(_imagePath!);
          // Use timestamp for unique filename
          final fileName = 'note_${DateTime.now().millisecondsSinceEpoch}$extension';
          final savedImage = File('${directory.path}/$fileName');
          
          await File(_imagePath!).copy(savedImage.path);
          permanentImagePath = fileName; // Store only filename
        } catch (e) {
          debugPrint('Error saving image: $e');
          // If copy fails, fallback to original path but log error
          permanentImagePath = _imagePath;
        }
      }

      final note = ShoppingNote(
        storeName: _storeController.text,
        date: DateTime.now(),
        items: items,
        photoUrl: permanentImagePath,
      );

      ref.read(shoppingNotesServiceProvider).createNote(note);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final currencySymbol = locale.languageCode == 'pt' ? 'R\$' : '\$';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Expanded(
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
                      Text(
                        l10n.newNoteTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.newNoteSubtitle,
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
                    _buildLabel(l10n.storeLabel, Icons.store_outlined, isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _storeController,
                      decoration: InputDecoration(
                        hintText: l10n.storeHint,
                        filled: true,
                        fillColor: inputFillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? l10n.requiredField : null,
                    ),
                    const SizedBox(height: 24),

                    // Total Value
                    _buildLabel(l10n.totalValueLabel, Icons.attach_money, isDark),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          currencySymbol,
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
                            inputFormatters: [CurrencyInputFormatter(locale: Localizations.localeOf(context).toString())],
                            decoration: InputDecoration(
                              hintText: locale.languageCode == 'pt' ? '0,00' : '0.00',
                              filled: true,
                              fillColor: inputFillColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? l10n.requiredField : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Photo Upload
                    _buildLabel(l10n.notePhotoLabel, Icons.camera_alt_outlined, isDark),
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
                                      l10n.addPhotoHint,
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

            if (!Platform.isAndroid) ...[
              _buildSaveButton(l10n),
              const SizedBox(height: 24),
            ],
          ],
        ),
        ),
      ),
      if (Platform.isAndroid)
        Padding(
          padding: EdgeInsets.only(bottom: 24 + math.max(MediaQuery.of(context).viewPadding.bottom, 45.0), top: 16),
          child: _buildSaveButton(l10n),
        ),
      ],
    )));
  }

  Widget _buildSaveButton(AppLocalizations l10n) {
    return Padding(
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 24),
              const SizedBox(width: 8),
              Text(
                l10n.saveNoteButton,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
