import 'package:uuid/uuid.dart';

enum ShotShape {
  straight,
  draw,
  fade,
  hook,
  slice,
  push,
  pull
}

class Shot {
  final String id;
  final String sessionId;
  final String clubId;
  final double distance;
  final ShotShape? shape;
  final String? notes;
  final DateTime createdAt;

  Shot({
    String? id,
    required this.sessionId,
    required this.clubId,
    required this.distance,
    this.shape,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'clubId': clubId,
      'distance': distance,
      'shape': shape?.index,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Shot.fromMap(Map<String, dynamic> map) {
    return Shot(
      id: map['id'],
      sessionId: map['sessionId'],
      clubId: map['clubId'],
      distance: map['distance'].toDouble(),
      shape: map['shape'] != null ? ShotShape.values[map['shape']] : null,
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  static String getShotShapeDisplayName(ShotShape shape) {
    switch (shape) {
      case ShotShape.straight:
        return 'Straight';
      case ShotShape.draw:
        return 'Draw';
      case ShotShape.fade:
        return 'Fade';
      case ShotShape.hook:
        return 'Hook';
      case ShotShape.slice:
        return 'Slice';
      case ShotShape.push:
        return 'Push';
      case ShotShape.pull:
        return 'Pull';
    }
  }
}