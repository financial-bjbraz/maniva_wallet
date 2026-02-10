import 'package:maniva_wallet/entities/token_helper.dart';

abstract class TokenService {
  Future<int> createOrUpdate(Token token);

  Future<List<Token>> list(int chainId);
}

class TokenServiceImpl implements TokenService {
  TokenHelper helper = TokenHelper();

  @override
  Future<int> createOrUpdate(Token token) async {
    var inserted = await helper.insertItem(token);
    return inserted;
  }

  @override
  Future<List<Token>> list(int chainId) async {
    var list = await helper.fetchItems(chainId);
    return list;
  }
}
