import 'package:mobile_pos/Screens/Products/Model/product_model.dart';

class ProductListResponse {
  final double totalStockValue;
  final List<Product> products;

  ProductListResponse({
    required this.totalStockValue,
    required this.products,
  });

  factory ProductListResponse.fromJson(Map<String, dynamic> json) {
    // Safely parse total_stock_value, handling both num and String types
    double totalStockValue = 0.0;
    final totalStockValueData = json['total_stock_value'];
    if (totalStockValueData != null) {
      if (totalStockValueData is num) {
        totalStockValue = totalStockValueData.toDouble();
      } else if (totalStockValueData is String) {
        totalStockValue = num.tryParse(totalStockValueData)?.toDouble() ?? 0.0;
      } else {
        totalStockValue = num.tryParse(totalStockValueData.toString())?.toDouble() ?? 0.0;
      }
    }
    
    return ProductListResponse(
      totalStockValue: totalStockValue,
      products: (json['data'] as List).map((item) => Product.fromJson(item)).toList(),
    );
  }
}
