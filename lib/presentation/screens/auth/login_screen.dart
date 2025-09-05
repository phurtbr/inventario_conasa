import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/formatters.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/connectivity_provider.dart';
import '../../presentation/widgets/common/loading_indicator.dart';
import '../../presentation/widgets/common/error_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _showServerConfig = false;
  bool _rememberMe = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSavedCredentials();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  void _loadSavedCredentials() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final savedCredentials = await authProvider.getSavedCredentials();

    if (savedCredentials != null) {
      setState(() {
        _usernameController.text = savedCredentials['username'] ?? '';
        _serverController.text =
            savedCredentials['serverUrl'] ?? AppStrings.defaultServerUrl;
        _rememberMe = savedCredentials['rememberMe'] ?? false;
      });
    } else {
      _serverController.text = AppStrings.defaultServerUrl;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<AuthProvider, ConnectivityProvider>(
        builder: (context, authProvider, connectivityProvider, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildLoginContent(authProvider, connectivityProvider),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginContent(
    AuthProvider authProvider,
    ConnectivityProvider connectivityProvider,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogo(),
            const SizedBox(height: 48),
            _buildLoginCard(authProvider, connectivityProvider),
            const SizedBox(height: 24),
            _buildServerConfigToggle(),
            if (_showServerConfig) ...[
              const SizedBox(height: 16),
              _buildServerConfigCard(connectivityProvider),
            ],
            const SizedBox(height: 24),
            _buildConnectionStatus(connectivityProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            size: 60,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          AppStrings.welcome,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
        ),
        const Text(
          AppStrings.appName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(
    AuthProvider authProvider,
    ConnectivityProvider connectivityProvider,
  ) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.loginTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.loginSubtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildUsernameField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildRememberMeCheckbox(),
              const SizedBox(height: 24),
              _buildLoginButton(authProvider, connectivityProvider),
              const SizedBox(height: 16),
              _buildForgotPasswordButton(),
              if (authProvider.error != null) ...[
                const SizedBox(height: 16),
                CustomErrorWidget(
                  message: authProvider.error!,
                  onRetry: () => authProvider.clearError(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: InputDecoration(
        labelText: AppStrings.username,
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      validator: Validators.validateRequired,
      onChanged: (_) => _clearErrorIfNeeded(),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: AppStrings.password,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      textInputAction: TextInputAction.done,
      validator: Validators.validateRequired,
      onChanged: (_) => _clearErrorIfNeeded(),
      onFieldSubmitted: (_) => _handleLogin(),
    );
  }

  Widget _buildRememberMeCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
        ),
        Text(
          AppStrings.rememberMe,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildLoginButton(
    AuthProvider authProvider,
    ConnectivityProvider connectivityProvider,
  ) {
    final isLoading = authProvider.isLoading;
    final isOffline = !connectivityProvider.isConnected;

    return ElevatedButton(
      onPressed: isLoading || isOffline ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: isLoading
          ? const LoadingIndicator(size: 20, color: Colors.white)
          : Text(
              isOffline ? AppStrings.noConnection : AppStrings.login,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: _showForgotPasswordDialog,
      child: Text(
        AppStrings.forgotPassword,
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildServerConfigToggle() {
    return TextButton.icon(
      onPressed: () {
        setState(() {
          _showServerConfig = !_showServerConfig;
        });
      },
      icon: Icon(
        _showServerConfig ? Icons.expand_less : Icons.expand_more,
        color: Colors.white70,
      ),
      label: const Text(
        AppStrings.serverConfig,
        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildServerConfigCard(ConnectivityProvider connectivityProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.serverConfig,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serverController,
              decoration: InputDecoration(
                labelText: AppStrings.serverUrl,
                prefixIcon: const Icon(Icons.cloud_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'http://servidor:porta/rest',
              ),
              keyboardType: TextInputType.url,
              validator: Validators.validateUrl,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: connectivityProvider.isConnected
                  ? _testConnection
                  : null,
              icon: const Icon(Icons.network_check),
              label: const Text(AppStrings.testConnection),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
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

  Widget _buildConnectionStatus(ConnectivityProvider connectivityProvider) {
    final isConnected = connectivityProvider.isConnected;
    final networkType = connectivityProvider.networkType;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: isConnected ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            isConnected
                ? '${AppStrings.connected} ($networkType)'
                : AppStrings.noConnection,
            style: TextStyle(
              color: isConnected ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _clearErrorIfNeeded() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.error != null) {
      authProvider.clearError();
    }
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        serverUrl: _serverController.text.trim(),
        rememberMe: _rememberMe,
      );

      if (success && mounted) {
        // Verificar se há empresa selecionada
        if (authProvider.selectedCompany != null) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.main);
        } else {
          Navigator.of(
            context,
          ).pushReplacementNamed(AppRoutes.companySelection);
        }
      }
    } catch (e) {
      // O erro será tratado pelo provider
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.loginError),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _testConnection() async {
    if (_serverController.text.trim().isEmpty) {
      _showErrorSnackBar(AppStrings.serverUrlRequired);
      return;
    }

    final connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );

    try {
      final isValid = await connectivityProvider.testServerConnection(
        _serverController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isValid
                  ? AppStrings.connectionSuccess
                  : AppStrings.connectionError,
            ),
            backgroundColor: isValid ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(AppStrings.connectionError);
      }
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.forgotPassword),
        content: const Text(AppStrings.forgotPasswordMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
