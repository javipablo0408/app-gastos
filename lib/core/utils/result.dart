import 'package:dartz/dartz.dart';
import 'package:app_contabilidad/core/errors/failures.dart';

/// Tipo de resultado que puede ser éxito o fallo
typedef Result<T> = Either<Failure, T>;

/// Extensión para facilitar el uso de Result
extension ResultExtension<T> on Result<T> {
  /// Obtiene el valor si es éxito, null si es fallo
  T? get valueOrNull => fold((l) => null, (r) => r);

  /// Obtiene el error si es fallo, null si es éxito
  Failure? get errorOrNull => fold((l) => l, (r) => null);

  /// Verifica si es éxito
  bool get isSuccess => isRight();

  /// Verifica si es fallo
  bool get isFailure => isLeft();
}

