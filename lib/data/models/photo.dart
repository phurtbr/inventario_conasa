import 'dart:convert';
import 'dart:io';

/// Modelo de dados para fotos/anexos do inventário
/// Gerencia fotos capturadas durante a contagem
class Photo {
  final String id;
  final String inventoryBatchId;
  final String inventoryItemId;
  final String productCode;
  final String fileName;
  final String localPath;
  final String? serverPath;
  final String? url;
  final int fileSize;
  final String mimeType;
  final PhotoType type;
  final int width;
  final int height;
  final double? latitude;
  final double? longitude;
  final String capturedBy;
  final DateTime capturedAt;
  final String? description;
  final bool isCompressed;
  final int? originalFileSize;
  final PhotoStatus status;
  final SyncStatus syncStatus;
  final DateTime? lastSyncAt;
  final String? syncError;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Photo({
    required this.id,
    required this.inventoryBatchId,
    required this.inventoryItemId,
    required this.productCode,
    required this.fileName,
    required this.localPath,
    this.serverPath,
    this.url,
    this.fileSize = 0,
    this.mimeType = 'image/jpeg',
    this.type = PhotoType.product,
    this.width = 0,
    this.height = 0,
    this.latitude,
    this.longitude,
    required this.capturedBy,
    required this.capturedAt,
    this.description,
    this.isCompressed = false,
    this.originalFileSize,
    this.status = PhotoStatus.captured,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncAt,
    this.syncError,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria uma instância a partir de JSON
  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id']?.toString() ?? '',
      inventoryBatchId: json['lote_id'] ?? json['inventory_batch_id'] ?? '',
      inventoryItemId: json['item_id'] ?? json['inventory_item_id'] ?? '',
      productCode: json['codigo_produto'] ?? json['product_code'] ?? '',
      fileName: json['nome_arquivo'] ?? json['file_name'] ?? '',
      localPath: json['caminho_local'] ?? json['local_path'] ?? '',
      serverPath: json['caminho_servidor'] ?? json['server_path'],
      url: json['url'],
      fileSize: json['tamanho_arquivo'] ?? json['file_size'] ?? 0,
      mimeType: json['tipo_mime'] ?? json['mime_type'] ?? 'image/jpeg',
      type: PhotoType.fromString(json['tipo'] ?? json['type'] ?? 'produto'),
      width: json['largura'] ?? json['width'] ?? 0,
      height: json['altura'] ?? json['height'] ?? 0,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      capturedBy: json['capturado_por'] ?? json['captured_by'] ?? '',
      capturedAt: json['data_captura'] != null
          ? DateTime.parse(json['data_captura'])
          : json['captured_at'] != null
          ? DateTime.parse(json['captured_at'])
          : DateTime.now(),
      description: json['descricao'] ?? json['description'],
      isCompressed: json['comprimida'] ?? json['is_compressed'] ?? false,
      originalFileSize: json['tamanho_original'] ?? json['original_file_size'],
      status: PhotoStatus.fromString(json['status'] ?? 'capturada'),
      syncStatus: SyncStatus.fromString(json['sync_status'] ?? 'pending'),
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'])
          : null,
      syncError: json['erro_sync'] ?? json['sync_error'],
      metadata: json['metadata'] ?? {},
      createdAt: json['data_criacao'] != null
          ? DateTime.parse(json['data_criacao'])
          : json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['data_atualizacao'] != null
          ? DateTime.parse(json['data_atualizacao'])
          : json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lote_id': inventoryBatchId,
      'item_id': inventoryItemId,
      'codigo_produto': productCode,
      'nome_arquivo': fileName,
      'caminho_local': localPath,
      'caminho_servidor': serverPath,
      'url': url,
      'tamanho_arquivo': fileSize,
      'tipo_mime': mimeType,
      'tipo': type.value,
      'largura': width,
      'altura': height,
      'latitude': latitude,
      'longitude': longitude,
      'capturado_por': capturedBy,
      'data_captura': capturedAt.toIso8601String(),
      'descricao': description,
      'comprimida': isCompressed,
      'tamanho_original': originalFileSize,
      'status': status.value,
      'sync_status': syncStatus.value,
      'last_sync_at': lastSyncAt?.toIso8601String(),
      'erro_sync': syncError,
      'metadata': metadata,
      'data_criacao': createdAt.toIso8601String(),
      'data_atualizacao': updatedAt.toIso8601String(),
    };
  }

  /// Converte para JSON do banco local
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'inventory_batch_id': inventoryBatchId,
      'inventory_item_id': inventoryItemId,
      'product_code': productCode,
      'file_name': fileName,
      'local_path': localPath,
      'server_path': serverPath,
      'url': url,
      'file_size': fileSize,
      'mime_type': mimeType,
      'type': type.value,
      'width': width,
      'height': height,
      'latitude': latitude,
      'longitude': longitude,
      'captured_by': capturedBy,
      'captured_at': capturedAt.toIso8601String(),
      'description': description,
      'is_compressed': isCompressed ? 1 : 0,
      'original_file_size': originalFileSize,
      'status': status.value,
      'sync_status': syncStatus.value,
      'last_sync_at': lastSyncAt?.toIso8601String(),
      'sync_error': syncError,
      'metadata': jsonEncode(metadata),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Cria uma instância a partir do JSON do banco local
  factory Photo.fromLocalJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id']?.toString() ?? '',
      inventoryBatchId: json['inventory_batch_id'] ?? '',
      inventoryItemId: json['inventory_item_id'] ?? '',
      productCode: json['product_code'] ?? '',
      fileName: json['file_name'] ?? '',
      localPath: json['local_path'] ?? '',
      serverPath: json['server_path'],
      url: json['url'],
      fileSize: json['file_size'] ?? 0,
      mimeType: json['mime_type'] ?? 'image/jpeg',
      type: PhotoType.fromString(json['type'] ?? 'produto'),
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      capturedBy: json['captured_by'] ?? '',
      capturedAt: json['captured_at'] != null
          ? DateTime.parse(json['captured_at'])
          : DateTime.now(),
      description: json['description'],
      isCompressed: json['is_compressed'] == 1,
      originalFileSize: json['original_file_size'],
      status: PhotoStatus.fromString(json['status'] ?? 'capturada'),
      syncStatus: SyncStatus.fromString(json['sync_status'] ?? 'pending'),
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'])
          : null,
      syncError: json['sync_error'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(jsonDecode(json['metadata']))
          : {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  /// Cria cópia com modificações
  Photo copyWith({
    String? id,
    String? inventoryBatchId,
    String? inventoryItemId,
    String? productCode,
    String? fileName,
    String? localPath,
    String? serverPath,
    String? url,
    int? fileSize,
    String? mimeType,
    PhotoType? type,
    int? width,
    int? height,
    double? latitude,
    double? longitude,
    String? capturedBy,
    DateTime? capturedAt,
    String? description,
    bool? isCompressed,
    int? originalFileSize,
    PhotoStatus? status,
    SyncStatus? syncStatus,
    DateTime? lastSyncAt,
    String? syncError,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Photo(
      id: id ?? this.id,
      inventoryBatchId: inventoryBatchId ?? this.inventoryBatchId,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      productCode: productCode ?? this.productCode,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      serverPath: serverPath ?? this.serverPath,
      url: url ?? this.url,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      type: type ?? this.type,
      width: width ?? this.width,
      height: height ?? this.height,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capturedBy: capturedBy ?? this.capturedBy,
      capturedAt: capturedAt ?? this.capturedAt,
      description: description ?? this.description,
      isCompressed: isCompressed ?? this.isCompressed,
      originalFileSize: originalFileSize ?? this.originalFileSize,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncError: syncError ?? this.syncError,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verifica se o arquivo existe localmente
  bool get existsLocally => File(localPath).existsSync();

  /// Retorna o tamanho do arquivo em MB
  double get fileSizeInMB => fileSize / (1024 * 1024);

  /// Verifica se a foto foi comprimida
  double? get compressionRatio {
    if (originalFileSize == null || originalFileSize == 0) return null;
    return fileSize / originalFileSize!;
  }

  /// Verifica se precisa sincronizar
  bool get needsSync => syncStatus != SyncStatus.synced;

  /// Verifica se está sincronizada
  bool get isSynced => syncStatus == SyncStatus.synced;

  /// Verifica se tem erro de sincronização
  bool get hasSyncError => syncStatus == SyncStatus.error;

  /// Verifica se tem localização GPS
  bool get hasLocation => latitude != null && longitude != null;

  /// Retorna a extensão do arquivo
  String get fileExtension {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1) return '';
    return fileName.substring(lastDot);
  }

  /// Retorna o nome base do arquivo (sem extensão)
  String get baseFileName {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1) return fileName;
    return fileName.substring(0, lastDot);
  }

  /// Gera thumbnail path
  String get thumbnailPath {
    final basePath = localPath.substring(0, localPath.lastIndexOf('/'));
    return '$basePath/thumb_$fileName';
  }

  /// Verifica se é uma imagem válida
  bool get isValidImage {
    return mimeType.startsWith('image/') && existsLocally && fileSize > 0;
  }

  /// Retorna o aspect ratio da imagem
  double get aspectRatio {
    if (height == 0) return 1.0;
    return width / height;
  }

  /// Verifica se é uma imagem em formato paisagem
  bool get isLandscape => aspectRatio > 1.0;

  /// Verifica se é uma imagem em formato retrato
  bool get isPortrait => aspectRatio < 1.0;

  /// Retorna informações resumidas para logs
  String get logInfo =>
      'Photo(id: $id, file: $fileName, size: ${fileSizeInMB.toStringAsFixed(2)}MB)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Photo && other.id == id && other.fileName == fileName;
  }

  @override
  int get hashCode => Object.hash(id, fileName);

  @override
  String toString() {
    return 'Photo(id: $id, fileName: $fileName, status: ${status.label}, sync: ${syncStatus.label})';
  }
}

/// Enum para tipo de foto
enum PhotoType {
  product('produto', 'Produto'),
  location('localizacao', 'Localização'),
  tag('tag', 'TAG'),
  damage('dano', 'Dano'),
  general('geral', 'Geral'),
  document('documento', 'Documento');

  const PhotoType(this.value, this.label);

  final String value;
  final String label;

  static PhotoType fromString(String value) {
    return PhotoType.values.firstWhere(
      (type) => type.value == value.toLowerCase(),
      orElse: () => PhotoType.product,
    );
  }
}

/// Enum para status da foto
enum PhotoStatus {
  captured('capturada', 'Capturada'),
  compressed('comprimida', 'Comprimida'),
  processing('processando', 'Processando'),
  ready('pronta', 'Pronta'),
  uploaded('enviada', 'Enviada'),
  error('erro', 'Erro'),
  deleted('excluida', 'Excluída');

  const PhotoStatus(this.value, this.label);

  final String value;
  final String label;

  static PhotoStatus fromString(String value) {
    return PhotoStatus.values.firstWhere(
      (status) => status.value == value.toLowerCase(),
      orElse: () => PhotoStatus.captured,
    );
  }
}

/// Enum para status de sincronização
enum SyncStatus {
  pending('pending', 'Pendente'),
  syncing('syncing', 'Sincronizando'),
  synced('synced', 'Sincronizado'),
  error('error', 'Erro');

  const SyncStatus(this.value, this.label);

  final String value;
  final String label;

  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (status) => status.value == value.toLowerCase(),
      orElse: () => SyncStatus.pending,
    );
  }
}
