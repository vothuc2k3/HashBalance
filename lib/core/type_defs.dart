import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/models/user_model.dart';

typedef FutureEither<T> = Future<Either<Failures, T>>;
typedef FutureVoid = FutureEither<void>;
typedef FutureString = FutureEither<String>;
typedef FutureUserModel = FutureEither<UserModel>;
