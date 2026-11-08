import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  static const _storageKey = 'cart_items';

  final List<CartItem> _items = [];
  bool _loaded = false;

  CartProvider() {
    _load();
  }

  // ---------------- READ ----------------
  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  bool get loaded => _loaded;

  /// Total jumlah barang (akumulasi quantity) — untuk badge.
  int get totalQuantity => _items.fold(0, (s, i) => s + i.quantity);

  double get totalPrice => _items.fold(0.0, (s, i) => s + i.subtotal);

  int quantityOf(int productId) {
    final idx = _items.indexWhere((i) => i.productId == productId);
    return idx == -1 ? 0 : _items[idx].quantity;
  }

  // ---------------- CREATE ----------------
  /// Mengembalikan null jika sukses, atau pesan error jika gagal.
  String? addToCart(Product product, {int qty = 1}) {
    if (product.stock <= 0) return 'Stok produk habis';

    final idx = _items.indexWhere((i) => i.productId == product.id);
    if (idx == -1) {
      _items.add(
        CartItem.fromProduct(product, quantity: qty.clamp(1, product.stock)),
      );
    } else {
      final current = _items[idx];
      final next = current.quantity + qty;
      if (next > current.stock) {
        return 'Jumlah melebihi stok (${current.stock})';
      }
      _items[idx] = current.copyWith(quantity: next);
    }
    _commit();
    return null;
  }

  // ---------------- UPDATE ----------------
  /// Mengembalikan null jika sukses, atau pesan error jika gagal.
  String? updateQuantity(int productId, int qty) {
    final idx = _items.indexWhere((i) => i.productId == productId);
    if (idx == -1) return 'Item tidak ditemukan';
    if (qty <= 0) {
      removeItem(productId);
      return null;
    }
    if (qty > _items[idx].stock) {
      return 'Jumlah melebihi stok (${_items[idx].stock})';
    }
    _items[idx] = _items[idx].copyWith(quantity: qty);
    _commit();
    return null;
  }

  String? increment(int productId) =>
      updateQuantity(productId, quantityOf(productId) + 1);

  String? decrement(int productId) =>
      updateQuantity(productId, quantityOf(productId) - 1);

  // ---------------- DELETE ----------------
  /// Mengembalikan index item yang dihapus (untuk fitur undo), atau -1.
  int removeItem(int productId) {
    final idx = _items.indexWhere((i) => i.productId == productId);
    if (idx == -1) return -1;
    _items.removeAt(idx);
    _commit();
    return idx;
  }

  /// Dipakai untuk "Urungkan" setelah item dihapus.
  void restoreItem(CartItem item, int index) {
    if (_items.any((i) => i.productId == item.productId)) return;
    _items.insert(index.clamp(0, _items.length), item);
    _commit();
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

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_items.map((e) => e.toJson()).toList()),
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
          ..addAll(
            list.map((e) => CartItem.fromJson(e as Map<String, dynamic>)),
          );
      }
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }
}
