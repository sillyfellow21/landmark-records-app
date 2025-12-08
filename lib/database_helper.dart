import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:landmark_records/landmark.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('landmarks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE landmarks (
  id $idType,
  title $textType,
  lat $doubleType,
  lon $doubleType,
  image $textType
)
''');
  }

  Future<void> insertLandmark(Landmark landmark) async {
    final db = await instance.database;
    await db.insert('landmarks', landmark.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Landmark>> getLandmarks() async {
    final db = await instance.database;
    final maps = await db.query('landmarks');

    if (maps.isNotEmpty) {
      return maps.map((json) => Landmark.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  Future<void> clearLandmarks() async {
    final db = await instance.database;
    await db.delete('landmarks');
  }
}

extension on Landmark {
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'lat': lat,
    'lon': lon,
    'image': image,
  };
}
