import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper para gerenciamento de preferências locais usando SharedPreferences
/// Armazena configurações e dados de sessão do usuário
class PreferencesHelper {
  // Chaves das preferências
  static const String _keyServerUrl = 'server_url';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyLastUsername = 'last_username';
  static const String _keySelectedCompany = 'selected_company';
  static const String _keyAppTheme = 'app_theme';
  static const String _keyAutoSync = 'auto_sync';
  static const String _keySyncInterval = 'sync_interval';
  static const String _keyLastSyncAt = 'last_sync_at';
  static const String _keyPhotoQuality = 'photo_quality';
  static const String _keyAutoCompressPhotos = 'auto_compress_photos';
  static const String _keyOfflineMode = 'offline_mode';
  static const String _keyShowOnboarding = 'show_onboarding';
  static const String _keyAppVersion = 'app_version';
  static const String _keyFirstRun = 'first_run';

  /// Obter instância do SharedPreferences
  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // ===== CONFIGURAÇÕES DE SERVIDOR =====

  /// Salvar URL do servidor
  static Future<void> setServerUrl(String url) async {
    final prefs = await _prefs;
    await prefs.setString(_keyServerUrl, url);
  }

  /// Obter URL do servidor
  static Future<String?> getServerUrl() async {
    final prefs = await _prefs;
    return prefs.getString(_keyServerUrl);
  }

  /// Remover URL do servidor
  static Future<void> clearServerUrl() async {
    final prefs = await _prefs;
    await prefs.remove(_keyServerUrl);
  }

  // ===== DADOS DE AUTENTICAÇÃO =====

  /// Definir se está logado
  static Future<void> setIsLoggedIn(bool isLoggedIn) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
  }

  /// Verificar se está logado
  static Future<bool> isLoggedIn() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Salvar último username usado
  static Future<void> setLastUsername(String username) async {
    final prefs = await _prefs;
    await prefs.setString(_keyLastUsername, username);
  }

  /// Obter último username usado
  static Future<String?> getLastUsername() async {
    final prefs = await _prefs;
    return prefs.getString(_keyLastUsername);
  }

  /// Salvar empresa selecionada
  static Future<void> setSelectedCompany(Map<String, dynamic> company) async {
    final prefs = await _prefs;
    await prefs.setString(_keySelectedCompany, jsonEncode(company));
  }

  /// Obter empresa selecionada
  static Future<Map<String, dynamic>?> getSelectedCompany() async {
    final prefs = await _prefs;
    final companyJson = prefs.getString(_keySelectedCompany);
    if (companyJson != null) {
      return jsonDecode(companyJson);
    }
    return null;
  }

  /// Limpar dados do usuário
  static Future<void> clearUserData() async {
    final prefs = await _prefs;
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyLastUsername);
    await prefs.remove(_keySelectedCompany);
  }

  // ===== CONFIGURAÇÕES DO APP =====

  /// Salvar tema do app
  static Future<void> setAppTheme(String theme) async {
    final prefs = await _prefs;
    await prefs.setString(_keyAppTheme, theme);
  }

  /// Obter tema do app
  static Future<String> getAppTheme() async {
    final prefs = await _prefs;
    return prefs.getString(_keyAppTheme) ?? 'light';
  }

  /// Definir se primeira execução
  static Future<void> setFirstRun(bool isFirstRun) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyFirstRun, isFirstRun);
  }

  /// Verificar se é primeira execução
  static Future<bool> isFirstRun() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyFirstRun) ?? true;
  }

  /// Definir se mostrar onboarding
  static Future<void> setShowOnboarding(bool show) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyShowOnboarding, show);
  }

  /// Verificar se deve mostrar onboarding
  static Future<bool> shouldShowOnboarding() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyShowOnboarding) ?? true;
  }

  /// Salvar versão do app
  static Future<void> setAppVersion(String version) async {
    final prefs = await _prefs;
    await prefs.setString(_keyAppVersion, version);
  }

  /// Obter versão do app
  static Future<String?> getAppVersion() async {
    final prefs = await _prefs;
    return prefs.getString(_keyAppVersion);
  }

  // ===== CONFIGURAÇÕES DE SINCRONIZAÇÃO =====

  /// Habilitar/desabilitar sincronização automática
  static Future<void> setAutoSync(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyAutoSync, enabled);
  }

  /// Verificar se sincronização automática está habilitada
  static Future<bool> isAutoSyncEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyAutoSync) ?? true;
  }

  /// Definir intervalo de sincronização (em minutos)
  static Future<void> setSyncInterval(int minutes) async {
    final prefs = await _prefs;
    await prefs.setInt(_keySyncInterval, minutes);
  }

  /// Obter intervalo de sincronização
  static Future<int> getSyncInterval() async {
    final prefs = await _prefs;
    return prefs.getInt(_keySyncInterval) ?? 30; // Padrão: 30 minutos
  }

  /// Salvar timestamp da última sincronização
  static Future<void> setLastSyncAt(DateTime dateTime) async {
    final prefs = await _prefs;
    await prefs.setString(_keyLastSyncAt, dateTime.toIso8601String());
  }

  /// Obter timestamp da última sincronização
  static Future<DateTime?> getLastSyncAt() async {
    final prefs = await _prefs;
    final timestampString = prefs.getString(_keyLastSyncAt);
    if (timestampString != null) {
      return DateTime.parse(timestampString);
    }
    return null;
  }

  /// Definir modo offline
  static Future<void> setOfflineMode(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyOfflineMode, enabled);
  }

  /// Verificar se modo offline está ativado
  static Future<bool> isOfflineModeEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyOfflineMode) ?? false;
  }

  // ===== CONFIGURAÇÕES DE FOTOS =====

  /// Definir qualidade das fotos (0-100)
  static Future<void> setPhotoQuality(int quality) async {
    final prefs = await _prefs;
    final clampedQuality = quality.clamp(0, 100);
    await prefs.setInt(_keyPhotoQuality, clampedQuality);
  }

  /// Obter qualidade das fotos
  static Future<int> getPhotoQuality() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyPhotoQuality) ?? 85; // Padrão: 85%
  }

  /// Habilitar/desabilitar compressão automática de fotos
  static Future<void> setAutoCompressPhotos(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyAutoCompressPhotos, enabled);
  }

  /// Verificar se compressão automática está habilitada
  static Future<bool> isAutoCompressPhotosEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyAutoCompressPhotos) ?? true;
  }

  // ===== MÉTODOS UTILITÁRIOS =====

  /// Obter todas as configurações
  static Future<Map<String, dynamic>> getAllSettings() async {
    final prefs = await _prefs;
    return {
      'serverUrl': prefs.getString(_keyServerUrl),
      'isLoggedIn': prefs.getBool(_keyIsLoggedIn) ?? false,
      'lastUsername': prefs.getString(_keyLastUsername),
      'selectedCompany': prefs.getString(_keySelectedCompany),
      'appTheme': prefs.getString(_keyAppTheme) ?? 'light',
      'autoSync': prefs.getBool(_keyAutoSync) ?? true,
      'syncInterval': prefs.getInt(_keySyncInterval) ?? 30,
      'lastSyncAt': prefs.getString(_keyLastSyncAt),
      'photoQuality': prefs.getInt(_keyPhotoQuality) ?? 85,
      'autoCompressPhotos': prefs.getBool(_keyAutoCompressPhotos) ?? true,
      'offlineMode': prefs.getBool(_keyOfflineMode) ?? false,
      'showOnboarding': prefs.getBool(_keyShowOnboarding) ?? true,
      'appVersion': prefs.getString(_keyAppVersion),
      'firstRun': prefs.getBool(_keyFirstRun) ?? true,
    };
  }

  /// Resetar todas as configurações
  static Future<void> resetAllSettings() async {
    final prefs = await _prefs;
    await prefs.clear();
  }

  /// Resetar apenas configurações do usuário (manter configurações do app)
  static Future<void> resetUserSettings() async {
    final prefs = await _prefs;
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyLastUsername);
    await prefs.remove(_keySelectedCompany);
    await prefs.remove(_keyLastSyncAt);
  }

  /// Backup das configurações em JSON
  static Future<String> exportSettings() async {
    final settings = await getAllSettings();
    return jsonEncode(settings);
  }

  /// Restaurar configurações de JSON
  static Future<bool> importSettings(String jsonString) async {
    try {
      final settings = jsonDecode(jsonString) as Map<String, dynamic>;
      final prefs = await _prefs;

      // Aplicar cada configuração
      for (final entry in settings.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value == null) continue;

        if (value is String) {
          await prefs.setString(_getPreferenceKey(key), value);
        } else if (value is bool) {
          await prefs.setBool(_getPreferenceKey(key), value);
        } else if (value is int) {
          await prefs.setInt(_getPreferenceKey(key), value);
        } else if (value is double) {
          await prefs.setDouble(_getPreferenceKey(key), value);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mapear nomes de configurações para chaves
  static String _getPreferenceKey(String settingName) {
    switch (settingName) {
      case 'serverUrl':
        return _keyServerUrl;
      case 'isLoggedIn':
        return _keyIsLoggedIn;
      case 'lastUsername':
        return _keyLastUsername;
      case 'selectedCompany':
        return _keySelectedCompany;
      case 'appTheme':
        return _keyAppTheme;
      case 'autoSync':
        return _keyAutoSync;
      case 'syncInterval':
        return _keySyncInterval;
      case 'lastSyncAt':
        return _keyLastSyncAt;
      case 'photoQuality':
        return _keyPhotoQuality;
      case 'autoCompressPhotos':
        return _keyAutoCompressPhotos;
      case 'offlineMode':
        return _keyOfflineMode;
      case 'showOnboarding':
        return _keyShowOnboarding;
      case 'appVersion':
        return _keyAppVersion;
      case 'firstRun':
        return _keyFirstRun;
      default:
        return settingName;
    }
  }

  /// Verificar se é uma nova instalação ou atualização
  static Future<AppUpdateStatus> checkAppUpdateStatus(
    String currentVersion,
  ) async {
    final savedVersion = await getAppVersion();

    if (savedVersion == null) {
      await setAppVersion(currentVersion);
      return AppUpdateStatus.firstInstall;
    }

    if (savedVersion != currentVersion) {
      await setAppVersion(currentVersion);
      return AppUpdateStatus.updated;
    }

    return AppUpdateStatus.same;
  }

  /// Configurações padrão para primeira instalação
  static Future<void> setDefaultSettings() async {
    await setFirstRun(false);
    await setShowOnboarding(true);
    await setAutoSync(true);
    await setSyncInterval(30);
    await setPhotoQuality(85);
    await setAutoCompressPhotos(true);
    await setOfflineMode(false);
    await setAppTheme('light');
  }

  /// Validar configurações críticas
  static Future<ValidationResult> validateSettings() async {
    final issues = <String>[];

    // Verificar URL do servidor
    final serverUrl = await getServerUrl();
    if (serverUrl == null || serverUrl.isEmpty) {
      issues.add('URL do servidor não configurada');
    }

    // Verificar qualidade da foto
    final photoQuality = await getPhotoQuality();
    if (photoQuality < 10 || photoQuality > 100) {
      issues.add('Qualidade de foto inválida: $photoQuality');
      await setPhotoQuality(85); // Corrigir automaticamente
    }

    // Verificar intervalo de sincronização
    final syncInterval = await getSyncInterval();
    if (syncInterval < 5) {
      issues.add(
        'Intervalo de sincronização muito baixo: $syncInterval minutos',
      );
      await setSyncInterval(30); // Corrigir automaticamente
    }

    return ValidationResult(isValid: issues.isEmpty, issues: issues);
  }
}

/// Status de atualização do app
enum AppUpdateStatus { firstInstall, updated, same }

/// Resultado de validação de configurações
class ValidationResult {
  final bool isValid;
  final List<String> issues;

  const ValidationResult({required this.isValid, required this.issues});

  bool get hasIssues => issues.isNotEmpty;

  @override
  String toString() {
    return isValid
        ? 'ValidationResult: Valid'
        : 'ValidationResult: ${issues.length} issues - ${issues.join(", ")}';
  }
}
