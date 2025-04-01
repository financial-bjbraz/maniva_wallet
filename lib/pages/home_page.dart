import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:my_rootstock_wallet/pages/wallet/my_dots_app.dart';
import 'package:my_rootstock_wallet/pages/wallet/central_widgets_content.dart';
import 'package:my_rootstock_wallet/util/util.dart';
import '../entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import '../entities/simple_user.dart';
import 'menu/my_app_bar.dart';
import 'menu/menu_app.dart';

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

  _HomePageState();

  @override
  void initState() {
    super.initState();
    _showMenu = false;
    _currentIndex = 0;
    _walletQuantity = 0;
  }

  loadWallets() async {
    try {
        setState(() {
          _walletQuantity = widget.wallets.length;
        });
    }catch(e) {
      // print('error occurred $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    loadWallets();
    double heightScreen = MediaQuery.of(context).size.height;

    if (_yPosition == 0) {
      _yPosition = heightScreen * .22;
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
                _yPosition =
                    _showMenu ? heightScreen * .42 : heightScreen * .22;
              });
            },
          ),
          MenuApp(
            top: heightScreen * .205,
            showMenu: _showMenu,
          ),

          CentralWidgetsContent(
            user: widget.user,
            showMenu: _showMenu,
            top: _yPosition,
            wallets: widget.wallets,
            onChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            onPanUpdated: (details) {
              double positionBottonLimit = heightScreen * .75;
              double positionTopLimit = heightScreen * .24;
              double middlePosition = positionBottonLimit - positionTopLimit;
              middlePosition = middlePosition / 2;

              setState(() {
                _yPosition += details.delta.dy;

                _yPosition = _yPosition < positionTopLimit
                    ? positionTopLimit
                    : _yPosition;

                _yPosition = _yPosition > positionBottonLimit
                    ? positionBottonLimit
                    : _yPosition;

                if (_yPosition != positionBottonLimit && details.delta.dy > 0) {
                  _yPosition =
                      _yPosition > positionTopLimit + middlePosition - 50
                          ? positionBottonLimit
                          : _yPosition;
                }

                if (_yPosition != positionTopLimit && details.delta.dy < 0) {
                  _yPosition = _yPosition < positionBottonLimit - middlePosition
                      ? positionTopLimit
                      : _yPosition;
                }

                if (_yPosition == positionBottonLimit) {
                  _showMenu = true;
                } else if (_yPosition == positionTopLimit) {
                  _showMenu = false;
                }
              });
            },

          ),

          MyDotsApp(
            showMenu: _showMenu,
            top: heightScreen * .90,
            currentIndex: _currentIndex,
            walletQuantity: _walletQuantity,
          ),
        ],
      ),

      bottomNavigationBar:
      CurvedNavigationBar(color: orange()!, backgroundColor: Colors.black, buttonBackgroundColor: orange(), items: [
        GestureDetector(
            child: const Icon(Icons.home, color: Colors.white),
            onTap: () => {
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => HomePage(user: widget.user, wallets: widget.wallets),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  var begin = const Offset(0.0, 1.0);
                  var end = Offset.zero;
                  var curve = Curves.ease;

                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              ))
            },
        ),
        _walletQuantity > 0 ? GestureDetector(
          child: const Icon(Icons.call_made, color: Colors.white),
          onTap: () => {
            Navigator.of(context).push(PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => HomePage(user: widget.user, wallets: widget.wallets),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                var begin = const Offset(0.0, 1.0);
                var end = Offset.zero;
                var curve = Curves.ease;

                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));

                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            ))
          },
        ) : const SizedBox(),

        _walletQuantity > 0 ? const Icon(Icons.call_received, color: Colors.white) : const SizedBox(),
      ]),
    );
  }
}
