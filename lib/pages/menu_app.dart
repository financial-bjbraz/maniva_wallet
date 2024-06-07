import 'package:flutter/material.dart';
import 'package:my_rootstock_wallet/pages/item_menu.dart';
import 'package:my_rootstock_wallet/pages/login.dart';

class MenuApp extends StatelessWidget {
  const MenuApp({super.key, required this.top, required this.showMenu});
  final double top;
  final bool showMenu;

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.8);
        const end = Offset.zero;
        const curve = Curves.ease;
        
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
  
  

  @override
  Widget build(BuildContext context) {
    final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(88, 36),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
    );

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 800),
        opacity: showMenu ? 1 : 0,
        child: Container(
            //color: Colors.red,
            height: MediaQuery.of(context).size.height * 0.55,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: <Widget>[
                  Image.network(
                    "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/QR_code_for_mobile_English_Wikipedia.svg/1200px-QR_code_for_mobile_English_Wikipedia.svg.png",
                    height: 100,
                    color: Colors.white,
                  ),
                  const Text.rich(
                    TextSpan(text: "Banco ", children: [
                      TextSpan(
                        text: "260 - Nu Pagamentos S.A",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ]),
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text.rich(
                    TextSpan(text: "Agência ", children: [
                      TextSpan(
                        text: "0001",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ]),
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text.rich(
                    TextSpan(text: "Conta ", children: [
                      TextSpan(
                        text: "000000-0",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ]),
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        const ItemMenu(
                          icone: Icons.info_outline,
                          text: "Me ajuda",
                        ),
                        const ItemMenu(
                          icone: Icons.person_outline,
                          text: "Perfil",
                        ),
                        const ItemMenu(
                          icone: Icons.settings,
                          text: "Configurar conta",
                        ),
                        const SizedBox(
                          height: 22.6,
                        ),
                        Container(
                          height: 35,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 0.7,
                              color: Colors.white54,
                            ),
                          ),
                          child: ElevatedButton(
                            style: raisedButtonStyle,
                            // color: Colors.purple[800],
                            // highlightColor: Colors.transparent,
                            // elevation: 0,
                            // disabledElevation: 0,
                            // highlightElevation: 0,
                            // hoverElevation: 0,
                            onPressed: () {

                            },
                            // focusElevation: 0,
                            // splashColor: Colors.purple[900],
                            child: GestureDetector(
                              onTap: () {

                                Navigator.of(context).push(_createRoute());
                              },
                              child: const Text(
                              "SAIR DO APP",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            )
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ),
    );
  }
}
