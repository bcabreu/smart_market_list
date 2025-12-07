import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_market_list/providers/shopping_notes_provider.dart';
import 'package:smart_market_list/ui/screens/shopping_notes/widgets/shopping_note_card.dart';
import 'package:smart_market_list/ui/screens/shopping_notes/modals/add_note_modal.dart';
import 'package:smart_market_list/ui/common/animations/staggered_entry.dart';

import 'package:smart_market_list/ui/widgets/pulse_fab.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';

class ShoppingNotesScreen extends ConsumerWidget {
  const ShoppingNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(shoppingNotesProvider);
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final l10n = AppLocalizations.of(context)!;


    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.store_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.shoppingNotesTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.shoppingNotesSubtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Summary Card
            notesAsync.when(
              data: (notes) {
                final totalSpent = notes.fold<double>(
                  0,
                  (sum, note) => sum + note.total,
                );

                final isDark = Theme.of(context).brightness == Brightness.dark;
                final cardColor = isDark 
                    ? const Color(0xFF1E2C2C)
                    : const Color(0xFFE0F7FA).withOpacity(0.5);
                final borderColor = isDark
                    ? const Color(0xFF2C4A4A)
                    : const Color(0xFFB2EBF2);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.totalSpent,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey[400] : Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(totalSpent),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF26A69A), // Teal 400
                                height: 1.0,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              l10n.savedNotes,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                notes.length.toString(),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // List or Empty State
            Expanded(
              child: notesAsync.when(
                data: (notes) {
                  if (notes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              size: 48,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.noSavedNotes,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noSavedNotesSubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return StaggeredEntry(
                        index: index,
                        child: NoteItemWrapper(
                          key: ValueKey(note.id),
                          onDismiss: () {
                             ref.read(shoppingNotesServiceProvider).deleteNote(note.id);
                          },
                          builder: (context, triggerAnimation) {
                            return ShoppingNoteCard(
                              note: note,
                              onTap: () async {
                                  if (note.photoUrl != null && note.photoUrl!.isNotEmpty) {
                                    String? imagePath = note.photoUrl;
                                    
                                    if (!note.photoUrl!.startsWith('http')) {
                                      final file = File(note.photoUrl!);
                                      if (!await file.exists()) {
                                        try {
                                          final docsDir = await getApplicationDocumentsDirectory();
                                          final name = note.photoUrl!.split('/').last;
                                          final newPath = '${docsDir.path}/$name';
                                          if (await File(newPath).exists()) {
                                            imagePath = newPath;
                                          } else {
                                            imagePath = null;
                                          }
                                        } catch (e) {
                                          debugPrint('Error resolving image path: $e');
                                          imagePath = null;
                                        }
                                      }
                                    }

                                    if (context.mounted && imagePath != null) {
                                      final pathToShow = imagePath;
                                      showDialog(
                                        context: context,
                                        builder: (context) => Dialog(
                                          backgroundColor: Colors.transparent,
                                          insetPadding: const EdgeInsets.all(16),
                                          child: Stack(
                                            alignment: Alignment.topRight,
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(16),
                                                child: pathToShow.startsWith('http')
                                                    ? CachedNetworkImage(
                                                        imageUrl: pathToShow,
                                                        fit: BoxFit.contain,
                                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                                        errorWidget: (context, url, error) => const Icon(Icons.error),
                                                      )
                                                    : Image.file(
                                                        File(pathToShow),
                                                        fit: BoxFit.contain,
                                                      ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: CircleAvatar(
                                                  backgroundColor: Colors.black54,
                                                  child: IconButton(
                                                    icon: const Icon(Icons.close, color: Colors.white),
                                                    onPressed: () => Navigator.pop(context),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    } else if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(l10n.imageNotFound)),
                                      );
                                    }
                                  }
                                },
                              onDelete: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    backgroundColor: Theme.of(context).cardColor,
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFEBEE), 
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.delete_forever_rounded,
                                              size: 32,
                                              color: Color(0xFFE57373), 
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            l10n.deleteNoteTitle,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).brightness == Brightness.dark 
                                                  ? Colors.white 
                                                  : Colors.black87,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            l10n.deleteNoteMessage,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Theme.of(context).brightness == Brightness.dark 
                                                  ? Colors.grey[400] 
                                                  : Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 24),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    l10n.cancel,
                                                    style: TextStyle(
                                                      color: Theme.of(context).brightness == Brightness.dark 
                                                          ? Colors.grey[400] 
                                                          : Colors.grey[600],
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(context); // Close dialog
                                                    triggerAnimation(); // Trigger exit animation
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFFEF5350), 
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    l10n.delete,
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Erro: $err')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: PulseFloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddNoteModal(),
          );
        },
        color: AppColors.secondary,
      ),
    );
  }
}

class NoteItemWrapper extends StatefulWidget {
  final Widget Function(BuildContext, VoidCallback) builder;
  final VoidCallback onDismiss;

  const NoteItemWrapper({
    super.key,
    required this.builder,
    required this.onDismiss,
  });

  @override
  State<NoteItemWrapper> createState() => _NoteItemWrapperState();
}

class _NoteItemWrapperState extends State<NoteItemWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: 1.0, 
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInBack, 
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerExit() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _scaleAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.builder(context, _triggerExit),
      ),
    );
  }
}
