import 'package:flutter/material.dart';
import 'package:my_rootstock_wallet/pages/wallet/create_import/create_wallet_app.dart';
import 'package:my_rootstock_wallet/entities/simple_user.dart';
import 'package:provider/provider.dart';
import 'create_import/import_seed_pk_app.dart';
import 'view_wallet_detail.dart';
import '../../entities/wallet_entity.dart';
import '../../services/wallet_service.dart';
import '../../wallets/create_import/create_wallet_detail.dart';
import '../../wallets/create_import/import_wallet_pk_detail.dart';
import '../../wallets/create_import/import_wallet_seed_detail.dart';

class CentralWidgetsContent extends StatefulWidget {
  final double top;
  final ValueChanged<int> onChanged;
  final GestureDragUpdateCallback onPanUpdated;
  final bool showMenu;
  final SimpleUser user;
  final List<WalletEntity> wallets;

  const CentralWidgetsContent(
      {super.key,
      required this.top,
      required this.onChanged,
      required this.onPanUpdated,
      required this.showMenu,
      required this.user,
      required this.wallets});

  @override
  _PageViewAppState createState() => _PageViewAppState();
}

class _PageViewAppState extends State<CentralWidgetsContent> {
  late WalletServiceImpl walletService =
      Provider.of<WalletServiceImpl>(context);
  late Tween<double> _tween;
  var widgets = <Widget>{};
  bool isExpanded = false;

  _PageViewAppState();

  @override
  void initState() {
    super.initState();
    _tween = Tween<double>(begin: 150.0, end: 0.0);
    //delayAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadWallets();
  }

  loadWallets() async {
    for (final item in widget.wallets) {
      widgets.add(ViewWalletDetailPage(wallet: item, user: widget.user));
    }

    widgets.add(CreateWalletApp(
        user: widget.user,
        detailChild: CreateNewWalletDetail(
          user: widget.user,
        )));
    widgets.add(ImportSeedPkApp(
        user: widget.user,
        importWalletByPrivateKey: ImportNewWalletByPrivateKeyDetail(
          user: widget.user,
        ),
        importWalletBySeed: ImportNewWalletBySeedDetail(user: widget.user)));
  }

  Future<void> delayAnimation() async {
    Future.delayed(const Duration(milliseconds: 0), () {
      setState(() {
        _tween = Tween<double>(begin: 150.0, end: 0.0);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
        tween: _tween,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutExpo,
        builder: (context, value, child) {
          return AnimatedPositioned(
            duration: const Duration(microseconds: 250),
            curve: Curves.easeOut,
            left: value,
            right: value * -1,
            top: widget.top,
            height: MediaQuery.of(context).size.height * .65,
            child: PageView(
              onPageChanged: widget.onChanged,
              physics: widget.showMenu
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              children: <Widget>[
                ...widgets,
              ],
            ),
          );
        });
  }
}
