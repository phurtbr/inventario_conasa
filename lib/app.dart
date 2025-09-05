import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation/app_router.dart';
import 'navigation/main_navigation.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_strings.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/connectivity_provider.dart';
import 'presentation/providers/sync_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';

class ConasaApp extends StatefulWidget {
  const ConasaApp({Key? key}) : super(key: key);

  @override
  State<ConasaApp> createState() => _ConasaAppState();
}

class _ConasaAppState extends State<ConasaApp> with WidgetsBindingObserver {
  bool _isInitialized = false;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final connectivityProvider = context.read<ConnectivityProvider>();
    final syncProvider = context.read<SyncProvider>();

    switch (state) {
      case AppLifecycleState.resumed:
        // App voltou ao foco
        connectivityProvider.startMonitoring();
        if (connectivityProvider.canSync && syncProvider.autoSyncEnabled) {
          syncProvider.performIncrementalSync();
        }
        break;
      case AppLifecycleState.paused:
        // App foi para background
        if (syncProvider.isSyncing) {
          syncProvider.pauseSync();
        }
        break;
      case AppLifecycleState.inactive:
        // App perdeu foco temporariamente
        break;
      case AppLifecycleState.detached:
        // App está sendo finalizado
        connectivityProvider.stopMonitoring();
        break;
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Aguardar um frame para garantir que o contexto esteja disponível
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      // Inicializar providers em ordem
      await _initializeProviders();

      // Aguardar tempo mínimo de splash
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Erro na inicialização do app: $e');
      setState(() {
        _initializationError = e.toString();
        _isInitialized = true; // Permite mostrar a tela de erro
      });
    }
  }

  Future<void> _initializeProviders() async {
    final authProvider = context.read<AuthProvider>();
    final connectivityProvider = context.read<ConnectivityProvider>();
    final syncProvider = context.read<SyncProvider>();

    // Inicializar conectividade
    await connectivityProvider.initialize();

    // Tentar fazer login automático se há credenciais salvas
    await authProvider.attemptAutoLogin();

    // Se está autenticado e conectado, fazer sincronização inicial
    if (authProvider.isAuthenticated && connectivityProvider.canSync) {
      await syncProvider.performIncrementalSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SplashScreen();
    }

    if (_initializationError != null) {
      return _buildErrorScreen();
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return MaterialApp(
          title: 'Inventário Conasa',
          navigatorKey: AppRouter.navigatorKey,
          initialRoute: _getInitialRoute(authProvider),
          onGenerateRoute: (settings) =>
              AppRouter.generateRouteWithAuth(settings, authProvider),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return _AppWrapper(child: child!);
          },
        );
      },
    );
  }

  String _getInitialRoute(AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) {
      return AppRoutes.login;
    }

    if (authProvider.selectedCompany == null) {
      return AppRoutes.companySelection;
    }

    return AppRoutes.home;
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.initializationError,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _initializationError ?? AppStrings.unknownError,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _retryInitialization,
                child: const Text(AppStrings.tryAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _retryInitialization() {
    setState(() {
      _isInitialized = false;
      _initializationError = null;
    });
    _initializeApp();
  }
}

class _AppWrapper extends StatelessWidget {
  final Widget child;

  const _AppWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [child, _buildGlobalOverlays(context)]);
  }

  Widget _buildGlobalOverlays(BuildContext context) {
    return Consumer2<ConnectivityProvider, SyncProvider>(
      builder: (context, connectivityProvider, syncProvider, child) {
        return Stack(
          children: [
            // Banner de conectividade
            if (!connectivityProvider.isConnected)
              _buildConnectivityBanner(context, connectivityProvider),

            // Indicador de sincronização global
            if (syncProvider.isSyncing)
              _buildSyncIndicator(context, syncProvider),
          ],
        );
      },
    );
  }

  Widget _buildConnectivityBanner(
    BuildContext context,
    ConnectivityProvider provider,
  ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Material(
          elevation: 4,
          color: Theme.of(context).colorScheme.error,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off,
                  color: Theme.of(context).colorScheme.onError,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.noInternetConnection,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => provider.forceReconnect(),
                  child: Text(
                    AppStrings.retry,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncIndicator(BuildContext context, SyncProvider syncProvider) {
    return Positioned(
      bottom: 100,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surface,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                syncProvider.currentOperationDescription.isNotEmpty
                    ? syncProvider.currentOperationDescription
                    : AppStrings.syncing,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget personalizado para navegação principal
class MainNavigationWrapper extends StatelessWidget {
  final int initialIndex;
  final String? initialInventoryId;

  const MainNavigationWrapper({
    Key? key,
    this.initialIndex = 0,
    this.initialInventoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MainNavigation(
      initialIndex: initialIndex,
      initialInventoryId: initialInventoryId,
    );
  }
}

// Middleware para verificação de autenticação
class AuthGuard extends StatelessWidget {
  final Widget child;
  final bool requiresAuth;
  final bool requiresCompanySelection;

  const AuthGuard({
    Key? key,
    required this.child,
    this.requiresAuth = true,
    this.requiresCompanySelection = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Se não requer autenticação, mostrar widget diretamente
        if (!requiresAuth) {
          return child;
        }

        // Se requer autenticação mas não está autenticado
        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
          });
          return const Center(child: CircularProgressIndicator());
        }

        // Se requer seleção de empresa mas não há empresa selecionada
        if (requiresCompanySelection && authProvider.selectedCompany == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.companySelection,
              (route) => false,
            );
          });
          return const Center(child: CircularProgressIndicator());
        }

        // Se tudo está OK, mostrar o widget
        return child;
      },
    );
  }
}

// Provider personalizado para facilitar acesso aos providers
class AppProviders {
  static AuthProvider auth(BuildContext context, {bool listen = true}) {
    return Provider.of<AuthProvider>(context, listen: listen);
  }

  static ConnectivityProvider connectivity(
    BuildContext context, {
    bool listen = true,
  }) {
    return Provider.of<ConnectivityProvider>(context, listen: listen);
  }

  static SyncProvider sync(BuildContext context, {bool listen = true}) {
    return Provider.of<SyncProvider>(context, listen: listen);
  }

  static InventoryProvider inventory(
    BuildContext context, {
    bool listen = true,
  }) {
    return Provider.of<InventoryProvider>(context, listen: listen);
  }

  static CountingProvider counting(BuildContext context, {bool listen = true}) {
    return Provider.of<CountingProvider>(context, listen: listen);
  }
}

// Extensões para facilitar navegação
extension AppNavigation on BuildContext {
  void showLoading() {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void hideLoading() {
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop();
    }
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(this).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: AppStrings.dismiss,
          textColor: Theme.of(this).colorScheme.onError,
          onPressed: () => ScaffoldMessenger.of(this).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: AppStrings.dismiss,
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(this).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void showInfoDialog({
    required String title,
    required String message,
    String? confirmText,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          if (onConfirm != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text(confirmText ?? AppStrings.confirm),
            ),
        ],
      ),
    );
  }

  Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
  }) async {
    final result = await showDialog<bool>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText ?? AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText ?? AppStrings.confirm),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
