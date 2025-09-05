import 'package:flutter/material.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

/// Provider para gerenciamento de estado de autenticação
/// Controla login, logout e estado do usuário logado
class AuthProvider with ChangeNotifier {
  static AuthProvider? _instance;
  static AuthProvider get instance => _instance ??= AuthProvider._();

  AuthProvider._();

  final AuthRepository _authRepository = AuthRepository.instance;

  // Estado do usuário
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  List<UserCompany> _availableCompanies = [];

  // Estado de login
  bool _isLoggingIn = false;
  bool _isLoggingOut = false;

  // Estado de configuração
  String? _serverUrl;
  bool _isServerConfigured = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null && _authRepository.isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<UserCompany> get availableCompanies => _availableCompanies;
  bool get isLoggingIn => _isLoggingIn;
  bool get isLoggingOut => _isLoggingOut;
  String? get serverUrl => _serverUrl;
  bool get isServerConfigured => _isServerConfigured;

  // Getters de conveniência
  bool get hasError => _error != null;
  String get userName => _currentUser?.name ?? '';
  String get userEmail => _currentUser?.email ?? '';
  UserCompany? get selectedCompany => _currentUser?.selectedCompany;
  bool get hasSelectedCompany => selectedCompany != null;

  /// Inicializar provider
  Future<void> initialize() async {
    await _loadServerConfiguration();
    await _tryAutoLogin();
  }

  /// Carregar configuração do servidor
  Future<void> _loadServerConfiguration() async {
    try {
      final url = await _authRepository.getServerUrl();
      _serverUrl = url;
      _isServerConfigured = url != null && url.isNotEmpty;
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar configuração: $e');
    }
  }

  /// Tentar login automático
  Future<void> _tryAutoLogin() async {
    if (!_isServerConfigured) return;

    _setLoading(true);

    try {
      final result = await _authRepository.autoLogin();
      if (result.isSuccess && result.data != null) {
        _currentUser = result.data!;
        _clearError();
        notifyListeners();
      }
    } catch (e) {
      // Erro silencioso no auto-login
      print('Auto-login falhou: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Configurar URL do servidor
  Future<bool> configureServer(String url) async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.setServerUrl(url);
      _serverUrl = url;
      _isServerConfigured = true;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao configurar servidor: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Testar conexão com servidor
  Future<bool> testServerConnection() async {
    if (_serverUrl == null || _serverUrl!.isEmpty) {
      _setError('URL do servidor não configurada');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final isConnected = await _authRepository.testServerConnection();
      if (!isConnected) {
        _setError('Não foi possível conectar ao servidor');
      }
      return isConnected;
    } catch (e) {
      _setError('Erro ao testar conexão: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Fazer login
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    if (!_isServerConfigured) {
      _setError('Servidor não configurado');
      return false;
    }

    _isLoggingIn = true;
    _clearError();
    notifyListeners();

    try {
      final result = await _authRepository.login(
        username: username,
        password: password,
      );

      if (result.isSuccess && result.data != null) {
        _currentUser = result.data!;
        notifyListeners();
        return true;
      } else {
        _setError(result.error ?? 'Falha no login');
        return false;
      }
    } catch (e) {
      _setError('Erro durante login: $e');
      return false;
    } finally {
      _isLoggingIn = false;
      notifyListeners();
    }
  }

  /// Fazer logout
  Future<void> logout() async {
    _isLoggingOut = true;
    notifyListeners();

    try {
      await _authRepository.logout();
      _currentUser = null;
      _availableCompanies = [];
      _clearError();
    } catch (e) {
      print('Erro durante logout: $e');
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  /// Buscar empresas disponíveis
  Future<bool> loadAvailableCompanies() async {
    if (!isLoggedIn) {
      _setError('Usuário não está logado');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await _authRepository.getAvailableCompanies();

      if (result.isSuccess && result.data != null) {
        _availableCompanies = result.data!;
        notifyListeners();
        return true;
      } else {
        _setError(result.error ?? 'Falha ao obter empresas');
        return false;
      }
    } catch (e) {
      _setError('Erro ao buscar empresas: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Selecionar empresa
  Future<bool> selectCompany(UserCompany company) async {
    if (!isLoggedIn) {
      _setError('Usuário não está logado');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await _authRepository.selectCompany(company);

      if (result.isSuccess && result.data != null) {
        _currentUser = result.data!;
        notifyListeners();
        return true;
      } else {
        _setError(result.error ?? 'Falha ao selecionar empresa');
        return false;
      }
    } catch (e) {
      _setError('Erro ao selecionar empresa: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Atualizar perfil do usuário
  Future<bool> updateProfile({String? name, String? email}) async {
    if (!isLoggedIn) {
      _setError('Usuário não está logado');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await _authRepository.updateUserProfile(
        name: name,
        email: email,
      );

      if (result.isSuccess && result.data != null) {
        _currentUser = result.data!;
        notifyListeners();
        return true;
      } else {
        _setError(result.error ?? 'Falha ao atualizar perfil');
        return false;
      }
    } catch (e) {
      _setError('Erro ao atualizar perfil: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verificar se precisa renovar token
  Future<void> checkTokenRefresh() async {
    if (isLoggedIn) {
      try {
        await _authRepository.checkTokenRefresh();
        // Recarregar usuário se token foi renovado
        _currentUser = _authRepository.currentUser;
        notifyListeners();
      } catch (e) {
        // Se falhar, fazer logout
        await logout();
      }
    }
  }

  /// Obter último username usado
  Future<String?> getLastUsername() async {
    try {
      return await _authRepository.getLastUsername();
    } catch (e) {
      return null;
    }
  }

  /// Verificar permissão específica
  bool hasPermission(String permission) {
    return _currentUser?.hasPermission(permission) ?? false;
  }

  /// Verificar se pode acessar inventário
  bool get canAccessInventory => _currentUser?.canAccessInventory ?? false;

  /// Verificar se pode modificar inventário
  bool get canModifyInventory => _currentUser?.canModifyInventory ?? false;

  /// Verificar se pode sincronizar dados
  bool get canSyncData => _currentUser?.canSyncData ?? false;

  /// Limpar erro
  void clearError() {
    _clearError();
    notifyListeners();
  }

  /// Resetar estado para configuração inicial
  Future<void> resetToInitialSetup() async {
    await logout();
    _serverUrl = null;
    _isServerConfigured = false;
    _availableCompanies = [];
    _clearError();
    notifyListeners();
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Debug: Obter informações do estado atual
  Map<String, dynamic> getDebugInfo() {
    return {
      'isLoggedIn': isLoggedIn,
      'isLoading': isLoading,
      'hasError': hasError,
      'error': error,
      'isServerConfigured': isServerConfigured,
      'serverUrl': serverUrl,
      'userName': userName,
      'userEmail': userEmail,
      'hasSelectedCompany': hasSelectedCompany,
      'selectedCompanyName': selectedCompany?.name,
      'availableCompaniesCount': availableCompanies.length,
      'isLoggingIn': isLoggingIn,
      'isLoggingOut': isLoggingOut,
      'canAccessInventory': canAccessInventory,
      'canModifyInventory': canModifyInventory,
      'canSyncData': canSyncData,
    };
  }
}
