import 'package:flutter/material.dart';

import '../../../entities/simple_user.dart';
import '../../details/detail_list.dart';
import '../../../wallets/create_import/import_wallet_pk_detail.dart';
import '../../../wallets/create_import/import_wallet_seed_detail.dart';

class ImportSeedPkApp extends StatelessWidget {
  final ImportNewWalletByPrivateKeyDetail importWalletByPrivateKey ;
  final ImportNewWalletBySeedDetail importWalletBySeed;
  final SimpleUser user;

  const ImportSeedPkApp({super.key, required this.user, required this.importWalletByPrivateKey, required this.importWalletBySeed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.black,
            border: Border.all(color: Colors.white)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 20, top: 30, bottom: 5),
                      child: GestureDetector(
                          child: const Row(
                            children: [
                              Icon(
                                Icons.add_circle,
                                color: Color.fromRGBO(7, 255, 208, 1),
                                size: 48,
                              ),
                              Text(
                                "Importar Seed ",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    color: Colors.black,
                                    backgroundColor:
                                        Color.fromRGBO(7, 255, 208, 1),
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).push(PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => DetailList(child: importWalletBySeed),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
                            ));

                          }),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 20),
                      child: GestureDetector(
                          child: const Row(
                            children: [
                              Icon(
                                Icons.add_circle,
                                color: Color.fromRGBO(7, 255, 208, 1),
                                size: 48,
                              ),
                              Text(
                                "Importar \nPrivate Key ",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    color: Colors.black,
                                    backgroundColor:
                                        Color.fromRGBO(7, 255, 208, 1),
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          onTap: () {

                            Navigator.of(context).push(PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => DetailList(child: importWalletByPrivateKey),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
                            ));

                          }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
