import 'dart:convert';

class ArchivedConversationModel {
  final String id;
  final String conversationId;
  final String archivedBy;

  ArchivedConversationModel({
    required this.id,
    required this.conversationId,
    required this.archivedBy,
  });

  ArchivedConversationModel copyWith({
    String? id,
    String? conversationId,
    String? archivedBy,
  }) {
    return ArchivedConversationModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      archivedBy: archivedBy ?? this.archivedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'conversationId': conversationId,
      'archivedBy': archivedBy,
    };
  }

  factory ArchivedConversationModel.fromMap(Map<String, dynamic> map) {
    return ArchivedConversationModel(
      id: map['id'] as String,
      conversationId: map['conversationId'] as String,
      archivedBy: map['archivedBy'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory ArchivedConversationModel.fromJson(String source) => ArchivedConversationModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'ArchivedConversationModel(id: $id, conversationId: $conversationId, archivedBy: $archivedBy)';

  @override
  bool operator ==(covariant ArchivedConversationModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.conversationId == conversationId &&
      other.archivedBy == archivedBy;
  }

  @override
  int get hashCode => id.hashCode ^ conversationId.hashCode ^ archivedBy.hashCode;
}
