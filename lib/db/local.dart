import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/data_model.dart';

class sqliteDB {
  sqliteDB._();
  static final sqliteDB dataBase = sqliteDB._();    //SINGLETON
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await initDataBase();
    return _database!;
  }

  initDataBase() async {
    return await openDatabase(
      join(await getDatabasesPath(), "password_manager_db.db"),
      onCreate: (db, version) {
        db.execute('''
        CREATE TABLE userData (id INTEGER PRIMARY KEY AUTOINCREMENT, site TEXT, user TEXT, password TEXT)
       ''');
      },
      version: 1,
    );
  }

  addNewData(Data newData) async {
    final db = await database;
    db.insert("userData", newData.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  addNewDataFromMap(Map<String, dynamic> newData) async {
    final db = await database;
    db.insert("userData", newData,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<dynamic> getData() async {
    final db = await database;
    var res = await db.rawQuery("SELECT id, site, user FROM userData");
    if (res.isEmpty) {
      return Null;
    } else {
      var resultMap = res.toList();
      return resultMap.isNotEmpty ? resultMap : Null;
    }
  }

  Future<String> queryPassword(int id) async{
    final db = await database;
    var res = await db.rawQuery("SELECT password FROM userData WHERE id=?", ["$id"]);

    return (res[0]['password'].toString());
  }

  Future<int> updateData(Map<String, dynamic> row) async {
    final db = await database;
    var id = row['id'];

    return await db.update("userData", row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteData(int id) async{
    final db = await database;
    return await db.delete("userData", where: 'id = ?', whereArgs: [id]);
  }
}
