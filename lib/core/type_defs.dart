import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/models/post.dart';
import 'package:hash_balance/models/user.dart';

typedef FutureEither<T> = Future<Either<Failures, T>>;
typedef FutureVoid = FutureEither<void>;
typedef FutureString = FutureEither<String>;
typedef FutureBool = FutureEither<bool>;
typedef FutureUserModel = FutureEither<UserModel>;
typedef FuturePost = FutureEither<Post>;
