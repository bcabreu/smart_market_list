import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;

    // Replace dot with comma
    if (newText.contains('.')) {
      newText = newText.replaceAll('.', ',');
    }

    // If user deleted, just return
    if (newValue.selection.baseOffset < oldValue.selection.baseOffset) {
      return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newValue.selection.baseOffset),
      );
    }

    // Validate format
    // 1. Only digits and comma
    if (!RegExp(r'^[0-9,]*$').hasMatch(newText)) {
      return oldValue;
    }

    // 2. Only one comma
    if (newText.indexOf(',') != newText.lastIndexOf(',')) {
      return oldValue;
    }

    // 3. Max 2 decimal places
    if (newText.contains(',')) {
      final parts = newText.split(',');
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
