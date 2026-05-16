class ProductSuggestion {
  final String name;
  final String category;
  final String defaultQuantity;
  final String imageUrl;
  final double price;

  const ProductSuggestion({
    required this.name,
    required this.category,
    required this.defaultQuantity,
    required this.imageUrl,
    this.price = 0.0,
  });
}
