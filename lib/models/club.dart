import 'package:uuid/uuid.dart';

enum ClubType {
  driver,
  fairwayWood,
  hybrid,
  iron,
  wedge,
  putter
}

class Club {
  final String id;
  final ClubType type;
  final String name;
  final String? brand;
  final String? model;
  final String? loft;
  final String? shaft;
  final DateTime createdAt;
  final DateTime updatedAt;

  Club({
    String? id,
    required this.type,
    required this.name,
    this.brand,
    this.model,
    this.loft,
    this.shaft,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'name': name,
      'brand': brand,
      'model': model,
      'loft': loft,
      'shaft': shaft,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Club.fromMap(Map<String, dynamic> map) {
    return Club(
      id: map['id'],
      type: ClubType.values[map['type']],
      name: map['name'],
      brand: map['brand'],
      model: map['model'],
      loft: map['loft'],
      shaft: map['shaft'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Club copyWith({
    String? id,
    ClubType? type,
    String? name,
    String? brand,
    String? model,
    String? loft,
    String? shaft,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Club(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      loft: loft ?? this.loft,
      shaft: shaft ?? this.shaft,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  String get displayName {
    if (brand != null && model != null) {
      return '$brand $model';
    }
    return name;
  }

  static String getClubTypeDisplayName(ClubType type) {
    switch (type) {
      case ClubType.driver:
        return 'Driver';
      case ClubType.fairwayWood:
        return 'Fairway Wood';
      case ClubType.hybrid:
        return 'Hybrid';
      case ClubType.iron:
        return 'Iron';
      case ClubType.wedge:
        return 'Wedge';
      case ClubType.putter:
        return 'Putter';
    }
  }
}