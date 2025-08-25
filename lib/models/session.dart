import 'package:uuid/uuid.dart';

class Session {
  final String id;
  final String location;
  final List<String> clubIds;
  final DateTime startTime;
  final DateTime? endTime;
  final String? notes;
  final String? weather;
  final String? temperature;
  final DateTime createdAt;
  final DateTime updatedAt;

  Session({
    String? id,
    required this.location,
    List<String>? clubIds,
    DateTime? startTime,
    this.endTime,
    this.notes,
    this.weather,
    this.temperature,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        clubIds = clubIds ?? [],
        startTime = startTime ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'location': location,
      'clubIds': clubIds.join(','),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'notes': notes,
      'weather': weather,
      'temperature': temperature,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'],
      location: map['location'],
      clubIds: map['clubIds'] != null && map['clubIds'].toString().isNotEmpty
          ? map['clubIds'].toString().split(',')
          : [],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      notes: map['notes'],
      weather: map['weather'],
      temperature: map['temperature'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Session copyWith({
    String? id,
    String? location,
    List<String>? clubIds,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    String? weather,
    String? temperature,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Session(
      id: id ?? this.id,
      location: location ?? this.location,
      clubIds: clubIds ?? this.clubIds,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      weather: weather ?? this.weather,
      temperature: temperature ?? this.temperature,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  bool get isActive => endTime == null;
}