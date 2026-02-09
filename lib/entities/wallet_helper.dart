import 'package:maniva_wallet/entities/entity_helper.dart';
import 'package:sqflite/sqflite.dart';

class WalletHelper extends EntityHelper {
  static const table = 'wallets';
  static const privateKey = 'privateKey';
  static const walletName = 'walletName';
  static const walletId = 'walletId';
  static const publicKey = 'publicKey';
  static const btcAddress = 'btcAddress';
  static const ownerEmail = 'ownerEmail';
  static const amount = 'amount';
  static const btcAmount = 'btcAmount';

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
            $btcAddress TEXT, 
            $ownerEmail TEXT, 
            $amount REAL,
            $btcAmount REAL
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

  Future<int> updateBalance(WalletEntity wallet) async {
    final db = await database;
    int updateCount = await db.update(
      'wallets',
      {
        'amount': wallet.amount,
        'btcAmount': wallet.btcAmount, // New value for the 'FIRST_NAME' column
      },
      where: 'privateKey = ?', // Condition to specify which rows to update
      whereArgs: [wallet.privateKey],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    db.close();
    return updateCount;
  }

  Future<WalletEntity> getWalletByPrivateKey(final String privateKey) async {
    final db = await database;

    final List<Map<String, Object?>> walletMaps =
        await db.query('wallets', where: 'privateKey = ?', whereArgs: [privateKey]);

    return WalletEntity(
      amount: walletMaps[0]['amount'] as double,
      btcAmount: walletMaps[0]['btcAmount'] as double,
      privateKey: walletMaps[0]['privateKey'] as String,
      publicKey: walletMaps[0]['publicKey'] as String,
      btcAddress: walletMaps[0]['btcAddress'] as String,
      walletId: walletMaps[0]['walletId'] as String,
      walletName: walletMaps[0]['walletName'] as String,
      ownerEmail: walletMaps[0]['ownerEmail'] as String,
    );
  }

  Future<List<WalletEntity>> fetchItems(final String ownerEmail) async {
    final db = await database;

    final List<Map<String, Object?>> walletMaps =
        await db.query('wallets', where: 'ownerEmail = ?', whereArgs: [ownerEmail]);

    if (walletMaps.isNotEmpty) {
      return [
        for (final {
              'amount': amountValue as double,
              'btcAmount': btcAmountValue as double,
              'privateKey': privateKey as String,
              'walletName': walletName as String,
              'walletId': walletId as String,
              'publicKey': publicKey as String,
              'btcAddress': btcAddress as String,
              'ownerEmail': ownerEmail as String,
            } in walletMaps)
          WalletEntity(
            amount: amountValue,
            btcAmount: btcAmountValue,
            privateKey: privateKey,
            publicKey: publicKey,
            btcAddress: btcAddress,
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
  late double amount;
  late double btcAmount;
  final String privateKey;
  final String walletName;
  final String walletId;
  final String publicKey;
  final String btcAddress;
  final String ownerEmail;

  WalletEntity({
    required this.amount,
    required this.btcAmount,
    required this.privateKey,
    required this.walletName,
    required this.walletId,
    required this.publicKey,
    required this.ownerEmail,
    required this.btcAddress,
  });

  Map<String, Object?> toMap() {
    return {
      'amount': amount,
      'btcAmount': btcAmount,
      'privateKey': privateKey,
      'walletName': walletName,
      'walletId': walletId,
      'publicKey': publicKey,
      'btcAddress': btcAddress,
      'ownerEmail': ownerEmail,
    };
  }

  @override
  String toString() {
    return 'WalletEntity{btcAddress: $btcAddress, walletName: $walletName, walletId: $walletId, publicKey: $publicKey ownerEmail: $ownerEmail amount: $amount btcAmount: $btcAmount}';
  }
}
