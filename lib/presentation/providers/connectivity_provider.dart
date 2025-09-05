import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/constants/app_strings.dart';

enum ConnectivityType { none, mobile, wifi, ethernet, vpn }

enum NetworkQuality { excellent, good, fair, poor, none }

enum ApiStatus { available, unavailable, limited, maintenance }

class NetworkInfo {
  final ConnectivityType type;
  final String? networkName;
  final String? ipAddress;
  final int? signalStrength;
  final bool isMetered;
  final bool isRoaming;
  final NetworkQuality quality;
  final DateTime lastChecked;
  final double downloadSpeed;
  final double uploadSpeed;
  final int latency;

  NetworkInfo({
    required this.type,
    this.networkName,
    this.ipAddress,
    this.signalStrength,
    this.isMetered = false,
    this.isRoaming = false,
    this.quality = NetworkQuality.none,
    required this.lastChecked,
    this.downloadSpeed = 0.0,
    this.uploadSpeed = 0.0,
    this.latency = 0,
  });

  NetworkInfo copyWith({
    ConnectivityType? type,
    String? networkName,
    String? ipAddress,
    int? signalStrength,
    bool? isMetered,
    bool? isRoaming,
    NetworkQuality? quality,
    DateTime? lastChecked,
    double? downloadSpeed,
    double? uploadSpeed,
    int? latency,
  }) {
    return NetworkInfo(
      type: type ?? this.type,
      networkName: networkName ?? this.networkName,
      ipAddress: ipAddress ?? this.ipAddress,
      signalStrength: signalStrength ?? this.signalStrength,
      isMetered: isMetered ?? this.isMetered,
      isRoaming: isRoaming ?? this.isRoaming,
      quality: quality ?? this.quality,
      lastChecked: lastChecked ?? this.lastChecked,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      latency: latency ?? this.latency,
    );
  }

  bool get isConnected => type != ConnectivityType.none;
  bool get isWifi => type == ConnectivityType.wifi;
  bool get isMobile => type == ConnectivityType.mobile;
  bool get hasGoodConnection =>
      quality == NetworkQuality.excellent || quality == NetworkQuality.good;
}

class ApiEndpointStatus {
  final String endpoint;
  final ApiStatus status;
  final DateTime lastChecked;
  final Duration? responseTime;
  final String? errorMessage;
  final int consecutiveFailures;

  ApiEndpointStatus({
    required this.endpoint,
    required this.status,
    required this.lastChecked,
    this.responseTime,
    this.errorMessage,
    this.consecutiveFailures = 0,
  });

  ApiEndpointStatus copyWith({
    String? endpoint,
    ApiStatus? status,
    DateTime? lastChecked,
    Duration? responseTime,
    String? errorMessage,
    int? consecutiveFailures,
  }) {
    return ApiEndpointStatus(
      endpoint: endpoint ?? this.endpoint,
      status: status ?? this.status,
      lastChecked: lastChecked ?? this.lastChecked,
      responseTime: responseTime ?? this.responseTime,
      errorMessage: errorMessage ?? this.errorMessage,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
    );
  }

  bool get isAvailable => status == ApiStatus.available;
  bool get isHealthy => isAvailable && consecutiveFailures == 0;
}

class ConnectivityProvider with ChangeNotifier {
  static const Duration _networkCheckInterval = Duration(seconds: 30);
  static const Duration _apiCheckInterval = Duration(minutes: 2);
  static const int _maxConsecutiveFailures = 3;

  // Estados principais
  NetworkInfo _networkInfo = NetworkInfo(
    type: ConnectivityType.none,
    lastChecked: DateTime.now(),
    quality: NetworkQuality.none,
  );

  Map<String, ApiEndpointStatus> _apiStatuses = {};
  bool _isMonitoring = false;

  // Timers para monitoramento
  Timer? _networkMonitorTimer;
  Timer? _apiMonitorTimer;

  // Configurações
  bool _autoCheckEnabled = true;
  bool _showConnectivityAlerts = true;
  bool _trackDataUsage = true;
  int _networkTimeoutSeconds = 10;

  // Histórico e estatísticas
  List<NetworkInfo> _connectionHistory = [];
  List<ApiEndpointStatus> _apiHistory = [];
  DateTime? _lastDisconnection;
  DateTime? _lastConnection;
  Duration _totalDowntime = Duration.zero;

  // Estados de bateria e energia
  bool _isBatteryLow = false;
  bool _isCharging = false;
  bool _isPowerSaveMode = false;

  // Getters principais
  NetworkInfo get networkInfo => _networkInfo;
  Map<String, ApiEndpointStatus> get apiStatuses =>
      Map.unmodifiable(_apiStatuses);
  bool get isMonitoring => _isMonitoring;

  // Estados de conectividade
  bool get isConnected => _networkInfo.isConnected;
  bool get isWifi => _networkInfo.isWifi;
  bool get isMobile => _networkInfo.isMobile;
  bool get hasGoodConnection => _networkInfo.hasGoodConnection;
  bool get isMeteredConnection => _networkInfo.isMetered;
  bool get isRoaming => _networkInfo.isRoaming;

  // Estados da API
  bool get isApiAvailable =>
      _apiStatuses.values.any((status) => status.isAvailable);
  bool get areAllApisHealthy =>
      _apiStatuses.values.every((status) => status.isHealthy);
  List<String> get unavailableApis => _apiStatuses.entries
      .where((entry) => !entry.value.isAvailable)
      .map((entry) => entry.key)
      .toList();

  // Configurações
  bool get autoCheckEnabled => _autoCheckEnabled;
  bool get showConnectivityAlerts => _showConnectivityAlerts;
  bool get trackDataUsage => _trackDataUsage;
  int get networkTimeoutSeconds => _networkTimeoutSeconds;

  // Histórico e estatísticas
  List<NetworkInfo> get connectionHistory =>
      List.unmodifiable(_connectionHistory);
  List<ApiEndpointStatus> get apiHistory => List.unmodifiable(_apiHistory);
  DateTime? get lastDisconnection => _lastDisconnection;
  DateTime? get lastConnection => _lastConnection;
  Duration get totalDowntime => _totalDowntime;
  double get uptimePercentage {
    if (_connectionHistory.isEmpty) return 0.0;
    final totalTime = DateTime.now().difference(
      _connectionHistory.first.lastChecked,
    );
    if (totalTime.inMilliseconds == 0) return 100.0;
    return ((totalTime - _totalDowntime).inMilliseconds /
            totalTime.inMilliseconds) *
        100;
  }

  // Estados de energia
  bool get isBatteryLow => _isBatteryLow;
  bool get isCharging => _isCharging;
  bool get isPowerSaveMode => _isPowerSaveMode;
  bool get shouldReduceNetworkActivity =>
      _isBatteryLow && !_isCharging || _isPowerSaveMode;

  // Inicialização
  Future<void> initialize() async {
    await _checkNetworkStatus();
    await _initializeApiEndpoints();
    startMonitoring();
  }

  // Monitoramento automático
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;

    if (_autoCheckEnabled) {
      _networkMonitorTimer = Timer.periodic(
        _networkCheckInterval,
        (_) => _checkNetworkStatus(),
      );
      _apiMonitorTimer = Timer.periodic(
        _apiCheckInterval,
        (_) => _checkApiStatuses(),
      );
    }

    notifyListeners();
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _networkMonitorTimer?.cancel();
    _apiMonitorTimer?.cancel();
    _networkMonitorTimer = null;
    _apiMonitorTimer = null;
    notifyListeners();
  }

  // Verificação de status da rede
  Future<void> _checkNetworkStatus() async {
    try {
      final previousStatus = _networkInfo.isConnected;

      // Aqui seria implementada a lógica real de verificação de conectividade
      // usando packages como connectivity_plus, network_info_plus, etc.
      final newNetworkInfo = await _performNetworkCheck();

      _networkInfo = newNetworkInfo;
      _connectionHistory.add(_networkInfo);

      // Manter apenas últimas 100 entradas do histórico
      if (_connectionHistory.length > 100) {
        _connectionHistory.removeAt(0);
      }

      // Detectar mudanças de conectividade
      if (previousStatus != _networkInfo.isConnected) {
        if (_networkInfo.isConnected) {
          _lastConnection = DateTime.now();
          if (_lastDisconnection != null) {
            _totalDowntime =
                _totalDowntime +
                _lastConnection!.difference(_lastDisconnection!);
          }
        } else {
          _lastDisconnection = DateTime.now();
        }

        if (_showConnectivityAlerts) {
          _showConnectivityAlert();
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao verificar status da rede: $e');
    }
  }

  Future<NetworkInfo> _performNetworkCheck() async {
    // Simulação - na implementação real usaria packages específicos
    return NetworkInfo(
      type: ConnectivityType.wifi, // Seria detectado dinamicamente
      networkName: 'Conasa-WiFi',
      ipAddress: '192.168.1.100',
      signalStrength: 85,
      isMetered: false,
      isRoaming: false,
      quality: NetworkQuality.good,
      lastChecked: DateTime.now(),
      downloadSpeed: 50.0,
      uploadSpeed: 25.0,
      latency: 45,
    );
  }

  // Verificação de APIs
  Future<void> _initializeApiEndpoints() async {
    final endpoints = [
      'http://protheus.conasa.com:8890/rest/auth',
      'http://protheus.conasa.com:8890/rest/Z75',
      'http://protheus.conasa.com:8890/rest/Z76',
      'http://protheus.conasa.com:8890/rest/cstProduto',
      'http://protheus.conasa.com:8890/rest/cstInventario',
    ];

    for (final endpoint in endpoints) {
      _apiStatuses[endpoint] = ApiEndpointStatus(
        endpoint: endpoint,
        status: ApiStatus.unavailable,
        lastChecked: DateTime.now(),
      );
    }

    await _checkApiStatuses();
  }

  Future<void> _checkApiStatuses() async {
    if (!_networkInfo.isConnected) {
      // Marcar todas as APIs como indisponíveis se não há conexão
      _apiStatuses.forEach((endpoint, status) {
        _apiStatuses[endpoint] = status.copyWith(
          status: ApiStatus.unavailable,
          lastChecked: DateTime.now(),
          errorMessage: AppStrings.noInternetConnection,
        );
      });
      notifyListeners();
      return;
    }

    for (final endpoint in _apiStatuses.keys) {
      await _checkSingleApiEndpoint(endpoint);
    }

    notifyListeners();
  }

  Future<void> _checkSingleApiEndpoint(String endpoint) async {
    try {
      final startTime = DateTime.now();

      // Aqui seria feita a requisição HTTP real para verificar o endpoint
      // usando dio, http, ou outro cliente HTTP
      final isAvailable = await _performApiHealthCheck(endpoint);

      final responseTime = DateTime.now().difference(startTime);
      final currentStatus = _apiStatuses[endpoint]!;

      if (isAvailable) {
        _apiStatuses[endpoint] = currentStatus.copyWith(
          status: ApiStatus.available,
          lastChecked: DateTime.now(),
          responseTime: responseTime,
          errorMessage: null,
          consecutiveFailures: 0,
        );
      } else {
        final newFailureCount = currentStatus.consecutiveFailures + 1;
        _apiStatuses[endpoint] = currentStatus.copyWith(
          status: newFailureCount >= _maxConsecutiveFailures
              ? ApiStatus.unavailable
              : ApiStatus.limited,
          lastChecked: DateTime.now(),
          responseTime: responseTime,
          errorMessage: AppStrings.apiEndpointUnavailable,
          consecutiveFailures: newFailureCount,
        );
      }

      _apiHistory.add(_apiStatuses[endpoint]!);

      // Manter apenas últimas 50 entradas por endpoint
      _apiHistory = _apiHistory
          .where(
            (status) =>
                _apiHistory
                    .where((s) => s.endpoint == status.endpoint)
                    .length <=
                50,
          )
          .toList();
    } catch (e) {
      final currentStatus = _apiStatuses[endpoint]!;
      _apiStatuses[endpoint] = currentStatus.copyWith(
        status: ApiStatus.unavailable,
        lastChecked: DateTime.now(),
        errorMessage: e.toString(),
        consecutiveFailures: currentStatus.consecutiveFailures + 1,
      );

      debugPrint('Erro ao verificar endpoint $endpoint: $e');
    }
  }

  Future<bool> _performApiHealthCheck(String endpoint) async {
    // Simulação - na implementação real faria requisição HTTP
    await Future.delayed(Duration(milliseconds: 200));
    return DateTime.now().millisecondsSinceEpoch % 4 != 0; // 75% de sucesso
  }

  // Verificações manuais
  Future<void> checkNetworkNow() async {
    await _checkNetworkStatus();
  }

  Future<void> checkApisNow() async {
    await _checkApiStatuses();
  }

  Future<void> checkSpecificApi(String endpoint) async {
    if (_apiStatuses.containsKey(endpoint)) {
      await _checkSingleApiEndpoint(endpoint);
      notifyListeners();
    }
  }

  // Teste de velocidade da rede
  Future<void> performSpeedTest() async {
    if (!_networkInfo.isConnected) return;

    try {
      final startTime = DateTime.now();

      // Simulação de teste de velocidade
      // Na implementação real seria usado um serviço de teste de velocidade
      await Future.delayed(Duration(seconds: 3));

      final testDuration = DateTime.now().difference(startTime);

      _networkInfo = _networkInfo.copyWith(
        downloadSpeed: 45.5, // Mbps simulado
        uploadSpeed: 22.3, // Mbps simulado
        latency: 38, // ms simulado
        lastChecked: DateTime.now(),
        quality: _calculateNetworkQuality(45.5, 22.3, 38),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Erro no teste de velocidade: $e');
    }
  }

  NetworkQuality _calculateNetworkQuality(
    double download,
    double upload,
    int latency,
  ) {
    if (download >= 25 && upload >= 10 && latency <= 50) {
      return NetworkQuality.excellent;
    } else if (download >= 10 && upload >= 5 && latency <= 100) {
      return NetworkQuality.good;
    } else if (download >= 5 && upload >= 2 && latency <= 200) {
      return NetworkQuality.fair;
    } else if (download >= 1 && upload >= 0.5) {
      return NetworkQuality.poor;
    } else {
      return NetworkQuality.none;
    }
  }

  // Alertas e notificações
  void _showConnectivityAlert() {
    // Aqui seria implementada a lógica para mostrar alertas
    // usando SnackBar, Dialog, ou notificações push
    debugPrint(
      _networkInfo.isConnected
          ? 'Conectividade restaurada: ${_networkInfo.type.name}'
          : 'Conectividade perdida',
    );
  }

  // Configurações
  void setAutoCheckEnabled(bool enabled) {
    _autoCheckEnabled = enabled;
    if (enabled && !_isMonitoring) {
      startMonitoring();
    } else if (!enabled && _isMonitoring) {
      stopMonitoring();
    }
    notifyListeners();
  }

  void setShowConnectivityAlerts(bool show) {
    _showConnectivityAlerts = show;
    notifyListeners();
  }

  void setTrackDataUsage(bool track) {
    _trackDataUsage = track;
    notifyListeners();
  }

  void setNetworkTimeout(int seconds) {
    _networkTimeoutSeconds = seconds;
    notifyListeners();
  }

  // Estados de bateria e energia
  void updateBatteryStatus(
    bool isBatteryLow,
    bool isCharging,
    bool isPowerSaveMode,
  ) {
    _isBatteryLow = isBatteryLow;
    _isCharging = isCharging;
    _isPowerSaveMode = isPowerSaveMode;

    // Ajustar frequência de monitoramento baseado no estado da bateria
    if (_isMonitoring && shouldReduceNetworkActivity) {
      _adjustMonitoringFrequency(reduce: true);
    } else if (_isMonitoring && !shouldReduceNetworkActivity) {
      _adjustMonitoringFrequency(reduce: false);
    }

    notifyListeners();
  }

  void _adjustMonitoringFrequency({required bool reduce}) {
    _networkMonitorTimer?.cancel();
    _apiMonitorTimer?.cancel();

    if (reduce) {
      // Reduzir frequência para economizar bateria
      _networkMonitorTimer = Timer.periodic(
        Duration(minutes: 2),
        (_) => _checkNetworkStatus(),
      );
      _apiMonitorTimer = Timer.periodic(
        Duration(minutes: 5),
        (_) => _checkApiStatuses(),
      );
    } else {
      // Frequência normal
      _networkMonitorTimer = Timer.periodic(
        _networkCheckInterval,
        (_) => _checkNetworkStatus(),
      );
      _apiMonitorTimer = Timer.periodic(
        _apiCheckInterval,
        (_) => _checkApiStatuses(),
      );
    }
  }

  // Diagnósticos e relatórios
  Map<String, dynamic> generateDiagnosticReport() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'network': {
        'type': _networkInfo.type.name,
        'isConnected': _networkInfo.isConnected,
        'quality': _networkInfo.quality.name,
        'downloadSpeed': _networkInfo.downloadSpeed,
        'uploadSpeed': _networkInfo.uploadSpeed,
        'latency': _networkInfo.latency,
        'signalStrength': _networkInfo.signalStrength,
        'isMetered': _networkInfo.isMetered,
        'isRoaming': _networkInfo.isRoaming,
      },
      'apis': _apiStatuses.map(
        (endpoint, status) => MapEntry(endpoint, {
          'status': status.status.name,
          'lastChecked': status.lastChecked.toIso8601String(),
          'responseTime': status.responseTime?.inMilliseconds,
          'consecutiveFailures': status.consecutiveFailures,
          'errorMessage': status.errorMessage,
        }),
      ),
      'statistics': {
        'uptimePercentage': uptimePercentage,
        'totalDowntime': _totalDowntime.inMinutes,
        'lastConnection': _lastConnection?.toIso8601String(),
        'lastDisconnection': _lastDisconnection?.toIso8601String(),
        'connectionHistoryCount': _connectionHistory.length,
        'apiHistoryCount': _apiHistory.length,
      },
      'configuration': {
        'autoCheckEnabled': _autoCheckEnabled,
        'showConnectivityAlerts': _showConnectivityAlerts,
        'trackDataUsage': _trackDataUsage,
        'networkTimeoutSeconds': _networkTimeoutSeconds,
      },
      'battery': {
        'isBatteryLow': _isBatteryLow,
        'isCharging': _isCharging,
        'isPowerSaveMode': _isPowerSaveMode,
        'shouldReduceNetworkActivity': shouldReduceNetworkActivity,
      },
    };
  }

  // Utilitários
  String getConnectionSummary() {
    if (!_networkInfo.isConnected) {
      return AppStrings.noConnection;
    }

    final qualityText = _getQualityText(_networkInfo.quality);
    final typeText = _getConnectionTypeText(_networkInfo.type);

    return '$typeText - $qualityText';
  }

  String getApiStatusSummary() {
    final availableCount = _apiStatuses.values
        .where((s) => s.isAvailable)
        .length;
    final totalCount = _apiStatuses.length;

    if (availableCount == totalCount) {
      return AppStrings.allApisAvailable;
    } else if (availableCount == 0) {
      return AppStrings.allApisUnavailable;
    } else {
      return '$availableCount de $totalCount APIs disponíveis';
    }
  }

  String _getQualityText(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return AppStrings.excellentConnection;
      case NetworkQuality.good:
        return AppStrings.goodConnection;
      case NetworkQuality.fair:
        return AppStrings.fairConnection;
      case NetworkQuality.poor:
        return AppStrings.poorConnection;
      case NetworkQuality.none:
        return AppStrings.noConnection;
    }
  }

  String _getConnectionTypeText(ConnectivityType type) {
    switch (type) {
      case ConnectivityType.wifi:
        return 'Wi-Fi';
      case ConnectivityType.mobile:
        return 'Dados Móveis';
      case ConnectivityType.ethernet:
        return 'Ethernet';
      case ConnectivityType.vpn:
        return 'VPN';
      case ConnectivityType.none:
        return 'Desconectado';
    }
  }

  // Verificações condicionais
  bool canPerformHeavyOperations() {
    return _networkInfo.isConnected &&
        _networkInfo.hasGoodConnection &&
        !shouldReduceNetworkActivity &&
        (!_networkInfo.isMetered || isWifi);
  }

  bool canPerformLightOperations() {
    return _networkInfo.isConnected &&
        (_networkInfo.quality != NetworkQuality.none);
  }

  bool shouldUseWifiOnly() {
    return _networkInfo.isMetered || _isBatteryLow || _isPowerSaveMode;
  }

  // Limpeza de dados
  void clearHistory() {
    _connectionHistory.clear();
    _apiHistory.clear();
    _totalDowntime = Duration.zero;
    _lastConnection = null;
    _lastDisconnection = null;
    notifyListeners();
  }

  void clearApiStatuses() {
    _apiStatuses.forEach((endpoint, status) {
      _apiStatuses[endpoint] = status.copyWith(
        consecutiveFailures: 0,
        errorMessage: null,
      );
    });
    notifyListeners();
  }

  // Forçar reconexão
  Future<void> forceReconnect() async {
    await _checkNetworkStatus();
    await _checkApiStatuses();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
