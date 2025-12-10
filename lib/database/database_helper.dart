import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:landmark_records/models/landmark.dart';

class DatabaseHelper {
  static const _databaseName = "Landmark.db";
  static const _databaseVersion = 1;

  static const table = 'landmarks';
  
  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnLat = 'lat';
  static const columnLon = 'lon';
  static const columnImage = 'image';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId TEXT PRIMARY KEY,
            $columnTitle TEXT NOT NULL,
            $columnLat REAL NOT NULL,
            $columnLon REAL NOT NULL,
            $columnImage TEXT NOT NULL
          )
          ''');
  }

  Future<int> insertLandmark(Landmark landmark) async {
    Database db = await instance.database;
    return await db.insert(table, {
      columnId: landmark.id,
      columnTitle: landmark.title,
      columnLat: landmark.lat,
      columnLon: landmark.lon,
      columnImage: landmark.image
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Landmark>> getLandmarks() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(table);
    return List.generate(maps.length, (i) {
      return Landmark.fromJson(maps[i]);
    });
  }

  Future<void> clearLandmarks() async {
    Database db = await instance.database;
    await db.delete(table);
  }
}
