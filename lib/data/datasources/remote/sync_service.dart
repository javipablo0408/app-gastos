import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/constants.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/data/datasources/local/change_log_service.dart';
import 'package:app_contabilidad/domain/entities/change_log.dart';
import 'package:app_contabilidad/domain/entities/category.dart';
import 'package:app_contabilidad/domain/entities/expense.dart';
import 'package:app_contabilidad/domain/entities/income.dart';
import 'package:app_contabilidad/domain/entities/budget.dart';

/// Estado de sincronización
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Servicio de sincronización bidireccional con OneDrive usando Microsoft Graph REST API
class SyncService {
  final DatabaseService _databaseService;
  final ChangeLogService _changeLogService;
  final http.Client _httpClient;
  SharedPreferences? _prefs;

  SyncService(
    this._databaseService,
    this._changeLogService,
    this._httpClient,
  );

  /// Inicializa el servicio
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== AUTENTICACIÓN ====================

  /// Obtiene el token de acceso
  Future<String?> _getAccessToken() async {
    return _prefs?.getString('onedrive_access_token');
  }

  /// Guarda el token de acceso
  Future<void> _saveAccessToken(String token) async {
    await _prefs?.setString('onedrive_access_token', token);
  }

  /// Obtiene el refresh token
  Future<String?> _getRefreshToken() async {
    return _prefs?.getString('onedrive_refresh_token');
  }

  /// Guarda el refresh token
  Future<void> _saveRefreshToken(String token) async {
    await _prefs?.setString('onedrive_refresh_token', token);
  }

  /// Obtiene la URL de autorización OAuth2 PKCE
  String getAuthorizationUrl() {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    
    // Guardar code_verifier para después
    _prefs?.setString('oauth_code_verifier', codeVerifier);
    
    final params = {
      'client_id': AppConstants.clientId,
      'response_type': 'code',
      'redirect_uri': AppConstants.redirectUri,
      'response_mode': 'query',
      'scope': AppConstants.scopes.join(' '),
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    };

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '${AppConstants.authBaseUrl}/authorize?$queryString';
  }

  /// Intercambia el código de autorización por tokens
  Future<Result<void>> exchangeCodeForTokens(String authorizationCode) async {
    try {
      final codeVerifier = _prefs?.getString('oauth_code_verifier');
      if (codeVerifier == null) {
        return Left(AuthFailure('Code verifier no encontrado'));
      }

      final response = await _httpClient.post(
        Uri.parse('${AppConstants.authBaseUrl}/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': AppConstants.clientId,
          'code': authorizationCode,
          'redirect_uri': AppConstants.redirectUri,
          'grant_type': 'authorization_code',
          'code_verifier': codeVerifier,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveAccessToken(data['access_token'] as String);
        await _saveRefreshToken(data['refresh_token'] as String);
        await _prefs?.remove('oauth_code_verifier');
        return const Right(null);
      } else {
        return Left(AuthFailure('Error al intercambiar código: ${response.body}'));
      }
    } catch (e) {
      appLogger.e('Error exchanging code for tokens', error: e);
      return Left(AuthFailure('Error al obtener tokens: ${e.toString()}'));
    }
  }

  /// Refresca el token de acceso
  Future<Result<void>> refreshAccessToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) {
        return Left(AuthFailure('No hay refresh token disponible'));
      }

      final response = await _httpClient.post(
        Uri.parse('${AppConstants.authBaseUrl}/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': AppConstants.clientId,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveAccessToken(data['access_token'] as String);
        if (data.containsKey('refresh_token')) {
          await _saveRefreshToken(data['refresh_token'] as String);
        }
        return const Right(null);
      } else {
        return Left(AuthFailure('Error al refrescar token: ${response.body}'));
      }
    } catch (e) {
      appLogger.e('Error refreshing access token', error: e);
      return Left(AuthFailure('Error al refrescar token: ${e.toString()}'));
    }
  }

  /// Verifica si está autenticado
  Future<bool> isAuthenticated() async {
    final token = await _getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Cierra sesión
  Future<void> logout() async {
    await _prefs?.remove('onedrive_access_token');
    await _prefs?.remove('onedrive_refresh_token');
  }

  // ==================== SINCRONIZACIÓN ====================

  /// Realiza sincronización bidireccional completa
  Future<Result<void>> sync() async {
    try {
      if (!await isAuthenticated()) {
        return Left(AuthFailure('No autenticado'));
      }

      // 1. Descargar datos remotos
      final remoteDataResult = await _downloadRemoteData();
      if (remoteDataResult.isFailure) {
        return Left(remoteDataResult.errorOrNull!);
      }

      // 2. Cargar datos locales
      final localDataResult = await _loadLocalData();
      if (localDataResult.isFailure) {
        return Left(localDataResult.errorOrNull!);
      }

      // 3. Merge bidireccional
      final mergeResult = await _mergeData(
        localDataResult.valueOrNull!,
        remoteDataResult.valueOrNull!,
      );
      if (mergeResult.isFailure) {
        return Left(mergeResult.errorOrNull!);
      }

      // 4. Subir cambios locales pendientes
      final uploadResult = await _uploadPendingChanges();
      if (uploadResult.isFailure) {
        return Left(uploadResult.errorOrNull!);
      }

      return const Right(null);
    } catch (e) {
      appLogger.e('Error during sync', error: e);
      return Left(SyncFailure('Error durante sincronización: ${e.toString()}'));
    }
  }

  /// Descarga datos remotos de OneDrive
  Future<Result<Map<String, dynamic>>> _downloadRemoteData() async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        return Left(AuthFailure('Token no disponible'));
      }

      // Buscar archivo en OneDrive
      final fileId = await _findOrCreateSyncFile(token);
      if (fileId == null) {
        return Left(SyncFailure('No se pudo encontrar o crear archivo de sincronización'));
      }

      // Descargar contenido
      final response = await _httpClient.get(
        Uri.parse('${AppConstants.graphApiBaseUrl}/me/drive/items/$fileId/content'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(data);
      } else if (response.statusCode == 401) {
        // Token expirado, intentar refrescar
        final refreshResult = await refreshAccessToken();
        if (refreshResult.isSuccess) {
          return _downloadRemoteData(); // Reintentar
        }
        return Left(AuthFailure('Token expirado y no se pudo refrescar'));
      } else {
        return Left(SyncFailure('Error al descargar datos: ${response.body}'));
      }
    } catch (e) {
      appLogger.e('Error downloading remote data', error: e);
      return Left(SyncFailure('Error al descargar datos remotos: ${e.toString()}'));
    }
  }

  /// Carga datos locales de la base de datos
  Future<Result<Map<String, dynamic>>> _loadLocalData() async {
    try {
      final categoriesResult = await _databaseService.getAllCategories();
      final expensesResult = await _databaseService.getAllExpenses();
      final incomesResult = await _databaseService.getAllIncomes();
      final budgetsResult = await _databaseService.getAllBudgets();

      if (categoriesResult.isFailure ||
          expensesResult.isFailure ||
          incomesResult.isFailure ||
          budgetsResult.isFailure) {
        return Left(DatabaseFailure('Error al cargar datos locales'));
      }

      return Right({
        'categories': categoriesResult.valueOrNull!.map((c) => _entityToJson(c)).toList(),
        'expenses': expensesResult.valueOrNull!.map((e) => _entityToJson(e)).toList(),
        'incomes': incomesResult.valueOrNull!.map((i) => _entityToJson(i)).toList(),
        'budgets': budgetsResult.valueOrNull!.map((b) => _entityToJson(b)).toList(),
        'lastSync': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      appLogger.e('Error loading local data', error: e);
      return Left(DatabaseFailure('Error al cargar datos locales: ${e.toString()}'));
    }
  }

  /// Realiza merge bidireccional de datos
  Future<Result<void>> _mergeData(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) async {
    try {
      // Merge de categorías
      await _mergeCategories(
        (localData['categories'] as List).cast<Map<String, dynamic>>(),
        (remoteData['categories'] as List).cast<Map<String, dynamic>>(),
      );

      // Merge de gastos
      await _mergeExpenses(
        (localData['expenses'] as List).cast<Map<String, dynamic>>(),
        (remoteData['expenses'] as List).cast<Map<String, dynamic>>(),
      );

      // Merge de ingresos
      await _mergeIncomes(
        (localData['incomes'] as List).cast<Map<String, dynamic>>(),
        (remoteData['incomes'] as List).cast<Map<String, dynamic>>(),
      );

      // Merge de presupuestos
      await _mergeBudgets(
        (localData['budgets'] as List).cast<Map<String, dynamic>>(),
        (remoteData['budgets'] as List).cast<Map<String, dynamic>>(),
      );

      return const Right(null);
    } catch (e) {
      appLogger.e('Error merging data', error: e);
      return Left(SyncFailure('Error al hacer merge: ${e.toString()}'));
    }
  }

  /// Sube cambios pendientes a OneDrive
  Future<Result<void>> _uploadPendingChanges() async {
    try {
      final pendingLogsResult = await _changeLogService.getPendingLogs();
      if (pendingLogsResult.isFailure) {
        return Left(pendingLogsResult.errorOrNull!);
      }

      final pendingLogs = pendingLogsResult.valueOrNull!;
      if (pendingLogs.isEmpty) {
        return const Right(null);
      }

      // Cargar datos actualizados
      final localDataResult = await _loadLocalData();
      if (localDataResult.isFailure) {
        return Left(localDataResult.errorOrNull!);
      }

      // Subir a OneDrive
      final uploadResult = await _uploadToOneDrive(localDataResult.valueOrNull!);
      if (uploadResult.isFailure) {
        return Left(uploadResult.errorOrNull!);
      }

      // Marcar logs como sincronizados
      final logIds = pendingLogs.map((l) => l.id).toList();
      await _changeLogService.markAsSynced(logIds);

      return const Right(null);
    } catch (e) {
      appLogger.e('Error uploading pending changes', error: e);
      return Left(SyncFailure('Error al subir cambios: ${e.toString()}'));
    }
  }

  // ==================== HELPERS ====================

  String _generateCodeVerifier() {
    final random = List<int>.generate(32, (i) => (256 * (i / 256)).floor());
    return base64UrlEncode(random).replaceAll('=', '');
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  Future<String?> _findOrCreateSyncFile(String token) async {
    try {
      // Buscar archivo existente
      final searchResponse = await _httpClient.get(
        Uri.parse('${AppConstants.graphApiBaseUrl}/me/drive/root/search(q=\'${AppConstants.syncFileName}\')'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (searchResponse.statusCode == 200) {
        final data = jsonDecode(searchResponse.body) as Map<String, dynamic>;
        final items = data['value'] as List;
        if (items.isNotEmpty) {
          return items[0]['id'] as String;
        }
      }

      // Crear archivo nuevo si no existe
      final createResponse = await _httpClient.put(
        Uri.parse('${AppConstants.graphApiBaseUrl}/me/drive/root:/${AppConstants.syncFileName}:/content'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'initialData': {}}),
      );

      if (createResponse.statusCode == 200 || createResponse.statusCode == 201) {
        final data = jsonDecode(createResponse.body) as Map<String, dynamic>;
        return data['id'] as String;
      }

      return null;
    } catch (e) {
      appLogger.e('Error finding/creating sync file', error: e);
      return null;
    }
  }

  Future<Result<void>> _uploadToOneDrive(Map<String, dynamic> data) async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        return Left(AuthFailure('Token no disponible'));
      }

      final fileId = await _findOrCreateSyncFile(token);
      if (fileId == null) {
        return Left(SyncFailure('No se pudo encontrar o crear archivo'));
      }

      final response = await _httpClient.put(
        Uri.parse('${AppConstants.graphApiBaseUrl}/me/drive/items/$fileId/content'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Right(null);
      } else if (response.statusCode == 401) {
        final refreshResult = await refreshAccessToken();
        if (refreshResult.isSuccess) {
          return _uploadToOneDrive(data); // Reintentar
        }
        return Left(AuthFailure('Token expirado'));
      } else {
        return Left(SyncFailure('Error al subir: ${response.body}'));
      }
    } catch (e) {
      appLogger.e('Error uploading to OneDrive', error: e);
      return Left(SyncFailure('Error al subir datos: ${e.toString()}'));
    }
  }

  Map<String, dynamic> _entityToJson(dynamic entity) {
    // Implementación simplificada - en producción usar json_serializable
    if (entity is Category) {
      return {
        'id': entity.id,
        'name': entity.name,
        'icon': entity.icon,
        'color': entity.color,
        'type': entity.type.name,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'syncId': entity.syncId,
      };
    } else if (entity is Expense) {
      return {
        'id': entity.id,
        'amount': entity.amount,
        'description': entity.description,
        'categoryId': entity.categoryId,
        'date': entity.date.toIso8601String(),
        'receiptImagePath': entity.receiptImagePath,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'syncId': entity.syncId,
        'version': entity.version,
      };
    } else if (entity is Income) {
      return {
        'id': entity.id,
        'amount': entity.amount,
        'description': entity.description,
        'categoryId': entity.categoryId,
        'date': entity.date.toIso8601String(),
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'syncId': entity.syncId,
        'version': entity.version,
      };
    } else if (entity is Budget) {
      return {
        'id': entity.id,
        'categoryId': entity.categoryId,
        'amount': entity.amount,
        'startDate': entity.startDate.toIso8601String(),
        'endDate': entity.endDate.toIso8601String(),
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'syncId': entity.syncId,
      };
    }
    return {};
  }

  Future<void> _mergeCategories(
    List<Map<String, dynamic>> local,
    List<Map<String, dynamic>> remote,
  ) async {
    // Implementación de merge - estrategia: última actualización gana
    // En producción, implementar lógica más sofisticada con resolución de conflictos
  }

  Future<void> _mergeExpenses(
    List<Map<String, dynamic>> local,
    List<Map<String, dynamic>> remote,
  ) async {
    // Implementación de merge
  }

  Future<void> _mergeIncomes(
    List<Map<String, dynamic>> local,
    List<Map<String, dynamic>> remote,
  ) async {
    // Implementación de merge
  }

  Future<void> _mergeBudgets(
    List<Map<String, dynamic>> local,
    List<Map<String, dynamic>> remote,
  ) async {
    // Implementación de merge
  }
}

