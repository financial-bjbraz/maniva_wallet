import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:maniva_wallet/entities/token_helper.dart';
import 'package:maniva_wallet/entities/transaction_helper.dart';
import 'package:maniva_wallet/entities/user_helper.dart';
import 'package:maniva_wallet/entities/wallet_helper.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common/sqlite_api.dart'
    show Database, OpenDatabaseOptions, ConflictAlgorithm;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' as ffi_web;
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;

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

  /// sqflite_sqlcipher (used for encrypted storage on Android/iOS/macOS) has
  /// no Linux or Web platform implementation, so those two platforms fall
  /// back to plain, unencrypted sqflite_common_ffi / sqflite_common_ffi_web
  /// instead. This is a known security tradeoff, not an oversight — see
  /// docs/linux-web-support-plan.md. The DAO layer (wallet/transaction/
  /// user/token helpers) is unaffected: it only depends on the shared
  /// sqflite_common `Database` interface, not on sqlcipher directly.
  Future<Database> _initDatabase() async {
    var dbKey = dotenv.env['PRIVATE_KEY'];
    const fileName = "$DATA_BASE_VERSION+$DATA_BASE_NAME";

    if (kIsWeb) {
      if (kDebugMode) {
        log.info("Database persisted in browser storage (unencrypted) as $fileName");
      }
      final db = await ffi_web.databaseFactoryFfiWeb.openDatabase(
        fileName,
        options: OpenDatabaseOptions(version: DATA_BASE_VERSION, onCreate: _onCreateDatabase),
      );
      return _runPostCreateMigrations(db);
    }

    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      String path = join(await sqlcipher.getDatabasesPath(), fileName);
      if (kDebugMode) {
        log.info("Database persisted at $path");
      }
      final db = await sqlcipher.openDatabase(path,
          password: dbKey, version: DATA_BASE_VERSION, onCreate: _onCreateDatabase);
      return _runPostCreateMigrations(db);
    }

    // Linux (and Windows, if ever added): no OS-level "databases" directory
    // convention like Android's, so use the app's writable support
    // directory instead. Unencrypted — see the class-level doc comment.
    ffi.sqfliteFfiInit();
    final dir = await getApplicationSupportDirectory();
    String path = join(dir.path, fileName);
    if (kDebugMode) {
      log.info("Database persisted at $path (unencrypted)");
    }
    final db = await ffi.databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(version: DATA_BASE_VERSION, onCreate: _onCreateDatabase),
    );
    return _runPostCreateMigrations(db);
  }

  void _onCreateDatabase(Database db, int version) {
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

    // Mainnet token list for the testnet/mainnet toggle, seeded the same
    // way as TOKENS above. Left empty by default (no real mainnet contract
    // addresses configured) — the mainnet token section simply shows
    // nothing until TOKENS_MAIN is filled in.
    final String rawJsonStringMain = dotenv.env['TOKENS_MAIN'] ?? '';
    if (rawJsonStringMain.isNotEmpty) {
      List<dynamic> jsonMapMain = jsonDecode(rawJsonStringMain) as List<dynamic>;
      for (int i = 0; i < jsonMapMain.length; i++) {
        db.insert(
          TokenHelper.table,
          jsonMapMain[i] as Map<String, dynamic>,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      if (kDebugMode) {
        log.info("${jsonMapMain.length} mainnet tokens added to database");
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
  }

  // Defensive migration for the transactions table's network/timestampMs
  // columns: existing DB files (already at this version) never re-run
  // onCreate, so add these columns in place instead of bumping
  // DATA_BASE_VERSION (which would create a brand new, empty DB file per
  // this scheme's "$DATA_BASE_VERSION+$DATA_BASE_NAME" path pattern,
  // wiping out existing wallets/transactions).
  Future<Database> _runPostCreateMigrations(Database db) async {
    try {
      await db.execute(
          "ALTER TABLE ${TransactionHelper.table} ADD COLUMN ${TransactionHelper.network} TEXT NOT NULL DEFAULT ''");
    } catch (_) {
      // Column already exists.
    }
    try {
      await db.execute(
          "ALTER TABLE ${TransactionHelper.table} ADD COLUMN ${TransactionHelper.timestampMs} INTEGER NOT NULL DEFAULT 0");
    } catch (_) {
      // Column already exists.
    }

    return db;
  }
}
