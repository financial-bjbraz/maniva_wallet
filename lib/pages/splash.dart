import 'package:flutter/material.dart';
import 'package:my_rootstock_wallet/pages/login.dart';

import '../util/util.dart';

// ignore_for_file: strict_raw_type
class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    delay();
  }

  delay() async {
    verifyAndCreateDataBase().then((created) {
      print("Database created: $created");
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (BuildContext context, Animation animation, Animation secondaryAnimation) {
            return const LoginPage();
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Image.asset(
            "assets/images/maniva.png",
            height: 180,
          ),
        ));
  }
}
