import 'package:hash_balance/models/conbined_models/poll_data_model.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';

class NewsfeedCombinedModel {
  final PostDataModel? post;
  final PollDataModel? poll;

  NewsfeedCombinedModel({
    this.post,
    this.poll,
  });
}
