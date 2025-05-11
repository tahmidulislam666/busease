import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'busease.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS bus_routes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bus_name TEXT,
            service_type TEXT,
            image TEXT,
            stops TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertBusRoute(String name, String serviceType, String image, List<String> stops) async {
    final db = await database;
    await db.insert(
      'bus_routes',
      {
        'bus_name': name,
        'service_type': serviceType,
        'image': image,
        'stops': stops.join(','), // Store stops as CSV
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> searchBusRoutes(String start, String end) async {
    final db = await database;
    
    // Ensuring the database does not lock
    try {
      List<Map<String, dynamic>> results = await db.query(
        'bus_routes',
        where: "stops LIKE ? AND stops LIKE ?",
        whereArgs: ['%$start%', '%$end%'],
      );
      return results;
    } catch (e) {
      print("❌ Database Query Error: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchBusesByName(String query) async {
    final db = await database;
    return await db.query(
      'bus_routes',
      where: 'bus_name LIKE ? OR service_type LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
  }
}
