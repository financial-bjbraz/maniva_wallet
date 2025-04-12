import 'package:my_rootstock_wallet/entities/entity_helper.dart';
import 'package:sqflite/sqflite.dart';

class WalletHelper extends EntityHelper {
  static const table = 'wallets';
  static const privateKey = 'privateKey';
  static const walletName = 'walletName';
  static const walletId = 'walletId';
  static const publicKey = 'publicKey';
  static const ownerEmail = 'ownerEmail';
  static const amount = 'amount';

  static final WalletHelper _instance = WalletHelper._internal();

  factory WalletHelper() {
    return _instance;
  }

  WalletHelper._internal();

  static String scriptCreation() {
    String createTable = '''
          CREATE TABLE $table (
            $privateKey TEXT PRIMARY KEY, 
            $walletName TEXT, 
            $walletId TEXT,
            $publicKey TEXT, 
            $ownerEmail TEXT, 
            $amount REAL
          )
          ''';
    return createTable;
  }

  Future<int> insertItem(WalletEntity wallet) async {
    final db = await database;
    int inserted = await db.insert(
      'wallets',
      wallet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    db.close();

    return inserted;
  }

  Future<List<WalletEntity>> fetchItems(final String ownerEmail) async {
    final db = await database;

    final List<Map<String, Object?>> walletMaps =
        await db.query('wallets', where: 'ownerEmail = ?', whereArgs: [ownerEmail]);

    if (walletMaps.isNotEmpty) {
      return [
        for (final {
              'privateKey': privateKey as String,
              'walletName': walletName as String,
              'walletId': walletId as String,
              'publicKey': publicKey as String,
              'ownerEmail': ownerEmail as String,
              'amount': amountValue as double,
            } in walletMaps)
          WalletEntity(
            amountValue,
            privateKey: privateKey,
            publicKey: publicKey,
            walletId: walletId,
            walletName: walletName,
            ownerEmail: ownerEmail,
          ),
      ];
    }

    return [];
  }
}

class WalletEntity {
  final String privateKey;
  final String walletName;
  final String walletId;
  final String publicKey;
  final String ownerEmail;
  double amount;

  WalletEntity(
    this.amount, {
    required this.privateKey,
    required this.walletName,
    required this.walletId,
    required this.publicKey,
    required this.ownerEmail,
  });

  Map<String, Object?> toMap() {
    return {
      'privateKey': privateKey,
      'walletName': walletName,
      'walletId': walletId,
      'publicKey': publicKey,
      'ownerEmail': ownerEmail,
      'amount': amount,
    };
  }

  @override
  String toString() {
    return 'WalletEntity{privateKey: $privateKey, walletName: $walletName, walletId: $walletId, publicKey: $publicKey ownerEmail: $ownerEmail} amount: $amount';
  }
}
