import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/favorite_provider.dart';
import '../theme/app_theme.dart';

const Color kStockRed = Color(0xFFD9534F);
const Color kHeartRed = Color(0xFFE5566D);

/// Tinggi kartu produk (dipakai grid dan daftar horizontal).
const double kProductCardHeight = 262;

String formatPrice(double v) => '\$${v.toStringAsFixed(2)}';

String prettyCategory(String s) {
  final t = s.replaceAll('-', ' ');
  return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}

void showAppToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: AppColors.primary)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.blue,
        persist: false,
        duration: const Duration(seconds: 2),
      ),
    );
}

Future<bool> confirmDialog(
  BuildContext context,
  String title,
  String message,
) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(color: AppColors.secondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Ya'),
        ),
      ],
    ),
  );
  return res ?? false;
}

/// Tombol keranjang dengan badge jumlah barang.
class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
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
    );
  }
}

/// Kartu produk: gambar dengan pil harga diskon, harga awal dicoret,
/// label persen diskon, sisa stok, rating, judul, dan tombol keranjang.
/// Tinggi kartu ditentukan oleh parent ([kProductCardHeight]).
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final soldOut = product.stock <= 0;

    return GestureDetector(
      onTap: () => context.push('/detail/${product.id}'),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: AppStyle.panel(radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 118,
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: product.thumbnail.isEmpty
                      ? const Icon(
                          Icons.shopping_bag_rounded,
                          color: AppColors.primary,
                        )
                      : CachedNetworkImage(
                          imageUrl: product.thumbnail,
                          fit: BoxFit.contain,
                          placeholder: (_, _) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          errorWidget: (_, _, _) => const Icon(
                            Icons.broken_image,
                            color: AppColors.secondary,
                          ),
                        ),
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary, width: 1),
                      ),
                      child: Text(
                        '-${product.discountPercentage.round()}%',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                Positioned(top: 6, right: 6, child: _HeartButton(product)),
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      formatPrice(product.discountedPrice),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      soldOut ? 'Stok habis' : 'Sisa ${product.stock} stok',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: kStockRed,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.star,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (product.hasDiscount) ...[
                          Flexible(
                            child: Text(
                              formatPrice(product.price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.secondary,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppColors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        const Spacer(),
                        SoftIconButton(
                          size: 32,
                          icon: Icons.add_shopping_cart_rounded,
                          tooltip: 'Tambah ke keranjang',
                          onTap: () {
                            final err = context.read<CartProvider>().addToCart(
                              product,
                            );
                            showAppToast(
                              context,
                              err ??
                                  '${product.title} ditambahkan ke keranjang',
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeartButton extends StatelessWidget {
  final Product product;
  const _HeartButton(this.product);

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteProvider>(
      builder: (context, fav, _) {
        final isFav = fav.isFavorite(product.id);
        return GestureDetector(
          onTap: () {
            final added = fav.toggle(product);
            showAppToast(
              context,
              added ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit',
            );
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 17,
              color: isFav ? kHeartRed : AppColors.secondary,
            ),
          ),
        );
      },
    );
  }
}
