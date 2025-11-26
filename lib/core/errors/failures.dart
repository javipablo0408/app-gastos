import 'package:equatable/equatable.dart';

/// Clase base para todos los errores de la aplicación
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Error de base de datos
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});
}

/// Error de sincronización
class SyncFailure extends Failure {
  const SyncFailure(super.message, {super.code});
}

/// Error de red
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// Error de autenticación
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// Error de archivo
class FileFailure extends Failure {
  const FileFailure(super.message, {super.code});
}

/// Error de validación
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Error desconocido
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code});
}

