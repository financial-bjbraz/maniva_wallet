import 'package:sqflite/sqflite.dart';

import 'entity_helper.dart';

class UserHelper extends EntityHelper {
  static const table = 'users';
  static const name = 'name';
  static const email = 'email';
  static const userId = 'userId';
  static const password = 'password';
  static final UserHelper _instance = UserHelper._internal();

  factory UserHelper() {
    return _instance;
  }

  UserHelper._internal();

  static String scriptCreation() {
    String createTable = '''
          CREATE TABLE $table (
            $name TEXT PRIMARY KEY,
            $email TEXT NOT NULL,
            $userId TEXT NOT NULL,
            $password TEXT NOT NULL
          )
          ''';
    return createTable;
  }

  Future<int> insertItem(SimpleUser user) async {
    final db = await database;
    int inserted = await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    db.close();

    return inserted;
  }

  Future<List<SimpleUser>> fetchItems(final SimpleUser user) async {
    final db = await database;

    final List<Map<String, Object?>> users = await db
        .query(table, where: 'email = ? and password = ?', whereArgs: [user.email, user.password]);

    if (users.isNotEmpty) {
      return [
        for (final {
              'name': name as String,
              'email': email as String,
              'password': password as String,
            } in users)
          SimpleUser(name: name, email: email, password: password),
      ];
    }

    return [];
  }
}

class SimpleUser {
  late String name;
  late String email;
  String userId = '';
  late String password;

  SimpleUser({required this.name, required this.email, required this.password});

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'email': email,
      'userId': userId,
      'password': password,
    };
  }

  @override
  String toString() {
    return 'SimpleUser{name: $name, email: $email, userId: $userId, password: $password}';
  }
}
