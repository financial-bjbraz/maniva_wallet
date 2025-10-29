import 'package:sqflite/sqflite.dart';

import 'entity_helper.dart';

class TokenHelper extends EntityHelper {
  static const table = 'token';
  static const tokenId = 'tokenId';
  static const network = 'network';
  static const networkName = 'networkName';
  static const symbol = 'symbol';
  static const symbol2 = 'symbol2';
  static const address = 'address';
  static const nodeUrl = 'nodeUrl';

  static final TokenHelper _instance = TokenHelper._internal();

  factory TokenHelper() {
    return _instance;
  }

  TokenHelper._internal();

  static String scriptCreation() {
    String createTable = '''
          CREATE TABLE $table (
            $tokenId TEXT PRIMARY KEY,
            $network TEXT NOT NULL,
            $networkName TEXT NOT NULL,
            $symbol TEXT NOT NULL,
            $symbol2 TEXT NOT NULL,
            $address TEXT NOT NULL,
            $nodeUrl TEXT NOT NULL
          )
          ''';
    return createTable;
  }

  Future<int> insertItem(Token token) async {
    final db = await database;
    var inserted = await db.insert(
      table,
      token.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return inserted;
  }

  Future<List<Token>> fetchItems() async {
    final db = await database;
    final List<Map<String, Object?>> walletMaps = await db.query(table);
    if (walletMaps.isNotEmpty) {
      var list = [
        for (final {
              'tokenId': tokenId as String,
              'network': network as String,
              'networkName': networkName as String,
              'symbol': symbol as String,
              'symbol2': symbol2 as String,
              'address': address as String,
              'nodeUrl': nodeUrl as String,
            } in walletMaps)
          Token(
            tokenId: tokenId ?? "",
            network: network,
            networkName: networkName,
            symbol: symbol,
            symbol2: symbol2,
            address: address,
            nodeUrl: nodeUrl,
          ),
      ];
      return list;
    }
    return [];
  }
}

class Token {
  late String tokenId;
  late String network;
  late String networkName;
  late String symbol;
  late String symbol2;
  late String address;
  late String nodeUrl;

  Token(
      {required this.tokenId,
      required this.network,
      required this.networkName,
      required this.symbol,
      required this.symbol2,
      required this.address,
      required this.nodeUrl});

  Map<String, Object?> toMap() {
    return {
      'tokenId': tokenId,
      'network': network,
      'networkName': networkName,
      'symbol': symbol,
      'symbol2': symbol2,
      'address': address,
      'nodeUrl': nodeUrl
    };
  }

  @override
  String toString() {
    return 'Token{tokenId: $tokenId, network: $network, networkName: $networkName,  symbol: $symbol}, symbol2: ${symbol2}, address: ${address},  nodeUrl: ${nodeUrl} ';
  }
}
