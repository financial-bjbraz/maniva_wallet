import 'package:flutter/cupertino.dart';
import 'package:my_rootstock_wallet/entities/simple_transaction.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../util/util.dart';

abstract class CreateTransactionService {
  void createOrUpdateTransaction(SimpleTransaction transaction);
  void listTransactions(String walletId);
}

class CreateTransactionServiceImpl extends ChangeNotifier
    implements CreateTransactionService {
  @override
  void createOrUpdateTransaction(SimpleTransaction transaction) async {
    final db = await openDataBase();

    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<SimpleTransaction>> listTransactions(String walletId) async {
    WidgetsFlutterBinding.ensureInitialized();
    final database = openDatabase(
      join(await getDatabasesPath(), databaseName),
    );

    // Get a reference to the database.
    final db = await database;

    // Query the table for all the dogs.
    final List<Map<String, Object?>> walletMaps = await db
        .query('transactions', where: 'walletId = ? ', whereArgs: [walletId]);
    if (walletMaps != null && walletMaps.isNotEmpty) {
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
