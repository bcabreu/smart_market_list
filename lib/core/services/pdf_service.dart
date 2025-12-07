
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:smart_market_list/data/models/shopping_note.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';

class PdfService {
  Future<void> generateAndShareReport({
    required List<ShoppingNote> notes,
    required Map<String, double> goals, // Key: "yyyy-MM"
    required AppLocalizations l10n,
    required Locale locale,
  }) async {
    final pdf = pw.Document();

    // Load fonts with fallback
    pw.Font font;
    pw.Font fontBold;
    pw.Font fontEmoji;

    try {
      font = await PdfGoogleFonts.openSansRegular();
      fontBold = await PdfGoogleFonts.openSansBold();
      // Use NotoEmoji (B/W) instead of Color to save memory/time, or fallback to symbols
      fontEmoji = await PdfGoogleFonts.notoEmojiRegular(); 
    } catch (e) {
      print('Error loading HTML fonts: $e');
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
      fontEmoji = pw.Font.zapfDingbats(); // Best effort fallback
    }
    
    // Theme with fallback for emojis
    final theme = pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
      fontFallback: [fontEmoji, font],
    );
    
    // 1. Prepare Data
    final now = DateTime.now();
    final monthlyData = List.generate(12, (index) {
      final date = DateTime(now.year, now.month - index, 1);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      
      final monthlyNotes = notes.where((n) {
        return n.date.year == date.year && n.date.month == date.month;
      });
      final spent = monthlyNotes.fold<double>(0, (sum, n) => sum + n.total);
      final goal = goals[key] ?? 1000.0; 
      
      return _ReportRow(date, spent, goal, monthlyNotes.toList());
    });

    final chartData = monthlyData.reversed.toList();

    // Stats
    final totalSpent = monthlyData.fold<double>(0, (sum, row) => sum + row.spent);
    final totalNotes = minutesCount(notes);
    final avgMonthly = totalSpent / 12;
    var maxSpentRow = monthlyData.first;
    if (monthlyData.isNotEmpty) {
       maxSpentRow = monthlyData.reduce((curr, next) => curr.spent > next.spent ? curr : next);
    }
    final avgPerPurchase = notes.isNotEmpty ? totalSpent / notes.length : 0.0;

    // 2. Build PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme, // APPLY THEME
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => _buildFooter(context, l10n),
        build: (pw.Context context) {
          return [
            _buildHeader(l10n, locale),
            pw.SizedBox(height: 20),
            
            // Executive Summary (Stats)
            _buildExecutiveSummary(totalSpent, avgMonthly, maxSpentRow, avgPerPurchase, totalNotes, l10n, locale),
            pw.SizedBox(height: 20),
            
            // Chart
            TextWithDivider(l10n.pdfFinancialEvolution),
            pw.SizedBox(height: 10),
            _buildChartSection(chartData, locale, l10n),
            pw.SizedBox(height: 20),
            
            // Monthly Summary Table (THE RESTORED TABLE)
            TextWithDivider(l10n.pdfMonthlySummary),
            pw.SizedBox(height: 10),
            _buildMonthlySummaryTable(monthlyData, l10n, locale),
            pw.SizedBox(height: 20),

            // Detailed Logs
            pw.NewPage(),
            TextWithDivider(l10n.pdfDetailedLogs),
            pw.SizedBox(height: 10),
            ..._buildDetailedLog(monthlyData, l10n, locale),
          ];
        },
      ),
    );

    final filename = 'report_smart_market_${locale.languageCode}.pdf';
    await Printing.sharePdf(bytes: await pdf.save(), filename: filename);
  }

  int minutesCount(List<ShoppingNote> notes) => notes.length;

  // --- Widgets ---

  pw.Widget TextWithDivider(String text) {
     return pw.Column(
       crossAxisAlignment: pw.CrossAxisAlignment.start,
       children: [
         pw.Text(text, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
         pw.Divider(color: PdfColors.teal, thickness: 1),
       ]
     );
  }

  pw.Widget _buildHeader(AppLocalizations l10n, Locale locale) {
    return pw.Column(
      children: [
         pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Smart Market List', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                pw.Text(l10n.pdfReportTitle, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
              ]
            ),
            // pw.PdfLogo() REMOVED to avoid AssetManifest errors
          ]
        ),
        pw.SizedBox(height: 10),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            l10n.pdfGeneratedAt(DateFormat('dd/MM/yyyy HH:mm', locale.toString()).format(DateTime.now())),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)
          ),
        ),
      ],
    );
  }

  pw.Widget _buildExecutiveSummary(double total, double avg, _ReportRow maxRow, double avgPurchase, int count, AppLocalizations l10n, Locale locale) {
    final currency = NumberFormat.simpleCurrency(locale: locale.toString());
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(l10n.pdfTotalSpent, currency.format(total), isPrimary: true),
          _buildStatItem(l10n.pdfMonthlyAverage, currency.format(avg)),
          _buildStatItem(l10n.pdfHighestSpending, "${DateFormat.MMM(locale.toString()).format(maxRow.date)}: ${currency.format(maxRow.spent)}"),
          _buildStatItem(l10n.pdfAverageTicket, currency.format(avgPurchase)),
        ],
      ),
    );
  }

  pw.Widget _buildStatItem(String label, String value, {bool isPrimary = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: isPrimary ? PdfColors.teal : PdfColors.black)),
      ],
    );
  }

  pw.Widget _buildChartSection(List<_ReportRow> data, Locale locale, AppLocalizations l10n) {
    if (data.isEmpty) return pw.SizedBox();

    final maxSpent = data.isNotEmpty ? data.map((e) => e.spent).reduce((a, b) => a > b ? a : b) : 0.0;
    final maxGoal = data.isNotEmpty ? data.map((e) => e.goal).reduce((a, b) => a > b ? a : b) : 1.0;
    final overallMax = (maxSpent > maxGoal ? maxSpent : maxGoal);
    final safeMax = overallMax == 0 ? 100.0 : overallMax * 1.1;

    return pw.Container(
      height: 140,
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Column(
        children: [
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: data.map((row) {
                final spentPct = (row.spent / safeMax);
                final goalPct = (row.goal / safeMax);
                final isOver = row.spent > row.goal;

                return pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(width: 4, height: 100 * goalPct, color: PdfColors.grey300),
                        pw.SizedBox(width: 1),
                        pw.Container(width: 6, height: 100 * spentPct, color: isOver ? PdfColors.red400 : PdfColors.teal),
                      ]
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      DateFormat.MMM(locale.toString()).format(row.date).toUpperCase(), 
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)
                    ),
                  ]
                );
              }).toList(),
            ),
          ),
          pw.SizedBox(height: 5),
            pw.Row(
             mainAxisAlignment: pw.MainAxisAlignment.center,
             children: [
               pw.Container(width: 6, height: 6, color: PdfColors.grey300),
               pw.SizedBox(width: 4),
               pw.Text(l10n.pdfGoal, style: const pw.TextStyle(fontSize: 7)),
               pw.SizedBox(width: 10),
               pw.Container(width: 6, height: 6, color: PdfColors.teal),
               pw.SizedBox(width: 4),
               pw.Text(l10n.pdfSpent, style: const pw.TextStyle(fontSize: 7)),
               pw.SizedBox(width: 10),
               pw.Container(width: 6, height: 6, color: PdfColors.red400),
               pw.SizedBox(width: 4),
               pw.Text(l10n.pdfStatusOver, style: const pw.TextStyle(fontSize: 7)),
             ]
           )
        ]
      )
    );
  }

  pw.Widget _buildMonthlySummaryTable(List<_ReportRow> data, AppLocalizations l10n, Locale locale) {
    final currency = NumberFormat.simpleCurrency(locale: locale.toString());
    final dateFormat = DateFormat.MMMM(locale.toString());

    return pw.TableHelper.fromTextArray(
      headers: [l10n.pdfMonth, l10n.pdfGoal, l10n.pdfSpent, l10n.pdfStatus],
      data: data.map((row) {
        final monthName = dateFormat.format(row.date);
        final formattedMonth = "${monthName[0].toUpperCase()}${monthName.substring(1)} ${row.date.year}";
        final isOver = row.spent > row.goal;
        
        return [
          formattedMonth,
          currency.format(row.goal),
          currency.format(row.spent),
          isOver ? l10n.pdfStatusOver : l10n.pdfStatusOk,
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.center,
      },
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
    );
  }

  List<pw.Widget> _buildDetailedLog(List<_ReportRow> data, AppLocalizations l10n, Locale locale) {
    final currency = NumberFormat.simpleCurrency(locale: locale.toString());
    final dateFormat = DateFormat('dd/MM - HH:mm', locale.toString());
    final widgets = <pw.Widget>[];

    // Show newest first
    for (var row in data) {
      if (row.notes.isEmpty) continue;

      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10, bottom: 5),
          child: pw.Text(
            "${DateFormat.MMMM(locale.toString()).format(row.date).toUpperCase()} ${row.date.year} (${l10n.pdfGoal}: ${currency.format(row.goal)})",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey800)
          ),
        )
      );

      for (var note in row.notes) {
         widgets.add(
           pw.Container(
             margin: const pw.EdgeInsets.only(bottom: 10),
             decoration: pw.BoxDecoration(
               border: pw.Border.all(color: PdfColors.grey300),
               borderRadius: pw.BorderRadius.circular(4),
             ),
             child: pw.Column(
               crossAxisAlignment: pw.CrossAxisAlignment.start,
               children: [
                 // Note Header
                 pw.Container(
                   padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   color: PdfColors.grey100,
                   child: pw.Row(
                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                     children: [
                       pw.Text("${note.storeEmoji} ${note.storeName}  •  ${dateFormat.format(note.date)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                       pw.Text("${l10n.totalLabel}: ${currency.format(note.total)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                     ]
                   )
                 ),
                 // Note Items Table
                 pw.Table(
                   border: null,
                   columnWidths: {
                     0: const pw.FlexColumnWidth(3), // Item
                     1: const pw.FlexColumnWidth(1), // Qty
                     2: const pw.FlexColumnWidth(1), // Price
                   },
                   children: note.items.map((item) {
                     return pw.TableRow(
                       children: [
                         pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.name == 'Compra Geral' ? note.storeName : item.name, style: const pw.TextStyle(fontSize: 8))),
                         pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.quantity, style: const pw.TextStyle(fontSize: 8))),
                         pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(currency.format(item.price), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
                       ]
                     );
                   }).toList()
                 )
               ]
             )
           )
         );
      }
    }
    return widgets;
  }

  pw.Widget _buildFooter(pw.Context context, AppLocalizations l10n) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text('${l10n.pdfPage} ${context.pageNumber} ${l10n.pdfOf} ${context.pagesCount}', style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 8)),
    );
  }
}

class _ReportRow {
  final DateTime date;
  final double spent;
  final double goal;
  final List<ShoppingNote> notes;

  _ReportRow(this.date, this.spent, this.goal, this.notes);
}
