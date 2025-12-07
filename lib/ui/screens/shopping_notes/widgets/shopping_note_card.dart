import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_market_list/data/models/shopping_note.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';

class ShoppingNoteCard extends StatelessWidget {
  final ShoppingNote note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ShoppingNoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    
    // Custom date format
    final day = note.date.day.toString().padLeft(2, '0');
    final month = DateFormat('MMM', locale.toString()).format(note.date).toLowerCase();
    final year = note.date.year;
    final dateString = '$day ${locale.languageCode == 'pt' ? 'de ' : ''}$month${locale.languageCode == 'pt' ? '.' : ''} ${locale.languageCode == 'pt' ? 'de ' : ''}$year';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final priceColor = isDark ? const Color(0xFF64FFDA) : const Color(0xFF00897B);
    
    // Button Colors
    final viewBtnColor = isDark ? const Color(0xFF64FFDA) : const Color(0xFF00897B);
    final deleteBtnColor = isDark ? const Color(0xFFFF5252) : const Color(0xFFD32F2F);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              
              // Store Name & Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.storeName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: mutedColor),
                        const SizedBox(width: 4),
                        Text(
                          dateString,
                          style: TextStyle(
                            fontSize: 13,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Total Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.totalLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: mutedColor,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: locale.toString(), 
                      symbol: locale.languageCode == 'pt' ? 'R\$' : '\$'
                    ).format(note.total),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: priceColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Image (if exists)
          if (note.photoUrl != null && note.photoUrl!.isNotEmpty) ...[
            FutureBuilder<String?>(
              future: _resolveImagePath(note.photoUrl!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                
                return Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: snapshot.data!.startsWith('http')
                          ? CachedNetworkImageProvider(snapshot.data!) as ImageProvider
                          : FileImage(File(snapshot.data!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // Actions
          Row(
            children: [
              if (note.photoUrl != null && note.photoUrl!.isNotEmpty) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTap, // View Note
                    style: OutlinedButton.styleFrom(
                      foregroundColor: viewBtnColor,
                      side: BorderSide(color: viewBtnColor.withOpacity(0.5)),
                      backgroundColor: viewBtnColor.withOpacity(0.05),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: Text(l10n.viewNote),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: deleteBtnColor,
                    side: BorderSide(color: deleteBtnColor.withOpacity(0.5)),
                    backgroundColor: deleteBtnColor.withOpacity(0.05),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l10n.delete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    }

  Future<String?> _resolveImagePath(String path) async {
    if (path.startsWith('http')) return path;

    final file = File(path);
    if (await file.exists()) return path;

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final name = path.split('/').last;
      final newPath = '${docsDir.path}/$name';
      if (await File(newPath).exists()) {
        return newPath;
      }
    } catch (e) {
      debugPrint('Error resolving image path: $e');
    }
    
    return null;
  }
}
