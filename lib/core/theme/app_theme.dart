/// Constantes de rotas do aplicativo Inventário Conasa
/// Centralizadas para facilitar navegação e manutenção
class AppRoutes {
  // Rota inicial
  static const String initial = '/';
  static const String splash = '/splash';

  // Autenticação
  static const String serverConfig = '/server-config';
  static const String login = '/login';
  static const String companySelection = '/company-selection';

  // Navegação principal
  static const String main = '/main';
  static const String home = '/home';

  // Inventários
  static const String inventoryList = '/inventory-list';
  static const String inventoryDetail = '/inventory-detail';
  static const String inventorySync = '/inventory-sync';
  static const String inventoryHistory = '/inventory-history';

  // Contagem
  static const String counting = '/counting';
  static const String scanner = '/scanner';
  static const String productDetail = '/product-detail';
  static const String productSearch = '/product-search';
  static const String photoCapture = '/photo-capture';
  static const String photoViewer = '/photo-viewer';
  static const String tagScanner = '/tag-scanner';

  // Itens
  static const String itemsList = '/items-list';
  static const String itemDetail = '/item-detail';
  static const String itemEdit = '/item-edit';

  // Configurações
  static const String settings = '/settings';
  static const String userProfile = '/user-profile';
  static const String appSettings = '/app-settings';
  static const String about = '/about';
  static const String help = '/help';

  // Sincronização
  static const String syncStatus = '/sync-status';
  static const String syncHistory = '/sync-history';
  static const String dataExport = '/data-export';
  static const String dataImport = '/data-import';

  // Utilitários
  static const String networkStatus = '/network-status';
  static const String debugInfo = '/debug-info';

  // Rotas com parâmetros
  static String inventoryDetailWithId(String id) => '$inventoryDetail/$id';
  static String productDetailWithCode(String code) => '$productDetail/$code';
  static String itemDetailWithId(String id) => '$itemDetail/$id';
  static String photoCaptureWithParams(
    String inventoryId,
    String productCode,
  ) => '$photoCapture/$inventoryId/$productCode';
  static String photoViewerWithPath(String photoPath) =>
      '$photoViewer?path=$photoPath';

  // Parâmetros de query
  static const String paramInventoryId = 'inventoryId';
  static const String paramProductCode = 'productCode';
  static const String paramItemId = 'itemId';
  static const String paramPhotoPath = 'photoPath';
  static const String paramPhotoIndex = 'photoIndex';
  static const String paramReturnTo = 'returnTo';
  static const String paramMode = 'mode';
  static const String paramFilter = 'filter';
  static const String paramSort = 'sort';

  // Modos de operação
  static const String modeView = 'view';
  static const String modeEdit = 'edit';
  static const String modeAdd = 'add';
  static const String modeDelete = 'delete';
  static const String modeCounting = 'counting';
  static const String modeReview = 'review';

  // Grupos de rotas para verificações
  static const List<String> publicRoutes = [splash, serverConfig, login];

  static const List<String> authRequiredRoutes = [
    companySelection,
    main,
    home,
    inventoryList,
    inventoryDetail,
    counting,
    itemsList,
    settings,
  ];

  static const List<String> mainNavigationRoutes = [
    inventoryList,
    counting,
    itemsList,
    settings,
  ];

  static const List<String> scannerRoutes = [scanner, tagScanner];

  static const List<String> photoRoutes = [photoCapture, photoViewer];

  // Métodos utilitários
  static bool isPublicRoute(String route) {
    return publicRoutes.contains(route);
  }

  static bool requiresAuth(String route) {
    return authRequiredRoutes.any((authRoute) => route.startsWith(authRoute));
  }

  static bool isMainNavigationRoute(String route) {
    return mainNavigationRoutes.any((navRoute) => route.startsWith(navRoute));
  }

  static bool isScannerRoute(String route) {
    return scannerRoutes.any((scanRoute) => route.startsWith(scanRoute));
  }

  static bool isPhotoRoute(String route) {
    return photoRoutes.any((photoRoute) => route.startsWith(photoRoute));
  }

  // Extração de parâmetros de rotas
  static String? extractInventoryId(String route) {
    final regex = RegExp(r'/inventory-detail/([^/]+)');
    final match = regex.firstMatch(route);
    return match?.group(1);
  }

  static String? extractProductCode(String route) {
    final regex = RegExp(r'/product-detail/([^/]+)');
    final match = regex.firstMatch(route);
    return match?.group(1);
  }

  static String? extractItemId(String route) {
    final regex = RegExp(r'/item-detail/([^/]+)');
    final match = regex.firstMatch(route);
    return match?.group(1);
  }

  // Construção de rotas com query parameters
  static String buildRouteWithQuery(
    String route,
    Map<String, String> queryParams,
  ) {
    if (queryParams.isEmpty) return route;

    final queryString = queryParams.entries
        .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value)}')
        .join('&');

    return '$route?$queryString';
  }

  // Rotas de retorno padrão
  static const String defaultReturnRoute = inventoryList;
  static const String defaultAuthRoute = login;
  static const String defaultMainRoute = main;

  // Rotas de erro
  static const String notFound = '/not-found';
  static const String error = '/error';
  static const String networkError = '/network-error';
  static const String authError = '/auth-error';

  // Deep links (para futuras implementações)
  static const String deepLinkScheme = 'inventario-conasa';
  static const String deepLinkHost = 'app.conasa.com';

  static String buildDeepLink(String path) {
    return '$deepLinkScheme://$deepLinkHost$path';
  }
}
