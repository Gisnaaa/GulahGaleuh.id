import '../models/product_model.dart';

class CartItem {
  final int productId;
  final String title;
  final String thumbnail;
  final double price;
  final int stock;
  final int quantity;

  const CartItem({
    required this.productId,
    required this.title,
    required this.thumbnail,
    required this.price,
    required this.stock,
    this.quantity = 1,
  });

  factory CartItem.fromProduct(Product p, {int quantity = 1}) => CartItem(
    productId: p.id,
    title: p.title,
    thumbnail: p.thumbnail,
    price: p.price,
    stock: p.stock,
    quantity: quantity,
  );

  double get subtotal => price * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
    productId: productId,
    title: title,
    thumbnail: thumbnail,
    price: price,
    stock: stock,
    quantity: quantity ?? this.quantity,
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'title': title,
    'thumbnail': thumbnail,
    'price': price,
    'stock': stock,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    productId: json['productId'] ?? 0,
    title: json['title'] ?? '',
    thumbnail: json['thumbnail'] ?? '',
    price: (json['price'] ?? 0).toDouble(),
    stock: json['stock'] ?? 0,
    quantity: json['quantity'] ?? 1,
  );
}
