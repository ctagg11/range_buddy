import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/shot.dart';
import '../services/database_service.dart';

class SessionProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  Session? _activeSession;
  List<Session> _sessions = [];
  List<Shot> _currentSessionShots = [];
  Map<String, double> _clubAverages = {};
  Map<String, Map<String, double>> _sessionClubStats = {};
  bool _isLoading = false;

  Session? get activeSession => _activeSession;
  List<Session> get sessions => _sessions;
  List<Shot> get currentSessionShots => _currentSessionShots;
  Map<String, double> get clubAverages => _clubAverages;
  Map<String, Map<String, double>> get sessionClubStats => _sessionClubStats;
  bool get isLoading => _isLoading;

  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _sessions = await _db.getAllSessions();
      _activeSession = await _db.getActiveSession();
      if (_activeSession != null) {
        await loadSessionShots(_activeSession!.id);
      }
      await loadClubAverages();
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startSession(Session session) async {
    try {
      // End any active session first
      if (_activeSession != null) {
        await endSession();
      }
      
      final sessionId = await _db.insertSession(session);
      _activeSession = session;
      _sessions.insert(0, session);
      _currentSessionShots = [];
      _sessionClubStats = {};
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting session: $e');
      rethrow;
    }
  }

  Future<void> endSession() async {
    if (_activeSession == null) return;

    try {
      final endedSession = _activeSession!.copyWith(endTime: DateTime.now());
      await _db.updateSession(endedSession);
      
      final index = _sessions.indexWhere((s) => s.id == _activeSession!.id);
      if (index != -1) {
        _sessions[index] = endedSession;
      }
      
      _activeSession = null;
      _currentSessionShots = [];
      _sessionClubStats = {};
      notifyListeners();
    } catch (e) {
      debugPrint('Error ending session: $e');
      rethrow;
    }
  }

  Future<void> addShot(Shot shot) async {
    try {
      await _db.insertShot(shot);
      _currentSessionShots.insert(0, shot);
      
      // Update session stats for this club
      await _updateSessionClubStats(shot.sessionId, shot.clubId);
      
      // Update overall club averages
      await loadClubAverages();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding shot: $e');
      rethrow;
    }
  }

  Future<void> deleteShot(String shotId) async {
    try {
      final shot = _currentSessionShots.firstWhere((s) => s.id == shotId);
      await _db.deleteShot(shotId);
      _currentSessionShots.removeWhere((s) => s.id == shotId);
      
      // Update stats
      await _updateSessionClubStats(shot.sessionId, shot.clubId);
      await loadClubAverages();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting shot: $e');
      rethrow;
    }
  }

  Future<void> loadSessionShots(String sessionId) async {
    try {
      _currentSessionShots = await _db.getShotsForSession(sessionId);
      
      // Load stats for each club in the session
      if (_activeSession != null) {
        for (final clubId in _activeSession!.clubIds) {
          await _updateSessionClubStats(sessionId, clubId);
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading session shots: $e');
    }
  }

  Future<void> loadClubAverages() async {
    try {
      _clubAverages = await _db.getAverageDistanceByClub();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading club averages: $e');
    }
  }

  Future<void> _updateSessionClubStats(String sessionId, String clubId) async {
    try {
      final stats = await _db.getSessionAverageForClub(sessionId, clubId);
      _sessionClubStats[clubId] = stats;
    } catch (e) {
      debugPrint('Error updating session club stats: $e');
    }
  }

  double? getSessionAverageForClub(String clubId) {
    return _sessionClubStats[clubId]?['average'];
  }

  int getSessionShotCountForClub(String clubId) {
    return _sessionClubStats[clubId]?['count']?.toInt() ?? 0;
  }

  double? getOverallAverageForClub(String clubId) {
    return _clubAverages[clubId];
  }

  List<Shot> getShotsForClub(String clubId) {
    return _currentSessionShots.where((s) => s.clubId == clubId).toList();
  }
}