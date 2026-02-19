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

class Unit {
  final int id;
  final String name;

  Unit({required this.id, required this.name});

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
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
  final int? unitId;
  final String unit;
  final int? categoryId;
  final String? categoryName;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    this.unitId,
    required this.unit,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      unitId: json['unit_id'],
      unit: json['unit'] ?? '-',
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      imageUrl: json['image_url'],
    );
  }
}
