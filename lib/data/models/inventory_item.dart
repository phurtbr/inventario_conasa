import 'dart:convert';

/// Modelo de dados para item inventariado (Tabela Z76)
/// Representa um item contado durante o inventário
class InventoryItem {
  final String id;
  final String inventoryBatchId;
  final String productCode;
  final String productDescription;
  final String unitOfMeasure;
  final String location;
  final String? subLocation;
  final double quantity;
  final double? systemQuantity;
  final double? variance;
  final double? averageCost;
  final double? totalCost;
  final String? tagCode;
  final bool tagRequired;
  final bool tagDamaged;
  final String countedBy;
  final DateTime countedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? notes;
  final List<String> photoIds;
  final InventoryItemStatus status;
  final int sequence;
  final int? recount;
  final Map<String, dynamic> additionalData;
  final SyncStatus syncStatus;
  final DateTime? lastSyncAt;
  final String companyCode;
  final String branchCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryItem({
    required this.id,
    required this.inventoryBatchId,
    required this.productCode,
    required this.productDescription,
    required this.unitOfMeasure,
    required this.location,
    this.subLocation,
    required this.quantity,
    this.systemQuantity,
    this.variance,
    this.averageCost,
    this.totalCost,
    this.tagCode,
    this.tagRequired = false,
    this.tagDamaged = false,
    required this.countedBy,
    required this.countedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.notes,
    this.photoIds = const [],
    this.status = InventoryItemStatus.counted,
    this.sequence = 1,
    this.recount,
    this.additionalData = const {},
    this.syncStatus = SyncStatus.pending,
    this.lastSyncAt,
    required this.companyCode,
    required this.branchCode,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria uma instância a partir de JSON da API Z76
  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id']?.toString() ?? '',
      inventoryBatchId: json['lote_id'] ?? json['inventory_batch_id'] ?? '',
      productCode: json['codigo_produto'] ?? json['product_code'] ?? '',
      productDescription:
          json['descricao_produto'] ?? json['product_description'] ?? '',
      unitOfMeasure: json['unidade_medida'] ?? json['unit_of_measure'] ?? '',
      location: json['localizacao'] ?? json['location'] ?? '',
      subLocation: json['sub_localizacao'] ?? json['sub_location'],
      quantity: (json['quantidade'] ?? json['quantity'] ?? 0.0).toDouble(),
      systemQuantity: json['quantidade_sistema'] != null
          ? (json['quantidade_sistema']).toDouble()
          : json['system_quantity'] != null
          ? (json['system_quantity']).toDouble()
          : null,
      variance: json['divergencia'] != null
          ? (json['divergencia']).toDouble()
          : json['variance'] != null
          ? (json['variance']).toDouble()
          : null,
      averageCost: json['custo_medio'] != null
          ? (json['custo_medio']).toDouble()
          : json['average_cost'] != null
          ? (json['average_cost']).toDouble()
          : null,
      totalCost: json['custo_total'] != null
          ? (json['custo_total']).toDouble()
          : json['total_cost'] != null
          ? (json['total_cost']).toDouble()
          : null,
      tagCode: json['codigo_tag'] ?? json['tag_code'],
      tagRequired: json['tag_obrigatoria'] ?? json['tag_required'] ?? false,
      tagDamaged: json['tag_danificada'] ?? json['tag_damaged'] ?? false,
      countedBy: json['contado_por'] ?? json['counted_by'] ?? '',
      countedAt: json['data_contagem'] != null
          ? DateTime.parse(json['data_contagem'])
          : json['counted_at'] != null
          ? DateTime.parse(json['counted_at'])
          : DateTime.now(),
      reviewedBy: json['revisado_por'] ?? json['reviewed_by'],
      reviewedAt: json['data_revisao'] != null
          ? DateTime.parse(json['data_revisao'])
          : json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'])
          : null,
      notes: json['observacoes'] ?? json['notes'],
      photoIds: json['fotos'] != null
          ? List<String>.from(json['fotos'])
          : json['photo_ids'] != null
          ? List<String>.from(json['photo_ids'])
          : [],
      status: InventoryItemStatus.fromString(json['status'] ?? 'contado'),
      sequence: json['sequencia'] ?? json['sequence'] ?? 1,
      recount: json['recontagem'] ?? json['recount'],
      additionalData: json['dados_adicionais'] ?? json['additional_data'] ?? {},
      syncStatus: SyncStatus.fromString(json['sync_status'] ?? 'pending'),
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'])
          : null,
      companyCode: json['empresa'] ?? json['company_code'] ?? '',
      branchCode: json['filial'] ?? json['branch_code'] ?? '',
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

  /// Converte para JSON da API Z76
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lote_id': inventoryBatchId,
      'codigo_produto': productCode,
      'descricao_produto': productDescription,
      'unidade_medida': unitOfMeasure,
      'localizacao': location,
      'sub_localizacao': subLocation,
      'quantidade': quantity,
      'quantidade_sistema': systemQuantity,
      'divergencia': variance,
      'custo_medio': averageCost,
      'custo_total': totalCost,
      'codigo_tag': tagCode,
      'tag_obrigatoria': tagRequired,
      'tag_danificada': tagDamaged,
      'contado_por': countedBy,
      'data_contagem': countedAt.toIso8601String(),
      'revisado_por': reviewedBy,
      'data_revisao': reviewedAt?.toIso8601String(),
      'observacoes': notes,
      'fotos': photoIds,
      'status': status.value,
      'sequencia': sequence,
      'recontagem': recount,
      'dados_adicionais': additionalData,
      'sync_status': syncStatus.value,
      'last_sync_at': lastSyncAt?.toIso8601String(),
      'empresa': companyCode,
      'filial': branchCode,
      'data_criacao': createdAt.toIso8601String(),
      'data_atualizacao': updatedAt.toIso8601String(),
    };
  }

  /// Converte para JSON do banco local
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'inventory_batch_id': inventoryBatchId,
      'product_code': productCode,
      'product_description': productDescription,
      'unit_of_measure': unitOfMeasure,
      'location': location,
      'sub_location': subLocation,
      'quantity': quantity,
      'system_quantity': systemQuantity,
      'variance': variance,
      'average_cost': averageCost,
      'total_cost': totalCost,
      'tag_code': tagCode,
      'tag_required': tagRequired ? 1 : 0,
      'tag_damaged': tagDamaged ? 1 : 0,
      'counted_by': countedBy,
      'counted_at': countedAt.toIso8601String(),
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'notes': notes,
      'photo_ids': jsonEncode(photoIds),
      'status': status.value,
      'sequence': sequence,
      'recount': recount,
      'additional_data': jsonEncode(additionalData),
      'sync_status': syncStatus.value,
      'last_sync_at': lastSyncAt?.toIso8601String(),
      'company_code': companyCode,
      'branch_code': branchCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Cria uma instância a partir do JSON do banco local
  factory InventoryItem.fromLocalJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id']?.toString() ?? '',
      inventoryBatchId: json['inventory_batch_id'] ?? '',
      productCode: json['product_code'] ?? '',
      productDescription: json['product_description'] ?? '',
      unitOfMeasure: json['unit_of_measure'] ?? '',
      location: json['location'] ?? '',
      subLocation: json['sub_location'],
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      systemQuantity: json['system_quantity']?.toDouble(),
      variance: json['variance']?.toDouble(),
      averageCost: json['average_cost']?.toDouble(),
      totalCost: json['total_cost']?.toDouble(),
      tagCode: json['tag_code'],
      tagRequired: json['tag_required'] == 1,
      tagDamaged: json['tag_damaged'] == 1,
      countedBy: json['counted_by'] ?? '',
      countedAt: json['counted_at'] != null
          ? DateTime.parse(json['counted_at'])
          : DateTime.now(),
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'])
          : null,
      notes: json['notes'],
      photoIds: json['photo_ids'] != null
          ? List<String>.from(jsonDecode(json['photo_ids']))
          : [],
      status: InventoryItemStatus.fromString(json['status'] ?? 'contado'),
      sequence: json['sequence'] ?? 1,
      recount: json['recount'],
      additionalData: json['additional_data'] != null
          ? Map<String, dynamic>.from(jsonDecode(json['additional_data']))
          : {},
      syncStatus: SyncStatus.fromString(json['sync_status'] ?? 'pending'),
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'])
          : null,
      companyCode: json['company_code'] ?? '',
      branchCode: json['branch_code'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  /// Cria cópia com modificações
  InventoryItem copyWith({
    String? id,
    String? inventoryBatchId,
    String? productCode,
    String? productDescription,
    String? unitOfMeasure,
    String? location,
    String? subLocation,
    double? quantity,
    double? systemQuantity,
    double? variance,
    double? averageCost,
    double? totalCost,
    String? tagCode,
    bool? tagRequired,
    bool? tagDamaged,
    String? countedBy,
    DateTime? countedAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? notes,
    List<String>? photoIds,
    InventoryItemStatus? status,
    int? sequence,
    int? recount,
    Map<String, dynamic>? additionalData,
    SyncStatus? syncStatus,
    DateTime? lastSyncAt,
    String? companyCode,
    String? branchCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      inventoryBatchId: inventoryBatchId ?? this.inventoryBatchId,
      productCode: productCode ?? this.productCode,
      productDescription: productDescription ?? this.productDescription,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      location: location ?? this.location,
      subLocation: subLocation ?? this.subLocation,
      quantity: quantity ?? this.quantity,
      systemQuantity: systemQuantity ?? this.systemQuantity,
      variance: variance ?? this.variance,
      averageCost: averageCost ?? this.averageCost,
      totalCost: totalCost ?? this.totalCost,
      tagCode: tagCode ?? this.tagCode,
      tagRequired: tagRequired ?? this.tagRequired,
      tagDamaged: tagDamaged ?? this.tagDamaged,
      countedBy: countedBy ?? this.countedBy,
      countedAt: countedAt ?? this.countedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      notes: notes ?? this.notes,
      photoIds: photoIds ?? this.photoIds,
      status: status ?? this.status,
      sequence: sequence ?? this.sequence,
      recount: recount ?? this.recount,
      additionalData: additionalData ?? this.additionalData,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      companyCode: companyCode ?? this.companyCode,
      branchCode: branchCode ?? this.branchCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calcula a variância se não foi definida
  double get calculatedVariance {
    if (variance != null) return variance!;
    if (systemQuantity != null) return quantity - systemQuantity!;
    return 0.0;
  }

  /// Verifica se tem divergência
  bool get hasVariance => calculatedVariance.abs() > 0.001;

  /// Verifica se a divergência é positiva (sobra)
  bool get hasPositiveVariance => calculatedVariance > 0.001;

  /// Verifica se a divergência é negativa (falta)
  bool get hasNegativeVariance => calculatedVariance < -0.001;

  /// Verifica se tem fotos anexadas
  bool get hasPhotos => photoIds.isNotEmpty;

  /// Verifica se atende aos requisitos de TAG
  bool get meetTagRequirements {
    if (!tagRequired) return true;
    if (tagDamaged) return true; // TAG danificada é aceita
    return tagCode?.isNotEmpty == true;
  }

  /// Verifica se pode ser editado
  bool get canBeEdited => status == InventoryItemStatus.counted;

  /// Verifica se precisa de revisão
  bool get needsReview => hasVariance && status == InventoryItemStatus.counted;

  /// Verifica se precisa sincronizar
  bool get needsSync => syncStatus != SyncStatus.synced;

  /// Retorna o nome do arquivo de foto baseado no padrão
  String generatePhotoFileName(int photoIndex) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'INV_${inventoryBatchId}_${sequence}_${productCode}_${timestamp}_$photoIndex.jpg';
  }

  /// Verifica se corresponde aos termos de busca
  bool matchesSearch(String searchTerm) {
    final term = searchTerm.toLowerCase();
    return productCode.toLowerCase().contains(term) ||
        productDescription.toLowerCase().contains(term) ||
        location.toLowerCase().contains(term) ||
        (tagCode?.toLowerCase().contains(term) ?? false) ||
        (notes?.toLowerCase().contains(term) ?? false);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryItem &&
        other.id == id &&
        other.inventoryBatchId == inventoryBatchId &&
        other.productCode == productCode;
  }

  @override
  int get hashCode => Object.hash(id, inventoryBatchId, productCode);

  @override
  String toString() {
    return 'InventoryItem(id: $id, product: $productCode, quantity: $quantity $unitOfMeasure, status: ${status.label})';
  }
}

/// Enum para status do item inventariado
enum InventoryItemStatus {
  counted('contado', 'Contado'),
  reviewed('revisado', 'Revisado'),
  approved('aprovado', 'Aprovado'),
  rejected('rejeitado', 'Rejeitado'),
  recount('recontagem', 'Recontagem');

  const InventoryItemStatus(this.value, this.label);

  final String value;
  final String label;

  static InventoryItemStatus fromString(String value) {
    return InventoryItemStatus.values.firstWhere(
      (status) => status.value == value.toLowerCase(),
      orElse: () => InventoryItemStatus.counted,
    );
  }
}

/// Enum para status de sincronização (reutilizado)
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
