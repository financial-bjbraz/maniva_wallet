import 'package:flutter/material.dart';
import 'package:my_rootstock_wallet/pages/details/detail_list.dart';

class ItemMenuBottom extends StatelessWidget {
  final IconData icon;
  final String text;
  final StatelessWidget widget;

  const ItemMenuBottom(
      {super.key, required this.icon, required this.text, required this.widget});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .15,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 12,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(7.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(icon),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      onTap: () {
        Navigator.of(context).push(PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              DetailList(child: widget),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = const Offset(0.0, 1.0);
            var end = Offset.zero;
            var curve = Curves.ease;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ));
      },
    );
  }
}
