import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';

typedef FutureEither<T> = Future<Either<Failures, T>>;
typedef FutureVoid = FutureEither<void>;
