import 'package:flutter/material.dart';
import '../core/constants/app_routes.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/company_selection_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/inventory/inventory_list_screen.dart';
import '../presentation/screens/inventory/inventory_detail_screen.dart';
import '../presentation/screens/inventory/create_inventory_screen.dart';
import '../presentation/screens/counting/counting_screen.dart';
import '../presentation/screens/counting/scanner_screen.dart';
import '../presentation/screens/counting/product_detail_screen.dart';
import '../presentation/screens/items/item_list_screen.dart';
import '../presentation/screens/items/item_detail_screen.dart';
import '../presentation/screens/sync/sync_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/settings/user_profile_screen.dart';
import '../presentation/screens/settings/app_preferences_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extrair argumentos da rota
    final args = settings.arguments as Map<String, dynamic>?;

    switch (settings.name) {
      // Rota inicial e splash
      case AppRoutes.splash:
        return _buildRoute(const SplashScreen(), settings);

      // Autenticação
      case AppRoutes.login:
        return _buildRoute(const LoginScreen(), settings);

      case AppRoutes.companySelection:
        return _buildRoute(const CompanySelectionScreen(), settings);

      // Tela principal
      case AppRoutes.home:
        return _buildRoute(const HomeScreen(), settings);

      // Inventários
      case AppRoutes.inventoryList:
        return _buildRoute(const InventoryListScreen(), settings);

      case AppRoutes.inventoryDetail:
        final inventoryId = args?['inventoryId'] as String?;
        if (inventoryId == null) {
          return _buildErrorRoute('ID do inventário é obrigatório');
        }
        return _buildRoute(
          InventoryDetailScreen(inventoryId: inventoryId),
          settings,
        );

      case AppRoutes.createInventory:
        return _buildRoute(const CreateInventoryScreen(), settings);

      // Contagem
      case AppRoutes.counting:
        final inventoryId = args?['inventoryId'] as String?;
        if (inventoryId == null) {
          return _buildErrorRoute('ID do inventário é obrigatório');
        }
        return _buildRoute(CountingScreen(inventoryId: inventoryId), settings);

      case AppRoutes.scanner:
        final inventoryId = args?['inventoryId'] as String?;
        if (inventoryId == null) {
          return _buildErrorRoute('ID do inventário é obrigatório');
        }
        return _buildRoute(ScannerScreen(inventoryId: inventoryId), settings);

      case AppRoutes.productDetail:
        final productCode = args?['productCode'] as String?;
        final inventoryId = args?['inventoryId'] as String?;
        if (productCode == null || inventoryId == null) {
          return _buildErrorRoute(
            'Código do produto e ID do inventário são obrigatórios',
          );
        }
        return _buildRoute(
          ProductDetailScreen(
            productCode: productCode,
            inventoryId: inventoryId,
          ),
          settings,
        );

      // Itens
      case AppRoutes.itemList:
        final inventoryId = args?['inventoryId'] as String?;
        if (inventoryId == null) {
          return _buildErrorRoute('ID do inventário é obrigatório');
        }
        return _buildRoute(ItemListScreen(inventoryId: inventoryId), settings);

      case AppRoutes.itemDetail:
        final itemId = args?['itemId'] as String?;
        if (itemId == null) {
          return _buildErrorRoute('ID do item é obrigatório');
        }
        return _buildRoute(ItemDetailScreen(itemId: itemId), settings);

      // Sincronização
      case AppRoutes.sync:
        return _buildRoute(const SyncScreen(), settings);

      // Configurações
      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen(), settings);

      case AppRoutes.userProfile:
        return _buildRoute(const UserProfileScreen(), settings);

      case AppRoutes.appPreferences:
        return _buildRoute(const AppPreferencesScreen(), settings);

      // Rota padrão/erro
      default:
        return _buildErrorRoute('Rota não encontrada: ${settings.name}');
    }
  }

  // Construir rota com transição personalizada
  static Route<dynamic> _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Transição personalizada baseada na rota
        return _getTransition(settings.name, animation, child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // Definir tipo de transição baseado na rota
  static Widget _getTransition(
    String? routeName,
    Animation<double> animation,
    Widget child,
  ) {
    switch (routeName) {
      // Transições específicas para diferentes tipos de tela
      case AppRoutes.splash:
      case AppRoutes.login:
        return FadeTransition(opacity: animation, child: child);

      case AppRoutes.scanner:
      case AppRoutes.counting:
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
          child: child,
        );

      case AppRoutes.inventoryDetail:
      case AppRoutes.itemDetail:
      case AppRoutes.productDetail:
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
          child: child,
        );

      default:
        // Transição padrão
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
          child: child,
        );
    }
  }

  // Rota de erro
  static Route<dynamic> _buildErrorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Erro de Navegação'),
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                child: const Text('Voltar ao Início'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Métodos de navegação utilitários
  static Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    return navigatorKey.currentState!.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String routeName,
    bool Function(Route<dynamic>) predicate, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      routeName,
      predicate,
      arguments: arguments,
    );
  }

  static void pop<T extends Object?>([T? result]) {
    return navigatorKey.currentState!.pop<T>(result);
  }

  static void popUntil(bool Function(Route<dynamic>) predicate) {
    return navigatorKey.currentState!.popUntil(predicate);
  }

  static bool canPop() {
    return navigatorKey.currentState!.canPop();
  }

  // Navegação específica do app
  static Future<void> goToLogin() {
    return pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  static Future<void> goToHome() {
    return pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  static Future<void> goToInventoryDetail(String inventoryId) {
    return pushNamed(
      AppRoutes.inventoryDetail,
      arguments: {'inventoryId': inventoryId},
    );
  }

  static Future<void> goToCounting(String inventoryId) {
    return pushNamed(
      AppRoutes.counting,
      arguments: {'inventoryId': inventoryId},
    );
  }

  static Future<void> goToScanner(String inventoryId) {
    return pushNamed(
      AppRoutes.scanner,
      arguments: {'inventoryId': inventoryId},
    );
  }

  static Future<void> goToProductDetail(
    String productCode,
    String inventoryId,
  ) {
    return pushNamed(
      AppRoutes.productDetail,
      arguments: {'productCode': productCode, 'inventoryId': inventoryId},
    );
  }

  static Future<void> goToItemList(String inventoryId) {
    return pushNamed(
      AppRoutes.itemList,
      arguments: {'inventoryId': inventoryId},
    );
  }

  static Future<void> goToItemDetail(String itemId) {
    return pushNamed(AppRoutes.itemDetail, arguments: {'itemId': itemId});
  }

  // Verificação de autenticação para rotas protegidas
  static bool _isProtectedRoute(String routeName) {
    const protectedRoutes = [
      AppRoutes.home,
      AppRoutes.inventoryList,
      AppRoutes.inventoryDetail,
      AppRoutes.createInventory,
      AppRoutes.counting,
      AppRoutes.scanner,
      AppRoutes.productDetail,
      AppRoutes.itemList,
      AppRoutes.itemDetail,
      AppRoutes.sync,
      AppRoutes.settings,
      AppRoutes.userProfile,
      AppRoutes.appPreferences,
    ];

    return protectedRoutes.contains(routeName);
  }

  // Middleware para verificar autenticação
  static Route<dynamic> generateRouteWithAuth(
    RouteSettings settings,
    AuthProvider authProvider,
  ) {
    // Se a rota é protegida e o usuário não está autenticado
    if (_isProtectedRoute(settings.name!) && !authProvider.isAuthenticated) {
      return generateRoute(const RouteSettings(name: AppRoutes.login));
    }

    // Se o usuário está autenticado mas não selecionou empresa
    if (_isProtectedRoute(settings.name!) &&
        authProvider.isAuthenticated &&
        authProvider.selectedCompany == null &&
        settings.name != AppRoutes.companySelection) {
      return generateRoute(
        const RouteSettings(name: AppRoutes.companySelection),
      );
    }

    return generateRoute(settings);
  }

  // Limpar stack de navegação (útil para logout)
  static void clearNavigationStack() {
    navigatorKey.currentState!.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }
}
