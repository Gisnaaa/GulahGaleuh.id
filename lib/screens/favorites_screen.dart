import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/favorite_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_widgets.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoriteProvider>();

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Favorit',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${fav.count} produk tersimpan',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (fav.count > 0)
                  SoftIconButton(
                    icon: Icons.delete_sweep_outlined,
                    tooltip: 'Hapus semua favorit',
                    onTap: () async {
                      final ok = await confirmDialog(
                        context,
                        'Hapus semua favorit?',
                        'Semua produk favorit akan dihapus dari daftar.',
                      );
                      if (ok && context.mounted) {
                        context.read<FavoriteProvider>().clear();
                      }
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: !fav.loaded
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : fav.count == 0
                ? _EmptyFavorites(
                    onShop: () {
                      // Kembali ke tab Beranda lewat shell.
                      context.go('/products');
                    },
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: kProductCardHeight,
                        ),
                    itemCount: fav.count,
                    itemBuilder: (context, i) =>
                        ProductCard(product: fav.items[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  final VoidCallback onShop;
  const _EmptyFavorites({required this.onShop});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.favorite_border_rounded,
              size: 72,
              color: AppColors.accent,
            ),
            SizedBox(height: 14),
            Text(
              'Belum ada favorit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Ketuk ikon hati pada produk\nuntuk menyimpannya di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
