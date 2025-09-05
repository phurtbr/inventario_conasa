import 'dart:io';
import '../../core/constants/app_strings.dart';
import '../models/inventory_batch.dart';
import '../models/inventory_item.dart';
import '../models/product.dart';
import '../models/photo.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/photo_service.dart';
import '../services/sync_service.dart';

/// Repository para gerenciamento de inventários
/// Coordena operações de inventário entre API e banco local
class InventoryRepository {
  static InventoryRepository? _instance;
  static InventoryRepository get instance =>
      _instance ??= InventoryRepository._();

  InventoryRepository._();

  final ApiService _apiService = ApiService.instance;
  final DatabaseService _dbService = DatabaseService.instance;
  final PhotoService _photoService = PhotoService.instance;
  final SyncService _syncService = SyncService.instance;

  /// Obter lotes de inventário
  Future<InventoryResult<List<InventoryBatch>>> getInventoryBatches({
    String? status,
    String? companyCode,
    String? branchCode,
    bool forceRefresh = false,
  }) async {
    try {
      // Se forçar refresh e tiver internet, sincronizar primeiro
      if (forceRefresh && await _syncService.hasInternetConnection()) {
        await _syncService.downloadInventoryBatches();
      }

      // Buscar do banco local
      final batches = await _dbService.getInventoryBatches(
        status: status,
        companyCode: companyCode,
        branchCode: branchCode,
      );

      return InventoryResult.success(batches);
    } catch (e) {
      return InventoryResult.error('Erro ao obter lotes: $e');
    }
  }

  /// Obter lote específico
  Future<InventoryResult<InventoryBatch>> getInventoryBatch(String id) async {
    try {
      final batch = await _dbService.getInventoryBatch(id);
      if (batch != null) {
        return InventoryResult.success(batch);
      } else {
        return InventoryResult.error('Lote não encontrado');
      }
    } catch (e) {
      return InventoryResult.error('Erro ao obter lote: $e');
    }
  }

  /// Iniciar contagem de um lote
  Future<InventoryResult<InventoryBatch>> startCounting(String batchId) async {
    try {
      final batch = await _dbService.getInventoryBatch(batchId);
      if (batch == null) {
        return InventoryResult.error('Lote não encontrado');
      }

      if (!batch.canStart) {
        return InventoryResult.error(
          'Lote não pode ser iniciado (status: ${batch.status.label})',
        );
      }

      final updatedBatch = batch.copyWith(
        status: InventoryStatus.counting,
        startedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      await _dbService.saveInventoryBatch(updatedBatch);

      return InventoryResult.success(updatedBatch);
    } catch (e) {
      return InventoryResult.error('Erro ao iniciar contagem: $e');
    }
  }

  /// Finalizar contagem de um lote
  Future<InventoryResult<InventoryBatch>> finishCounting(String batchId) async {
    try {
      final batch = await _dbService.getInventoryBatch(batchId);
      if (batch == null) {
        return InventoryResult.error('Lote não encontrado');
      }

      if (!batch.canFinish) {
        return InventoryResult.error('Lote não pode ser finalizado');
      }

      final updatedBatch = batch.copyWith(
        status: InventoryStatus.closed,
        finishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      await _dbService.saveInventoryBatch(updatedBatch);

      return InventoryResult.success(updatedBatch);
    } catch (e) {
      return InventoryResult.error('Erro ao finalizar contagem: $e');
    }
  }

  /// Buscar produtos
  Future<InventoryResult<List<Product>>> searchProducts({
    required String searchTerm,
    String? companyCode,
    String? branchCode,
    int? limit,
  }) async {
    try {
      final products = await _dbService.searchProducts(
        searchTerm: searchTerm,
        companyCode: companyCode,
        branchCode: branchCode,
        limit: limit ?? 50,
      );

      return InventoryResult.success(products);
    } catch (e) {
      return InventoryResult.error('Erro ao buscar produtos: $e');
    }
  }

  /// Obter produto por código
  Future<InventoryResult<Product>> getProduct(
    String code,
    String companyCode,
    String branchCode,
  ) async {
    try {
      final product = await _dbService.getProduct(
        code,
        companyCode,
        branchCode,
      );
      if (product != null) {
        return InventoryResult.success(product);
      } else {
        return InventoryResult.error('Produto não encontrado');
      }
    } catch (e) {
      return InventoryResult.error('Erro ao obter produto: $e');
    }
  }

  /// Adicionar item ao inventário
  Future<InventoryResult<InventoryItem>> addInventoryItem({
    required String inventoryBatchId,
    required String productCode,
    required double quantity,
    required String location,
    String? subLocation,
    String? tagCode,
    bool tagRequired = false,
    bool tagDamaged = false,
    String? notes,
    required String countedBy,
    String? companyCode,
    String? branchCode,
  }) async {
    try {
      // Verificar se o lote existe e está em contagem
      final batch = await _dbService.getInventoryBatch(inventoryBatchId);
      if (batch == null) {
        return InventoryResult.error('Lote de inventário não encontrado');
      }

      if (!batch.isInProgress) {
        return InventoryResult.error('Lote não está em contagem');
      }

      // Verificar se o produto existe
      final product = await _dbService.getProduct(
        productCode,
        companyCode ?? batch.companyCode,
        branchCode ?? batch.branchCode,
      );

      if (product == null) {
        return InventoryResult.error('Produto não encontrado');
      }

      // Validar TAG se obrigatória
      if (tagRequired && !tagDamaged && (tagCode == null || tagCode.isEmpty)) {
        return InventoryResult.error('TAG é obrigatória para este produto');
      }

      // Gerar próximo número de sequência
      final existingItems = await _dbService.getInventoryItems(
        inventoryBatchId,
      );
      final nextSequence = existingItems.length + 1;

      // Criar item
      final item = InventoryItem(
        id: _generateItemId(),
        inventoryBatchId: inventoryBatchId,
        productCode: productCode,
        productDescription: product.description,
        unitOfMeasure: product.unitOfMeasure,
        location: location,
        subLocation: subLocation,
        quantity: quantity,
        systemQuantity: product.currentStock,
        tagCode: tagCode,
        tagRequired: tagRequired,
        tagDamaged: tagDamaged,
        countedBy: countedBy,
        countedAt: DateTime.now(),
        notes: notes,
        status: InventoryItemStatus.counted,
        sequence: nextSequence,
        companyCode: companyCode ?? batch.companyCode,
        branchCode: branchCode ?? batch.branchCode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Salvar no banco
      await _dbService.saveInventoryItem(item);

      return InventoryResult.success(item);
    } catch (e) {
      return InventoryResult.error('Erro ao adicionar item: $e');
    }
  }

  /// Obter itens de um lote
  Future<InventoryResult<List<InventoryItem>>> getInventoryItems(
    String batchId,
  ) async {
    try {
      final items = await _dbService.getInventoryItems(batchId);
      return InventoryResult.success(items);
    } catch (e) {
      return InventoryResult.error('Erro ao obter itens: $e');
    }
  }

  /// Obter item específico
  Future<InventoryResult<InventoryItem>> getInventoryItem(String itemId) async {
    try {
      final item = await _dbService.getInventoryItem(itemId);
      if (item != null) {
        return InventoryResult.success(item);
      } else {
        return InventoryResult.error('Item não encontrado');
      }
    } catch (e) {
      return InventoryResult.error('Erro ao obter item: $e');
    }
  }

  /// Editar item inventariado
  Future<InventoryResult<InventoryItem>> updateInventoryItem({
    required String itemId,
    double? quantity,
    String? location,
    String? subLocation,
    String? tagCode,
    bool? tagDamaged,
    String? notes,
  }) async {
    try {
      final item = await _dbService.getInventoryItem(itemId);
      if (item == null) {
        return InventoryResult.error('Item não encontrado');
      }

      if (!item.canBeEdited) {
        return InventoryResult.error('Item não pode ser editado');
      }

      final updatedItem = item.copyWith(
        quantity: quantity ?? item.quantity,
        location: location ?? item.location,
        subLocation: subLocation ?? item.subLocation,
        tagCode: tagCode ?? item.tagCode,
        tagDamaged: tagDamaged ?? item.tagDamaged,
        notes: notes ?? item.notes,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      await _dbService.saveInventoryItem(updatedItem);

      return InventoryResult.success(updatedItem);
    } catch (e) {
      return InventoryResult.error('Erro ao editar item: $e');
    }
  }

  /// Deletar item inventariado
  Future<InventoryResult<bool>> deleteInventoryItem(String itemId) async {
    try {
      final item = await _dbService.getInventoryItem(itemId);
      if (item == null) {
        return InventoryResult.error('Item não encontrado');
      }

      // Deletar fotos associadas
      final photos = await _photoService.getPhotosForItem(itemId);
      for (final photo in photos) {
        await _photoService.deletePhoto(photo.id);
      }

      // Deletar item
      await _dbService.deleteInventoryItem(itemId);

      return InventoryResult.success(true);
    } catch (e) {
      return InventoryResult.error('Erro ao deletar item: $e');
    }
  }

  /// Adicionar foto a um item
  Future<InventoryResult<Photo>> addPhotoToItem({
    required String itemId,
    required String userId,
    PhotoType type = PhotoType.product,
    String? description,
    double? latitude,
    double? longitude,
    File? imageFile,
    bool fromCamera = true,
  }) async {
    try {
      final item = await _dbService.getInventoryItem(itemId);
      if (item == null) {
        return InventoryResult.error('Item não encontrado');
      }

      Photo? photo;

      if (imageFile != null) {
        // Processar arquivo fornecido
        // TODO: Implementar processamento de arquivo específico
        return InventoryResult.error(
          'Processamento de arquivo específico não implementado',
        );
      } else if (fromCamera) {
        // Capturar da câmera
        photo = await _photoService.capturePhotoForItem(
          item,
          userId,
          type: type,
          description: description,
          latitude: latitude,
          longitude: longitude,
        );
      } else {
        // Selecionar da galeria
        photo = await _photoService.pickPhotoForItem(
          item,
          userId,
          type: type,
          description: description,
          latitude: latitude,
          longitude: longitude,
        );
      }

      if (photo != null) {
        return InventoryResult.success(photo);
      } else {
        return InventoryResult.error('Falha ao capturar/processar foto');
      }
    } catch (e) {
      return InventoryResult.error('Erro ao adicionar foto: $e');
    }
  }

  /// Obter fotos de um item
  Future<InventoryResult<List<Photo>>> getItemPhotos(String itemId) async {
    try {
      final photos = await _photoService.getPhotosForItem(itemId);
      return InventoryResult.success(photos);
    } catch (e) {
      return InventoryResult.error('Erro ao obter fotos: $e');
    }
  }

  /// Deletar foto
  Future<InventoryResult<bool>> deletePhoto(String photoId) async {
    try {
      final success = await _photoService.deletePhoto(photoId);
      if (success) {
        return InventoryResult.success(true);
      } else {
        return InventoryResult.error('Falha ao deletar foto');
      }
    } catch (e) {
      return InventoryResult.error('Erro ao deletar foto: $e');
    }
  }

  /// Sincronizar dados
  Future<InventoryResult<bool>> syncData() async {
    try {
      if (!await _syncService.hasInternetConnection()) {
        return InventoryResult.error('Sem conexão com a internet');
      }

      final result = await _syncService.fullSync();
      if (result.isSuccess) {
        return InventoryResult.success(true);
      } else {
        return InventoryResult.error(result.message);
      }
    } catch (e) {
      return InventoryResult.error('Erro na sincronização: $e');
    }
  }

  /// Obter estatísticas do inventário
  Future<InventoryResult<InventoryStatistics>> getInventoryStatistics(
    String batchId,
  ) async {
    try {
      final batch = await _dbService.getInventoryBatch(batchId);
      if (batch == null) {
        return InventoryResult.error('Lote não encontrado');
      }

      final items = await _dbService.getInventoryItems(batchId);

      int itemsWithVariance = 0;
      int itemsWithPhotos = 0;
      int itemsWithTags = 0;
      double totalVariance = 0.0;

      for (final item in items) {
        if (item.hasVariance) {
          itemsWithVariance++;
          totalVariance += item.calculatedVariance.abs();
        }

        if (item.hasPhotos) {
          itemsWithPhotos++;
        }

        if (item.tagCode?.isNotEmpty == true) {
          itemsWithTags++;
        }
      }

      final statistics = InventoryStatistics(
        batchId: batchId,
        totalItems: items.length,
        itemsWithVariance: itemsWithVariance,
        itemsWithPhotos: itemsWithPhotos,
        itemsWithTags: itemsWithTags,
        totalVariance: totalVariance,
        averageVariance: itemsWithVariance > 0
            ? totalVariance / itemsWithVariance
            : 0.0,
        progressPercentage: batch.progressPercentage,
        startedAt: batch.startedAt,
        estimatedCompletion: _estimateCompletion(batch, items),
      );

      return InventoryResult.success(statistics);
    } catch (e) {
      return InventoryResult.error('Erro ao calcular estatísticas: $e');
    }
  }

  /// Estimar tempo de conclusão
  DateTime? _estimateCompletion(
    InventoryBatch batch,
    List<InventoryItem> items,
  ) {
    if (batch.startedAt == null || items.isEmpty) return null;

    final countingDuration = DateTime.now().difference(batch.startedAt!);
    final remainingItems = batch.totalItems - batch.countedItems;

    if (remainingItems <= 0 || batch.countedItems <= 0) return null;

    final averageTimePerItem =
        countingDuration.inMilliseconds / batch.countedItems;
    final estimatedRemainingTime = Duration(
      milliseconds: (remainingItems * averageTimePerItem).round(),
    );

    return DateTime.now().add(estimatedRemainingTime);
  }

  /// Gerar ID único para item
  String _generateItemId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'item_${timestamp}_${_generateRandomString(8)}';
  }

  /// Gerar string aleatória
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      length,
      (index) => chars[DateTime.now().millisecondsSinceEpoch % chars.length],
    ).join();
  }
}

/// Resultado de operações de inventário
class InventoryResult<T> {
  final bool isSuccess;
  final T? data;
  final String? error;

  const InventoryResult._({required this.isSuccess, this.data, this.error});

  factory InventoryResult.success(T data) {
    return InventoryResult._(isSuccess: true, data: data);
  }

  factory InventoryResult.error(String error) {
    return InventoryResult._(isSuccess: false, error: error);
  }

  bool get isError => !isSuccess;

  @override
  String toString() {
    return isSuccess
        ? 'InventoryResult.success($data)'
        : 'InventoryResult.error($error)';
  }
}

/// Estatísticas de inventário
class InventoryStatistics {
  final String batchId;
  final int totalItems;
  final int itemsWithVariance;
  final int itemsWithPhotos;
  final int itemsWithTags;
  final double totalVariance;
  final double averageVariance;
  final double progressPercentage;
  final DateTime? startedAt;
  final DateTime? estimatedCompletion;

  const InventoryStatistics({
    required this.batchId,
    required this.totalItems,
    required this.itemsWithVariance,
    required this.itemsWithPhotos,
    required this.itemsWithTags,
    required this.totalVariance,
    required this.averageVariance,
    required this.progressPercentage,
    this.startedAt,
    this.estimatedCompletion,
  });

  double get variancePercentage {
    return totalItems > 0 ? (itemsWithVariance / totalItems) * 100 : 0.0;
  }

  double get photosPercentage {
    return totalItems > 0 ? (itemsWithPhotos / totalItems) * 100 : 0.0;
  }

  double get tagsPercentage {
    return totalItems > 0 ? (itemsWithTags / totalItems) * 100 : 0.0;
  }
}
