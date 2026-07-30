import 'package:flutter/material.dart';
import 'package:maniva_wallet/pages/wallet/create_import/create_wallet_app.dart';
import 'package:provider/provider.dart';

import '../../entities/user_helper.dart';
import '../../entities/wallet_helper.dart';
import '../../services/wallet_service.dart';
import '../../util/app_theme.dart';
import '../../util/util.dart';
import 'create_import/create_wallet_detail.dart';
import 'create_import/import_seed_pk_app.dart';
import 'create_import/import_wallet_pk_detail.dart';
import 'create_import/import_wallet_seed_detail.dart';
import 'view_wallet_detail.dart';

const double _kCardHeightMin = .30;
const double _kCardHeightDefault = .57;
// Leaves a safety margin below the card's bottom edge before the MyDotsApp
// indicator at .85.
const double _kCardBottomMax = .84;

class CentralWidgetsContent extends StatefulWidget {
  final double top;
  final double restingTopFraction;
  final ValueChanged<int> onChanged;
  final ValueChanged<double> onManualDrag;
  final VoidCallback onManualDragEnd;
  final bool showMenu;
  final SimpleUser user;
  final List<WalletEntity> wallets;

  const CentralWidgetsContent(
      {super.key,
      required this.top,
      required this.restingTopFraction,
      required this.onChanged,
      required this.onManualDrag,
      required this.onManualDragEnd,
      required this.showMenu,
      required this.user,
      required this.wallets});

  @override
  _PageViewAppState createState() => _PageViewAppState();
}

class _PageViewAppState extends State<CentralWidgetsContent> {
  late WalletServiceImpl walletService = Provider.of<WalletServiceImpl>(context);
  late Tween<double> _tween;
  var widgets = <Widget>{};
  bool isExpanded = false;
  double _heightFraction = _kCardHeightDefault;

  _PageViewAppState();

  @override
  void initState() {
    super.initState();
    _tween = Tween<double>(begin: 150.0, end: 0.0);
    //delayAnimation();
    getWalletCardHeightFraction().then((saved) {
      if (mounted && saved != null) {
        setState(() {
          _heightFraction = saved;
        });
      }
    });
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

  double _maxHeightFraction() => _kCardBottomMax - widget.restingTopFraction;

  Widget _dragHandle() {
    return Positioned(
      top: 6,
      left: 0,
      right: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (details) => widget.onManualDrag(details.delta.dy),
        onPanEnd: (_) => widget.onManualDragEnd(),
        child: Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: rootstockCream.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resizeGrip() {
    return Positioned(
      right: 4,
      bottom: 4,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (details) {
          final heightScreen = MediaQuery.of(context).size.height;
          setState(() {
            _heightFraction += details.delta.dy / heightScreen;
            _heightFraction =
                _heightFraction.clamp(_kCardHeightMin, _maxHeightFraction());
          });
        },
        onPanEnd: (_) => setWalletCardHeightFraction(_heightFraction),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Icon(
            Icons.height,
            size: 18,
            color: rootstockCream.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double heightFraction = _heightFraction.clamp(_kCardHeightMin, _maxHeightFraction());
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
            height: MediaQuery.of(context).size.height * heightFraction,
            child: Stack(
              children: [
                PageView(
                  onPageChanged: widget.onChanged,
                  physics: widget.showMenu
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  children: <Widget>[
                    ...widgets,
                  ],
                ),
                if (!widget.showMenu) _dragHandle(),
                if (!widget.showMenu) _resizeGrip(),
              ],
            ),
          );
        });
  }
}
