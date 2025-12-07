import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final String locale;

  CurrencyInputFormatter({this.locale = 'pt_BR'});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;
    final isPt = locale.startsWith('pt');
    final separator = isPt ? ',' : '.';
    final unwanted = isPt ? '.' : ',';

    // Swap separators if user typed the wrong one
    if (newText.contains(unwanted)) {
      newText = newText.replaceAll(unwanted, separator);
    }

    // If user deleted, just return
    if (newValue.selection.baseOffset < oldValue.selection.baseOffset) {
      return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newValue.selection.baseOffset),
      );
    }

    // Validate format
    // 1. Only digits and separator
    final pattern = isPt ? r'^[0-9,]*$' : r'^[0-9.]*$';
    if (!RegExp(pattern).hasMatch(newText)) {
      return oldValue;
    }

    // 2. Only one separator
    if (newText.indexOf(separator) != newText.lastIndexOf(separator)) {
      return oldValue;
    }

    // 3. Max 2 decimal places
    if (newText.contains(separator)) {
      final parts = newText.split(separator);
      if (parts.length > 1 && parts[1].length > 2) {
        return oldValue;
      }
    }

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
