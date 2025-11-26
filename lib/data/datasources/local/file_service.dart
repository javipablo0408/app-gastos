import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

/// Servicio para gestión de archivos (imágenes de tickets, etc.)
class FileService {
  final ImagePicker _imagePicker = ImagePicker();

  /// Obtiene el directorio de documentos de la app
  Future<Result<Directory>> _getAppDocumentsDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final appDir = Directory(p.join(directory.path, 'app_contabilidad'));
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      return Right(appDir);
    } catch (e) {
      appLogger.e('Error getting app documents directory', error: e);
      return Left(FileFailure('Error al obtener directorio de documentos: ${e.toString()}'));
    }
  }

  /// Obtiene el directorio de imágenes
  Future<Result<Directory>> _getImagesDirectory() async {
    final appDirResult = await _getAppDocumentsDirectory();
    return appDirResult.fold(
      (failure) => Left(failure),
      (appDir) async {
        try {
          final imagesDir = Directory(p.join(appDir.path, 'images'));
          if (!await imagesDir.exists()) {
            await imagesDir.create(recursive: true);
          }
          return Right(imagesDir);
        } catch (e) {
          appLogger.e('Error creating images directory', error: e);
          return Left(FileFailure('Error al crear directorio de imágenes: ${e.toString()}'));
        }
      },
    );
  }

  /// Obtiene el directorio de documentos/facturas
  Future<Result<Directory>> _getDocumentsDirectory() async {
    final appDirResult = await _getAppDocumentsDirectory();
    return appDirResult.fold(
      (failure) => Left(failure),
      (appDir) async {
        try {
          final docsDir = Directory(p.join(appDir.path, 'documents'));
          if (!await docsDir.exists()) {
            await docsDir.create(recursive: true);
          }
          return Right(docsDir);
        } catch (e) {
          appLogger.e('Error creating documents directory', error: e);
          return Left(FileFailure('Error al crear directorio de documentos: ${e.toString()}'));
        }
      },
    );
  }

  /// Selecciona una imagen de la galería
  Future<Result<String>> pickImageFromGallery() async {
    try {
      // Verificar permisos
      final permissionResult = await _requestStoragePermission();
      if (permissionResult.isFailure) {
        return Left(permissionResult.errorOrNull!);
      }

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: AppConstants.imageQuality,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null) {
        return Left(FileFailure('No se seleccionó ninguna imagen'));
      }

      // Guardar y comprimir la imagen
      return await saveAndCompressImage(pickedFile.path);
    } catch (e) {
      appLogger.e('Error picking image from gallery', error: e);
      return Left(FileFailure('Error al seleccionar imagen: ${e.toString()}'));
    }
  }

  /// Toma una foto con la cámara
  Future<Result<String>> takePhotoWithCamera() async {
    try {
      // Verificar permisos
      final cameraPermission = await Permission.camera.request();
      if (!cameraPermission.isGranted) {
        return Left(FileFailure('Permiso de cámara denegado'));
      }

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: AppConstants.imageQuality,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null) {
        return Left(FileFailure('No se tomó ninguna foto'));
      }

      // Guardar y comprimir la imagen
      return await saveAndCompressImage(pickedFile.path);
    } catch (e) {
      appLogger.e('Error taking photo', error: e);
      return Left(FileFailure('Error al tomar foto: ${e.toString()}'));
    }
  }

  /// Guarda y comprime una imagen
  Future<Result<String>> saveAndCompressImage(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return Left(FileFailure('El archivo fuente no existe'));
      }

      // Verificar tamaño
      final fileSize = await sourceFile.length();
      if (fileSize > AppConstants.maxImageSize) {
        return Left(FileFailure('La imagen es demasiado grande (máximo ${AppConstants.maxImageSize ~/ 1024 ~/ 1024}MB)'));
      }

      // Leer y decodificar imagen
      final imageBytes = await sourceFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        return Left(FileFailure('No se pudo decodificar la imagen'));
      }

      // Comprimir si es necesario
      if (fileSize > 1024 * 1024) { // Si es mayor a 1MB
        image = img.copyResize(
          image,
          width: image.width > 1920 ? 1920 : null,
          height: image.height > 1920 ? 1920 : null,
          maintainAspect: true,
        );
      }

      // Codificar como JPEG con calidad
      final compressedBytes = img.encodeJpg(image, quality: AppConstants.imageQuality);

      // Guardar en directorio de imágenes
      final imagesDirResult = await _getImagesDirectory();
      return imagesDirResult.fold(
        (failure) => Left(failure),
        (imagesDir) async {
          try {
            final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
            final targetPath = p.join(imagesDir.path, fileName);
            final targetFile = File(targetPath);
            await targetFile.writeAsBytes(compressedBytes);
            return Right(targetPath);
          } catch (e) {
            appLogger.e('Error saving compressed image', error: e);
            return Left(FileFailure('Error al guardar imagen: ${e.toString()}'));
          }
        },
      );
    } catch (e) {
      appLogger.e('Error compressing image', error: e);
      return Left(FileFailure('Error al comprimir imagen: ${e.toString()}'));
    }
  }

  /// Lee una imagen como bytes
  Future<Result<Uint8List>> readImageAsBytes(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return Left(FileFailure('El archivo no existe'));
      }
      final bytes = await file.readAsBytes();
      return Right(bytes);
    } catch (e) {
      appLogger.e('Error reading image', error: e);
      return Left(FileFailure('Error al leer imagen: ${e.toString()}'));
    }
  }

  /// Elimina una imagen
  Future<Result<void>> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
      return const Right(null);
    } catch (e) {
      appLogger.e('Error deleting image', error: e);
      return Left(FileFailure('Error al eliminar imagen: ${e.toString()}'));
    }
  }

  /// Verifica si un archivo existe
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el tamaño de un archivo
  Future<Result<int>> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return Left(FileFailure('El archivo no existe'));
      }
      final size = await file.length();
      return Right(size);
    } catch (e) {
      appLogger.e('Error getting file size', error: e);
      return Left(FileFailure('Error al obtener tamaño del archivo: ${e.toString()}'));
    }
  }

  /// Solicita permisos de almacenamiento
  Future<Result<void>> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (status.isGranted || status.isLimited) {
          return const Right(null);
        }
        return Left(FileFailure('Permiso de almacenamiento denegado'));
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request();
        if (status.isGranted || status.isLimited) {
          return const Right(null);
        }
        return Left(FileFailure('Permiso de fotos denegado'));
      }
      return const Right(null);
    } catch (e) {
      appLogger.e('Error requesting storage permission', error: e);
      return Left(FileFailure('Error al solicitar permisos: ${e.toString()}'));
    }
  }

  /// Selecciona un archivo PDF de factura
  Future<Result<String>> pickPDFFile() async {
    try {
      final permissionResult = await _requestStoragePermission();
      if (permissionResult.isFailure) {
        return Left(permissionResult.errorOrNull!);
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return Left(FileFailure('No se seleccionó ningún archivo'));
      }

      final pickedFile = result.files.single;
      if (pickedFile.path == null) {
        return Left(FileFailure('No se pudo obtener la ruta del archivo'));
      }

      // Copiar el archivo al directorio de documentos de la app
      final sourceFile = File(pickedFile.path!);
      if (!await sourceFile.exists()) {
        return Left(FileFailure('El archivo seleccionado no existe'));
      }

      // Verificar tamaño (máximo 10MB)
      final fileSize = await sourceFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        return Left(FileFailure('El archivo es demasiado grande (máximo 10MB)'));
      }

      final docsDirResult = await _getDocumentsDirectory();
      return docsDirResult.fold(
        (failure) => Left(failure),
        (docsDir) async {
          try {
            final fileName = 'bill_${DateTime.now().millisecondsSinceEpoch}.pdf';
            final targetPath = p.join(docsDir.path, fileName);
            final targetFile = File(targetPath);
            await sourceFile.copy(targetPath);
            return Right(targetPath);
          } catch (e) {
            appLogger.e('Error copying PDF file', error: e);
            return Left(FileFailure('Error al guardar archivo: ${e.toString()}'));
          }
        },
      );
    } catch (e) {
      appLogger.e('Error picking PDF file', error: e);
      return Left(FileFailure('Error al seleccionar archivo PDF: ${e.toString()}'));
    }
  }

  /// Elimina un archivo PDF
  Future<Result<void>> deletePDFFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      return const Right(null);
    } catch (e) {
      appLogger.e('Error deleting PDF file', error: e);
      return Left(FileFailure('Error al eliminar archivo PDF: ${e.toString()}'));
    }
  }

  /// Limpia archivos antiguos (más de 30 días sin usar)
  Future<Result<void>> cleanOldFiles() async {
    try {
      final imagesDirResult = await _getImagesDirectory();
      return imagesDirResult.fold(
        (failure) => Left(failure),
        (imagesDir) async {
          try {
            final now = DateTime.now();
            final files = imagesDir.listSync();
            int deletedCount = 0;

            for (final file in files) {
              if (file is File) {
                final stat = await file.stat();
                final age = now.difference(stat.modified);
                if (age.inDays > 30) {
                  await file.delete();
                  deletedCount++;
                }
              }
            }

            appLogger.i('Cleaned $deletedCount old files');
            return const Right(null);
          } catch (e) {
            appLogger.e('Error cleaning old files', error: e);
            return Left(FileFailure('Error al limpiar archivos antiguos: ${e.toString()}'));
          }
        },
      );
    } catch (e) {
      appLogger.e('Error in cleanOldFiles', error: e);
      return Left(FileFailure('Error al limpiar archivos: ${e.toString()}'));
    }
  }
}

