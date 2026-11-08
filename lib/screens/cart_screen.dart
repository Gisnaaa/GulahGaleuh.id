import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _snack(BuildContext context, String msg, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(color: AppColors.primary)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.blue,
          action: action,
          persist: false,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<bool> _confirm(
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

  void _removeWithUndo(BuildContext context, CartItem item) {
    final cart = context.read<CartProvider>();
    final idx = cart.removeItem(item.productId);
    if (idx == -1) return;
    _snack(
      context,
      '${item.title} dihapus',
      action: SnackBarAction(
        label: 'Urungkan',
        textColor: AppColors.primary,
        onPressed: () => cart.restoreItem(item, idx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  SoftIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
                  const Spacer(),
                  if (!cart.isEmpty)
                    SoftIconButton(
                      icon: Icons.delete_sweep_outlined,
                      tooltip: 'Kosongkan keranjang',
                      onTap: () async {
                        final ok = await _confirm(
                          context,
                          'Kosongkan keranjang?',
                          'Semua barang di keranjang akan dihapus.',
                        );
                        if (ok && context.mounted) {
                          context.read<CartProvider>().clear();
                        }
                      },
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Keranjang',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cart.totalQuantity} barang',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: !cart.loaded
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : cart.isEmpty
                  ? _EmptyCart(onShop: () => context.go('/products'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final item = cart.items[i];
                        return Dismissible(
                          key: ValueKey(item.productId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red.shade700,
                            ),
                          ),
                          onDismissed: (_) => _removeWithUndo(context, item),
                          child: _CartTile(
                            item: item,
                            onTap: () =>
                                context.push('/detail/${item.productId}'),
                            onDelete: () => _removeWithUndo(context, item),
                            onMinus: () {
                              final err = cart.decrement(item.productId);
                              if (err != null) _snack(context, err);
                            },
                            onPlus: () {
                              final err = cart.increment(item.productId);
                              if (err != null) _snack(context, err);
                            },
                          ),
                        );
                      },
                    ),
            ),
            if (!cart.isEmpty)
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
                          'Total',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.secondary,
                          ),
                        ),
                        Text(
                          '\$${cart.totalPrice.toStringAsFixed(2)}',
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
                        label: 'Checkout',
                        onPressed: () async {
                          final ok = await _confirm(
                            context,
                            'Konfirmasi pesanan',
                            'Total \$${cart.totalPrice.toStringAsFixed(2)} '
                                'untuk ${cart.totalQuantity} barang. Lanjutkan?',
                          );
                          if (ok && context.mounted) {
                            context.read<CartProvider>().clear();
                            _snack(context, 'Pesanan berhasil dibuat 🎉');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onTap, onDelete, onMinus, onPlus;

  const _CartTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppStyle.panel(radius: 20),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: item.thumbnail.isEmpty
                  ? const Icon(
                      Icons.shopping_bag_rounded,
                      color: AppColors.primary,
                    )
                  : CachedNetworkImage(
                      imageUrl: item.thumbnail,
                      fit: BoxFit.contain,
                      errorWidget: (_, _, _) => const Icon(
                        Icons.broken_image,
                        color: AppColors.secondary,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      _QtyButton(icon: Icons.remove_rounded, onTap: onMinus),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      _QtyButton(icon: Icons.add_rounded, onTap: onPlus),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.chip,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onShop;
  const _EmptyCart({required this.onShop});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 72,
              color: AppColors.accent,
            ),
            const SizedBox(height: 14),
            const Text(
              'Keranjangmu masih kosong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Yuk, tambahkan produk favoritmu.',
              style: TextStyle(fontSize: 13, color: AppColors.secondary),
            ),
            const SizedBox(height: 20),
            AppButton(label: 'Mulai belanja', onPressed: onShop),
          ],
        ),
      ),
    );
  }
}
