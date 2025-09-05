import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/inventory_provider.dart';
import '../../../presentation/providers/sync_provider.dart';
import '../../../presentation/providers/connectivity_provider.dart';
import '../../../presentation/widgets/common/loading_indicator.dart';
import '../../../presentation/widgets/inventory/inventory_card.dart';
import '../../../presentation/widgets/inventory/status_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _loadInitialData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  void _initializeAnimations() {
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _refreshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut),
    );
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inventoryProvider = Provider.of<InventoryProvider>(
        context,
        listen: false,
      );
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);

      inventoryProvider.loadInventories();
      syncProvider.checkPendingSyncs();
    });
  }

  void _refreshData() async {
    _refreshController.forward();

    final inventoryProvider = Provider.of<InventoryProvider>(
      context,
      listen: false,
    );
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);

    await Future.wait([
      inventoryProvider.refreshInventories(),
      syncProvider.checkPendingSyncs(),
    ]);

    _refreshController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body:
          Consumer4<
            AuthProvider,
            InventoryProvider,
            SyncProvider,
            ConnectivityProvider
          >(
            builder:
                (
                  context,
                  authProvider,
                  inventoryProvider,
                  syncProvider,
                  connectivityProvider,
                  child,
                ) {
                  return RefreshIndicator(
                    onRefresh: _refreshData,
                    color: AppColors.primary,
                    child: CustomScrollView(
                      slivers: [
                        _buildAppBar(authProvider, connectivityProvider),
                        _buildDashboardCards(inventoryProvider, syncProvider),
                        _buildQuickActions(),
                        _buildRecentInventories(inventoryProvider),
                        _buildSyncStatus(syncProvider),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 100),
                        ), // Bottom padding
                      ],
                    ),
                  );
                },
          ),
    );
  }

  Widget _buildAppBar(
    AuthProvider authProvider,
    ConnectivityProvider connectivityProvider,
  ) {
    final user = authProvider.currentUser;
    final company = authProvider.selectedCompany;

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          AppStrings.appName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppStrings.welcome}, ${user?.name ?? AppStrings.user}!',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            if (company != null)
                              Text(
                                company.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildConnectionIndicator(connectivityProvider),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionIndicator(ConnectivityProvider connectivityProvider) {
    final isConnected = connectivityProvider.isConnected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.cloud_done : Icons.cloud_off,
            size: 16,
            color: isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            isConnected ? AppStrings.online : AppStrings.offline,
            style: TextStyle(
              color: isConnected ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCards(
    InventoryProvider inventoryProvider,
    SyncProvider syncProvider,
  ) {
    final stats = inventoryProvider.inventoryStats;
    final syncStats = syncProvider.syncStats;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.dashboard,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: AppStrings.totalInventories,
                    value: stats.totalInventories.toString(),
                    icon: Icons.inventory_2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: AppStrings.activeInventories,
                    value: stats.activeInventories.toString(),
                    icon: Icons.play_circle_fill,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: AppStrings.itemsCounted,
                    value: stats.totalItemsCounted.toString(),
                    icon: Icons.check_circle,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: AppStrings.pendingSync,
                    value: syncStats.pendingItems.toString(),
                    icon: Icons.sync_problem,
                    color: syncStats.pendingItems > 0
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.trending_up, size: 16, color: color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.quickActions,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    title: AppStrings.newInventory,
                    subtitle: AppStrings.createNewInventory,
                    icon: Icons.add_box,
                    color: AppColors.primary,
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.createInventory),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    title: AppStrings.scanProduct,
                    subtitle: AppStrings.quickScan,
                    icon: Icons.qr_code_scanner,
                    color: AppColors.secondary,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.scanner),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    title: AppStrings.syncData,
                    subtitle: AppStrings.syncAllData,
                    icon: Icons.sync,
                    color: AppColors.info,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.syncStatus),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    title: AppStrings.viewReports,
                    subtitle: AppStrings.inventoryReports,
                    icon: Icons.assessment,
                    color: AppColors.success,
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.inventoryHistory),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentInventories(InventoryProvider inventoryProvider) {
    if (inventoryProvider.isLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: LoadingIndicator(),
          ),
        ),
      );
    }

    final recentInventories = inventoryProvider.inventories.take(3).toList();

    if (recentInventories.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildEmptyInventoriesState(),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  AppStrings.recentInventories,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.inventoryList),
                  child: Text(
                    AppStrings.viewAll,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recentInventories.map(
              (inventory) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InventoryCard(
                  inventory: inventory,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.inventoryDetail,
                    arguments: {'inventoryId': inventory.id},
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInventoriesState() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              AppStrings.noInventoriesYet,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.createFirstInventory,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.createInventory),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.createInventory),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatus(SyncProvider syncProvider) {
    final stats = syncProvider.syncStats;

    if (stats.pendingItems == 0 && !syncProvider.isSyncing) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          color: syncProvider.isSyncing
              ? AppColors.info.withOpacity(0.1)
              : AppColors.warning.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  syncProvider.isSyncing ? Icons.sync : Icons.sync_problem,
                  color: syncProvider.isSyncing
                      ? AppColors.info
                      : AppColors.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        syncProvider.isSyncing
                            ? AppStrings.syncInProgress
                            : AppStrings.syncPending,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!syncProvider.isSyncing)
                        Text(
                          '${stats.pendingItems} ${AppStrings.itemsPendingSync}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                if (syncProvider.isSyncing)
                  const LoadingIndicator(size: 20)
                else
                  TextButton(
                    onPressed: () async {
                      await syncProvider.syncAll();
                    },
                    child: const Text(AppStrings.syncNow),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
