import 'package:flutter/material.dart';
import '../models/bag.dart';
import '../models/club.dart';
import '../services/database_service.dart';
import 'club_provider.dart';

class BagProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Bag> _bags = [];
  bool _isLoading = false;

  List<Bag> get bags => _bags;
  bool get isLoading => _isLoading;
  Bag? get defaultBag => _bags.firstWhere((b) => b.isDefault, orElse: () => _bags.first);

  Future<void> loadBags() async {
    _isLoading = true;
    notifyListeners();

    try {
      _bags = await _db.getAllBags();
    } catch (e) {
      debugPrint('Error loading bags: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBag(Bag bag) async {
    try {
      await _db.insertBag(bag);
      
      if (bag.isDefault) {
        for (var b in _bags) {
          if (b.isDefault) {
            final updatedBag = b.copyWith(isDefault: false);
            final index = _bags.indexOf(b);
            _bags[index] = updatedBag;
          }
        }
      }
      
      _bags.add(bag);
      _bags.sort((a, b) {
        if (a.isDefault) return -1;
        if (b.isDefault) return 1;
        return a.name.compareTo(b.name);
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding bag: $e');
      rethrow;
    }
  }

  Future<void> updateBag(Bag bag) async {
    try {
      await _db.updateBag(bag);
      
      if (bag.isDefault) {
        for (var i = 0; i < _bags.length; i++) {
          if (_bags[i].id != bag.id && _bags[i].isDefault) {
            _bags[i] = _bags[i].copyWith(isDefault: false);
          }
        }
      }
      
      final index = _bags.indexWhere((b) => b.id == bag.id);
      if (index != -1) {
        _bags[index] = bag;
        _bags.sort((a, b) {
          if (a.isDefault) return -1;
          if (b.isDefault) return 1;
          return a.name.compareTo(b.name);
        });
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating bag: $e');
      rethrow;
    }
  }

  Future<void> deleteBag(String id) async {
    try {
      await _db.deleteBag(id);
      _bags.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting bag: $e');
      rethrow;
    }
  }

  Future<void> addClubToBag(String bagId, String clubId) async {
    final bag = _bags.firstWhere((b) => b.id == bagId);
    if (!bag.clubIds.contains(clubId)) {
      final updatedBag = bag.copyWith(clubIds: [...bag.clubIds, clubId]);
      await updateBag(updatedBag);
    }
  }

  Future<void> removeClubFromBag(String bagId, String clubId) async {
    final bag = _bags.firstWhere((b) => b.id == bagId);
    final updatedClubIds = List<String>.from(bag.clubIds)..remove(clubId);
    final updatedBag = bag.copyWith(clubIds: updatedClubIds);
    await updateBag(updatedBag);
  }

  List<Club> getClubsForBag(String bagId, ClubProvider clubProvider) {
    final bag = _bags.firstWhere((b) => b.id == bagId);
    return bag.clubIds
        .map((id) => clubProvider.getClubById(id))
        .where((club) => club != null)
        .cast<Club>()
        .toList();
  }

  Bag? getBagById(String id) {
    try {
      return _bags.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }
}