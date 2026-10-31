import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';

class ListProductScreen extends StatefulWidget {
  const ListProductScreen({super.key});

  @override
  State<ListProductScreen> createState() => _ListProductScreenState();
}

class _ListProductScreenState extends State<ListProductScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _chipScroll = ScrollController();
  Timer? _debounce;
  String _selectedCategory = '';

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
    _chipScroll.dispose();
    super.dispose();
  }

  Future<void> _openAdd() async {
    await context.push('/add');
    if (mounted) _reload();
  }

  Future<void> _reload() async {
    final p = context.read<ProductProvider>();
    final q = _searchController.text.trim();
    if (q.isNotEmpty) {
      await p.searchProducts(q);
    } else {
      await p.filterByCategory(_selectedCategory);
    }
  }

  void _onSearchChanged(String text) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final q = text.trim();
      final p = context.read<ProductProvider>();
      if (q.isEmpty) {
        p.filterByCategory(_selectedCategory);
      } else {
        setState(() => _selectedCategory = '');
        p.searchProducts(q);
      }
    });
  }

  void _onSearchSubmitted(String text) {
    _debounce?.cancel();
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

  void _scrollChips(double delta) {
    if (!_chipScroll.hasClients) return;
    final target = (_chipScroll.offset + delta)
        .clamp(0.0, _chipScroll.position.maxScrollExtent);
    _chipScroll.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  String _pretty(String s) {
    final t = s.replaceAll('-', ' ');
    return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
  }

  String _subtitle(ProductProvider provider) {
    final q = _searchController.text.trim();
    final count = provider.loading ? '' : ' (${provider.total} produk)';
    if (q.isNotEmpty) return 'Hasil untuk "$q"$count';
    if (_selectedCategory.isNotEmpty) {
      return '${_pretty(_selectedCategory)}$count';
    }
    return 'Semua produk$count';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  SoftIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.go('/'),
                  ),
                  const Spacer(),
                  SoftIconButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Tambah produk',
                    onTap: _openAdd,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Text(
                'GulahGaleuh.id',
                style: TextStyle(
                  fontSize: 32,
                  letterSpacing: -1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 2, 22, 14),
              child: Text(
                _subtitle(provider),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondary,
                ),
              ),
            ),

            // Pencarian
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  onSubmitted: _onSearchSubmitted,
                  decoration: InputDecoration(
                    hintText: 'Cari produk',
                    hintStyle: TextStyle(
                      color: AppColors.secondary.withOpacity(0.7),
                      fontSize: 13.5,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.primary, size: 22),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.secondary, size: 20),
                            onPressed: _clearSearch,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter kategori
            if (provider.categoryList.isNotEmpty)
              SizedBox(
                height: 46,
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    SoftIconButton(
                      icon: Icons.chevron_left_rounded,
                      size: 32,
                      onTap: () => _scrollChips(-250),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _chipScroll,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        itemCount: provider.categoryList.length + 1,
                        itemBuilder: (context, index) {
                          final cat =
                              index == 0 ? '' : provider.categoryList[index - 1];
                          final label = index == 0 ? 'Semua' : _pretty(cat);
                          return _categoryChip(label, _selectedCategory == cat,
                              () => _selectCategory(cat));
                        },
                      ),
                    ),
                    SoftIconButton(
                      icon: Icons.chevron_right_rounded,
                      size: 32,
                      onTap: () => _scrollChips(250),
                    ),
                    const SizedBox(width: 14),
                  ],
                ),
              ),
            const SizedBox(height: 8),

            // Daftar produk
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await _reload();
                  if (mounted) {
                    await context.read<ProductProvider>().fetchCategories();
                  }
                },
                child: provider.loading
                    ? ListView(children: const [
                        SizedBox(height: 140),
                        Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      ])
                    : provider.products.isEmpty
                        ? ListView(children: [
                            const SizedBox(height: 100),
                            Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.search_off_rounded,
                                      size: 52, color: AppColors.accent),
                                  const SizedBox(height: 12),
                                  Text(
                                    provider.error != null
                                        ? 'Gagal memuat produk:\n${provider.error}'
                                        : 'Tidak ada produk yang cocok.\nCoba kata kunci lain.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: AppColors.secondary,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ])
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                            itemCount: provider.products.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _productTile(provider.products[index]),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
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
  }

  /// Baris produk: gambar di kiri, info di kanan.
  Widget _productTile(Product product) {
    final hasDiscount = product.discountPercentage >= 1;

    return GestureDetector(
      onTap: () => context.push('/detail/${product.id}'),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: AppStyle.panel(radius: 22),
        child: Row(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(8),
              child: Hero(
                tag: 'product-${product.id}',
                child: CachedNetworkImage(
                  imageUrl: product.thumbnail,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image,
                      color: AppColors.secondary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pretty(product.category),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: AppColors.star),
                      const SizedBox(width: 2),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.chip,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Diskon ${product.discountPercentage.round()}%',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.accent, size: 26),
          ],
        ),
      ),
    );
  }
}