import 'package:flutter/material.dart';
import '../../data/models/inventory_item.dart';
import '../../data/models/product.dart';
import '../../data/models/photo.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/services/photo_service.dart';
import '../../core/utils/validators.dart';
import '../../core/constants/app_strings.dart';

enum CountingMode { scanner, manual, guided }

enum CountingStep {
  productScan,
  quantityInput,
  locationInput,
  photoCapture,
  confirmation,
}

class CountingSession {
  final String inventoryId;
  final String sessionId;
  final DateTime startTime;
  final CountingMode mode;
  final List<String> processedItems;
  int totalScanned;
  int totalErrors;

  CountingSession({
    required this.inventoryId,
    required this.sessionId,
    required this.startTime,
    required this.mode,
    this.processedItems = const [],
    this.totalScanned = 0,
    this.totalErrors = 0,
  });

  CountingSession copyWith({
    String? inventoryId,
    String? sessionId,
    DateTime? startTime,
    CountingMode? mode,
    List<String>? processedItems,
    int? totalScanned,
    int? totalErrors,
  }) {
    return CountingSession(
      inventoryId: inventoryId ?? this.inventoryId,
      sessionId: sessionId ?? this.sessionId,
      startTime: startTime ?? this.startTime,
      mode: mode ?? this.mode,
      processedItems: processedItems ?? this.processedItems,
      totalScanned: totalScanned ?? this.totalScanned,
      totalErrors: totalErrors ?? this.totalErrors,
    );
  }
}

class CountingProvider with ChangeNotifier {
  final InventoryRepository _inventoryRepository;
  final PhotoService _photoService;

  CountingProvider(this._inventoryRepository, this._photoService);

  // Estados da sessão de contagem
  CountingSession? _currentSession;
  CountingStep _currentStep = CountingStep.productScan;
  bool _isProcessing = false;
  String? _error;

  // Dados temporários da contagem atual
  String _scannedCode = '';
  Product? _currentProduct;
  InventoryItem? _currentItem;
  double _enteredQuantity = 0;
  String _enteredLocation = '';
  List<Photo> _capturedPhotos = [];

  // Configurações de contagem
  bool _requirePhotoConfirmation = false;
  bool _allowNegativeQuantity = false;
  bool _requireLocationConfirmation = true;
  bool _autoAdvanceOnScan = true;
  bool _vibrationEnabled = true;
  bool _soundEnabled = true;

  // Estados de validação
  Map<String, String> _validationErrors = {};
  bool _isValidatingCode = false;

  // Getters
  CountingSession? get currentSession => _currentSession;
  CountingStep get currentStep => _currentStep;
  bool get isProcessing => _isProcessing;
  bool get isCountingActive => _currentSession != null;
  String? get error => _error;

  String get scannedCode => _scannedCode;
  Product? get currentProduct => _currentProduct;
  InventoryItem? get currentItem => _currentItem;
  double get enteredQuantity => _enteredQuantity;
  String get enteredLocation => _enteredLocation;
  List<Photo> get capturedPhotos => _capturedPhotos;

  // Configurações
  bool get requirePhotoConfirmation => _requirePhotoConfirmation;
  bool get allowNegativeQuantity => _allowNegativeQuantity;
  bool get requireLocationConfirmation => _requireLocationConfirmation;
  bool get autoAdvanceOnScan => _autoAdvanceOnScan;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get soundEnabled => _soundEnabled;

  // Validações
  Map<String, String> get validationErrors => _validationErrors;
  bool get isValidatingCode => _isValidatingCode;
  bool get canProceedToNextStep => _getCanProceedToNextStep();
  bool get canFinishCounting => _getCanFinishCounting();

  // Estatísticas da sessão atual
  int get sessionDurationMinutes => _currentSession != null
      ? DateTime.now().difference(_currentSession!.startTime).inMinutes
      : 0;

  double get itemsPerMinute => sessionDurationMinutes > 0
      ? (_currentSession?.totalScanned ?? 0) / sessionDurationMinutes
      : 0;

  // Iniciar sessão de contagem
  Future<void> startCountingSession(
    String inventoryId,
    CountingMode mode,
  ) async {
    _currentSession = CountingSession(
      inventoryId: inventoryId,
      sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      startTime: DateTime.now(),
      mode: mode,
    );

    _resetCurrentItem();
    _currentStep = CountingStep.productScan;
    _error = null;

    notifyListeners();
  }

  // Finalizar sessão de contagem
  void endCountingSession() {
    _currentSession = null;
    _resetCurrentItem();
    _currentStep = CountingStep.productScan;
    _error = null;
    notifyListeners();
  }

  // Processar código escaneado ou digitado
  Future<void> processProductCode(String code) async {
    if (_isValidatingCode) return;

    _isValidatingCode = true;
    _error = null;
    _validationErrors.clear();
    notifyListeners();

    try {
      // Validar formato do código
      if (!Validators.isValidProductCode(code)) {
        _validationErrors['code'] = AppStrings.invalidProductCode;
        return;
      }

      _scannedCode = code;

      // Buscar produto no repositório
      _currentProduct = await _inventoryRepository.getProductByCode(code);

      if (_currentProduct == null) {
        _validationErrors['code'] = AppStrings.productNotFound;
        return;
      }

      // Verificar se já existe item para este produto no inventário
      if (_currentSession != null) {
        final existingItem = await _inventoryRepository
            .getInventoryItemByProduct(_currentSession!.inventoryId, code);
        _currentItem = existingItem;
      }

      // Pré-preencher dados se item já existe
      if (_currentItem != null) {
        _enteredQuantity = _currentItem!.countedQuantity;
        _enteredLocation = _currentItem!.location ?? '';
      } else {
        _enteredQuantity = 0;
        _enteredLocation = _currentProduct!.defaultLocation ?? '';
      }

      // Avançar para próximo step automaticamente se configurado
      if (_autoAdvanceOnScan && _validationErrors.isEmpty) {
        _advanceToNextStep();
      }
    } catch (e) {
      _error = AppStrings.errorProcessingProduct;
      debugPrint('Erro ao processar código do produto: $e');
    } finally {
      _isValidatingCode = false;
      notifyListeners();
    }
  }

  // Definir quantidade contada
  void setQuantity(double quantity) {
    _enteredQuantity = quantity;
    _validationErrors.remove('quantity');

    // Validar quantidade
    if (!_allowNegativeQuantity && quantity < 0) {
      _validationErrors['quantity'] = AppStrings.negativeQuantityNotAllowed;
    }

    if (quantity.toString().split('.').length > 1 &&
        quantity.toString().split('.')[1].length > 3) {
      _validationErrors['quantity'] = AppStrings.tooManyDecimals;
    }

    notifyListeners();
  }

  // Definir localização
  void setLocation(String location) {
    _enteredLocation = location.trim();
    _validationErrors.remove('location');

    if (_requireLocationConfirmation && location.trim().isEmpty) {
      _validationErrors['location'] = AppStrings.locationRequired;
    }

    notifyListeners();
  }

  // Capturar foto
  Future<void> capturePhoto() async {
    if (_currentProduct == null) return;

    try {
      _isProcessing = true;
      notifyListeners();

      final photo = await _photoService.capturePhoto(
        inventoryId: _currentSession!.inventoryId,
        productCode: _currentProduct!.code,
      );

      if (photo != null) {
        _capturedPhotos.add(photo);
      }
    } catch (e) {
      _error = AppStrings.errorCapturingPhoto;
      debugPrint('Erro ao capturar foto: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Remover foto
  void removePhoto(String photoId) {
    _capturedPhotos.removeWhere((photo) => photo.id == photoId);
    notifyListeners();
  }

  // Avançar para próximo step
  void _advanceToNextStep() {
    switch (_currentStep) {
      case CountingStep.productScan:
        if (_currentProduct != null) {
          _currentStep = CountingStep.quantityInput;
        }
        break;
      case CountingStep.quantityInput:
        if (_validationErrors['quantity'] == null) {
          _currentStep = _requireLocationConfirmation
              ? CountingStep.locationInput
              : (_requirePhotoConfirmation
                    ? CountingStep.photoCapture
                    : CountingStep.confirmation);
        }
        break;
      case CountingStep.locationInput:
        if (_validationErrors['location'] == null) {
          _currentStep = _requirePhotoConfirmation
              ? CountingStep.photoCapture
              : CountingStep.confirmation;
        }
        break;
      case CountingStep.photoCapture:
        _currentStep = CountingStep.confirmation;
        break;
      case CountingStep.confirmation:
        // Finalizar item atual
        break;
    }
    notifyListeners();
  }

  // Voltar para step anterior
  void goToPreviousStep() {
    switch (_currentStep) {
      case CountingStep.quantityInput:
        _currentStep = CountingStep.productScan;
        break;
      case CountingStep.locationInput:
        _currentStep = CountingStep.quantityInput;
        break;
      case CountingStep.photoCapture:
        _currentStep = _requireLocationConfirmation
            ? CountingStep.locationInput
            : CountingStep.quantityInput;
        break;
      case CountingStep.confirmation:
        _currentStep = _requirePhotoConfirmation
            ? CountingStep.photoCapture
            : (_requireLocationConfirmation
                  ? CountingStep.locationInput
                  : CountingStep.quantityInput);
        break;
      case CountingStep.productScan:
        // Já está no primeiro step
        break;
    }
    notifyListeners();
  }

  // Ir diretamente para um step específico
  void goToStep(CountingStep step) {
    _currentStep = step;
    notifyListeners();
  }

  // Confirmar e salvar item contado
  Future<void> confirmCurrentItem() async {
    if (!_getCanFinishCounting()) return;

    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // Criar ou atualizar item do inventário
      final item = InventoryItem(
        id: _currentItem?.id,
        inventoryId: _currentSession!.inventoryId,
        productCode: _currentProduct!.code,
        productDescription: _currentProduct!.description,
        countedQuantity: _enteredQuantity,
        location: _enteredLocation.isNotEmpty ? _enteredLocation : null,
        photos: _capturedPhotos.map((p) => p.id!).toList(),
        countedAt: DateTime.now(),
        countedBy: 'current_user', // Seria obtido do AuthProvider
        isCompleted: true,
        needsReview: false,
      );

      await _inventoryRepository.saveInventoryItem(item);

      // Atualizar estatísticas da sessão
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(
          totalScanned: _currentSession!.totalScanned + 1,
          processedItems: [
            ..._currentSession!.processedItems,
            _currentProduct!.code,
          ],
        );
      }

      // Reset para próximo item
      _resetCurrentItem();
      _currentStep = CountingStep.productScan;
    } catch (e) {
      _error = AppStrings.errorSavingItem;
      _currentSession = _currentSession?.copyWith(
        totalErrors: (_currentSession?.totalErrors ?? 0) + 1,
      );
      debugPrint('Erro ao confirmar item: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Pular item atual
  void skipCurrentItem() {
    _resetCurrentItem();
    _currentStep = CountingStep.productScan;
    notifyListeners();
  }

  // Reset dados do item atual
  void _resetCurrentItem() {
    _scannedCode = '';
    _currentProduct = null;
    _currentItem = null;
    _enteredQuantity = 0;
    _enteredLocation = '';
    _capturedPhotos.clear();
    _validationErrors.clear();
  }

  // Configurações
  void setRequirePhotoConfirmation(bool require) {
    _requirePhotoConfirmation = require;
    notifyListeners();
  }

  void setAllowNegativeQuantity(bool allow) {
    _allowNegativeQuantity = allow;
    notifyListeners();
  }

  void setRequireLocationConfirmation(bool require) {
    _requireLocationConfirmation = require;
    notifyListeners();
  }

  void setAutoAdvanceOnScan(bool autoAdvance) {
    _autoAdvanceOnScan = autoAdvance;
    notifyListeners();
  }

  void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
    notifyListeners();
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    notifyListeners();
  }

  // Validações privadas
  bool _getCanProceedToNextStep() {
    switch (_currentStep) {
      case CountingStep.productScan:
        return _currentProduct != null && !_isValidatingCode;
      case CountingStep.quantityInput:
        return _validationErrors['quantity'] == null;
      case CountingStep.locationInput:
        return _validationErrors['location'] == null;
      case CountingStep.photoCapture:
        return !_requirePhotoConfirmation || _capturedPhotos.isNotEmpty;
      case CountingStep.confirmation:
        return true;
    }
  }

  bool _getCanFinishCounting() {
    return _currentProduct != null &&
        _validationErrors.isEmpty &&
        (!_requirePhotoConfirmation || _capturedPhotos.isNotEmpty) &&
        (!_requireLocationConfirmation || _enteredLocation.isNotEmpty);
  }

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Limpar erro de validação específico
  void clearValidationError(String field) {
    _validationErrors.remove(field);
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
