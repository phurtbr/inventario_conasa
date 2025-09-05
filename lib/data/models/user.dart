import 'dart:convert';

/// Modelo de dados para usuário do sistema
/// Baseado na autenticação OAuth2 do Protheus
class User {
  final String id;
  final String username;
  final String name;
  final String email;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? tokenExpiry;
  final List<String> permissions;
  final UserCompany? selectedCompany;
  final List<UserCompany> availableCompanies;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiry,
    this.permissions = const [],
    this.selectedCompany,
    this.availableCompanies = const [],
    this.isActive = true,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria uma instância a partir de JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      tokenExpiry: json['expires_in'] != null
          ? DateTime.now().add(Duration(seconds: json['expires_in']))
          : null,
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : [],
      selectedCompany: json['selected_company'] != null
          ? UserCompany.fromJson(json['selected_company'])
          : null,
      availableCompanies: json['available_companies'] != null
          ? (json['available_companies'] as List)
                .map((company) => UserCompany.fromJson(company))
                .toList()
          : [],
      isActive: json['is_active'] ?? true,
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': tokenExpiry?.difference(DateTime.now()).inSeconds,
      'permissions': permissions,
      'selected_company': selectedCompany?.toJson(),
      'available_companies': availableCompanies.map((c) => c.toJson()).toList(),
      'is_active': isActive,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Converte para JSON do banco local
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_expiry': tokenExpiry?.toIso8601String(),
      'permissions': jsonEncode(permissions),
      'selected_company': selectedCompany != null
          ? jsonEncode(selectedCompany!.toJson())
          : null,
      'available_companies': jsonEncode(
        availableCompanies.map((c) => c.toJson()).toList(),
      ),
      'is_active': isActive ? 1 : 0,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Cria uma instância a partir do JSON do banco local
  factory User.fromLocalJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      tokenExpiry: json['token_expiry'] != null
          ? DateTime.parse(json['token_expiry'])
          : null,
      permissions: json['permissions'] != null
          ? List<String>.from(jsonDecode(json['permissions']))
          : [],
      selectedCompany: json['selected_company'] != null
          ? UserCompany.fromJson(jsonDecode(json['selected_company']))
          : null,
      availableCompanies: json['available_companies'] != null
          ? (jsonDecode(json['available_companies']) as List)
                .map((company) => UserCompany.fromJson(company))
                .toList()
          : [],
      isActive: json['is_active'] == 1,
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  /// Cria cópia com modificações
  User copyWith({
    String? id,
    String? username,
    String? name,
    String? email,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiry,
    List<String>? permissions,
    UserCompany? selectedCompany,
    List<UserCompany>? availableCompanies,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
      permissions: permissions ?? this.permissions,
      selectedCompany: selectedCompany ?? this.selectedCompany,
      availableCompanies: availableCompanies ?? this.availableCompanies,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verifica se o token está válido
  bool get isTokenValid {
    if (accessToken == null || tokenExpiry == null) return false;
    return DateTime.now().isBefore(tokenExpiry!);
  }

  /// Verifica se precisa renovar o token (faltam 5 minutos para expirar)
  bool get needsTokenRefresh {
    if (tokenExpiry == null) return false;
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return fiveMinutesFromNow.isAfter(tokenExpiry!);
  }

  /// Verifica se tem permissão específica
  bool hasPermission(String permission) {
    return permissions.contains(permission) || permissions.contains('*');
  }

  /// Verifica se tem acesso a inventário
  bool get canAccessInventory {
    return hasPermission('inventory.read') || hasPermission('inventory.*');
  }

  /// Verifica se pode modificar inventário
  bool get canModifyInventory {
    return hasPermission('inventory.write') || hasPermission('inventory.*');
  }

  /// Verifica se pode sincronizar dados
  bool get canSyncData {
    return hasPermission('sync.execute') || hasPermission('sync.*');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id && other.username == username;
  }

  @override
  int get hashCode => Object.hash(id, username);

  @override
  String toString() {
    return 'User(id: $id, username: $username, name: $name, company: ${selectedCompany?.name})';
  }
}

/// Modelo para empresa/filial do usuário
class UserCompany {
  final String code;
  final String branchCode;
  final String name;
  final String description;
  final bool isActive;

  const UserCompany({
    required this.code,
    required this.branchCode,
    required this.name,
    required this.description,
    this.isActive = true,
  });

  /// Cria uma instância a partir de JSON
  factory UserCompany.fromJson(Map<String, dynamic> json) {
    return UserCompany(
      code: json['code'] ?? json['empresa'] ?? '',
      branchCode: json['branchCode'] ?? json['filial'] ?? '',
      name: json['name'] ?? json['nome'] ?? '',
      description: json['description'] ?? json['descricao'] ?? '',
      isActive: json['isActive'] ?? json['ativo'] ?? true,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'branchCode': branchCode,
      'name': name,
      'description': description,
      'isActive': isActive,
    };
  }

  /// Cria cópia com modificações
  UserCompany copyWith({
    String? code,
    String? branchCode,
    String? name,
    String? description,
    bool? isActive,
  }) {
    return UserCompany(
      code: code ?? this.code,
      branchCode: branchCode ?? this.branchCode,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Retorna o identificador completo (empresa|filial)
  String get fullCode => '$code|$branchCode';

  /// Retorna o nome completo para exibição
  String get displayName => '$name - $description';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserCompany &&
        other.code == code &&
        other.branchCode == branchCode;
  }

  @override
  int get hashCode => Object.hash(code, branchCode);

  @override
  String toString() {
    return 'UserCompany(code: $code, branchCode: $branchCode, name: $name)';
  }
}
