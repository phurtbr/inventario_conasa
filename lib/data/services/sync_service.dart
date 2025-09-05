import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/constants/app_strings.dart';
import '../models/inventory_batch.dart';
import '../models/inventory_item.dart';
import '../models/photo.dart';
import '../models/product.dart';
import 'api_service.dart';
import 'database_service.dart';

/// Serviço de sincronização entre dados locais e servidor Protheus
/// Gerencia upload/download de dados e trabalho offline
class SyncService {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();

  SyncService._();

  final ApiService _apiService = ApiService.instance;
  final DatabaseService _dbService = DatabaseService.instance;
  final Connectivity _connectivity = Connectivity();

  bool _isSyncing = false;

  /// Verificar se está sincronizando
  bool get isSyncing => _isSyncing;

  /// Verificar conectividade
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Teste de conectividade real com o servidor
      final result = await _apiService.testConnection();
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }

  /// Sincronização completa
  Future<SyncResult> fullSync() async {
    if (_isSyncing) {
      return SyncResult.error('Sincronização já em andamento');
    }

    if (!await hasInternetConnection()) {
      return SyncResult.error('Sem conexão com a internet');
    }

    _isSyncing = true;

    try {
      final startTime = DateTime.now();
      final results = <String>[];
      int totalOperations = 0;
      int successfulOperations = 0;

      // 1. Sincronizar dados básicos (produtos, centro de custo, etc.)
      final basicDataResult = await syncBasicData();
      results.add('Dados básicos: ${basicDataResult.message}');
      totalOperations++;
      if (basicDataResult.isSuccess) successfulOperations++;

      // 2. Sincronizar lotes de inventário do servidor
      final batchesResult = await downloadInventoryBatches();
      results.add('Lotes de inventário: ${batchesResult.message}');
      totalOperations++;
      if (batchesResult.isSuccess) successfulOperations++;

      // 3. Enviar dados locais pendentes
      final uploadResult = await uploadPendingData();
      results.add('Upload de dados: ${uploadResult.message}');
      totalOperations++;
      if (uploadResult.isSuccess) successfulOperations++;

      // 4. Enviar fotos pendentes
      final photosResult = await uploadPendingPhotos();
      results.add('Upload de fotos: ${photosResult.message}');
      totalOperations++;
      if (photosResult.isSuccess) successfulOperations++;

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      final isFullSuccess = successfulOperations == totalOperations;
      final message = isFullSuccess
          ? 'Sincronização concluída com sucesso em ${duration.inSeconds}s'
          : 'Sincronização parcial: $successfulOperations/$totalOperations operações bem-sucedidas';

      return SyncResult(
        isSuccess: isFullSuccess,
        message: message,
        details: results,
        duration: duration,
        operationsTotal: totalOperations,
        operationsSuccess: successfulOperations,
      );
    } catch (e) {
      return SyncResult.error('Erro na sincronização: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sincronizar dados básicos (produtos, centros de custo, etc.)
  Future<SyncResult> syncBasicData() async {
    try {
      final results = <String>[];

      // Sincronizar produtos
      final productsResult = await _syncProducts();
      results.add('Produtos: ${productsResult.message}');

      // Sincronizar centros de custo (se necessário)
      // final centersResult = await _syncCostCenters();
      // results.add('Centros de custo: ${centersResult.message}');

      return SyncResult.success(
        'Dados básicos sincronizados',
        details: results,
      );
    } catch (e) {
      return SyncResult.error('Erro ao sincronizar dados básicos: $e');
    }
  }

  /// Sincronizar produtos do servidor
  Future<SyncResult> _syncProducts() async {
    try {
      // Buscar produtos da API cstProduto
      final response = await _apiService.get<Map<String, dynamic>>(
        AppStrings.productsEndpoint,
        queryParams: {
          'Empresa': '01', // Pegar da configuração do usuário
          'Filial': '01',
        },
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final productsData = data['produtos'] as List?;

        if (productsData != null) {
          final products = productsData
              .map((item) => Product.fromJson(item))
              .toList();

          // Salvar produtos no banco local
          await _dbService.saveProducts(products);

          return SyncResult.success(
            '${products.length} produtos sincronizados',
          );
        }
      }

      return SyncResult.error('Falha ao obter produtos do servidor');
    } catch (e) {
      return SyncResult.error('Erro ao sincronizar produtos: $e');
    }
  }

  /// Baixar lotes de inventário do servidor
  Future<SyncResult> downloadInventoryBatches() async {
    try {
      // Buscar lotes da API Z75
      final response = await _apiService.get<Map<String, dynamic>>(
        AppStrings.inventoryHeaderEndpoint,
        queryParams: {
          'empresa': '01',
          'filial': '01',
          'status': 'aberto,contagem', // Apenas lotes ativos
        },
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final batchesData = data['lotes'] as List?;

        if (batchesData != null) {
          final batches = batchesData
              .map((item) => InventoryBatch.fromJson(item))
              .toList();

          // Salvar lotes no banco local
          for (final batch in batches) {
            await _dbService.saveInventoryBatch(batch);
          }

          return SyncResult.success(
            '${batches.length} lotes de inventário baixados',
          );
        }
      }

      return SyncResult.error('Falha ao obter lotes do servidor');
    } catch (e) {
      return SyncResult.error('Erro ao baixar lotes: $e');
    }
  }

  /// Enviar dados locais pendentes
  Future<SyncResult> uploadPendingData() async {
    try {
      final pendingData = await _dbService.getPendingSyncData();
      final results = <String>[];

      // Enviar lotes de inventário
      final batches = pendingData['inventory_batches'] ?? [];
      if (batches.isNotEmpty) {
        final batchResult = await _uploadInventoryBatches(batches);
        results.add('Lotes: ${batchResult.message}');
      }

      // Enviar itens inventariados
      final items = pendingData['inventory_items'] ?? [];
      if (items.isNotEmpty) {
        final itemsResult = await _uploadInventoryItems(items);
        results.add('Itens: ${itemsResult.message}');
      }

      if (results.isEmpty) {
        return SyncResult.success('Nenhum dado pendente para enviar');
      }

      return SyncResult.success('Dados enviados com sucesso', details: results);
    } catch (e) {
      return SyncResult.error('Erro ao enviar dados: $e');
    }
  }

  /// Enviar lotes de inventário
  Future<SyncResult> _uploadInventoryBatches(
    List<Map<String, dynamic>> batches,
  ) async {
    int successCount = 0;

    for (final batchData in batches) {
      try {
        final batch = InventoryBatch.fromLocalJson(batchData);

        await _dbService.saveSyncLog(
          entityType: 'inventory_batch',
          entityId: batch.id,
          operation: 'upload',
          status: 'started',
          startedAt: DateTime.now(),
        );

        final response = await _apiService.post<Map<String, dynamic>>(
          AppStrings.inventoryHeaderEndpoint,
          body: batch.toJson(),
        );

        if (response.isSuccess) {
          await _dbService.markAsSynced('inventory_batches', batch.id);
          await _dbService.saveSyncLog(
            entityType: 'inventory_batch',
            entityId: batch.id,
            operation: 'upload',
            status: 'success',
            startedAt: DateTime.now(),
            finishedAt: DateTime.now(),
            responseData: jsonEncode(response.data),
          );
          successCount++;
        } else {
          await _dbService.saveSyncLog(
            entityType: 'inventory_batch',
            entityId: batch.id,
            operation: 'upload',
            status: 'error',
            errorMessage: response.error,
            startedAt: DateTime.now(),
            finishedAt: DateTime.now(),
          );
        }
      } catch (e) {
        await _dbService.saveSyncLog(
          entityType: 'inventory_batch',
          entityId: batchData['id'] ?? 'unknown',
          operation: 'upload',
          status: 'error',
          errorMessage: e.toString(),
          startedAt: DateTime.now(),
          finishedAt: DateTime.now(),
        );
      }
    }

    return SyncResult.success('$successCount/${batches.length} lotes enviados');
  }

  /// Enviar itens inventariados
  Future<SyncResult> _uploadInventoryItems(
    List<Map<String, dynamic>> items,
  ) async {
    int successCount = 0;

    for (final itemData in items) {
      try {
        final item = InventoryItem.fromLocalJson(itemData);

        await _dbService.saveSyncLog(
          entityType: 'inventory_item',
          entityId: item.id,
          operation: 'upload',
          status: 'started',
          startedAt: DateTime.now(),
        );

        final response = await _apiService.post<Map<String, dynamic>>(
          AppStrings.inventoryItemsEndpoint,
          body: item.toJson(),
        );

        if (response.isSuccess) {
          await _dbService.markAsSynced('inventory_items', item.id);
          await _dbService.saveSyncLog(
            entityType: 'inventory_item',
            entityId: item.id,
            operation: 'upload',
            status: 'success',
            startedAt: DateTime.now(),
            finishedAt: DateTime.now(),
            responseData: jsonEncode(response.data),
          );
          successCount++;
        } else {
          await _dbService.saveSyncLog(
            entityType: 'inventory_item',
            entityId: item.id,
            operation: 'upload',
            status: 'error',
            errorMessage: response.error,
            startedAt: DateTime.now(),
            finishedAt: DateTime.now(),
          );
        }
      } catch (e) {
        await _dbService.saveSyncLog(
          entityType: 'inventory_item',
          entityId: itemData['id'] ?? 'unknown',
          operation: 'upload',
          status: 'error',
          errorMessage: e.toString(),
          startedAt: DateTime.now(),
          finishedAt: DateTime.now(),
        );
      }
    }

    return SyncResult.success('$successCount/${items.length} itens enviados');
  }

  /// Enviar fotos pendentes
  Future<SyncResult> uploadPendingPhotos() async {
    try {
      final pendingData = await _dbService.getPendingSyncData();
      final photos = pendingData['photos'] ?? [];

      if (photos.isEmpty) {
        return SyncResult.success('Nenhuma foto pendente para enviar');
      }

      int successCount = 0;

      for (final photoData in photos) {
        final photo = Photo.fromLocalJson(photoData);

        if (photo.existsLocally) {
          final uploadResult = await _uploadSinglePhoto(photo);
          if (uploadResult.isSuccess) {
            successCount++;
          }
        }
      }

      return SyncResult.success(
        '$successCount/${photos.length} fotos enviadas',
      );
    } catch (e) {
      return SyncResult.error('Erro ao enviar fotos: $e');
    }
  }

  /// Enviar uma única foto
  Future<SyncResult> _uploadSinglePhoto(Photo photo) async {
    try {
      await _dbService.saveSyncLog(
        entityType: 'photo',
        entityId: photo.id,
        operation: 'upload',
        status: 'started',
        startedAt: DateTime.now(),
      );

      final file = File(photo.localPath);

      final response = await _apiService.uploadFile(
        '/upload/photo',
        file,
        fields: {
          'inventory_batch_id': photo.inventoryBatchId,
          'inventory_item_id': photo.inventoryItemId,
          'product_code': photo.productCode,
          'type': photo.type.value,
          'description': photo.description ?? '',
        },
        fieldName: 'photo',
      );

      if (response.isSuccess) {
        // Atualizar foto com informações do servidor
        final serverData = response.data!;
        final updatedPhoto = photo.copyWith(
          serverPath: serverData['server_path'],
          url: serverData['url'],
          syncStatus: SyncStatus.synced,
          lastSyncAt: DateTime.now(),
        );

        await _dbService.savePhoto(updatedPhoto);

        await _dbService.saveSyncLog(
          entityType: 'photo',
          entityId: photo.id,
          operation: 'upload',
          status: 'success',
          startedAt: DateTime.now(),
          finishedAt: DateTime.now(),
          responseData: jsonEncode(response.data),
        );

        return SyncResult.success('Foto enviada');
      } else {
        await _dbService.saveSyncLog(
          entityType: 'photo',
          entityId: photo.id,
          operation: 'upload',
          status: 'error',
          errorMessage: response.error,
          startedAt: DateTime.now(),
          finishedAt: DateTime.now(),
        );

        return SyncResult.error(response.error ?? 'Erro no upload');
      }
    } catch (e) {
      await _dbService.saveSyncLog(
        entityType: 'photo',
        entityId: photo.id,
        operation: 'upload',
        status: 'error',
        errorMessage: e.toString(),
        startedAt: DateTime.now(),
        finishedAt: DateTime.now(),
      );

      return SyncResult.error('Erro ao enviar foto: $e');
    }
  }

  /// Sincronização automática em background
  Future<void> autoSync() async {
    if (_isSyncing || !await hasInternetConnection()) {
      return;
    }

    try {
      // Sincronização leve - apenas dados críticos
      await uploadPendingData();
      await uploadPendingPhotos();
    } catch (e) {
      // Log silencioso do erro
      print('Erro na sincronização automática: $e');
    }
  }

  /// Limpar dados de sincronização antigos
  Future<void> cleanupOldSyncData() async {
    await _dbService.clearOldData();
  }

  /// Verificar status de sincronização
  Future<SyncStatus> getSyncStatus() async {
    final pendingData = await _dbService.getPendingSyncData();

    final totalPending = pendingData.values
        .map((list) => list.length)
        .fold(0, (a, b) => a + b);

    if (totalPending == 0) {
      return SyncStatus(
        isUpToDate: true,
        pendingItems: 0,
        lastSyncAt: DateTime.now(),
        message: 'Todos os dados estão sincronizados',
      );
    } else {
      return SyncStatus(
        isUpToDate: false,
        pendingItems: totalPending,
        lastSyncAt: null,
        message: '$totalPending itens pendentes de sincronização',
      );
    }
  }
}

/// Resultado de operação de sincronização
class SyncResult {
  final bool isSuccess;
  final String message;
  final List<String> details;
  final Duration? duration;
  final int? operationsTotal;
  final int? operationsSuccess;

  const SyncResult({
    required this.isSuccess,
    required this.message,
    this.details = const [],
    this.duration,
    this.operationsTotal,
    this.operationsSuccess,
  });

  factory SyncResult.success(
    String message, {
    List<String> details = const [],
    Duration? duration,
  }) {
    return SyncResult(
      isSuccess: true,
      message: message,
      details: details,
      duration: duration,
    );
  }

  factory SyncResult.error(String message) {
    return SyncResult(isSuccess: false, message: message);
  }

  bool get isError => !isSuccess;

  @override
  String toString() {
    return isSuccess
        ? 'SyncResult.success($message)'
        : 'SyncResult.error($message)';
  }
}

/// Status de sincronização
class SyncStatus {
  final bool isUpToDate;
  final int pendingItems;
  final DateTime? lastSyncAt;
  final String message;

  const SyncStatus({
    required this.isUpToDate,
    required this.pendingItems,
    this.lastSyncAt,
    required this.message,
  });

  @override
  String toString() {
    return 'SyncStatus(upToDate: $isUpToDate, pending: $pendingItems)';
  }
}
