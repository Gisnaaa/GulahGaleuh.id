import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/auth_provider.dart';
import 'navigation/main_shell.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/detail_product_screen.dart';
import 'screens/edit_product_screen.dart';
import 'screens/cart_screen.dart';
import 'models/product_model.dart';
import 'theme/app_theme.dart';

final AuthProvider _auth = AuthProvider();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _auth.init(); // Pulihkan sesi login dari SharedPreferences
  runApp(const MyApp());
}

// Konfigurasi GoRouter dengan alur: Welcome -> Login -> MainShell
final GoRouter _router = GoRouter(
  refreshListenable: _auth,
  initialLocation: '/',
  redirect: (context, state) {
    final loc = state.matchedLocation;

    // Jika belum login dan memaksa masuk ke /main, arahkan ke /login
    if (!_auth.isLoggedIn && (loc == '/main' || loc == '/products')) {
      return '/login';
    }

    return null;
  },
  routes: [
    // 1. Halaman awal (Welcome Screen)
    GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
    // 2. Halaman Login
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    // 3. Halaman Utama / Home (MainShell)
    GoRoute(path: '/main', builder: (context, state) => const MainShell()),
    // Rute cadangan jika ada yang memanggil /products
    GoRoute(path: '/products', builder: (context, state) => const MainShell()),
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
    GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
  ],
);

const double kMobileWidth = 412;
const double kMobileHeight = 892;

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
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
      ],
      child: MaterialApp.router(
        title: 'GG.ID',
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
        builder: (context, child) =>
            _isWebOrDesktop ? MobileFrame(child: child!) : child!,
      ),
    );
  }
}

class MobileFrame extends StatelessWidget {
  final Widget child;
  const MobileFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final w = media.size.width < kMobileWidth ? media.size.width : kMobileWidth;
    final h = media.size.height < kMobileHeight
        ? media.size.height
        : kMobileHeight;

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
                color: AppColors.primary.withValues(alpha: 0.18),
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
