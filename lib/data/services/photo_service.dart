import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/image_helper.dart';
import '../models/photo.dart';
import '../models/inventory_item.dart';
import 'database_service.dart';

/// Serviço especializado para gerenciamento de fotos do inventário
/// Coordena captura, processamento, armazenamento e sincronização de fotos
class PhotoService {
  static PhotoService? _instance;
  static PhotoService get instance => _instance ??= PhotoService._();

  PhotoService._();

  final DatabaseService _dbService = DatabaseService.instance;

  /// Capturar foto da câmera para um item de inventário
  Future<Photo?> capturePhotoForItem(
    InventoryItem item,
    String userId, {
    PhotoType type = PhotoType.product,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Capturar foto
      final imageFile = await ImageHelper.captureFromCamera();
      if (imageFile == null) return null;

      return await _processAndSavePhoto(
        imageFile,
        item,
        userId,
        type: type,
        description: description,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      print('Erro ao capturar foto: $e');
      return null;
    }
  }

  /// Selecionar foto da galeria para um item de inventário
  Future<Photo?> pickPhotoForItem(
    InventoryItem item,
    String userId, {
    PhotoType type = PhotoType.product,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Selecionar da galeria
      final imageFile = await ImageHelper.pickFromGallery();
      if (imageFile == null) return null;

      return await _processAndSavePhoto(
        imageFile,
        item,
        userId,
        type: type,
        description: description,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      print('Erro ao selecionar foto: $e');
      return null;
    }
  }

  /// Processar e salvar foto
  Future<Photo?> _processAndSavePhoto(
    File imageFile,
    InventoryItem item,
    String userId, {
    PhotoType type = PhotoType.product,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Validar arquivo
      if (!ImageHelper.isValidImageFile(imageFile)) {
        throw Exception('Arquivo de imagem inválido');
      }

      if (!await ImageHelper.isValidFileSize(imageFile)) {
        throw Exception('Arquivo muito grande (máximo 5MB)');
      }

      // Gerar nome único para o arquivo
      final fileName = ImageHelper.generateUniqueFileName(
        item.inventoryBatchId,
        item.productCode,
        item.sequence,
      );

      // Salvar no diretório do app
      final savedFile = await ImageHelper.saveImageToAppDirectory(
        imageFile,
        fileName,
      );

      if (savedFile == null) {
        throw Exception('Falha ao salvar arquivo');
      }

      // Obter informações da imagem
      final imageInfo = await ImageHelper.getImageInfo(savedFile);
      if (imageInfo == null) {
        throw Exception('Falha ao obter informações da imagem');
      }

      // Comprimir se necessário
      File? compressedFile;
      int? originalFileSize;
      bool isCompressed = false;

      if (imageInfo.fileSizeInMB > 2.0) {
        originalFileSize = imageInfo.fileSize;
        compressedFile = await ImageHelper.compressImage(savedFile);

        if (compressedFile != null) {
          // Substituir arquivo original pelo comprimido
          await savedFile.delete();
          await compressedFile.copy(savedFile.path);
          await compressedFile.delete();
          isCompressed = true;
        }
      }

      // Criar thumbnail
      final thumbnailFileName = 'thumb_$fileName';
      await ImageHelper.createThumbnail(savedFile, thumbnailFileName);

      // Criar modelo de foto
      final photo = Photo(
        id: _generatePhotoId(),
        inventoryBatchId: item.inventoryBatchId,
        inventoryItemId: item.id,
        productCode: item.productCode,
        fileName: fileName,
        localPath: savedFile.path,
        fileSize: await savedFile.length(),
        mimeType: imageInfo.mimeType,
        type: type,
        width: imageInfo.width,
        height: imageInfo.height,
        latitude: latitude,
        longitude: longitude,
        capturedBy: userId,
        capturedAt: DateTime.now(),
        description: description,
        isCompressed: isCompressed,
        originalFileSize: originalFileSize,
        status: PhotoStatus.ready,
        syncStatus: SyncStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Salvar no banco de dados
      await _dbService.savePhoto(photo);

      // Atualizar lista de fotos do item
      await _updateItemPhotoIds(item, photo.id);

      return photo;
    } catch (e) {
      print('Erro ao processar foto: $e');

      // Limpar arquivo em caso de erro
      try {
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      } catch (_) {}

      return null;
    }
  }

  /// Atualizar IDs de fotos no item
  Future<void> _updateItemPhotoIds(InventoryItem item, String photoId) async {
    final updatedPhotoIds = List<String>.from(item.photoIds);
    if (!updatedPhotoIds.contains(photoId)) {
      updatedPhotoIds.add(photoId);

      final updatedItem = item.copyWith(
        photoIds: updatedPhotoIds,
        updatedAt: DateTime.now(),
      );

      await _dbService.saveInventoryItem(updatedItem);
    }
  }

  /// Obter fotos de um item
  Future<List<Photo>> getPhotosForItem(String itemId) async {
    return await _dbService.getPhotos(itemId);
  }

  /// Deletar foto
  Future<bool> deletePhoto(String photoId) async {
    try {
      // Obter foto do banco
      final photos = await _dbService.getPhotos(''); // Buscar por ID específico
      final photo = photos.where((p) => p.id == photoId).firstOrNull;

      if (photo == null) return false;

      // Deletar arquivo local
      await ImageHelper.deleteImageFile(photo.localPath);

      // Deletar thumbnail se existir
      final thumbnailPath = photo.thumbnailPath;
      await ImageHelper.deleteImageFile(thumbnailPath);

      // Remover do banco
      await _dbService.deletePhoto(photoId);

      // Atualizar item removendo a referência da foto
      final item = await _dbService.getInventoryItem(photo.inventoryItemId);
      if (item != null) {
        final updatedPhotoIds = item.photoIds
            .where((id) => id != photoId)
            .toList();
        final updatedItem = item.copyWith(
          photoIds: updatedPhotoIds,
          updatedAt: DateTime.now(),
        );
        await _dbService.saveInventoryItem(updatedItem);
      }

      return true;
    } catch (e) {
      print('Erro ao deletar foto: $e');
      return false;
    }
  }

  /// Fazer backup de todas as fotos
  Future<BackupResult> backupPhotos() async {
    try {
      // Obter todas as fotos pendentes de sincronização
      final pendingData = await _dbService.getPendingSyncData();
      final photosData = pendingData['photos'] ?? [];

      int successCount = 0;
      int errorCount = 0;
      final errors = <String>[];

      for (final photoData in photosData) {
        final photo = Photo.fromLocalJson(photoData);

        if (photo.existsLocally) {
          final backupFile = await ImageHelper.backupImageFile(
            File(photo.localPath),
          );
          if (backupFile != null) {
            successCount++;
          } else {
            errorCount++;
            errors.add('Falha no backup de ${photo.fileName}');
          }
        }
      }

      return BackupResult(
        isSuccess: errorCount == 0,
        totalFiles: photosData.length,
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
      );
    } catch (e) {
      return BackupResult(
        isSuccess: false,
        totalFiles: 0,
        successCount: 0,
        errorCount: 1,
        errors: ['Erro no backup: $e'],
      );
    }
  }

  /// Limpar fotos antigas e temporárias
  Future<CleanupResult> cleanupOldPhotos({int daysOld = 30}) async {
    try {
      int deletedFiles = 0;
      int freedSpaceBytes = 0;

      // Limpar arquivos temporários
      await ImageHelper.cleanupTempFiles();

      // Limpar fotos de inventários antigos já sincronizados
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      // Buscar fotos antigas no banco
      final db = await _dbService.database;
      final oldPhotos = await db.query(
        'photos',
        where: 'sync_status = ? AND created_at < ?',
        whereArgs: ['synced', cutoffDate.toIso8601String()],
      );

      for (final photoData in oldPhotos) {
        final photo = Photo.fromLocalJson(photoData);

        if (photo.existsLocally) {
          final file = File(photo.localPath);
          final fileSize = await file.length();

          if (await ImageHelper.deleteImageFile(photo.localPath)) {
            deletedFiles++;
            freedSpaceBytes += fileSize;

            // Remover do banco
            await _dbService.deletePhoto(photo.id);
          }
        }
      }

      return CleanupResult(
        isSuccess: true,
        deletedFiles: deletedFiles,
        freedSpaceBytes: freedSpaceBytes,
        message:
            'Limpeza concluída: $deletedFiles arquivos removidos, ${_formatFileSize(freedSpaceBytes)} liberados',
      );
    } catch (e) {
      return CleanupResult(
        isSuccess: false,
        deletedFiles: 0,
        freedSpaceBytes: 0,
        message: 'Erro na limpeza: $e',
      );
    }
  }

  /// Obter estatísticas de fotos
  Future<PhotoStatistics> getPhotoStatistics() async {
    try {
      final db = await _dbService.database;

      // Contar fotos por status
      final statusCounts = await db.rawQuery('''
        SELECT status, COUNT(*) as count 
        FROM photos 
        GROUP BY status
      ''');

      // Contar fotos por tipo
      final typeCounts = await db.rawQuery('''
        SELECT type, COUNT(*) as count 
        FROM photos 
        GROUP BY type
      ''');

      // Calcular tamanho total
      final sizeResult = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_photos,
          SUM(file_size) as total_size,
          AVG(file_size) as average_size
        FROM photos
      ''');

      // Fotos pendentes de sincronização
      final pendingResult = await db.rawQuery('''
        SELECT COUNT(*) as pending_count
        FROM photos 
        WHERE sync_status != 'synced'
      ''');

      final totalPhotos = sizeResult.first['total_photos'] as int? ?? 0;
      final totalSize = sizeResult.first['total_size'] as int? ?? 0;
      final averageSize = sizeResult.first['average_size'] as double? ?? 0.0;
      final pendingCount = pendingResult.first['pending_count'] as int? ?? 0;

      return PhotoStatistics(
        totalPhotos: totalPhotos,
        totalSizeBytes: totalSize,
        averageSizeBytes: averageSize,
        pendingSyncCount: pendingCount,
        statusBreakdown: Map.fromEntries(
          statusCounts.map(
            (row) => MapEntry(row['status'] as String, row['count'] as int),
          ),
        ),
        typeBreakdown: Map.fromEntries(
          typeCounts.map(
            (row) => MapEntry(row['type'] as String, row['count'] as int),
          ),
        ),
      );
    } catch (e) {
      return PhotoStatistics(
        totalPhotos: 0,
        totalSizeBytes: 0,
        averageSizeBytes: 0.0,
        pendingSyncCount: 0,
        statusBreakdown: {},
        typeBreakdown: {},
      );
    }
  }

  /// Verificar integridade das fotos
  Future<IntegrityCheckResult> checkPhotoIntegrity() async {
    try {
      final allPhotos = await _getAllPhotos();
      int validFiles = 0;
      int missingFiles = 0;
      int corruptedFiles = 0;
      final issues = <String>[];

      for (final photo in allPhotos) {
        final file = File(photo.localPath);

        if (!await file.exists()) {
          missingFiles++;
          issues.add('Arquivo não encontrado: ${photo.fileName}');
          continue;
        }

        // Verificar tamanho do arquivo
        final actualSize = await file.length();
        if (actualSize != photo.fileSize) {
          corruptedFiles++;
          issues.add(
            'Tamanho incorreto: ${photo.fileName} (esperado: ${photo.fileSize}, atual: $actualSize)',
          );
          continue;
        }

        // Verificar se é uma imagem válida
        if (!ImageHelper.isValidImageFile(file)) {
          corruptedFiles++;
          issues.add('Arquivo corrompido: ${photo.fileName}');
          continue;
        }

        validFiles++;
      }

      return IntegrityCheckResult(
        totalFiles: allPhotos.length,
        validFiles: validFiles,
        missingFiles: missingFiles,
        corruptedFiles: corruptedFiles,
        issues: issues,
      );
    } catch (e) {
      return IntegrityCheckResult(
        totalFiles: 0,
        validFiles: 0,
        missingFiles: 0,
        corruptedFiles: 0,
        issues: ['Erro na verificação: $e'],
      );
    }
  }

  /// Obter todas as fotos do banco
  Future<List<Photo>> _getAllPhotos() async {
    final db = await _dbService.database;
    final maps = await db.query('photos');
    return maps.map((map) => Photo.fromLocalJson(map)).toList();
  }

  /// Gerar ID único para foto
  String _generatePhotoId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'photo_${timestamp}_${_generateRandomString(8)}';
  }

  /// Gerar string aleatória
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      length,
      (index) => chars[DateTime.now().millisecondsSinceEpoch % chars.length],
    ).join();
  }

  /// Formatar tamanho de arquivo
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Resultado de operação de backup
class BackupResult {
  final bool isSuccess;
  final int totalFiles;
  final int successCount;
  final int errorCount;
  final List<String> errors;

  const BackupResult({
    required this.isSuccess,
    required this.totalFiles,
    required this.successCount,
    required this.errorCount,
    required this.errors,
  });

  String get message {
    if (isSuccess) {
      return 'Backup concluído: $successCount/$totalFiles arquivos processados';
    } else {
      return 'Backup com erros: $successCount/$totalFiles sucessos, $errorCount erros';
    }
  }
}

/// Resultado de operação de limpeza
class CleanupResult {
  final bool isSuccess;
  final int deletedFiles;
  final int freedSpaceBytes;
  final String message;

  const CleanupResult({
    required this.isSuccess,
    required this.deletedFiles,
    required this.freedSpaceBytes,
    required this.message,
  });
}

/// Estatísticas de fotos
class PhotoStatistics {
  final int totalPhotos;
  final int totalSizeBytes;
  final double averageSizeBytes;
  final int pendingSyncCount;
  final Map<String, int> statusBreakdown;
  final Map<String, int> typeBreakdown;

  const PhotoStatistics({
    required this.totalPhotos,
    required this.totalSizeBytes,
    required this.averageSizeBytes,
    required this.pendingSyncCount,
    required this.statusBreakdown,
    required this.typeBreakdown,
  });

  String get totalSizeFormatted => _formatFileSize(totalSizeBytes);
  String get averageSizeFormatted => _formatFileSize(averageSizeBytes.round());

  double get syncPercentage {
    if (totalPhotos == 0) return 100.0;
    return ((totalPhotos - pendingSyncCount) / totalPhotos) * 100;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Resultado de verificação de integridade
class IntegrityCheckResult {
  final int totalFiles;
  final int validFiles;
  final int missingFiles;
  final int corruptedFiles;
  final List<String> issues;

  const IntegrityCheckResult({
    required this.totalFiles,
    required this.validFiles,
    required this.missingFiles,
    required this.corruptedFiles,
    required this.issues,
  });

  bool get hasIssues => missingFiles > 0 || corruptedFiles > 0;

  String get summary {
    if (!hasIssues) {
      return 'Todas as $totalFiles fotos estão íntegras';
    } else {
      return '$validFiles válidas, $missingFiles ausentes, $corruptedFiles corrompidas';
    }
  }
}
