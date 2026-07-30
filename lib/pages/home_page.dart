import 'package:flutter/material.dart';
import 'package:maniva_wallet/pages/wallet/central_widgets_content.dart';
import 'package:maniva_wallet/pages/wallet/my_dots_app.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../entities/user_helper.dart';
import '../entities/wallet_helper.dart';
import '../util/app_theme.dart';
import '../util/util.dart';
import 'menu/menu_app.dart';
import 'menu/my_app_bar.dart';

// Manual drag bounds for the wallet card's top position, as fractions of
// screen height. Kept apart so CentralWidgetsContent can clamp its own
// height against _restingTopFraction without overflowing past the
// MyDotsApp indicator at .85.
const double _kCardTopMin = .12;
const double _kCardTopMax = .45;
const double _kCardTopDefault = .27;

class HomePage extends StatefulWidget {
  final SimpleUser user;
  final List<WalletEntity> wallets;

  const HomePage({super.key, required this.user, required this.wallets});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late bool _showMenu;
  late int _currentIndex;
  late double _yPosition = 0;
  late int _walletQuantity;
  String _appVersion = '';
  double _restingTopFraction = _kCardTopDefault;

  _HomePageState();

  @override
  void initState() {
    super.initState();
    _showMenu = false;
    _currentIndex = 0;
    _walletQuantity = 0;
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() {
          _appVersion = 'v${info.version}';
        });
      }
    });
    getWalletCardTopFraction().then((saved) {
      if (mounted && saved != null) {
        setState(() {
          _restingTopFraction = saved;
          if (!_showMenu) {
            _yPosition = MediaQuery.of(context).size.height * _restingTopFraction;
          }
        });
      }
    });
  }

  loadWallets() async {
    try {
      setState(() {
        _walletQuantity = widget.wallets.length;
      });
    } catch (e) {
      // print('error occurred $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    loadWallets();
    double heightScreen = MediaQuery.of(context).size.height;
    double distanciaParaTopoComMenuExpandido = .55;

    if (_yPosition == 0) {
      _yPosition = heightScreen * _restingTopFraction;
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          MyAppBar(
            showMenu: _showMenu,
            userName: widget.user.name,
            onTap: () {
              setState(() {
                _showMenu = !_showMenu;
                _yPosition = _showMenu
                    ? heightScreen * distanciaParaTopoComMenuExpandido
                    : heightScreen * _restingTopFraction;
              });
            },
          ),
          MenuApp(
            top: heightScreen * .200,
            showMenu: _showMenu,
            user: widget.user,
            wallets: widget.wallets,
          ),
          CentralWidgetsContent(
            user: widget.user,
            showMenu: _showMenu,
            top: _yPosition,
            restingTopFraction: _restingTopFraction,
            wallets: widget.wallets,
            onChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            // Free-form manual drag for the card's resting position (via the
            // handle bar CentralWidgetsContent renders), clamped to
            // [_kCardTopMin, _kCardTopMax] — separate from the menu tap
            // toggle above, which snaps to two fixed positions instead.
            onManualDrag: (deltaDy) {
              if (_showMenu) {
                return;
              }
              setState(() {
                _restingTopFraction += deltaDy / heightScreen;
                _restingTopFraction = _restingTopFraction.clamp(_kCardTopMin, _kCardTopMax);
                _yPosition = heightScreen * _restingTopFraction;
              });
            },
            onManualDragEnd: () {
              setWalletCardTopFraction(_restingTopFraction);
            },
          ),
          MyDotsApp(
            showMenu: _showMenu,
            top: heightScreen * .85,
            currentIndex: _currentIndex,
            walletQuantity: _walletQuantity,
          ),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 32,
        child: SafeArea(
          top: false,
          child: Center(
            child: Text(
              _appVersion,
              style: const TextStyle(color: rootstockCream, fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }
}
