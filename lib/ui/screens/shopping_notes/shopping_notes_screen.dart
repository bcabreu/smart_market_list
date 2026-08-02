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
import 'package:smart_market_list/providers/user_profile_provider.dart';
import 'package:smart_market_list/ui/common/modals/paywall_modal.dart';

class ShoppingNotesScreen extends ConsumerStatefulWidget {
  const ShoppingNotesScreen({super.key});

  @override
  ConsumerState<ShoppingNotesScreen> createState() => _ShoppingNotesScreenState();
}

class _ShoppingNotesScreenState extends ConsumerState<ShoppingNotesScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  String _formatMonthYear(DateTime date, String locale) {
    final format = DateFormat('MMMM yyyy', locale);
    final formatted = format.format(date);
    // Capitalize first letter
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  List<DateTime> _getAvailableMonths(List notes) {
    final months = <DateTime>{};
    for (final note in notes) {
      months.add(DateTime(note.date.year, note.date.month));
    }
    final sortedMonths = months.toList()..sort((a, b) => b.compareTo(a));
    
    // Ensure current month is always available
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    if (!sortedMonths.contains(currentMonth)) {
      sortedMonths.insert(0, currentMonth);
    }
    
    return sortedMonths;
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(shoppingNotesProvider);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final localeStr = locale.toString();
    final currencySymbol = locale.languageCode == 'pt' ? 'R\$' : '\$';
    final currencyFormat = NumberFormat.currency(
      locale: localeStr,
      symbol: currencySymbol,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Month Selector & Summary Card
            notesAsync.when(
              data: (notes) {
                // Filter notes by selected month
                final filteredNotes = notes.where((note) {
                  return note.date.year == _selectedMonth.year &&
                      note.date.month == _selectedMonth.month;
                }).toList();

                final totalSpent = filteredNotes.fold<double>(
                  0,
                  (sum, note) => sum + note.total,
                );

                final cardColor = isDark 
                    ? const Color(0xFF1E2C2C)
                    : const Color(0xFFE0F7FA).withOpacity(0.5);
                final borderColor = isDark
                    ? const Color(0xFF2C4A4A)
                    : const Color(0xFFB2EBF2);

                final availableMonths = _getAvailableMonths(notes);

                return Column(
                  children: [
                    // Month Selector
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: GestureDetector(
                        onTap: () {
                          _showMonthPicker(context, availableMonths, localeStr);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 20,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatMonthYear(_selectedMonth, localeStr),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Summary Card
                    Padding(
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
                                    color: Color(0xFF26A69A),
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
                                    filteredNotes.length.toString(),
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
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            // List or Empty State
            Expanded(
              child: notesAsync.when(
                data: (notes) {
                  // Filter notes by selected month
                  final filteredNotes = notes.where((note) {
                    return note.date.year == _selectedMonth.year &&
                        note.date.month == _selectedMonth.month;
                  }).toList();

                  if (filteredNotes.isEmpty) {
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
                            l10n.noNotesInMonth,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noNotesInMonthSubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
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
                                      final isFullPath = note.photoUrl!.contains('/');
                                      
                                      if (isFullPath) {
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
                                      } else {
                                        try {
                                          final docsDir = await getApplicationDocumentsDirectory();
                                          final fullPath = '${docsDir.path}/${note.photoUrl}';
                                          if (await File(fullPath).exists()) {
                                            imagePath = fullPath;
                                          } else {
                                            debugPrint('Image file not found: $fullPath');
                                            imagePath = null;
                                          }
                                        } catch (e) {
                                          debugPrint('Error constructing image path: $e');
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
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            l10n.deleteNoteMessage,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                                                    Navigator.pop(context);
                                                    triggerAnimation();
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
          final isPremium = ref.read(userProfileProvider).value?.isPremium ?? false;

          if (!isPremium) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const PaywallModal(),
            );
          } else {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddNoteModal(),
            );
          }
        },
        color: AppColors.secondary,
      ),
    );
  }

  void _showMonthPicker(BuildContext context, List<DateTime> availableMonths, String locale) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppColors.secondary),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.selectMonth,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableMonths.length,
                  itemBuilder: (context, index) {
                    final month = availableMonths[index];
                    final isSelected = month.year == _selectedMonth.year &&
                        month.month == _selectedMonth.month;
                    
                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? AppColors.secondary : Colors.grey,
                      ),
                      title: Text(
                        _formatMonthYear(month, locale),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.secondary : null,
                        ),
                      ),
                      onTap: () {
                        setState(() => _selectedMonth = month);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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
