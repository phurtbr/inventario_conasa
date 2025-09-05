import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync_service.dart';
import '../services/database_service.dart';
import '../local/preferences_helper.dart';

/// Repository para gerenciamento de sincronização
/// Coordena operações de sync entre app e servidor
class SyncRepository {
  static SyncRepository? _instance;
  static SyncRepository get instance => _instance ??= SyncRepository._();

  SyncRepository._();

  final SyncService _syncService = SyncService.instance;
  final DatabaseService _dbService = DatabaseService.instance;
  final Connectivity _connectivity = Connectivity();

  /// Realizar sincronização completa
  Future<SyncResult> performFullSync() async {
    try {
      final result = await _syncService.fullSync();

      // Salvar timestamp da última sincronização se foi bem-sucedida
      if (result.isSuccess) {
        await PreferencesHelper.setLastSyncAt(DateTime.now());
      }

      return result;
    } catch (e) {
      return SyncResult.error('Erro na sincronização: $e');
    }
  }

  /// Sincronizar apenas dados básicos
  Future<SyncResult> syncBasicData() async {
    try {
      return await _syncService.syncBasicData();
    } catch (e) {
      return SyncResult.error('Erro ao sincronizar dados básicos: $e');
    }
  }

  /// Sincronizar apenas dados pendentes
  Future<SyncResult> syncPendingData() async {
    try {
      return await _syncService.uploadPendingData();
    } catch (e) {
      return SyncResult.error('Erro ao sincronizar dados pendentes: $e');
    }
  }

  /// Sincronizar apenas fotos pendentes
  Future<SyncResult> syncPendingPhotos() async {
    try {
      return await _syncService.uploadPendingPhotos();
    } catch (e) {
      return SyncResult.error('Erro ao sincronizar fotos: $e');
    }
  }

  /// Verificar status de conectividade
  Future<ConnectivityInfo> checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final hasInternet = await _syncService.hasInternetConnection();

      return ConnectivityInfo(
        connectivityResult: connectivityResult,
        hasInternetAccess: hasInternet,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return ConnectivityInfo(
        connectivityResult: ConnectivityResult.none,
        hasInternetAccess: false,
        timestamp: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Obter status atual de sincronização
  Future<SyncStatusInfo> getSyncStatus() async {
    try {
      // Obter dados pendentes
      final pendingData = await _dbService.getPendingSyncData();

      final pendingBatches = pendingData['inventory_batches']?.length ?? 0;
      final pendingItems = pendingData['inventory_items']?.length ?? 0;
      final pendingPhotos = pendingData['photos']?.length ?? 0;

      final totalPending = pendingBatches + pendingItems + pendingPhotos;

      // Obter última sincronização
      final lastSyncAt = await PreferencesHelper.getLastSyncAt();

      // Verificar conectividade
      final connectivity = await checkConnectivity();

      return SyncStatusInfo(
        isUpToDate: totalPending == 0,
        pendingBatches: pendingBatches,
        pendingItems: pendingItems,
        pendingPhotos: pendingPhotos,
        totalPending: totalPending,
        lastSyncAt: lastSyncAt,
        hasConnectivity: connectivity.hasInternetAccess,
        isSyncing: _syncService.isSyncing,
      );
    } catch (e) {
      return SyncStatusInfo(
        isUpToDate: false,
        pendingBatches: 0,
        pendingItems: 0,
        pendingPhotos: 0,
        totalPending: 0,
        lastSyncAt: null,
        hasConnectivity: false,
        isSyncing: false,
        error: e.toString(),
      );
    }
  }

  /// Configurar sincronização automática
  Future<void> configureAutoSync({
    required bool enabled,
    int intervalMinutes = 30,
  }) async {
    await PreferencesHelper.setAutoSync(enabled);
    await PreferencesHelper.setSyncInterval(intervalMinutes);
  }

  /// Verificar se deve fazer sincronização automática
  Future<bool> shouldAutoSync() async {
    try {
      // Verificar se auto-sync está habilitado
      final autoSyncEnabled = await PreferencesHelper.isAutoSyncEnabled();
      if (!autoSyncEnabled) return false;

      // Verificar conectividade
      if (!await _syncService.hasInternetConnection()) return false;

      // Verificar se não está sincronizando
      if (_syncService.isSyncing) return false;

      // Verificar intervalo
      final lastSyncAt = await PreferencesHelper.getLastSyncAt();
      final syncInterval = await PreferencesHelper.getSyncInterval();

      if (lastSyncAt == null) return true;

      final nextSyncTime = lastSyncAt.add(Duration(minutes: syncInterval));
      return DateTime.now().isAfter(nextSyncTime);
    } catch (e) {
      return false;
    }
  }

  /// Executar sincronização automática se necessário
  Future<SyncResult?> autoSyncIfNeeded() async {
    try {
      if (await shouldAutoSync()) {
        return await _syncService.autoSync().then(
          (_) => SyncResult.success('Sincronização automática executada'),
        );
      }
      return null;
    } catch (e) {
      return SyncResult.error('Erro na sincronização automática: $e');
    }
  }

  /// Obter histórico de sincronização
  Future<List<SyncLogEntry>> getSyncHistory({int limit = 50}) async {
    try {
      final db = await _dbService.database;

      final logs = await db.query(
        'sync_logs',
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return logs.map((log) => SyncLogEntry.fromMap(log)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Limpar dados de sincronização antigos
  Future<void> cleanupOldSyncData() async {
    try {
      await _syncService.cleanupOldSyncData();
    } catch (e) {
      print('Erro ao limpar dados antigos: $e');
    }
  }

  /// Resetar status de sincronização
  Future<void> resetSyncStatus() async {
    try {
      final db = await _dbService.database;

      // Resetar status de sincronização para 'pending'
      await db.update(
        'inventory_batches',
        {'sync_status': 'pending'},
        where: 'sync_status != ?',
        whereArgs: ['synced'],
      );

      await db.update(
        'inventory_items',
        {'sync_status': 'pending'},
        where: 'sync_status != ?',
        whereArgs: ['synced'],
      );

      await db.update(
        'photos',
        {'sync_status': 'pending'},
        where: 'sync_status != ?',
        whereArgs: ['synced'],
      );
    } catch (e) {
      print('Erro ao resetar status de sincronização: $e');
    }
  }

  /// Forçar nova sincronização
  Future<SyncResult> forceSyncReset() async {
    try {
      await resetSyncStatus();
      return await performFullSync();
    } catch (e) {
      return SyncResult.error('Erro ao forçar sincronização: $e');
    }
  }

  /// Monitorar conectividade (Stream)
  Stream<ConnectivityInfo> monitorConnectivity() async* {
    await for (final result in _connectivity.onConnectivityChanged) {
      final hasInternet = await _syncService.hasInternetConnection();

      yield ConnectivityInfo(
        connectivityResult: result,
        hasInternetAccess: hasInternet,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Configurações de sincronização
  Future<SyncConfiguration> getSyncConfiguration() async {
    return SyncConfiguration(
      autoSyncEnabled: await PreferencesHelper.isAutoSyncEnabled(),
      syncIntervalMinutes: await PreferencesHelper.getSyncInterval(),
      lastSyncAt: await PreferencesHelper.getLastSyncAt(),
      offlineModeEnabled: await PreferencesHelper.isOfflineModeEnabled(),
    );
  }

  /// Atualizar configurações de sincronização
  Future<void> updateSyncConfiguration(SyncConfiguration config) async {
    await PreferencesHelper.setAutoSync(config.autoSyncEnabled);
    await PreferencesHelper.setSyncInterval(config.syncIntervalMinutes);
    await PreferencesHelper.setOfflineMode(config.offlineModeEnabled);
  }
}

/// Informações de conectividade
class ConnectivityInfo {
  final ConnectivityResult connectivityResult;
  final bool hasInternetAccess;
  final DateTime timestamp;
  final String? error;

  const ConnectivityInfo({
    required this.connectivityResult,
    required this.hasInternetAccess,
    required this.timestamp,
    this.error,
  });

  bool get isConnected => hasInternetAccess;

  String get connectionType {
    switch (connectivityResult) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Dados Móveis';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.none:
        return 'Sem Conexão';
      default:
        return 'Desconhecido';
    }
  }

  @override
  String toString() {
    return 'ConnectivityInfo(type: $connectionType, hasInternet: $hasInternetAccess)';
  }
}

/// Status detalhado de sincronização
class SyncStatusInfo {
  final bool isUpToDate;
  final int pendingBatches;
  final int pendingItems;
  final int pendingPhotos;
  final int totalPending;
  final DateTime? lastSyncAt;
  final bool hasConnectivity;
  final bool isSyncing;
  final String? error;

  const SyncStatusInfo({
    required this.isUpToDate,
    required this.pendingBatches,
    required this.pendingItems,
    required this.pendingPhotos,
    required this.totalPending,
    this.lastSyncAt,
    required this.hasConnectivity,
    required this.isSyncing,
    this.error,
  });

  String get statusMessage {
    if (error != null) return 'Erro: $error';
    if (isSyncing) return 'Sincronizando...';
    if (!hasConnectivity) return 'Sem conexão';
    if (isUpToDate) return 'Todos os dados sincronizados';
    return '$totalPending itens pendentes';
  }

  String get lastSyncMessage {
    if (lastSyncAt == null) return 'Nunca sincronizado';

    final now = DateTime.now();
    final difference = now.difference(lastSyncAt!);

    if (difference.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else {
      return '${difference.inDays} dias atrás';
    }
  }

  @override
  String toString() {
    return 'SyncStatusInfo(upToDate: $isUpToDate, pending: $totalPending, syncing: $isSyncing)';
  }
}

/// Entrada do log de sincronização
class SyncLogEntry {
  final int id;
  final String entityType;
  final String entityId;
  final String operation;
  final String status;
  final String? errorMessage;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final DateTime createdAt;

  const SyncLogEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.status,
    this.errorMessage,
    required this.startedAt,
    this.finishedAt,
    required this.createdAt,
  });

  factory SyncLogEntry.fromMap(Map<String, dynamic> map) {
    return SyncLogEntry(
      id: map['id'] as int,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      operation: map['operation'] as String,
      status: map['status'] as String,
      errorMessage: map['error_message'] as String?,
      startedAt: DateTime.parse(map['started_at'] as String),
      finishedAt: map['finished_at'] != null
          ? DateTime.parse(map['finished_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Duration? get duration {
    if (finishedAt == null) return null;
    return finishedAt!.difference(startedAt);
  }

  bool get isSuccess => status == 'success';
  bool get isError => status == 'error';
  bool get isInProgress => finishedAt == null;

  @override
  String toString() {
    return 'SyncLogEntry(entity: $entityType, operation: $operation, status: $status)';
  }
}

/// Configuração de sincronização
class SyncConfiguration {
  final bool autoSyncEnabled;
  final int syncIntervalMinutes;
  final DateTime? lastSyncAt;
  final bool offlineModeEnabled;

  const SyncConfiguration({
    required this.autoSyncEnabled,
    required this.syncIntervalMinutes,
    this.lastSyncAt,
    required this.offlineModeEnabled,
  });

  SyncConfiguration copyWith({
    bool? autoSyncEnabled,
    int? syncIntervalMinutes,
    DateTime? lastSyncAt,
    bool? offlineModeEnabled,
  }) {
    return SyncConfiguration(
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      offlineModeEnabled: offlineModeEnabled ?? this.offlineModeEnabled,
    );
  }

  @override
  String toString() {
    return 'SyncConfiguration(autoSync: $autoSyncEnabled, interval: ${syncIntervalMinutes}min, offline: $offlineModeEnabled)';
  }
}
