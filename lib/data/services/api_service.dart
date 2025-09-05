import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/app_strings.dart';
import '../models/user.dart';

/// Serviço para comunicação com APIs REST do Protheus
/// Gerencia autenticação OAuth2 e requisições HTTP
class ApiService {
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();

  ApiService._();

  String? _baseUrl;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  // Headers padrão
  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  // Timeout das requisições
  static const Duration _timeout = Duration(seconds: 30);

  /// Configurar URL base do servidor
  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }

  /// Obter URL base configurada
  String? get baseUrl => _baseUrl;

  /// Configurar tokens de autenticação
  void setAuthTokens(
    String accessToken,
    String refreshToken,
    DateTime? expiry,
  ) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _tokenExpiry = expiry;
  }

  /// Limpar tokens de autenticação
  void clearAuthTokens() {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
  }

  /// Verificar se está autenticado
  bool get isAuthenticated => _accessToken != null && isTokenValid;

  /// Verificar se o token está válido
  bool get isTokenValid {
    if (_tokenExpiry == null) return false;
    return DateTime.now().isBefore(_tokenExpiry!);
  }

  /// Verificar se precisa renovar o token
  bool get needsTokenRefresh {
    if (_tokenExpiry == null) return false;
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return fiveMinutesFromNow.isAfter(_tokenExpiry!);
  }

  /// Fazer login OAuth2
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String username,
    required String password,
  }) async {
    try {
      if (_baseUrl == null) {
        return ApiResponse.error('URL do servidor não configurada');
      }

      final url = '$_baseUrl${AppStrings.tokenEndpoint}?grant_type=password';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              ..._defaultHeaders,
              'username': username,
              'password': password,
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Configurar tokens
        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;
        final expiresIn = data['expires_in'] as int?;

        if (accessToken != null && refreshToken != null) {
          final expiry = expiresIn != null
              ? DateTime.now().add(Duration(seconds: expiresIn))
              : DateTime.now().add(const Duration(hours: 1));

          setAuthTokens(accessToken, refreshToken, expiry);
        }

        return ApiResponse.success(data);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(
          errorData['message'] ?? 'Erro de autenticação',
        );
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão com o servidor');
    } on http.ClientException {
      return ApiResponse.error('Erro na requisição HTTP');
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e');
    }
  }

  /// Renovar token usando refresh token
  Future<ApiResponse<Map<String, dynamic>>> refreshToken() async {
    try {
      if (_baseUrl == null || _refreshToken == null) {
        return ApiResponse.error('Configuração ou refresh token inválido');
      }

      final url =
          '$_baseUrl${AppStrings.tokenEndpoint}?grant_type=refresh_token&refresh_token=$_refreshToken';

      final response = await http
          .post(Uri.parse(url), headers: _defaultHeaders)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Atualizar tokens
        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;
        final expiresIn = data['expires_in'] as int?;

        if (accessToken != null && refreshToken != null) {
          final expiry = expiresIn != null
              ? DateTime.now().add(Duration(seconds: expiresIn))
              : DateTime.now().add(const Duration(hours: 1));

          setAuthTokens(accessToken, refreshToken, expiry);
        }

        return ApiResponse.success(data);
      } else {
        clearAuthTokens();
        return ApiResponse.error('Falha ao renovar token');
      }
    } catch (e) {
      clearAuthTokens();
      return ApiResponse.error('Erro ao renovar token: $e');
    }
  }

  /// Fazer requisição GET
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    return _makeRequest<T>(
      'GET',
      endpoint,
      queryParams: queryParams,
      requiresAuth: requiresAuth,
    );
  }

  /// Fazer requisição POST
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    return _makeRequest<T>(
      'POST',
      endpoint,
      body: body,
      queryParams: queryParams,
      requiresAuth: requiresAuth,
    );
  }

  /// Fazer requisição PUT
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    return _makeRequest<T>(
      'PUT',
      endpoint,
      body: body,
      queryParams: queryParams,
      requiresAuth: requiresAuth,
    );
  }

  /// Fazer requisição DELETE
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    return _makeRequest<T>(
      'DELETE',
      endpoint,
      queryParams: queryParams,
      requiresAuth: requiresAuth,
    );
  }

  /// Upload de arquivo
  Future<ApiResponse<Map<String, dynamic>>> uploadFile(
    String endpoint,
    File file, {
    Map<String, String>? fields,
    String fieldName = 'file',
  }) async {
    try {
      if (!await _ensureAuthenticated()) {
        return ApiResponse.error('Falha na autenticação');
      }

      final url = '$_baseUrl$endpoint';
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Adicionar headers de autenticação
      request.headers.addAll(_getAuthHeaders());

      // Adicionar arquivo
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, file.path),
      );

      // Adicionar campos adicionais
      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(errorData['message'] ?? 'Erro no upload');
      }
    } catch (e) {
      return ApiResponse.error('Erro no upload: $e');
    }
  }

  /// Fazer requisição HTTP genérica
  Future<ApiResponse<T>> _makeRequest<T>(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      if (_baseUrl == null) {
        return ApiResponse.error('URL do servidor não configurada');
      }

      if (requiresAuth && !await _ensureAuthenticated()) {
        return ApiResponse.error('Falha na autenticação');
      }

      // Construir URL
      String url = '$_baseUrl$endpoint';
      if (queryParams != null && queryParams.isNotEmpty) {
        final query = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url += '?$query';
      }

      // Preparar headers
      final headers = Map<String, String>.from(_defaultHeaders);
      if (requiresAuth) {
        headers.addAll(_getAuthHeaders());
      }

      // Fazer requisição
      late http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(Uri.parse(url), headers: headers)
              .timeout(_timeout);
          break;
        case 'POST':
          response = await http
              .post(
                Uri.parse(url),
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await http
              .put(
                Uri.parse(url),
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_timeout);
          break;
        case 'DELETE':
          response = await http
              .delete(Uri.parse(url), headers: headers)
              .timeout(_timeout);
          break;
        default:
          return ApiResponse.error('Método HTTP não suportado: $method');
      }

      // Processar resposta
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return ApiResponse.success(null as T);
        }

        final data = jsonDecode(response.body);
        return ApiResponse.success(data as T);
      } else {
        final errorData = _parseErrorResponse(response);
        return ApiResponse.error(errorData['message'] ?? 'Erro na requisição');
      }
    } on SocketException {
      return ApiResponse.error('Erro de conexão com o servidor');
    } catch (e) {
      return ApiResponse.error('Erro inesperado: $e');
    }
  }

  /// Garantir que está autenticado
  Future<bool> _ensureAuthenticated() async {
    if (!isAuthenticated) {
      return false;
    }

    if (needsTokenRefresh) {
      final refreshResult = await refreshToken();
      return refreshResult.isSuccess;
    }

    return true;
  }

  /// Obter headers de autenticação
  Map<String, String> _getAuthHeaders() {
    if (_accessToken == null) return {};

    return {'Authorization': 'Bearer $_accessToken'};
  }

  /// Processar resposta de erro
  Map<String, dynamic> _parseErrorResponse(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'message': 'Erro HTTP ${response.statusCode}',
        'statusCode': response.statusCode,
      };
    }
  }

  /// Testar conectividade com o servidor
  Future<ApiResponse<bool>> testConnection() async {
    try {
      if (_baseUrl == null) {
        return ApiResponse.error('URL do servidor não configurada');
      }

      // Tentar fazer uma requisição simples
      final response = await http
          .get(Uri.parse('$_baseUrl/health'), headers: _defaultHeaders)
          .timeout(const Duration(seconds: 10));

      return ApiResponse.success(response.statusCode < 400);
    } on SocketException {
      return ApiResponse.error('Servidor inacessível');
    } catch (e) {
      return ApiResponse.error('Erro de conexão: $e');
    }
  }
}

/// Classe para resposta padronizada da API
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final int? statusCode;

  const ApiResponse._({
    required this.isSuccess,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse._(isSuccess: true, data: data);
  }

  factory ApiResponse.error(String error, [int? statusCode]) {
    return ApiResponse._(
      isSuccess: false,
      error: error,
      statusCode: statusCode,
    );
  }

  bool get isError => !isSuccess;

  @override
  String toString() {
    return isSuccess
        ? 'ApiResponse.success($data)'
        : 'ApiResponse.error($error)';
  }
}
