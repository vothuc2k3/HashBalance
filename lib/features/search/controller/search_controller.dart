import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/features/search/repository/search_repository.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/user_model.dart';

final searchCommunityProvider =
    FutureProvider.family((ref, String query) async {
  final searchRepository = ref.watch(searchRepositoryProvider);
  return searchRepository.searchCommunities(query);
});

final searchUserProvider = FutureProvider.family((ref, String query) async {
  final searchRepository = ref.watch(searchRepositoryProvider);
  return searchRepository.searchUsers(query);
});

final searchControllerProvider = Provider((ref) {
  final searchRepository = ref.watch(searchRepositoryProvider);
  return SearchController(
    searchRepository: searchRepository,
  );
});

class SearchController {
  final SearchRepository _searchRepository;

  SearchController({
    required SearchRepository searchRepository,
  }) : _searchRepository = searchRepository;

  Future<List<Community>> searchCommunities(String query) async {
    return await _searchRepository.searchCommunities(query);
  }

  Future<List<UserModel>> searchUsers(String query) async {
    return await _searchRepository.searchUsers(query);
  }
}
