import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/club.dart';
import '../models/bag.dart';
import '../models/session.dart';
import '../models/shot.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'range_buddy.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: _onOpen,
    );
  }

  Future<void> _onOpen(Database db) async {
    // Check if default clubs exist
    final clubs = await db.query('clubs');
    if (clubs.isEmpty) {
      await _seedDefaultClubs(db);
    }
    
    // Check if default bag exists
    final bags = await db.query('bags');
    if (bags.isEmpty) {
      await _seedDefaultBag(db);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clubs (
        id TEXT PRIMARY KEY,
        type INTEGER NOT NULL,
        name TEXT NOT NULL,
        brand TEXT,
        model TEXT,
        loft TEXT,
        shaft TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        clubIds TEXT,
        isDefault INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        location TEXT NOT NULL,
        clubIds TEXT,
        startTime TEXT NOT NULL,
        endTime TEXT,
        notes TEXT,
        weather TEXT,
        temperature TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE shots (
        id TEXT PRIMARY KEY,
        sessionId TEXT NOT NULL,
        clubId TEXT NOT NULL,
        distance REAL NOT NULL,
        shape INTEGER,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (sessionId) REFERENCES sessions (id),
        FOREIGN KEY (clubId) REFERENCES clubs (id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_shots_sessionId ON shots (sessionId)
    ''');

    await db.execute('''
      CREATE INDEX idx_shots_clubId ON shots (clubId)
    ''');
  }

  // Club operations
  Future<String> insertClub(Club club) async {
    final db = await database;
    await db.insert('clubs', club.toMap());
    return club.id;
  }

  Future<List<Club>> getAllClubs() async {
    final db = await database;
    final maps = await db.query('clubs', orderBy: 'type, name');
    return maps.map((map) => Club.fromMap(map)).toList();
  }

  Future<Club?> getClub(String id) async {
    final db = await database;
    final maps = await db.query('clubs', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Club.fromMap(maps.first);
  }

  Future<void> updateClub(Club club) async {
    final db = await database;
    await db.update('clubs', club.toMap(), where: 'id = ?', whereArgs: [club.id]);
  }

  Future<void> deleteClub(String id) async {
    final db = await database;
    await db.delete('clubs', where: 'id = ?', whereArgs: [id]);
  }

  // Bag operations
  Future<String> insertBag(Bag bag) async {
    final db = await database;
    
    // If this is set as default, unset other defaults
    if (bag.isDefault) {
      await db.update('bags', {'isDefault': 0});
    }
    
    await db.insert('bags', bag.toMap());
    return bag.id;
  }

  Future<List<Bag>> getAllBags() async {
    final db = await database;
    final maps = await db.query('bags', orderBy: 'isDefault DESC, name');
    return maps.map((map) => Bag.fromMap(map)).toList();
  }

  Future<Bag?> getBag(String id) async {
    final db = await database;
    final maps = await db.query('bags', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Bag.fromMap(maps.first);
  }

  Future<Bag?> getDefaultBag() async {
    final db = await database;
    final maps = await db.query('bags', where: 'isDefault = ?', whereArgs: [1]);
    if (maps.isEmpty) return null;
    return Bag.fromMap(maps.first);
  }

  Future<void> updateBag(Bag bag) async {
    final db = await database;
    
    // If this is set as default, unset other defaults
    if (bag.isDefault) {
      await db.update('bags', {'isDefault': 0});
    }
    
    await db.update('bags', bag.toMap(), where: 'id = ?', whereArgs: [bag.id]);
  }

  Future<void> deleteBag(String id) async {
    final db = await database;
    await db.delete('bags', where: 'id = ?', whereArgs: [id]);
  }

  // Session operations
  Future<String> insertSession(Session session) async {
    final db = await database;
    await db.insert('sessions', session.toMap());
    return session.id;
  }

  Future<List<Session>> getAllSessions() async {
    final db = await database;
    final maps = await db.query('sessions', orderBy: 'startTime DESC');
    return maps.map((map) => Session.fromMap(map)).toList();
  }

  Future<Session?> getSession(String id) async {
    final db = await database;
    final maps = await db.query('sessions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Session.fromMap(maps.first);
  }

  Future<Session?> getActiveSession() async {
    final db = await database;
    final maps = await db.query('sessions', where: 'endTime IS NULL', orderBy: 'startTime DESC', limit: 1);
    if (maps.isEmpty) return null;
    return Session.fromMap(maps.first);
  }

  Future<void> updateSession(Session session) async {
    final db = await database;
    await db.update('sessions', session.toMap(), where: 'id = ?', whereArgs: [session.id]);
  }

  Future<void> deleteSession(String id) async {
    final db = await database;
    await db.delete('shots', where: 'sessionId = ?', whereArgs: [id]);
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  // Shot operations
  Future<String> insertShot(Shot shot) async {
    final db = await database;
    await db.insert('shots', shot.toMap());
    return shot.id;
  }

  Future<List<Shot>> getShotsForSession(String sessionId) async {
    final db = await database;
    final maps = await db.query('shots', where: 'sessionId = ?', whereArgs: [sessionId], orderBy: 'createdAt DESC');
    return maps.map((map) => Shot.fromMap(map)).toList();
  }

  Future<List<Shot>> getShotsForClub(String clubId) async {
    final db = await database;
    final maps = await db.query('shots', where: 'clubId = ?', whereArgs: [clubId], orderBy: 'createdAt DESC');
    return maps.map((map) => Shot.fromMap(map)).toList();
  }

  Future<Map<String, double>> getAverageDistanceByClub() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT clubId, AVG(distance) as avgDistance
      FROM shots
      GROUP BY clubId
    ''');
    
    final Map<String, double> averages = {};
    for (final row in result) {
      averages[row['clubId'] as String] = row['avgDistance'] as double;
    }
    return averages;
  }

  Future<double?> getAverageDistanceForClub(String clubId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT AVG(distance) as avgDistance
      FROM shots
      WHERE clubId = ?
    ''', [clubId]);
    
    if (result.isEmpty || result.first['avgDistance'] == null) return null;
    return result.first['avgDistance'] as double;
  }

  Future<Map<String, double>> getSessionAverageForClub(String sessionId, String clubId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT AVG(distance) as avgDistance, COUNT(*) as shotCount
      FROM shots
      WHERE sessionId = ? AND clubId = ?
    ''', [sessionId, clubId]);
    
    if (result.isEmpty) return {'average': 0, 'count': 0};
    
    final avgDistance = result.first['avgDistance'];
    final shotCount = result.first['shotCount'];
    
    return {
      'average': avgDistance != null ? (avgDistance as num).toDouble() : 0.0,
      'count': shotCount != null ? (shotCount as num).toDouble() : 0.0,
    };
  }

  Future<void> deleteShot(String id) async {
    final db = await database;
    await db.delete('shots', where: 'id = ?', whereArgs: [id]);
  }

  // Seed default clubs based on standard driving range set
  Future<void> _seedDefaultClubs(Database db) async {
    const uuid = Uuid();
    final now = DateTime.now().toIso8601String();
    
    // Standard driving range club set - all marked as "Default" for clarity
    final defaultClubs = [
      // Driver
      {'id': uuid.v4(), 'type': 0, 'name': 'Default Driver', 'brand': 'Standard', 'loft': '10.5'},
      
      // Fairway Woods
      {'id': uuid.v4(), 'type': 1, 'name': 'Default 3 Wood', 'brand': 'Standard', 'loft': '15'},
      {'id': uuid.v4(), 'type': 1, 'name': 'Default 5 Wood', 'brand': 'Standard', 'loft': '18'},
      
      // Hybrids
      {'id': uuid.v4(), 'type': 2, 'name': 'Default 3 Hybrid', 'brand': 'Standard', 'loft': '19'},
      {'id': uuid.v4(), 'type': 2, 'name': 'Default 4 Hybrid', 'brand': 'Standard', 'loft': '22'},
      
      // Irons
      {'id': uuid.v4(), 'type': 3, 'name': 'Default 5 Iron', 'brand': 'Standard', 'loft': '24'},
      {'id': uuid.v4(), 'type': 3, 'name': 'Default 6 Iron', 'brand': 'Standard', 'loft': '27'},
      {'id': uuid.v4(), 'type': 3, 'name': 'Default 7 Iron', 'brand': 'Standard', 'loft': '31'},
      {'id': uuid.v4(), 'type': 3, 'name': 'Default 8 Iron', 'brand': 'Standard', 'loft': '35'},
      {'id': uuid.v4(), 'type': 3, 'name': 'Default 9 Iron', 'brand': 'Standard', 'loft': '40'},
      
      // Wedges
      {'id': uuid.v4(), 'type': 4, 'name': 'Default PW', 'brand': 'Standard', 'loft': '45'},
      {'id': uuid.v4(), 'type': 4, 'name': 'Default GW', 'brand': 'Standard', 'loft': '50'},
      {'id': uuid.v4(), 'type': 4, 'name': 'Default SW', 'brand': 'Standard', 'loft': '56'},
      {'id': uuid.v4(), 'type': 4, 'name': 'Default LW', 'brand': 'Standard', 'loft': '60'},
    ];
    
    for (final club in defaultClubs) {
      await db.insert('clubs', {
        ...club,
        'model': null,
        'shaft': 'Regular',
        'createdAt': now,
        'updatedAt': now,
      });
    }
  }
  
  // Seed default bag with all clubs
  Future<void> _seedDefaultBag(Database db) async {
    const uuid = Uuid();
    final now = DateTime.now().toIso8601String();
    
    // Get all default club IDs (the ones we just created)
    final clubs = await db.query('clubs', 
        columns: ['id'], 
        where: "brand = 'Standard'");
    final clubIds = clubs.map((c) => c['id'] as String).join(',');
    
    // Create default bag with all default clubs
    await db.insert('bags', {
      'id': uuid.v4(),
      'name': 'Standard Set',
      'clubIds': clubIds,
      'isDefault': 1,
      'createdAt': now,
      'updatedAt': now,
    });
  }
}