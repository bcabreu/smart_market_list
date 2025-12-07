import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';

import '../../../../providers/shopping_notes_provider.dart';

class ExpenseChartsModal extends ConsumerStatefulWidget {
  const ExpenseChartsModal({super.key});

  @override
  ConsumerState<ExpenseChartsModal> createState() => _ExpenseChartsModalState();
}

class _ExpenseChartsModalState extends ConsumerState<ExpenseChartsModal> {
  // We no longer need _data state for values, only maybe for optimization but build is fine
  // We still need to know the months we are displaying.
  
  String _getMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  void _showEditGoalDialog(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final key = _getMonthKey(date);
    final currentGoal = ref.read(goalsProvider.notifier).getGoal(key);

    final controller = TextEditingController(text: currentGoal.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editGoalTitle),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: l10n.editGoalHint,
            prefixText: 'R\$ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', '.'));
              if (val != null) {
                // Save to persistence
                ref.read(goalsProvider.notifier).setGoal(key, val);
                // No need to setState if we watch the provider, but checking build method
                // We should watch the goals or force rebuild. 
                // Since goalsProvider is not being watched for *changes* (it's a notifier/method), we need setState or watch state.
                setState(() {});
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.simpleCurrency(locale: Localizations.localeOf(context).toString());
    
    final notesAsync = ref.watch(shoppingNotesProvider);

    return notesAsync.when(
      loading: () => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
      error: (err, stack) => SizedBox(height: 300, child: Center(child: Text('Error: $err'))),
      data: (allNotes) {
        final now = DateTime.now();
        // Generate last 6 months data dynamically
        final displayData = List.generate(6, (index) {
          final date = DateTime(now.year, now.month - index, 1);
          final key = _getMonthKey(date);
          
          // Filter notes for this month
          final monthlyNotes = allNotes.where((note) {
            return note.date.year == date.year && note.date.month == date.month;
          });
          
          final totalAmount = monthlyNotes.fold<double>(0, (sum, note) => sum + note.total);
          
          // Fetch goal
          final goal = ref.read(goalsProvider.notifier).getGoal(key); // Reading here is fine, setState updates UI
          // To ensure reactivity on goal change if we used setGoal:
          // We rely on setState in the dialog to trigger this build.

          return {
            'date': date,
            'value': totalAmount,
            'goal': goal,
          };
        });

        final total = displayData.fold<double>(0, (sum, item) => sum + (item['value'] as double));
        final average = total / displayData.length;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.show_chart_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.expenseCharts,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          l10n.expenseChartsPeriod,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.chartsDisclaimer,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Charts
              ...displayData.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final date = item['date'] as DateTime;
                final amount = item['value'] as double;
                final goal = item['goal'] as double;

                final monthName = DateFormat.MMM(Localizations.localeOf(context).toString()).format(date);
                final formattedMonth = monthName[0].toUpperCase() + monthName.substring(1);
                
                // Goal Logic
                final widthFactor = (amount / goal).clamp(0.0, 1.0);
                final isOverBudget = amount > goal;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                formattedMonth,
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currencyFormat.format(amount),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          // Goal Label (Editable)
                          InkWell(
                            onTap: () => _showEditGoalDialog(context, date),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                children: [
                                  Text(
                                    '${l10n.goalLabel}: ${currencyFormat.format(goal)}',
                                    style: TextStyle(
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 12,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Bar Chart
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Container(
                                height: 32,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: widthFactor),
                                duration: const Duration(milliseconds: 1200),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  final percentage = (amount / goal * 100).toInt();
                                  final status = isOverBudget ? l10n.statusOverBudget : l10n.statusWithinGoal;
                                  final displayText = '$percentage% - $status';

                                  return Container(
                                    height: 32,
                                    width: constraints.maxWidth * value,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    alignment: Alignment.centerRight,
                                    decoration: BoxDecoration(
                                      color: isOverBudget ? const Color(0xFFEF5350) : const Color(0xFF4DB6AC), // Red if over, Teal if safe
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: value > 0.15 
                                        ? FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              displayText, 
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                              maxLines: 1,
                                            ),
                                          )
                                        : null,
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 16),

              // Footer Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1), // Light Teal
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.monthlyAverage,
                          style: const TextStyle(
                            color: Color(0xFF00695C), 
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          currencyFormat.format(average),
                          style: const TextStyle(
                            color: Color(0xFF004D40),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.totalSixMonths,
                          style: const TextStyle(
                            color: Color(0xFF00695C),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          currencyFormat.format(total),
                          style: const TextStyle(
                            color: Color(0xFF004D40),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
