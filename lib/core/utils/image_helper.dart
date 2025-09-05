import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Helper para manipulação de imagens no aplicativo
/// Gerencia captura, compressão, redimensionamento e armazenamento
class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  // Configurações padrão
  static const int defaultMaxWidth = 1920;
  static const int defaultMaxHeight = 1080;
  static const int defaultQuality = 85;
  static const int thumbnailSize = 200;
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB

  /// Capturar foto da câmera
  static Future<File?> captureFromCamera({
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
    int imageQuality = defaultQuality,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao capturar foto da câmera: $e');
      return null;
    }
  }

  /// Selecionar foto da galeria
  static Future<File?> pickFromGallery({
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
    int imageQuality = defaultQuality,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao selecionar foto da galeria: $e');
      return null;
    }
  }

  /// Mostrar opções de captura (câmera ou galeria)
  static Future<File?> showImageSourceOptions(BuildContext context) async {
    return await showModalBottomSheet<File?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () async {
                Navigator.pop(context);
                final file = await captureFromCamera();
                if (context.mounted) {
                  Navigator.pop(context, file);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () async {
                Navigator.pop(context);
                final file = await pickFromGallery();
                if (context.mounted) {
                  Navigator.pop(context, file);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancelar'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Salvar imagem no diretório do aplicativo
  static Future<File?> saveImageToAppDirectory(
    File imageFile,
    String fileName,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');

      // Criar diretório se não existir
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final savedFile = File('${imagesDir.path}/$fileName');
      return await imageFile.copy(savedFile.path);
    } catch (e) {
      debugPrint('Erro ao salvar imagem: $e');
      return null;
    }
  }

  /// Comprimir imagem
  static Future<File?> compressImage(
    File imageFile, {
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
    int quality = defaultQuality,
  }) async {
    try {
      // Ler a imagem como bytes
      final bytes = await imageFile.readAsBytes();

      // Decodificar a imagem
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: maxWidth,
        targetHeight: maxHeight,
      );

      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      // Converter para PNG bytes
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final compressedBytes = byteData.buffer.asUint8List();

        // Salvar arquivo comprimido
        final compressedFile = File('${imageFile.path}_compressed.jpg');
        await compressedFile.writeAsBytes(compressedBytes);

        return compressedFile;
      }

      return null;
    } catch (e) {
      debugPrint('Erro ao comprimir imagem: $e');
      return null;
    }
  }

  /// Criar thumbnail da imagem
  static Future<File?> createThumbnail(
    File imageFile,
    String thumbnailFileName,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();

      // Decodificar e redimensionar para thumbnail
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: thumbnailSize,
        targetHeight: thumbnailSize,
      );

      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      // Converter para bytes
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final thumbnailBytes = byteData.buffer.asUint8List();

        // Salvar thumbnail
        final appDir = await getApplicationDocumentsDirectory();
        final thumbnailsDir = Directory('${appDir.path}/thumbnails');

        if (!await thumbnailsDir.exists()) {
          await thumbnailsDir.create(recursive: true);
        }

        final thumbnailFile = File('${thumbnailsDir.path}/$thumbnailFileName');
        await thumbnailFile.writeAsBytes(thumbnailBytes);

        return thumbnailFile;
      }

      return null;
    } catch (e) {
      debugPrint('Erro ao criar thumbnail: $e');
      return null;
    }
  }

  /// Obter dimensões da imagem
  static Future<Size?> getImageDimensions(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      return Size(image.width.toDouble(), image.height.toDouble());
    } catch (e) {
      debugPrint('Erro ao obter dimensões da imagem: $e');
      return null;
    }
  }

  /// Verificar se arquivo é uma imagem válida
  static bool isValidImageFile(File file) {
    if (!file.existsSync()) return false;

    final extension = path.extension(file.path).toLowerCase();
    const validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];

    return validExtensions.contains(extension);
  }

  /// Verificar tamanho do arquivo
  static Future<bool> isValidFileSize(File file) async {
    try {
      final fileSize = await file.length();
      return fileSize <= maxFileSizeBytes;
    } catch (e) {
      debugPrint('Erro ao verificar tamanho do arquivo: $e');
      return false;
    }
  }

  /// Gerar nome único para arquivo
  static String generateUniqueFileName(
    String inventoryBatchId,
    String productCode,
    int sequence, [
    String extension = '.jpg',
  ]) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'INV_${inventoryBatchId}_${sequence}_${productCode}_${timestamp}$extension';
  }

  /// Limpar arquivos temporários
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();

      if (await tempDir.exists()) {
        await for (final entity in tempDir.list()) {
          if (entity is File) {
            final fileName = path.basename(entity.path);

            // Remover arquivos de imagem temporários mais antigos que 1 dia
            if (fileName.startsWith('image_picker_') ||
                fileName.contains('_temp') ||
                fileName.contains('_compressed')) {
              final stat = await entity.stat();
              final age = DateTime.now().difference(stat.modified);

              if (age.inDays > 1) {
                try {
                  await entity.delete();
                  debugPrint('Arquivo temporário removido: $fileName');
                } catch (e) {
                  debugPrint('Erro ao remover arquivo temporário: $e');
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erro na limpeza de arquivos temporários: $e');
    }
  }

  /// Obter informações detalhadas da imagem
  static Future<ImageInfo?> getImageInfo(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      final dimensions = await getImageDimensions(imageFile);
      final fileName = path.basename(imageFile.path);
      final extension = path.extension(imageFile.path);

      if (dimensions != null) {
        return ImageInfo(
          fileName: fileName,
          filePath: imageFile.path,
          fileSize: fileSize,
          width: dimensions.width.toInt(),
          height: dimensions.height.toInt(),
          extension: extension,
          aspectRatio: dimensions.width / dimensions.height,
          isLandscape: dimensions.width > dimensions.height,
          mimeType: _getMimeType(extension),
        );
      }

      return null;
    } catch (e) {
      debugPrint('Erro ao obter informações da imagem: $e');
      return null;
    }
  }

  /// Obter tipo MIME baseado na extensão
  static String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.bmp':
        return 'image/bmp';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Deletar arquivo de imagem
  static Future<bool> deleteImageFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao deletar arquivo de imagem: $e');
      return false;
    }
  }

  /// Copiar arquivo para backup
  static Future<File?> backupImageFile(File originalFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/backup');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final fileName = path.basename(originalFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFileName = '${timestamp}_$fileName';

      final backupFile = File('${backupDir.path}/$backupFileName');
      return await originalFile.copy(backupFile.path);
    } catch (e) {
      debugPrint('Erro ao fazer backup da imagem: $e');
      return null;
    }
  }
}

/// Classe para informações detalhadas da imagem
class ImageInfo {
  final String fileName;
  final String filePath;
  final int fileSize;
  final int width;
  final int height;
  final String extension;
  final double aspectRatio;
  final bool isLandscape;
  final String mimeType;

  const ImageInfo({
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.width,
    required this.height,
    required this.extension,
    required this.aspectRatio,
    required this.isLandscape,
    required this.mimeType,
  });

  bool get isPortrait => !isLandscape;

  double get fileSizeInMB => fileSize / (1024 * 1024);

  String get resolution => '${width}x$height';

  @override
  String toString() {
    return 'ImageInfo(fileName: $fileName, size: ${fileSizeInMB.toStringAsFixed(2)}MB, resolution: $resolution)';
  }
}
