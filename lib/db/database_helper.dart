import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final _databaseName = "CoffeeMemo.db";
  static final _databaseVersion = 1;

  final List<String> coffeebeansColumns = [
    'id',
    'name',
    'store',
    'description', 
    'imagePath',
    'purchaseDate',
    'updateDate',
    'price',
    'purchasedGrams',
    'origin',
    'farmName',
    'variety',
    'process', 
    'roastLevel',
    'body',
    'acidity',
    'story',
  ];
  final List<String> journalColumns = [
    'id',
    'usedBeans',
    'imagePath',
    'deviceUsed',
    'brewDate',
    'brewMethods', 
    'updateDate',
    'overallScore',
    'overallMemo',
    'acidityScore',
    'acidityMemo',
    'aromaScore',
    'aromaMemo',
    'bitternessScore',
    'bitternessMemo',
    'bodyScore',
    'bodyMemo',
    'sweetnessScore',
    'sweetnessMemo',
  ];

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    // deleteDatabase(join(await getDatabasesPath(), _databaseName));
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
  CREATE TABLE CoffeeBeansTable (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    store TEXT,
    description TEXT, 
    imagePath TEXT,
    purchaseDate TEXT,
    updateDate TEXT,
    price REAL,
    purchasedGrams INTEGER,
    origin TEXT,
    farmName TEXT,
    variety TEXT,
    process TEXT, 
    roastLevel INTEGER,
    body INTEGER,
    acidity INTEGER,
    story TEXT
  )
''');

    await db.execute('''
  CREATE TABLE JournalTable (
    id INTEGER PRIMARY KEY,
    usedBeans INTEGER, 
    imagePath TEXT,
    deviceUsed TEXT,
    brewDate TEXT,
    brewMethods TEXT,
    updateDate TEXT, 
    overallScore INTEGER,
    overallMemo TEXT,
    acidityScore INTEGER,
    acidityMemo TEXT,
    aromaScore INTEGER,
    aromaMemo TEXT,
    bitternessScore INTEGER,
    bitternessMemo TEXT,
    bodyScore INTEGER,
    bodyMemo TEXT,
    sweetnessScore INTEGER,
    sweetnessMemo TEXT
  )
''');
  }

  Future<int> insert(String tablename, Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tablename, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows(String tablename) async {
    Database db = await instance.database;
    return await db.query(tablename);
  }

  Future<Map<String, dynamic>> queryItemById(String tablename, int id) async {
    Database db = await instance.database;
    List<Map> maps = await db.query(
      tablename,
      columns: tablename == 'CoffeeBeansTable'
          ? coffeebeansColumns
          : journalColumns, // テーブルに応じてカラムを選択
      where: 'id = ?', // カラム名を直接指定
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first.map<String, dynamic>(
          (key, value) => MapEntry(key.toString(), value));
    } else {
      throw Exception('ID $id のアイテムが見つかりませんでした。');
    }
  }

  Future<int> update(String tablename, Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = int.tryParse(row['id'].toString()) ?? -1;
    // int id = row['id'];
    return await db.update(tablename, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String tablename, int id) async {
    Database db = await instance.database;
    return await db.delete(tablename, where: 'id = ?', whereArgs: [id]);
  }
  Future<List<Map<String, dynamic>>> queryRecentActivities(int itemId) async {
    Database db = await instance.database;
    return await db.query(
      'JournalTable',
      where: 'usedBeans = ?',
      whereArgs: [itemId],
      orderBy: 'brewDate DESC',
      limit: 5,
        );
  }
}
