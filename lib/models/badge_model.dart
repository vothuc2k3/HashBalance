import 'dart:convert';

class BadgeModel {
  final String id;
  final String name;
  final int threshold;
  final String description;
  final String imageUrl;
  BadgeModel({
    required this.id,
    required this.name,
    required this.threshold,
    required this.description,
    required this.imageUrl,
  });

  BadgeModel copyWith({
    String? id,
    String? name,
    int? threshold,
    String? description,
    String? imageUrl,
  }) {
    return BadgeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      threshold: threshold ?? this.threshold,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'threshold': threshold,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  factory BadgeModel.fromMap(Map<String, dynamic> map) {
    return BadgeModel(
      id: map['id'] as String,
      name: map['name'] as String,
      threshold: map['threshold'] as int,
      description: map['description'] as String,
      imageUrl: map['imageUrl'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory BadgeModel.fromJson(String source) => BadgeModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BadgeModel(id: $id, name: $name, threshold: $threshold, description: $description, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(covariant BadgeModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.name == name &&
      other.threshold == threshold &&
      other.description == description &&
      other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      threshold.hashCode ^
      description.hashCode ^
      imageUrl.hashCode;
  }
}
