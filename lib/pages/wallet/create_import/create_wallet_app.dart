import 'package:flutter/material.dart';
import 'package:my_rootstock_wallet/pages/details/detail_list.dart';
import 'package:my_rootstock_wallet/wallets/create_import/create_wallet.dart';
import 'package:my_rootstock_wallet/wallets/create_import/create_wallet_detail.dart';

import '../../../entities/simple_user.dart';

class CreateWalletApp extends StatelessWidget {
  final SimpleUser user;
  final CreateWallet createWalletBox = const CreateWallet();
  final CreateNewWalletDetail detailChild;

  const CreateWalletApp({super.key, required this.user, required this.detailChild});

  @override
  Widget build(BuildContext context) {

    Future<void> dialogBuilder(BuildContext context) {
      return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Create new seed'),
            content: const Text(
              'You will create a new seed and from this seed a new private key and an account will be generated.\n'
                  'Make sure you have privacy so that your seed and privateKey are not copied.\n'
                  'Make sure you make a backup or you may lose access to your account.\n'
                  'We are not responsible for lost seeds.\n'
                  'Are you sure you want to create a new seed \n'
                  'and that you are in a safe environment to do so?',
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('Create'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => DetailList(child: detailChild),
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
                },
              ),
            ],
          );
        },
      );
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20), color: Colors.black, border: Border.all(color: Colors.white)),
          child: createWalletBox,
        ),
        onTap: () {
          dialogBuilder(context);
        //if
        },
      ),
    );
  }
}
