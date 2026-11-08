import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_widgets.dart';

enum _Sort { newest, priceLow, priceHigh, rating, discount }

const Map<_Sort, String> _sortLabels = {
  _Sort.newest: 'Default',
  _Sort.priceLow: 'Harga terendah',
  _Sort.priceHigh: 'Harga tertinggi',
  _Sort.rating: 'Rating tertinggi',
  _Sort.discount: 'Diskon terbesar',
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _banner = PageController();
  Timer? _debounce;
  String _selectedCategory = '';
  _Sort _sort = _Sort.newest;
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ProductProvider>();
      if (p.products.isEmpty) p.fetchProducts();
      p.fetchCategories();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _banner.dispose();
    super.dispose();
  }

  // ---------------- Aksi ----------------
  Future<void> _reload() async {
    final p = context.read<ProductProvider>();
    final q = _searchController.text.trim();
    if (q.isNotEmpty) {
      await p.searchProducts(q);
    } else {
      await p.filterByCategory(_selectedCategory);
    }
    if (!mounted) return;
    await p.fetchCategories();
  }

  void _onSearchChanged(String text) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _runSearch(text);
    });
  }

  void _runSearch(String text) {
    final q = text.trim();
    final p = context.read<ProductProvider>();
    if (q.isEmpty) {
      p.filterByCategory(_selectedCategory);
    } else {
      setState(() => _selectedCategory = '');
      p.searchProducts(q);
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {});
    context.read<ProductProvider>().filterByCategory(_selectedCategory);
  }

  void _selectCategory(String cat) {
    FocusScope.of(context).unfocus();
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _selectedCategory = cat);
    context.read<ProductProvider>().filterByCategory(cat);
  }

  void _openSort() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Urutkan produk',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              for (final e in _sortLabels.entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    e.value,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: _sort == e.key
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () {
                    setState(() => _sort = e.key);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Data turunan ----------------
  List<Product> _sorted(List<Product> src) {
    final list = [...src];
    switch (_sort) {
      case _Sort.priceLow:
        list.sort((a, b) => a.discountedPrice.compareTo(b.discountedPrice));
        break;
      case _Sort.priceHigh:
        list.sort((a, b) => b.discountedPrice.compareTo(a.discountedPrice));
        break;
      case _Sort.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _Sort.discount:
        list.sort(
          (a, b) => b.discountPercentage.compareTo(a.discountPercentage),
        );
        break;
      case _Sort.newest:
        break;
    }
    return list;
  }

  List<Product> _featured(List<Product> src) {
    final list = src.where((p) => p.hasDiscount).toList()
      ..sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
    return list.take(8).toList();
  }

  // ---------------- Tampilan ----------------
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final userName = context.watch<AuthProvider>().user?.name ?? 'Pengguna';
    final cartVisible = context.select<CartProvider, bool>((c) => !c.isEmpty);

    final query = _searchController.text.trim();
    final filtering = query.isNotEmpty || _selectedCategory.isNotEmpty;
    final products = _sorted(provider.products);
    final featured = _featured(provider.products);
    final showPromo = !filtering && !provider.loading && featured.isNotEmpty;

    final String resultTitle = query.isNotEmpty
        ? 'Hasil untuk "$query"'
        : _selectedCategory.isNotEmpty
        ? prettyCategory(_selectedCategory)
        : 'Semua produk';

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(child: _header(userName)),
                SliverToBoxAdapter(child: _searchRow()),
                SliverToBoxAdapter(child: _chips(provider)),
                if (showPromo) ...[
                  SliverToBoxAdapter(child: _promo(featured.take(3).toList())),
                  SliverToBoxAdapter(child: _sectionTitle('Produk unggulan')),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: kProductCardHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: featured.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => SizedBox(
                          width: 168,
                          child: ProductCard(product: featured[i]),
                        ),
                      ),
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  child: _sectionTitle(
                    resultTitle,
                    trailing: provider.loading
                        ? null
                        : '${products.length} produk',
                  ),
                ),
                if (provider.loading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                else if (products.isEmpty)
                  SliverToBoxAdapter(child: _emptyState(provider))
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => ProductCard(product: products[i]),
                        childCount: products.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: kProductCardHeight,
                          ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(height: cartVisible ? 96 : 28),
                ),
              ],
            ),
          ),
          const Positioned(left: 20, right: 20, bottom: 12, child: _CartBar()),
        ],
      ),
    );
  }

  Widget _header(String name) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat datang kembali',
                  style: TextStyle(fontSize: 11.5, color: AppColors.secondary),
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const CartIconButton(),
        ],
      ),
    );
  }

  Widget _searchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: AppStyle.panel(radius: 16),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                cursorColor: AppColors.primary,
                onChanged: _onSearchChanged,
                onSubmitted: (t) {
                  _debounce?.cancel();
                  _runSearch(t);
                },
                decoration: InputDecoration(
                  hintText: 'Cari produk',
                  hintStyle: TextStyle(
                    color: AppColors.secondary.withValues(alpha: 0.7),
                    fontSize: 13.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                          onPressed: _clearSearch,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              SoftIconButton(
                icon: Icons.tune_rounded,
                size: 52,
                tooltip: 'Urutkan',
                onTap: _openSort,
              ),
              if (_sort != _Sort.newest)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bg, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chips(ProductProvider provider) {
    if (provider.categoryList.isEmpty) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: provider.categoryList.length + 1,
          itemBuilder: (context, index) {
            final cat = index == 0 ? '' : provider.categoryList[index - 1];
            final label = index == 0 ? 'Semua' : prettyCategory(cat);
            final selected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _selectCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.blue : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _promo(List<Product> items) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          SizedBox(
            height: 156,
            child: PageView.builder(
              controller: _banner,
              itemCount: items.length,
              onPageChanged: (i) => setState(() => _bannerIndex = i),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _PromoCard(product: items[i]),
              ),
            ),
          ),
          if (items.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                items.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _bannerIndex ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _bannerIndex
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.primary,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.secondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(ProductProvider provider) {
    final failed = provider.error != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 0),
      child: Column(
        children: [
          Icon(
            failed ? Icons.cloud_off_rounded : Icons.search_off_rounded,
            size: 52,
            color: AppColors.accent,
          ),
          const SizedBox(height: 12),
          Text(
            failed
                ? 'Gagal memuat produk.\nPeriksa koneksi lalu coba lagi.'
                : 'Tidak ada produk yang cocok.\nCoba kata kunci lain.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.secondary, fontSize: 14),
          ),
          if (failed) ...[
            const SizedBox(height: 16),
            AppButton(label: 'Coba lagi', onPressed: _reload),
          ],
        ],
      ),
    );
  }
}

/// Banner promo: produk dengan diskon terbesar.
class _PromoCard extends StatelessWidget {
  final Product product;
  const _PromoCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/detail/${product.id}'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.blue, AppColors.accentLight],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 0, 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diskon ${product.discountPercentage.round()}%',
                      style: const TextStyle(
                        fontSize: 24,
                        height: 1.1,
                        letterSpacing: -0.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          formatPrice(product.discountedPrice),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            formatPrice(product.price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Belanja sekarang',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 130,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: product.thumbnail.isEmpty
                    ? const Icon(
                        Icons.shopping_bag_rounded,
                        size: 64,
                        color: AppColors.primary,
                      )
                    : CachedNetworkImage(
                        imageUrl: product.thumbnail,
                        fit: BoxFit.contain,
                        errorWidget: (_, _, _) => const Icon(
                          Icons.broken_image,
                          color: AppColors.secondary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bar mengambang "Lihat keranjang" saat keranjang berisi barang.
class _CartBar extends StatelessWidget {
  const _CartBar();

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (cart.isEmpty) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => context.push('/cart'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text(
                  'Lihat keranjang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${cart.totalQuantity}x',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  formatPrice(cart.totalPrice),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
