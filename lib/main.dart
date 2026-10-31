import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/product_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/list_product_screen.dart';
import 'screens/detail_product_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/edit_product_screen.dart';
import 'models/product_model.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => const ListProductScreen(),
    ),
    GoRoute(
      path: '/detail/:id',
      builder: (context, state) =>
          DetailProductScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/edit/:id',
      builder: (context, state) =>
          EditProductScreen(product: state.extra as Product),
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) => const AddProductScreen(),
    ),
  ],
);

/// Ukuran layar mobile yang dipakai saat run di web / desktop.
const double kMobileWidth = 412;
const double kMobileHeight = 892;

/// true jika app jalan di web atau desktop (bukan Android/iOS).
bool get _isWebOrDesktop =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.macOS;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp.router(
        title: 'GulahGaleuh.id',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.blue,
            surface: AppColors.bg,
          ),
          scaffoldBackgroundColor: AppColors.bg,
        ),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
        // Android/iOS: tampil penuh. Web/desktop: dipaksa ukuran mobile.
        builder: (context, child) =>
            _isWebOrDesktop ? MobileFrame(child: child!) : child!,
      ),
    );
  }
}

/// Memaksa tampilan berukuran layar ponsel di tengah jendela.
class MobileFrame extends StatelessWidget {
  final Widget child;
  const MobileFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final w = media.size.width < kMobileWidth ? media.size.width : kMobileWidth;
    final h =
        media.size.height < kMobileHeight ? media.size.height : kMobileHeight;

    return ColoredBox(
      color: const Color(0xFFCFE4F6),
      child: Center(
        child: Container(
          width: w,
          height: h,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(h < kMobileHeight ? 0 : 28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.18),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: MediaQuery(
            data: media.copyWith(size: Size(w, h)),
            child: child,
          ),
        ),
      ),
    );
  }
}