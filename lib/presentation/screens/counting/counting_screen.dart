import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';
import '../../../data/models/inventory_item.dart';
import '../../../presentation/providers/counting_provider.dart';
import '../../../presentation/providers/inventory_provider.dart';
import '../../../presentation/widgets/common/loading_indicator.dart';
import '../../../presentation/widgets/common/error_widget.dart';
import '../../../presentation/widgets/counting/product_info_card.dart';
import '../../../presentation/widgets/counting/quantity_input.dart';
import '../../../presentation/widgets/counting/photo_grid.dart';

enum CountingMode { scanner, manual, search }

class CountingScreen extends StatefulWidget {
  final String inventoryId;

  const CountingScreen({
    Key? key,
    required this.inventoryId,
  }) : super(key: key);

  @override
  State<CountingScreen> createState() => _CountingScreenState();
}

class _CountingScreenState extends State<CountingScreen>
    with TickerProviderStateMixin {
  final _codeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _observationsController = TextEditingController();
  final _scrollController = ScrollController();

  late AnimationController _slideController;
  late AnimationController _bounceController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;

  CountingMode _currentMode = CountingMode.scanner;
  Product? _currentProduct;
  bool _isConfirming = false;
  int _itemCount = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSession();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _bounceController.dispose();
    _codeController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _observationsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _slideController.forward();
  }

  void _initializeSession() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final countingProvider = Provider.of<CountingProvider>(context, listen: false);
      countingProvider.startSession(widget.inventoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Consumer2<CountingProvider, InventoryProvider>(
        builder: (context, countingProvider, inventoryProvider, child) {
          return Column(
            children: [
              _buildProgressHeader(countingProvider),
              Expanded(
                child: _buildContent(countingProvider),
              ),
              _buildBottomActions(countingProvider),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(AppStrings.counting),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _showCountingHistory,
          icon: const Icon(Icons.history),
          tooltip: AppStrings.history,
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'mode',
              child: Text(AppStrings.resumeCounting),
            ),
            const PopupMenuItem(
              value: 'pause',
              child: Text(AppStrings.pauseCounting),
            ),
            const PopupMenuItem(
              value: 'finish',
              child: Text(AppStrings.finishCounting),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.quantity,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            QuantityInput(
              controller: _quantityController,
              product: _currentProduct!,
              onChanged: _validateQuantity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.location,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: AppStrings.inventoryLocation,
                hintText: AppStrings.locationInput,
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(CountingProvider countingProvider) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  AppStrings.photos,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${countingProvider.sessionPhotos.length}/5',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PhotoGrid(
              photos: countingProvider.sessionPhotos,
              onAddPhoto: _addPhoto,
              onRemovePhoto: _removePhoto,
              onViewPhoto: _viewPhoto,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservationsSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.notes,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observationsController,
              decoration: InputDecoration(
                hintText: AppStrings.enterObservations,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(CountingProvider countingProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _clearCurrentItem,
                icon: const Icon(Icons.clear),
                label: const Text(AppStrings.clear),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ScaleTransition(
                scale: _bounceAnimation,
                child: ElevatedButton.icon(
                  onPressed: _currentProduct != null && !countingProvider.isLoading
                      ? () => _confirmItem(countingProvider)
                      : null,
                  icon: countingProvider.isLoading
                      ? const LoadingIndicator(size: 16, color: Colors.white)
                      : const Icon(Icons.check),
                  label: Text(_isConfirming ? AppStrings.confirming : AppStrings.confirm),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getModeLabel(CountingMode mode) {
    switch (mode) {
      case CountingMode.scanner:
        return AppStrings.scanner;
      case CountingMode.manual:
        return AppStrings.manual;
      case CountingMode.search:
        return AppStrings.search;
    }
  }

  String _getInputTitle() {
    switch (_currentMode) {
      case CountingMode.scanner:
        return AppStrings.scanBarcode;
      case CountingMode.manual:
        return AppStrings.productCode;
      case CountingMode.search:
        return AppStrings.scanProduct;
    }
  }

  void _changeMode(CountingMode mode) {
    setState(() {
      _currentMode = mode;
      _clearCurrentItem();
    });
  }

  void _openScanner() {
    Navigator.of(context).pushNamed(
      AppRoutes.scanner,
      arguments: {
        'inventoryId': widget.inventoryId,
        'returnTo': AppRoutes.counting,
      },
    ).then((result) {
      if (result != null && result is String) {
        _codeController.text = result;
        _searchProduct(Provider.of<CountingProvider>(context, listen: false));
      }
    });
  }

  void _searchProduct(CountingProvider countingProvider) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    HapticFeedback.lightImpact();

    try {
      final product = await countingProvider.searchProduct(code);
      if (product != null && mounted) {
        setState(() {
          _currentProduct = product;
          _quantityController.text = '1';
        });
        
        _bounceController.forward().then((_) {
          _bounceController.reverse();
        });

        // Auto-scroll para mostrar as opções de quantidade
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.productNotFound),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _validateQuantity(String value) {
    // Validação em tempo real da quantidade
    if (_currentProduct != null) {
      final quantity = double.tryParse(value);
      if (quantity != null && quantity > 0) {
        // Quantidade válida
      }
    }
  }

  void _addPhoto() {
    Navigator.of(context).pushNamed(
      AppRoutes.photoCapture,
      arguments: {
        'inventoryId': widget.inventoryId,
        'productCode': _currentProduct?.code ?? '',
      },
    );
  }

  void _removePhoto(int index) {
    final countingProvider = Provider.of<CountingProvider>(context, listen: false);
    countingProvider.removePhoto(index);
  }

  void _viewPhoto(int index) {
    final countingProvider = Provider.of<CountingProvider>(context, listen: false);
    final photos = countingProvider.sessionPhotos;
    
    if (index < photos.length) {
      Navigator.of(context).pushNamed(
        AppRoutes.photoViewer,
        arguments: {
          'photoPath': photos[index].filePath,
          'photoIndex': index,
        },
      );
    }
  }

  void _showProductDetails() {
    if (_currentProduct != null) {
      Navigator.of(context).pushNamed(
        AppRoutes.productDetail,
        arguments: {'productCode': _currentProduct!.code},
      );
    }
  }

  void _clearCurrentItem() {
    setState(() {
      _currentProduct = null;
      _isConfirming = false;
      _codeController.clear();
      _quantityController.clear();
      _locationController.clear();
      _observationsController.clear();
    });
    
    final countingProvider = Provider.of<CountingProvider>(context, listen: false);
    countingProvider.clearSessionPhotos();
  }

  void _confirmItem(CountingProvider countingProvider) async {
    if (_currentProduct == null) return;

    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.invalidQuantity),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isConfirming = true;
    });

    HapticFeedback.mediumImpact();

    try {
      final item = InventoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        inventoryId: widget.inventoryId,
        productCode: _currentProduct!.code,
        productDescription: _currentProduct!.description,
        quantity: quantity,
        unit: _currentProduct!.unit,
        location: _locationController.text.trim(),
        observations: _observationsController.text.trim(),
        countedAt: DateTime.now(),
        countedBy: '', // Será preenchido pelo provider
        photos: countingProvider.sessionPhotos,
        isSync: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await countingProvider.addInventoryItem(item);

      if (mounted) {
        setState(() {
          _itemCount++;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.itemAdded),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );

        _clearCurrentItem();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.errorAddingItem),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  void _showCountingHistory() {
    Navigator.of(context).pushNamed(
      AppRoutes.itemsList,
      arguments: {'inventoryId': widget.inventoryId},
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'mode':
        _showModeSelector();
        break;
      case 'pause':
        _pauseSession();
        break;
      case 'finish':
        _finishSession();
        break;
    }
  }

  void _showModeSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.selectMode,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text(AppStrings.scanner),
              subtitle: const Text(AppStrings.scannerDescription),
              trailing: _currentMode == CountingMode.scanner
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                Navigator.of(context).pop();
                _changeMode(CountingMode.scanner);
              },
            ),
            ListTile(
              leading: const Icon(Icons.keyboard),
              title: const Text(AppStrings.manual),
              subtitle: const Text(AppStrings.manualDescription),
              trailing: _currentMode == CountingMode.manual
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                Navigator.of(context).pop();
                _changeMode(CountingMode.manual);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text(AppStrings.search),
              subtitle: const Text(AppStrings.searchDescription),
              trailing: _currentMode == CountingMode.search
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                Navigator.of(context).pop();
                _changeMode(CountingMode.search);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pauseSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.pauseSession),
        content: const Text(AppStrings.pauseSessionConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performPauseSession();
            },
            child: const Text(AppStrings.pause),
          ),
        ],
      ),
    );
  }

  void _performPauseSession() async {
    final countingProvider = Provider.of<CountingProvider>(context, listen: false);
    
    try {
      await countingProvider.pauseSession();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.sessionPaused),
            backgroundColor: AppColors.info,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.errorPausingSession),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _finishSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.finishSession),
        content: Text('${AppStrings.finishSessionConfirmation} $_itemCount ${AppStrings.itemsCounted}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performFinishSession();
            },
            child: const Text(AppStrings.finish),
          ),
        ],
      ),
    );
  }

  void _performFinishSession() async {
    final countingProvider = Provider.of<CountingProvider>(context, listen: false);
    
    try {
      await countingProvider.finishSession();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.sessionCompleted),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.errorFinishingSession),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}buildProgressHeader(CountingProvider countingProvider) {
    final session = countingProvider.currentSession;
    final progress = countingProvider.sessionProgress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session?.inventoryDescription ?? AppStrings.inventory,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppStrings.mode}: ${_getModeLabel(_currentMode)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _itemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% ${AppStrings.completed}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(CountingProvider countingProvider) {
    if (countingProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingIndicator(size: 40),
            SizedBox(height: 16),
            Text(
              AppStrings.loading,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (countingProvider.error != null) {
      return Center(
        child: CustomErrorWidget(
          message: countingProvider.error!,
          onRetry: () => countingProvider.clearError(),
        ),
      );
    }

    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildModeSelector(),
            const SizedBox(height: 16),
            _buildInputSection(countingProvider),
            if (_currentProduct != null) ...[
              const SizedBox(height: 16),
              _buildProductInfo(),
              const SizedBox(height: 16),
              _buildQuantitySection(),
              const SizedBox(height: 16),
              _buildLocationSection(),
              const SizedBox(height: 16),
              _buildPhotoSection(countingProvider),
              const SizedBox(height: 16),
              _buildObservationsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: _buildModeButton(
                mode: CountingMode.scanner,
                icon: Icons.qr_code_scanner,
                label: AppStrings.scanner,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildModeButton(
                mode: CountingMode.manual,
                icon: Icons.keyboard,
                label: AppStrings.manual,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildModeButton(
                mode: CountingMode.search,
                icon: Icons.search,
                label: AppStrings.search,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required CountingMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentMode == mode;

    return GestureDetector(
      onTap: () => _changeMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(CountingProvider countingProvider) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _getInputTitle(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_currentMode == CountingMode.scanner)
              _buildScannerButton()
            else
              _buildManualInput(countingProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerButton() {
    return ElevatedButton.icon(
      onPressed: _openScanner,
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text(AppStrings.openScanner),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.conasecondary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildManualInput(CountingProvider countingProvider) {
    return Column(
      children: [
        TextFormField(
          controller: _codeController,
          decoration: InputDecoration(
            labelText: AppStrings.productCode,
            hintText: AppStrings.enterProductCode,
            prefixIcon: const Icon(Icons.qr_code),
            suffixIcon: IconButton(
              onPressed: () => _searchProduct(countingProvider),
              icon: const Icon(Icons.search),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          textInputAction: TextInputAction.search,
          onFieldSubmitted: (_) => _searchProduct(countingProvider),
          validator: Validators.validateRequired,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _searchProduct(countingProvider),
          icon: const Icon(Icons.search),
          label: const Text(AppStrings.searchProduct),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return ProductInfoCard(
      product: _currentProduct!,
      onTap: () => _showProductDetails(),
    );
  }

  Widget _