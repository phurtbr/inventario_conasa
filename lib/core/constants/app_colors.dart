/// Constantes de strings do aplicativo Inventário Conasa
/// Centralizadas para facilitar manutenção e futuras traduções
class AppStrings {
  // Informações do aplicativo
  static const String appName = 'Inventário Conasa';
  static const String appVersion = '1.0.0';
  static const String companyName = 'Conasa Infraestrutura';
  static const String appDescription = 'Gestão de Inventário Empresarial';

  // URLs e configurações
  static const String defaultServerUrl = 'http://protheus.conasa.com:8890/rest';
  static const String tokenEndpoint = '/api/oauth2/v1/token';
  static const String branchesEndpoint = '/api/tsi/v1/TSIBranches';
  static const String companiesEndpoint = '/api/framework/v1/companies';

  // Endpoints customizados para inventário
  static const String inventoryHeaderEndpoint =
      '/cstInventarioHeader'; // API Z75
  static const String inventoryItemsEndpoint = '/cstInventarioItems'; // API Z76
  static const String productsEndpoint = '/cstProduto'; // API SB1
  static const String centersEndpoint = '/cstCentroCusto'; // API CTT
  static const String locationsEndpoint = '/cstLocalizacao'; // API NNR
  static const String stockEndpoint = '/cstEstoque'; // API SB2

  // Textos de autenticação
  static const String welcome = 'Bem-vindo ao';
  static const String loginTitle = 'Fazer Login';
  static const String loginSubtitle =
      'Entre com suas credenciais para acessar o sistema';
  static const String username = 'Usuário';
  static const String password = 'Senha';
  static const String login = 'Entrar';
  static const String logout = 'Sair';
  static const String forgotPassword = 'Esqueci minha senha';
  static const String serverConfig = 'Configurar Servidor';
  static const String serverUrl = 'URL do Servidor';
  static const String testConnection = 'Testar Conexão';
  static const String connectionSuccess = 'Conexão estabelecida com sucesso!';
  static const String connectionError = 'Erro ao conectar com o servidor';

  // Seleção de empresa
  static const String selectCompany = 'Selecionar Empresa';
  static const String selectBranch = 'Selecionar Filial';
  static const String company = 'Empresa';
  static const String branch = 'Filial';
  static const String confirm = 'Confirmar';
  static const String loading = 'Carregando...';

  // Navegação
  static const String inventories = 'Inventários';
  static const String counting = 'Contagem';
  static const String items = 'Itens';
  static const String settings = 'Configurações';
  static const String scanner = 'Scanner';
  static const String camera = 'Câmera';
  static const String gallery = 'Galeria';
  static const String photos = 'Fotos';

  // Lista de inventários
  static const String inventoryList = 'Lista de Inventários';
  static const String availableInventories = 'Inventários Disponíveis';
  static const String noInventories = 'Nenhum inventário disponível';
  static const String refreshList = 'Atualizar Lista';
  static const String searchInventories = 'Buscar inventários...';
  static const String filterByStatus = 'Filtrar por Status';
  static const String allStatus = 'Todos os Status';

  // Status de inventário
  static const String statusOpen = 'Aberto';
  static const String statusCounting = 'Contagem';
  static const String statusClosed = 'Encerrado';
  static const String statusReviewed = 'Revisado';
  static const String statusApproved = 'Aprovado';
  static const String statusTransferred = 'Transferido';
  static const String statusExecuted = 'Executado';

  // Detalhes do inventário
  static const String inventoryCode = 'Código do Lote';
  static const String creationDate = 'Data de Criação';
  static const String warehouse = 'Armazém';
  static const String responsible = 'Responsável';
  static const String currentStatus = 'Status Atual';
  static const String countingProgress = 'Progresso da Contagem';
  static const String startCounting = 'Iniciar Contagem';
  static const String continueCounting = 'Continuar Contagem';
  static const String finishCounting = 'Finalizar Contagem';
  static const String reviewItems = 'Revisar Itens';

  // Processo de contagem
  static const String productCode = 'Código do Produto';
  static const String productDescription = 'Descrição do Produto';
  static const String productGroup = 'Grupo do Produto';
  static const String unitOfMeasure = 'Unidade de Medida';
  static const String location = 'Localização';
  static const String quantity = 'Quantidade';
  static const String tagControl = 'Controle TAG';
  static const String tagRequired = 'TAG Obrigatória';
  static const String tagDamaged = 'TAG Danificada';
  static const String tagCode = 'Código da TAG';
  static const String scanProduct = 'Escanear Produto';
  static const String manualEntry = 'Entrada Manual';
  static const String productNotFound = 'Produto não encontrado';
  static const String addToInventory = 'Adicionar ao Inventário';
  static const String saveItem = 'Salvar Item';
  static const String editItem = 'Editar Item';
  static const String deleteItem = 'Excluir Item';

  // Scanner
  static const String scanBarcode = 'Escanear Código de Barras';
  static const String scanQRCode = 'Escanear QR Code';
  static const String scanTAG = 'Escanear TAG';
  static const String holdSteady = 'Mantenha o código centralizado';
  static const String scanSuccess = 'Código escaneado com sucesso!';
  static const String scanError = 'Erro ao escanear código';
  static const String enableCamera = 'Habilitar Câmera';
  static const String cameraPermission = 'Permissão de câmera necessária';
  static const String flashOn = 'Flash Ligado';
  static const String flashOff = 'Flash Desligado';

  // Fotos
  static const String takePhoto = 'Tirar Foto';
  static const String selectPhoto = 'Selecionar Foto';
  static const String photoRequired = 'Foto Obrigatória';
  static const String photoOptional = 'Foto Opcional';
  static const String addPhoto = 'Adicionar Foto';
  static const String removePhoto = 'Remover Foto';
  static const String viewPhoto = 'Visualizar Foto';
  static const String photoSaved = 'Foto salva com sucesso';
  static const String photoError = 'Erro ao processar foto';

  // Lista de itens
  static const String inventoriedItems = 'Itens Inventariados';
  static const String totalItems = 'Total de Itens';
  static const String itemsCount = 'itens';
  static const String searchItems = 'Buscar itens...';
  static const String filterItems = 'Filtrar Itens';
  static const String sortBy = 'Ordenar por';
  static const String sortByCode = 'Código';
  static const String sortByDescription = 'Descrição';
  static const String sortByDate = 'Data';
  static const String sortByQuantity = 'Quantidade';

  // Sincronização
  static const String sync = 'Sincronizar';
  static const String syncData = 'Sincronizar Dados';
  static const String syncPending = 'Pendente';
  static const String syncInProgress = 'Sincronizando...';
  static const String syncSuccess = 'Sincronizado';
  static const String syncError = 'Erro na Sincronização';
  static const String lastSync = 'Última Sincronização';
  static const String autoSync = 'Sincronização Automática';
  static const String syncNow = 'Sincronizar Agora';
  static const String downloadData = 'Baixar Dados';
  static const String uploadData = 'Enviar Dados';
  static const String syncComplete = 'Sincronização concluída';
  static const String syncFailed = 'Falha na sincronização';

  // Configurações
  static const String generalSettings = 'Configurações Gerais';
  static const String userInfo = 'Informações do Usuário';
  static const String serverSettings = 'Configurações do Servidor';
  static const String appSettings = 'Configurações do App';
  static const String about = 'Sobre';
  static const String version = 'Versão';
  static const String clearCache = 'Limpar Cache';
  static const String exportData = 'Exportar Dados';
  static const String importData = 'Importar Dados';

  // Mensagens de erro
  static const String error = 'Erro';
  static const String warning = 'Aviso';
  static const String info = 'Informação';
  static const String success = 'Sucesso';
  static const String genericError = 'Ocorreu um erro inesperado';
  static const String networkError = 'Erro de conexão com a internet';
  static const String serverError = 'Erro no servidor';
  static const String authError = 'Erro de autenticação';
  static const String invalidCredentials = 'Credenciais inválidas';
  static const String sessionExpired = 'Sessão expirada';
  static const String permissionDenied = 'Permissão negada';
  static const String fileNotFound = 'Arquivo não encontrado';
  static const String insufficientStorage = 'Espaço insuficiente';

  // Validações
  static const String fieldRequired = 'Este campo é obrigatório';
  static const String invalidFormat = 'Formato inválido';
  static const String invalidQuantity = 'Quantidade inválida';
  static const String quantityRequired = 'Quantidade é obrigatória';
  static const String quantityPositive = 'Quantidade deve ser positiva';
  static const String codeRequired = 'Código é obrigatório';

  // Ações
  static const String save = 'Salvar';
  static const String cancel = 'Cancelar';
  static const String edit = 'Editar';
  static const String delete = 'Excluir';
  static const String add = 'Adicionar';
  static const String remove = 'Remover';
  static const String update = 'Atualizar';
  static const String refresh = 'Atualizar';
  static const String search = 'Buscar';
  static const String filter = 'Filtrar';
  static const String clear = 'Limpar';
  static const String select = 'Selecionar';
  static const String back = 'Voltar';
  static const String next = 'Próximo';
  static const String finish = 'Finalizar';
  static const String close = 'Fechar';
  static const String open = 'Abrir';
  static const String view = 'Visualizar';
  static const String send = 'Enviar';

  // Confirmações
  static const String confirmAction = 'Confirmar Ação';
  static const String confirmDelete = 'Confirmar Exclusão';
  static const String confirmLogout = 'Confirmar Saída';
  static const String deleteItemConfirm = 'Deseja realmente excluir este item?';
  static const String logoutConfirm = 'Deseja realmente sair do aplicativo?';
  static const String discardChanges = 'Descartar alterações?';
  static const String unsavedChanges = 'Há alterações não salvas';

  // Status de conectividade
  static const String online = 'Online';
  static const String offline = 'Offline';
  static const String connecting = 'Conectando...';
  static const String connected = 'Conectado';
  static const String disconnected = 'Desconectado';
  static const String noInternet = 'Sem conexão com a internet';
  static const String checkConnection = 'Verifique sua conexão';

  // Formato de datas
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // Datas relativas
  static const String today = 'Hoje';
  static const String yesterday = 'Ontem';
  static const String thisWeek = 'Esta semana';
  static const String lastWeek = 'Semana passada';
  static const String thisMonth = 'Este mês';
  static const String lastMonth = 'Mês passado';

  // Unidades
  static const String unit = 'UN';
  static const String kilogram = 'KG';
  static const String meter = 'M';
  static const String liter = 'L';
  static const String piece = 'PC';

  // Padrões de nomenclatura de fotos
  static const String photoPrefix = 'INV';
  static const String photoSeparator = '_';
  static const String photoExtension = '.jpg';
}
