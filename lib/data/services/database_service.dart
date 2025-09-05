import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/inventory_batch.dart';
import '../models/product.dart';
import '../models/inventory_item.dart';
import '../models/photo.dart';

/// Serviço para gerenciamento do banco de dados SQLite local
/// Armazena dados para funcionamento offline
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  Database? _database;
  static const String _databaseName = 'inventario_conasa.db';
  static const int _databaseVersion = 1;

  /// Inicializar banco de dados
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Inicializar o banco de dados
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Criar tabelas do banco
  Future<void> _onCreate(Database db, int version) async {
    // Tabela de usuários
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        access_token TEXT,
        refresh_token TEXT,
        token_expiry TEXT,
        permissions TEXT,
        selected_company TEXT,
        available_companies TEXT,
        is_active INTEGER DEFAULT 1,
        last_login TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabela de lotes de inventário (Z75)
    await db.execute('''
      CREATE TABLE inventory_batches (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        description TEXT NOT NULL,
        company_code TEXT NOT NULL,
        branch_code TEXT NOT NULL,
        warehouse_code TEXT NOT NULL,
        warehouse_name TEXT NOT NULL,
        responsible_id TEXT NOT NULL,
        responsible_name TEXT NOT NULL,
        status TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        started_at TEXT,
        finished_at TEXT,
        approved_at TEXT,
        updated_at TEXT NOT NULL,
        total_items INTEGER DEFAULT 0,
        counted_items INTEGER DEFAULT 0,
        pending_items INTEGER DEFAULT 0,
        progress_percentage REAL DEFAULT 0.0,
        locations TEXT,
        notes TEXT,
        metadata TEXT,
        sync_status TEXT DEFAULT 'pending',
        last_sync_at TEXT
      )
    ''');

    // Tabela de produtos (SB1)
    await db.execute('''
      CREATE TABLE products (
        code TEXT NOT NULL,
        description TEXT NOT NULL,
        unit_of_measure TEXT NOT NULL,
        type TEXT NOT NULL,
        default_location TEXT NOT NULL,
        group_code TEXT NOT NULL,
        group_description TEXT NOT NULL,
        group_type TEXT NOT NULL,
        current_stock REAL DEFAULT 0.0,
        average_cost REAL DEFAULT 0.0,
        requires_tag INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        is_blocked INTEGER DEFAULT 0,
        barcode TEXT,
        alternative_code TEXT,
        ncm_code TEXT,
        family_code TEXT,
        sub_family_code TEXT,
        dimensions TEXT,
        additional_info TEXT,
        last_inventory_date TEXT,
        company_code TEXT NOT NULL,
        branch_code TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (code, company_code, branch_code)
      )
    ''');

    // Tabela de itens inventariados (Z76)
    await db.execute('''
      CREATE TABLE inventory_items (
        id TEXT PRIMARY KEY,
        inventory_batch_id TEXT NOT NULL,
        product_code TEXT NOT NULL,
        product_description TEXT NOT NULL,
        unit_of_measure TEXT NOT NULL,
        location TEXT NOT NULL,
        sub_location TEXT,
        quantity REAL NOT NULL,
        system_quantity REAL,
        variance REAL,
        average_cost REAL,
        total_cost REAL,
        tag_code TEXT,
        tag_required INTEGER DEFAULT 0,
        tag_damaged INTEGER DEFAULT 0,
        counted_by TEXT NOT NULL,
        counted_at TEXT NOT NULL,
        reviewed_by TEXT,
        reviewed_at TEXT,
        notes TEXT,
        photo_ids TEXT,
        status TEXT NOT NULL,
        sequence INTEGER DEFAULT 1,
        recount INTEGER,
        additional_data TEXT,
        sync_status TEXT DEFAULT 'pending',
        last_sync_at TEXT,
        company_code TEXT NOT NULL,
        branch_code TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (inventory_batch_id) REFERENCES inventory_batches (id)
      )
    ''');

    // Tabela de fotos
    await db.execute('''
      CREATE TABLE photos (
        id TEXT PRIMARY KEY,
        inventory_batch_id TEXT NOT NULL,
        inventory_item_id TEXT NOT NULL,
        product_code TEXT NOT NULL,
        file_name TEXT NOT NULL,
        local_path TEXT NOT NULL,
        server_path TEXT,
        url TEXT,
        file_size INTEGER DEFAULT 0,
        mime_type TEXT DEFAULT 'image/jpeg',
        type TEXT NOT NULL,
        width INTEGER DEFAULT 0,
        height INTEGER DEFAULT 0,
        latitude REAL,
        longitude REAL,
        captured_by TEXT NOT NULL,
        captured_at TEXT NOT NULL,
        description TEXT,
        is_compressed INTEGER DEFAULT 0,
        original_file_size INTEGER,
        status TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        last_sync_at TEXT,
        sync_error TEXT,
        metadata TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (inventory_batch_id) REFERENCES inventory_batches (id),
        FOREIGN KEY (inventory_item_id) REFERENCES inventory_items (id)
      )
    ''');

    // Tabela de logs de sincronização
    await db.execute('''
      CREATE TABLE sync_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        status TEXT NOT NULL,
        error_message TEXT,
        request_data TEXT,
        response_data TEXT,
        started_at TEXT NOT NULL,
        finished_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Criar índices para melhor performance
    await _createIndexes(db);
  }

  /// Criar índices
  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX idx_inventory_batches_status ON inventory_batches (status)',
    );
    await db.execute(
      'CREATE INDEX idx_inventory_batches_company ON inventory_batches (company_code, branch_code)',
    );
    await db.execute(
      'CREATE INDEX idx_inventory_batches_sync ON inventory_batches (sync_status)',
    );

    await db.execute('CREATE INDEX idx_products_code ON products (code)');
    await db.execute('CREATE INDEX idx_products_barcode ON products (barcode)');
    await db.execute(
      'CREATE INDEX idx_products_company ON products (company_code, branch_code)',
    );

    await db.execute(
      'CREATE INDEX idx_inventory_items_batch ON inventory_items (inventory_batch_id)',
    );
    await db.execute(
      'CREATE INDEX idx_inventory_items_product ON inventory_items (product_code)',
    );
    await db.execute(
      'CREATE INDEX idx_inventory_items_status ON inventory_items (status)',
    );
    await db.execute(
      'CREATE INDEX idx_inventory_items_sync ON inventory_items (sync_status)',
    );

    await db.execute(
      'CREATE INDEX idx_photos_batch ON photos (inventory_batch_id)',
    );
    await db.execute(
      'CREATE INDEX idx_photos_item ON photos (inventory_item_id)',
    );
    await db.execute('CREATE INDEX idx_photos_sync ON photos (sync_status)');

    await db.execute(
      'CREATE INDEX idx_sync_logs_entity ON sync_logs (entity_type, entity_id)',
    );
    await db.execute('CREATE INDEX idx_sync_logs_status ON sync_logs (status)');
  }

  /// Upgrade do banco de dados
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implementar migrações futuras aqui
    if (oldVersion < 2) {
      // Exemplo de migração
      // await db.execute('ALTER TABLE users ADD COLUMN new_field TEXT');
    }
  }

  /// Salvar usuário
  Future<void> saveUser(User user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toLocalJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obter usuário por ID
  Future<User?> getUser(String id) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return User.fromLocalJson(maps.first);
    }
    return null;
  }

  /// Obter usuário logado
  Future<User?> getLoggedUser() async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'access_token IS NOT NULL',
      orderBy: 'last_login DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return User.fromLocalJson(maps.first);
    }
    return null;
  }

  /// Deletar usuário
  Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  /// Salvar lote de inventário
  Future<void> saveInventoryBatch(InventoryBatch batch) async {
    final db = await database;
    await db.insert(
      'inventory_batches',
      batch.toLocalJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obter lotes de inventário
  Future<List<InventoryBatch>> getInventoryBatches({
    String? status,
    String? companyCode,
    String? branchCode,
  }) async {
    final db = await database;

    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (status != null) {
      where += ' AND status = ?';
      whereArgs.add(status);
    }

    if (companyCode != null) {
      where += ' AND company_code = ?';
      whereArgs.add(companyCode);
    }

    if (branchCode != null) {
      where += ' AND branch_code = ?';
      whereArgs.add(branchCode);
    }

    final maps = await db.query(
      'inventory_batches',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => InventoryBatch.fromLocalJson(map)).toList();
  }

  /// Obter lote de inventário por ID
  Future<InventoryBatch?> getInventoryBatch(String id) async {
    final db = await database;
    final maps = await db.query(
      'inventory_batches',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return InventoryBatch.fromLocalJson(maps.first);
    }
    return null;
  }

  /// Atualizar progresso do lote
  Future<void> updateInventoryBatchProgress(String batchId) async {
    final db = await database;

    // Calcular progresso baseado nos itens
    final result = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as total_items,
        COUNT(CASE WHEN status = 'contado' THEN 1 END) as counted_items
      FROM inventory_items 
      WHERE inventory_batch_id = ?
    ''',
      [batchId],
    );

    if (result.isNotEmpty) {
      final totalItems = result.first['total_items'] as int;
      final countedItems = result.first['counted_items'] as int;
      final pendingItems = totalItems - countedItems;
      final progressPercentage = totalItems > 0
          ? (countedItems / totalItems) * 100
          : 0.0;

      await db.update(
        'inventory_batches',
        {
          'total_items': totalItems,
          'counted_items': countedItems,
          'pending_items': pendingItems,
          'progress_percentage': progressPercentage,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [batchId],
      );
    }
  }

  /// Salvar produto
  Future<void> saveProduct(Product product) async {
    final db = await database;
    await db.insert(
      'products',
      product.toLocalJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Salvar múltiplos produtos
  Future<void> saveProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();

    for (final product in products) {
      batch.insert(
        'products',
        product.toLocalJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Buscar produtos
  Future<List<Product>> searchProducts({
    String? searchTerm,
    String? companyCode,
    String? branchCode,
    int? limit,
  }) async {
    final db = await database;

    String where = 'is_active = 1 AND is_blocked = 0';
    List<dynamic> whereArgs = [];

    if (searchTerm != null && searchTerm.isNotEmpty) {
      where += ' AND (code LIKE ? OR description LIKE ? OR barcode LIKE ?)';
      final term = '%$searchTerm%';
      whereArgs.addAll([term, term, term]);
    }

    if (companyCode != null) {
      where += ' AND company_code = ?';
      whereArgs.add(companyCode);
    }

    if (branchCode != null) {
      where += ' AND branch_code = ?';
      whereArgs.add(branchCode);
    }

    final maps = await db.query(
      'products',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'description',
      limit: limit,
    );

    return maps.map((map) => Product.fromLocalJson(map)).toList();
  }

  /// Obter produto por código
  Future<Product?> getProduct(
    String code,
    String companyCode,
    String branchCode,
  ) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'code = ? AND company_code = ? AND branch_code = ?',
      whereArgs: [code, companyCode, branchCode],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Product.fromLocalJson(maps.first);
    }
    return null;
  }

  /// Salvar item inventariado
  Future<void> saveInventoryItem(InventoryItem item) async {
    final db = await database;
    await db.insert(
      'inventory_items',
      item.toLocalJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Atualizar progresso do lote
    await updateInventoryBatchProgress(item.inventoryBatchId);
  }

  /// Obter itens inventariados por lote
  Future<List<InventoryItem>> getInventoryItems(String batchId) async {
    final db = await database;
    final maps = await db.query(
      'inventory_items',
      where: 'inventory_batch_id = ?',
      whereArgs: [batchId],
      orderBy: 'sequence, created_at',
    );

    return maps.map((map) => InventoryItem.fromLocalJson(map)).toList();
  }

  /// Obter item inventariado por ID
  Future<InventoryItem?> getInventoryItem(String id) async {
    final db = await database;
    final maps = await db.query(
      'inventory_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return InventoryItem.fromLocalJson(maps.first);
    }
    return null;
  }

  /// Deletar item inventariado
  Future<void> deleteInventoryItem(String id) async {
    final db = await database;

    // Obter o item para pegar o batch ID
    final item = await getInventoryItem(id);

    await db.delete('inventory_items', where: 'id = ?', whereArgs: [id]);

    // Atualizar progresso do lote
    if (item != null) {
      await updateInventoryBatchProgress(item.inventoryBatchId);
    }
  }

  /// Salvar foto
  Future<void> savePhoto(Photo photo) async {
    final db = await database;
    await db.insert(
      'photos',
      photo.toLocalJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obter fotos por item
  Future<List<Photo>> getPhotos(String itemId) async {
    final db = await database;
    final maps = await db.query(
      'photos',
      where: 'inventory_item_id = ?',
      whereArgs: [itemId],
      orderBy: 'created_at',
    );

    return maps.map((map) => Photo.fromLocalJson(map)).toList();
  }

  /// Deletar foto
  Future<void> deletePhoto(String id) async {
    final db = await database;
    await db.delete('photos', where: 'id = ?', whereArgs: [id]);
  }

  /// Obter dados pendentes de sincronização
  Future<Map<String, List<Map<String, dynamic>>>> getPendingSyncData() async {
    final db = await database;

    final result = <String, List<Map<String, dynamic>>>{};

    // Lotes de inventário pendentes
    final batches = await db.query(
      'inventory_batches',
      where: 'sync_status != ?',
      whereArgs: ['synced'],
    );
    result['inventory_batches'] = batches;

    // Itens pendentes
    final items = await db.query(
      'inventory_items',
      where: 'sync_status != ?',
      whereArgs: ['synced'],
    );
    result['inventory_items'] = items;

    // Fotos pendentes
    final photos = await db.query(
      'photos',
      where: 'sync_status != ?',
      whereArgs: ['synced'],
    );
    result['photos'] = photos;

    return result;
  }

  /// Marcar como sincronizado
  Future<void> markAsSynced(String tableName, String id) async {
    final db = await database;
    await db.update(
      tableName,
      {
        'sync_status': 'synced',
        'last_sync_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Salvar log de sincronização
  Future<void> saveSyncLog({
    required String entityType,
    required String entityId,
    required String operation,
    required String status,
    String? errorMessage,
    String? requestData,
    String? responseData,
    required DateTime startedAt,
    DateTime? finishedAt,
  }) async {
    final db = await database;
    await db.insert('sync_logs', {
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'status': status,
      'error_message': errorMessage,
      'request_data': requestData,
      'response_data': responseData,
      'started_at': startedAt.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Limpar dados antigos
  Future<void> clearOldData() async {
    final db = await database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    // Limpar logs de sincronização antigos
    await db.delete(
      'sync_logs',
      where: 'created_at < ?',
      whereArgs: [thirtyDaysAgo.toIso8601String()],
    );

    // Limpar inventários antigos já sincronizados
    await db.delete(
      'inventory_batches',
      where: 'sync_status = ? AND updated_at < ?',
      whereArgs: ['synced', thirtyDaysAgo.toIso8601String()],
    );
  }

  /// Fechar banco de dados
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Deletar banco de dados (para debug/reset)
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
