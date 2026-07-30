import '../entities/transaction_helper.dart';

abstract class CreateTransactionService {
  Future<int> createOrUpdateTransaction(SimpleTransaction transaction);

  Future<List<SimpleTransaction>> listTransactionsOnDataBase(String walletId, {String? network});
}

class CreateTransactionServiceImpl implements CreateTransactionService {
  TransactionHelper helper = TransactionHelper();

  @override
  Future<int> createOrUpdateTransaction(SimpleTransaction transaction) async {
    var inserted = await helper.insertItem(transaction);
    return inserted;
  }

  @override
  Future<List<SimpleTransaction>> listTransactionsOnDataBase(String walletId,
      {String? network}) async {
    var list = await helper.fetchItems(walletId, networkFilter: network);
    return list;
  }

  Future<bool> transactionExists(String transactionId) {
    return helper.transactionExists(transactionId);
  }
}
