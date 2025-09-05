import 'dart:convert';

/// Modelo de dados para lote de inventário (Cabeçalho Z75)
/// Representa um inventário criado no sistema
class InventoryBatch {
  final String id;
  final String code;
  final String description;
  final String companyCode;
  final String branchCode;
  final String warehouseCode;
  final String warehouseName;
  final String responsibleId;
  final String responsibleName;
  final InventoryStatus status;
  final InventoryType type;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime? approvedAt;
  final DateTime updatedAt;
  final int totalItems;
  final int countedItems;
  final int pendingItems;
  final double progressPercentage;
  final List<String> locations;
  final String? notes;
  final Map<String, dynamic> metadata;
  final SyncStatus syncStatus;
  final DateTime? lastSyncAt;

  const InventoryBatch({
    required this.id,
    required this.code,
    required this.description,
    required this.companyCode,
    required this.branchCode,
    required this.warehouseCode,
    required this.warehouseName,
    required this.responsibleId,
    required this.responsibleName,
    required this.status,
    this.type = InventoryType.general,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
    this.approvedAt,
    required this.updatedAt,
    this.totalItems = 0,
    this.countedItems = 0,
    this.pendingItems = 0,
    this.progressPercentage = 0.0,
    this.locations = const [],
    this.notes,
    this.metadata = const {},
    this.syncStatus = SyncStatus.pending,
    this.lastSyncAt,
  });

  /// Cria uma instância a partir de JSON da API Z75
  factory InventoryBatch.fromJson(Map<String, dynamic> json) {
    return InventoryBatch(
      id: json['id']?.toString() ?? '',
      code: json['codigo'] ?? json['code'] ?? '',
      description: json['descricao'] ?? json['description'] ?? '',
      companyCode: json['empresa'] ?? json['company_code'] ?? '',
      branchCode: json['filial'] ?? json['branch_code'] ?? '',
      warehouseCode: json['armazem'] ?? json['warehouse_code'] ?? '',
      warehouseName: json['nome_armazem'] ?? json['warehouse_name'] ?? '',
      responsibleId: json['responsavel_id'] ?? json['responsible_id'] ?? '',
      responsibleName:
          json['responsavel_nome'] ?? json['responsible_name'] ?? '',
      status: InventoryStatus.fromString(json['status'] ?? 'aberto'),
      type: InventoryType.fromString(json['tipo'] ?? json['type'] ?? 'geral'),
      createdAt: json['data_criacao'] != null
          ? DateTime.parse(json['data_criacao'])
          : DateTime.now(),
      startedAt: json['data_inicio'] != null
          ? DateTime.parse(json['data_inicio'])
          : null,
      finishedAt: json['data_fim'] != null
          ? DateTime.parse(json['data_fim'])
          : null,
      approvedAt: json['data_aprovacao'] != null
          ? DateTime.parse(json['data_aprovacao'])
          : null,
      updatedAt: json['data_atualizacao'] != null
          ? DateTime.parse(json['data_atualizacao'])
          : DateTime.now(),
      totalItems: json['total_itens'] ?? json['total_items'] ?? 0,
      countedItems: json['itens_contados'] ?? json['counted_items'] ?? 0,
      pendingItems: json['itens_pendentes'] ?? json['pending_items'] ?? 0,
      progressPercentage:
          (json['percentual_progresso'] ?? json['progress_percentage'] ?? 0.0)
              .toDouble(),
      locations: json['localizacoes'] != null
          ? List<String>.from(json['localizacoes'])
          : json['locations'] != null
          ? List<String>.from(json['locations'])
          : [],
      notes: json['observacoes'] ?? json['notes'],
      metadata: json['metadata'] ?? {},
      syncStatus: SyncStatus.fromString(json['sync_status'] ?? 'pending'),
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'])
          : null,
    );
  }

  /// Converte para JSON da API Z75
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': code,
      'descricao': description,
      'empresa': companyCode,
      'filial': branchCode,
      'armazem': warehouseCode,
      'nome_armazem': warehouseName,
      'responsavel_id': responsibleId,
      'responsavel_nome': responsibleName,
      'status': status.value,
      'tipo': type.value,
      'data_criacao': createdAt.toIso8601String(),
      'data_inicio': startedAt?.toIso8601String(),
      'data_fim': finishedAt?.toIso8601String(),
      'data_aprovacao': approvedAt?.toIso8601String(),
      'data_atualizacao': updatedAt.toIso8601String(),
      'total_itens': totalItems,
      'itens_contados': countedItems,
      'itens_pendentes': pendingItems,
      'percentual_progresso': progressPercentage,
      'localizacoes': locations,
      'observacoes': notes,
      'metadata': metadata,
      'sync_status': syncStatus.value,
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }

  /// Converte para JSON do banco local
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'company_code': companyCode,
      'branch_code': branchCode,
      'warehouse_code': warehouseCode,
      'warehouse_name': warehouseName,
      'responsible_id': responsibleId,
      'responsible_name': responsibleName,
      'status': status.value,
      'type': type.value,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'total_items': totalItems,
      'counted_items': countedItems,
      'pending_items': pendingItems,
      'progress_percentage': progressPercentage,
      'locations': jsonEncode(locations),
      'notes': notes,
      'metadata': jsonEncode(metadata),
      'sync_status': syncStatus.value,
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }

  /// Cria uma instância a partir do JSON do banco local
  factory InventoryBatch.fromLocalJson(Map<String, dynamic> json) {
    return InventoryBatch(
      id: json['id']?.toString() ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      companyCode: json['company_code'] ?? '',
      branchCode: json['branch_code'] ?? '',
      warehouseCode: json['warehouse_code'] ?? '',
      warehouseName: json['warehouse_name'] ?? '',
      responsibleId: json['responsible_id'] ?? '',
      responsibleName: json['responsible_name'] ?? '',
      status: InventoryStatus.fromString(json['status'] ?? 'aberto'),
      type: InventoryType.fromString(json['type'] ?? 'geral'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      finishedAt: json['finished_at'] != null
          ? DateTime.parse(json['finished_at'])
          : null,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      totalItems: json['total_items'] ?? 0,
      countedItems: json['counted_items'] ?? 0,
      pendingItems: json['pending_items'] ?? 0,
      progressPercentage: (json['progress_percentage'] ?? 0.0).toDouble(),
      locations: json['locations'] != null
          ? List<String>.from(jsonDecode(json['locations']))
          : [],
      notes: json['notes'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(jsonDecode(json['metadata']))
          : {},
      syncStatus: SyncStatus.fromString(json['sync_status'] ?? 'pending'),
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'])
          : null,
    );
  }

  /// Cria cópia com modificações
  InventoryBatch copyWith({
    String? id,
    String? code,
    String? description,
    String? companyCode,
    String? branchCode,
    String? warehouseCode,
    String? warehouseName,
    String? responsibleId,
    String? responsibleName,
    InventoryStatus? status,
    InventoryType? type,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    DateTime? approvedAt,
    DateTime? updatedAt,
    int? totalItems,
    int? countedItems,
    int? pendingItems,
    double? progressPercentage,
    List<String>? locations,
    String? notes,
    Map<String, dynamic>? metadata,
    SyncStatus? syncStatus,
    DateTime? lastSyncAt,
  }) {
    return InventoryBatch(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      companyCode: companyCode ?? this.companyCode,
      branchCode: branchCode ?? this.branchCode,
      warehouseCode: warehouseCode ?? this.warehouseCode,
      warehouseName: warehouseName ?? this.warehouseName,
      responsibleId: responsibleId ?? this.responsibleId,
      responsibleName: responsibleName ?? this.responsibleName,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalItems: totalItems ?? this.totalItems,
      countedItems: countedItems ?? this.countedItems,
      pendingItems: pendingItems ?? this.pendingItems,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      locations: locations ?? this.locations,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  /// Verifica se pode ser iniciado
  bool get canStart => status == InventoryStatus.open;

  /// Verifica se está em progresso
  bool get isInProgress => status == InventoryStatus.counting;

  /// Verifica se pode ser finalizado
  bool get canFinish =>
      status == InventoryStatus.counting && progressPercentage >= 100;

  /// Verifica se pode ser aprovado
  bool get canApprove => status == InventoryStatus.closed;

  /// Verifica se está completo
  bool get isComplete => progressPercentage >= 100;

  /// Verifica se precisa sincronizar
  bool get needsSync => syncStatus != SyncStatus.synced;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryBatch && other.id == id && other.code == code;
  }

  @override
  int get hashCode => Object.hash(id, code);

  @override
  String toString() {
    return 'InventoryBatch(id: $id, code: $code, status: ${status.label}, progress: ${progressPercentage.toStringAsFixed(1)}%)';
  }
}

/// Enum para status do inventário
enum InventoryStatus {
  open('aberto', 'Aberto'),
  counting('contagem', 'Contagem'),
  closed('encerrado', 'Encerrado'),
  reviewed('revisado', 'Revisado'),
  approved('aprovado', 'Aprovado'),
  transferred('transferido', 'Transferido'),
  executed('executado', 'Executado');

  const InventoryStatus(this.value, this.label);

  final String value;
  final String label;

  static InventoryStatus fromString(String value) {
    return InventoryStatus.values.firstWhere(
      (status) => status.value == value.toLowerCase(),
      orElse: () => InventoryStatus.open,
    );
  }
}

/// Enum para tipo do inventário
enum InventoryType {
  general('geral', 'Geral'),
  partial('parcial', 'Parcial'),
  cyclical('ciclico', 'Cíclico'),
  location('localizacao', 'Por Localização'),
  product('produto', 'Por Produto');

  const InventoryType(this.value, this.label);

  final String value;
  final String label;

  static InventoryType fromString(String value) {
    return InventoryType.values.firstWhere(
      (type) => type.value == value.toLowerCase(),
      orElse: () => InventoryType.general,
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
