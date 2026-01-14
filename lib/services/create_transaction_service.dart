import '../entities/transaction_helper.dart';

abstract class CreateTransactionService {
  void createOrUpdateTransaction(SimpleTransaction transaction);

  void listTransactionsOnDataBase(String walletId);
}

class CreateTransactionServiceImpl implements CreateTransactionService {
  TransactionHelper helper = TransactionHelper();

  @override
  Future<int> createOrUpdateTransaction(SimpleTransaction transaction) async {
    var inserted = await helper.insertItem(transaction);
    return inserted;
  }

  @override
  Future<List<SimpleTransaction>> listTransactionsOnDataBase(String walletId) async {
    var list = await helper.fetchItems(walletId);
    return list;
  }
}
