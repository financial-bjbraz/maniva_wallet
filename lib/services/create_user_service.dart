import 'package:flutter/cupertino.dart';
import 'package:my_rootstock_wallet/entities/user_helper.dart';

abstract class CreateUserService {
  Future<SimpleUser?> getUser(SimpleUser user);
  void createUser(SimpleUser user);
  void changePassword(String password);
}

class CreateUserServiceImpl extends ChangeNotifier implements CreateUserService {
  @override
  void changePassword(String password) {}
  UserHelper helper = UserHelper();

  @override
  void createUser(SimpleUser user) async {
    await helper.insertItem(user);
  }

  @override
  Future<SimpleUser?> getUser(SimpleUser user) async {
    WidgetsFlutterBinding.ensureInitialized();
    var users = await helper.fetchItems(user);
    if (users.isEmpty) {
      return null;
    }
    return users.first;
  }
}
