class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Product {
  final int id;
  final String name;
  final String sku;
  final double price;
  final String unit;
  final String? categoryName;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.unit,
    this.categoryName,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      sku: json['sku'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      unit: json['unit'],
      categoryName: json['category_name'],
      imageUrl: json['image_url'],
    );
  }
}
