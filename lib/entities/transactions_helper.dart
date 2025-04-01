// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

class DatabaseHelper {
  // static final _databaseName = "myDatabase.db";
  // static final _databaseVersion = 1;
  //
  // static final table = 'transactions';
  // static final transactionId = 'transactionId';
  // static final walletId = 'walletId';
  // static final amountInWeis = 'amountInWeis';
  // static final valueInUsdFormatted = 'valueInUsdFormatted';
  // static final valueinWeiFormatted = 'valueinWeiFormatted';
  // static final date = 'date';
  // static final status = 'status';
  //
  // // make this a singleton class
  // DatabaseHelper._privateConstructor();
  // static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // only have a single app-wide reference to the database
  // late Database _database => async {await _initDatabase()};
  // Future<Database> get database async {
  //   return _database;
  //   _database = await _initDatabase();
  //   return _database;
  // }

  // this opens the database (and creates it if it doesn't exist)
  //  Future<Database> _initDatabase() async {
  //   String path = join(await getDatabasesPath(), _databaseName);
  //   return openDatabase(path, version: _databaseVersion,
  //       onCreate: (db, version) {
  //         db.execute('''
  //         CREATE TABLE $table (
  //           $transactionId TEXT PRIMARY KEY,
  //           $walletId TEXT NOT NULL,
  //           $amountInWeis TEXT NOT NULL,
  //           $valueInUsdFormatted TEXT NOT NULL,
  //           $valueinWeiFormatted TEXT NOT NULL,
  //           $date TEXT NOT NULL,
  //           $status TEXT NOT NULL,
  //         )
  //         ''');
  //       });
  // }
}