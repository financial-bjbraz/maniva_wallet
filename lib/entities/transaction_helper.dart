import 'package:sqflite/sqflite.dart';

import 'entity_helper.dart';

class TransactionHelper extends EntityHelper {
  static const table = 'transactions';
  static const transactionId = 'transactionId';
  static const walletId = 'walletId';
  static const amountInWeis = 'amountInWeis';
  static const valueInUsdFormatted = 'valueInUsdFormatted';
  static const valueinWeiFormatted = 'valueinWeiFormatted';
  static const date = 'date';
  static const status = 'status';
  static const type = 'type';
  static const destination = 'destination';

  static final TransactionHelper _instance = TransactionHelper._internal();

  factory TransactionHelper() {
    return _instance;
  }

  TransactionHelper._internal();

  static String scriptCreation() {
    String createTable = '''
          CREATE TABLE $table (
            $transactionId TEXT PRIMARY KEY,
            $walletId TEXT NOT NULL,
            $amountInWeis TEXT NOT NULL,
            $valueInUsdFormatted TEXT NOT NULL,
            $valueinWeiFormatted TEXT NOT NULL,
            $date TEXT NOT NULL,
            $status TEXT NOT NULL,
            $type INTEGER NOT NULL,
            $destination TEXT NOT NULL
          )
          ''';
    return createTable;
  }

  Future<int> insertItem(SimpleTransaction transaction) async {
    final db = await database;
    var inserted = await db.insert(
      table,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    close();
    return inserted;
  }

  Future<List<SimpleTransaction>> fetchItems(final String walletId) async {
    final db = await database;
    final List<Map<String, Object?>> walletMaps =
        await db.query(table, where: 'walletId = ? ', whereArgs: [walletId]);
    if (walletMaps.isNotEmpty) {
      var list = [
        for (final {
              'transactionId': transactionId as String,
              'amountInWeis': amountInWeis as int,
              'date': date as String,
              'walletId': walletId as String,
              'valueInUsdFormatted': valueInUsdFormatted as String,
              'valueinWeiFormatted': valueInWeiFormatted as String,
              'status': status as String?,
              'type': type as int,
              'destination': destination as String?,
            } in walletMaps)
          SimpleTransaction(
            status: status ?? "",
            transactionId: transactionId,
            amountInWeis: amountInWeis,
            date: date,
            walletId: walletId,
            valueInUsdFormatted: valueInUsdFormatted,
            valueInWeiFormatted: valueInWeiFormatted,
            type: type,
            destination: destination,
          ),
      ];
      return list;
    }
    return [];
  }
}

class SimpleTransaction {
  late String transactionId;
  late int amountInWeis;
  late String valueInUsdFormatted;
  late String valueInWeiFormatted;
  late bool? transactionSent;
  String date = '';
  int type = 0; // TransactionType
  final String walletId;
  final String? status;
  final String? destination;

  SimpleTransaction(
      {this.status,
      required this.transactionId,
      required this.amountInWeis,
      required this.date,
      required this.walletId,
      required this.valueInUsdFormatted,
      required this.valueInWeiFormatted,
      required this.type,
      required this.destination});

  Map<String, Object?> toMap() {
    return {
      'transactionId': transactionId,
      'amountInWeis': amountInWeis,
      'date': date,
      'walletId': walletId,
      'valueInUsdFormatted': valueInUsdFormatted,
      'valueInWeiFormatted': valueInWeiFormatted,
      'status': status,
      'type': type,
      'destination': destination
    };
  }

  @override
  String toString() {
    return 'SimpleTransaction{transactionId: $transactionId, amountInWeis: $amountInWeis, date: $date,  walletId: $walletId}, valueInUsdFormatted: ${valueInUsdFormatted}, valueInWeiFormatted: ${valueInWeiFormatted},  status: ${status} type: $type destination: $destination';
  }
}
