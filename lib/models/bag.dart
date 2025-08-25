import 'package:uuid/uuid.dart';
import 'club.dart';

class Bag {
  final String id;
  final String name;
  final List<String> clubIds;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bag({
    String? id,
    required this.name,
    List<String>? clubIds,
    this.isDefault = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        clubIds = clubIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'clubIds': clubIds.join(','),
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Bag.fromMap(Map<String, dynamic> map) {
    return Bag(
      id: map['id'],
      name: map['name'],
      clubIds: map['clubIds'] != null && map['clubIds'].toString().isNotEmpty
          ? map['clubIds'].toString().split(',')
          : [],
      isDefault: map['isDefault'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Bag copyWith({
    String? id,
    String? name,
    List<String>? clubIds,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bag(
      id: id ?? this.id,
      name: name ?? this.name,
      clubIds: clubIds ?? this.clubIds,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}