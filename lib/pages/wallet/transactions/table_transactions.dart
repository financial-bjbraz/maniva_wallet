import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_rootstock_wallet/entities/wallet_dto.dart';
import 'package:my_rootstock_wallet/pages/details/detail_list.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/incoming_line.dart';
import 'package:my_rootstock_wallet/pages/wallet/transactions/outgoing_line.dart';
import 'package:my_rootstock_wallet/wallets/info/account_receive.dart';
import 'package:my_rootstock_wallet/wallets/info/account_send.dart';
import 'package:provider/provider.dart';
import '../../../entities/simple_user.dart';
import '../../../entities/wallet_entity.dart';
import '../../../services/wallet_service.dart';
import '../../../util/shimmer_loading.dart';

class TableTransactions extends StatefulWidget {
  const TableTransactions(
      {super.key, required this.wallet, required this.user});

  final WalletEntity wallet;
  final SimpleUser user;

  @override
  _TableTransactions createState() => _TableTransactions();
}

class _TableTransactions extends State<TableTransactions> {
  late WalletServiceImpl walletService =
  Provider.of<WalletServiceImpl>(context, listen: false);
  bool _isLoading = true;
  _TableTransactions();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadWalletData();
  }

  loadWalletData() async {
    await Future.delayed(const Duration(seconds: 3), () {
      walletService.createWalletToDisplay(widget.wallet).then((dto) => {
        setState(() {
          _isLoading = false;
        })
      });
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _isLoading = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    loadWalletData();
    return ShimmerLoading(
        isLoading: _isLoading,
        child: SingleChildScrollView(
      child: Table(
        columnWidths:
        {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(4),
          2: FlexColumnWidth(4),
          3: FlexColumnWidth(4),
          4: FlexColumnWidth(2),
          5: FlexColumnWidth(2),
        },
        children: [
          IncomingTransactionLine(this.widget.user).create(),
          OutgoingTransactionLine(this.widget.user).create(),
          IncomingTransactionLine(this.widget.user).create(),
          OutgoingTransactionLine(this.widget.user).create(),
          OutgoingTransactionLine(this.widget.user).create(),
          IncomingTransactionLine(this.widget.user).create(),
        ],
      ),
    ),
    );
  }
}
