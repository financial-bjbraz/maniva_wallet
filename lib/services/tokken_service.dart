import 'package:flutter/cupertino.dart';
import 'package:my_rootstock_wallet/entities/token_helper.dart';

abstract class TokenService {
  void createOrUpdate(Token token);
  void list();
}

class TokenServiceImpl extends ChangeNotifier implements TokenService {
  TokenHelper helper = TokenHelper();

  @override
  Future<int> createOrUpdate(Token token) async {
    var inserted = await helper.insertItem(token);
    helper.close();
    return inserted;
  }

  @override
  Future<List<Token>> list() async {
    WidgetsFlutterBinding.ensureInitialized();
    var list = await helper.fetchItems();
    helper.close();
    return list;
  }
}
