class AppStrings {
  // Informações do aplicativo
  static const String appName = 'Inventário Conasa';
  static const String companyName = 'Conasa Infraestrutura';
  static const String appTagline = 'Gestão inteligente de inventário';

  // URLs e Endpoints API
  static const String baseUrl = 'http://protheus.conasa.com:8890/rest';
  static const String authEndpoint = '/auth';
  static const String inventoryHeaderEndpoint = '/Z75';
  static const String inventoryItemsEndpoint = '/Z76';
  static const String productsEndpoint = '/cstProduto';
  static const String inventoryEndpoint = '/cstInventario';
  static const String companiesEndpoint = '/companies';

  // Endpoints de sincronização
  static const String syncProductsEndpoint = '/SB1';
  static const String syncLocationsEndpoint = '/NNR';
  static const String syncStockEndpoint = '/SB2';
  static const String syncCostCentersEndpoint = '/CTT';

  // Textos de interface - Navegação
  static const String home = 'Início';
  static const String inventories = 'Inventários';
  static const String counting = 'Contagem';
  static const String sync = 'Sincronização';
  static const String settings = 'Configurações';

  // Textos de interface - Ações
  static const String login = 'Entrar';
  static const String logout = 'Sair';
  static const String save = 'Salvar';
  static const String cancel = 'Cancelar';
  static const String confirm = 'Confirmar';
  static const String delete = 'Excluir';
  static const String edit = 'Editar';
  static const String create = 'Criar';
  static const String search = 'Buscar';
  static const String filter = 'Filtrar';
  static const String refresh = 'Atualizar';
  static const String loading = 'Carregando...';
  static const String retry = 'Tentar novamente';
  static const String dismiss = 'Dispensar';
  static const String tryAgain = 'Tentar Novamente';

  // Textos de interface - Estados
  static const String empty = 'Vazio';
  static const String noData = 'Nenhum dado encontrado';
  static const String noResults = 'Nenhum resultado encontrado';
  static const String completed = 'Concluído';
  static const String pending = 'Pendente';
  static const String inProgress = 'Em andamento';
  static const String synchronized = 'Sincronizado';
  static const String notSynchronized = 'Não sincronizado';

  // Autenticação
  static const String username = 'Usuário';
  static const String password = 'Senha';
  static const String company = 'Empresa';
  static const String selectCompany = 'Selecionar Empresa';
  static const String loginError = 'Erro ao fazer login';
  static const String invalidCredentials = 'Credenciais inválidas';
  static const String sessionExpired = 'Sessão expirada';
  static const String welcomeBack = 'Bem-vindo de volta';

  // Inventários
  static const String newInventory = 'Novo Inventário';
  static const String inventoryName = 'Nome do Inventário';
  static const String inventoryDescription = 'Descrição';
  static const String inventoryLocation = 'Local';
  static const String inventoryDate = 'Data';
  static const String responsible = 'Responsável';
  static const String totalItems = 'Total de Itens';
  static const String countedItems = 'Itens Contados';
  static const String pendingItems = 'Itens Pendentes';
  static const String viewInventories = 'Ver Inventários';
  static const String selectInventory = 'Selecionar Inventário';
  static const String selectInventoryToCount =
      'Selecione um inventário para contar';

  // Contagem
  static const String scanProduct = 'Escanear Produto';
  static const String productCode = 'Código do Produto';
  static const String productDescription = 'Descrição do Produto';
  static const String quantity = 'Quantidade';
  static const String location = 'Localização';
  static const String notes = 'Observações';
  static const String capturePhoto = 'Capturar Foto';
  static const String countedQuantity = 'Quantidade Contada';
  static const String systemQuantity = 'Quantidade do Sistema';
  static const String difference = 'Diferença';

  // Sincronização
  static const String syncing = 'Sincronizando...';
  static const String syncComplete = 'Sincronização concluída';
  static const String syncError = 'Erro na sincronização';
  static const String lastSync = 'Última sincronização';
  static const String autoSync = 'Sincronização automática';
  static const String manualSync = 'Sincronização manual';
  static const String syncNow = 'Sincronizar agora';
  static const String syncingFullData = 'Sincronizando dados completos';
  static const String syncingIncrementalData = 'Sincronizando alterações';
  static const String syncingPhotos = 'Sincronizando fotos';
  static const String syncingMasterData = 'Sincronizando dados mestre';

  // Conectividade
  static const String noInternetConnection = 'Sem conexão com a internet';
  static const String connectionRestored = 'Conexão restaurada';
  static const String wifiOnlyModeEnabled = 'Modo apenas Wi-Fi ativo';
  static const String batteryLowSyncPaused =
      'Sincronização pausada - bateria baixa';
  static const String cannotSyncRightNow = 'Não é possível sincronizar agora';
  static const String excellentConnection = 'Excelente';
  static const String goodConnection = 'Boa';
  static const String fairConnection = 'Regular';
  static const String poorConnection = 'Ruim';
  static const String noConnection = 'Sem conexão';
  static const String allApisAvailable = 'Todas as APIs disponíveis';
  static const String allApisUnavailable = 'Todas as APIs indisponíveis';

  // Configurações
  static const String userProfile = 'Perfil do Usuário';
  static const String appPreferences = 'Preferências do App';
  static const String theme = 'Tema';
  static const String language = 'Idioma';
  static const String notifications = 'Notificações';
  static const String about = 'Sobre';
  static const String version = 'Versão';

  // Validações
  static const String fieldRequired = 'Campo obrigatório';
  static const String invalidEmail = 'E-mail inválido';
  static const String invalidCPF = 'CPF inválido';
  static const String invalidCNPJ = 'CNPJ inválido';
  static const String invalidProductCode = 'Código de produto inválido';
  static const String invalidQuantity = 'Quantidade inválida';
  static const String invalidDate = 'Data inválida';
  static const String productNotFound = 'Produto não encontrado';
  static const String negativeQuantityNotAllowed =
      'Quantidade negativa não permitida';
  static const String tooManyDecimals = 'Muitas casas decimais';
  static const String locationRequired = 'Localização obrigatória';

  // Mensagens de erro
  static const String errorGeneric = 'Ocorreu um erro inesperado';
  static const String errorNetwork = 'Erro de conexão';
  static const String errorTimeout = 'Tempo limite excedido';
  static const String errorServer = 'Erro interno do servidor';
  static const String errorNotFound = 'Recurso não encontrado';
  static const String errorUnauthorized = 'Não autorizado';
  static const String errorForbidden = 'Acesso negado';
  static const String errorLoadingData = 'Erro ao carregar dados';
  static const String errorSavingData = 'Erro ao salvar dados';
  static const String errorDeletingData = 'Erro ao excluir dados';
  static const String errorLoadingInventories = 'Erro ao carregar inventários';
  static const String errorSavingInventory = 'Erro ao salvar inventário';
  static const String errorProcessingProduct = 'Erro ao processar produto';
  static const String errorCapturingPhoto = 'Erro ao capturar foto';
  static const String errorSavingItem = 'Erro ao salvar item';
  static const String apiEndpointUnavailable = 'Endpoint da API indisponível';
  static const String initializationError = 'Erro na inicialização';
  static const String unknownError = 'Erro desconhecido';

  // Mensagens de sucesso
  static const String successSave = 'Salvo com sucesso';
  static const String successDelete = 'Excluído com sucesso';
  static const String successSync = 'Sincronizado com sucesso';
  static const String successLogin = 'Login realizado com sucesso';
  static const String successLogout = 'Logout realizado com sucesso';

  // Títulos de tela
  static const String homeTitle = 'Início';
  static const String inventoriesTitle = 'Inventários';
  static const String countingTitle = 'Contagem';
  static const String syncTitle = 'Sincronização';
  static const String settingsTitle = 'Configurações';
  static const String loginTitle = 'Login';
  static const String createInventoryTitle = 'Criar Inventário';
  static const String inventoryDetailsTitle = 'Detalhes do Inventário';
  static const String productDetailsTitle = 'Detalhes do Produto';
  static const String scannerTitle = 'Scanner';

  // Formatação e unidades
  static const String itemsCount = 'itens';
  static const String percentageFormat = '%';
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Paginação
  static const String loadMore = 'Carregar mais';
  static const String showingResults = 'Mostrando resultados';
  static const String of = 'de';
  static const String page = 'Página';

  // Filtros e ordenação
  static const String filterBy = 'Filtrar por';
  static const String sortBy = 'Ordenar por';
  static const String ascending = 'Crescente';
  static const String descending = 'Decrescente';
  static const String all = 'Todos';
  static const String name = 'Nome';
  static const String date = 'Data';
  static const String status = 'Status';
  static const String progress = 'Progresso';

  // Ações específicas
  static const String startCounting = 'Iniciar Contagem';
  static const String pauseCounting = 'Pausar Contagem';
  static const String resumeCounting = 'Retomar Contagem';
  static const String finishCounting = 'Finalizar Contagem';
  static const String reviewItems = 'Revisar Itens';
  static const String exportData = 'Exportar Dados';
  static const String importData = 'Importar Dados';

  // Status específicos
  static const String draft = 'Rascunho';
  static const String active = 'Ativo';
  static const String paused = 'Pausado';
  static const String finished = 'Finalizado';
  static const String archived = 'Arquivado';

  // Mensagens informativas
  static const String noInventoriesMessage =
      'Nenhum inventário encontrado. Crie seu primeiro inventário para começar.';
  static const String noItemsMessage =
      'Nenhum item encontrado neste inventário.';
  static const String noProductsMessage = 'Nenhum produto encontrado.';
  static const String inventoryCompletedMessage =
      'Inventário concluído com sucesso!';
  static const String syncRequiredMessage =
      'É necessário sincronizar antes de continuar.';
  static const String offlineModeMessage =
      'Modo offline ativo. Dados serão sincronizados quando a conexão for restaurada.';

  // Confirmações
  static const String confirmDelete = 'Tem certeza que deseja excluir?';
  static const String confirmDeleteInventory =
      'Tem certeza que deseja excluir este inventário?';
  static const String confirmDeleteItem =
      'Tem certeza que deseja excluir este item?';
  static const String confirmLogout = 'Tem certeza que deseja sair?';
  static const String confirmFinishInventory =
      'Tem certeza que deseja finalizar este inventário?';
  static const String confirmCancelCounting =
      'Tem certeza que deseja cancelar a contagem?';
  static const String confirmSync = 'Tem certeza que deseja sincronizar agora?';

  // Dicas e instruções
  static const String tipScanBarcode =
      'Aponte a câmera para o código de barras';
  static const String tipEnterManually = 'Ou digite o código manualmente';
  static const String tipTapToEdit = 'Toque para editar';
  static const String tipSwipeToDelete = 'Deslize para excluir';
  static const String tipPullToRefresh = 'Puxe para atualizar';
  static const String instructionSelectInventory =
      'Selecione um inventário para começar a contagem';
  static const String instructionScanProduct =
      'Escaneie ou digite o código do produto';
  static const String instructionEnterQuantity = 'Digite a quantidade contada';
  static const String instructionConfirmLocation =
      'Confirme a localização do produto';

  // Estatísticas
  static const String totalInventories = 'Total de Inventários';
  static const String completedInventories = 'Inventários Concluídos';
  static const String pendingInventories = 'Inventários Pendentes';
  static const String synchronizedInventories = 'Inventários Sincronizados';
  static const String totalProducts = 'Total de Produtos';
  static const String scannedToday = 'Escaneados Hoje';
  static const String averageTime = 'Tempo Médio';
  static const String productivity = 'Produtividade';

  // Unidades e medidas
  static const String unitPiece = 'UN';
  static const String unitKilogram = 'KG';
  static const String unitMeter = 'M';
  static const String unitLiter = 'L';
  static const String unitBox = 'CX';
  static const String unitPackage = 'PCT';

  // Controles de camera e scanner
  static const String cameraPermissionRequired =
      'Permissão de câmera necessária';
  static const String cameraPermissionDenied = 'Permissão de câmera negada';
  static const String flashOn = 'Flash ligado';
  static const String flashOff = 'Flash desligado';
  static const String switchCamera = 'Alternar câmera';
  static const String focusTap = 'Toque para focar';

  // Configurações de contagem
  static const String countingSettings = 'Configurações de Contagem';
  static const String requirePhotoConfirmation = 'Exigir confirmação de foto';
  static const String allowNegativeQuantity = 'Permitir quantidade negativa';
  static const String requireLocationConfirmation =
      'Exigir confirmação de localização';
  static const String autoAdvanceOnScan = 'Avançar automaticamente ao escanear';
  static const String vibrationEnabled = 'Vibração habilitada';
  static const String soundEnabled = 'Som habilitado';

  // Configurações de sincronização
  static const String syncSettings = 'Configurações de Sincronização';
  static const String autoSyncEnabled = 'Sincronização automática';
  static const String wifiOnlySync = 'Sincronizar apenas via Wi-Fi';
  static const String syncPhotos = 'Sincronizar fotos';
  static const String syncMasterData = 'Sincronizar dados mestre';
  static const String syncInterval = 'Intervalo de sincronização';
  static const String maxRetryAttempts = 'Máximo de tentativas';
  static const String pauseOnBatteryLow = 'Pausar com bateria baixa';

  // Intervalos de tempo
  static const String every15Minutes = 'A cada 15 minutos';
  static const String every30Minutes = 'A cada 30 minutos';
  static const String every1Hour = 'A cada 1 hora';
  static const String every2Hours = 'A cada 2 horas';
  static const String every4Hours = 'A cada 4 horas';
  static const String manually = 'Manualmente';

  // Estados da bateria
  static const String batteryLow = 'Bateria baixa';
  static const String batteryCharging = 'Carregando';
  static const String powerSaveMode = 'Modo economia de energia';

  // Qualidade de rede
  static const String networkExcellent = 'Excelente';
  static const String networkGood = 'Boa';
  static const String networkFair = 'Regular';
  static const String networkPoor = 'Ruim';
  static const String networkNone = 'Sem rede';

  // Tipos de sincronização
  static const String fullSync = 'Sincronização completa';
  static const String incrementalSync = 'Sincronização incremental';
  static const String photoSync = 'Sincronização de fotos';
  static const String masterDataSync = 'Sincronização de dados mestre';

  // Estados de sincronização
  static const String syncIdle = 'Parado';
  static const String syncInProgress = 'Em progresso';
  static const String syncPaused = 'Pausado';
  static const String syncCompleted = 'Concluído';

  // Operações de sincronização
  static const String uploadingData = 'Enviando dados';
  static const String downloadingData = 'Baixando dados';
  static const String processingData = 'Processando dados';
  static const String validatingData = 'Validando dados';

  // Modos de contagem
  static const String scannerMode = 'Modo Scanner';
  static const String manualMode = 'Modo Manual';
  static const String guidedMode = 'Modo Guiado';

  // Etapas de contagem
  static const String productScan = 'Escanear Produto';
  static const String quantityInput = 'Inserir Quantidade';
  static const String locationInput = 'Inserir Localização';
  static const String photoCapture = 'Capturar Foto';
  static const String confirmation = 'Confirmação';

  // Navegação e direções
  static const String next = 'Próximo';
  static const String previous = 'Anterior';
  static const String skip = 'Pular';
  static const String finish = 'Finalizar';
  static const String goBack = 'Voltar';
  static const String goHome = 'Ir para o Início';

  // Permissões
  static const String permissionRequired = 'Permissão necessária';
  static const String cameraPermission = 'Permissão de câmera';
  static const String storagePermission = 'Permissão de armazenamento';
  static const String locationPermission = 'Permissão de localização';
  static const String permissionExplanation =
      'Esta permissão é necessária para o funcionamento do aplicativo';
  static const String openSettings = 'Abrir Configurações';

  // Acessibilidade
  static const String accessibilityHint = 'Dica de acessibilidade';
  static const String accessibilityLabel = 'Rótulo de acessibilidade';
  static const String accessibilityButton = 'Botão';
  static const String accessibilityImage = 'Imagem';
  static const String accessibilityInput = 'Campo de entrada';

  // Formatação de dados
  static const String kilobytes = 'KB';
  static const String megabytes = 'MB';
  static const String gigabytes = 'GB';
  static const String seconds = 'segundos';
  static const String minutes = 'minutos';
  static const String hours = 'horas';
  static const String days = 'dias';

  // Mensagens de debug (apenas para desenvolvimento)
  static const String debugMode = 'Modo Debug';
  static const String debugInfo = 'Informações de Debug';
  static const String debugLogs = 'Logs de Debug';
  static const String clearLogs = 'Limpar Logs';

  // Empresa específica
  static const String conasaInfraestrutura = 'Conasa Infraestrutura';
  static const String conasaLogo = 'Logo Conasa';
  static const String conasaColors = 'Cores Conasa';

  // Campos específicos do negócio
  static const String costCenter = 'Centro de Custo';
  static const String warehouse = 'Armazém';
  static const String shelf = 'Prateleira';
  static const String bin = 'Endereço';
  static const String serialNumber = 'Número de Série';
  static const String lotNumber = 'Número do Lote';
  static const String expirationDate = 'Data de Validade';
  static const String unitCost = 'Custo Unitário';
  static const String totalCost = 'Custo Total';

  // Relatórios
  static const String reports = 'Relatórios';
  static const String generateReport = 'Gerar Relatório';
  static const String reportGenerated = 'Relatório gerado';
  static const String reportError = 'Erro ao gerar relatório';
  static const String inventoryReport = 'Relatório de Inventário';
  static const String varianceReport = 'Relatório de Variações';
  static const String summaryReport = 'Relatório Resumo';

  // Exportação
  static const String export = 'Exportar';
  static const String exportToExcel = 'Exportar para Excel';
  static const String exportToPdf = 'Exportar para PDF';
  static const String exportToEmail = 'Exportar por E-mail';
  static const String exportCompleted = 'Exportação concluída';
  static const String exportError = 'Erro na exportação';

  // Importação
  static const String import = 'Importar';
  static const String importFromFile = 'Importar de arquivo';
  static const String importCompleted = 'Importação concluída';
  static const String importError = 'Erro na importação';
  static const String selectFile = 'Selecionar arquivo';

  // Backup e restore
  static const String backup = 'Backup';
  static const String restore = 'Restaurar';
  static const String backupCreated = 'Backup criado';
  static const String backupError = 'Erro no backup';
  static const String restoreCompleted = 'Restauração concluída';
  static const String restoreError = 'Erro na restauração';
}
