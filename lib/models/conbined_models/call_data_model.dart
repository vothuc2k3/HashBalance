import 'dart:convert';

import 'package:hash_balance/models/call_model.dart';
import 'package:hash_balance/models/user_model.dart';

class CallDataModel {
  final Call call;
  final UserModel caller;
  final UserModel receiver;
  CallDataModel({
    required this.call,
    required this.caller,
    required this.receiver,
  });

  CallDataModel copyWith({
    Call? call,
    UserModel? caller,
    UserModel? receiver,
  }) {
    return CallDataModel(
      call: call ?? this.call,
      caller: caller ?? this.caller,
      receiver: receiver ?? this.receiver,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'call': call.toMap(),
      'caller': caller.toMap(),
      'receiver': receiver.toMap(),
    };
  }

  factory CallDataModel.fromMap(Map<String, dynamic> map) {
    return CallDataModel(
      call: Call.fromMap(map['call'] as Map<String,dynamic>),
      caller: UserModel.fromMap(map['caller'] as Map<String,dynamic>),
      receiver: UserModel.fromMap(map['receiver'] as Map<String,dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory CallDataModel.fromJson(String source) => CallDataModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'CallDataModel(call: $call, caller: $caller, receiver: $receiver)';

  @override
  bool operator ==(covariant CallDataModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.call == call &&
      other.caller == caller &&
      other.receiver == receiver;
  }

  @override
  int get hashCode => call.hashCode ^ caller.hashCode ^ receiver.hashCode;
}
