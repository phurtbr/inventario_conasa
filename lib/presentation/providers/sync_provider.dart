import 'package:flutter/material.dart';
import '../../data/repositories/sync_repository.dart';
import '../../data/models/inventory_batch.dart';
import '../../data/models/inventory_item.dart';
import '../../data/models/photo.dart';
import '../../core/constants/app_strings.dart';

enum SyncStatus { idle, syncing, paused, completed, error }

enum SyncDirection { upload, download, bidirectional }

enum SyncPriority { low, normal, high, critical }

enum SyncType { full, incremental, photos, masterData }

class SyncOperation {
  final String id;
  final SyncType type;
  final SyncDirection direction;
  final SyncPriority priority;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final SyncStatus status;
  final String? error;
  final int totalItems;
  final int processedItems;
  final Map<String, dynamic> metadata;

  SyncOperation({
    required this.id,
    required this.type,
    required this.direction,
    required this.priority,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.status = SyncStatus.idle,
    this.error,
    this.totalItems = 0,
    this.processedItems = 0,
    this.metadata = const {},
  });

  SyncOperation copyWith({
    String? id,
    SyncType? type,
    SyncDirection? direction,
    SyncPriority? priority,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    SyncStatus? status,
    String? error,
    int? totalItems,
    int? processedItems,
    Map<String, dynamic>? metadata,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      direction: direction ?? this.direction,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      error: error ?? this.error,
      totalItems: totalItems ?? this.totalItems,
      processedItems: processedItems ?? this.processedItems,
      metadata: metadata ?? this.metadata,
    );
  }

  double get progress => totalItems > 0 ? processedItems / totalItems : 0.0;
  Duration? get duration => startedAt != null && completedAt != null
      ? completedAt!.difference(startedAt!)
      : null;
  bool get isActive => status == SyncStatus.syncing;
  bool get isCompleted => status == SyncStatus.completed;
  bool get hasError => status == SyncStatus.error;
}

class SyncStatistics {
  final DateTime lastFullSync;
  final DateTime lastIncrementalSync;
  final int totalSyncsToday;
  final int successfulSyncs;
  final int failedSyncs;
  final int totalItemsSynced;
  final int totalPhotosSynced;
  final double avgSyncDuration;
  final int pendingUploads;
  final int pendingDownloads;

  SyncStatistics({
    required this.lastFullSync,
    required this.lastIncrementalSync,
    this.totalSyncsToday = 0,
    this.successfulSyncs = 0,
    this.failedSyncs = 0,
    this.totalItemsSynced = 0,
    this.totalPhotosSynced = 0,
    this.avgSyncDuration = 0.0,
    this.pendingUploads = 0,
    this.pendingDownloads = 0,
  });
}

class SyncProvider with ChangeNotifier {
  final SyncRepository _syncRepository;

  SyncProvider(this._syncRepository) {
    _initializeSync();
  }

  // Estados principais
  SyncStatus _status = SyncStatus.idle;
  SyncOperation? _currentOperation;
  List<SyncOperation> _operationQueue = [];
  List<SyncOperation> _operationHistory = [];
  String? _error;
  SyncStatistics? _statistics;

  // Configurações de sincronização
  bool _autoSyncEnabled = true;
  bool _wifiOnlySync = true;
  bool _syncPhotos = true;
  bool _syncMasterData = true;
  int _syncIntervalMinutes = 30;
  int _maxRetryAttempts = 3;
  bool _pauseOnBatteryLow = true;

  // Estados de conectividade e recursos
  bool _isConnected = false;
  bool _isWifiConnected = false;
  bool _isBatteryLow = false;
  bool _isCharging = false;

  // Controle de progresso
  double _overallProgress = 0.0;
  String _currentOperationDescription = '';

  // Getters
  SyncStatus get status => _status;
  SyncOperation? get currentOperation => _currentOperation;
  List<SyncOperation> get operationQueue => List.unmodifiable(_operationQueue);
  List<SyncOperation> get operationHistory =>
      List.unmodifiable(_operationHistory);
  String? get error => _error;
  SyncStatistics? get statistics => _statistics;

  bool get autoSyncEnabled => _autoSyncEnabled;
  bool get wifiOnlySync => _wifiOnlySync;
  bool get syncPhotos => _syncPhotos;
  bool get syncMasterData => _syncMasterData;
  int get syncIntervalMinutes => _syncIntervalMinutes;
  int get maxRetryAttempts => _maxRetryAttempts;
  bool get pauseOnBatteryLow => _pauseOnBatteryLow;

  bool get isConnected => _isConnected;
  bool get isWifiConnected => _isWifiConnected;
  bool get isBatteryLow => _isBatteryLow;
  bool get isCharging => _isCharging;

  double get overallProgress => _overallProgress;
  String get currentOperationDescription => _currentOperationDescription;

  // Estados computados
  bool get isSyncing => _status == SyncStatus.syncing;
  bool get canSync =>
      _isConnected &&
      (!_wifiOnlySync || _isWifiConnected) &&
      (!_pauseOnBatteryLow || !_isBatteryLow || _isCharging);
  bool get hasPendingOperations => _operationQueue.isNotEmpty;
  int get pendingOperationsCount => _operationQueue.length;

  SyncOperation? get lastCompletedOperation => _operationHistory
      .where((op) => op.isCompleted)
      .fold<SyncOperation?>(
        null,
        (prev, current) =>
            prev == null || current.completedAt!.isAfter(prev.completedAt!)
            ? current
            : prev,
      );

  // Inicialização
  Future<void> _initializeSync() async {
    try {
      await _loadSyncHistory();
      await _loadSyncStatistics();
      _scheduleAutoSync();
    } catch (e) {
      debugPrint('Erro ao inicializar sincronização: $e');
    }
  }

  // Operações principais de sincronização
  Future<void> performFullSync() async {
    final operation = SyncOperation(
      id: 'full_sync_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncType.full,
      direction: SyncDirection.bidirectional,
      priority: SyncPriority.high,
      createdAt: DateTime.now(),
    );

    await _queueOperation(operation);
  }

  Future<void> performIncrementalSync() async {
    final operation = SyncOperation(
      id: 'incremental_sync_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncType.incremental,
      direction: SyncDirection.bidirectional,
      priority: SyncPriority.normal,
      createdAt: DateTime.now(),
    );

    await _queueOperation(operation);
  }

  Future<void> syncPhotos() async {
    if (!_syncPhotos) return;

    final operation = SyncOperation(
      id: 'photos_sync_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncType.photos,
      direction: SyncDirection.upload,
      priority: SyncPriority.low,
      createdAt: DateTime.now(),
    );

    await _queueOperation(operation);
  }

  Future<void> syncMasterData() async {
    if (!_syncMasterData) return;

    final operation = SyncOperation(
      id: 'master_data_sync_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncType.masterData,
      direction: SyncDirection.download,
      priority: SyncPriority.normal,
      createdAt: DateTime.now(),
    );

    await _queueOperation(operation);
  }

  Future<void> syncSpecificInventory(String inventoryId) async {
    final operation = SyncOperation(
      id: 'inventory_sync_${inventoryId}_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncType.incremental,
      direction: SyncDirection.upload,
      priority: SyncPriority.high,
      createdAt: DateTime.now(),
      metadata: {'inventoryId': inventoryId},
    );

    await _queueOperation(operation);
  }

  // Controle de operações
  Future<void> _queueOperation(SyncOperation operation) async {
    if (!canSync) {
      _error = _getConnectionErrorMessage();
      notifyListeners();
      return;
    }

    _operationQueue.add(operation);
    _operationQueue.sort(
      (a, b) => b.priority.index.compareTo(a.priority.index),
    );

    notifyListeners();

    if (_status == SyncStatus.idle) {
      await _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (_operationQueue.isEmpty || _status == SyncStatus.syncing) return;

    _status = SyncStatus.syncing;
    _error = null;
    notifyListeners();

    while (_operationQueue.isNotEmpty && canSync) {
      final operation = _operationQueue.removeAt(0);
      await _executeOperation(operation);
    }

    _status = SyncStatus.idle;
    _currentOperation = null;
    _overallProgress = 0.0;
    _currentOperationDescription = '';
    notifyListeners();
  }

  Future<void> _executeOperation(SyncOperation operation) async {
    _currentOperation = operation.copyWith(
      status: SyncStatus.syncing,
      startedAt: DateTime.now(),
    );

    notifyListeners();

    try {
      switch (operation.type) {
        case SyncType.full:
          await _performFullSyncOperation(operation);
          break;
        case SyncType.incremental:
          await _performIncrementalSyncOperation(operation);
          break;
        case SyncType.photos:
          await _performPhotoSyncOperation(operation);
          break;
        case SyncType.masterData:
          await _performMasterDataSyncOperation(operation);
          break;
      }

      _currentOperation = _currentOperation!.copyWith(
        status: SyncStatus.completed,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      _currentOperation = _currentOperation!.copyWith(
        status: SyncStatus.error,
        error: e.toString(),
        completedAt: DateTime.now(),
      );

      _error = e.toString();
      debugPrint('Erro na operação de sincronização: $e');
    }

    _operationHistory.add(_currentOperation!);
    await _updateSyncStatistics();
    notifyListeners();
  }

  Future<void> _performFullSyncOperation(SyncOperation operation) async {
    _currentOperationDescription = AppStrings.syncingFullData;

    // Upload de dados locais
    if (operation.direction == SyncDirection.upload ||
        operation.direction == SyncDirection.bidirectional) {
      await _uploadInventories(operation);
      await _uploadInventoryItems(operation);
      if (_syncPhotos) {
        await _uploadPhotos(operation);
      }
    }

    // Download de dados do servidor
    if (operation.direction == SyncDirection.download ||
        operation.direction == SyncDirection.bidirectional) {
      await _downloadMasterData(operation);
      await _downloadInventories(operation);
    }
  }

  Future<void> _performIncrementalSyncOperation(SyncOperation operation) async {
    _currentOperationDescription = AppStrings.syncingIncrementalData;

    final lastSync = _statistics?.lastIncrementalSync ?? DateTime(2020);

    if (operation.metadata.containsKey('inventoryId')) {
      // Sincronização de inventário específico
      await _syncSpecificInventoryData(
        operation.metadata['inventoryId'],
        operation,
      );
    } else {
      // Sincronização incremental geral
      await _syncModifiedData(lastSync, operation);
    }
  }

  Future<void> _performPhotoSyncOperation(SyncOperation operation) async {
    _currentOperationDescription = AppStrings.syncingPhotos;
    await _uploadPhotos(operation);
  }

  Future<void> _performMasterDataSyncOperation(SyncOperation operation) async {
    _currentOperationDescription = AppStrings.syncingMasterData;
    await _downloadMasterData(operation);
  }

  // Implementações específicas de sincronização
  Future<void> _uploadInventories(SyncOperation operation) async {
    final inventories = await _syncRepository.getPendingInventories();
    operation = operation.copyWith(totalItems: inventories.length);

    for (int i = 0; i < inventories.length; i++) {
      await _syncRepository.uploadInventory(inventories[i]);
      operation = operation.copyWith(processedItems: i + 1);
      _overallProgress = operation.progress * 0.3; // 30% do progresso total
      notifyListeners();
    }
  }

  Future<void> _uploadInventoryItems(SyncOperation operation) async {
    final items = await _syncRepository.getPendingInventoryItems();
    final currentProcessed = operation.processedItems;
    operation = operation.copyWith(
      totalItems: operation.totalItems + items.length,
    );

    for (int i = 0; i < items.length; i++) {
      await _syncRepository.uploadInventoryItem(items[i]);
      operation = operation.copyWith(processedItems: currentProcessed + i + 1);
      _overallProgress = operation.progress * 0.5 + 0.3; // 50% + 30% anterior
      notifyListeners();
    }
  }

  Future<void> _uploadPhotos(SyncOperation operation) async {
    final photos = await _syncRepository.getPendingPhotos();
    final currentProcessed = operation.processedItems;
    operation = operation.copyWith(
      totalItems: operation.totalItems + photos.length,
    );

    for (int i = 0; i < photos.length; i++) {
      await _syncRepository.uploadPhoto(photos[i]);
      operation = operation.copyWith(processedItems: currentProcessed + i + 1);
      _overallProgress = operation.progress * 0.2 + 0.8; // 20% + 80% anterior
      notifyListeners();
    }
  }

  Future<void> _downloadMasterData(SyncOperation operation) async {
    // Download de produtos, localizações, centros de custo, etc.
    await _syncRepository.downloadProducts();
    await _syncRepository.downloadLocations();
    await _syncRepository.downloadCostCenters();

    _overallProgress = 1.0;
    notifyListeners();
  }

  Future<void> _downloadInventories(SyncOperation operation) async {
    final serverInventories = await _syncRepository.downloadInventories();
    operation = operation.copyWith(totalItems: serverInventories.length);

    for (int i = 0; i < serverInventories.length; i++) {
      await _syncRepository.saveInventoryFromServer(serverInventories[i]);
      operation = operation.copyWith(processedItems: i + 1);
      _overallProgress = operation.progress;
      notifyListeners();
    }
  }

  Future<void> _syncSpecificInventoryData(
    String inventoryId,
    SyncOperation operation,
  ) async {
    await _syncRepository.syncInventoryById(inventoryId);
    _overallProgress = 1.0;
    notifyListeners();
  }

  Future<void> _syncModifiedData(
    DateTime lastSync,
    SyncOperation operation,
  ) async {
    await _syncRepository.syncModifiedDataSince(lastSync);
    _overallProgress = 1.0;
    notifyListeners();
  }

  // Controle manual
  Future<void> pauseSync() async {
    if (_status == SyncStatus.syncing) {
      _status = SyncStatus.paused;
      notifyListeners();
    }
  }

  Future<void> resumeSync() async {
    if (_status == SyncStatus.paused) {
      _status = SyncStatus.syncing;
      await _processQueue();
    }
  }

  Future<void> cancelCurrentOperation() async {
    if (_currentOperation != null) {
      _currentOperation = _currentOperation!.copyWith(
        status: SyncStatus.error,
        error: 'Cancelado pelo usuário',
        completedAt: DateTime.now(),
      );

      _operationHistory.add(_currentOperation!);
      _currentOperation = null;
      _status = SyncStatus.idle;
      _overallProgress = 0.0;
      _currentOperationDescription = '';

      notifyListeners();
    }
  }

  void clearQueue() {
    _operationQueue.clear();
    notifyListeners();
  }

  // Configurações
  void setAutoSyncEnabled(bool enabled) {
    _autoSyncEnabled = enabled;
    if (enabled) {
      _scheduleAutoSync();
    }
    notifyListeners();
  }

  void setWifiOnlySync(bool wifiOnly) {
    _wifiOnlySync = wifiOnly;
    notifyListeners();
  }

  void setSyncPhotos(bool sync) {
    _syncPhotos = sync;
    notifyListeners();
  }

  void setSyncMasterData(bool sync) {
    _syncMasterData = sync;
    notifyListeners();
  }

  void setSyncInterval(int minutes) {
    _syncIntervalMinutes = minutes;
    _scheduleAutoSync();
    notifyListeners();
  }

  void setMaxRetryAttempts(int attempts) {
    _maxRetryAttempts = attempts;
    notifyListeners();
  }

  void setPauseOnBatteryLow(bool pause) {
    _pauseOnBatteryLow = pause;
    notifyListeners();
  }

  // Estados de conectividade
  void updateConnectivityStatus(bool isConnected, bool isWifi) {
    _isConnected = isConnected;
    _isWifiConnected = isWifi;
    notifyListeners();

    if (_autoSyncEnabled && canSync && _operationQueue.isNotEmpty) {
      _processQueue();
    }
  }

  void updateBatteryStatus(bool isBatteryLow, bool isCharging) {
    _isBatteryLow = isBatteryLow;
    _isCharging = isCharging;
    notifyListeners();

    if (_pauseOnBatteryLow &&
        isBatteryLow &&
        !isCharging &&
        _status == SyncStatus.syncing) {
      pauseSync();
    }
  }

  // Utilitários
  String _getConnectionErrorMessage() {
    if (!_isConnected) {
      return AppStrings.noInternetConnection;
    } else if (_wifiOnlySync && !_isWifiConnected) {
      return AppStrings.wifiOnlyModeEnabled;
    } else if (_pauseOnBatteryLow && _isBatteryLow && !_isCharging) {
      return AppStrings.batteryLowSyncPaused;
    }
    return AppStrings.cannotSyncRightNow;
  }

  void _scheduleAutoSync() {
    // Aqui seria implementado o agendamento automático
    // usando WorkManager ou similar
  }

  Future<void> _loadSyncHistory() async {
    try {
      _operationHistory = await _syncRepository.getSyncHistory();
    } catch (e) {
      debugPrint('Erro ao carregar histórico de sincronização: $e');
    }
  }

  Future<void> _loadSyncStatistics() async {
    try {
      _statistics = await _syncRepository.getSyncStatistics();
    } catch (e) {
      debugPrint('Erro ao carregar estatísticas de sincronização: $e');
    }
  }

  Future<void> _updateSyncStatistics() async {
    try {
      await _syncRepository.updateSyncStatistics(_currentOperation!);
      _statistics = await _syncRepository.getSyncStatistics();
    } catch (e) {
      debugPrint('Erro ao atualizar estatísticas de sincronização: $e');
    }
  }

  // Limpeza
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearHistory() {
    _operationHistory.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
