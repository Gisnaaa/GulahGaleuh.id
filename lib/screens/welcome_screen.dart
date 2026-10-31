import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  final PageController _page = PageController(viewportFraction: 0.78);
  Timer? _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ProductProvider>();
      if (p.products.isEmpty) p.fetchProducts();
    });
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_page.hasClients) return;
      final count = math.min(3, context.read<ProductProvider>().products.length);
      if (count < 2) return;
      _page.animateToPage(
        (_current + 1) % count,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    _float.dispose();
    _intro.dispose();
    super.dispose();
  }

  Widget _reveal(double start, double end, Widget child) {
    final anim = CurvedAnimation(
      parent: _intro,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  Widget _perk(IconData icon, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: AppStyle.panel(radius: 16),
          child: Column(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _productImage(String url) {
    const fallback =
        Icon(Icons.shopping_bag_rounded, size: 120, color: AppColors.primary);
    if (url.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      errorWidget: (_, __, ___) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final urls = provider.products.take(3).map((e) => e.thumbnail).toList();
    final items = urls.isEmpty ? [''] : urls;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reveal(
                0.0,
                0.5,
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'GulahGaleuh',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              _reveal(
                0.1,
                0.7,
                const Text(
                  'Temukan yang\nkamu butuhkan.',
                  style: TextStyle(
                    fontSize: 34,
                    height: 1.1,
                    letterSpacing: -1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _reveal(
                0.25,
                0.85,
                const Text(
                  'Jelajahi ratusan produk, cari dengan cepat, '
                  'dan kelola katalogmu sendiri.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Panel lengkung berisi carousel produk
              Expanded(
                child: Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.accentLight, AppColors.blue],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(170),
                      topRight: Radius.circular(170),
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _float,
                    builder: (context, _) {
                      final t = Curves.easeInOut.transform(_float.value);
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 40, bottom: 40),
                            child: Transform.translate(
                              offset: Offset(0, -10 * t),
                              child: PageView.builder(
                                controller: _page,
                                itemCount: items.length,
                                onPageChanged: (i) =>
                                    setState(() => _current = i),
                                itemBuilder: (_, i) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: _productImage(items[i]),
                                ),
                              ),
                            ),
                          ),
                          if (items.length > 1)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    items.length,
                                    (i) => AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      width: i == _current ? 22 : 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: i == _current
                                            ? AppColors.primary
                                            : AppColors.primary
                                                .withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),
              _reveal(
                0.5,
                1.0,
                Row(
                  children: [
                    _perk(Icons.local_shipping_outlined, 'Gratis ongkir'),
                    const SizedBox(width: 10),
                    _perk(Icons.verified_outlined, 'Original'),
                    const SizedBox(width: 10),
                    _perk(Icons.bolt_rounded, 'Cepat sampai'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _reveal(
                0.6,
                1.0,
                AppButton(
                  label: 'Mulai belanja',
                  icon: Icons.arrow_forward_rounded,
                  width: double.infinity,
                  onPressed: () => context.go('/products'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}