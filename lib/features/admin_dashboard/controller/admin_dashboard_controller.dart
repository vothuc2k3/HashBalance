import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/features/admin_dashboard/repository/admin_dashboard_repository.dart';
import 'package:hash_balance/models/report_model.dart';

final adminReportsProvider = StreamProvider((ref) {
  return ref.watch(adminDashboardControllerProvider.notifier).getReports();
});

final topActiveUsersProvider = FutureProvider((ref) {
  return ref
      .watch(adminDashboardControllerProvider.notifier)
      .getTopActiveUsers();
});

final trendingHashtagsProvider = FutureProvider((ref) {
  return ref
      .watch(adminDashboardControllerProvider.notifier)
      .getTrendingHashtags();
});

final reportsCountProvider = StreamProvider<int>((ref) {
  return ref.watch(adminDashboardControllerProvider.notifier).getReportsCount();
});

final postsCountProvider = StreamProvider<int>((ref) {
  return ref.watch(adminDashboardControllerProvider.notifier).getPostsCount();
});

final usersCountProvider = StreamProvider<int>((ref) {
  return ref.watch(adminDashboardControllerProvider.notifier).getUsersCount();
});

final commentsCountProvider = StreamProvider<int>((ref) {
  return ref
      .watch(adminDashboardControllerProvider.notifier)
      .getCommentsCount();
});

final adminDashboardControllerProvider = StateNotifierProvider(
  (ref) => AdminDashboardController(
    adminDashboardRepository: ref.read(adminDashboardRepositoryProvider),
    ref: ref,
  ),
);

class AdminDashboardController extends StateNotifier<bool> {
  final AdminDashboardRepository _adminDashboardRepository;

  AdminDashboardController({
    required AdminDashboardRepository adminDashboardRepository,
    required Ref ref,
  })  : _adminDashboardRepository = adminDashboardRepository,
        super(false);

  Stream<int> getUsersCount() {
    return _adminDashboardRepository.getUsersCount();
  }

  Stream<int> getPostsCount() {
    return _adminDashboardRepository.getPostsCount();
  }

  Stream<int> getCommentsCount() {
    return _adminDashboardRepository.getCommentsCount();
  }

  Stream<int> getReportsCount() {
    return _adminDashboardRepository.getReportsCount();
  }

  Future<List<Map<String, dynamic>>> getTrendingHashtags() async {
    return await _adminDashboardRepository.getTrendingHashtags();
  }

  Future<List<Map<String, dynamic>>> getTopActiveUsers() async {
    return await _adminDashboardRepository.getTopActiveUsers();
  }

  Future<Either<Failures, void>> disableUserAccount(String uid) async {
    return await _adminDashboardRepository.disableUserAccount(uid);
  }

  Stream<Either<Failures, List<Report>>> getReports() {
    return _adminDashboardRepository.getReports();
  }


}
