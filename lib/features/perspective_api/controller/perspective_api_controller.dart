import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/features/perspective_api/repository/perspective_api_repository.dart';

final perspectiveApiControllerProvider = Provider((ref) {
  return PerspectiveApiController(
    ref.read(perspectiveApiRepositoryProvider),
  );
});

class PerspectiveApiController {
  final PerspectiveApiRepository _perspectiveApiRepository;

  PerspectiveApiController(
    this._perspectiveApiRepository,
  );

  Future<Either<Failures, String?>> isCommentSafe(String comment) async {
    return await _perspectiveApiRepository.isCommentSafe(comment);
  }
}
