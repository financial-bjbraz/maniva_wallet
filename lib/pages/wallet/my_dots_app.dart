import 'package:flutter/material.dart';

class MyDotsApp extends StatelessWidget {
  const MyDotsApp(
      {super.key,
      required this.currentIndex,
      required this.top,
      required this.showMenu,
      required this.walletQuantity});

  final int currentIndex;
  final double top;
  final bool showMenu;
  final int walletQuantity;

  getColor(int index) {
    return index != currentIndex ? Colors.white38 : Colors.white;
  }

  getWidth() {
    return 8.0;
  }

  @override
  Widget build(BuildContext context) {
    var widgets = <Widget>{};

    if(walletQuantity > 0) {
      for (int i = 0; i < walletQuantity; i++) {
        widgets.add(SizedBox(
          width: getWidth() as double?
          ,
        ));
        widgets.add(AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 7,
          width: 7,
          decoration: BoxDecoration(
            color: getColor(i) as Color?,
            shape: BoxShape.circle,
          ),
        ));
      }
    }else{
      widgets.add(
          const SizedBox(
           width: 8,
          )
      );
    }

    return Positioned(
      top: top,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: showMenu ? 0 : 1,
        child: Row(
          children: <Widget>[
            ...widgets,
            const SizedBox(
              width: 8,
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 7,
              width: 7,
              decoration: BoxDecoration(
                color: getColor(walletQuantity+0) as Color?,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 7,
              width: 7,
              decoration: BoxDecoration(
                color: getColor(walletQuantity+1) as Color?,
                shape: BoxShape.circle,
              ),
            ),

            // AnimatedContainer(
            //   duration: const Duration(milliseconds: 300),
            //   height: 7,
            //   width: 7,
            //   decoration: BoxDecoration(
            //     color: getColor(3),
            //     shape: BoxShape.circle,
            //   ),
            // ),
            // const SizedBox(
            //   width: 8,
            // ),
            // AnimatedContainer(
            //   duration: const Duration(milliseconds: 300),
            //   height: 7,
            //   width: 7,
            //   decoration: BoxDecoration(
            //     color: getColor(4),
            //     shape: BoxShape.circle,
            //   ),
            // ),
            // const SizedBox(
            //   width: 8,
            // ),
            // AnimatedContainer(
            //   duration: const Duration(milliseconds: 300),
            //   height: 7,
            //   width: 7,
            //   decoration: BoxDecoration(
            //     color: getColor(5),
            //     shape: BoxShape.circle,
            //   ),
            // ),
            // const SizedBox(
            //   width: 8,
            // ),
            // AnimatedContainer(
            //   duration: const Duration(milliseconds: 300),
            //   height: 7,
            //   width: 7,
            //   decoration: BoxDecoration(
            //     color: getColor(6),
            //     shape: BoxShape.circle,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
