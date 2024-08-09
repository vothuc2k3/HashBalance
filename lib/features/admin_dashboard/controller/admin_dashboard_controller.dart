import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/admin_dashboard/repository/admin_dashboard_repository.dart';

final getTodayPostsCountProvider =
    StreamProvider.family((ref, String communityId) {
  return ref
      .watch(adminDashboardControllerProvider.notifier)
      .getTodayPostsCountByHour(communityId);
});

final adminDashboardControllerProvider = StateNotifierProvider((ref) =>
    AdminDashboardController(
        adminDashboardRepository: ref.watch(adminDashboardRepositoryProvider),
        ref: ref));

class AdminDashboardController extends StateNotifier<bool> {
  final AdminDashboardRepository _adminDashboardRepository;

  AdminDashboardController({
    required AdminDashboardRepository adminDashboardRepository,
    required Ref ref,
  })  : _adminDashboardRepository = adminDashboardRepository,
        super(false);

  Stream<Map<int, int>> getTodayPostsCountByHour(String communityId) {
    return _adminDashboardRepository.getTodayPostsCountByHour(communityId);
  }
}
