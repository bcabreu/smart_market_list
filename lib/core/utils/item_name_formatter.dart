String formatItemName(String value) {
  final normalizedWhitespace = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalizedWhitespace.isEmpty) return normalizedWhitespace;

  return normalizedWhitespace[0].toUpperCase() +
      normalizedWhitespace.substring(1);
}
