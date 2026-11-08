import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../services/api_service_products.dart';
import '../theme/app_theme.dart';
import '../providers/cart_provider.dart';

class DetailProductScreen extends StatefulWidget {
  final String id;

  const DetailProductScreen({super.key, required this.id});

  @override
  State<DetailProductScreen> createState() => _DetailProductScreenState();
}

class _DetailProductScreenState extends State<DetailProductScreen> {
  final ApiServiceProducts _api = ApiServiceProducts();
  late Future<Product> _productFuture;
  bool _favorite = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _productFuture = _api.getProduct(int.parse(widget.id));
  }

  Future<void> _openEdit(Product product) async {
    await context.push('/edit/${product.id}', extra: product);
    if (mounted) setState(_load);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: AppColors.primary)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.blue,
      ),
    );
  }

  String _pretty(String s) {
    final t = s.replaceAll('-', ' ');
    return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
  }

  Widget _tag(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.chip,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FutureBuilder<Product>(
          future: _productFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Gagal memuat produk:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
              );
            } else if (!snapshot.hasData) {
              return const Center(child: Text('Produk tidak ditemukan'));
            }

            final product = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SoftIconButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: () => context.pop(),
                            ),
                            const Spacer(),
                            SoftIconButton(
                              icon: Icons.edit_outlined,
                              tooltip: 'Edit produk',
                              onTap: () => _openEdit(product),
                            ),
                            const SizedBox(width: 10),
                            // Tombol keranjang dengan badge jumlah item dinamis
                            Consumer<CartProvider>(
                              builder: (context, cart, _) => Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  SoftIconButton(
                                    icon: Icons.shopping_cart_outlined,
                                    tooltip: 'Keranjang',
                                    onTap: () => context.push('/cart'),
                                  ),
                                  if (cart.totalQuantity > 0)
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '${cart.totalQuantity}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Panel gambar besar
                        Container(
                          width: double.infinity,
                          height: 300,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [AppColors.accentLight, AppColors.blue],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(120),
                              topRight: Radius.circular(120),
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(28),
                                  child: Hero(
                                    tag: 'product-${product.id}',
                                    child: CachedNetworkImage(
                                      imageUrl: product.thumbnail,
                                      fit: BoxFit.contain,
                                      placeholder: (_, _) => const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      errorWidget: (_, _, _) => const Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 14,
                                bottom: 14,
                                child: SoftIconButton(
                                  icon: _favorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  tooltip: 'Favorit',
                                  onTap: () =>
                                      setState(() => _favorite = !_favorite),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          product.title,
                          style: const TextStyle(
                            fontSize: 25,
                            height: 1.15,
                            letterSpacing: -0.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _tag(
                              Icons.star_rounded,
                              product.rating.toStringAsFixed(1),
                            ),
                            _tag(
                              Icons.category_outlined,
                              _pretty(product.category),
                            ),
                            _tag(
                              Icons.sell_outlined,
                              product.brand.isEmpty ? 'Generic' : product.brand,
                            ),
                            _tag(
                              Icons.inventory_2_outlined,
                              'Stok ${product.stock}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          product.description,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.secondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bilah bawah: harga + tombol tambah ke keranjang
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    border: Border(
                      top: BorderSide(color: AppColors.border, width: 1.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Harga',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.secondary,
                            ),
                          ),
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: AppButton(
                          label: 'Tambah ke keranjang',
                          onPressed: () {
                            final err = context.read<CartProvider>().addToCart(
                              product,
                            );
                            _toast(
                              err ??
                                  '${product.title} ditambahkan ke keranjang',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
