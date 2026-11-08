import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';

/// Menyimpan produk favorit secara lokal (SharedPreferences).
class FavoriteProvider extends ChangeNotifier {
  static const _storageKey = 'favorite_products';

  final List<Product> _items = [];
  bool _loaded = false;

  FavoriteProvider() {
    _load();
  }

  List<Product> get items => List.unmodifiable(_items);
  bool get loaded => _loaded;
  int get count => _items.length;

  bool isFavorite(int productId) => _items.any((p) => p.id == productId);

  /// Mengembalikan true jika produk sekarang menjadi favorit.
  bool toggle(Product product) {
    final idx = _items.indexWhere((p) => p.id == product.id);
    if (idx == -1) {
      _items.insert(0, product);
    } else {
      _items.removeAt(idx);
    }
    _commit();
    return idx == -1;
  }

  void clear() {
    _items.clear();
    _commit();
  }

  // ---------------- PERSISTENCE ----------------
  void _commit() {
    notifyListeners();
    _save();
  }

  Map<String, dynamic> _toMap(Product p) => {
    'id': p.id,
    'title': p.title,
    'description': p.description,
    'category': p.category,
    'price': p.price,
    'discountPercentage': p.discountPercentage,
    'rating': p.rating,
    'stock': p.stock,
    'brand': p.brand,
    'thumbnail': p.thumbnail,
  };

  Product _fromMap(Map<String, dynamic> m) => Product(
    id: m['id'] ?? 0,
    title: m['title'] ?? '',
    description: m['description'] ?? '',
    category: m['category'] ?? '',
    price: (m['price'] ?? 0).toDouble(),
    discountPercentage: (m['discountPercentage'] ?? 0).toDouble(),
    rating: (m['rating'] ?? 0).toDouble(),
    stock: m['stock'] ?? 0,
    brand: m['brand'] ?? '',
    thumbnail: m['thumbnail'] ?? '',
  );

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_items.map(_toMap).toList()),
      );
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _items
          ..clear()
          ..addAll(list.map((e) => _fromMap(e as Map<String, dynamic>)));
      }
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }
}
