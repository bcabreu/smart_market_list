import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/data/models/shopping_note.dart';

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
    final dateFormat = DateFormat('dd/MM/yyyy'); // Or 'dd 'de' MMM.'
    // Custom date format to match "01 de dez. de 2024"
    final day = note.date.day.toString().padLeft(2, '0');
    final month = DateFormat('MMM', 'pt_BR').format(note.date).toLowerCase();
    final year = note.date.year;
    final dateString = '$day de $month. de $year';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.grey[500] : Colors.grey[600];

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
                  color: AppColors.secondary,
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
                    'Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: mutedColor,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(note.total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF26A69A), // Teal 400
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Image (if exists)
          if (note.photoUrl != null && note.photoUrl!.isNotEmpty) ...[
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: note.photoUrl!.startsWith('http')
                      ? CachedNetworkImageProvider(note.photoUrl!) as ImageProvider
                      : FileImage(File(note.photoUrl!)),
                  fit: BoxFit.cover,
                ),
              ),
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
                      foregroundColor: const Color(0xFF26A69A),
                      side: const BorderSide(color: Color(0xFFB2EBF2)),
                      backgroundColor: const Color(0xFFE0F7FA).withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('Ver nota'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextButton.icon(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    backgroundColor: Colors.red.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Excluir'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
