import 'package:hash_balance/models/block_model.dart';
import 'package:hash_balance/models/user_model.dart';

class BlockDataModel {
  final BlockModel block;
  final UserModel user;
  BlockDataModel({
    required this.block,
    required this.user,
  });
}
