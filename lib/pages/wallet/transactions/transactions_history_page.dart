import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../entities/transaction_helper.dart';
import '../../../entities/wallet_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/create_transaction_service.dart';
import '../../../services/wallet_service.dart';
import '../../../util/app_theme.dart';
import '../../../util/network.dart';
import '../../../util/transaction_type.dart';
import '../../../util/util.dart';

/// Transaction history for a single wallet, filtered to one network (BTC or
/// RSK), newest first. Each row shows the native amount, the USD value at
/// the time the transaction happened (as stored), and the USD value at the
/// current quotation (recalculated live) side by side.
class TransactionsHistoryPage extends StatefulWidget {
  const TransactionsHistoryPage({super.key, required this.wallet, required this.network});

  final WalletEntity wallet;
  final Network network;

  @override
  _TransactionsHistoryPageState createState() => _TransactionsHistoryPageState();
}

class _TransactionsHistoryPageState extends State<TransactionsHistoryPage> {
  final CreateTransactionServiceImpl txService = CreateTransactionServiceImpl();
  final NumberFormat _usdFormat = NumberFormat.simpleCurrency(name: 'USD');

  bool _loading = true;
  bool _syncing = false;
  List<SimpleTransaction> _transactions = [];
  double _currentPrice = 0;

  late final WalletServiceImpl walletService =
      Provider.of<WalletServiceImpl>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _load();
    _sync();
  }

  bool get _isBitcoin =>
      widget.network == Network.BITCOIN_TESTNET || widget.network == Network.BITCOIN_MAINNET;

  Future<void> _load() async {
    final list = await txService.listTransactionsOnDataBase(
      widget.wallet.walletId,
      network: widget.network.name,
    );
    final price = await walletService.getCurrentUsdPricePerCoin();
    if (mounted) {
      setState(() {
        _transactions = list;
        _currentPrice = price;
        _loading = false;
      });
    }
  }

  Future<void> _sync() async {
    if (_syncing) {
      return;
    }
    _syncing = true;
    try {
      if (_isBitcoin) {
        await walletService.syncBitcoinTransactions(widget.wallet);
      } else {
        await walletService.syncRootstockTransactions(widget.wallet);
      }
      await _load();
    } finally {
      _syncing = false;
    }
  }

  String _symbol() => _isBitcoin ? 'BTC' : 'RBTC';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final networkLabel = _isBitcoin ? t.bitcoinLabel : t.rootstockLabel;
    return Scaffold(
      backgroundColor: rootstockBlack,
      appBar: AppBar(
        backgroundColor: rootstockBlack,
        iconTheme: const IconThemeData(color: rootstockCream),
        title: Text(t.networkTransactionsTitle(networkLabel),
            style: const TextStyle(color: rootstockCream, fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: rootstockCream),
            onPressed: _sync,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? Center(
                  child: Text(t.noTransactionsYet, style: mutedCaptionText),
                )
              : RefreshIndicator(
                  onRefresh: _sync,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: rootstockCream, height: 24),
                    itemBuilder: (context, index) => _transactionRow(_transactions[index]),
                  ),
                ),
    );
  }

  Widget _transactionRow(SimpleTransaction tx) {
    final t = AppLocalizations.of(context)!;
    final incoming = tx.type == TransactionType.REGULAR_INCOMING.type;
    final nativeAmount = double.tryParse(tx.valueInWeiFormatted) ?? 0;
    final currentUsd = nativeAmount * _currentPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  incoming ? Icons.arrow_downward : Icons.arrow_upward,
                  color: incoming ? Colors.greenAccent : Colors.orangeAccent,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  incoming ? t.receivedLabel : t.sentLabel,
                  style: const TextStyle(color: rootstockCream, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(tx.ddateTime, style: mutedCaptionText),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          formatTextWithParameter(tx.destination ?? '', 10),
          style: mutedCaptionText,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${tx.valueInWeiFormatted} ${_symbol()}',
                style: const TextStyle(color: rootstockCream, fontSize: 15)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${t.atTheTimeLabel}: ${tx.valueInUsdFormatted}', style: mutedCaptionText),
                Text('${t.nowLabel}: ${_usdFormat.format(currentUsd)}', style: mutedCaptionText),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
