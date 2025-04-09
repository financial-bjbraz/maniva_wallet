import 'package:flutter/cupertino.dart';
import 'package:my_rootstock_wallet/entities/simple_user.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../util/util.dart';

abstract class CreateUserService {
  Future<SimpleUser?> getUser(SimpleUser user);
  void createUser(SimpleUser user);
  void changePassword(String password);
}

class CreateUserServiceImpl extends ChangeNotifier implements CreateUserService {
  @override
  void changePassword(String password) {}

  @override
  void createUser(SimpleUser user) async {
    final db = await openDataBase();

    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<SimpleUser?> getUser(SimpleUser user) async {
    WidgetsFlutterBinding.ensureInitialized();

    // Open the database and store the reference.
    final database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), databaseName),
    );

    // Get a reference to the database.
    final db = await database;

    // Query the table for all the dogs.
    final List<Map<String, Object?>> walletMaps = await db.query('users',
        where: 'email = ? and password = ?', whereArgs: [user.email, user.password]);

    // Convert the list of each dog's fields into a list of `Dog` objects.
    var list = [
      for (final {
            'name': name as String,
            'email': email as String,
            'password': password as String,
          } in walletMaps)
        SimpleUser(name: name, email: email, password: password),
    ];
    return list.firstOrNull;
  }
}
