class StockOpnameItem {
  final int productId;
  final String productName;
  final double systemQty;
  double actualQty;

  StockOpnameItem({
    required this.productId,
    required this.productName,
    required this.systemQty,
    required this.actualQty,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'system_qty': systemQty,
      'actual_qty': actualQty,
    };
  }
}
