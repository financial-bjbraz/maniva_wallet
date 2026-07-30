import 'package:sqflite/sqflite.dart';

import 'entity_helper.dart';

class TransactionHelper extends EntityHelper {
  static const table = 'transactions';
  static const transactionId = 'transactionId';
  static const walletId = 'walletId';
  static const amountInWeis = 'amountInWeis';
  static const valueInUsdFormatted = 'valueInUsdFormatted';
  static const valueinWeiFormatted = 'valueinWeiFormatted';
  static const ddateTime = 'ddateTime';
  static const status = 'status';
  static const type = 'type';
  static const destination = 'destination';
  static const network = 'network';
  static const timestampMs = 'timestampMs';

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
            $ddateTime TEXT NOT NULL,
            $status TEXT NOT NULL,
            $type INTEGER NOT NULL,
            $destination TEXT NOT NULL,
            $network TEXT NOT NULL DEFAULT '',
            $timestampMs INTEGER NOT NULL DEFAULT 0
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
    return inserted;
  }

  Future<bool> transactionExists(String txId) async {
    final db = await database;
    final rows = await db.query(table, where: '$transactionId = ?', whereArgs: [txId], limit: 1);
    return rows.isNotEmpty;
  }

  /// Fetches transactions for [walletId], optionally filtered to a single
  /// [networkFilter] (a Network enum's .name, e.g. "BITCOIN_TESTNET"),
  /// ordered newest-first by [timestampMs].
  Future<List<SimpleTransaction>> fetchItems(final String walletId, {String? networkFilter}) async {
    final db = await database;
    final where = networkFilter == null ? 'walletId = ?' : 'walletId = ? AND network = ?';
    final whereArgs = networkFilter == null ? [walletId] : [walletId, networkFilter];
    final List<Map<String, Object?>> walletMaps = await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestampMs DESC',
    );
    if (walletMaps.isNotEmpty) {
      var list = [
        for (final {
              'transactionId': transactionId as String,
              'amountInWeis': amountInWeis as String,
              'ddateTime': ddateTime as String,
              'walletId': walletId as String,
              'valueInUsdFormatted': valueInUsdFormatted as String,
              'valueinWeiFormatted': valueInWeiFormatted as String,
              'status': status as String?,
              'type': type as int,
              'destination': destination as String?,
              'network': txNetwork as String?,
              'timestampMs': txTimestampMs as int?,
            } in walletMaps)
          SimpleTransaction(
            status: status ?? "",
            transactionId: transactionId,
            amountInWeis: amountInWeis,
            ddateTime: ddateTime,
            walletId: walletId,
            valueInUsdFormatted: valueInUsdFormatted,
            valueInWeiFormatted: valueInWeiFormatted,
            type: type,
            destination: destination,
            network: txNetwork ?? '',
            timestampMs: txTimestampMs ?? 0,
          ),
      ];
      return list;
    }
    return [];
  }
}

class SimpleTransaction {
  late String transactionId;
  late String amountInWeis;
  late String valueInUsdFormatted;
  late String valueInWeiFormatted;
  bool? transactionSent;
  String ddateTime = '';
  int type = 0; // TransactionType
  final String walletId;
  final String? status;
  final String? destination;
  final String network;
  final int timestampMs;

  SimpleTransaction(
      {this.status,
      required this.transactionId,
      required this.amountInWeis,
      required this.ddateTime,
      required this.walletId,
      required this.valueInUsdFormatted,
      required this.valueInWeiFormatted,
      required this.type,
      required this.destination,
      this.transactionSent,
      this.network = '',
      this.timestampMs = 0});

  Map<String, Object?> toMap() {
    return {
      'transactionId': transactionId,
      'amountInWeis': amountInWeis,
      'ddateTime': ddateTime,
      'walletId': walletId,
      'valueInUsdFormatted': valueInUsdFormatted,
      'valueInWeiFormatted': valueInWeiFormatted,
      'status': status,
      'type': type,
      'destination': destination,
      'network': network,
      'timestampMs': timestampMs,
    };
  }

  @override
  String toString() {
    return 'SimpleTransaction{transactionId: $transactionId, amountInWeis: $amountInWeis, ddateTime: $ddateTime,  walletId: $walletId}, valueInUsdFormatted: ${valueInUsdFormatted}, valueInWeiFormatted: ${valueInWeiFormatted},  status: ${status} type: $type destination: $destination network: $network timestampMs: $timestampMs';
  }
}
