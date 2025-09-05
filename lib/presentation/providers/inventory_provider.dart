import 'package:flutter/material.dart';
import '../../data/models/inventory_batch.dart';
import '../../data/models/inventory_item.dart';
import '../../data/models/product.dart';
import '../../data/repositories/inventory_repository.dart';

/// Provider para gerenciamento de estado de inventários
/// Controla lotes, itens e operações de contagem
class InventoryProvider with ChangeNotifier {
  static InventoryProvider? _instance;
  static InventoryProvider get instance => _instance ??= InventoryProvider._();

  InventoryProvider._();

  final InventoryRepository _inventoryRepository = InventoryRepository.instance;

  // Estado dos lotes
  List<InventoryBatch> _inventoryBatches = [];
  InventoryBatch? _currentBatch;
  bool _isLoadingBatches = false;
  String? _batchesError;

  // Estado dos itens
  List<InventoryItem> _currentItems = [];
  InventoryItem? _selectedItem;
  bool _isLoadingItems = false;
  String? _itemsError;

  // Estado de busca de produtos
  List<Product> _searchResults = [];
  Product? _selectedProduct;
  bool _isSearchingProducts = false;
  String? _searchError;
  String _lastSearchTerm = '';

  // Estado de operações
  bool _isStartingCounting = false;
  bool _isFinishingCounting = false;
  bool _isAddingItem = false;
  bool _isUpdatingItem = false;
  bool _isDeletingItem = false;
  String? _operationError;

  // Filtros e configurações
  String? _statusFilter;
  String _searchFilter = '';

  // Getters - Lotes
  List<InventoryBatch> get inventoryBatches => _inventoryBatches;
  InventoryBatch? get currentBatch => _currentBatch;
  bool get isLoadingBatches => _isLoadingBatches;
  String? get batchesError => _batchesError;
  bool get hasBatchesError => _batchesError != null;

  // Getters - Itens
  List<InventoryItem> get currentItems => _currentItems;
  InventoryItem? get selectedItem => _selectedItem;
  bool get isLoadingItems => _isLoadingItems;
  String? get itemsError => _itemsError;
  bool get hasItemsError => _itemsError != null;

  // Getters - Busca de produtos
  List<Product> get searchResults => _searchResults;
  Product? get selectedProduct => _selectedProduct;
  bool get isSearchingProducts => _isSearchingProducts;
  String? get searchError => _searchError;
  bool get hasSearchError => _searchError != null;
  String get lastSearchTerm => _lastSearchTerm;
  bool get hasSearchResults => _searchResults.isNotEmpty;

  // Getters - Operações
  bool get isStartingCounting => _isStartingCounting;
  bool get isFinishingCounting => _isFinishingCounting;
  bool get isAddingItem => _isAddingItem;
  bool get isUpdatingItem => _isUpdatingItem;
  bool get isDeletingItem => _isDeletingItem;
  String? get operationError => _operationError;
  bool get hasOperationError => _operationError != null;
  bool get isPerformingOperation =>
      _isStartingCounting ||
      _isFinishingCounting ||
      _isAddingItem ||
      _isUpdatingItem ||
      _isDeletingItem;

  // Getters - Filtros
  String? get statusFilter => _statusFilter;
  String get searchFilter => _searchFilter;
  bool get hasActiveFilters =>
      _statusFilter != null || _searchFilter.isNotEmpty;

  // Getters de conveniência
  bool get hasCurrentBatch => _currentBatch != null;
  bool get canStartCounting => _currentBatch?.canStart ?? false;
  bool get canFinishCounting => _currentBatch?.canFinish ?? false;
  bool get isCurrentBatchInProgress => _currentBatch?.isInProgress ?? false;
  int get currentItemsCount => _currentItems.length;
  double get currentProgress => _currentBatch?.progressPercentage ?? 0.0;

  /// Carregar lotes de inventário
  Future<void> loadInventoryBatches({
    String? status,
    String? companyCode,
    String? branchCode,
    bool forceRefresh = false,
  }) async {
    _isLoadingBatches = true;
    _batchesError = null;
    notifyListeners();

    try {
      final result = await _inventoryRepository.getInventoryBatches(
        status: status,
        companyCode: companyCode,
        branchCode: branchCode,
        forceRefresh: forceRefresh,
      );

      if (result.isSuccess && result.data != null) {
        _inventoryBatches = result.data!;
        _applyFilters();
      } else {
        _batchesError = result.error ?? 'Erro ao carregar lotes';
      }
    } catch (e) {
      _batchesError = 'Erro inesperado: $e';
    } finally {
      _isLoadingBatches = false;
      notifyListeners();
    }
  }

  /// Selecionar lote atual
  Future<void> selectBatch(String batchId) async {
    try {
      final result = await _inventoryRepository.getInventoryBatch(batchId);

      if (result.isSuccess && result.data != null) {
        _currentBatch = result.data!;
        await loadCurrentBatchItems();
        notifyListeners();
      } else {
        _batchesError = result.error ?? 'Erro ao selecionar lote';
        notifyListeners();
      }
    } catch (e) {
      _batchesError = 'Erro ao selecionar lote: $e';
      notifyListeners();
    }
  }

  /// Iniciar contagem de um lote
  Future<bool> startCounting(String batchId) async {
    _isStartingCounting = true;
    _operationError = null;
    notifyListeners();

    try {
      final result = await _inventoryRepository.startCounting(batchId);

      if (result.isSuccess && result.data != null) {
        _currentBatch = result.data!;
        // Atualizar também na lista
        final index = _inventoryBatches.indexWhere((b) => b.id == batchId);
        if (index >= 0) {
          _inventoryBatches[index] = result.data!;
        }
        notifyListeners();
        return true;
      } else {
        _operationError = result.error ?? 'Erro ao iniciar contagem';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _operationError = 'Erro ao iniciar contagem: $e';
      notifyListeners();
      return false;
    } finally {
      _isStartingCounting = false;
      notifyListeners();
    }
  }

  /// Finalizar contagem de um lote
  Future<bool> finishCounting(String batchId) async {
    _isFinishingCounting = true;
    _operationError = null;
    notifyListeners();

    try {
      final result = await _inventoryRepository.finishCounting(batchId);

      if (result.isSuccess && result.data != null) {
        _currentBatch = result.data!;
        // Atualizar também na lista
        final index = _inventoryBatches.indexWhere((b) => b.id == batchId);
        if (index >= 0) {
          _inventoryBatches[index] = result.data!;
        }
        notifyListeners();
        return true;
      } else {
        _operationError = result.error ?? 'Erro ao finalizar contagem';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _operationError = 'Erro ao finalizar contagem: $e';
      notifyListeners();
      return false;
    } finally {
      _isFinishingCounting = false;
      notifyListeners();
    }
  }

  /// Carregar itens do lote atual
  Future<void> loadCurrentBatchItems() async {
    if (_currentBatch == null) return;

    _isLoadingItems = true;
    _itemsError = null;
    notifyListeners();

    try {
      final result = await _inventoryRepository.getInventoryItems(
        _currentBatch!.id,
      );

      if (result.isSuccess && result.data != null) {
        _currentItems = result.data!;
      } else {
        _itemsError = result.error ?? 'Erro ao carregar itens';
      }
    } catch (e) {
      _itemsError = 'Erro ao carregar itens: $e';
    } finally {
      _isLoadingItems = false;
      notifyListeners();
    }
  }

  /// Buscar produtos
  Future<void> searchProducts(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      _searchResults = [];
      _lastSearchTerm = '';
      notifyListeners();
      return;
    }

    _isSearchingProducts = true;
    _searchError = null;
    _lastSearchTerm = searchTerm;
    notifyListeners();

    try {
      final result = await _inventoryRepository.searchProducts(
        searchTerm: searchTerm,
        limit: 20,
      );

      if (result.isSuccess && result.data != null) {
        _searchResults = result.data!;
      } else {
        _searchError = result.error ?? 'Erro na busca';
        _searchResults = [];
      }
    } catch (e) {
      _searchError = 'Erro na busca: $e';
      _searchResults = [];
    } finally {
      _isSearchingProducts = false;
      notifyListeners();
    }
  }

  /// Selecionar produto
  void selectProduct(Product product) {
    _selectedProduct = product;
    notifyListeners();
  }

  /// Limpar seleção de produto
  void clearProductSelection() {
    _selectedProduct = null;
    notifyListeners();
  }

  /// Adicionar item ao inventário
  Future<bool> addInventoryItem({
    required String productCode,
    required double quantity,
    required String location,
    String? subLocation,
    String? tagCode,
    bool tagRequired = false,
    bool tagDamaged = false,
    String? notes,
    required String countedBy,
  }) async {
    if (_currentBatch == null) {
      _operationError = 'Nenhum lote selecionado';
      notifyListeners();
      return false;
    }

    _isAddingItem = true;
    _operationError = null;
    notifyListeners();

    try {
      final result = await _inventoryRepository.addInventoryItem(
        inventoryBatchId: _currentBatch!.id,
        productCode: productCode,
        quantity: quantity,
        location: location,
        subLocation: subLocation,
        tagCode: tagCode,
        tagRequired: tagRequired,
        tagDamaged: tagDamaged,
        notes: notes,
        countedBy: countedBy,
      );

      if (result.isSuccess && result.data != null) {
        // Adicionar item à lista local
        _currentItems.add(result.data!);

        // Atualizar progresso do lote atual
        await _refreshCurrentBatch();

        notifyListeners();
        return true;
      } else {
        _operationError = result.error ?? 'Erro ao adicionar item';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _operationError = 'Erro ao adicionar item: $e';
      notifyListeners();
      return false;
    } finally {
      _isAddingItem = false;
      notifyListeners();
    }
  }

  /// Selecionar item
  Future<void> selectItem(String itemId) async {
    try {
      final result = await _inventoryRepository.getInventoryItem(itemId);

      if (result.isSuccess && result.data != null) {
        _selectedItem = result.data!;
        notifyListeners();
      }
    } catch (e) {
      _itemsError = 'Erro ao selecionar item: $e';
      notifyListeners();
    }
  }

  /// Editar item inventariado
  Future<bool> updateInventoryItem({
    required String itemId,
    double? quantity,
    String? location,
    String? subLocation,
    String? tagCode,
    bool? tagDamaged,
    String? notes,
  }) async {
    _isUpdatingItem = true;
    _operationError = null;
    notifyListeners();

    try {
      final result = await _inventoryRepository.updateInventoryItem(
        itemId: itemId,
        quantity: quantity,
        location: location,
        subLocation: subLocation,
        tagCode: tagCode,
        tagDamaged: tagDamaged,
        notes: notes,
      );

      if (result.isSuccess && result.data != null) {
        // Atualizar item na lista local
        final index = _currentItems.indexWhere((item) => item.id == itemId);
        if (index >= 0) {
          _currentItems[index] = result.data!;
        }

        // Atualizar item selecionado se for o mesmo
        if (_selectedItem?.id == itemId) {
          _selectedItem = result.data!;
        }

        notifyListeners();
        return true;
      } else {
        _operationError = result.error ?? 'Erro ao editar item';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _operationError = 'Erro ao editar item: $e';
      notifyListeners();
      return false;
    } finally {
      _isUpdatingItem = false;
      notifyListeners();
    }
  }

  /// Deletar item inventariado
  Future<bool> deleteInventoryItem(String itemId) async {
    _isDeletingItem = true;
    _operationError = null;
    notifyListeners();

    try {
      final result = await _inventoryRepository.deleteInventoryItem(itemId);

      if (result.isSuccess) {
        // Remover item da lista local
        _currentItems.removeWhere((item) => item.id == itemId);

        // Limpar seleção se for o item deletado
        if (_selectedItem?.id == itemId) {
          _selectedItem = null;
        }

        // Atualizar progresso do lote atual
        await _refreshCurrentBatch();

        notifyListeners();
        return true;
      } else {
        _operationError = result.error ?? 'Erro ao deletar item';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _operationError = 'Erro ao deletar item: $e';
      notifyListeners();
      return false;
    } finally {
      _isDeletingItem = false;
      notifyListeners();
    }
  }

  /// Aplicar filtro de status
  void setStatusFilter(String? status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  /// Aplicar filtro de busca
  void setSearchFilter(String search) {
    _searchFilter = search;
    _applyFilters();
    notifyListeners();
  }

  /// Limpar todos os filtros
  void clearFilters() {
    _statusFilter = null;
    _searchFilter = '';
    _applyFilters();
    notifyListeners();
  }

  /// Aplicar filtros aos lotes
  void _applyFilters() {
    // Esta implementação seria mais complexa em um cenário real
    // Por agora, mantemos simples
    // TODO: Implementar filtros locais
  }

  /// Atualizar lote atual
  Future<void> _refreshCurrentBatch() async {
    if (_currentBatch == null) return;

    try {
      final result = await _inventoryRepository.getInventoryBatch(
        _currentBatch!.id,
      );
      if (result.isSuccess && result.data != null) {
        _currentBatch = result.data!;

        // Atualizar também na lista de lotes
        final index = _inventoryBatches.indexWhere(
          (b) => b.id == _currentBatch!.id,
        );
        if (index >= 0) {
          _inventoryBatches[index] = _currentBatch!;
        }
      }
    } catch (e) {
      print('Erro ao atualizar lote atual: $e');
    }
  }

  /// Limpar erros
  void clearErrors() {
    _batchesError = null;
    _itemsError = null;
    _searchError = null;
    _operationError = null;
    notifyListeners();
  }

  /// Limpar erro específico
  void clearBatchesError() {
    _batchesError = null;
    notifyListeners();
  }

  void clearItemsError() {
    _itemsError = null;
    notifyListeners();
  }

  void clearSearchError() {
    _searchError = null;
    notifyListeners();
  }

  void clearOperationError() {
    _operationError = null;
    notifyListeners();
  }

  /// Resetar estado
  void reset() {
    _inventoryBatches = [];
    _currentBatch = null;
    _currentItems = [];
    _selectedItem = null;
    _searchResults = [];
    _selectedProduct = null;
    _statusFilter = null;
    _searchFilter = '';
    _lastSearchTerm = '';
    clearErrors();
    notifyListeners();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }

  /// Debug: Obter informações do estado atual
  Map<String, dynamic> getDebugInfo() {
    return {
      'batchesCount': inventoryBatches.length,
      'currentBatchId': currentBatch?.id,
      'currentBatchStatus': currentBatch?.status.label,
      'currentItemsCount': currentItems.length,
      'selectedItemId': selectedItem?.id,
      'searchResultsCount': searchResults.length,
      'selectedProductCode': selectedProduct?.code,
      'isLoadingBatches': isLoadingBatches,
      'isLoadingItems': isLoadingItems,
      'isSearchingProducts': isSearchingProducts,
      'isPerformingOperation': isPerformingOperation,
      'hasActiveFilters': hasActiveFilters,
      'statusFilter': statusFilter,
      'searchFilter': searchFilter,
      'lastSearchTerm': lastSearchTerm,
      'currentProgress': currentProgress,
      'canStartCounting': canStartCounting,
      'canFinishCounting': canFinishCounting,
      'isCurrentBatchInProgress': isCurrentBatchInProgress,
    };
  }
}
