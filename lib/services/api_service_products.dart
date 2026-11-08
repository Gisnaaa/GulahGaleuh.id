import 'package:dio/dio.dart';

import '../models/product_model.dart'; // Sesuaikan dengan path model kamu

class ApiServiceProducts {
  final Dio _dio = Dio(
    BaseOptions(
      // UBAH BASE_URL INI KE BACKEND DOCKER KAMU:
      // - Port API PHP = 8080 (8081 adalah phpMyAdmin).
      // - Gunakan 'http://10.0.2.2:8080/products' jika menggunakan Emulator Android.
      // - Gunakan IP lokal PC (misal: 'http://192.168.1.x:8080/products') jika menggunakan HP fisik.
      baseUrl: 'http://10.182.31.211:8080/products',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<ProductsResponse> getAllProducts({
    int limit = 30,
    int skip = 0,
  }) async {
    final res = await _dio.get(
      '',
      queryParameters: {'limit': limit, 'skip': skip},
    );
    return ProductsResponse.fromJson(res.data);
  }

  Future<Product> getProduct(int id) async {
    final res = await _dio.get('/$id');
    return Product.fromJson(res.data);
  }

  /// Pencarian di sisi app: ambil daftar produk (endpoint list yang sudah
  /// berfungsi), lalu saring berdasarkan judul, kategori, brand, deskripsi,
  /// dan tag. Tidak bergantung pada parameter `q` di backend.
  Future<ProductsResponse> searchProducts(String query) async {
    final q = query.trim().toLowerCase();
    final all = await getAllProducts(limit: 200, skip: 0);

    final filtered = all.products.where((p) {
      return p.title.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();

    return ProductsResponse(
      products: filtered,
      total: filtered.length,
      skip: 0,
      limit: filtered.length,
    );
  }

  Future<ProductsResponse> getProductsPaginated({
    int limit = 10,
    int skip = 0,
    String? select,
  }) async {
    Map<String, dynamic> params = {'limit': limit, 'skip': skip};
    if (select != null) params['select'] = select;
    final res = await _dio.get('', queryParameters: params);
    return ProductsResponse.fromJson(res.data);
  }

  Future<ProductsResponse> sortProducts(String sortBy, String order) async {
    final res = await _dio.get(
      '',
      queryParameters: {'sortBy': sortBy, 'order': order},
    );
    return ProductsResponse.fromJson(res.data);
  }

  Future<List<Category>> getCategories() async {
    final res = await _dio.get('/categories');
    return (res.data as List).map((e) => Category.fromJson(e)).toList();
  }

  Future<List<String>> getCategoryList() async {
    final res = await _dio.get('/category-list');
    return (res.data as List).map((e) => e.toString()).toList();
  }

  Future<ProductsResponse> getProductsByCategory(String category) async {
    final res = await _dio.get('/category/$category');
    return ProductsResponse.fromJson(res.data);
  }

  Future<Product> addProduct(Map<String, dynamic> data) async {
    final res = await _dio.post('/add', data: data);
    return Product.fromJson(res.data);
  }

  Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('/$id', data: data);
    return Product.fromJson(res.data);
  }

  Future<Product> patchProduct(int id, Map<String, dynamic> partialData) async {
    final res = await _dio.patch('/$id', data: partialData);
    return Product.fromJson(res.data);
  }

  Future<Product> deleteProduct(int id) async {
    final res = await _dio.delete('/$id');
    return Product.fromJson(res.data);
  }
}
