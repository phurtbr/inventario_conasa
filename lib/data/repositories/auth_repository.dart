import '../../core/constants/app_strings.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../local/preferences_helper.dart';

/// Repository para gerenciamento de autenticação
/// Coordena login, logout e gerenciamento de sessão do usuário
class AuthRepository {
  static AuthRepository? _instance;
  static AuthRepository get instance => _instance ??= AuthRepository._();

  AuthRepository._();

  final ApiService _apiService = ApiService.instance;
  final DatabaseService _dbService = DatabaseService.instance;

  User? _currentUser;

  /// Usuário atual logado
  User? get currentUser => _currentUser;

  /// Verificar se está logado
  bool get isLoggedIn => _currentUser != null && _currentUser!.isTokenValid;

  /// Configurar URL do servidor
  Future<void> setServerUrl(String url) async {
    _apiService.setBaseUrl(url);
    await PreferencesHelper.setServerUrl(url);
  }

  /// Obter URL do servidor configurada
  Future<String?> getServerUrl() async {
    return await PreferencesHelper.getServerUrl();
  }

  /// Fazer login
  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    try {
      // Verificar se URL do servidor está configurada
      final serverUrl = await getServerUrl();
      if (serverUrl == null || serverUrl.isEmpty) {
        return AuthResult.error('URL do servidor não configurada');
      }

      // Fazer login via API
      final response = await _apiService.login(
        username: username,
        password: password,
      );

      if (response.isSuccess && response.data != null) {
        final loginData = response.data!;

        // Criar usuário a partir dos dados de login
        final user = User(
          id: username, // Usar username como ID por enquanto
          username: username,
          name: username, // Será atualizado quando implementarmos perfil
          email: '', // Será atualizado quando implementarmos perfil
          accessToken: loginData['access_token'],
          refreshToken: loginData['refresh_token'],
          tokenExpiry: loginData['expires_in'] != null
              ? DateTime.now().add(Duration(seconds: loginData['expires_in']))
              : null,
          permissions: [], // Será implementado conforme necessidade
          lastLogin: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Salvar usuário no banco local
        await _dbService.saveUser(user);

        // Configurar tokens na API
        _apiService.setAuthTokens(
          user.accessToken!,
          user.refreshToken!,
          user.tokenExpiry,
        );

        // Definir como usuário atual
        _currentUser = user;

        // Salvar dados de login nas preferências
        await PreferencesHelper.setLastUsername(username);
        await PreferencesHelper.setIsLoggedIn(true);

        return AuthResult.success(user);
      } else {
        return AuthResult.error(response.error ?? 'Falha no login');
      }
    } catch (e) {
      return AuthResult.error('Erro durante o login: $e');
    }
  }

  /// Fazer logout
  Future<void> logout() async {
    try {
      // Limpar tokens da API
      _apiService.clearAuthTokens();

      // Limpar usuário atual
      if (_currentUser != null) {
        await _dbService.deleteUser(_currentUser!.id);
        _currentUser = null;
      }

      // Limpar preferências
      await PreferencesHelper.setIsLoggedIn(false);
      await PreferencesHelper.clearUserData();
    } catch (e) {
      print('Erro durante logout: $e');
    }
  }

  /// Tentar login automático (restore session)
  Future<AuthResult> autoLogin() async {
    try {
      // Verificar se estava logado
      final wasLoggedIn = await PreferencesHelper.isLoggedIn();
      if (!wasLoggedIn) {
        return AuthResult.error('Usuário não estava logado');
      }

      // Buscar usuário salvo no banco
      final savedUser = await _dbService.getLoggedUser();
      if (savedUser == null) {
        return AuthResult.error('Dados do usuário não encontrados');
      }

      // Verificar se token ainda é válido
      if (!savedUser.isTokenValid) {
        // Tentar renovar token
        if (savedUser.refreshToken != null) {
          _apiService.setAuthTokens(
            savedUser.accessToken!,
            savedUser.refreshToken!,
            savedUser.tokenExpiry,
          );

          final refreshResult = await _apiService.refreshToken();
          if (refreshResult.isSuccess && refreshResult.data != null) {
            final refreshData = refreshResult.data!;

            // Atualizar usuário com novos tokens
            final updatedUser = savedUser.copyWith(
              accessToken: refreshData['access_token'],
              refreshToken: refreshData['refresh_token'],
              tokenExpiry: refreshData['expires_in'] != null
                  ? DateTime.now().add(
                      Duration(seconds: refreshData['expires_in']),
                    )
                  : null,
              updatedAt: DateTime.now(),
            );

            await _dbService.saveUser(updatedUser);
            _currentUser = updatedUser;

            return AuthResult.success(updatedUser);
          } else {
            // Token refresh falhou, fazer logout
            await logout();
            return AuthResult.error('Sessão expirada, faça login novamente');
          }
        } else {
          // Sem refresh token, fazer logout
          await logout();
          return AuthResult.error('Sessão expirada, faça login novamente');
        }
      } else {
        // Token ainda válido
        _apiService.setAuthTokens(
          savedUser.accessToken!,
          savedUser.refreshToken!,
          savedUser.tokenExpiry,
        );

        _currentUser = savedUser;
        return AuthResult.success(savedUser);
      }
    } catch (e) {
      await logout();
      return AuthResult.error('Erro ao restaurar sessão: $e');
    }
  }

  /// Obter empresas/filiais disponíveis
  Future<AuthResult<List<UserCompany>>> getAvailableCompanies() async {
    try {
      if (!isLoggedIn) {
        return AuthResult.error('Usuário não está logado');
      }

      // Buscar filiais via API
      final response = await _apiService.get<Map<String, dynamic>>(
        AppStrings.branchesEndpoint,
        queryParams: {
          'companyId': 'T1|D MG 01', // Formato exemplo da documentação
        },
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final branchesData = data['branches'] as List?;

        if (branchesData != null) {
          final companies = branchesData
              .map((item) => UserCompany.fromJson(item))
              .toList();

          return AuthResult.success(companies);
        }
      }

      return AuthResult.error('Falha ao obter empresas');
    } catch (e) {
      return AuthResult.error('Erro ao buscar empresas: $e');
    }
  }

  /// Selecionar empresa/filial
  Future<AuthResult> selectCompany(UserCompany company) async {
    try {
      if (!isLoggedIn || _currentUser == null) {
        return AuthResult.error('Usuário não está logado');
      }

      // Atualizar usuário com empresa selecionada
      final updatedUser = _currentUser!.copyWith(
        selectedCompany: company,
        updatedAt: DateTime.now(),
      );

      // Salvar no banco
      await _dbService.saveUser(updatedUser);

      // Atualizar usuário atual
      _currentUser = updatedUser;

      // Salvar empresa selecionada nas preferências
      await PreferencesHelper.setSelectedCompany(company.toJson());

      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.error('Erro ao selecionar empresa: $e');
    }
  }

  /// Verificar se precisa renovar token
  Future<void> checkTokenRefresh() async {
    if (_currentUser != null && _currentUser!.needsTokenRefresh) {
      await _refreshCurrentUserToken();
    }
  }

  /// Renovar token do usuário atual
  Future<void> _refreshCurrentUserToken() async {
    if (_currentUser == null) return;

    final refreshResult = await _apiService.refreshToken();
    if (refreshResult.isSuccess && refreshResult.data != null) {
      final refreshData = refreshResult.data!;

      final updatedUser = _currentUser!.copyWith(
        accessToken: refreshData['access_token'],
        refreshToken: refreshData['refresh_token'],
        tokenExpiry: refreshData['expires_in'] != null
            ? DateTime.now().add(Duration(seconds: refreshData['expires_in']))
            : null,
        updatedAt: DateTime.now(),
      );

      await _dbService.saveUser(updatedUser);
      _currentUser = updatedUser;
    } else {
      // Falha ao renovar, fazer logout
      await logout();
    }
  }

  /// Obter último username usado
  Future<String?> getLastUsername() async {
    return await PreferencesHelper.getLastUsername();
  }

  /// Verificar conectividade com servidor
  Future<bool> testServerConnection() async {
    final result = await _apiService.testConnection();
    return result.isSuccess;
  }

  /// Atualizar perfil do usuário
  Future<AuthResult> updateUserProfile({String? name, String? email}) async {
    try {
      if (!isLoggedIn || _currentUser == null) {
        return AuthResult.error('Usuário não está logado');
      }

      final updatedUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        email: email ?? _currentUser!.email,
        updatedAt: DateTime.now(),
      );

      await _dbService.saveUser(updatedUser);
      _currentUser = updatedUser;

      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.error('Erro ao atualizar perfil: $e');
    }
  }
}

/// Resultado de operações de autenticação
class AuthResult<T> {
  final bool isSuccess;
  final T? data;
  final String? error;

  const AuthResult._({required this.isSuccess, this.data, this.error});

  factory AuthResult.success(T data) {
    return AuthResult._(isSuccess: true, data: data);
  }

  factory AuthResult.error(String error) {
    return AuthResult._(isSuccess: false, error: error);
  }

  bool get isError => !isSuccess;

  @override
  String toString() {
    return isSuccess ? 'AuthResult.success($data)' : 'AuthResult.error($error)';
  }
}
