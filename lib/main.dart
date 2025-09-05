import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/constants/app_colors.dart';
import 'data/services/database_service.dart';
import 'data/services/api_service.dart';
import 'data/services/sync_service.dart';
import 'data/services/photo_service.dart';
import 'data/local/preferences_helper.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/inventory_repository.dart';
import 'data/repositories/sync_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/inventory_provider.dart';
import 'presentation/providers/counting_provider.dart';
import 'presentation/providers/sync_provider.dart';
import 'presentation/providers/connectivity_provider.dart';

void main() async {
  // Garantir que o Flutter esteja inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientação da tela (apenas retrato)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configurar barra de status
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Inicializar serviços
  await _initializeServices();

  // Executar aplicativo
  runApp(const InventoryApp());
}

Future<void> _initializeServices() async {
  try {
    // Inicializar banco de dados local
    final databaseService = DatabaseService();
    await databaseService.initialize();

    // Inicializar SharedPreferences
    final preferencesHelper = PreferencesHelper();
    await preferencesHelper.initialize();

    debugPrint('✅ Serviços inicializados com sucesso');
  } catch (e) {
    debugPrint('❌ Erro ao inicializar serviços: $e');
    // Em produção, aqui poderia ser implementado um crash reporting
  }
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _buildProviders(),
      child: Consumer<ConnectivityProvider>(
        builder: (context, connectivityProvider, child) {
          return MaterialApp(
            title: 'Inventário Conasa',
            debugShowCheckedModeBanner: false,

            // Configuração de tema
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: ThemeMode.system,

            // Configuração de navegação
            home: const ConasaApp(),

            // Configurações de localização
            supportedLocales: const [Locale('pt', 'BR')],
            locale: const Locale('pt', 'BR'),

            // Configurações de performance
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: 1.0, // Fixar escala de texto
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }

  List<ChangeNotifierProvider> _buildProviders() {
    // Instanciar serviços
    final databaseService = DatabaseService();
    final apiService = ApiService();
    final syncService = SyncService(databaseService, apiService);
    final photoService = PhotoService(databaseService);
    final preferencesHelper = PreferencesHelper();

    // Instanciar repositórios
    final authRepository = AuthRepository(apiService, preferencesHelper);
    final inventoryRepository = InventoryRepository(
      databaseService,
      apiService,
    );
    final syncRepository = SyncRepository(
      syncService,
      databaseService,
      apiService,
    );

    return [
      // Provider de autenticação
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(authRepository),
      ),

      // Provider de conectividade
      ChangeNotifierProvider<ConnectivityProvider>(
        create: (_) => ConnectivityProvider()..initialize(),
      ),

      // Provider de sincronização
      ChangeNotifierProvider<SyncProvider>(
        create: (_) => SyncProvider(syncRepository),
      ),

      // Provider de inventários
      ChangeNotifierProvider<InventoryProvider>(
        create: (_) => InventoryProvider(inventoryRepository),
      ),

      // Provider de contagem
      ChangeNotifierProvider<CountingProvider>(
        create: (_) => CountingProvider(inventoryRepository, photoService),
      ),
    ];
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.conaprimary,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.conaprimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.conaprimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.conaprimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.conaprimary,
        foregroundColor: Colors.white,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.conaprimary,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.conaprimary.withOpacity(0.9),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.conaprimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.conaprimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.conaprimary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
