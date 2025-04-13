import 'package:my_rootstock_wallet/entities/transaction_helper.dart';
import 'package:my_rootstock_wallet/entities/user_helper.dart';
import 'package:my_rootstock_wallet/entities/wallet_helper.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../util/util.dart';

class EntityHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future close() async {
    database;
    final db = _database;
    _database = null;
    return db?.close();
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), DATA_BASE_NAME);
    return openDatabase(path, version: DATA_BASE_VERSION, onCreate: (db, version) {
      db.execute(TransactionHelper.scriptCreation());
      db.execute(WalletHelper.scriptCreation());
      db.execute(UserHelper.scriptCreation());
    });
  }
}
