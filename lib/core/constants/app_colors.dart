import 'package:flutter/material.dart';

/// Constantes de cores do aplicativo Inventário Conasa
/// Baseado na identidade visual da Conasa Infraestrutura
class AppColors {
  // Cores primárias da Conasa
  static const Color conaprimary = Color(0xFF1E5BA8); // Azul Conasa principal
  static const Color primary = Color(0xFF1E5BA8); // Azul Conasa principal
  static const Color conasecondary = Color(0xFF4A90E2); // Azul secundário
  static const Color secondary = Color(0xFF4A90E2); // Azul secundário
  static const Color primaryLight = Color(0xFF4A90E2); // Azul secundário

  // Cores neutras
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFFE0E0E0);
  static const Color darkGray = Color(0xFF757575);
  static const Color charcoal = Color(0xFF424242);

  //Faltantes
  static const Color inputBorder = Color.fromARGB(255, 255, 0, 0);
  static const Color accent = Color.fromARGB(255, 255, 0, 0);
  static const Color primaryDark = Color(0xFF424242);

  // Cores de status
  static const Color success = Color(0xFF28A745); // Verde sucesso
  static const Color error = Color(0xDC3545); // Vermelho erro
  static const Color warning = Color(0xFFFFC107); // Amarelo aviso
  static const Color info = Color(0xFF17A2B8); // Azul informação

  // Cores de estado de inventário
  static const Color statusOpen = Color(0xFF28A745); // Aberto - Verde
  static const Color statusCounting = Color(0xFF4A90E2); // Contagem - Azul
  static const Color statusClosed = Color(0xFFF39C12); // Encerrado - Laranja
  static const Color statusReviewed = Color(0xFF9B59B6); // Revisado - Roxo
  static const Color statusApproved = Color(
    0xFF27AE60,
  ); // Aprovado - Verde escuro
  static const Color statusTransferred = Color(
    0xFF34495E,
  ); // Transferido - Cinza escuro
  static const Color statusExecuted = Color(
    0xFF2ECC71,
  ); // Executado - Verde claro

  // Cores de sincronização
  static const Color syncPending = Color(0xFFF39C12); // Pendente - Laranja
  static const Color syncInProgress = Color(0xFF3498DB); // Em progresso - Azul
  static const Color syncSuccess = Color(0xFF27AE60); // Sincronizado - Verde
  static const Color syncError = Color(0xFFE74C3C); // Erro - Vermelho

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [conaprimary, conasecondary],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightGray, white],
  );

  // Cores de fundo
  static const Color scaffoldBackground = Color(0xFFFAFAFA);
  static const Color cardBackground = white;
  static const Color inputBackground = lightGray;

  // Cores de texto
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = white;
  static const Color textHint = Color(0xFF9E9E9E);

  // Cores de borda
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFBDBDBD);
  static const Color borderDark = Color(0xFF757575);

  // Cores de sombra
  static const Color shadowLight = Color(0x1F000000);
  static const Color shadowMedium = Color(0x3F000000);

  // Cores específicas para scanner
  static const Color scannerOverlay = Color(
    0x80000000,
  ); // Preto com 50% transparência
  static const Color scannerFrame = white;
  static const Color scannerSuccess = success;
  static const Color scannerError = error;

  // Cores para elementos de navegação
  static const Color navSelected = conaprimary;
  static const Color navUnselected = darkGray;
  static const Color navBackground = white;

  // Métodos utilitários para obter cores por status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aberto':
      case 'open':
        return statusOpen;
      case 'contagem':
      case 'counting':
        return statusCounting;
      case 'encerrado':
      case 'closed':
        return statusClosed;
      case 'revisado':
      case 'reviewed':
        return statusReviewed;
      case 'aprovado':
      case 'approved':
        return statusApproved;
      case 'transferido':
      case 'transferred':
        return statusTransferred;
      case 'executado':
      case 'executed':
        return statusExecuted;
      default:
        return mediumGray;
    }
  }

  static Color getSyncStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'pendente':
        return syncPending;
      case 'syncing':
      case 'sincronizando':
        return syncInProgress;
      case 'synced':
      case 'sincronizado':
        return syncSuccess;
      case 'error':
      case 'erro':
        return syncError;
      default:
        return mediumGray;
    }
  }
}
