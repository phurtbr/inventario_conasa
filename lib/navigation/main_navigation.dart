import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../presentation/providers/connectivity_provider.dart';
import '../presentation/providers/sync_provider.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/inventory/inventory_list_screen.dart';
import '../presentation/screens/counting/counting_screen.dart';
import '../presentation/screens/inventory/sync_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';

enum NavigationTab { home, inventories, counting, sync, settings }

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  final String? initialInventoryId;

  const MainNavigation({
    Key? key,
    this.initialIndex = 0,
    this.initialInventoryId,
  }) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  int _currentIndex = 0;
  bool _isInitialized = false;

  // Lista de abas de navegação
  final List<NavigationTabConfig> _tabs = [
    NavigationTabConfig(
      tab: NavigationTab.home,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: AppStrings.home,
      color: AppColors.primary,
    ),
    NavigationTabConfig(
      tab: NavigationTab.inventories,
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: AppStrings.inventories,
      color: AppColors.conasecondary,
    ),
    NavigationTabConfig(
      tab: NavigationTab.counting,
      icon: Icons.qr_code_scanner_outlined,
      selectedIcon: Icons.qr_code_scanner,
      label: AppStrings.counting,
      color: AppColors.accent,
    ),
    NavigationTabConfig(
      tab: NavigationTab.sync,
      icon: Icons.sync_outlined,
      selectedIcon: Icons.sync,
      label: AppStrings.sync,
      color: AppColors.success,
    ),
    NavigationTabConfig(
      tab: NavigationTab.settings,
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: AppStrings.settings,
      color: AppColors.textSecondary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isInitialized = true;
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Animar FAB baseado na aba selecionada
    if (_shouldShowFab(index)) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  bool _shouldShowFab(int index) {
    return index == NavigationTab.inventories.index ||
        index == NavigationTab.counting.index;
  }

  Widget _buildFab() {
    IconData fabIcon;
    String fabLabel;
    VoidCallback? fabAction;

    switch (NavigationTab.values[_currentIndex]) {
      case NavigationTab.inventories:
        fabIcon = Icons.add;
        fabLabel = AppStrings.newInventory;
        fabAction = _onCreateInventory;
        break;
      case NavigationTab.counting:
        fabIcon = Icons.qr_code_scanner;
        fabLabel = AppStrings.scanProduct;
        fabAction = _onScanProduct;
        break;
      default:
        return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _fabAnimationController,
      child: FloatingActionButton.extended(
        onPressed: fabAction,
        icon: Icon(fabIcon),
        label: Text(fabLabel),
        backgroundColor: _tabs[_currentIndex].color,
        foregroundColor: Colors.white,
        elevation: 4,
        heroTag: 'main_fab_${_currentIndex}',
      ),
    );
  }

  void _onCreateInventory() {
    Navigator.of(context).pushNamed('/create-inventory');
  }

  void _onScanProduct() {
    // Se há um inventário inicial, ir direto para o scanner
    if (widget.initialInventoryId != null) {
      Navigator.of(context).pushNamed(
        '/scanner',
        arguments: {'inventoryId': widget.initialInventoryId},
      );
    } else {
      // Mostrar seleção de inventário primeiro
      _showInventorySelectionDialog();
    }
  }

  void _showInventorySelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.selectInventory),
        content: const Text('Selecione um inventário para iniciar a contagem'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentIndex = NavigationTab.inventories.index;
              });
              _pageController.animateToPage(
                NavigationTab.inventories.index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: const Text(AppStrings.selectInventory),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });

        if (_shouldShowFab(index)) {
          _fabAnimationController.forward();
        } else {
          _fabAnimationController.reverse();
        }
      },
      children: [
        const HomeScreen(),
        const InventoryListScreen(),
        widget.initialInventoryId != null
            ? CountingScreen(inventoryId: widget.initialInventoryId!)
            : const _CountingPlaceholderScreen(),
        const SyncScreen(),
        const SettingsScreen(),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final config = entry.value;
              final isSelected = _currentIndex == index;

              return _buildNavigationItem(config, index, isSelected);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(
    NavigationTabConfig config,
    int index,
    bool isSelected,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? config.color.withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Icon(
                    isSelected ? config.selectedIcon : config.icon,
                    color: isSelected ? config.color : AppColors.textSecondary,
                    size: 24,
                  ),
                  if (config.tab == NavigationTab.sync) _buildSyncIndicator(),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? config.color : AppColors.textSecondary,
                ),
                child: Text(
                  config.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncIndicator() {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        if (!syncProvider.isSyncing && !syncProvider.hasPendingOperations) {
          return const SizedBox.shrink();
        }

        return Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: syncProvider.isSyncing
                  ? AppColors.warning
                  : AppColors.error,
              shape: BoxShape.circle,
            ),
            child: syncProvider.isSyncing
                ? Container(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 1,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildConnectivityBanner() {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, child) {
        if (connectivityProvider.isConnected) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.error,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.noInternetConnection,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => connectivityProvider.forceReconnect(),
                  child: const Text(
                    AppStrings.retry,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildConnectivityBanner(),
          Expanded(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeOut,
                        ),
                      ),
                  child: FadeTransition(
                    opacity: _animationController,
                    child: _buildBody(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class NavigationTabConfig {
  final NavigationTab tab;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color color;

  const NavigationTabConfig({
    required this.tab,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.color,
  });
}

class _CountingPlaceholderScreen extends StatelessWidget {
  const _CountingPlaceholderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.selectInventoryToCount,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vá para a aba Inventários para selecionar um inventário e iniciar a contagem',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navegar para a aba de inventários
                if (context.findAncestorStateOfType<_MainNavigationState>() !=
                    null) {
                  context
                      .findAncestorStateOfType<_MainNavigationState>()!
                      ._onTabSelected(NavigationTab.inventories.index);
                }
              },
              icon: const Icon(Icons.inventory_2),
              label: const Text(AppStrings.viewInventories),
            ),
          ],
        ),
      ),
    );
  }
}

// Extensão para facilitar o acesso ao estado de navegação
extension MainNavigationExtension on BuildContext {
  void navigateToTab(NavigationTab tab) {
    final navigationState = findAncestorStateOfType<_MainNavigationState>();
    navigationState?._onTabSelected(tab.index);
  }

  void navigateToInventories() => navigateToTab(NavigationTab.inventories);
  void navigateToHome() => navigateToTab(NavigationTab.home);
  void navigateToCounting() => navigateToTab(NavigationTab.counting);
  void navigateToSync() => navigateToTab(NavigationTab.sync);
  void navigateToSettings() => navigateToTab(NavigationTab.settings);
}
