import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/features/search/repository/search_repository.dart';

final searchProvider = StreamProvider.family((ref, String query) {
  return ref.watch(searchControllerProvider.notifier).search(query);
});

final searchControllerProvider =
    StateNotifierProvider<SearchController, bool>((ref) {
  final searchRepository = ref.watch(searchRepositoryProvider);
  return SearchController(
    searchRepository: searchRepository,
    ref: ref,
  );
});

class SearchController extends StateNotifier<bool> {
  final SearchRepository _searchRepository;

  SearchController({
    required SearchRepository searchRepository,
    required Ref ref,
  })  : _searchRepository = searchRepository,
        super(false);

  //pass the query in the repo
  Stream<List<dynamic>> search(String query) {
    return _searchRepository.search(query);
  }
}
