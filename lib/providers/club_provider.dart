import 'package:flutter/material.dart';
import '../models/club.dart';
import '../services/database_service.dart';

class ClubProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Club> _clubs = [];
  bool _isLoading = false;

  List<Club> get clubs => _clubs;
  bool get isLoading => _isLoading;

  Future<void> loadClubs() async {
    _isLoading = true;
    notifyListeners();

    try {
      _clubs = await _db.getAllClubs();
    } catch (e) {
      debugPrint('Error loading clubs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addClub(Club club) async {
    try {
      await _db.insertClub(club);
      _clubs.add(club);
      _clubs.sort((a, b) {
        int typeCompare = a.type.index.compareTo(b.type.index);
        if (typeCompare != 0) return typeCompare;
        return a.name.compareTo(b.name);
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding club: $e');
      rethrow;
    }
  }

  Future<void> updateClub(Club club) async {
    try {
      await _db.updateClub(club);
      final index = _clubs.indexWhere((c) => c.id == club.id);
      if (index != -1) {
        _clubs[index] = club;
        _clubs.sort((a, b) {
          int typeCompare = a.type.index.compareTo(b.type.index);
          if (typeCompare != 0) return typeCompare;
          return a.name.compareTo(b.name);
        });
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating club: $e');
      rethrow;
    }
  }

  Future<void> deleteClub(String id) async {
    try {
      await _db.deleteClub(id);
      _clubs.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting club: $e');
      rethrow;
    }
  }

  Club? getClubById(String id) {
    try {
      return _clubs.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Club> getClubsByType(ClubType type) {
    return _clubs.where((c) => c.type == type).toList();
  }
}