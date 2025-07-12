import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Interface for use cases
/// 
/// Type `Type` is the return type
/// Type `Params` is the input parameters type
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// No parameters class for use cases that don't require parameters
class NoParams {
  const NoParams();
}