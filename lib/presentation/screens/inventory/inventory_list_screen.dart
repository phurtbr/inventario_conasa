import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/inventory_batch.dart';
import '../../../presentation/providers/inventory_provider.dart';
import '../../../presentation/providers/sync_provider.dart';
import '../../../presentation/widgets/common/loading_indicator.dart';
import '../../../presentation/widgets/common/error_widget.dart';
import '../../../presentation/widgets/inventory/inventory_card.dart';
import '../../../presentation/widgets/inventory/status_badge.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({Key? key}) : super(key: key);

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  InventoryStatus? _selectedStatus;
  String _sortBy = 'date';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInventories();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeInOut));

    _fabController.forward();
  }

  void _loadInventories() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inventoryProvider = Provider.of<InventoryProvider>(
        context,
        listen: false,
      );
      inventoryProvider.loadInventories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Consumer2<InventoryProvider, SyncProvider>(
        builder: (context, inventoryProvider, syncProvider, child) {
          return Column(
            children: [
              _buildSearchAndFilter(inventoryProvider),
              _buildInventoryStats(inventoryProvider),
              Expanded(
                child: _buildInventoryList(inventoryProvider, syncProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.createInventory),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text(AppStrings.newInventory),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(AppStrings.inventories),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _showSortDialog,
          icon: const Icon(Icons.sort),
          tooltip: AppStrings.sort,
        ),
        IconButton(
          onPressed: _refreshInventories,
          icon: const Icon(Icons.refresh),
          tooltip: AppStrings.refresh,
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter(InventoryProvider inventoryProvider) {
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
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppStrings.searchInventories,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        inventoryProvider.setSearchQuery('');
                      },
                      icon: const Icon(Icons.clear, color: Colors.grey),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              inventoryProvider.setSearchQuery(value);
            },
          ),
          const SizedBox(height: 16),
          _buildStatusFilter(inventoryProvider),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(InventoryProvider inventoryProvider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: AppStrings.all,
            isSelected: _selectedStatus == null,
            onSelected: () {
              setState(() {
                _selectedStatus = null;
              });
              inventoryProvider.setStatusFilter(null);
            },
          ),
          const SizedBox(width: 8),
          ...InventoryStatus.values.map(
            (status) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                label: _getStatusLabel(status),
                isSelected: _selectedStatus == status,
                onSelected: () {
                  setState(() {
                    _selectedStatus = status;
                  });
                  inventoryProvider.setStatusFilter(status);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey[300]!,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildInventoryStats(InventoryProvider inventoryProvider) {
    final stats = inventoryProvider.inventoryStats;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: AppStrings.total,
            value: stats.totalInventories.toString(),
            color: AppColors.primary,
          ),
          _buildStatDivider(),
          _buildStatItem(
            label: AppStrings.active,
            value: stats.activeInventories.toString(),
            color: AppColors.success,
          ),
          _buildStatDivider(),
          _buildStatItem(
            label: AppStrings.completed,
            value: stats.completedInventories.toString(),
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[300]);
  }

  Widget _buildInventoryList(
    InventoryProvider inventoryProvider,
    SyncProvider syncProvider,
  ) {
    if (inventoryProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingIndicator(size: 40),
            SizedBox(height: 16),
            Text(
              AppStrings.loadingInventories,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (inventoryProvider.error != null) {
      return Center(
        child: CustomErrorWidget(
          message: inventoryProvider.error!,
          onRetry: () => inventoryProvider.loadInventories(),
        ),
      );
    }

    final inventories = inventoryProvider.filteredInventories;

    if (inventories.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshInventories,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: inventories.length,
        itemBuilder: (context, index) {
          final inventory = inventories[index];
          final hasPendingSync = syncProvider.hasPendingSync(inventory.id);

          return AnimatedContainer(
            duration: Duration(milliseconds: 200 + (index * 50)),
            curve: Curves.easeOutBack,
            margin: const EdgeInsets.only(bottom: 12),
            child: InventoryCard(
              inventory: inventory,
              hasPendingSync: hasPendingSync,
              onTap: () => _navigateToInventoryDetail(inventory),
              onLongPress: () => _showInventoryOptions(inventory),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilter =
        _selectedStatus != null || _searchController.text.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilter ? Icons.search_off : Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? AppStrings.noResultsFound
                  : AppStrings.noInventoriesYet,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? AppStrings.tryDifferentFilter
                  : AppStrings.createFirstInventory,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (hasFilter)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedStatus = null;
                    _searchController.clear();
                  });
                  final inventoryProvider = Provider.of<InventoryProvider>(
                    context,
                    listen: false,
                  );
                  inventoryProvider.clearFilters();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text(AppStrings.clearFilters),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.createInventory),
                icon: const Icon(Icons.add),
                label: const Text(AppStrings.createInventory),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(InventoryStatus status) {
    switch (status) {
      case InventoryStatus.draft:
        return AppStrings.draft;
      case InventoryStatus.active:
        return AppStrings.active;
      case InventoryStatus.paused:
        return AppStrings.paused;
      case InventoryStatus.completed:
        return AppStrings.completed;
      case InventoryStatus.cancelled:
        return AppStrings.cancelled;
    }
  }

  void _showSortDialog() {
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
              AppStrings.sortBy,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSortOption(
              title: AppStrings.date,
              value: 'date',
              icon: Icons.date_range,
            ),
            _buildSortOption(
              title: AppStrings.name,
              value: 'name',
              icon: Icons.sort_by_alpha,
            ),
            _buildSortOption(
              title: AppStrings.status,
              value: 'status',
              icon: Icons.flag,
            ),
            _buildSortOption(
              title: AppStrings.progress,
              value: 'progress',
              icon: Icons.trending_up,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _sortAscending = !_sortAscending;
                      });
                      _applySorting();
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                    ),
                    label: Text(
                      _sortAscending
                          ? AppStrings.ascending
                          : AppStrings.descending,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _sortBy == value;

    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        _applySorting();
        Navigator.of(context).pop();
      },
    );
  }

  void _applySorting() {
    final inventoryProvider = Provider.of<InventoryProvider>(
      context,
      listen: false,
    );
    inventoryProvider.setSorting(_sortBy, _sortAscending);
  }

  Future<void> _refreshInventories() async {
    final inventoryProvider = Provider.of<InventoryProvider>(
      context,
      listen: false,
    );
    await inventoryProvider.refreshInventories();
  }

  void _navigateToInventoryDetail(InventoryBatch inventory) {
    Navigator.of(context).pushNamed(
      AppRoutes.inventoryDetail,
      arguments: {'inventoryId': inventory.id},
    );
  }

  void _showInventoryOptions(InventoryBatch inventory) {
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
              inventory.description,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StatusBadge(status: inventory.status),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text(AppStrings.viewDetails),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToInventoryDetail(inventory);
              },
            ),
            if (inventory.status == InventoryStatus.active)
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text(AppStrings.startCounting),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(
                    AppRoutes.counting,
                    arguments: {'inventoryId': inventory.id},
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text(AppStrings.syncInventory),
              onTap: () {
                Navigator.of(context).pop();
                _syncInventory(inventory);
              },
            ),
            if (inventory.status == InventoryStatus.draft)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text(
                  AppStrings.delete,
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteConfirmation(inventory);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _syncInventory(InventoryBatch inventory) async {
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);

    try {
      await syncProvider.syncInventory(inventory.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.syncCompleted),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.syncError),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(InventoryBatch inventory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.confirmDelete),
        content: Text(
          '${AppStrings.deleteInventoryConfirmation} "${inventory.description}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteInventory(inventory);
            },
            child: const Text(
              AppStrings.delete,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteInventory(InventoryBatch inventory) async {
    final inventoryProvider = Provider.of<InventoryProvider>(
      context,
      listen: false,
    );

    try {
      await inventoryProvider.deleteInventory(inventory.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.inventoryDeleted),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.deleteError),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
