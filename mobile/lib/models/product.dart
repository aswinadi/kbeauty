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
  final double? price;
  final int? unitId;
  final String unit;
  final int? secondaryUnitId;
  final String? secondaryUnitName;
  final double? conversionRatio;
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
    this.secondaryUnitId,
    this.secondaryUnitName,
    this.conversionRatio,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      unitId: json['unit_id'],
      unit: json['unit'] ?? '-',
      secondaryUnitId: json['secondary_unit_id'],
      secondaryUnitName: json['secondary_unit_name'],
      conversionRatio: json['conversion_ratio'] != null 
          ? double.tryParse(json['conversion_ratio'].toString()) 
          : null,
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      imageUrl: json['image_url'],
    );
  }
}
