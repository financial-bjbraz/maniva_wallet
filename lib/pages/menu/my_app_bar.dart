import 'package:flutter/material.dart';

import '../../util/util.dart';

class MyAppBar extends StatelessWidget {
  final bool showMenu;
  final VoidCallback onTap;
  final String userName;

  const MyAppBar(
      {super.key,
      required this.showMenu,
      required this.onTap,
      required this.userName});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: MediaQuery.of(context).padding.top,
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                color: orange(),
            ),
            //color: orange(),
            height: MediaQuery.of(context).size.height * .15,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset('assets/images/maniva_logo_white.png',
                        height: 70),
                    // const SizedBox(
                    //   width: 10,
                    // ),
                    // Text(
                    //   userName,
                    //   style: const TextStyle(
                    //     fontWeight: FontWeight.bold,
                    //     fontSize: 18,
                    //     color: Colors.white,
                    //   ),
                    // ),
                  ],
                ),
                Icon(showMenu ? Icons.expand_less : Icons.expand_more, color: Colors.white,),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
