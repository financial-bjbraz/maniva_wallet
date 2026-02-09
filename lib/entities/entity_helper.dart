import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:maniva_wallet/entities/token_helper.dart';
import 'package:maniva_wallet/entities/transaction_helper.dart';
import 'package:maniva_wallet/entities/user_helper.dart';
import 'package:maniva_wallet/entities/wallet_helper.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../util/util.dart';

class EntityHelper {
  static Database? _database;
  final log = Logger("EntityHelper");

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future setUp() async {
    database;
    _database;
  }

  Future<Database> _initDatabase() async {
    var dbKey = dotenv.env['PRIVATE_KEY'];
    String path = join(await getDatabasesPath(), "$DATA_BASE_VERSION+$DATA_BASE_NAME");
    if (kDebugMode) {
      log.info("Database persisted at ${path}");
    }

    return openDatabase(path, password: dbKey, version: DATA_BASE_VERSION,
        onCreate: (db, int version) {
      try {
        if (kDebugMode) {
          log.info("Creating transactions");
        }
        db.execute(TransactionHelper.scriptCreation());
        if (kDebugMode) {
          log.info("Transactions created");
        }
      } catch (e) {
        log.severe("Error creating transactions table: $e");
      }
      try {
        if (kDebugMode) {
          log.info("Creating wallets");
        }
        db.execute(WalletHelper.scriptCreation());
        if (kDebugMode) {
          log.info("Wallets created");
        }
      } catch (e) {}
      try {
        if (kDebugMode) {
          log.info("Creating users");
        }
        db.execute(UserHelper.scriptCreation());
        if (kDebugMode) {
          log.info("Users created");
        }
      } catch (e) {}
      try {
        if (kDebugMode) {
          log.info("Creating tokens");
        }
        db.execute(TokenHelper.scriptCreation());
        if (kDebugMode) {
          log.info("Table Tokens created");
        }
      } catch (e) {}

      final String rawJsonString = dotenv.env['TOKENS'] ?? '';
      if (rawJsonString.isNotEmpty) {
        List<dynamic> jsonMap = jsonDecode(rawJsonString) as List<dynamic>;
        for (int i = 0; i < jsonMap.length; i++) {
          db.insert(
            TokenHelper.table,
            jsonMap[i] as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        if (kDebugMode) {
          log.info("${jsonMap.length} tokens added to database");
        }
      }

      final String transactionsList = dotenv.env['TRANSACTIONS'] ?? '';
      if (transactionsList.isNotEmpty) {
        List<dynamic> transactionsMap = jsonDecode(transactionsList) as List<dynamic>;
        for (int i = 0; i < transactionsMap.length; i++) {
          db.insert(
            TransactionHelper.table,
            transactionsMap[i] as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      if (kDebugMode) {
        log.info("Initial available data inserted");
      }
    });
  }
}
